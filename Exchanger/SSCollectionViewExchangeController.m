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
@property (nonatomic)           CGPoint             offsetToCenter;

// This helps safeguard against the documented behaviour regarding items that are hidden.
// As an optimization, the collection view might not create the corresponding view
// if the hidden property (UICollectionViewLayoutAttributes) is set to YES. In the
// gesture recognizer's ended state we always need the cell for the item that
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
        
        // defaults...
        _minimumPressDuration =     0.15;
        _alphaForDimmedItem =       0.60;
        _animationDuration =        0.20;
        _blinkToScaleForCatch =     1.20;
        _blinkToScaleForRelease =   1.05;
        _alphaForImage =            0.80;
        _backgroundColorForImage =  [UIColor darkGrayColor];
        
        
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress)];
        _longPressGestureRecognizer.minimumPressDuration = _minimumPressDuration;
        _longPressGestureRecognizer.delaysTouchesBegan = YES;
        [collectionView addGestureRecognizer:_longPressGestureRecognizer];
        
        collectionView.collectionViewLayout = [[SSCollectionViewExchangeLayout alloc] initWithDelegate:self];
        
        _collectionView = collectionView;
        _delegate = delegate;
    }
    return self;
}



//-------------------------
#pragma mark - Accessors...

- (void)setMinimumPressDuration:(CFTimeInterval)minimumPressDuration {
    
    if (_minimumPressDuration != minimumPressDuration) {
        _minimumPressDuration = minimumPressDuration;
        self.longPressGestureRecognizer.minimumPressDuration = minimumPressDuration;
    }
}

