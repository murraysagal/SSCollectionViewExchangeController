//
//  UIView+SSCollectionViewExchangeControllerAdditions.h
//  Exchanger
//
//  Created by Murray Sagal on 2/5/2014.
//  Copyright (c) 2014 Murray Sagal. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (SSCollectionViewExchangeControllerAdditions)

- (CGPoint)offsetToCenterFromPoint:(CGPoint)point;
// Returns the offset from point to the center of this view, in its coordinate system.
// Important: This is not the offset to self.center (which is in the superview's coordinate system).

@end
