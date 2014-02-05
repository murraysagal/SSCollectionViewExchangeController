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
#import "UIView+SSCollectionViewExchangeControllerAdditions.h"


typedef NS_ENUM(NSInteger, ExchangeEventType) {
    ExchangeEventTypeDraggedFromStartingItem,
    ExchangeEventTypeDraggedToOtherItem,
    ExchangeEventTypeDraggedToStartingItem,
    ExchangeEventTypeNothingToExchange,
    ExchangeEventTypeCannotDisplaceItem
};



@interface SSCollectionViewExchangeController () <SSCollectionViewExchangeLayoutDelegate>

@property (weak, nonatomic)             id<SSCollectionViewExchangeControllerDelegate> delegate;            // the delegate, which must conform to the SSCollectionViewExchangeControllerDelegate protocol

@property (weak, nonatomic)             UICollectionView                *collectionView;                    // the collection view that this exchange controller responds to

@property (weak, nonatomic, readwrite)  UILongPressGestureRecognizer    *longPressGestureRecognizer;        // exposed as readonly in the header to allow configuration if required
@property (nonatomic)                   CGPoint                         locationInCollectionView;           // the last known location of the long press

@property (strong, nonatomic)           UIView                          *snapshot;                          // this is the view that follows the user's finger during the long press
@property (nonatomic)                   CGPoint                         offsetToCenterOfSnapshot;           // for the snapshot, this is the offset from the location of the long press to its center

@property (strong, nonatomic)           NSIndexPath                     *originalIndexPathForDraggedItem;   // the index path where the exchange transaction began
@property (strong, nonatomic)           NSIndexPath                     *originalIndexPathForDisplacedItem; // the original index path for the item most recently displaced item
@property (strong, nonatomic)           NSIndexPath                     *currentIndexPath;                  // the index path for the item under locationInCollectionView

@property (nonatomic, assign)           BOOL                            mustUndoPriorExchange;              // for each exchange, tells the exchange controller if a prior exchange must be undone first
@property (nonatomic, assign)           BOOL                            longPressWasManuallyCancelled;      // in some cases the exchange controller needs to cancel the gesture recognizer, this flag distinguishes those cases from cases where the system cancels the recognizer
@property (nonatomic, assign, readwrite) BOOL                           exchangeTransactionInProgress;      // exposed as readonly in the header to allow the delegate to determine if an exchange transaction is in progress

@property (nonatomic, copy)             PostReleaseCompletionBlock      postReleaseCompletionBlock;         // refer to the comments in the header file

@property (strong, nonatomic)           NSIndexPath                     *indexPathForItemLastChecked;       // refer to the comments in delegateAllowsDisplacingItemAtIndexPath:withItemFromIndexPath:
@property (nonatomic, assign)           BOOL                            resultForItemLastChecked;           // ditto


// At the end of the exchange transation the snapshot is animated to the center of the cell
// that is hidden. But, as an optimization, the collection view does not create the view for cells
// that are hidden. So the center can't be determined at that time. So this property is set at
// the end of each exchange event just before the layout hides the item.
@property (nonatomic)                   CGPoint                         centerOfHiddenCell;

@end


@implementation SSCollectionViewExchangeController

- (id)initWithDelegate:(id<SSCollectionViewExchangeControllerDelegate>)delegate
        collectionView:(UICollectionView *)collectionView
{
    self = [super init];
    if (self) {
        
        // defaults...
        _alphaForDisplacedItem =        0.60;
        _animationDuration =            0.20;
        _blinkToScaleForCatch =         1.20;
        _blinkToScaleForRelease =       1.05;
        _animationBacklogDelay =        0.50;
        _snapshotAlpha =                0.80;
        _snapshotBackgroundColor =      [UIColor darkGrayColor];
        _longPressWasManuallyCancelled = NO;
        
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress)];
        longPress.minimumPressDuration = 0.15;
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
            [self updateSnapshotLocation];
            [self performExchangeEventType];
            break;
            
        case UIGestureRecognizerStateEnded:
            [self finishExchangeTransaction];
            break;
            
        case UIGestureRecognizerStateCancelled:
            [self cancelExchangeTransaction];
            break;
            
        case UIGestureRecognizerStatePossible:
            NSLog(@"UIGestureRecognizerStatePossible");
            break;
            
        case UIGestureRecognizerStateFailed:
            NSLog(@"UIGestureRecognizerStateFailed");
            break;
    }
}

