//
//  SSCollectionViewExchangeLayout.h
//  Exchanger
//
//  Created by Murray Sagal on 2012-10-31.
//  Copyright (c) 2014 Signature Software. All rights reserved.
//

#import <UIKit/UIKit.h>


// This UICollectionViewFlowLayout subclass implements a layout designed
// to manage hiding and dimming items during the exchange process.


@protocol SSCollectionViewExchangeLayoutDelegate

@required

- (NSIndexPath *)indexPathForItemToHide;
- (NSIndexPath *)indexPathForItemToDim;
- (CGFloat)alphaForItemToDim;

@end


@interface SSCollectionViewExchangeLayout : UICollectionViewFlowLayout

- (id)initWithDelegate:(id<SSCollectionViewExchangeLayoutDelegate>)delegate;

@end
