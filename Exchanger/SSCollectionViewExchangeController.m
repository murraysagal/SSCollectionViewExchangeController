//
//  SSCollectionViewExchangeController.m
//  Exchanger
//
//  Created by Murray Sagal on 1/9/2014.
//  Copyright (c) 2014 Signature Software. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.



#import "SSCollectionViewExchangeController.h"
#import "SSCollectionViewExchangeLayout.h"
#import "UIGestureRecognizer+SSCollectionViewExchangeControllerAdditions.h"


typedef NS_ENUM(NSInteger, ExchangeEventType) {
    ExchangeEventTypeDraggedFromStartingItem,
    ExchangeEventTypeDraggedToOtherItem,
    ExchangeEventTypeDraggedToStartingItem,
    ExchangeEventTypeNothingToExchange
};



@interface SSCollectionViewExchangeController () <SSCollectionViewExchangeLayoutDelegate>

@property (weak, nonatomic)     id<SSCollectionViewExchangeControllerDelegate> delegate;

@property (weak, nonatomic)     UICollectionView    *collectionView;
@property (strong, nonatomic)   UIView              *snapshot;
@property (nonatomic)           CGPoint             locationInCollectionView;
@property (strong, nonatomic)   NSIndexPath         *originalIndexPathForDraggedItem;
@property (strong, nonatomic)   NSIndexPath         *originalIndexPathForDisplacedItem;
@property (strong, nonatomic)   NSIndexPath         *currentIndexPath;
@property (nonatomic)           BOOL                mustUndoPriorExchange;

@property (weak, nonatomic)     UILongPressGestureRecognizer    *longPressGestureRecognizer;
@property (nonatomic, copy)     PostReleaseCompletionBlock      postReleaseCompletionBlock;

// For the view being dragged, this is the offset from the location of the long press to its center...
@property (nonatomic)           CGPoint             offsetToCenterOfSnapshot;

// At the end of the exchange transation the snapshot is animated to the center of the cell
// that is hidden. But, as an optimization, the collection view does not create the view for cells
// that are hidden. So the center can't be determined at that time. So this property is set at
// the end of each exchange event just before the layout hides the item.
@property (nonatomic)           CGPoint             centerOfHiddenCell;

@property (nonatomic, readwrite) BOOL               exchangeTransactionInProgress;

@end


@implementation SSCollectionViewExchangeController

- (id)initWithDelegate:(id<SSCollectionViewExchangeControllerDelegate>)delegate
        collectionView:(UICollectionView *)collectionView
{
    self = [super init];
    if (self) {
        
        // defaults...
        _minimumPressDuration =     0.15;
        _alphaForDisplacedItem =    0.60;
        _animationDuration =        0.20;
        _blinkToScaleForCatch =     1.20;
        _blinkToScaleForRelease =   1.05;
        _snapshotAlpha =            0.80;
        _snapshotBackgroundColor =  [UIColor darkGrayColor];
        
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress)];
        longPress.minimumPressDuration = _minimumPressDuration;
        longPress.delaysTouchesBegan = YES;
        [collectionView addGestureRecognizer:longPress];
        
        collectionView.collectionViewLayout = [[SSCollectionViewExchangeLayout alloc] initWithDelegate:self];
        
        _collectionView = collectionView;
        _longPressGestureRecognizer = longPress;
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

- (PostReleaseCompletionBlock)postReleaseCompletionBlock {
    
    __weak SSCollectionViewExchangeController *weakSelf = self;
    
    return ^ void (NSTimeInterval duration) {
        
        weakSelf.originalIndexPathForDisplacedItem = nil;
        weakSelf.originalIndexPathForDraggedItem = nil;
        [weakSelf.collectionView.collectionViewLayout invalidateLayout];
        
        [UIView animateWithDuration:duration animations:^ {
            weakSelf.snapshot.alpha = 0.0;
        } completion:^(BOOL finished) {
            [weakSelf.snapshot removeFromSuperview];
        }];
    };
}



//-------------------------------------------------------------------------------
#pragma mark - UILongPressGestureRecognizer action method and exchange methods...

