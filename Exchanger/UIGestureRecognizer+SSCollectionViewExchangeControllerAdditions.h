//
//  UIGestureRecognizer+SSCollectionViewExchangeControllerAdditions.h
//  Exchanger
//
//  Created by Murray Sagal on 1/14/2014.
//  Copyright (c) 2014 Signature Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIGestureRecognizer (SSCollectionViewExchangeControllerAdditions)

- (CGPoint)offsetFromLocationToCenterForView:(UIView *)view;

@end
