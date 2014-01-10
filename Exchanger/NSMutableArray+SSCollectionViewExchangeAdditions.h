//
//  NSMutableArray+SSCollectionViewExchangeAdditions.h
//  Exchanger
//
//  Created by Murray Sagal on 1/10/2014.
//  Copyright (c) 2014 Murray Sagal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (SSCollectionViewExchangeAdditions)

+ (void)exchangeItemInArray:(NSMutableArray *)array1 atIndex:(NSUInteger)index1
            withItemInArray:(NSMutableArray *)array2 atIndex:(NSUInteger)index2;

@end