- (void)longPress {
    
    switch (self.longPressGestureRecognizer.state) {
            
        case UIGestureRecognizerStateBegan:
            [self beginExchangeTransaction];
            break;
            
        case UIGestureRecognizerStateChanged:
            [self updateSnapshotLocation];
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
    
    NSIndexPath *startingIndexPath = [self.collectionView indexPathForItemAtPoint:self.locationInCollectionView];
    
    if ([self shouldNotContinueExchangeTransactionAtIndexPath:startingIndexPath]) {
        [self cancelLongPressRecognizer];
        return;
    }
    
    self.exchangeTransactionInProgress = YES;
    
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:startingIndexPath];
    UIView *snapshot = [self snapshotForCell:cell];
    [self.collectionView addSubview:snapshot];
    
    [self animateCatch:snapshot];
    
    self.offsetToCenterOfSnapshot = [self.longPressGestureRecognizer offsetFromLocationToCenterForView:cell];
    self.snapshot = snapshot;
    self.centerOfHiddenCell = cell.center;
    self.originalIndexPathForDraggedItem = startingIndexPath;
    self.originalIndexPathForDisplacedItem = startingIndexPath;
    self.mustUndoPriorExchange = NO;
    
    // InvalidateLayout kicks off the process of redrawing the layout.
    // SSCollectionViewExchangeLayout intervenes in that process by overriding
    // layoutAttributesForElementsInRect: and layoutAttributesForItemAtIndexPath:
    // to hide and dim collection view items as required.
    [self.collectionView.collectionViewLayout invalidateLayout];
    
}

- (void)updateSnapshotLocation {
    
    CGPoint offsetLocationInCollectionView = CGPointMake(self.locationInCollectionView.x - self.offsetToCenterOfSnapshot.x, self.locationInCollectionView.y - self.offsetToCenterOfSnapshot.y);
    self.snapshot.center = offsetLocationInCollectionView;
}

- (ExchangeEventType)exchangeEventType {
    
    // The user is still dragging in the long press. Determine the exchange event type.
    
    self.currentIndexPath = [self.collectionView indexPathForItemAtPoint:self.locationInCollectionView];
    
    if  ([self isOverSameItemAtIndexPath:self.currentIndexPath] || self.currentIndexPath == nil) {
        return ExchangeEventTypeNothingToExchange;
    }
    
    
    // Otherwise there is an exchange event to perform. What kind?
    
    if (self.mustUndoPriorExchange) {
        
        return ([self isBackToStartingItemAtIndexPath:self.currentIndexPath])? ExchangeEventTypeDraggedToStartingItem : ExchangeEventTypeDraggedToOtherItem;
        
    } else {
        
        return ExchangeEventTypeDraggedFromStartingItem;
    }
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
        [self.delegate exchangeController:self
              didExchangeItemAtIndexPath1:self.currentIndexPath
                     withItemAtIndexPath2:self.originalIndexPathForDraggedItem];
        [self.delegate exchangeControllerDidFinishExchangeEvent:self];
        
        // View...
        [self.collectionView moveItemAtIndexPath:self.originalIndexPathForDraggedItem toIndexPath:self.currentIndexPath];
        [self.collectionView moveItemAtIndexPath:self.currentIndexPath toIndexPath:self.originalIndexPathForDraggedItem];
        
        [self setPostExchangeEventStateWithIndexPathForDisplacedItem:self.currentIndexPath undoFlag:YES];
        
    } completion:nil];
}


- (void)performExchangeEventTypeDraggedToOtherItem {
    
    [self.collectionView performBatchUpdates:^{
        
        // Model...
        [self.delegate exchangeController:self
              didExchangeItemAtIndexPath1:self.originalIndexPathForDraggedItem
                     withItemAtIndexPath2:self.originalIndexPathForDisplacedItem];
        [self.delegate exchangeController:self
              didExchangeItemAtIndexPath1:self.currentIndexPath
                     withItemAtIndexPath2:self.originalIndexPathForDraggedItem];
        [self.delegate exchangeControllerDidFinishExchangeEvent:self];
        
        // View...
        [self.collectionView moveItemAtIndexPath:self.originalIndexPathForDraggedItem toIndexPath:self.originalIndexPathForDisplacedItem];
        [self.collectionView moveItemAtIndexPath:self.originalIndexPathForDisplacedItem toIndexPath:self.currentIndexPath];
        [self.collectionView moveItemAtIndexPath:self.currentIndexPath toIndexPath:self.originalIndexPathForDraggedItem];
        
        [self setPostExchangeEventStateWithIndexPathForDisplacedItem:self.currentIndexPath undoFlag:YES];
        
    } completion:nil];
}

