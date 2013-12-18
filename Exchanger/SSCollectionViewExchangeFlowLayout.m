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
@property (strong, nonatomic) UIView *viewForItemBeingDragged;

// These contain the offset to the view's center...
@property (nonatomic) float xOffsetForViewBeingDragged;
@property (nonatomic) float yOffsetForViewBeingDragged;

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
        collectionView:(UICollectionView *)collectionView
{
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

- (void)longPress:(UILongPressGestureRecognizer *)sender
{
    switch (sender.state) {
            
        case UIGestureRecognizerStateBegan:
            [self setUpForExchangeTransaction:sender];
            break;
            
        case UIGestureRecognizerStateChanged:
            [self manageExchangeEvent:sender];
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
    CGPoint locationInCollectionView = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:locationInCollectionView];
    
    if ([self.delegate canExchange] == NO || indexPath == nil)
    {
        [self cancelGestureRecognizer:gestureRecognizer];
        return;
    }
    
    // Get the cell from the indexPath...
    UICollectionViewCell *itemCell = [self.collectionView cellForItemAtIndexPath:indexPath];
    
    // Create an image of the cell. This is what will follow the user's finger...
    UIColor *originalBackgroundColor = itemCell.backgroundColor;
    itemCell.backgroundColor = [UIColor darkGrayColor];
    itemCell.alpha = 0.8;
    UIGraphicsBeginImageContextWithOptions(itemCell.bounds.size, itemCell.opaque, 0.0f);
    [itemCell.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *itemCellImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageView *itemCellImageView = [[UIImageView alloc] initWithImage:itemCellImage];
    itemCell.backgroundColor = originalBackgroundColor;
    itemCell.alpha = 1.0;
    
    // Create a view and add the image...
    self.viewForItemBeingDragged = [[UIView alloc] initWithFrame:itemCell.frame];
    [self.viewForItemBeingDragged addSubview:itemCellImageView];
    
    // Add this view to the collection view...
    [self.collectionView addSubview:self.viewForItemBeingDragged];
    
    // Calculate and keep the offsets from the location of the user's finger to the center of view being dragged...
    CGPoint locationInCellImageView = [gestureRecognizer locationInView:self.viewForItemBeingDragged];
    
    // TODO: look at anchorPoint!!!
    CGPoint imageViewCenter = CGPointMake(self.viewForItemBeingDragged.frame.size.width/2, self.viewForItemBeingDragged.frame.size.height/2);
//    self.viewForItemBeingDragged.layer.anchorPoint
    
    // ???: could these two just be a point???
    self.xOffsetForViewBeingDragged = locationInCellImageView.x - imageViewCenter.x;
    self.yOffsetForViewBeingDragged = locationInCellImageView.y - imageViewCenter.y;
    
    // Blink. This is one of any number of ways to accomplish this.
    [UIView animateWithDuration:0.15 animations:^{
         self.viewForItemBeingDragged.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
     } completion:^(BOOL finished){
         [UIView animateWithDuration:0.25 animations:^{
              self.viewForItemBeingDragged.transform = CGAffineTransformMakeScale(1.05f, 1.05f);
          }];
     }];
    
    
    
    // See the comments for this property in the declaration...
    self.centerOfCellForLastItemExchanged = itemCell.center;
    
    // It is necessary to know where this started. Hang on to the indexPath...
    self.originalIndexPathForItemBeingDragged = indexPath;
    
    // Managing the values in these properties is critical to tracking the state of the exchange process.
    self.indexPathOfItemLastExchanged = self.originalIndexPathForItemBeingDragged;
    self.mustUndoPriorExchange = NO;
    
    // Finally, hide the item being dragged. invalidateLayout kicks off the process of redrawing the layout.
    // This class intervenes in that process by overriding layoutAttributesForElementsInRect: and
    // layoutAttributesForItemAtIndexPath: to hide and dim items as required.
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)manageExchangeEvent:(UIGestureRecognizer *)gestureRecognizer
{
    // Update the location of the view the user is dragging around...
    CGPoint locationInCollectionView = [gestureRecognizer locationInView:self.collectionView]; //this is where the finger is in the collection view's coordinate system
    CGPoint offsetLocationInCollectionView = CGPointMake(locationInCollectionView.x - self.xOffsetForViewBeingDragged, locationInCollectionView.y - self.yOffsetForViewBeingDragged);
    self.viewForItemBeingDragged.center = offsetLocationInCollectionView;
    
    // Where has the user dragged to on the collection view? What indexPath...
    NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint:locationInCollectionView];
    
    ExchangeEventType exchangeEventType = [self exchangeEventTypeForCurrentIndexPath:currentIndexPath];
    
    switch (exchangeEventType) {
            
        case ExchangeEventTypeNothingToExchange:
            return;
            break;
            
        case ExchangeEventTypeDraggedFromStartingItem:
            [self performExchangeForDraggedFromStartingItemToIndexPath:currentIndexPath];
            return;
            break;
            
        case ExchangeEventTypeDraggedToOtherItem:
            [self performExchangeForDraggedToOtherItemAtIndexPath:currentIndexPath];
            return;
            break;
            
        case ExchangeEventTypeDraggedToStartingItem:
            [self performExchangeForDraggedToStartingItemAtIndexPath:currentIndexPath];
            return;
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

- (void)keepCenterOfCellForLastItemExchangedAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *itemCell = [self.collectionView cellForItemAtIndexPath:indexPath];
    self.centerOfCellForLastItemExchanged = itemCell.center;
}

- (void)finishExchangeTransaction
{
    // Control reaches here when the user lifts his/her finger...
    
    NSLog(@"[<%@ %p> %@ line= %d]", [self class], self, NSStringFromSelector(_cmd), __LINE__);
    
    if ([self isBackToStartingItemAtIndexPath:self.indexPathOfItemLastExchanged] == YES) {
        
        // The user released after dragging back to the starting location.
        // So, in the end, nothing was exchanged.
        // Let the delegate know by passing nil in the indexPaths.
        [self.delegate didFinishExchangeTransactionWithItemAtIndexPath:nil andItemAtIndexPath:nil];
        
    } else {
        
        // There was an exchange. Let the delegate know that the transaction is finished.
        [self.delegate didFinishExchangeTransactionWithItemAtIndexPath:self.indexPathOfItemLastExchanged andItemAtIndexPath:self.originalIndexPathForItemBeingDragged];
        
        // Get the cell...
        UICollectionViewCell *cellForOriginalLocation = [self.collectionView cellForItemAtIndexPath:self.originalIndexPathForItemBeingDragged];
        
        
        // TODO: these animations are colliding!
        
        // Animate the undimming...
        [UIView animateWithDuration:0.4 animations:^{
//             cellForOriginalLocation.alpha = 0.1;
             cellForOriginalLocation.alpha = 1.0;
         }];
    }
    
    // Animate the release...
    // This is one of any number of ways to accomplish this.
    // But it's important to do the cleanup at the end.
    [UIView animateWithDuration:0.15 animations:^{
         self.viewForItemBeingDragged.center = self.centerOfCellForLastItemExchanged;
     } completion:^(BOOL finished){
         // Blink...
         [UIView animateWithDuration:0.3 animations:^{
              self.viewForItemBeingDragged.transform = CGAffineTransformMakeScale(1.08f, 1.08f);
          } completion:^(BOOL finished) {
              
              // Clean up...
              [self.viewForItemBeingDragged removeFromSuperview];
              
              // Set state so nothing is hidden or dimmed now...
              self.indexPathOfItemLastExchanged = nil;
              self.originalIndexPathForItemBeingDragged = nil;
              [self.collectionView.collectionViewLayout invalidateLayout];
              
          }];
     }];
}

- (BOOL)isOverSameItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [indexPath isEqual:self.indexPathOfItemLastExchanged];
}

- (BOOL)isOverNewItemAtIndexPath:(NSIndexPath *)indexPath // TODO: not called
{
    return ![indexPath isEqual:self.indexPathOfItemLastExchanged];
}

- (BOOL)isBackToStartingItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [indexPath isEqual:self.originalIndexPathForItemBeingDragged];
}

@end
