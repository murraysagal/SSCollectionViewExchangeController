//
//  SSCollectionViewExchangeController.h
//  Exchanger
//
//  Created by Murray Sagal on 1/9/2014.
//  Copyright (c) 2014 Murray Sagal. All rights reserved.
//

/*
 
 SSCollectionViewExchangeController manages the process of exchanging 2 collection view items. 
 It installs a gesture recognizer in your collection view and creates a custom layout object,
 SSCollectionViewExchangeLayout, that manages the hiding and dimming of items in the collection 
 view during the exchange process. Through the SSCollectionViewExchangeControllerDelegate protocol 
 your view controller is kept informed allowing you to keep your model in sync with the changes 
 occuring on the collection view and perform any kind of live updating required during the process.
 
 
 Conceptual Diagram...
 
        ---------------------
        |                   |       delegate
     ---|  ViewController   |<----------------------
    |   |                   |                       |
    |   ---------------------                       |
    |        |                                      |
    |        |                       ------------------------------------------
    |        |  @property (strong)   |                                        |
    |         ---------------------->|   SSCollectionViewExchangeController   |
    |                                |                                        |
    |                                ------------------------------------------
    |                                                   |
    |   ------------------------                        |
    |   |                      |                        V
     -->|   UICollectionView   |----    ---------------------------------------
        |                      |    |   |                                     |
        ------------------------     -->|   SSCollectionViewExchangeLayout    |
                                        |                                     |
                                        ---------------------------------------
 
 
 Exchange Transactions and Exchange Events...
 
 An exchange transaction begins with a long press on an item and concludes when the user releases,
 normally over another item, causing the two to be exchanged. However, between the beginning and
 the end the user may drag over many items including, possibly, the starting position.
 
 An exchange event occurs each time the user drags to a different item. If it is the first
 exchange event it is a simple exchange between the item being dragged and the item dragged to.
 If the user keeps dragging to new items subsequent exchange events include undoing the previous
 exchange and then performing the new exchange.
 
 
 Usage...
 
 1. In your view controller import SSCollectionViewExchangeController...
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
 
 
 6. Implement the protocol...
        - (BOOL)canExchange;
        - (void)exchangeItemAtIndexPath:(NSIndexPath *)indexPath1 withItemAtIndexPath:(NSIndexPath *)indexPath2;
        - (void)didFinishExchangeEvent;
        - (void)didFinishExchangeTransactionWithItemAtIndexPath:(NSIndexPath *)firstItem andItemAtIndexPath:(NSIndexPath *)secondItem;
 
 
 7. Optional. This example app contains a category on NSMutableArray that implements a method for 
    exchanging two items that can be in different arrays. You can import that category and use
    the method in the exchangeItemAtIndexPath:withItemAtIndexPath: delegate method.
 
        [NSMutableArray exchangeItemInArray:array1
                                    atIndex:indexPath1.item
                            withItemInArray:array2
                                    atIndex:indexPath2.item];
 
    Note: see the arrayForSection: method in ViewController.m for an example of how to map your
    collection view sections to arrays. You may need to implement something like this.
 
 
 8. Optional. The long press gesture recognizer is created with a default minimumPressDuration of 0.15. If you
    require a different value this property is exposed. Set it as required...
        self.exchangeController.minimumPressDuration = 0.30;

 
 9. Optional. The custom layout hides and dims items during the exchange process. Items are dimmed by setting
    their alpha value to a default of 0.60. If you require a different value this property is exposed. 
    Set it as required...
        self.exchangeController.alphaForDimmedItem = 0.75;
 
 
 10. Optional. This class provides default animations during the exchange process to provide feedback to
    the user. If you need to change those animations you have two options.
 
        1. This class exposes the properties used to set some aspects of the animations. You can set
            those properties as you require. 
        2. The protocol defines two optional methods that you can implement to do your own catch 
            and release animations.
 
 At the beginning of the process, when the long press enters the Began state, an image of the
    cell is created with a default background color ([UIColor darkGrayColor]) and alpha (0.8). The image is
    transformed to blink indicating a successful grab. That image is then animated around the screen following
    the user's finger
 
 */



#import <UIKit/UIKit.h>

@class SSCollectionViewExchangeController;

@protocol SSCollectionViewExchangeControllerDelegate <NSObject>

- (BOOL)exchangeControllerCanExchange:(SSCollectionViewExchangeController *)exchangeController ;
// Called before beginning the exchange transaction to determine if it is ok to allow exchanges.


- (void)exchangeController:(SSCollectionViewExchangeController *)exchangeController
  exchangeItemAtIndexPath1:(NSIndexPath *)indexPath1
      withItemAtIndexPath2:(NSIndexPath *)indexPath2;
// Called whenever an exchange event occurs during an exchange transaction. This method
// provides the delegate with an opportunity to update the model as the user is dragging. This method
// may be called twice during a single exchange event. If so, the first call will be to undo a prior
// exchange and the second call will be for the new exchange. In all cases the delegate should just
// update the model by exchanging the elements at the indicated index paths.


- (void)exchangeControllerDidFinishExchangeEvent:(SSCollectionViewExchangeController *)exchangeController;
// Called when an exchange event finishes within an exchange transaction. This method
// provides the delegate with an opportunity to perform live updating as the user drags.


- (void)exchangeControllerDidFinishExchangeTransaction:(SSCollectionViewExchangeController *)exchangeController
                                        withIndexPath1:(NSIndexPath *)indexPath1
                                            indexPath2:(NSIndexPath *)indexPath2;
// Called when the exchange transaction completes (the user lifts his/her finger). The
// index paths represent the two items that were finally exchanged. This allows the delegate
// to setup for undo, for example. If the user dragged back to the starting position and
// released (effectively nothing was exchanged) the index paths will be the same.


@optional

- (UIImageView *)exchangeController:(SSCollectionViewExchangeController *)exchangeController imageViewForCell:(UICollectionViewCell *)cell;
// SSCollectionViewExchangeController implements a method for returning an image of the cell using a default
// background color and alpha. If this does not suit your purposes then implement this delegate method.


- (void)exchangeController:(SSCollectionViewExchangeController *)exchangeController animateCatchForImage:(UIImageView *)cellImage;
- (void)exchangeController:(SSCollectionViewExchangeController *)exchangeController animateReleaseForImage:(UIImageView *)cellImage;
// To provide feedback to the user SSCollectionViewExchangeController implements default blink
// animations at the beginning and end of the process. If the default implementations don't suit
// your purposes then implmement either or both of these delegate methods.
//
// Note: If you implement exchangeController:animateReleaseForImage: you must call
// performPostReleaseCleanupWithAnimationDuration: in your final completion block.

@end


@interface SSCollectionViewExchangeController : NSObject

- (instancetype)initWithDelegate:(id<SSCollectionViewExchangeControllerDelegate>)delegate
                  collectionView:(UICollectionView *)collectionView;

- (void)performPostReleaseCleanupWithAnimationDuration:(NSTimeInterval)duration;

- (UICollectionViewFlowLayout *)layout;

@property (nonatomic) CFTimeInterval    minimumPressDuration;
@property (nonatomic) CGFloat           alphaForDimmedItem;

// Exchange process animation related properties...
@property (nonatomic) NSTimeInterval    animationDuration;
@property (nonatomic) CGFloat           blinkToScaleForCatch;
@property (nonatomic) CGFloat           blinkToScaleForRelease;
@property (nonatomic) CGFloat           alphaForImage;
@property (strong, nonatomic) UIColor   *backgroundColorForImage;

@end