- (void)performExchangeEventTypeDraggedToStartingItem {
    
    [self.collectionView performBatchUpdates:^{
        
        // Model...
        [self.delegate exchangeController:self
              didExchangeItemAtIndexPath1:self.originalIndexPathForDraggedItem
                     withItemAtIndexPath2:self.originalIndexPathForDisplacedItem];
        [self.delegate exchangeControllerDidFinishExchangeEvent:self];
        
        // View...
        [self.collectionView moveItemAtIndexPath:self.originalIndexPathForDraggedItem toIndexPath:self.originalIndexPathForDisplacedItem];
        [self.collectionView moveItemAtIndexPath:self.originalIndexPathForDisplacedItem toIndexPath:self.originalIndexPathForDraggedItem];
        
        [self setPostExchangeEventStateWithIndexPathForDisplacedItem:self.self.originalIndexPathForDraggedItem undoFlag:NO];
        
    } completion:nil];
}

- (void)finishExchangeTransaction {
    
    [self.delegate exchangeControllerDidFinishExchangeTransaction:self
                                                   withIndexPath1:self.originalIndexPathForDisplacedItem
                                                       indexPath2:self.originalIndexPathForDraggedItem];
    [self animateRelease];
    
    self.exchangeTransactionInProgress = NO;
}


//---------------------------------------
#pragma mark - Exchange helper methods...

- (void)cancelLongPressRecognizer {
    
    self.longPressGestureRecognizer.enabled = NO;
    self.longPressGestureRecognizer.enabled = YES;
    
}

- (BOOL)shouldNotContinueExchangeTransactionAtIndexPath:(NSIndexPath *)indexPath {
    
    return !(indexPath && [self.delegate exchangeControllerCanExchange:self] && [self locationIsInCatchRectangleForItemAtIndexPath:indexPath]);
    
}

- (BOOL)locationIsInCatchRectangleForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    BOOL locationIsInCatchRectangle;
    UIView *viewForCatchRectangle;
    
    if ([self.delegate respondsToSelector:@selector(exchangeController:viewForCatchRectangleForItemAtIndexPath:)]) {

        viewForCatchRectangle = [self.delegate exchangeController:self
                          viewForCatchRectangleForItemAtIndexPath:indexPath];
        
    }
    
    if (viewForCatchRectangle) {
        
        CGPoint locationInCatchRectangle = [self.longPressGestureRecognizer locationInView:viewForCatchRectangle];
        locationIsInCatchRectangle = (locationInCatchRectangle.x < 0 ||
                                      locationInCatchRectangle.y < 0 ||
                                      locationInCatchRectangle.x > viewForCatchRectangle.frame.size.width ||
                                      locationInCatchRectangle.y > viewForCatchRectangle.frame.size.height)? NO:YES;
        
    } else {
        
        locationIsInCatchRectangle = YES;
        
    }
    
    return locationIsInCatchRectangle;
    
}

- (void)setPostExchangeEventStateWithIndexPathForDisplacedItem:(NSIndexPath *)indexPathForDisplacedItem
                                                      undoFlag:(BOOL)undoFlag {
    self.originalIndexPathForDisplacedItem = indexPathForDisplacedItem;
    self.mustUndoPriorExchange = undoFlag;
    self.centerOfHiddenCell = [self.collectionView cellForItemAtIndexPath:self.currentIndexPath].center;
}

- (UIView *)snapshotForCell:(UICollectionViewCell *)cell {
    
    if ([self.delegate respondsToSelector:@selector(exchangeController:snapshotForCell:)]) {
        
        return [self.delegate exchangeController:self snapshotForCell:cell];
        
    } else {
        
        UIColor *originalBackgroundColor = cell.backgroundColor;
        float originalAlpha = cell.alpha;
        cell.backgroundColor = self.snapshotBackgroundColor;
        cell.alpha = self.snapshotAlpha;
        UIView *snapshot = [cell snapshotViewAfterScreenUpdates:YES];
        snapshot.frame = cell.frame;
        cell.backgroundColor = originalBackgroundColor;
        cell.alpha = originalAlpha;
        return snapshot;
        
    }
}

