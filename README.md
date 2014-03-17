# SSCollectionViewExchangeController

`SSCollectionViewExchangeController` manages the process of exchanging 2 items in a collection view. The key word is **exchange** which results in slightly different outcome compared to the more typical move scenario. Consider an example with these 5 items. 

    item1    item2    item3    item4    item5

In a move scenario, when item1 is moved to item5 this is the result:

    item2    item3    item4    item5    item1

With a move, all the items between the *from* and *to* items reposition themselves toward the original location of the *from* item. 

In an exchange scenario, when item1 is exchanged with item5 this is the result:

    item5    item2    item3    item4    item1

With an exchange the items between the *to* and the *from* don't move. Only the *from* and *to* items move.


## Features

* Comprehensive protocol keeps the delegate informed and in control.
* Support for items that can't be moved or exchanged. 
* Default animations at the beginning and end of the process or implement your own.
* Safely handles interruptions like a phone call in the middle of an exchange. 


## Conceptual Object Model
 
        ---------------------
        |                   |       delegate
     ---|  ViewController   |<----------------------
    |   |                   |                       |
    |   ---------------------                       |
    |        |                           ------------------------------------------
    |        |  @property (strong, ...   |                                        |
    |         -------------------------->|   SSCollectionViewExchangeController   |
    |                                    |                                        |
    |                                    ------------------------------------------
    |                                         |                            |
    |                                         V                            |
    |                              ----------------------------------      |
    |                              |                                |      |
    |                      ------->|  UILongPressGestureRecognizer  |      |
    |                     |        |                                |      |
    |                     |        ----------------------------------      |
    |   ------------------------                                           V
    |   |                      |            ---------------------------------------
     -->|   UICollectionView   |----------> |                                     |
        |                      |            |   SSCollectionViewExchangeLayout    |
        ------------------------            |                                     |
                                            ---------------------------------------

When you initialize an instance of `SSCollectionViewExchangeController` it installs a gesture recognizer in your collection view and creates a custom layout object, `SSCollectionViewExchangeLayout`, a `UICollectionViewFlowLayout` subclass, and sets that on your collection view. The layout manages the display of items in the collection view during the exchange process. Through the `SSCollectionViewExchangeControllerDelegate` protocol your view controller is kept informed allowing you to keep your model in sync with the changes occuring on the collection view and perform any kind of live updating required during the process. Your view controller must keep a strong pointer to the exchange controller. 
 
If your view contains multiple collection views you can have an exchange controller for each. But exchanges cannot occur between collection views. 




## Terminology
 
 **Catch**: The catch is the beginning of the exchange process. The user initiates the process with a long press on a collection view cell. If the gesture is recognized the catch animation runs (either the default or yours) to indicate a successul catch to the user.
 
 **Release**: The user releases their finger, usually over another item, ending the process. The release animation runs (again, either the default or yours).
 
 **Exchange Transaction**: An exchange transaction begins with a catch and concludes with a release, normally over another item, causing the two to be exchanged. However, between the catch and the release the user may drag over many items including, possibly, the starting position.
 
 **Exchange Event**: An exchange event occurs each time the user drags to a different item during an exchange transaction. There can be many exchange events within a single exchange transaction. An exchange event contains either one or two individual exchanges. If it is the first exchange event in the transaction there is an individual exchange between the item being dragged and the item dragged to. If the user keeps dragging to new items subsequent exchange events include two individual exchanges: one to undo the previous exchange and another for the new exchange. Refer to the timeline diagram below.
 
 **Displaced Item**: When the user drags over a new item that item is displaced. It animates away to the original location of the item being dragged. At the same time, the item that was previously displaced animates back to its original location. To indicate the displaced item the layout lowers its alpha.
 
**Hidden Item**: Between the catch and the release the cell for the dragged item is hidden. This is managed by the layout. Nevertheless, the hidden item is following the user as the exchange transaction proceeds. If you are curios, return nil from `indexPathForItemToHide` and you will be able to observe this, best viewed in the simulator with slow animations on.
 
 **Snapshot**: During the catch a snapshot of the cell is created. The snapshot follows the user's
 finger during the long press. 
 
 **Catch Rectangle**: In some implementations, collection view cells can only be caught if the long 
 press occurs over a specific rectangle within the cell. That is the catch rectangle. Refer to the 
 optional `exchangeController:viewForCatchRectangleForItemAtIndexPath:` delegate method.



## Exchange Transactions and Exchange Events: A Timeline View

``` 
                                        Exchange Transaction
|--------------------------------------------------------------------------------------------->|
Catch at index path 0,3                                                Release at index path 1,5
 
 
        Exchange Event 1                Exchange Event 2               Exchange Event 3
|----------------------------->||----------------------------->||----------------------------->|
move from:   0,3 to 1,3                    1,3 to 1,4                      1,4 to 1,5
 
 
         new exchange            undo previous   new exchange   undo previous    new exchange
|----------------------------->||------------->||------------>||-------------->||------------->|
exchange:   0,3 with 1,3          1,3 with 0,3    0,3 with 1,4   1,4 with 0,3     0,3 and 1,5

``` 

In the timeline you can see that an exchange transaction can include multiple exchange events. An exchange event has either one or two individual exchanges. Where there are two, the first is to undo the previous exchange. Where there is one, there isn't a previous exchange to undo. 

## Demo

You can see the demo app for `SSCollectionViewExchangeController` in action [here](http://youtu.be/6YvOK9m5RRA).



## Installation

`SSCollectionViewExchangeController` uses `UICollectionView` which was available starting with iOS 6.0.


### Cocoapods

1. Add an entry to your Podfile: `pod 'SSCollectionViewExchangeController'`
2. Install the pod(s) by running: `pod install`


### Source Files

Alternatively, copy these 8 files to your Xcode project:

* SSCollectionViewExchangeController.h and .m
* SSCollectionViewExchangeLayout.h and .m
* UIView+SSCollectionViewExchangeControllerAdditions.h and .m
* NSMutableArray+SSCollectionViewExchangeControllerAdditions.h and .m



## Usage
 
1. In your view controller import `SSCollectionViewExchangeController.h`...

        #import "SSCollectionViewExchangeController.h"
 

1. Adopt the `SSCollectionViewExchangeControllerDelegate` protocol...

        @interface MyViewController () <SSCollectionViewExchangeControllerDelegate>

 
1. Create a property for the exchange controller...

        @property (strong, nonatomic) SSCollectionViewExchangeController *exchangeController;
 
1. In `viewDidLoad` create an instance of `SSCollectionViewExchangeController`...

        self.exchangeController = [[SSCollectionViewExchangeController alloc] initWithDelegate:self
                                                                                collectionView:self.collectionView];

 
1. Get the layout and configure it as required...

        UICollectionViewFlowLayout *layout = self.exchangeController.layout;
        layout.itemSize = CGSizeMake(150, 30);
        ...
 
1. Implement the required protocol methods described in the next section.
 
 
1. Optional. This example app contains a category on `NSMutableArray` that implements a method for
    exchanging two items that can be in different arrays. You can import that category and use
    the method in your implementation of the `exchangeController:didExchangeItemAtIndexPath1:withItemAtIndexPath2:`
    delegate method. See `ViewController.m` in the demo app for an example implementation.
 
        [NSMutableArray exchangeObjectInArray:array      atIndex:indexPath1.item
                       withObjectInOtherArray:otherArray atIndex:indexPath2.item];
 
    Note: If your collection view has multiple sections with an array for each section refer 
    to the `arrayForSection:` method in `ViewController.m` for an example of how to map your
    collection view sections to arrays. You may need to implement something like this.
 
 
1. Optional. The exchange controller provides default animations during the exchange process to provide
    feedback to the user. Some properties related to those animations are exposed to allow you to configure 
    them to better meet your requirements. Refer to the comments for the property declarations below.
 
 
1. Optional. If the exposed properties don't provide you with the control you require you can implement
    the optional delegate methods for...

    - creating the snapshot
    - animating the catch
    - animating the release



## Required Delegate Methods

```objective-c

- (void)   exchangeController:(SSCollectionViewExchangeController *)exchangeController
  didExchangeItemAtIndexPath1:(NSIndexPath *)indexPath1
         withItemAtIndexPath2:(NSIndexPath *)indexPath2;
```

Called for each individual exchange within an exchange event. There may be one exchange or two per event. In all cases the delegate should just update the model by exchanging the elements at the indicated index paths. Refer to the Exchange Event description and the Exchange Transactions and Exchange Events: A Timeline View above. This method provides the delegate with an opportunity to keep its model in sync with changes happening on the view. If you are doing any kind of live updating as the user drags, this is usually not the place to invoke that because this method may be called twice for each exchange event. Live updating should be invoked in `exchangeControllerDidFinishExchangeEvent:`.

---

```objective-c

- (void)exchangeControllerDidFinishExchangeEvent:(SSCollectionViewExchangeController *)exchangeController;
```

Called when an exchange event finishes within an exchange transaction. This method provides the delegate with an opportunity to perform live updating as the user drags.

---

```objective-c

- (void)exchangeControllerDidFinishExchangeTransaction:(SSCollectionViewExchangeController *)exchangeController
                                        withIndexPath1:(NSIndexPath *)indexPath1
                                            indexPath2:(NSIndexPath *)indexPath2;
```

Called when an exchange transaction completes (the user lifts his/her finger). The index paths represent the two items in the final exchange. Do not exchange these items, you already have. This method allows the delegate to perform any task required at the end of the transaction such as setting up for undo. If the user dragged back to the starting position and released (effectively nothing was exchanged) the index paths will be the same.

---

```objective-c

- (void)exchangeControllerDidCancelExchangeTransaction:(SSCollectionViewExchangeController *)exchangeController;
```

Called when the long press gesture recognizer's state becomes `UIGestureRecognizerStateCancelled`. Normally, this only happens if the device receives a phone call during the exchange transaction. When this happens the exchange controller helps the delegate return to the state before the exchange transaction started. To do this the exchange controller first calls `exchangeController:didExchangeItemAtIndexPath1:withItemAtIndexPath2:` on the delegate with the index paths for the last items exchanged so the delegate can restore the model. Then this method is called allowing the delegate to perform any additional actions required. Normally, the delegate will not need to take any action on the collection view. The exchange controller will return the collection view to its previous state. No animation is applied because the view is hidden. 


## Optional Delegate Methods

```objective-c

- (BOOL)exchangeControllerCanBeginExchangeTransaction:(SSCollectionViewExchangeController *)exchangeController
                                  withItemAtIndexPath:(NSIndexPath *)indexPath;
```

If implemented, called before beginning an exchange transaction to determine if it is ok to begin. Implement this method if you have any or all of these requirements:

1. The delegate needs to know when an exchange transaction begins so it can prepare (update its UI, turn off other gestures, etc).  If you return YES it is safe to assume that the exchange transaction will begin.
1. And/or the delegate conditionally allows exchanges. For example, maybe exchanges are allowed only when editing.
1. And/or some of the items in the collection view can't be moved. The item at `indexPath` is the item that will be moved. Important note: Whether an item can be moved is determined here. Whether an item can be displaced is determined in the `canDisplaceItemAtIndexPath:` method. If an item can't be moved and can't be displaced you need to implement both methods.

Return NO if you do not want this exchange transaction to begin. If you return YES it is safe to assume that the exchange transaction will begin. If not implemented the exchange controller assumes YES.

---

```objective-c

- (BOOL)          exchangeController:(SSCollectionViewExchangeController *)exchangeController
          canDisplaceItemAtIndexPath:(NSIndexPath *)indexPathOfItemToDisplace
   withItemBeingDraggedFromIndexPath:(NSIndexPath *)indexPathOfItemBeingDragged;
```

If implemented, called throughout the exchange transaction to determine if it’s ok to exchange the two items. Implement this method if your collection view contains items that cannot be exchanged at all or if there may be a situation where the item to displace cannot be exchanged with the particular item being dragged. If not implemented, the default is YES.

---

```objective-c

- (UIView *)           exchangeController:(SSCollectionViewExchangeController *)exchangeController
  viewForCatchRectangleForItemAtIndexPath:(NSIndexPath *)indexPath;
```

If your collection view cells can only be caught if the long press occurs over a specific rectangle then implement this method and return the view representing that rectangle. If this method is not implemented the catch rectangle is assumed to be the entire cell.

---

```objective-c

- (UIView *)exchangeController:(SSCollectionViewExchangeController *)exchangeController
               snapshotForCell:(UICollectionViewCell *)cell;
```

`SSCollectionViewExchangeController` implements a default method for creating a snapshot of the cell using a default background color and alpha. If this does not meet your requirements then implement this delegate method. Before implementing this method remember that the properties for the background colour and alpha used in the default snapshot method are exposed. Consider setting those before implementing this method. 

---

```objective-c

- (void)animateCatchForExchangeController:(SSCollectionViewExchangeController *)exchangeController
                             withSnapshot:(UIView *)snapshot;

- (void)animateReleaseForExchangeController:(SSCollectionViewExchangeController *)exchangeController
                               withSnapshot:(UIView *)snapshot                              // this is the view the user has been dragging
                                    toPoint:(CGPoint)centerOfCell                           // this is the center of the cell where the release occurred
            originalIndexPathForDraggedItem:(NSIndexPath *)originalIndexPathForDraggedItem  // animate the alpha for the cell at this index path back to 1.0
                            completionBlock:(PostReleaseCompletionBlock)completionBlock;    // you must execute this completion block in your final completion block
```

To provide feedback to the user `SSCollectionViewExchangeController` implements default animations for the catch and the release. If these implementations don't meet your requirements then implement either or both of these delegate methods.

If you implement the `animateReleaseForExchangeController` method you should do the following:

1. Animate `snapshot` to `centerOfCell`.
1. Animate the `alpha` for the cell at `originalIndexPathForDraggedItem` back to 1.0.
1. Do not call `invalidateLayout` or remove the snapshot from its superview.
1. In your final completion block, execute `completionBlock` and pass it an animation duration. `completionBlock` manages the sequencing of the final moments of the exchange transaction. First, it sets some internal state and then calls `invalidateLayout` which unhides the hidden cell (where the user dragged to). This unhiding happens immediately and without any animation. But, purposefully, the snapshot the user dragged around is still on the view so the instant unhiding of the cell happens behind the snapshot so no change is visible. Then `completionBlock` animates the alpha of the snapshot to 0.0, according to the duration you provide, revealing the now unhidden cell. When that animation is finished it removes the snapshot from the collection view.

```objective-c

    ...
    } completion:^(BOOL finished) {
        completionBlock(duration);
    }];
```



## Exposed Methods

```objective-c

- (instancetype)initWithDelegate:(id<SSCollectionViewExchangeControllerDelegate>)delegate
                  collectionView:(UICollectionView *)collectionView;
```
This is the designated initializer. `delegate`, usually your view controller, must conform to the `SSCollectionViewExchangeControllerDelegate` protocol. `collectionView` is the collection view the exchange controller will manage. 

---

```objective-c

- (UICollectionViewFlowLayout *)layout;
```

This method is provided as a convenience. The delegate could ask its collection view for its layout but that will be returned as a `UICollectionViewLayout` and would need to be cast to a `UICollectionViewFlowLayout` before configuration. This method conveniently returns the layout as a `UICollectionViewFlowLayout`, ready to be configured.



## Exposed Properties

```objective-c

@property (weak, nonatomic, readonly)   UILongPressGestureRecognizer    *longPressGestureRecognizer; 
// exposed to allow the delegate to set its properties as required
// by default minimumPressDuration is 0.15 and delaysTouchesBegan is YES
```

---

```objective-c

@property (nonatomic) CGFloat           alphaForDisplacedItem;  
// to distinguish the displaced item, default: 0.60
```

---

```objective-c

@property (nonatomic) NSTimeInterval    animationDuration;          
// the duration of each segment of the default animations, default: 0.20

@property (nonatomic) CGFloat           blinkToScaleForCatch;       
// default: 1.20

@property (nonatomic) CGFloat           blinkToScaleForRelease;     
// default: 1.05
```

---

```objective-c

@property (nonatomic) CGFloat           snapshotAlpha;              
// default: 0.80

@property (strong, nonatomic) UIColor   *snapshotBackgroundColor;   
// if you set to nil, no background color will be applied, default: [UIColor darkGrayColor]
```

---

```objective-c

@property (nonatomic, readonly) BOOL    exchangeTransactionInProgress; 
// allows clients to determine if there is an exchange transaction in progress
```

---

```objective-c

@property (nonatomic) double            animationBacklogDelay;
// When the long press is cancelled, for example by an incoming call, depending on the 
// velocity there may be move animations in progress and pending. Without a delay, the 
// backlog of animations can still be executing when the exchange controller calls 
// reloadData. This prevents reloadData from working properly and restoring the 
// collection view to its previous state. The delay allows the backlog of animations 
// to complete before the exchange controller cancels the exchange. The default is 0.50
// and should be sufficient in most cases but is exposed in case that doesn't meet 
// your requirements.
```


## Limitations
 
* If your view contains multiple collection views the exchange controllers do not support exchanges between collection views.
* Scrolling is not supported. All the cells that can be exchanged need to be visible on the screen.
* The exchange controller does not provide direct support for rotation. But if your view controller allows rotation and manages the layout as required the exchange controller should continue to work (needs testing). But the rotation event should not occur during an exchange transaction. Your view controller can ask the exchange controller if an exchange transaction is in progress.



## Production Example

[PaddlesUp! Coach](https://itunes.apple.com/ca/app/paddlesup!-coach/id663179874?mt=8) uses SSCollectionViewExchangeController to help implement its dragon boat team lineup editor. You can see it in action [here](http://youtu.be/7S1QFx4Nfu0).



## Thanks to...
 
* Bolot Kerimbaev: For telling me about collection views when iOS 6 was released.
* Matt Galloway: For taking the time to answer my question, "Can I do that with a collection view?"
* Tony Copping: For schooling me on background threads.
* Cesare Rocchi: For patiently enduring multiple code walkthroughs and providing excellent suggestions.
* Gijs van Klooster: For asking, "Why are those methods so long?" And that great enum suggestion.



## Original Inspiration from...
 
LXReorderableCollectionViewFlowLayout: <https://github.com/lxcid/LXReorderableCollectionViewFlowLayout>


## About the Demo App

You can clone or download the repo to use the demo app. It exercises some but not all of the features of `SSCollectionViewExchangeController`.


## Tests

The demo app contains a set of tests for the `exchangeObjectInArray:atIndex:withObjectInOtherArray:atIndex:` method. If you copy the test file to your project you may need to configure the project so the test target will recognize the files.

1. Select your project in the Project Navigator pane.
1. Select your project in the Projects and Targets pane.
1. You must be on the Info tab.
1. In Configurations expand Debug and your project.
1. In <yourProjectName>Tests select Pods from the popup.


## Release History

* 0.1.0 - Mar 5, 2014: Initial release.
* 0.1.1 - Mar 17, 2014: Merged the pull request from eugenepavlyuk fixing the bug with headers and footers. 