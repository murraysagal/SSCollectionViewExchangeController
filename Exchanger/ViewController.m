//
//  ViewController.m
//  Exchanger
//
//  Created by Murray Sagal on 2012-10-30.
//  Copyright (c) 2012 Signature Software. All rights reserved.
//

/*
 
 This app demonstrates the capabilities of the SSCollectionViewExchangeFlowLayout class, 
 a subclass of UICollectionViewFlowLayout designed to exchange items in a 2 column grid.
 
 */

#import "ViewController.h"
#import "SSCollectionViewExchangeController.h"
#import "NSMutableArray+SSCollectionViewExchangeAdditions.h"


typedef NS_ENUM(NSInteger, SSCollectionViewSide) {
    SSCollectionViewSideLeft,
    SSCollectionViewSideRight
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

@property (strong, nonatomic) NSMutableArray *leftSide;
@property (strong, nonatomic) NSMutableArray *rightSide;

@property (strong, nonatomic) NSIndexPath *indexPath1ForLastExchange;
@property (strong, nonatomic) NSIndexPath *indexPath2ForLastExchange;

- (IBAction)reset:(id)sender;
- (IBAction)undo:(id)sender;

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
    
    // The SSCollectionViewExchangeController has created a layout and configured the collection
    // view to use it. The layout is a subclass of UICollectionViewFlowLayout specifically
    // designed to manage hiding and dimming items during the exchange process. But it has
    // not been configured. As a convenience the exchange controller can provide you with the
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
    // This is here simply to show how live updating is enabled by
    // the didFinishExchangeEvent delegate method.
    
    self.sumLeft.text =  [NSString stringWithFormat:@"%ld", (long)[self sumArray:self.leftSide]];
    self.sumRight.text = [NSString stringWithFormat:@"%ld", (long)[self sumArray:self.rightSide]];
}

- (IBAction)undo:(id)sender
{
    // This is a very basic example of undo, here simply to show how undo is enabled by the
    // didFinishExchangeTransactionWithItemAtIndexPath:andItemAtIndexPath: delegate method.
    
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
    // consider using a custom class for this cell
    // and creating a class method that returns the identifier

    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"itemCell" forIndexPath:indexPath];
    
    UILabel *itemLabel = (UILabel *)[cell viewWithTag:100];
    NSNumber *itemNumber = (indexPath.section == SSCollectionViewSideLeft)? self.leftSide[ indexPath.item ] : self.rightSide[ indexPath.item ];
    itemLabel.text = [NSString stringWithFormat:@" %@", itemNumber];
    
    return cell;
}



//----------------------------------------------------------------------------
#pragma mark - SSCollectionViewExchangeLayoutDelegate protocol methods...

- (void)exchangeItemAtIndexPath:(NSIndexPath *)indexPath1 withItemAtIndexPath:(NSIndexPath *)indexPath2
{
    // Called either one or two times during an exchange event. Allows the delegate
    // to keep the model synchronized with the changes occuring on the view. Refer
    // to the comments in the protocol definition.
    
    // Update the model. Not structured optimally, intention is readability...
    
    if ([indexPath1 isEqual:indexPath2])
    {
        // If the index paths are the same there's nothing to exchange...
        return;
    }
    
    // The index paths are not the same. What about the sections?
    
    if (indexPath1.section == indexPath2.section)
    {
        // The sections are the same. In other words the items to exchange
        // are in the same array.
        switch (indexPath1.section) {
                
            case SSCollectionViewSideLeft:
                [self.leftSide exchangeObjectAtIndex:indexPath1.item
                                   withObjectAtIndex:indexPath2.item];
                break;
                
            case SSCollectionViewSideRight:
                [self.rightSide exchangeObjectAtIndex:indexPath1.item
                                    withObjectAtIndex:indexPath2.item];
                break;
        }
        
    } else {
        
        // The sections are not the same. In other words the items being
        // exchanged are not in the same array.
        switch (indexPath1.section) {
                
            case SSCollectionViewSideLeft:
                [NSMutableArray exchangeItemInArray:self.leftSide
                                            atIndex:indexPath1.item
                                    withItemInArray:self.rightSide
                                            atIndex:indexPath2.item];
                break;
                
            case SSCollectionViewSideRight:
                [NSMutableArray exchangeItemInArray:self.rightSide
                                            atIndex:indexPath1.item
                                    withItemInArray:self.leftSide
                                            atIndex:indexPath2.item];
                break;
        }
    }
}

- (void)didFinishExchangeEvent
{
    // Called when an exchange event finishes. Refer to the comments in the protocol definition.
    // Allows the delegate to provide "live" updates as the user drags.
    
    // In this example update the sum labels and log the model.
    [self updateSumLabels];
    [self logModel];
}

- (void)didFinishExchangeTransactionWithItemAtIndexPath:(NSIndexPath *)firstItem andItemAtIndexPath:(NSIndexPath *)secondItem
{
    // Called at the end of the exchange transaction. Refer to the comments in the protocol definition.
    // Allows the delegate to perform any required action when the user completes the exchange.
    
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