- (void)animateCatch:(UIView *)snapshot {
    
    if ([self.delegate respondsToSelector:@selector(animateCatchForExchangeController:withSnapshot:)]) {
        
        [self.delegate animateCatchForExchangeController:self withSnapshot:snapshot];
        
    } else {
        
        NSTimeInterval duration = self.animationDuration;
        CGFloat blinkToScale = self.blinkToScaleForCatch;
        CGFloat finalScale = 1.0;
        
        [UIView animateWithDuration:duration animations:^ {
            snapshot.transform = CGAffineTransformMakeScale(blinkToScale, blinkToScale);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:duration animations:^ {
                snapshot.transform = CGAffineTransformMakeScale(finalScale, finalScale);
            }];
        }];
    }
}

- (void)animateRelease {
    
    UICollectionViewCell *cellForOriginalLocation = [self.collectionView cellForItemAtIndexPath:self.originalIndexPathForDraggedItem];
    
    if ([self.delegate respondsToSelector:@selector(animateReleaseForExchangeController:withSnapshot:toPoint:originalIndexPathForDraggedItem:completionBlock:)]) {
        
        [self.delegate animateReleaseForExchangeController:self
                                              withSnapshot:self.snapshot
                                                   toPoint:self.centerOfHiddenCell
                           originalIndexPathForDraggedItem:self.originalIndexPathForDraggedItem
                                           completionBlock:self.postReleaseCompletionBlock];
        
    } else {
        
        NSTimeInterval duration = self.animationDuration;
        CGFloat blinkToScale = self.blinkToScaleForRelease;
        CGFloat finalScale = 1.0;
        
        [UIView animateWithDuration:duration animations:^ {
            self.snapshot.center = self.centerOfHiddenCell;
            cellForOriginalLocation.alpha = 1.0;
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:duration animations:^ {
                self.snapshot.transform = CGAffineTransformMakeScale(blinkToScale, blinkToScale);
            } completion:^(BOOL finished) {
                
                [UIView animateWithDuration:duration animations:^ {
                    self.snapshot.transform = CGAffineTransformMakeScale(finalScale, finalScale);
                } completion:^(BOOL finished) {
                    self.postReleaseCompletionBlock(duration);
                }];
            }];
        }];
    }
}

- (BOOL)isOverSameItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return [indexPath isEqual:self.originalIndexPathForDisplacedItem];
}

- (BOOL)isBackToStartingItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return [indexPath isEqual:self.originalIndexPathForDraggedItem];
}

- (UIView *)snapshotForView:(UIView *)view
       withBackgroundColor:(UIColor *)backgroundColor
                      alpha:(float)alpha {
    
    UIColor *originalBackgroundColor = view.backgroundColor;
    float originialAlpha = view.alpha;
    view.backgroundColor = backgroundColor;
    view.alpha = alpha;
    UIView *snapshot = [view snapshotViewAfterScreenUpdates:YES];
    view.backgroundColor = originalBackgroundColor;
    view.alpha = originialAlpha;
    return snapshot;
    
}

- (CGPoint)locationInCollectionView {
    
    return [self.longPressGestureRecognizer locationInView:self.collectionView];
}



//--------------------------------------------------------------------------------
#pragma mark - SSCollectionViewExchangeLayoutDelegate methods...

- (NSIndexPath *)indexPathForItemToHide {
    
    return self.originalIndexPathForDisplacedItem;
    
    // Return nil if you don't want to hide.
    // This can be useful during testing to ensure that the item
    // you're dragging around is properly following.

}

- (NSIndexPath *)indexPathForItemToDim {
    
    return self.originalIndexPathForDraggedItem;

    // As above return nil if you don't want to dim.

}

- (CGFloat)alphaForItemToDim {
    
    return self.alphaForDisplacedItem;
}



@end
