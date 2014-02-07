//
//  ViewController.m
//  Exchanger
//
//  Created by Murray Sagal on 2012-10-30.
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



/*
 
 This app demonstrates the capabilities of the SSCollectionViewExchangeController
 and SSCollectionViewExchangeLayout classes that are designed to exchange items 
 in a collection view.
 
 Refer to SSCollectionViewExchangeController.h for detailed documentation.
 
 */

#import "ViewController.h"
#import "SSCollectionViewExchangeController.h"
#import "NSMutableArray+SSCollectionViewExchangeControllerAdditions.h"


#define CELL_LABEL_TAG      1
#define CATCH_RECTANGLE_TAG 2
#define LOCK_LABEL_TAG      3


NS_ENUM(NSInteger, CollectionViewSection) {
    CollectionViewSectionLeft,
    CollectionViewSectionMiddle,
    CollectionViewSectionRight
};


@interface ViewController ()

<
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    SSCollectionViewExchangeControllerDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *sumLeft;
@property (weak, nonatomic) IBOutlet UILabel *sumMiddle;
@property (weak, nonatomic) IBOutlet UILabel *sumRight;

- (IBAction)reset:(id)sender;
- (IBAction)undo:(id)sender;

@property (strong, nonatomic) NSMutableArray *leftSide;
@property (strong, nonatomic) NSMutableArray *middle;
@property (strong, nonatomic) NSMutableArray *rightSide;

@property (strong, nonatomic) NSIndexPath *indexPath1ForLastExchange;
@property (strong, nonatomic) NSIndexPath *indexPath2ForLastExchange;

@property (strong, nonatomic) SSCollectionViewExchangeController *exchangeController;

- (IBAction)catchRectangleSwitchChanged:(UISwitch *)sender;
@property (weak, nonatomic) IBOutlet UISwitch *catchRectangleSwitch;

- (IBAction)lockItemAtZeroZeroSwitchChanged:(UISwitch *)sender;
@property (weak, nonatomic) IBOutlet UISwitch *lockItemAtZeroZeroSwitch;

- (IBAction)conditionalExchangeSwitchChanged:(UISwitch *)sender;
@property (weak, nonatomic) IBOutlet UISwitch *conditionalExchangeSwitch;

- (IBAction)allowExchangesSwitchChanged:(UISwitch *)sender;
@property (weak, nonatomic) IBOutlet UISwitch *allowExchangesSwitch;

@property (strong, nonatomic) NSString *lockLabelText;
@property (strong, nonatomic) NSString *conditionalDisplacementLabelText;
@property (strong, nonatomic) NSIndexPath *indexPath1ForconditionalDisplacement;
@property (strong, nonatomic) NSIndexPath *indexPath2ForconditionalDisplacement;
@property (strong, nonatomic) NSIndexPath *indexPathZeroZero;

@end




@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Prepare...
    [self prepareModel];
    [self updateSumLabels];
    [self logModel];
    
    // Register the cell with the collection view...
    UINib *cellNib = [UINib nibWithNibName:@"ItemCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"itemCell"];
    
    self.exchangeController = [[SSCollectionViewExchangeController alloc] initWithDelegate:self
                                                                            collectionView:self.collectionView];
    
    // The SSCollectionViewExchangeController creates a layout and configures the collection
    // view to use it. The layout is a subclass of UICollectionViewFlowLayout specifically
    // designed to manage hiding and dimming items during the exchange process. But it has
    // not been configured. The exchange controller can provide you with the
    // layout, as a UICollectionViewFlowLayout, which you can configure as required.
    
    UICollectionViewFlowLayout *layout = self.exchangeController.layout;
    layout.itemSize = CGSizeMake(100, 30);
    layout.minimumLineSpacing = 1;
    layout.minimumInteritemSpacing = 1;
    layout.sectionInset = UIEdgeInsetsMake(5, 3, 5, 3);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    self.lockLabelText = @"🔒";
    self.conditionalDisplacementLabelText = @"🔐";
    self.indexPathZeroZero = [NSIndexPath indexPathForItem:0 inSection:0];
    self.indexPath1ForconditionalDisplacement = [NSIndexPath indexPathForItem:0 inSection:1];
    self.indexPath2ForconditionalDisplacement = [NSIndexPath indexPathForItem:0 inSection:2];
    
}



//---------------------------------
#pragma mark - Instance methods...

