//
//  SSSwappableCollectionViewFlowLayout.h
//  Swapper
//
//  Created by Murray Sagal on 2012-10-31.
//  Copyright (c) 2012 Signature Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol SSSwappableCollectionViewDelegateFlowLayout <UICollectionViewDelegate>

// Exchange Transaction and Exchange Event
// An exchange transaction begins with a long press on a cell and concludes when the user releases. Between
// the beginning and the end the user may drag over many other items including the position where it started.
// An exchange event occurs each time the user's finger moves over a different item, including possibly
// back to its original position. If it is the first exchange event it is a simple exchange between the item being
// dragged and the item dragged to. If the user keeps dragging to new items exchange events include undoing the
// previous exchange and then performing the new exchange.

@required

- (void)exchangeItemAtIndexPath:(NSIndexPath *)firstItem withItemAtIndexPath:(NSIndexPath *)secondItem;
// Called on the delegate whenever an exchange event occurs during an exchange transaction. This method
// provides the delegate with an opportunity to update the model. This method may be called twice during
// a single exchange event. If so, the first call will be to undo a prior exchange and the second call
// will be for the new exchange. In all cases the delegate should just update the model by exchanging
// the elements at the indicated index paths.


- (void)didFinishExchangeEvent;
// Called on the delegate when an exchange event finishes within an exchange transaction. At this point
// the delegate can update state knowing that changes to the model are finished for this exchange event.


- (void)didFinishExchangeTransactionWithItemAtIndexPath:(NSIndexPath *)firstItem andItemAtIndexPath:(NSIndexPath *)secondItem;
// Called on the delegate when the exchange transaction completes (the user lifts his/her finger). The
// index paths represent the two items that were finally exchanged. If the index paths are nil it means
// the user dragged back to the starting position and released (so nothing was really exchanged). This
// method allows the delegate to setup for undo.


- (BOOL)allowsExchange;
//C alled on the delegate to determine if it is ok to allow exchanges.

@end


@interface SSSwappableCollectionViewFlowLayout : UICollectionViewFlowLayout

@property (strong, nonatomic) id <SSSwappableCollectionViewDelegateFlowLayout> delegate;

@end