- (UICollectionViewFlowLayout *)layout {
    
    return (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
}



//-------------------------------------------------------------------------------
#pragma mark - UILongPressGestureRecognizer action method and exchange methods...

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

- (void)beginExchangeTransaction {
    
    NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint:self.locationInCollectionView];
    
    if ([self shouldNotContinueExchangeTransactionAtIndexPath:currentIndexPath]) {
        [self cancelLongPressRecognizer];
        return;
    }
    
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:currentIndexPath];
    UIImageView *cellImageView = [self imageViewForCell:cell];
    [self.collectionView addSubview:cellImageView];
    
    self.offsetToCenter = [self offsetToCenterForCellImageView:cellImageView];
    self.viewForImageBeingDragged = cellImageView;
    self.centerOfCellForLastItemExchanged = cell.center;
    self.originalIndexPathForItemBeingDragged = currentIndexPath;
    self.indexPathOfItemLastExchanged = currentIndexPath;
    self.mustUndoPriorExchange = NO;
    
    [self animateCatch:cellImageView];
    
    // InvalidateLayout kicks off the process of redrawing the layout.
    // SSCollectionViewExchangeLayout intervenes in that process by overriding
    // layoutAttributesForElementsInRect: and layoutAttributesForItemAtIndexPath:
    // to hide and dim collection view items as required.
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)updateCellImageLocation {
    
    CGPoint offsetLocationInCollectionView = CGPointMake(self.locationInCollectionView.x - self.offsetToCenter.x, self.locationInCollectionView.y - self.offsetToCenter.y);
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

- (ExchangeEventType)exchangeEventType {
    
    // The user is still dragging in the long press. Determine the exchange event type.
    self.currentIndexPath = [self.collectionView indexPathForItemAtPoint:self.locationInCollectionView];
    
    if  (self.currentIndexPath == nil || [self isOverSameItemAtIndexPath:self.currentIndexPath])
        return ExchangeEventTypeNothingToExchange;
    
    
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

- (void)performExchangeEventTypeDraggedFromStartingItem {
    
    [self.collectionView performBatchUpdates:^{
        
        // Model...
        [self.delegate exchangeController:self
                 exchangeItemAtIndexPath1:self.currentIndexPath
                     withItemAtIndexPath2:self.originalIndexPathForItemBeingDragged];
        [self.delegate exchangeControllerDidFinishExchangeEvent:self];
        
        // View...
        [self.collectionView moveItemAtIndexPath:self.originalIndexPathForItemBeingDragged toIndexPath:self.currentIndexPath];
        [self.collectionView moveItemAtIndexPath:self.currentIndexPath toIndexPath:self.originalIndexPathForItemBeingDragged];
        
        // State...
        self.indexPathOfItemLastExchanged = self.currentIndexPath;
        self.mustUndoPriorExchange = YES;
        [self keepCenterOfCellForLastItemExchanged];
        
    } completion:nil];
}

- (void)performExchangeEventTypeDraggedToOtherItem {
    
    [self.collectionView performBatchUpdates:^{
        
        // Model...
        [self.delegate exchangeController:self
                 exchangeItemAtIndexPath1:self.originalIndexPathForItemBeingDragged
                     withItemAtIndexPath2:self.indexPathOfItemLastExchanged];
        [self.delegate exchangeController:self
                 exchangeItemAtIndexPath1:self.currentIndexPath
                     withItemAtIndexPath2:self.originalIndexPathForItemBeingDragged];
        [self.delegate exchangeControllerDidFinishExchangeEvent:self];
        
        // View...
        [self.collectionView moveItemAtIndexPath:self.originalIndexPathForItemBeingDragged toIndexPath:self.indexPathOfItemLastExchanged];
        [self.collectionView moveItemAtIndexPath:self.indexPathOfItemLastExchanged toIndexPath:self.currentIndexPath];
        [self.collectionView moveItemAtIndexPath:self.currentIndexPath toIndexPath:self.originalIndexPathForItemBeingDragged];
        
        // State...
        self.indexPathOfItemLastExchanged = self.currentIndexPath;
        self.mustUndoPriorExchange = YES;
        [self keepCenterOfCellForLastItemExchanged];
        
    } completion:nil];
}

- (void)performExchangeEventTypeDraggedToStartingItem {
    
    [self.collectionView performBatchUpdates:^{
        
        // Model...
        [self.delegate exchangeController:self
                 exchangeItemAtIndexPath1:self.originalIndexPathForItemBeingDragged
                     withItemAtIndexPath2:self.indexPathOfItemLastExchanged];
        [self.delegate exchangeControllerDidFinishExchangeEvent:self];
        
        // View...
        [self.collectionView moveItemAtIndexPath:self.originalIndexPathForItemBeingDragged toIndexPath:self.indexPathOfItemLastExchanged];
        [self.collectionView moveItemAtIndexPath:self.indexPathOfItemLastExchanged toIndexPath:self.originalIndexPathForItemBeingDragged];
        
        // State...
        self.indexPathOfItemLastExchanged = self.originalIndexPathForItemBeingDragged;
        self.mustUndoPriorExchange = NO;
        [self keepCenterOfCellForLastItemExchanged];
        
    } completion:nil];
}

- (void)finishExchangeTransaction {
    
    [self.delegate exchangeControllerDidFinishExchangeTransaction:self
                                                   withIndexPath1:self.indexPathOfItemLastExchanged
                                                       indexPath2:self.originalIndexPathForItemBeingDragged];
    
    // Animate the release. This is one of any number of ways to accomplish this.
    // You can change the animation as you see fit but you must call
    // performPostReleaseCleanupWithAnimationDuration: in your final completion block.
    
    NSTimeInterval duration = self.animationDuration;
    CGFloat blinkToScale = self.blinkToScaleForCatch;
    CGFloat finalScale = 1.0;
    UICollectionViewCell *cellForOriginalLocation = [self.collectionView cellForItemAtIndexPath:self.originalIndexPathForItemBeingDragged];
    
    [UIView animateWithDuration:duration animations:^ {
        self.viewForImageBeingDragged.center = self.centerOfCellForLastItemExchanged;
        cellForOriginalLocation.alpha = 1.0;
    } completion:^(BOOL finished) {
        
        if ([self.delegate respondsToSelector:@selector(exchangeController:animateReleaseForImage:)]) {
            
            [self.delegate exchangeController:self animateReleaseForImage:self.viewForImageBeingDragged];
            
        } else {
            
            [UIView animateWithDuration:duration animations:^ {
                self.viewForImageBeingDragged.transform = CGAffineTransformMakeScale(blinkToScale, blinkToScale);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:duration animations:^ {
                    self.viewForImageBeingDragged.transform = CGAffineTransformMakeScale(finalScale, finalScale);
                } completion:^(BOOL finished) {
                    [self performPostReleaseCleanupWithAnimationDuration:duration];
                }];
            }];
        }
    }];
}



//---------------------------------------
#pragma mark - Exchange helper methods...

- (void)cancelLongPressRecognizer {
    
    // As per the docs, this triggers a cancel.
    
    self.longPressGestureRecognizer.enabled = NO;
    self.longPressGestureRecognizer.enabled = YES;
}

- (void)performPostReleaseCleanupWithAnimationDuration:(NSTimeInterval)duration {
    
    self.indexPathOfItemLastExchanged = nil;
    self.originalIndexPathForItemBeingDragged = nil;
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    [UIView animateWithDuration:duration animations:^{
        self.viewForImageBeingDragged.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.viewForImageBeingDragged removeFromSuperview];
    }];
}

