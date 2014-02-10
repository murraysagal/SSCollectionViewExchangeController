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
#import "NSIndexPath+RandomAdditions.h"
#import "NSMutableSet+AddObjectIfNotNil.h"


// Constants for NSUserDefault keys and other strings...

static NSString * const kFirstRunKey = @"firstRun";

// switches...
static NSString * const kAllowExchangesSwitchStateKey = @"allowExchangesSwitchState";
static NSString * const kConditionalExchangeSwitchStateKey = @"conditionalExchangeSwitchState";
static NSString * const kLockItemSwitchStateKey = @"lockItemSwitchState";
static NSString * const kCatchRectangleSwitchStateKey = @"catchRectangleSwitchState";

// index paths...
static NSString * const kIndexPathForLockedItem_SectionKey = @"indexPathForLockedItem_Section";
static NSString * const kIndexPathForLockedItem_ItemKey = @"indexPathForLockedItem_Item";

static NSString * const kIndexPath1ForConditionalDisplacement_SectionKey = @"indexPath1ForConditionalDisplacement_Section";
static NSString * const kIndexPath1ForConditionalDisplacement_ItemKey = @"indexPath1ForConditionalDisplacement_Item";

static NSString * const kIndexPath2ForConditionalDisplacement_SectionKey = @"indexPath2ForConditionalDisplacement_Section";
static NSString * const kIndexPath2ForConditionalDisplacement_ItemKey = @"indexPath2ForConditionalDisplacement_Item";

static NSString * const kIndexPath1ForLastExchange_SectionKey = @"indexPath1ForLastExchange_Section";
static NSString * const kIndexPath1ForLastExchange_ItemKey = @"indexPath1ForLastExchange_Item";

static NSString * const kIndexPath2ForLastExchange_SectionKey = @"indexPath2ForLastExchange_Section";
static NSString * const kIndexPath2ForLastExchange_ItemKey = @"indexPath2ForLastExchange_Item";

// model...
static NSString * const kLeftSideKey = @"leftSide";
static NSString * const kMiddleKey = @"middle";
static NSString * const kRightSideKey = @"rightSide";

// cell...
static NSUInteger const kCellLabelTag = 1;
static NSUInteger const kCatchRectangleTag = 2;
static NSUInteger const kLockLabelTag = 3;

// undo button...
static NSString * const kUndoText = @"Undo";
static NSString * const kRedoText = @"Redo";



// helps map collection view sections to arrays...
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
@property (weak, nonatomic) IBOutlet UIButton *undoButton;

@property (strong, nonatomic) NSMutableArray *leftSide;
@property (strong, nonatomic) NSMutableArray *middle;
@property (strong, nonatomic) NSMutableArray *rightSide;

@property (strong, nonatomic) NSIndexPath *indexPath1ForLastExchange;
@property (strong, nonatomic) NSIndexPath *indexPath2ForLastExchange;

@property (strong, nonatomic) SSCollectionViewExchangeController *exchangeController;

- (IBAction)catchRectangleSwitchChanged:(UISwitch *)sender;
@property (weak, nonatomic) IBOutlet UISwitch *catchRectangleSwitch;

- (IBAction)lockItemSwitchChanged:(UISwitch *)sender;
@property (weak, nonatomic) IBOutlet UISwitch *lockItemSwitch;
@property (strong, nonatomic) NSIndexPath *indexPathForLockedItem;
@property (strong, nonatomic) NSString *lockLabelText;

- (IBAction)conditionalExchangeSwitchChanged:(UISwitch *)sender;
@property (weak, nonatomic) IBOutlet UISwitch *conditionalExchangeSwitch;
@property (strong, nonatomic) NSString *conditionalDisplacementLabelText;
@property (strong, nonatomic) NSIndexPath *indexPath1ForConditionalDisplacement;
@property (strong, nonatomic) NSIndexPath *indexPath2ForConditionalDisplacement;

- (IBAction)allowExchangesSwitchChanged:(UISwitch *)sender;
@property (weak, nonatomic) IBOutlet UISwitch *allowExchangesSwitch;

@property (strong, nonatomic) NSUserDefaults *userDefaults;

@end




