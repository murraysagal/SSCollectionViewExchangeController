//
//  ViewController.m
//  Exchanger
//
//  Created by Murray Sagal on 2012-10-30.
//  Copyright (c) 2012 Signature Software. All rights reserved.
//

/*
 
 This app demonstrates the capabilities of the SSCollectionViewExchangeController
 and SSCollectionViewExchangeLayout classes that are designed to exchange items 
 in a 2 column grid.
 
 Refer to SSCollectionViewExchangeController.h for more comments. 
 
 */

#import "ViewController.h"
#import "SSCollectionViewExchangeController.h"
#import "NSMutableArray+SSCollectionViewExchangeAdditions.h"


NS_ENUM(NSInteger, CollectionViewSide) {
    CollectionViewSideLeft,
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
@property (weak, nonatomic) IBOutlet UILabel *sumRight;

- (IBAction)reset:(id)sender;
- (IBAction)undo:(id)sender;

@property (strong, nonatomic) NSMutableArray *leftSide;
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
    layout.itemSize = CGSizeMake(150, 30);
    layout.minimumLineSpacing = 1;
    layout.minimumInteritemSpacing = 1;
    layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

}



//---------------------------------
#pragma mark - Instance methods...

- (void)prepareModel
{    
    NSArray *temp1to10 =    @[  @1,  @2,  @3,  @4,  @5,  @6,  @7,  @8,  @9, @10 ];
    NSArray *temp11to20 =   @[ @11, @12, @13, @14, @15, @16, @17, @18, @19, @20 ];
    
    self.leftSide = [NSMutableArray arrayWithArray:temp1to10];
    self.rightSide = [NSMutableArray arrayWithArray:temp11to20];
}

- (void)updateSumLabels
{
    // Demonstrates how live updating is enabled by the didFinishExchangeEvent delegate method.
    
    self.sumLeft.text =  [NSString stringWithFormat:@"%ld", (long)[self sumArray:self.leftSide]];
    self.sumRight.text = [NSString stringWithFormat:@"%ld", (long)[self sumArray:self.rightSide]];
}

- (IBAction)undo:(id)sender
{
    // Demonstrates how undo is enabled by the didFinishExchangeTransactionWithItemAtIndexPath:andItemAtIndexPath: delegate method.
    
    if (self.indexPath1ForLastExchange != nil) {
        
        // Model...
        [self exchangeItemAtIndexPath:self.indexPath1ForLastExchange withItemAtIndexPath:self.indexPath2ForLastExchange];
        [self updateSumLabels];
        [self logModel];
        
        // View...
        [self.collectionView performBatchUpdates:^{
            [self.collectionView moveItemAtIndexPath:self.indexPath1ForLastExchange toIndexPath:self.indexPath2ForLastExchange];
            [self.collectionView moveItemAtIndexPath:self.indexPath2ForLastExchange toIndexPath:self.indexPath1ForLastExchange];
        }
                                      completion:nil];
    }
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
//    NSInteger sum = 0;
//    for (NSNumber *number in array) {
//        sum += [number integerValue];
//    }
//    return sum;
    
    __block NSInteger sum = 0;
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        sum += [obj integerValue];
    }];
    return sum;
}

- (void)logModel
{
    NSLog(@" ");
    NSLog(@"self.leftSide   |    self.rightSide");
    
    for (int i=0; i<[self.leftSide count]; i++) {
        NSLog(@"          %@     |    %@", self.leftSide[i], self.rightSide[i]);
    }
    
    NSInteger sumLeft = [self sumArray:self.leftSide];
    NSInteger sumRight = [self sumArray:self.rightSide];
    
    NSLog(@" ");
    NSLog(@"    sumLeft= %ld | sumRight= %ld", (long)sumLeft, (long)sumRight);
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
    return 2;
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
    
    NSNumber *itemNumber = (indexPath.section == CollectionViewSideLeft)? self.leftSide[ indexPath.item ] : self.rightSide[ indexPath.item ];
    itemLabel.text = [NSString stringWithFormat:@" %@", itemNumber];
    
    return cell;
}



//----------------------------------------------------------------------------
#pragma mark - SSCollectionViewExchangeLayoutDelegate protocol methods...

- (void)exchangeItemAtIndexPath:(NSIndexPath *)indexPath1 withItemAtIndexPath:(NSIndexPath *)indexPath2
{
    // Allows the delegate to keep the model synchronized with the changes occuring on the view.
    // Called either one or two times during an exchange event.
    // Refer to the additional comments in the protocol definition.
    
    NSMutableArray *array1 = [self arrayForSection:indexPath1.section];
    NSMutableArray *array2 = [self arrayForSection:indexPath2.section];
    
    [NSMutableArray exchangeItemInArray:array1
                                atIndex:indexPath1.item
                        withItemInArray:array2
                                atIndex:indexPath2.item];
    
}

- (void)didFinishExchangeEvent
{
    // Allows the delegate to provide live updates as the user drags.
    // Called when an exchange event finishes.
    // Refer to the additional comments in the protocol definition.
    
    [self updateSumLabels];
    [self logModel];
}

- (void)didFinishExchangeTransactionWithItemAtIndexPath:(NSIndexPath *)firstItem andItemAtIndexPath:(NSIndexPath *)secondItem
{
    // Allows the delegate to perform any required action when the user completes the exchange.
    // Called at the end of the exchange transaction.
    // Refer to the additional comments in the protocol definition.
    
    // In this example, simply prepare for undo...
    self.indexPath1ForLastExchange = firstItem;
    self.indexPath2ForLastExchange = secondItem;
}

- (BOOL)canExchange
{
    // Return whether the collection view can exchange items at this time.
    // For example, you may only allow exchanges when editing.
    
    // This example always returns YES.
    return YES;
}


@end
