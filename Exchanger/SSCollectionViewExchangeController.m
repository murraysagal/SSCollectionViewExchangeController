//
//  SSCollectionViewExchangeController.m
//  Exchanger
//
//  Created by Murray Sagal on 1/9/2014.
//  Copyright (c) 2014 Murray Sagal. All rights reserved.
//

#import "SSCollectionViewExchangeController.h"
#import "SSCollectionViewExchangeLayout.h"
#import <QuartzCore/QuartzCore.h>


typedef NS_ENUM(NSInteger, ExchangeEventType) {
    ExchangeEventTypeDraggedFromStartingItem,
    ExchangeEventTypeDraggedToOtherItem,
    ExchangeEventTypeDraggedToStartingItem,
    ExchangeEventTypeNothingToExchange
};

static CFTimeInterval const minimumPressDuration = 0.15; // ??? should this be exposed???


@interface SSCollectionViewExchangeController () <SSCollectionViewExchangeLayoutDelegate>

@property (weak, nonatomic)     id<SSCollectionViewExchangeControllerDelegate> delegate;

@property (weak, nonatomic)     UICollectionView    *collectionView;
@property (strong, nonatomic)   UIImageView         *viewForImageBeingDragged;
@property (nonatomic)           CGPoint             locationInCollectionView;
@property (strong, nonatomic)   NSIndexPath         *originalIndexPathForItemBeingDragged;
@property (strong, nonatomic)   NSIndexPath         *indexPathOfItemLastExchanged;
@property (strong, nonatomic)   NSIndexPath         *currentIndexPath;
@property (nonatomic)           BOOL                mustUndoPriorExchange;

// For the view being dragged, this is the offset from the location of the long press to its center...
@property (nonatomic)           CGPoint             offset;

// This helps safeguard against the documented behaviour regarding items that are hidden.
// As an optimization, the collection view might not create the corresponding view
// if the hidden property (UICollectionViewLayoutAttributes) is set to YES. In the
// gesture recognizer's recognized state we always need the cell for the item that
// is hidden so we can animate to its center when the user releases. So we use this
// property to hold the center of the cell at indexPathOfItemLastExchanged but it must
// be captured just before it is hidden.
@property (nonatomic)           CGPoint             centerOfCellForLastItemExchanged;

@property (strong, nonatomic)   UILongPressGestureRecognizer *longPressGestureRecognizer;

@end


@implementation SSCollectionViewExchangeController

- (id)initWithDelegate:(id<SSCollectionViewExchangeControllerDelegate>)delegate
        collectionView:(UICollectionView *)collectionView
{
    self = [super init];
    if (self) {
        
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress)];
        _longPressGestureRecognizer.minimumPressDuration = minimumPressDuration;
        _longPressGestureRecognizer.delaysTouchesBegan = YES;
        [collectionView addGestureRecognizer:_longPressGestureRecognizer];
        
        SSCollectionViewExchangeLayout *exchangeLayout = [[SSCollectionViewExchangeLayout alloc] initWithDelegate:self];
        
        collectionView.collectionViewLayout = exchangeLayout;
        
        self.collectionView = collectionView;
        self.delegate = delegate;
    }
    return self;
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
    // SSCollectionViewExchangeLayout intervenes in that process by overriding
    // layoutAttributesForElementsInRect: and layoutAttributesForItemAtIndexPath:
    // to hide and dim items as required.
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)updateCellImageLocation {
    
    CGPoint offsetLocationInCollectionView = CGPointMake(self.locationInCollectionView.x - self.offset.x, self.locationInCollectionView.y - self.offset.y);
    self.viewForImageBeingDragged.center = offsetLocationInCollectionView;
}