- (void)beginExchangeTransaction {
    
    NSIndexPath *startingIndexPath = [self.collectionView indexPathForItemAtPoint:self.locationInCollectionView];
    
    if ([self cannotBeginExchangeTransactionWithItemAtIndexPath:startingIndexPath]) {
        [self cancelLongPressRecognizer];
        return;
    }
    
    self.exchangeTransactionInProgress = YES;
    self.indexPathForItemLastChecked = nil;
    
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:startingIndexPath];
    UIView *snapshot = [self snapshotForCell:cell];
    [self.collectionView addSubview:snapshot];
    
    [self animateCatch:snapshot];
    
    CGPoint locationInCell = [self.longPressGestureRecognizer locationInView:cell];
    self.offsetToCenterOfSnapshot = [cell offsetToCenterFromPoint:locationInCell];
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
    
    if (![self delegateAllowsDisplacingItemAtIndexPath:self.currentIndexPath
                                 withItemFromIndexPath:self.originalIndexPathForDraggedItem]) {
        return ExchangeEventTypeCannotDisplaceItem;
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
            
        case ExchangeEventTypeCannotDisplaceItem:
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
        [self ensureItemsToMoveAreFrontMost];
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
        [self ensureItemsToMoveAreFrontMost];
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
        [self ensureItemsToMoveAreFrontMost];
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

- (void)cancelExchangeTransaction {
    
    // In certain circumstances the exchange controller can manually cancel the gesture recognizer.
    // This needs to be distinguished from system events, like an incoming phone call, that can
    // also cancel the gesture recognizer.
    
    if (self.longPressWasManuallyCancelled) {

        self.longPressWasManuallyCancelled = NO;
        
    } else {
        
        // Control reaches here, for example, if the user gets a phone call in the middle of the long press.
        
        // So the delegate can undo the last exchange in its model and thus
        // return it to its pre-exchange transaction state...
        [self.delegate exchangeController:self
              didExchangeItemAtIndexPath1:self.originalIndexPathForDisplacedItem
                     withItemAtIndexPath2:self.originalIndexPathForDraggedItem];
        
        // So the delegate has an opportunity to update its view...
        [self.delegate exchangeControllerDidCancelExchangeTransaction:self];
        
        self.originalIndexPathForDisplacedItem = nil;
        self.originalIndexPathForDraggedItem = nil;
        [self.snapshot removeFromSuperview];
        self.exchangeTransactionInProgress = NO;
        
        // Why delay? Refer to the comments for the animationBacklogDelay property in the .h file.
        [self performBlock:^{ [self.collectionView reloadData]; }
                afterDelay:self.animationBacklogDelay];
    }
}



//---------------------------------------
#pragma mark - Exchange helper methods...

- (void)cancelLongPressRecognizer {
    
    self.longPressWasManuallyCancelled = YES;
    self.longPressGestureRecognizer.enabled = NO;
    self.longPressGestureRecognizer.enabled = YES;
    
}

- (BOOL)canBeginExchangeTransactionWithItemAtIndexPath:(NSIndexPath *)indexPath {

    // There are several conditions that must be true to begin a transaction...
    //  1. indexPath must not be nil
    //  2. the location (of the user's finger) must be in the catch rectangle
    //  3. the delegate allows the exchange to begin

    if (indexPath == nil) return NO;
    if ([self locationIsInCatchRectangleForItemAtIndexPath:indexPath] == NO) return NO;
    if ([self delegateAllowsExchangeToBeginWithItemAtIndexPath:indexPath] == NO) return NO;
    
    // Otherwise...
    return YES;
}

- (BOOL)cannotBeginExchangeTransactionWithItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return ![self canBeginExchangeTransactionWithItemAtIndexPath:indexPath];
    
}