- (void)prepareModel
{    
    NSArray *temp1to10 =    @[  @1,  @2,  @3,  @4,  @5,  @6,  @7,  @8,  @9, @10 ];
    NSArray *temp11to20 =   @[ @11, @12, @13, @14, @15, @16, @17, @18, @19, @20 ];
    NSArray *temp21to30 =   @[ @21, @22, @23, @24, @25, @26, @27, @28, @29, @30 ];
    
    self.leftSide = [NSMutableArray arrayWithArray:temp1to10];
    self.middle = [NSMutableArray arrayWithArray:temp11to20];
    self.rightSide = [NSMutableArray arrayWithArray:temp21to30];
}

- (void)updateSumLabels
{
    // Demonstrates how live updating is enabled by the exchangeControllerDidFinishExchangeEvent: delegate method.
    
    self.sumLeft.text =     [NSString stringWithFormat:@"%ld", (long)[self sumArray:self.leftSide]];
    self.sumMiddle.text =   [NSString stringWithFormat:@"%ld", (long)[self sumArray:self.middle]];
    self.sumRight.text =    [NSString stringWithFormat:@"%ld", (long)[self sumArray:self.rightSide]];
}

- (IBAction)undo:(id)sender
{
    // Demonstrates how undo is enabled by the
    // exchangeControllerDidFinishExchangeTransaction:withIndexPath1:indexPath2:: delegate method.
    
    if (self.indexPath1ForLastExchange != nil) {
        
        [self.collectionView performBatchUpdates:^ {
            
            [self.collectionView moveItemAtIndexPath:self.indexPath1ForLastExchange toIndexPath:self.indexPath2ForLastExchange];
            [self.collectionView moveItemAtIndexPath:self.indexPath2ForLastExchange toIndexPath:self.indexPath1ForLastExchange];
            
        }
                                      completion:^(BOOL finished) {
                                          
                                          [self exchangeItemAtIndexPath1:self.indexPath1ForLastExchange
                                                    withItemAtIndexPath2:self.indexPath2ForLastExchange]; // sync the model
                                          [self updateSumLabels];
                                          [self logModel];
                                          
                                      }];
    }
}

- (void)exchangeItemAtIndexPath1:(NSIndexPath *)indexPath1 withItemAtIndexPath2:(NSIndexPath *)indexPath2 {
    
    NSMutableArray *array1 = [self arrayForSection:indexPath1.section];
    NSMutableArray *array2 = [self arrayForSection:indexPath2.section];
    
    // as defined in the NSMutableArray category, can exchange items in different arrays...
    [NSMutableArray exchangeObjectInArray:array1
                                  atIndex:indexPath1.item
                   withObjectInOtherArray:array2
                                  atIndex:indexPath2.item];

}

- (NSMutableArray *)arrayForSection:(NSUInteger)section {
    
    // Normally each section of a collection view has its own array. This is a simple example of how
    // you might map your sections to actual arrays. Using a technique like this simplifies the
    // implementation of the exchangeItemAtIndexPath1:withItemAtIndexPath2: method shown above.
    
    // If your collection view is represented by a single array you won't need a method like this.
    
    NSMutableArray *array;
    
    switch (section) {
            
        case CollectionViewSectionLeft:
            array = self.leftSide;
            break;
            
        case CollectionViewSectionMiddle:
            array = self.middle;
            break;
            
        case CollectionViewSectionRight:
            array = self.rightSide;
            break;
    }
    return array;
}

- (IBAction)reset:(id)sender
{
    [self prepareModel];
    [self.collectionView reloadData];
    [self updateSumLabels];
    self.indexPath1ForLastExchange = nil;
    self.indexPath2ForLastExchange = nil;
    [self logModel];
}

- (NSInteger)sumArray:(NSArray *)array
{
    NSInteger sum = 0;
    for (NSNumber *number in array) {
        sum += [number integerValue];
    }
    return sum;
}

- (void)prepareForUndoWithIndexPath1:(NSIndexPath *)indexPath1 indexPath2:(NSIndexPath *)indexPath2 {
    
    if (![indexPath1 isEqual:indexPath2]) {
        
        self.indexPath1ForLastExchange = indexPath1;
        self.indexPath2ForLastExchange = indexPath2;
        
    }
}

- (void)logModel
{
    // so you can verify that the model is staying in sync with the changes occurring on the view...
    
    NSLog(@" ");
    NSLog(@"self.leftSide   |    self.middle    |    self.rightSide");
    
    for (int i=0; i<[self.leftSide count]; i++) {
        NSLog(@"          %@     |         %@        |          %@", self.leftSide[i], self.middle[i], self.rightSide[i]);
    }
    
    NSInteger sumLeft =     [self sumArray:self.leftSide];
    NSInteger sumMiddle =   [self sumArray:self.middle];
    NSInteger sumRight =    [self sumArray:self.rightSide];
    
    NSLog(@" ");
    NSLog(@" sumLeft= %ld        sumMiddle= %ld      sumRight= %ld", (long)sumLeft, (long)sumMiddle, (long)sumRight);
    NSLog(@" ");
}



