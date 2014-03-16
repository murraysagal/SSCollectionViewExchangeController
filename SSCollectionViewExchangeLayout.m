//
//  SSCollectionViewExchangeLayout.m
//
// Created by Murray Sagal on 2012-10-31.
// Copyright (c) 2014 Signature Software and Murray Sagal
// SSCollectionViewExchangeController: https://github.com/murraysagal/SSCollectionViewExchangeController
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
    
    if (attributesForItem.representedElementKind == UICollectionElementKindSectionHeader || attributesForItem.representedElementKind == UICollectionElementKindSectionFooter)
    {
        return attributesForItem;
    }
    
    NSIndexPath *indexPathForItemToHide =   [self.delegate indexPathForItemToHide];
    NSIndexPath *indexPathForItemToDim =    [self.delegate indexPathForItemToDim];
    CGFloat alphaForItemToDim =             [self.delegate alphaForItemToDim];
    
    attributesForItem.hidden = ([attributesForItem.indexPath isEqual:indexPathForItemToHide])? YES : NO;
    attributesForItem.alpha =  ([attributesForItem.indexPath isEqual:indexPathForItemToDim])?  alphaForItemToDim : 1.0;

    return attributesForItem;
}

@end