- (BOOL)delegateAllowsExchangeToBeginWithItemAtIndexPath:(NSIndexPath *)indexPath {
    
    BOOL delegateAllowsExchangeToBeginWithItemAtIndexPath = YES;
    
    if ([self.delegate respondsToSelector:@selector(exchangeControllerCanBeginExchangeTransaction:withItemAtIndexPath:)]) {
        delegateAllowsExchangeToBeginWithItemAtIndexPath = [self.delegate exchangeControllerCanBeginExchangeTransaction:self
                                                                                                    withItemAtIndexPath:indexPath];
    }
    
    return delegateAllowsExchangeToBeginWithItemAtIndexPath;
}

- (BOOL)delegateAllowsDisplacingItemAtIndexPath:(NSIndexPath *)indexPathForItemToDisplace
                          withItemFromIndexPath:(NSIndexPath *)indexPathOfItemBeingDragged {
    
    // This if() is here to prevent repeated calls to the delegate. With this if() the delegate
    // is asked only once until indexPathForItemToDisplace changes.
    
    // ???: does self.indexPathForItemLastChecked need to be cleared at the end (or at the beginning)???
    if ([indexPathForItemToDisplace isEqual:self.indexPathForItemLastChecked]) {
        
        return self.resultForItemLastChecked;
        
    } else {
        
        self.indexPathForItemLastChecked = indexPathForItemToDisplace;
        
        BOOL delegateAllowsDisplacingItemAtIndexPath = YES;
        
        if ([self.delegate respondsToSelector:@selector(exchangeController:canDisplaceItemAtIndexPath:withItemBeingDraggedFromIndexPath:)]) {
            delegateAllowsDisplacingItemAtIndexPath = [self.delegate exchangeController:self
                                                             canDisplaceItemAtIndexPath:indexPathForItemToDisplace
                                                      withItemBeingDraggedFromIndexPath:indexPathOfItemBeingDragged];
        }
        
        self.resultForItemLastChecked = delegateAllowsDisplacingItemAtIndexPath;
        return delegateAllowsDisplacingItemAtIndexPath;
    }
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
        locationIsInCatchRectangle = [viewForCatchRectangle pointInside:locationInCatchRectangle withEvent:nil];
        
    } else {
        
        locationIsInCatchRectangle = YES;
        
    }
    
    return locationIsInCatchRectangle;
    
}

- (void)ensureItemsToMoveAreFrontMost {
    
    // It can happen that the cells being exchanged are not the frontmost in the view. In that case
    // the move animations are obscured behind other collection view items.
    
    UICollectionViewCell *cell;
    
    cell = [self.collectionView cellForItemAtIndexPath:self.originalIndexPathForDraggedItem];
    [self.collectionView bringSubviewToFront:cell];
    
    cell = [self.collectionView cellForItemAtIndexPath:self.currentIndexPath];
    [self.collectionView bringSubviewToFront:cell];
    
    [self.collectionView bringSubviewToFront:self.snapshot];
    
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
        
        BOOL shouldApplyBackgroundColor = self.snapshotBackgroundColor != nil;
        UIColor *originalBackgroundColor;
        
        if (shouldApplyBackgroundColor) {
            originalBackgroundColor = cell.backgroundColor;
            cell.backgroundColor = self.snapshotBackgroundColor;
        }
        
        float originalAlpha = cell.alpha;
        cell.alpha = self.snapshotAlpha;
        UIView *snapshot = [cell snapshotViewAfterScreenUpdates:YES];
        snapshot.frame = cell.frame;
        
        if (shouldApplyBackgroundColor) {
            cell.backgroundColor = originalBackgroundColor;
        }
        
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
    
    self.longPressGestureRecognizer.enabled = NO;

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

- (void)performBlock:(void (^) ())block afterDelay:(double)delay {
    
    double delayInSeconds = delay;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        block();
    });
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
            weakSelf.snapshot = nil;
            self.longPressGestureRecognizer.enabled = YES;
        }];
    };
}



//--------------------------------------------------------------
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
