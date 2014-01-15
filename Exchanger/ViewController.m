//
//  ViewController.m
//  Exchanger
//
//  Created by Murray Sagal on 2012-10-30.
//  Copyright (c) 2014 Signature Software. All rights reserved.
//

/*
 
 This app demonstrates the capabilities of the SSCollectionViewExchangeController
 and SSCollectionViewExchangeLayout classes that are designed to exchange items 
 in a multi column grid.
 
 Refer to SSCollectionViewExchangeController.h for more comments. 
 
 */

#import "ViewController.h"
#import "SSCollectionViewExchangeController.h"
#import "NSMutableArray+SSCollectionViewExchangeAdditions.h"


NS_ENUM(NSInteger, CollectionViewSide) {
    CollectionViewSideLeft,
    CollectionViewSideMiddle,
    CollectionViewSideRight
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
    // Demonstrates how live updating is enabled by the didFinishExchangeEvent delegate method.
    
    self.sumLeft.text =  [NSString stringWithFormat:@"%ld", (long)[self sumArray:self.leftSide]];
    self.sumMiddle.text =  [NSString stringWithFormat:@"%ld", (long)[self sumArray:self.middle]];
    self.sumRight.text = [NSString stringWithFormat:@"%ld", (long)[self sumArray:self.rightSide]];
}

- (IBAction)undo:(id)sender
{
    // Demonstrates how undo is enabled by the
    // exchangeControllerDidFinishExchangeTransaction:withIndexPath1:indexPath2:: delegate method.
    
    if (self.indexPath1ForLastExchange != nil) {
        
        // Model...
        [self exchangeItemAtIndexPath1:self.indexPath1ForLastExchange withItemAtIndexPath2:self.indexPath2ForLastExchange];
        [self updateSumLabels];
        [self logModel];
        
        // View...
        [self.collectionView performBatchUpdates:^ {
            [self.collectionView moveItemAtIndexPath:self.indexPath1ForLastExchange toIndexPath:self.indexPath2ForLastExchange];
            [self.collectionView moveItemAtIndexPath:self.indexPath2ForLastExchange toIndexPath:self.indexPath1ForLastExchange];
        }
                                      completion:nil];
    }
}