- (void)performExchangeEventType {
    
    switch ([self exchangeEventType]) {
            
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
        
        // Model...
        [self.delegate exchangeItemAtIndexPath:self.currentIndexPath withItemAtIndexPath:self.originalIndexPathForItemBeingDragged];
        [self.delegate didFinishExchangeEvent];
        
        // View...
        [self.collectionView moveItemAtIndexPath:self.originalIndexPathForItemBeingDragged toIndexPath:self.currentIndexPath];
        [self.collectionView moveItemAtIndexPath:self.currentIndexPath toIndexPath:self.originalIndexPathForItemBeingDragged];
        
        // State...
        self.indexPathOfItemLastExchanged = self.currentIndexPath;
        self.mustUndoPriorExchange = YES;
        
        [self keepCenterOfCellForLastItemExchangedAtIndexPath:self.currentIndexPath];
        
    } completion:nil];
}

- (void)performExchangeEventTypeDraggedToOtherItem {
    
    [self.collectionView performBatchUpdates:^{
        
        // Model...
        [self.delegate exchangeItemAtIndexPath:self.originalIndexPathForItemBeingDragged withItemAtIndexPath:self.indexPathOfItemLastExchanged];
        [self.delegate exchangeItemAtIndexPath:self.currentIndexPath withItemAtIndexPath:self.originalIndexPathForItemBeingDragged];
        [self.delegate didFinishExchangeEvent];
        
        // View...
        [self.collectionView moveItemAtIndexPath:self.originalIndexPathForItemBeingDragged toIndexPath:self.indexPathOfItemLastExchanged];
        [self.collectionView moveItemAtIndexPath:self.indexPathOfItemLastExchanged toIndexPath:self.currentIndexPath];
        [self.collectionView moveItemAtIndexPath:self.currentIndexPath toIndexPath:self.originalIndexPathForItemBeingDragged];
        
        // State...
        self.indexPathOfItemLastExchanged = self.currentIndexPath;
        self.mustUndoPriorExchange = YES;
        
        [self keepCenterOfCellForLastItemExchangedAtIndexPath:self.currentIndexPath];
        
    } completion:nil];
}

- (void)performExchangeEventTypeDraggedToStartingItem {
    
    [self.collectionView performBatchUpdates:^{
        
        // Model...
        [self.delegate exchangeItemAtIndexPath:self.originalIndexPathForItemBeingDragged withItemAtIndexPath:self.indexPathOfItemLastExchanged];
        [self.delegate didFinishExchangeEvent];
        
        // View...
        [self.collectionView moveItemAtIndexPath:self.originalIndexPathForItemBeingDragged toIndexPath:self.indexPathOfItemLastExchanged];
        [self.collectionView moveItemAtIndexPath:self.indexPathOfItemLastExchanged toIndexPath:self.originalIndexPathForItemBeingDragged];
        
        // State...
        self.indexPathOfItemLastExchanged = self.originalIndexPathForItemBeingDragged;
        self.mustUndoPriorExchange = NO;
        
        [self keepCenterOfCellForLastItemExchangedAtIndexPath:self.currentIndexPath];
        
    } completion:nil];
}

- (void)finishExchangeTransaction {
    
    [self.delegate didFinishExchangeTransactionWithItemAtIndexPath:self.indexPathOfItemLastExchanged
                                                andItemAtIndexPath:self.originalIndexPathForItemBeingDragged];
    
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

- (ExchangeEventType)exchangeEventType {
    
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

- (UICollectionViewFlowLayout *)layout {
    
    return (UICollectionViewFlowLayout *) self.collectionView.collectionViewLayout;
}



//--------------------------------------------------------------------------------
#pragma mark - SSCollectionViewExchangeLayoutDelegate methods...

- (NSIndexPath *)indexPathForItemToHide {
    
    return self.indexPathOfItemLastExchanged;
    
    // Return nil if you don't want to hide.
    // This can be useful during testing to ensure that the item
    // you're dragging around is properly following.

}

- (NSIndexPath *)indexPathForItemToDim {
    
    return self.originalIndexPathForItemBeingDragged;

    // As above return nil if you don't want to dim.

}



@end
