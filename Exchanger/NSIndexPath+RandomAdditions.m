//
//  NSIndexPath+RandomAdditions.m
//  Exchanger
//
//  Created by Murray Sagal on 2012-10-30.
//  Copyright (c) 2014 Signature Software. All rights reserved.
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


#import "NSIndexPath+RandomAdditions.h"

@implementation NSIndexPath (RandomAdditions)

+ (NSIndexPath *)randomIndexPathInArrays:(NSArray *)arrays
                     excludingIndexPaths:(NSSet *)excludedIndexPaths {
    
    if (arrays == nil) return nil;
    
    NSUInteger totalElementsInArrays = 0;
    for (NSArray *array in arrays) {
        if (array.count == 0) return nil;
        totalElementsInArrays += array.count;
    }
    
    if (excludedIndexPaths.count >= totalElementsInArrays) return nil;
    // This early return assumes that all the index paths in excludedIndexPaths are
    // relevant to the index paths represented in arrays. With that assumption if
    // there are too many excluded index paths, it is not possible to generate
    // a random index path for arrays.
    
    
    // Otherwise we are good to go...
    NSIndexPath *randomIndexPath;
    BOOL indexPathIsExcluded;
    
    do {
        
        NSUInteger randomSection = arc4random_uniform(arrays.count);
        NSArray *array = arrays[ randomSection ];
        NSUInteger randomItem = arc4random_uniform(array.count);
        randomIndexPath = [NSIndexPath indexPathForItem:randomItem inSection:randomSection];
        indexPathIsExcluded = [excludedIndexPaths containsObject:randomIndexPath];
        
    } while (indexPathIsExcluded);
    
    return randomIndexPath;
    
}

@end
