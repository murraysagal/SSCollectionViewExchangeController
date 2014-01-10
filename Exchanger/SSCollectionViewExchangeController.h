//
//  SSCollectionViewExchangeController.h
//  Exchanger
//
//  Created by Murray Sagal on 1/9/2014.
//  Copyright (c) 2014 Murray Sagal. All rights reserved.
//

/*
 
 SSCollectionViewExchangeController is designed to exchange 2 collection view items
 in a 2 column grid. It creates a custom layout object, SSCollectionViewExchangeLayout,
 that manages the hiding and dimming of items in the collection view.
 
 
        ---------------------
        |                   |       delegate
        |  ViewController   | <---------------------
     ---|                   |                       |
    |   ---------------------                       |
    |        |                                      |
    |        |                       -----------------------------------------
    |        |  @property (strong)   |                                       |
    |        ----------------------->|   SSCollectionViewExchangeController  |
    |                                |                                       |
    |                                -----------------------------------------
    |                                                   |
    |                                                   |
    |                                                   |
    |   ------------------------        -----------------------------------------
    |   |                      |        |                                       |
     -->|   UICollectionView   |<-------|   SSCollectionViewExchangeLayout      |
        |                      |        |                                       |
        ------------------------        -----------------------------------------
 
 Exchange Transactions and Exchange Events
 
 An exchange transaction begins with a long press on an item and concludes when the user releases,
 normally over another item, causing the two to be exchanged. However, between the beginning and
 the end the user may drag over many items including, possibly, the starting position.
 
 An exchange event occurs each time the user's finger moves to a different item. If it is the first
 exchange event it is a simple exchange between the item being dragged and the item dragged to.
 If the user keeps dragging to new items subsequent exchange events include undoing the previous
 exchange and then performing the new exchange.
 
 
 Usage
 
 1. In your view controller import SSCollectionViewExchangeController like this...
        #import "SSCollectionViewExchangeController.h"
 
 2. Adopt the SSCollectionViewExchangeControllerDelegate protocol...
        <SSCollectionViewExchangeControllerDelegate>

 3. Create a property for the exchange controller...
        @property (strong, nonatomic) SSCollectionViewExchangeController *exchangeController;
 
 4. In viewDidLoad create an instance of SSCollectionViewExchangeController...
        self.exchangeController = [[SSCollectionViewExchangeController alloc] initWithDelegate:self
                                                                                collectionView:self.collectionView];

 5. Get the layout and configure it as required...
        UICollectionViewFlowLayout *layout = self.exchangeController.layout;
        layout.itemSize = CGSizeMake(150, 30);
        ...
 
 */



#import <UIKit/UIKit.h>

@protocol SSCollectionViewExchangeControllerDelegate

- (void)exchangeItemAtIndexPath:(NSIndexPath *)firstItem withItemAtIndexPath:(NSIndexPath *)secondItem;
// Called whenever an exchange event occurs during an exchange transaction. This method
// provides the delegate with an opportunity to update the model as the user is dragging. This method
// may be called twice during a single exchange event. If so, the first call will be to undo a prior
// exchange and the second call will be for the new exchange. In all cases the delegate should just
// update the model by exchanging the elements at the indicated index paths.


- (void)didFinishExchangeEvent;
// Called when an exchange event finishes within an exchange transaction. This method
// provides the delegate with an opportunity to perform live updating as the user drags.


- (void)didFinishExchangeTransactionWithItemAtIndexPath:(NSIndexPath *)firstItem andItemAtIndexPath:(NSIndexPath *)secondItem;
// Called when the exchange transaction completes (the user lifts his/her finger). The
// index paths represent the two items that were finally exchanged. This allows the delegate
// to setup for undo, for example. If the user dragged back to the starting position and
// released (effectively nothing was exchanged) the index paths will be the same.


- (BOOL)canExchange;
// Called before beginning the exchange transaction to determine if it is ok to allow exchanges.

@end


@interface SSCollectionViewExchangeController : NSObject

- (instancetype)initWithDelegate:(id<SSCollectionViewExchangeControllerDelegate>)delegate
                  collectionView:(UICollectionView *)collectionView;

- (UICollectionViewFlowLayout *)layout;

@end
