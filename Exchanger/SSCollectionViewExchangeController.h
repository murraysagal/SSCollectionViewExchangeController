//
//  SSCollectionViewExchangeController.h
//  Exchanger
//
//  Created by Murray Sagal on 1/9/2014.
//  Copyright (c) 2014 Signature Software. All rights reserved.
//

/*
 
 SSCollectionViewExchangeController: 
 
 SSCollectionViewExchangeController manages the process of exchanging 2 collection view items. 
 The two items can be in different sections (and different arrays) but must be in the same 
 collection view. All cells that can be exchanged need to be visible--scrolling is not supported.
 When you initialize an instance of this class it installs a gesture recognizer in your collection 
 view and creates a custom layout object, SSCollectionViewExchangeLayout, that manages the hiding 
 and dimming of items in the collection view during the exchange process. Through the 
 SSCollectionViewExchangeControllerDelegate protocol your view controller is kept informed allowing 
 you to keep your model in sync with the changes occuring on the collection view and perform any 
 kind of live updating required during the process.
 
 If your view contains multiple collection views you can have an exchange controller for each. But
 exchanges cannot occur between collection views. 
 
 
 
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
 
 
 
 Terminology...
 
 Catch: The user initiates the process with a long press on a cell. The default catch animation 
 runs (you can create any animation you require) to indicate a successul catch to the user.
 
 Release: The user releases, usually over another item, ending the process. The default release
 animation runs (again, you can create any animation you require).
 
 Exchange Transaction: An exchange transaction begins with a catch and concludes with a release,
 normally over another item, causing the two to be exchanged. However, between the catch and
 the release the user may drag over many items including, possibly, the starting position.
 
 Exchange Event: An exchange event occurs each time the user drags to a different item. If it
 is the first exchange event it is a simple exchange between the item being dragged and the item 
 dragged to. If the user keeps dragging to new items subsequent exchange events include undoing 
 the previous exchange and then performing the new exchange. There can be many exchange events 
 within a single exchange transaction.
 
 Displaced Item: When the user drags over a new item that item is displaced. It animates away to 
 the original location of the item being dragged. At the same time, the item that was previously
 displaced animates back to its original location. To indicate the displaced item the layout 
 lowers its alpha.
 
 Hidden Item: Between the catch and the release the cell for the dragged item is hidden. This is
 managed by the layout. Nevertheless, the hidden item is following the user as the exchange
 transaction proceeds. If you are curios, return nil from the indexPathForItemToHide delegate 
 method and you will be able to observe this, best viewed in the simulator with slow
 animations on.
 
 Snapshot: During the catch a snapshot of the cell is created. The snapshot follows the user's
 finger during the long press. 
 
 Catch Rectangle: In some implementations, collection view cells can only be caught if the long 
 press occurs over a specific rectangle within the cell. That is the catch rectangle. Refer to the 
 optional exchangeController:viewForCatchRectangleForItemAtIndexPath: delegate method.
 
 
 
 Installation...
 
     Copy these files to your Xcode project:
        - SSCollectionViewExchangeController.h and .m
        - SSCollectionViewExchangeLayout.h and .m
        - UIGestureRecognizer+SSCollectionViewExchangeControllerAdditions.h and .m
        - NSMutableArray+SSCollectionViewExchangeControllerAdditions.h and .m
 
 
 
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
 
 
 6. Implement the mandatory protocol methods...
        - (BOOL)exchangeControllerCanExchange:(SSCollectionViewExchangeController *)exchangeController;
        - (void)exchangeController:(SSCollectionViewExchangeController *)exchangeController
       didExchangeItemAtIndexPath1:(NSIndexPath *)indexPath1
              withItemAtIndexPath2:(NSIndexPath *)indexPath2;
        - (void)exchangeControllerDidFinishExchangeEvent:(SSCollectionViewExchangeController *)exchangeController;
        - (void)exchangeControllerDidFinishExchangeTransaction:(SSCollectionViewExchangeController *)exchangeController
                                                withIndexPath1:(NSIndexPath *)indexPath1
                                                    indexPath2:(NSIndexPath *)indexPath2;
 
 
 7. Optional. This example app contains a category on NSMutableArray that implements a method for
    exchanging two items that can be in different arrays. You can import that category and use
    the method in your implementation of the exchangeController:didExchangeItemAtIndexPath1:withItemAtIndexPath2: 
    delegate method.
 
        [NSMutableArray exchangeItemInArray:array1
                                    atIndex:indexPath1.item
                            withItemInArray:array2
                                    atIndex:indexPath2.item];
 
    Note: see the arrayForSection: method in ViewController.m for an example of how to map your
    collection view sections to arrays. You may need to implement something like this.
 
 
 8. Optional. The exchange controller provides default animations during the exchange process to provide
    feedback to the user. Some properties related to visual aspects of the exchange process are exposed 
    to allow you to configure them to better meet your requirements. Refer to the comments for the 
    property declarations below.
 
 
 10. Optional. If the exposed properties don't provide you with the control you require you can implement
    the optional delegate methods for...
        - creating the snapshot
        - animating the catch
        - animating the release

 
 
 Limitations...
 
    - If your view contains multiple collection views the exchange controllers do not support exchanges
        between collection views.
    - Scrolling is not supported. All the cells that can be exchanged need to be visible on the screen.
    - The exchange controller does not provide direct support for rotation. But if your view controller
        allows rotation and manages the layout as required the exchange controller will continue to work.
        But the rotation event should not occur during an exchange transaction. Your view controller can
        ask the exchange controller if an exchange transaction is in progress.
 
 
 
 Thanks to...
 
    - Bolot Kerimbaev: For directing me to collection views when iOS 6 was released.
    - Matt Galloway: For taking the time to answer my question, "Can I do that with a collection view?"
    - Tony Copping: For schooling me on background threads.
    - Cesare Rocchi: For patiently enduring multiple code walkthroughs and providing excellent suggestions.
    - Gijs van Klooster: For asking, "Why are those methods so long?" And the enum suggestion.
 
 
 
 Original Inspiration from...
 
    LXReorderableCollectionViewFlowLayout: https://github.com/lxcid/LXReorderableCollectionViewFlowLayout
 
 */



