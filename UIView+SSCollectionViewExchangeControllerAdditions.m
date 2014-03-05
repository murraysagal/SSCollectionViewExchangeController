//
//  UIView+SSCollectionViewExchangeControllerAdditions.m
//  Exchanger
//
//  Created by Murray Sagal on 2/5/2014.
//  Copyright (c) 2014 Murray Sagal. All rights reserved.
//

#import "UIView+SSCollectionViewExchangeControllerAdditions.h"

@implementation UIView (SSCollectionViewExchangeControllerAdditions)

- (CGPoint)offsetToCenterFromPoint:(CGPoint)point {
    
    CGPoint center;
    CGPoint offsetToCenter;
    
    center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    offsetToCenter = CGPointMake(point.x - center.x, point.y - center.y);
    return offsetToCenter;
    
}
@end