@implementation ViewController


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([self isFirstRun]) {
        NSLog(@"is first run");
        [self useDefaultModel];
        [self saveModel];
        [self useDefaultSwitchStates];
        [self saveSwitchStates];
        [self saveIndexPaths];
        [self saveFirstRun];
        
    } else {
        NSLog(@"is not first run");
        [self useSavedModel];
        [self useSavedSwitchStates];
        [self useSavedIndexPaths];
        
    }
    
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
    
}



//------------------------------------------------------------------------------------
#pragma mark - SSCollectionViewExchangeControllerDelegate protocol required methods...

- (void)    exchangeController:(SSCollectionViewExchangeController *)exchangeController
   didExchangeItemAtIndexPath1:(NSIndexPath *)indexPath1
          withItemAtIndexPath2:(NSIndexPath *)indexPath2 {
    
    // Called for each individual exchange within an exchange event. There may be one exchange or two per
    // event. In all cases the delegate should just update the model by exchanging the elements at the
    // indicated index paths. Refer to the Exchange Event description and the Exchange Transaction and
    // Event Timeline. This method provides the delegate with an opportunity to keep its model in
    // sync with changes happening on the view.
    
    [self exchangeItemAtIndexPath1:indexPath1 withItemAtIndexPath2:indexPath2];
    
}

- (void)exchangeControllerDidFinishExchangeEvent:(SSCollectionViewExchangeController *)exchangeController {
    
    // Called when an exchange event finishes within an exchange transaction. This method
    // provides the delegate with an opportunity to perform live updating as the user drags.
    
    [self updateSumLabels];
    [self logModel];
    
}

- (void)exchangeControllerDidFinishExchangeTransaction:(SSCollectionViewExchangeController *)exchangeController
                                        withIndexPath1:(NSIndexPath *)indexPath1
                                            indexPath2:(NSIndexPath *)indexPath2 {
    
    // Called when an exchange transaction completes (the user lifts his/her finger). The
    // index paths represent the two items in the final exchange. Do not exchange these items,
    // you already have. This method allows the delegate to perform any task required at the end
    // of the transaction such as setting up for undo. If the user dragged back to the starting
    // position and released (effectively nothing was exchanged) the index paths will be the same.
    
    [self saveModel];
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
    
    if (self.lockItemSwitch.on && [indexPath isEqual:self.indexPathForLockedItem]) return NO;
    // It is important to understand that this does not prevent the locked item from being displaced
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
    
    if (self.lockItemSwitch.on && [indexPathOfItemToDisplace isEqual:self.indexPathForLockedItem]) {
        
        canDisplace = NO;
        
    } else if (self.conditionalExchangeSwitch.on) {
        
        // In this completely contrived case if the conditional exchange switch is on
        // the two conditional index paths can be exchanged only with each other.
        //
        // The logic is a bit twisted but the point is that you can implement your own logic here
        // to manage whatever conditional exchange requirements you have.
        
        BOOL indexPathOfItemBeingDraggedMatches = ([indexPathOfItemBeingDragged isEqual:self.indexPath1ForConditionalDisplacement] ||
                                                   [indexPathOfItemBeingDragged isEqual:self.indexPath2ForConditionalDisplacement])? YES:NO;
        BOOL indexPathOfItemToDisplaceMatches = ([indexPathOfItemToDisplace isEqual:self.indexPath1ForConditionalDisplacement] ||
                                                 [indexPathOfItemToDisplace isEqual:self.indexPath2ForConditionalDisplacement])? YES:NO;
        
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
        UIView *catchRectangle = [cell viewWithTag:kCatchRectangleTag];
        return catchRectangle;
    } else {
        return cell;
    }
    
}



//-----------------------------------------------------------------
#pragma mark - UICollectionView data source and delegate methods...

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return 3;
    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return 10;
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"itemCell" forIndexPath:indexPath];
    
    // The collection view cell doesn't have a class.
    // So subviews are retrieved with a tag.
    UIView *catchRectangle = [cell viewWithTag:kCatchRectangleTag];
    UILabel *lockLabel = (UILabel *)[cell viewWithTag:kLockLabelTag];
    UILabel *itemLabel = (UILabel *)[cell viewWithTag:kCellLabelTag];
    
    catchRectangle.hidden = (self.catchRectangleSwitch.on)? NO:YES;
    
    BOOL showLock = self.lockItemSwitch.on && [indexPath isEqual:self.indexPathForLockedItem];
    BOOL showConditionalExchangeLock = (self.conditionalExchangeSwitch.on &&
                                        ([indexPath isEqual:self.indexPath1ForConditionalDisplacement] ||
                                         [indexPath isEqual:self.indexPath2ForConditionalDisplacement]))? YES:NO;
    
    if (showLock) {
        lockLabel.text = self.lockLabelText;
    } else if (showConditionalExchangeLock) {
        lockLabel.text = self.conditionalDisplacementLabelText;
    } else {
        lockLabel.text = nil;
    }
    
    itemLabel.alpha = (self.allowExchangesSwitch.on)? 1.0:0.5;
    itemLabel.text = [NSString stringWithFormat:@" %@", [self arrayForSection:indexPath.section][ indexPath.item ]];
    
    return cell;
}



