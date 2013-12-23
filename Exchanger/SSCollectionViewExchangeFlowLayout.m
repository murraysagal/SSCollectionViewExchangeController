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

@interface SSCollectionViewExchangeFlowLayout ()


//@property (nonatomic, assign) ExchangeType exchangeType;


// This is the view that gets dragged around...
@property (strong, nonatomic) UIImageView *viewForImageBeingDragged;

// The offset from the location of the finger to the view's center...
@property (nonatomic) CGPoint offset;

// These manage the state of the exchange process...
@property (strong, nonatomic) NSIndexPath *originalIndexPathForItemBeingDragged;
@property (strong, nonatomic) NSIndexPath *indexPathOfItemLastExchanged;
@property (nonatomic) BOOL mustUndoPriorExchange;

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

@property (weak, nonatomic) id <SSCollectionViewExchangeFlowLayoutDelegate> delegate;

@end




@implementation SSCollectionViewExchangeFlowLayout

- (id)initWithDelegate:(id<SSCollectionViewExchangeFlowLayoutDelegate>)delegate
        collectionView:(UICollectionView *)collectionView {
    
    self = [super init];
    if (self) {
        
        // Create and configure the long press gesture recognizer...
        self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(longPress:)];
        self.longPressGestureRecognizer.minimumPressDuration = 0.15;
        self.longPressGestureRecognizer.delaysTouchesBegan = YES;
        
        // Add the gesture to the collection view...
        [collectionView addGestureRecognizer:self.longPressGestureRecognizer];
        
        // Set the delegate...
        self.delegate = delegate;
        
        // Set this object (self) to be the collection view's layout...
        collectionView.collectionViewLayout = self;
        
    }
    return self;
}


//-----------------------
#pragma mark - Accessors...

- (NSIndexPath *)indexPathOfItemToHide
{
    return self.indexPathOfItemLastExchanged;
    
    // Return nil if you don't want to hide.
    // This can be useful during testing to ensure that the item
    // you're dragging around is properly following.
}

- (NSIndexPath *)indexPathOfItemToDim
{
    return self.originalIndexPathForItemBeingDragged;
    
    // As above return nil if you don't want to dim.
}



//--------------------------------
#pragma mark - Layout attributes...

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

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *layoutAttributes = [super layoutAttributesForElementsInRect:rect];
    
    for (UICollectionViewLayoutAttributes *attributesForItem in layoutAttributes)
    {
        (void) [self layoutAttributesForItem:attributesForItem];
    }
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributesForItem = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    return [self layoutAttributesForItem:attributesForItem];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItem:(UICollectionViewLayoutAttributes *)attributesForItem
{
    attributesForItem.hidden = ([attributesForItem.indexPath isEqual:self.indexPathOfItemToHide])? YES : NO;
    attributesForItem.alpha =  ([attributesForItem.indexPath isEqual:self.indexPathOfItemToDim])?  0.6 : 1.0;

    return attributesForItem;
}



//-------------------------------------------------
#pragma mark - UIGestureRecognizer action method...

