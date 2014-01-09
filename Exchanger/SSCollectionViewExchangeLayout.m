//
//  SSCollectionViewExchangeFlowLayout.m
//  Exchanger
//
//  Created by Murray Sagal on 2012-10-31.
//  Copyright (c) 2012 Signature Software. All rights reserved.
//

#import "SSCollectionViewExchangeFlowLayout.h"
#import <QuartzCore/QuartzCore.h>


typedef NS_ENUM(NSInteger, ExchangeEventType) {
    ExchangeEventTypeDraggedFromStartingItem,
    ExchangeEventTypeDraggedToOtherItem,
    ExchangeEventTypeDraggedToStartingItem,
    ExchangeEventTypeNothingToExchange
};

static CFTimeInterval const minimumPressDuration = 0.15;
static CGFloat const alphaForDimmedItem = 0.6;


@interface SSCollectionViewExchangeFlowLayout ()

@property (weak, nonatomic) id <SSCollectionViewExchangeFlowLayoutDelegate> delegate;

@property (strong, nonatomic) UIImageView *viewForImageBeingDragged;
@property (nonatomic) CGPoint locationInCollectionView;
@property (strong, nonatomic) NSIndexPath *originalIndexPathForItemBeingDragged;
@property (strong, nonatomic) NSIndexPath *indexPathOfItemLastExchanged;
@property (strong, nonatomic) NSIndexPath *currentIndexPath;
@property (nonatomic) BOOL mustUndoPriorExchange;

// This is the offset from the location of the long press to the view's center...
@property (nonatomic) CGPoint offset;

// This helps safeguard against the documented behaviour regarding items that are hidden.
// As an optimization, the collection view might not create the corresponding view
// if the hidden property (UICollectionViewLayoutAttributes) is set to YES. In the
// gesture recognizer's recognized state we always need the cell for the item that
// was hidden so we can animate to its center when the user releases. So we use this
// property to hold the center of the cell at indexPathOfItemLastExchanged but it must
// be captured just before it is hidden.
@property (nonatomic) CGPoint centerOfCellForLastItemExchanged;

// These readonly properties just make the code a bit more readable...
@property (strong, nonatomic, readonly) NSIndexPath *indexPathOfItemToHide;
@property (strong, nonatomic, readonly) NSIndexPath *indexPathOfItemToDim;

@end



@implementation SSCollectionViewExchangeFlowLayout

- (id)initWithDelegate:(id<SSCollectionViewExchangeFlowLayoutDelegate>)delegate
        collectionView:(UICollectionView *)collectionView {
    
    self = [super init];
    if (self) {
        
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(longPress)];
        _longPressGestureRecognizer.minimumPressDuration = minimumPressDuration;
        _longPressGestureRecognizer.delaysTouchesBegan = YES;
        [collectionView addGestureRecognizer:_longPressGestureRecognizer];
        _delegate = delegate;
        collectionView.collectionViewLayout = self;
        
    }
    return self;
}



//-----------------------------------------------------
#pragma mark - Override the layout attribute methods...

// There is one item that needs hiding and one that needs dimming. As the user drags the item being moved over
// another item, that item moves to the original location of the item being dragged. That cell is dimmed, marking
// the original location of the item being moved. The cell at the position of the displaced item is hidden giving
// the user the sense that the item being dragged will land there if their finger is released.
//
// This is accomplished by overriding layoutAttributesForElementsInRect: and layoutAttributesForItemAtIndexPath:.
//
// It can happen that the item to hide and the item to dim will be the same. This happens when the user drags back
// to the starting location. This collision is irrelevant because there are two separate properties: one tracking
// the item to hide and one tracking the item to dim. In layoutAttributesForItem: the hidden property is set first
// then the alpha. If the items are the same setting the alpha for an item that is hidden has no effect.

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    
    NSArray *layoutAttributes = [super layoutAttributesForElementsInRect:rect];
    
    for (UICollectionViewLayoutAttributes *attributesForItem in layoutAttributes)
    {
        (void) [self layoutAttributesForItem:attributesForItem];
    }
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewLayoutAttributes *attributesForItem = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    return [self layoutAttributesForItem:attributesForItem];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItem:(UICollectionViewLayoutAttributes *)attributesForItem {
    
    attributesForItem.hidden = ([attributesForItem.indexPath isEqual:self.indexPathOfItemToHide])? YES : NO;
    attributesForItem.alpha =  ([attributesForItem.indexPath isEqual:self.indexPathOfItemToDim])?  alphaForDimmedItem : 1.0;

    return attributesForItem;
}



