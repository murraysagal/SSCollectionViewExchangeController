//
//  SSCollectionViewExchangeController.h
//  Exchanger
//
//  Created by Murray Sagal on 1/9/2014.
//  Copyright (c) 2014 Murray Sagal. All rights reserved.
//

/*
 
 SSCollectionViewExchangeController manages the process of exchanging 2 collection view items. 
 The two items can be in different sections (and different arrays) but must be in the same 
 collection view. All cells that can be exchanged need to be visible--scrolling is not supported.
 When you initialize an instance of this class it installs a gesture recognizer in your collection 
 view and creates a custom layout object, SSCollectionViewExchangeLayout, that manages the hiding 
 and dimming of items in the collection view during the exchange process. Through the 
 SSCollectionViewExchangeControllerDelegate protocol your view controller is kept informed allowing 
 you to keep your model in sync with the changes occuring on the collection view and perform any 
 kind of live updating required during the process.
 
 
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
 runs (you can create any animation you require) to indicate to the user that this item will be
 exchanged with another. 
 
 Release: The user releases, usually over another item, ending the process. The default release
 animation runs (again, you can create any animation you require).
 
 Exchange Transaction: An exchange transaction begins with a catch and concludes with a release,
 normally over another item, causing the two to be exchanged. However, between the beginning and
 the end the user may drag over many items including, possibly, the starting position.
 
 Exchange Events: An exchange event occurs each time the user drags to a different item. If it is the first
 exchange event it is a simple exchange between the item being dragged and the item dragged to.
 If the user keeps dragging to new items subsequent exchange events include undoing the previous
 exchange and then performing the new exchange. There can be many exchange events within a single
 exchange transaction.
 
 
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

typedef void (^PostReleaseCompletionBlock) (NSTimeInterval animationDuration);

@class SSCollectionViewExchangeController;

@protocol SSCollectionViewExchangeControllerDelegate <NSObject>

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

- (UIView *)      exchangeController:(SSCollectionViewExchangeController *)exchangeController
  viewForCatchRectangleForItemAtIndexPath:(NSIndexPath *)indexPath;
// If your collection view cells can only be caught if the long press occurs over a specific
// rectangle then implement this method and return the view representing that rectangle. If
// this method is not implemented the catch rectangle is assumed to be the entire cell. 


- (UIImageView *)exchangeController:(SSCollectionViewExchangeController *)exchangeController
                   imageViewForCell:(UICollectionViewCell *)cell;
// SSCollectionViewExchangeController implements a method for returning an image of the cell using a default
// background color and alpha. If this does not meet your requirements then implement this delegate method.


- (void)animateCatchForExchangeController:(SSCollectionViewExchangeController *)exchangeController
                                withImage:(UIImageView *)cellImage;

- (void)animateReleaseForExchangeController:(SSCollectionViewExchangeController *)exchangeController
                                  withImage:(UIImageView *)cellImage                        // this is the image the user has been dragging
                                    toPoint:(CGPoint)centerOfCell                           // this is the center of the cell where the release occurred
                     cellAtOriginalLocation:(UICollectionViewCell *)cellAtOriginalLocation  // animate its alpha back to 1.0
                            completionBlock:(PostReleaseCompletionBlock)completionBlock;    // you must execute this completion block in your final completion block
/*
 To provide feedback to the user SSCollectionViewExchangeController implements default
 animations for the catch and the release. If these implementations don't meet your
 requirements then implement either or both of these animate... delegate methods.

 Note: If you implement animateReleaseForExchangeController:withImage:toPoint:cellAtOriginalLocation:completionBlock:
 you must do the following...
    1. Animate cellImage to centerOfCell. The how is up to you.
    2. Animate the alpha for cellAtOriginalLocation back to 1.0.
    3. Do not call invalidateLayout or remove the image from its superview.
    4. In your final completion block, execute completionBlock and pass it an animation duration.
          ...
          } completion:^(BOOL finished) {
              completionBlock(duration);
          }];

        completionBlock manages the sequencing of the final moments of the exchange transaction.
        First, it sets some internal state and then calls invalidateLayout to unhide the hidden 
        cell (where the user dragged to). This unhiding happens immediately and without any animation.
        But, purposefully, the image the user dragged around is still on the view so the instant 
        unhiding of the cell happened behind the image so no change was visible. Then completionBlock 
        animates the alpha of the image to 0.0, according to the duration you provide, revealing the 
        now unhidden cell. When that animation is finished it removes the image from the collection view.
*/

@end


@interface SSCollectionViewExchangeController : NSObject

- (instancetype)initWithDelegate:(id<SSCollectionViewExchangeControllerDelegate>)delegate
                  collectionView:(UICollectionView *)collectionView;

- (UICollectionViewFlowLayout *)layout;

// for configuring the long press...
@property (nonatomic) CFTimeInterval    minimumPressDuration;

// the layout uses this property...
@property (nonatomic) CGFloat           alphaForDimmedItem;

// Exchange process animation related properties...
@property (nonatomic) NSTimeInterval    animationDuration;
@property (nonatomic) CGFloat           blinkToScaleForCatch;
@property (nonatomic) CGFloat           blinkToScaleForRelease;
@property (nonatomic) CGFloat           alphaForImage;
@property (strong, nonatomic) UIColor   *backgroundColorForImage;

@end