//-----------------------------------------------
#pragma mark - Action methods for the switches...

- (IBAction)someSwitchChanged {
    
    [self.collectionView reloadData];
    
}


- (IBAction)catchRectangleSwitchChanged:(UISwitch *)sender {
    
    [self.collectionView reloadData];
    
}
- (IBAction)lockItemAtZeroZeroSwitchChanged:(UISwitch *)sender {
    
    [self.collectionView reloadData];
    
}
- (IBAction)conditionalExchangeSwitchChanged:(UISwitch *)sender {
    
    [self.collectionView reloadData];
    
}

- (IBAction)allowExchangesSwitchChanged:(UISwitch *)sender {
    
    [self.collectionView reloadData];
    
}



//-----------------------------------------------------------------
#pragma mark - UICollectionView data source and delegate methods...

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 3;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 10;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"itemCell" forIndexPath:indexPath];
    
    NSNumber *itemNumber;
    
    switch (indexPath.section) {
            
        case CollectionViewSectionLeft:
            itemNumber = self.leftSide[ indexPath.item ];
            break;
            
        case CollectionViewSectionMiddle:
            itemNumber = self.middle[ indexPath.item ];
            break;
            
        case CollectionViewSectionRight:
            itemNumber = self.rightSide[ indexPath.item ];
            break;
    }
    
    // The collection view cell doesn't have a class.
    // So subviews are retrieved with a tag.
    UIView *catchRectangle = [cell viewWithTag:CATCH_RECTANGLE_TAG];
    UILabel *lockLabel = (UILabel *)[cell viewWithTag:LOCK_LABEL_TAG];
    UILabel *itemLabel = (UILabel *)[cell viewWithTag:CELL_LABEL_TAG];
    
    catchRectangle.hidden = (self.catchRectangleSwitch.on)? NO:YES;
    
    BOOL showLock = self.lockItemAtZeroZeroSwitch.on && [indexPath isEqual:self.indexPathZeroZero];
    BOOL showConditionalExchangeLock = (self.conditionalExchangeSwitch.on &&
                                        ([indexPath isEqual:self.indexPath1ForconditionalDisplacement] ||
                                         [indexPath isEqual:self.indexPath2ForconditionalDisplacement]))? YES:NO;

    if (showLock) {
        lockLabel.text = self.lockLabelText;
    } else if (showConditionalExchangeLock) {
        lockLabel.text = self.conditionalDisplacementLabelText;
    } else {
        lockLabel.text = nil;
    }
    
    itemLabel.alpha = (self.allowExchangesSwitch.on)? 1.0:0.5;
    itemLabel.text = [NSString stringWithFormat:@" %@", itemNumber];
    
    return cell;
}



//------------------------------------------------------------------------------------
#pragma mark - SSCollectionViewExchangeControllerDelegate protocol required methods...

- (void)    exchangeController:(SSCollectionViewExchangeController *)exchangeController
   didExchangeItemAtIndexPath1:(NSIndexPath *)indexPath1
          withItemAtIndexPath2:(NSIndexPath *)indexPath2
{
    // Called for each individual exchange within an exchange event. There may be one exchange or two per
    // event. In all cases the delegate should just update the model by exchanging the elements at the
    // indicated index paths. Refer to the Exchange Event description and the Exchange Transaction and
    // Event Timeline. This method provides the delegate with an opportunity to keep its model in
    // sync with changes happening on the view.
    
    [self exchangeItemAtIndexPath1:indexPath1 withItemAtIndexPath2:indexPath2];
}

- (void)exchangeControllerDidFinishExchangeEvent:(SSCollectionViewExchangeController *)exchangeController
{
    // Called when an exchange event finishes within an exchange transaction. This method
    // provides the delegate with an opportunity to perform live updating as the user drags.
    
    [self updateSumLabels];
    [self logModel];
}

- (void)exchangeControllerDidFinishExchangeTransaction:(SSCollectionViewExchangeController *)exchangeController
                                        withIndexPath1:(NSIndexPath *)indexPath1
                                            indexPath2:(NSIndexPath *)indexPath2
{
    // Called when an exchange transaction completes (the user lifts his/her finger). The
    // index paths represent the two items in the final exchange. Do not exchange these items,
    // you already have. This method allows the delegate to perform any task required at the end
    // of the transaction such as setting up for undo. If the user dragged back to the starting
    // position and released (effectively nothing was exchanged) the index paths will be the same.
    
    // In this example, prepare for undo...
    [self prepareForUndoWithIndexPath1:indexPath1 indexPath2:indexPath2];
}