//----------------------------------------------------------
#pragma mark - UILongPressGestureRecognizer action method...

- (void)longPress {
    
    switch (self.longPressGestureRecognizer.state) {
            
        case UIGestureRecognizerStateBegan:
            [self beginExchangeTransaction];
            break;
            
        case UIGestureRecognizerStateChanged:
            [self updateCellImageLocation];
            [self performExchangeEventType];
            break;
            
        case UIGestureRecognizerStateEnded:
            [self finishExchangeTransaction];
            break;
            
        case UIGestureRecognizerStatePossible:
            NSLog(@"UIGestureRecognizerStatePossible");
            break;
            
        case UIGestureRecognizerStateCancelled:
            NSLog(@"UIGestureRecognizerStateCancelled");
            break;
            
        case UIGestureRecognizerStateFailed:
            NSLog(@"UIGestureRecognizerStateFailed");
            break;
    }
}



//--------------------------------
#pragma mark - Instance methods...

- (void)cancelLongPressRecognizer {
    
    // As per the docs, this triggers a cancel.
    
    self.longPressGestureRecognizer.enabled = NO;
    self.longPressGestureRecognizer.enabled = YES;
}

- (void)beginExchangeTransaction {
 
    NSIndexPath *indexPath;
    BOOL cancel = YES;
    
    if ([self.delegate canExchange])
    {
        indexPath = [self.collectionView indexPathForItemAtPoint:self.locationInCollectionView];
        if (indexPath != nil) cancel = NO;
    }
    
    if (cancel) {
        [self cancelLongPressRecognizer];
        return;
    }
    
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    
    // Create an image of the cell, stuff it in an image view, and stick it under the user's finger...
    UIImage *cellImage = [self imageFromCell:cell withBackgroundColor:[UIColor darkGrayColor] alpha:0.8];
    UIImageView *cellImageView = [[UIImageView alloc] initWithImage:cellImage];
    cellImageView.frame = cell.frame;
    [self.collectionView addSubview:cellImageView];
    
    // TODO: look at anchorPoint!!!

    // Calculate the offset from the location of the user's finger to the center of view being dragged...
    CGPoint locationInCellImageView = [self.longPressGestureRecognizer locationInView:cellImageView];
    CGPoint cellImageViewCenter = CGPointMake(cellImageView.frame.size.width/2, cellImageView.frame.size.height/2);
    CGPoint offset = CGPointMake(locationInCellImageView.x - cellImageViewCenter.x, locationInCellImageView.y - cellImageViewCenter.y);
    
    // Blink. This is one of any number of ways to accomplish this.
    NSTimeInterval animationDuration = 0.20f;
    CGFloat blinkToScale = 1.2f;
    CGFloat finalScale = 1.0f;
    [UIView animateWithDuration:animationDuration animations:^ {
         cellImageView.transform = CGAffineTransformMakeScale(blinkToScale, blinkToScale);
     } completion:^(BOOL finished) {
         [UIView animateWithDuration:animationDuration animations:^ {
              cellImageView.transform = CGAffineTransformMakeScale(finalScale, finalScale);
          }];
     }];
    
    self.offset = offset;
    self.viewForImageBeingDragged = cellImageView;
    self.centerOfCellForLastItemExchanged = cell.center;
    self.originalIndexPathForItemBeingDragged = indexPath;
    self.indexPathOfItemLastExchanged = indexPath;
    self.mustUndoPriorExchange = NO;
    
    // InvalidateLayout kicks off the process of redrawing the layout.
    // This class intervenes in that process by overriding layoutAttributesForElementsInRect: and
    // layoutAttributesForItemAtIndexPath: to hide and dim items as required.
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)updateCellImageLocation {

    CGPoint offsetLocationInCollectionView = CGPointMake(self.locationInCollectionView.x - self.offset.x, self.locationInCollectionView.y - self.offset.y);
    self.viewForImageBeingDragged.center = offsetLocationInCollectionView;
}

