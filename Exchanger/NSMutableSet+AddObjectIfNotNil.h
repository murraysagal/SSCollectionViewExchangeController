//
//  NSMutableSet+AddObjectIfNotNil.h
//  Exchanger
//
//  Created by Murray Sagal on 2/9/2014.
//  Copyright (c) 2014 Murray Sagal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableSet (AddObjectIfNotNil)

- (void)addObjectIfNotNil:(id)object;

@end
