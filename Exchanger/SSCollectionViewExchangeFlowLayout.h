//
//  SSCollectionViewExchangeFlowLayout.h
//  Exchanger
//
//  Created by Murray Sagal on 2012-10-31.
//  Copyright (c) 2012 Signature Software. All rights reserved.
//

#import <UIKit/UIKit.h>


// This UICollectionViewFlowLayout subclass implements a layout designed to
// exchange 2 items in a 2 column grid.


@protocol SSCollectionViewExchangeFlowLayoutDelegate// <UICollectionViewDelegate>

// Exchange Transactions and Exchange Events
// An exchange transaction begins with a long press on an item and concludes when the user releases,
// normally over another item, causing the two to be exchanged. However, between the beginning and
// the end the user may drag over many other items including, possibly, the starting position. An
// exchange event occurs each time the user's finger moves to a different item,
// including possibly back to its original position. If it is the first exchange event it is a simple
// exchange between the item being dragged and the item dragged to. If the user keeps dragging to
// new items subsequent exchange events include undoing the previous exchange and then performing
// the new exchange.

@required

- (void)exchangeItemAtIndexPath:(NSIndexPath *)firstItem withItemAtIndexPath:(NSIndexPath *)secondItem;
// Called on the delegate whenever an exchange event occurs during an exchange transaction. This method
// provides the delegate with an opportunity to update the model as the user is dragging. This method
// may be called twice during a single exchange event. If so, the first call will be to undo a prior
// exchange and the second call will be for the new exchange. In all cases the delegate should just
// update the model by exchanging the elements at the indicated index paths.


- (void)didFinishExchangeEvent;
// Called on the delegate when an exchange event finishes within an exchange transaction. This method
// provides the delegate with an opportunity to perform live updating as the user drags.


- (void)didFinishExchangeTransactionWithItemAtIndexPath:(NSIndexPath *)firstItem andItemAtIndexPath:(NSIndexPath *)secondItem;
// Called on the delegate when the exchange transaction completes (the user lifts his/her finger). The
// index paths represent the two items that were finally exchanged. If the index paths are nil it means
// the user dragged back to the starting position and released (so nothing was exchanged). This method
// allows the delegate to setup for undo, for example.


- (BOOL)canExchange;
// Called on the delegate before beginning the exchange transaction to determine if it is ok to allow exchanges.

@end


@interface SSCollectionViewExchangeFlowLayout : UICollectionViewFlowLayout

- (id)initWithDelegate:(id<SSCollectionViewExchangeFlowLayoutDelegate>)delegate
        collectionView:(UICollectionView *)collectionView
   longPressRecognizer:(UILongPressGestureRecognizer *)longPressRecognizer;

@end