- (void)performExchangeEventType {
    
    ExchangeEventType exchangeEventType = [self exchangeEventTypeForCurrentIndexPath];

    switch (exchangeEventType) {
            
        case ExchangeEventTypeNothingToExchange:
            break;
            
        case ExchangeEventTypeDraggedFromStartingItem:
            [self performExchangeEventTypeDraggedFromStartingItem];
            break;
            
        case ExchangeEventTypeDraggedToOtherItem:
            [self performExchangeEventTypeDraggedToOtherItem];
            break;
            
        case ExchangeEventTypeDraggedToStartingItem:
            [self performExchangeEventTypeDraggedToStartingItem];
            break;
    }
}

- (void)performExchangeEventTypeDraggedFromStartingItem {
    
    [self.collectionView performBatchUpdates:^{
        
        // Move the item being dragged to indexPath...
        [self.collectionView moveItemAtIndexPath:self.originalIndexPathForItemBeingDragged toIndexPath:self.currentIndexPath];
        
        // Move the item at indexPath to the starting position...
        [self.collectionView moveItemAtIndexPath:self.currentIndexPath toIndexPath:self.originalIndexPathForItemBeingDragged];
        
        // Let the delegate know.
        [self.delegate exchangeItemAtIndexPath:self.currentIndexPath withItemAtIndexPath:self.originalIndexPathForItemBeingDragged];
        [self.delegate didFinishExchangeEvent];
        
        // Set state.
        self.indexPathOfItemLastExchanged = self.currentIndexPath;
        self.mustUndoPriorExchange = YES;
        
        [self keepCenterOfCellForLastItemExchangedAtIndexPath:self.currentIndexPath];
        
    } completion:nil];
}

- (void)performExchangeEventTypeDraggedToOtherItem {
    
    [self.collectionView performBatchUpdates:^{
        
        // Put the previously exchanged item back to its original location...
        [self.collectionView moveItemAtIndexPath:self.originalIndexPathForItemBeingDragged toIndexPath:self.indexPathOfItemLastExchanged];
        
        // Move the item being dragged to the current postion...
        [self.collectionView moveItemAtIndexPath:self.indexPathOfItemLastExchanged toIndexPath:self.currentIndexPath];
        
        // Move the item we're over to the original location of the item being dragged...
        [self.collectionView moveItemAtIndexPath:self.currentIndexPath toIndexPath:self.originalIndexPathForItemBeingDragged];
        
        // Let the delegate know. First undo the prior exchange then do the new exchange...
        [self.delegate exchangeItemAtIndexPath:self.originalIndexPathForItemBeingDragged withItemAtIndexPath:self.indexPathOfItemLastExchanged];
        [self.delegate exchangeItemAtIndexPath:self.currentIndexPath withItemAtIndexPath:self.originalIndexPathForItemBeingDragged];
        [self.delegate didFinishExchangeEvent];
        
        // Set state.
        self.indexPathOfItemLastExchanged = self.currentIndexPath;
        self.mustUndoPriorExchange = YES;
        
        [self keepCenterOfCellForLastItemExchangedAtIndexPath:self.currentIndexPath];
        
    } completion:nil];
}

- (void)performExchangeEventTypeDraggedToStartingItem {
    
    [self.collectionView performBatchUpdates:^{
        
        // Put the previously exchanged item back to its original location...
        [self.collectionView moveItemAtIndexPath:self.originalIndexPathForItemBeingDragged toIndexPath:self.indexPathOfItemLastExchanged];
        
        // Put the item we're dragging back into its origingal location...
        [self.collectionView moveItemAtIndexPath:self.indexPathOfItemLastExchanged toIndexPath:self.originalIndexPathForItemBeingDragged];
        
        // Let the delegate know.
        [self.delegate exchangeItemAtIndexPath:self.originalIndexPathForItemBeingDragged withItemAtIndexPath:self.indexPathOfItemLastExchanged];
        [self.delegate didFinishExchangeEvent];
        
        // Set state. This is the same state as when the gesture began.
        self.indexPathOfItemLastExchanged = self.originalIndexPathForItemBeingDragged;
        self.mustUndoPriorExchange = NO;
        
        [self keepCenterOfCellForLastItemExchangedAtIndexPath:self.currentIndexPath];
        
    } completion:nil];
}

