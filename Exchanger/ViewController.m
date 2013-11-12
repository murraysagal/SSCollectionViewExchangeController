//
//  ViewController.m
//  Swapper
//
//  Created by Murray Sagal on 2012-10-30.
//  Copyright (c) 2012 Signature Software. All rights reserved.
//

/*
    The main purpose of this app is to demonstrate a problem related to headers and footers in 
    collection views. The collection view displays as two columns of 10 rows. An item can be 
    exchanged with any other item by dragging. 
 
    By commenting and uncommenting the relevant code the collection view can be made to display
    its supplementary view as a footer for section 0 or a header for section 1. Visually it looks 
    the same with either method. The header or footer is the blue bar between the columns. 
 
    And either way the problem is apparent
 
*/

#import "ViewController.h"
#import "SSCollectionViewExchangeFlowLayout.h"


typedef enum : NSInteger {
    SSCollectionViewSideLeft = 0,
    SSCollectionViewSideRight = 1
} SSCollectionViewSide;


@interface ViewController ()

<
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    SSSwappableCollectionViewDelegateFlowLayout
>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

- (IBAction)resetModel:(id)sender;

@property (strong, nonatomic) NSMutableArray *leftSide;
@property (strong, nonatomic) NSMutableArray *rightSide;

@end




@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Get the data...
    [self setModel];
    
    // Register the cell with the collection view...
    UINib *cellNib = [UINib nibWithNibName:@"ItemCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"itemCell"];
    
    //register the supplementary view...
    UINib *nib = [UINib nibWithNibName:@"SupplementaryView" bundle:nil];
    
    //when using a header in section 1...
    [self.collectionView registerNib:nib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    
    //when using a footer in section 0...
    [self.collectionView registerNib:nib forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer"];

    
    // Set up the layout...
    SSCollectionViewExchangeFlowLayout *layout = [[SSCollectionViewExchangeFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(145, 30);
    layout.minimumLineSpacing = 1;
    layout.minimumInteritemSpacing = 1;
    layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

    // Set this object as the layout's delegate...
    layout.delegate = self;
    
    // Set layout to be the collection view's layout...
    self.collectionView.collectionViewLayout = layout;
        
    // Set up the long press gesture recognizer
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:layout action:@selector(longPress:)];
    longPressGestureRecognizer.minimumPressDuration = 0.15;
    [self.collectionView addGestureRecognizer:longPressGestureRecognizer];
    
}



//--------------------------------
#pragma mark - Instance methods...

- (void)setModel
{    
    NSArray *temp1to10 = @[ @"item 1",  @"item 2",  @"item 3",  @"item 4",  @"item 5",
                            @"item 6",  @"item 7",  @"item 8",  @"item 9",  @"item 10" ];
    
    NSArray *temp11to20 = @[@"item 11", @"item 12", @"item 13", @"item 14", @"item 15",
                            @"item 16", @"item 17", @"item 18", @"item 19", @"item 20" ];
    
    self.leftSide = [NSMutableArray arrayWithArray:temp1to10];
    self.rightSide = [NSMutableArray arrayWithArray:temp11to20];
}

- (IBAction)resetModel:(id)sender
{
    [self setModel];
    [self.collectionView reloadData];
}

- (void)logArrays
{
    NSLog(@" ");
    NSLog(@"self.leftSide   |    self.rightSide");
    
    for (int i=0; i<[self.leftSide count]; i++) {
        NSLog(@"     %@     |    %@", self.leftSide[i], self.rightSide[i]);
    }
    
    NSLog(@" ");
}

- (void)cancelGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    gestureRecognizer.enabled = NO;
    gestureRecognizer.enabled = YES;
    //as per the docs, this triggers a cancel
}



//-----------------------------------------------------------------
#pragma mark - UICollectionView data source and delegate methods...

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    //sizes for when using a header for section 1...
//    if (section == 0) {
//        return CGSizeMake(0, 0);
//    } else {
//        return CGSizeMake(8, 8);
//    }
    
    //sizes for when using a footer for section 0...
    return CGSizeMake(0, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    //sizes for when using a header for section 1...
//    return CGSizeMake(0, 0);
    
    //sizes for when using a footer for section 0...
    if (section == 0) {
        return CGSizeMake(8, 8);
    } else {
        return CGSizeMake(0, 0);
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    //when using a header in section 1...
//    UICollectionReusableView *supplementaryView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header" forIndexPath:indexPath];
//    return supplementaryView;
    
    //when using a footer in section 0...
    UICollectionReusableView *supplementaryView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer" forIndexPath:indexPath];
    return supplementaryView;
    
}

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
    
    UILabel *itemLabel = (UILabel *)[cell viewWithTag:100];
    
    if (indexPath.section == 0) {
        itemLabel.text = self.leftSide[indexPath.item];
    } else {
        itemLabel.text = self.rightSide[indexPath.item];
    }
    
    return cell;
}



//----------------------------------------------------------------------------
#pragma mark - SSSwappableCollectionViewDelegateFlowLayout protocol methods...

- (void)exchangeItemAtIndexPath:(NSIndexPath *)indexPath1 withItemAtIndexPath:(NSIndexPath *)indexPath2
{
    // Update the model...
    
    //not structured optimally, intention is readability...
    
    if ([indexPath1 isEqual:indexPath2])
    {
        // If the index paths are the same there's nothing to exchange...
        return;
    }
    
    // The index paths are not the same. What about the sections?
    
    if (indexPath1.section == indexPath2.section)
    {
        // The sections are the same. In other words the items to exchange are in the same array.
        switch (indexPath1.section) {
                
            case SSCollectionViewSideLeft:
                [self.leftSide exchangeObjectAtIndex:indexPath1.item withObjectAtIndex:indexPath2.item];
                break;
                
            case SSCollectionViewSideRight:
                [self.rightSide exchangeObjectAtIndex:indexPath1.item withObjectAtIndex:indexPath2.item];
                break;
        }
        
    } else {
        
        // The sections are not the same. In other words the items being exchanged are not in the same array.
        
        switch (indexPath1.section) {
                
            case SSCollectionViewSideLeft:
                [self exchangeItemInArray:self.leftSide atIndex:indexPath1.item withItemInArray:self.rightSide atIndex:indexPath2.item];
                break;
                
            case SSCollectionViewSideRight:
                [self exchangeItemInArray:self.rightSide atIndex:indexPath1.item withItemInArray:self.leftSide atIndex:indexPath2.item];
                break;
        }
    }
    
    [self logArrays];
}

- (void)exchangeItemInArray:(NSMutableArray *)array1 atIndex:(int)index1 withItemInArray:(NSMutableArray *)array2 atIndex:(int)index2
{
    id item1 = array1[index1];
    id item2 = array2[index2];
    
    [array1 replaceObjectAtIndex:index1 withObject:item2];
    [array2 replaceObjectAtIndex:index2 withObject:item1];
}

- (void)didFinishExchangeEvent
{
    NSLog(@"[<%@ %p> %@ line= %d]", [self class], self, NSStringFromSelector(_cmd), __LINE__);
}

- (void)didFinishExchangeTransactionWithItemAtIndexPath:(NSIndexPath *)firstItem andItemAtIndexPath:(NSIndexPath *)secondItem
{
    NSLog(@"[<%@ %p> %@ line= %d]", [self class], self, NSStringFromSelector(_cmd), __LINE__);
}

- (BOOL)allowsExchange
{
    return YES;
}


@end