#import <UIKit/UIKit.h>

typedef void (^PostReleaseCompletionBlock) (NSTimeInterval animationDuration);

@class SSCollectionViewExchangeController;

@protocol SSCollectionViewExchangeControllerDelegate <NSObject>

@required

- (BOOL)exchangeControllerCanExchange:(SSCollectionViewExchangeController *)exchangeController;
// Called before beginning the exchange transaction to determine if it is ok to allow exchanges.


- (void)    exchangeController:(SSCollectionViewExchangeController *)exchangeController
   didExchangeItemAtIndexPath1:(NSIndexPath *)indexPath1
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

- (UIView *)           exchangeController:(SSCollectionViewExchangeController *)exchangeController
  viewForCatchRectangleForItemAtIndexPath:(NSIndexPath *)indexPath;
// If your collection view cells can only be caught if the long press occurs over a specific
// rectangle then implement this method and return the view representing that rectangle. If
// this method is not implemented the catch rectangle is assumed to be the entire cell. 


- (UIView *)exchangeController:(SSCollectionViewExchangeController *)exchangeController
               snapshotForCell:(UICollectionViewCell *)cell;
// SSCollectionViewExchangeController implements a method for returning a snapshot of the cell using a default
// background color and alpha. If this does not meet your requirements then implement this delegate method.


- (void)animateCatchForExchangeController:(SSCollectionViewExchangeController *)exchangeController
                             withSnapshot:(UIView *)snapshot;

- (void)animateReleaseForExchangeController:(SSCollectionViewExchangeController *)exchangeController
                               withSnapshot:(UIView *)snapshot                              // this is the view the user has been dragging
                                    toPoint:(CGPoint)centerOfCell                           // this is the center of the cell where the release occurred
                     cellAtOriginalLocation:(UICollectionViewCell *)cellAtOriginalLocation  // animate its alpha back to 1.0
                            completionBlock:(PostReleaseCompletionBlock)completionBlock;    // you must execute this completion block in your final completion block
/*
 To provide feedback to the user SSCollectionViewExchangeController implements default
 animations for the catch and the release. If these implementations don't meet your
 requirements then implement either or both of the animate... delegate methods.

 Note: If you implement the animateRelease... method you must do the following...
    1. Animate snapshot to centerOfCell.
    2. Animate the alpha for cellAtOriginalLocation back to 1.0.
    3. Do not call invalidateLayout or remove the snapshot from its superview.
    4. In your final completion block, execute completionBlock and pass it an animation duration.
          ...
          } completion:^(BOOL finished) {
              completionBlock(duration);
          }];

        completionBlock manages the sequencing of the final moments of the exchange transaction.
        First, it sets some internal state and then calls invalidateLayout which unhides the hidden 
        cell (where the user dragged to). This unhiding happens immediately and without any animation.
        But, purposefully, the snapshot the user dragged around is still on the view so the instant
        unhiding of the cell happened behind the snapshot so no change was visible. Then completionBlock
        animates the alpha of the snapshot to 0.0, according to the duration you provide, revealing the
        now unhidden cell. When that animation is finished it removes the snapshot from the collection view.
*/

@end


@interface SSCollectionViewExchangeController : NSObject

- (instancetype)initWithDelegate:(id<SSCollectionViewExchangeControllerDelegate>)delegate
                  collectionView:(UICollectionView *)collectionView;

- (UICollectionViewFlowLayout *)layout;  // allows clients to configure the layout.
// This method is provided as a convenience. The delegate could ask its collection view
// for its layout but that will be returned as a UICollectionViewLayout and would need
// to be cast to a UICollectionViewFlowLayout before configuration. This method conveniently
// returns the layout as a UICollectionViewFlowLayout, ready to be configured.

@property (nonatomic) CFTimeInterval    minimumPressDuration;       // for configuring the long press, default: 0.15
@property (nonatomic) CGFloat           alphaForDisplacedItem;      // so the user can distinguish the most recently displaced item, default: 0.60

// Exchange process animation related properties...
@property (nonatomic) NSTimeInterval    animationDuration;          // the duration of each segment of the default animations, default: 0.20
@property (nonatomic) CGFloat           blinkToScaleForCatch;       // default: 1.20
@property (nonatomic) CGFloat           blinkToScaleForRelease;     // default: 1.05
@property (nonatomic) CGFloat           snapshotAlpha;              // default: 0.80
@property (strong, nonatomic) UIColor   *snapshotBackgroundColor;   // default: [UIColor darkGrayColor]

@property (nonatomic, readonly) BOOL    exchangeTransactionInProgress; // allows clients to determine if there is an exchange transaction in progress

@end