//---------------------------------
#pragma mark - Instance methods...

- (void)updateSumLabels {
    
    // Demonstrates how live updating is enabled by the exchangeControllerDidFinishExchangeEvent: delegate method.
    
    self.sumLeft.text =     [NSString stringWithFormat:@"%ld", (long)[self sumArray:self.leftSide]];
    self.sumMiddle.text =   [NSString stringWithFormat:@"%ld", (long)[self sumArray:self.middle]];
    self.sumRight.text =    [NSString stringWithFormat:@"%ld", (long)[self sumArray:self.rightSide]];
}

- (IBAction)undo:(id)sender {
    
    // Demonstrates how undo is enabled by the
    // exchangeControllerDidFinishExchangeTransaction:withIndexPath1:indexPath2:: delegate method.
    
    if (self.indexPath1ForLastExchange != nil) {
        
        [self.collectionView performBatchUpdates:^ {
            
            [self.collectionView moveItemAtIndexPath:self.indexPath1ForLastExchange toIndexPath:self.indexPath2ForLastExchange];
            [self.collectionView moveItemAtIndexPath:self.indexPath2ForLastExchange toIndexPath:self.indexPath1ForLastExchange];
            
        }
                                      completion:^(BOOL finished) {
                                          
                                          [self exchangeItemAtIndexPath1:self.indexPath1ForLastExchange
                                                    withItemAtIndexPath2:self.indexPath2ForLastExchange];
                                          [self saveModel];
                                          [self updateSumLabels];
                                          
                                          [self logModel];
                                          
                                      }];
        
        NSString *title = ([[self.undoButton titleForState:UIControlStateNormal] isEqualToString:kUndoText])? kRedoText : kUndoText;
        [self.undoButton setTitle:title forState:UIControlStateNormal];
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
    // implementation of the exchangeItemAtIndexPath1:withItemAtIndexPath2: method.
    
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

- (IBAction)reset:(id)sender {
    
    [self useDefaultModel];
    [self saveModel];
    [self logModel];
    
    [self.collectionView reloadData];
    [self updateSumLabels];
    
    [self.undoButton setTitle:kUndoText forState:UIControlStateNormal];
    self.indexPath1ForLastExchange = nil;
    self.indexPath2ForLastExchange = nil;
    [self saveIndexPaths];
}

- (NSInteger)sumArray:(NSArray *)array {
    
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
        [self saveIndexPaths];
        
    }
}

- (void)logModel {
    
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

- (IBAction)allowExchangesSwitchChanged:(UISwitch *)sender {
    
    [self.collectionView reloadData];
    [self saveSwitchStates];
    
}

- (IBAction)lockItemSwitchChanged:(UISwitch *)sender {
    
    if (sender.on) {
        
        NSArray *arrays = @[self.leftSide, self.middle, self.rightSide];
        
        NSMutableSet *excludingIndexPaths = [[NSMutableSet alloc] init];
        [excludingIndexPaths addObjectIfNotNil:self.indexPathForLockedItem];
        [excludingIndexPaths addObjectIfNotNil:self.indexPath1ForLastExchange];
        [excludingIndexPaths addObjectIfNotNil:self.indexPath2ForLastExchange];
        [excludingIndexPaths addObjectIfNotNil:self.indexPath1ForConditionalDisplacement];
        [excludingIndexPaths addObjectIfNotNil:self.indexPath2ForConditionalDisplacement];
        
        self.indexPathForLockedItem = [NSIndexPath randomIndexPathInArrays:arrays excludingIndexPaths:excludingIndexPaths];
        
    } else {
        
        self.indexPathForLockedItem = nil;
        
    }
    
    [self.collectionView reloadData];
    [self saveSwitchStates];
    [self saveIndexPaths];
    
}

- (IBAction)conditionalExchangeSwitchChanged:(UISwitch *)sender {
    
    if (sender.on) {
        
        NSArray *arrays = @[self.leftSide, self.middle, self.rightSide];
        
        NSMutableSet *excludingIndexPaths = [[NSMutableSet alloc] init];
        [excludingIndexPaths addObjectIfNotNil:self.indexPathForLockedItem];
        [excludingIndexPaths addObjectIfNotNil:self.indexPath1ForLastExchange];
        [excludingIndexPaths addObjectIfNotNil:self.indexPath2ForLastExchange];
        self.indexPath1ForConditionalDisplacement =[NSIndexPath randomIndexPathInArrays:arrays excludingIndexPaths:excludingIndexPaths];
        
        [excludingIndexPaths addObjectIfNotNil:self.indexPath1ForConditionalDisplacement];
        self.indexPath2ForConditionalDisplacement = [NSIndexPath randomIndexPathInArrays:arrays excludingIndexPaths:excludingIndexPaths];
        
    } else {
        
        self.indexPath1ForConditionalDisplacement = nil;
        self.indexPath2ForConditionalDisplacement = nil;
        
    }
    
    [self.collectionView reloadData];
    [self saveSwitchStates];
    [self saveIndexPaths];
    
}

- (IBAction)catchRectangleSwitchChanged:(UISwitch *)sender {
    
    [self.collectionView reloadData];
    [self saveSwitchStates];
    
}



//--------------------------------------------------
#pragma mark - Defaults and model related methods...

- (BOOL)isFirstRun {
    
    id firstRunObject = [self.userDefaults objectForKey:kFirstRunKey];
    
    if (firstRunObject == nil) {
        return YES;
    } else {
        return NO;
    }
}

- (void)saveFirstRun {
    
    [self.userDefaults setObject:@0 forKey:kFirstRunKey];
    [self.userDefaults synchronize]; // important moment
    
}

- (void)useDefaultSwitchStates {
    
    self.allowExchangesSwitch.on = YES;
    self.conditionalExchangeSwitch.on = NO;
    self.lockItemSwitch.on = NO;
    self.catchRectangleSwitch.on = NO;
    
}

- (void)useSavedSwitchStates {
    
    self.allowExchangesSwitch.on = [self.userDefaults boolForKey:kAllowExchangesSwitchStateKey];
    self.conditionalExchangeSwitch.on = [self.userDefaults boolForKey:kConditionalExchangeSwitchStateKey];
    self.lockItemSwitch.on = [self.userDefaults boolForKey:kLockItemSwitchStateKey];
    self.catchRectangleSwitch.on = [self.userDefaults boolForKey:kCatchRectangleSwitchStateKey];
    
}

- (void)saveSwitchStates {
    
    [self.userDefaults setBool:self.allowExchangesSwitch.on forKey:kAllowExchangesSwitchStateKey];
    [self.userDefaults setBool:self.conditionalExchangeSwitch.on forKey:kConditionalExchangeSwitchStateKey];
    [self.userDefaults setBool:self.lockItemSwitch.on forKey:kLockItemSwitchStateKey];
    [self.userDefaults setBool:self.catchRectangleSwitch.on forKey:kCatchRectangleSwitchStateKey];
    
}

- (void)useSavedIndexPaths {
    
    NSInteger section;
    NSInteger item;
    
    section = [self.userDefaults integerForKey:kIndexPathForLockedItem_SectionKey];
    item = [self.userDefaults integerForKey:kIndexPathForLockedItem_ItemKey];
    self.indexPathForLockedItem = (section < 0)? nil : [NSIndexPath indexPathForItem:item inSection:section];

    section = [self.userDefaults integerForKey:kIndexPath1ForConditionalDisplacement_SectionKey];
    item = [self.userDefaults integerForKey:kIndexPath1ForConditionalDisplacement_ItemKey];
    self.indexPath1ForConditionalDisplacement = (section < 0)? nil : [NSIndexPath indexPathForItem:item inSection:section];
    
    section = [self.userDefaults integerForKey:kIndexPath2ForConditionalDisplacement_SectionKey];
    item = [self.userDefaults integerForKey:kIndexPath2ForConditionalDisplacement_ItemKey];
    self.indexPath2ForConditionalDisplacement = (section < 0)? nil : [NSIndexPath indexPathForItem:item inSection:section];
    
    section = [self.userDefaults integerForKey:kIndexPath1ForLastExchange_SectionKey];
    item = [self.userDefaults integerForKey:kIndexPath1ForLastExchange_ItemKey];
    self.indexPath1ForLastExchange = (section < 0)? nil : [NSIndexPath indexPathForItem:item inSection:section];
    
    section = [self.userDefaults integerForKey:kIndexPath2ForLastExchange_SectionKey];
    item = [self.userDefaults integerForKey:kIndexPath2ForLastExchange_ItemKey];
    self.indexPath2ForLastExchange = (section < 0)? nil : [NSIndexPath indexPathForItem:item inSection:section];
    
}

- (void)saveIndexPaths {
    
    // index paths that are nil get saved with -1
    
    NSInteger section;
    NSInteger item;
    
    section = (self.indexPathForLockedItem)? self.indexPathForLockedItem.section : -1;
    item = (self.indexPathForLockedItem)? self.indexPathForLockedItem.item : -1;
    [self.userDefaults setInteger:section forKey:kIndexPathForLockedItem_SectionKey];
    [self.userDefaults setInteger:item forKey:kIndexPathForLockedItem_ItemKey];
    
    section = (self.indexPath1ForConditionalDisplacement)? self.indexPath1ForConditionalDisplacement.section : -1;
    item = (self.indexPath1ForConditionalDisplacement)? self.indexPath1ForConditionalDisplacement.item : -1;
    [self.userDefaults setInteger:section forKey:kIndexPath1ForConditionalDisplacement_SectionKey];
    [self.userDefaults setInteger:item forKey:kIndexPath1ForConditionalDisplacement_ItemKey];
    
    section = (self.indexPath2ForConditionalDisplacement)? self.indexPath2ForConditionalDisplacement.section : -1;
    item = (self.indexPath2ForConditionalDisplacement)? self.indexPath2ForConditionalDisplacement.item : -1;
    [self.userDefaults setInteger:section forKey:kIndexPath2ForConditionalDisplacement_SectionKey];
    [self.userDefaults setInteger:item forKey:kIndexPath2ForConditionalDisplacement_ItemKey];
    
    section = (self.indexPath1ForLastExchange)? self.indexPath1ForLastExchange.section : -1;
    item = (self.indexPath1ForLastExchange)? self.indexPath1ForLastExchange.item : -1;
    [self.userDefaults setInteger:section forKey:kIndexPath1ForLastExchange_SectionKey];
    [self.userDefaults setInteger:item forKey:kIndexPath1ForLastExchange_ItemKey];
    
    section = (self.indexPath2ForLastExchange)? self.indexPath2ForLastExchange.section : -1;
    item = (self.indexPath2ForLastExchange)? self.indexPath2ForLastExchange.item : -1;
    [self.userDefaults setInteger:section forKey:kIndexPath2ForLastExchange_SectionKey];
    [self.userDefaults setInteger:item forKey:kIndexPath2ForLastExchange_ItemKey];
    
}

- (void)useDefaultModel {
    
    NSArray *temp1to10 =    @[  @1,  @2,  @3,  @4,  @5,  @6,  @7,  @8,  @9, @10 ];
    NSArray *temp11to20 =   @[ @11, @12, @13, @14, @15, @16, @17, @18, @19, @20 ];
    NSArray *temp21to30 =   @[ @21, @22, @23, @24, @25, @26, @27, @28, @29, @30 ];
    
    self.leftSide = [NSMutableArray arrayWithArray:temp1to10];
    self.middle = [NSMutableArray arrayWithArray:temp11to20];
    self.rightSide = [NSMutableArray arrayWithArray:temp21to30];
    
}

- (void)useSavedModel {
    
    self.leftSide = [self.userDefaults objectForKey:kLeftSideKey];
    self.middle = [self.userDefaults objectForKey:kMiddleKey];
    self.rightSide = [self.userDefaults objectForKey:kRightSideKey];
    
}

- (void)saveModel {
    
    [self.userDefaults setObject:self.leftSide forKey:kLeftSideKey];
    [self.userDefaults setObject:self.middle forKey:kMiddleKey];
    [self.userDefaults setObject:self.rightSide forKey:kRightSideKey];
    
}

@end