- (void)exchangeItemAtIndexPath1:(NSIndexPath *)indexPath1 withItemAtIndexPath2:(NSIndexPath *)indexPath2 {
    
    NSMutableArray *array1 = [self arrayForSection:indexPath1.section];
    NSMutableArray *array2 = [self arrayForSection:indexPath2.section];
    
    [NSMutableArray exchangeItemInArray:array1
                                atIndex:indexPath1.item
                        withItemInArray:array2
                                atIndex:indexPath2.item];
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

- (void)logModel
{
    NSLog(@" ");
    NSLog(@"self.leftSide   |    self.middle    |    self.rightSide");
    
    for (int i=0; i<[self.leftSide count]; i++) {
        NSLog(@"          %@     |         %@        |          %@", self.leftSide[i], self.middle[i], self.rightSide[i]);
    }
    
    NSInteger sumLeft = [self sumArray:self.leftSide];
    NSInteger sumMiddle = [self sumArray:self.middle];
    NSInteger sumRight = [self sumArray:self.rightSide];
    
    NSLog(@" ");
    NSLog(@" sumLeft= %ld        sumMiddle= %ld      sumRight= %ld", (long)sumLeft, (long)sumMiddle, (long)sumRight);
    NSLog(@" ");
}

- (NSMutableArray *)arrayForSection:(NSUInteger)index {
    
    // Normally each section of a collection view has its own array. This is a simple example of how
    // you might map your sections to actual arrays. Using a technique like this simplifies the
    // implementation of the exchangeItemAtIndexPath:withItemAtIndexPath: delegate method.
    
    NSMutableArray *array;
    
    switch (index) {
        case CollectionViewSideLeft:
            array = self.leftSide;
            break;
            
        case CollectionViewSideMiddle:
            array = self.middle;
            break;
            
        case CollectionViewSideRight:
            array = self.rightSide;
            break;
    }
    return array;
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
    
    // To keep this example simple the custom cell doesn't have a class. So the label is retrieved with a tag...
    UILabel *itemLabel = (UILabel *)[cell viewWithTag:999];
    
    NSNumber *itemNumber;
    
    switch (indexPath.section) {
        case CollectionViewSideLeft:
            itemNumber = self.leftSide[ indexPath.item ];
            break;
            
        case CollectionViewSideMiddle:
            itemNumber = self.middle[ indexPath.item ];
            break;
            
        case CollectionViewSideRight:
            itemNumber = self.rightSide[ indexPath.item ];
            break;
    }
    
    itemLabel.text = [NSString stringWithFormat:@" %@", itemNumber];
    
    return cell;
}



//-----------------------------------------------------------------------
#pragma mark - SSCollectionViewExchangeControllerDelegate protocol methods...

- (void)    exchangeController:(SSCollectionViewExchangeController *)exchangeController
   didExchangeItemAtIndexPath1:(NSIndexPath *)indexPath1
          withItemAtIndexPath2:(NSIndexPath *)indexPath2
{
    // Allows the delegate to keep the model synchronized with the changes occuring on the view.
    // Called either one or two times during an exchange event.
    // Refer to the additional comments in the protocol definition.
    
    [self exchangeItemAtIndexPath1:indexPath1 withItemAtIndexPath2:indexPath2];
}

- (void)exchangeControllerDidFinishExchangeEvent:(SSCollectionViewExchangeController *)exchangeController
{
    // Allows the delegate to provide live updates as the user drags.
    // Called when an exchange event finishes.
    // Refer to the additional comments in the protocol definition.
    
    [self updateSumLabels];
    [self logModel];
}

- (void)exchangeControllerDidFinishExchangeTransaction:(SSCollectionViewExchangeController *)exchangeController
                                        withIndexPath1:(NSIndexPath *)indexPath1
                                            indexPath2:(NSIndexPath *)indexPath2
{
    // Allows the delegate to perform any required action when the user completes the exchange.
    // Called at the end of the exchange transaction.
    // Refer to the additional comments in the protocol definition.
    
    // In this example, simply prepare for undo...
    self.indexPath1ForLastExchange = indexPath1;
    self.indexPath2ForLastExchange = indexPath2;
}

- (BOOL)exchangeControllerCanExchange:(SSCollectionViewExchangeController *)exchangeController
{
    // Return whether the collection view can exchange items at this time.
    // For example, you may only allow exchanges when editing.
    
    // This example always returns YES.
    return YES;
}

- (void)animateCatchForExchangeController:(SSCollectionViewExchangeController *)exchangeController
                             withSnapshot:(UIView *)snapshot {

    NSTimeInterval duration = 0.20;
    CGFloat blinkToScale = 1.20;
    CGFloat finalScale = 1.0;
    
    [UIView animateWithDuration:duration animations:^ {
        snapshot.transform = CGAffineTransformMakeScale(blinkToScale, blinkToScale);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:duration animations:^ {
            snapshot.transform = CGAffineTransformMakeScale(finalScale, finalScale);
        }];
    }];
}

- (void)animateReleaseForExchangeController:(SSCollectionViewExchangeController *)exchangeController
                               withSnapshot:(UIView *)snapshot
                                    toPoint:(CGPoint)centerOfCell
                     cellAtOriginalLocation:(UICollectionViewCell *)cellAtOriginalLocation
                            completionBlock:(PostReleaseCompletionBlock)completionBlock {
    
    NSTimeInterval duration = 0.20;
    CGFloat blinkToScale = 1.05;
    CGFloat finalScale = 1.0;
    
    [UIView animateWithDuration:duration animations:^ {
        snapshot.center = centerOfCell;
        cellAtOriginalLocation.alpha = 1.0;
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:duration animations:^ {
            snapshot.transform = CGAffineTransformMakeScale(blinkToScale, blinkToScale);
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:duration animations:^ {
                snapshot.transform = CGAffineTransformMakeScale(finalScale, finalScale);
            } completion:^(BOOL finished) {
                completionBlock(duration);
            }];
        }];
    }];
}


@end
