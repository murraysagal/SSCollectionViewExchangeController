//
//  NSMutableSet+AddObjectIfNotNil.m
//  Exchanger
//
//  Created by Murray Sagal on 2/9/2014.
//  Copyright (c) 2014 Murray Sagal. All rights reserved.
//

#import "NSMutableSet+AddObjectIfNotNil.h"

@implementation NSMutableSet (AddObjectIfNotNil)

- (void)addObjectIfNotNil:(id)object {
    
    if (object) [self addObject:object];

}

@end