- (BOOL)shouldNotContinueExchangeTransactionAtIndexPath:(NSIndexPath *)indexPath {
    
    return (indexPath != nil && [self.delegate exchangeControllerCanExchange:self])? NO:YES;
}

- (UIImageView *)imageViewForCell:(UICollectionViewCell *)cell {
    
    if ([self.delegate respondsToSelector:@selector(exchangeController:imageViewForCell:)]) {
        
        return [self.delegate exchangeController:self imageViewForCell:cell];
        
    } else {
        
        UIImage *cellImage = [self imageFromCell:cell withBackgroundColor:[UIColor darkGrayColor] alpha:0.8];
        UIImageView *cellImageView = [[UIImageView alloc] initWithImage:cellImage];
        cellImageView.frame = cell.frame;
        return cellImageView;
    }
}

- (CGPoint)offsetToCenterForCellImageView:(UIImageView *)cellImageView {
    
    CGPoint locationInCellImageView = [self.longPressGestureRecognizer locationInView:cellImageView];
    CGPoint cellImageViewCenter = CGPointMake(cellImageView.frame.size.width/2, cellImageView.frame.size.height/2);
    return CGPointMake(locationInCellImageView.x - cellImageViewCenter.x, locationInCellImageView.y - cellImageViewCenter.y);
}

- (void)animateCatch:(UIImageView *)cellImage {
    
    if ([self.delegate respondsToSelector:@selector(exchangeController:animateCatchForImage:)]) {
        
        [self.delegate exchangeController:self animateCatchForImage:cellImage];
        
    } else {
        
        NSTimeInterval duration = 0.20;
        CGFloat blinkToScale = 1.2;
        CGFloat finalScale = 1.0;
        
        [UIView animateWithDuration:duration animations:^ {
            cellImage.transform = CGAffineTransformMakeScale(blinkToScale, blinkToScale);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:duration animations:^ {
                cellImage.transform = CGAffineTransformMakeScale(finalScale, finalScale);
            }];
        }];
    }
}

- (BOOL)isOverSameItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return [indexPath isEqual:self.indexPathOfItemLastExchanged];
}

- (BOOL)isBackToStartingItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return [indexPath isEqual:self.originalIndexPathForItemBeingDragged];
}

- (void)keepCenterOfCellForLastItemExchanged {
    
    UICollectionViewCell *itemCell = [self.collectionView cellForItemAtIndexPath:self.currentIndexPath];
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

- (CGPoint)locationInCollectionView {
    
    return [self.longPressGestureRecognizer locationInView:self.collectionView];
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

- (CGFloat)alphaForDimmedItem {
    
    return _alphaForDimmedItem;
}



@end