- (void)finishExchangeTransaction {
    
    // Let the delegate know...
    NSIndexPath *indexPath1 = ([self itemsWereExchanged])? self.indexPathOfItemLastExchanged : nil;
    NSIndexPath *indexPath2 = ([self itemsWereExchanged])? self.originalIndexPathForItemBeingDragged : nil;
    [self.delegate didFinishExchangeTransactionWithItemAtIndexPath:indexPath1 andItemAtIndexPath:indexPath2];
    
    // Animate the release. This is one of any number of ways to accomplish this.
    // You can change the animation as you see fit but you must call
    // performPostReleaseCleanupWithAnimationDuration: in your final completion block.

    NSTimeInterval duration = 0.20;
    CGFloat blinkToScale = 1.05f;
    CGFloat finalScale = 1.0f;
    UICollectionViewCell *cellForOriginalLocation = [self.collectionView cellForItemAtIndexPath:self.originalIndexPathForItemBeingDragged];
    
    [UIView animateWithDuration:duration animations:^ {
        self.viewForImageBeingDragged.center = self.centerOfCellForLastItemExchanged;
        cellForOriginalLocation.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:duration animations:^ {
            self.viewForImageBeingDragged.transform = CGAffineTransformMakeScale(blinkToScale, blinkToScale);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:duration animations:^ {
                self.viewForImageBeingDragged.transform = CGAffineTransformMakeScale(finalScale, finalScale);
            } completion:^(BOOL finished) {
                [self performPostReleaseCleanupWithAnimationDuration:duration];
            }];
        }];
    }];
}

- (void)performPostReleaseCleanupWithAnimationDuration:(float)animationDuration {
    
    [CATransaction begin];
    {
        self.indexPathOfItemLastExchanged = nil;
        self.originalIndexPathForItemBeingDragged = nil;
        [self.collectionView.collectionViewLayout invalidateLayout];
        
        [CATransaction setCompletionBlock:^{
            
            [UIView animateWithDuration:animationDuration animations:^{
                self.viewForImageBeingDragged.alpha = 0.0;
            } completion:^(BOOL finished) {
                [self.viewForImageBeingDragged removeFromSuperview];
            }];
        }];
    }
    [CATransaction commit];
}

- (BOOL)isOverSameItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return [indexPath isEqual:self.indexPathOfItemLastExchanged];
}

- (BOOL)isBackToStartingItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return [indexPath isEqual:self.originalIndexPathForItemBeingDragged];
}

- (void)keepCenterOfCellForLastItemExchangedAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *itemCell = [self.collectionView cellForItemAtIndexPath:indexPath];
    self.centerOfCellForLastItemExchanged = itemCell.center;
}

- (BOOL)itemsWereExchanged {
    
    return ![self isBackToStartingItemAtIndexPath:self.indexPathOfItemLastExchanged];
}

- (UIImage *)imageFromCell:(UICollectionViewCell *)cell
       withBackgroundColor:(UIColor *)backgroundColor
                     alpha:(float)alpha {
    
    UIColor *originalBackgroundColor = cell.backgroundColor;
    float originialAlpha = cell.alpha;
    cell.backgroundColor = backgroundColor;
    cell.alpha = alpha;
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, cell.opaque, 0.0f);
    [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *cellImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    cell.backgroundColor = originalBackgroundColor;
    cell.alpha = originialAlpha;
    
    return cellImage;
}

- (ExchangeEventType)exchangeEventTypeForCurrentIndexPath {
    
    // The user is still dragging in the long press. Determine the exchange event type.
    self.currentIndexPath = [self.collectionView indexPathForItemAtPoint:self.locationInCollectionView];

    if  (self.currentIndexPath == nil || [self isOverSameItemAtIndexPath:self.currentIndexPath]) return ExchangeEventTypeNothingToExchange;
    
    
    // Otherwise there is an exchange event to perform. What kind?
    
    if (self.mustUndoPriorExchange)
    {
        return ([self isBackToStartingItemAtIndexPath:self.currentIndexPath])? ExchangeEventTypeDraggedToStartingItem : ExchangeEventTypeDraggedToOtherItem;
    }
    else
    {
        return ExchangeEventTypeDraggedFromStartingItem;
    }
}

- (CGPoint)locationInCollectionView {
    
    return [self.longPressGestureRecognizer locationInView:self.collectionView];
}


//-----------------------
#pragma mark - Accessors...

- (NSIndexPath *)indexPathOfItemToHide {
    
    return self.indexPathOfItemLastExchanged;
    
    // Return nil if you don't want to hide.
    // This can be useful during testing to ensure that the item
    // you're dragging around is properly following.
}

- (NSIndexPath *)indexPathOfItemToDim {
    
    return self.originalIndexPathForItemBeingDragged;
    
    // As above return nil if you don't want to dim.
}

@end
