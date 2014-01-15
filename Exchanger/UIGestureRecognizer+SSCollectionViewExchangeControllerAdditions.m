//
//  UIGestureRecognizer+SSCollectionViewExchangeControllerAdditions.m
//  Exchanger
//
//  Created by Murray Sagal on 1/14/2014.
//  Copyright (c) 2014 Signature Software. All rights reserved.
//

#import "UIGestureRecognizer+SSCollectionViewExchangeControllerAdditions.h"

@implementation UIGestureRecognizer (SSCollectionViewExchangeControllerAdditions)

- (CGPoint)offsetFromLocationToCenterForView:(UIView *)view {
    
    CGPoint locationInView = [self locationInView:view];
    CGPoint viewCenter = CGPointMake(view.frame.size.width/2, view.frame.size.height/2);
    CGPoint offset = CGPointMake(locationInView.x - viewCenter.x, locationInView.y - viewCenter.y);
    return offset;
    
}

@end
