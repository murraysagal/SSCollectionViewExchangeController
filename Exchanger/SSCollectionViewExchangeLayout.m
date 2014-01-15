//
//  SSCollectionViewExchangeLayout.m
//  Exchanger
//
//  Created by Murray Sagal on 2012-10-31.
//  Copyright (c) 2014 Signature Software. All rights reserved.
//

#import "SSCollectionViewExchangeLayout.h"


@interface SSCollectionViewExchangeLayout ()

@property (weak, nonatomic) id <SSCollectionViewExchangeLayoutDelegate> delegate;

@end



@implementation SSCollectionViewExchangeLayout

- (id)initWithDelegate:(id<SSCollectionViewExchangeLayoutDelegate>)delegate {
    
    self = [super init];
    if (self) {
        
        _delegate = delegate;
    }
    return self;
}



//-----------------------------------------------------
#pragma mark - Override the layout attribute methods...

// There is one item that needs hiding and one that needs dimming. As the user drags the item being moved over
// another item, that item moves to the original location of the item being dragged. That cell is dimmed, marking
// the original location of the item being moved. The cell at the position of the displaced item is hidden giving
// the user the sense that the item being dragged will land there if their finger is released.
//
// This is accomplished by overriding layoutAttributesForElementsInRect: and layoutAttributesForItemAtIndexPath:.
//
// It can happen that the item to hide and the item to dim will be the same. This happens when the user drags back
// to the starting location. This collision is irrelevant because there are two separate properties: one tracking
// the item to hide and one tracking the item to dim. In layoutAttributesForItem: the hidden property is set first
// then the alpha. If the items are the same setting the alpha for an item that is hidden has no effect.

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    
    NSArray *layoutAttributes = [super layoutAttributesForElementsInRect:rect];
    
    for (UICollectionViewLayoutAttributes *attributesForItem in layoutAttributes)
    {
        (void) [self layoutAttributesForItem:attributesForItem];
    }
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewLayoutAttributes *attributesForItem = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    return [self layoutAttributesForItem:attributesForItem];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItem:(UICollectionViewLayoutAttributes *)attributesForItem {
    
    NSIndexPath *indexPathForItemToHide = [self.delegate indexPathForItemToHide];
    NSIndexPath *indexPathForItemToDim = [self.delegate indexPathForItemToDim];
    
    attributesForItem.hidden = ([attributesForItem.indexPath isEqual:indexPathForItemToHide])? YES : NO;
    attributesForItem.alpha =  ([attributesForItem.indexPath isEqual:indexPathForItemToDim])?  [self.delegate alphaForItemToDim] : 1.0;

    return attributesForItem;
}

@end