- (void)longPress:(UILongPressGestureRecognizer *)recognizer
{
    switch (recognizer.state) {
            
        case UIGestureRecognizerStateBegan:
            [self setUpForExchangeTransaction:recognizer];
            break;
            
        case UIGestureRecognizerStateChanged:
            [self manageExchangeEvent:recognizer];
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

- (void)cancelGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    // As per the docs, this triggers a cancel.
    
    gestureRecognizer.enabled = NO;
    gestureRecognizer.enabled = YES;
}

- (void)setUpForExchangeTransaction:(UIGestureRecognizer *)gestureRecognizer
{
    if ([self.delegate canExchange] == NO)
    {
        [self cancelGestureRecognizer:gestureRecognizer];
        return;
    }

    CGPoint locationInCollectionView = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:locationInCollectionView];
    
    if (indexPath == nil)
    {
        [self cancelGestureRecognizer:gestureRecognizer];
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
    CGPoint locationInCellImageView = [gestureRecognizer locationInView:cellImageView];
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

- (void)manageExchangeEvent:(UIGestureRecognizer *)gestureRecognizer
{
    // Update the location of the view the user is dragging around...
    CGPoint locationInCollectionView = [gestureRecognizer locationInView:self.collectionView];
    CGPoint offsetLocationInCollectionView = CGPointMake(locationInCollectionView.x - self.offset.x, locationInCollectionView.y - self.offset.y);
    self.viewForImageBeingDragged.center = offsetLocationInCollectionView;
    
    NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint:locationInCollectionView];
    
    ExchangeEventType exchangeEventType = [self exchangeEventTypeForCurrentIndexPath:currentIndexPath];
    
    switch (exchangeEventType) {
            
        case ExchangeEventTypeNothingToExchange:
            break;
            
        case ExchangeEventTypeDraggedFromStartingItem:
            [self performExchangeForDraggedFromStartingItemToIndexPath:currentIndexPath];
            break;
            
        case ExchangeEventTypeDraggedToOtherItem:
            [self performExchangeForDraggedToOtherItemAtIndexPath:currentIndexPath];
            break;
            
        case ExchangeEventTypeDraggedToStartingItem:
            [self performExchangeForDraggedToStartingItemAtIndexPath:currentIndexPath];
            break;
    }
}

- (ExchangeEventType)exchangeEventTypeForCurrentIndexPath:(NSIndexPath *)currentIndexPath
{
    // The user is still dragging in the long press. Determine the exchange event type.
    
    if  (currentIndexPath == nil || [self isOverSameItemAtIndexPath:currentIndexPath] == YES)
        return ExchangeEventTypeNothingToExchange;
    
    
    // Otherwise there is an exchange event to perform. What kind?
    
    if (self.mustUndoPriorExchange)
    {
        return ([self isBackToStartingItemAtIndexPath:currentIndexPath])? ExchangeEventTypeDraggedToStartingItem : ExchangeEventTypeDraggedToOtherItem;
    }
    else
    {
        return ExchangeEventTypeDraggedFromStartingItem;
    }
}

- (void)performExchangeForDraggedFromStartingItemToIndexPath:(NSIndexPath *)indexPath
{
    [self.collectionView performBatchUpdates:^{
        
        // Move the item being dragged to indexPath...
        [self.collectionView moveItemAtIndexPath:self.originalIndexPathForItemBeingDragged toIndexPath:indexPath];
        
        // Move the item at indexPath to the starting position...
        [self.collectionView moveItemAtIndexPath:indexPath toIndexPath:self.originalIndexPathForItemBeingDragged];
        
        // Let the delegate know.
        [self.delegate exchangeItemAtIndexPath:indexPath withItemAtIndexPath:self.originalIndexPathForItemBeingDragged];
        [self.delegate didFinishExchangeEvent];
        
        // Set state.
        self.indexPathOfItemLastExchanged = indexPath;
        self.mustUndoPriorExchange = YES;
        
        [self keepCenterOfCellForLastItemExchangedAtIndexPath:indexPath];
        
    } completion:nil];
}

- (void)performExchangeForDraggedToOtherItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.collectionView performBatchUpdates:^{
        
        // Put the previously exchanged item back to its original location...
        [self.collectionView moveItemAtIndexPath:self.originalIndexPathForItemBeingDragged toIndexPath:self.indexPathOfItemLastExchanged];
        
        // Move the item being dragged to the current postion...
        [self.collectionView moveItemAtIndexPath:self.indexPathOfItemLastExchanged toIndexPath:indexPath];
        
        // Move the item we're over to the original location of the item being dragged...
        [self.collectionView moveItemAtIndexPath:indexPath toIndexPath:self.originalIndexPathForItemBeingDragged];
        
        // Let the delegate know. First undo the prior exchange then do the new exchange...
        [self.delegate exchangeItemAtIndexPath:self.originalIndexPathForItemBeingDragged withItemAtIndexPath:self.indexPathOfItemLastExchanged];
        [self.delegate exchangeItemAtIndexPath:indexPath withItemAtIndexPath:self.originalIndexPathForItemBeingDragged];
        [self.delegate didFinishExchangeEvent];
        
        // Set state.
        self.indexPathOfItemLastExchanged = indexPath;
        self.mustUndoPriorExchange = YES;
        
        [self keepCenterOfCellForLastItemExchangedAtIndexPath:indexPath];
        
    } completion:nil];
}

- (void)performExchangeForDraggedToStartingItemAtIndexPath:(NSIndexPath *)indexPath
{
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
        
        [self keepCenterOfCellForLastItemExchangedAtIndexPath:indexPath];
        
    } completion:nil];
}

- (void)finishExchangeTransaction
{
    // Let the delegate know...
    NSIndexPath *indexPath1 = ([self itemsWereExchanged])? self.indexPathOfItemLastExchanged : nil;
    NSIndexPath *indexPath2 = ([self itemsWereExchanged])? self.originalIndexPathForItemBeingDragged : nil;
    [self.delegate didFinishExchangeTransactionWithItemAtIndexPath:indexPath1 andItemAtIndexPath:indexPath2];
    
    // Animate the release. This is one of any number of ways to accomplish this.
    // You can change the animation as you see fit but you must call
    // performPostReleaseCleanupWithAnimationDuration: in the final completion block.

    NSTimeInterval animationDuration = 0.20f;
    CGFloat blinkToScale = 1.05f;
    CGFloat finalScale = 1.0f;
    UICollectionViewCell *cellForOriginalLocation = [self.collectionView cellForItemAtIndexPath:self.originalIndexPathForItemBeingDragged];
    
    // FIX: There is a stall after the release???
    
    [UIView animateWithDuration:animationDuration animations:^ {
        self.viewForImageBeingDragged.center = self.centerOfCellForLastItemExchanged;
        cellForOriginalLocation.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:animationDuration animations:^ {
            self.viewForImageBeingDragged.transform = CGAffineTransformMakeScale(blinkToScale, blinkToScale);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:animationDuration animations:^ {
                self.viewForImageBeingDragged.transform = CGAffineTransformMakeScale(finalScale, finalScale);
            } completion:^(BOOL finished) {
                
                [self performPostReleaseCleanupWithAnimationDuration:animationDuration];
            
            }];
        }];
    }];
}

- (void)performPostReleaseCleanupWithAnimationDuration:(float)animationDuration
{
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

- (BOOL)isOverSameItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [indexPath isEqual:self.indexPathOfItemLastExchanged];
}

- (BOOL)isBackToStartingItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [indexPath isEqual:self.originalIndexPathForItemBeingDragged];
}

- (void)keepCenterOfCellForLastItemExchangedAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *itemCell = [self.collectionView cellForItemAtIndexPath:indexPath];
    self.centerOfCellForLastItemExchanged = itemCell.center;
}

- (BOOL)itemsWereExchanged
{
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

@end