- (void)exchangeControllerDidCancelExchangeTransaction:(SSCollectionViewExchangeController *)exchangeController {

    [self updateSumLabels];
    [self logModel];
}



//------------------------------------------------------------------------------------
#pragma mark - SSCollectionViewExchangeControllerDelegate protocol optional methods...

- (BOOL)exchangeControllerCanBeginExchangeTransaction:(SSCollectionViewExchangeController *)exchangeController
                                  withItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // If implemented, called before beginning an exchange transaction to determine if it is ok to begin.
    // Implement this method if:
    //  1. The delegate needs to know when an exchange transaction begins so it can prepare (update
    //      its UI, turn off other gestures, etc). If you return YES it is safe to assume that the
    //      exchange transaction will begin.
    //  2. And/or the delegate conditionally allows exchanges. For example, maybe exchanges are allowed
    //      only when editing.
    //  3. And/or some of the items in the collection view can't be moved. The item at indexPath is the
    //      item that will be moved. Important note: Whether an item can be moved is determined here.
    //      Whether an item can be displaced is determined in the canDisplaceItemAtIndexPath: method.
    //      If an item can't be moved and can't be displaced you need to implement both methods.
    // Return NO if you do not want this exchange transaction to begin. If not implemented the
    // exchange controller assumes YES.
    
    if (self.allowExchangesSwitch.on == NO) return NO;
    
    if (self.lockItemAtZeroZeroSwitch.on && [indexPath isEqual:self.indexPathZeroZero]) return NO;
    // It is important to understand that this does not prevent the item at 0,0 from being displaced
    // later during an exchange transaction. If that was also required you would implement that in the
    // canDisplaceItem... delegate method.

    
    // Otherwise...
    return YES;
    
}


- (BOOL)          exchangeController:(SSCollectionViewExchangeController *)exchangeController
          canDisplaceItemAtIndexPath:(NSIndexPath *)indexPathOfItemToDisplace
   withItemBeingDraggedFromIndexPath:(NSIndexPath *)indexPathOfItemBeingDragged {
    
    // If implemented, called throughout the exchange transaction to determine if it’s ok to exchange
    // the two items. Implement this method if your collection view contains items that cannot be
    // exchanged at all or if there may be a situation where the item to displace cannot be exchanged
    // with the particular item being dragged. If not implemented, the default is YES.

    BOOL canDisplace = YES;
    
    if (self.lockItemAtZeroZeroSwitch.on && [indexPathOfItemToDisplace isEqual:self.indexPathZeroZero]) {
        
        canDisplace = NO;
        
    } else if (self.conditionalExchangeSwitch.on) {

        // In this completely contrived case if the conditional exchange switch is on
        // the two conditional index paths can be exchanged only with each other.
        //
        // The logic is a bit twisted but the point is that you can implement your own logic here
        // to manage whatever conditional exchange requirements you have.

        BOOL indexPathOfItemBeingDraggedMatches = ([indexPathOfItemBeingDragged isEqual:self.indexPath1ForconditionalDisplacement] ||
                                                   [indexPathOfItemBeingDragged isEqual:self.indexPath2ForconditionalDisplacement])? YES:NO;
        BOOL indexPathOfItemToDisplaceMatches = ([indexPathOfItemToDisplace isEqual:self.indexPath1ForconditionalDisplacement] ||
                                                 [indexPathOfItemToDisplace isEqual:self.indexPath2ForconditionalDisplacement])? YES:NO;
        
        if (indexPathOfItemBeingDraggedMatches) {
            
            // The item being dragged is one of the mutually exchangeable items...
            // Allow only if the other one is too.
            
            if (!indexPathOfItemToDisplaceMatches) canDisplace = NO;
            
        } else {
            
            // The item being dragged isn't one of the mutually exchangeable items.
            // But the one to be displaced might be...
            
            if (indexPathOfItemToDisplaceMatches) canDisplace = NO;
        }
    }
    
    return canDisplace;

}


- (UIView *)             exchangeController:(SSCollectionViewExchangeController *)exchangeController
    viewForCatchRectangleForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    
    if (self.catchRectangleSwitch.on) {
        UIView *catchRectangle = [cell viewWithTag:CATCH_RECTANGLE_TAG];
        return catchRectangle;
    } else {
        return cell;
    }
    
}

@end
