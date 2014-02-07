//
//  NSIndexPath+RandomAdditons.h
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


#import <Foundation/Foundation.h>

@interface NSIndexPath (RandomAdditons)

+ (NSIndexPath *)randomIndexPathInArrays:(NSArray *)arrays
                     excludingIndexPaths:(NSSet *)excludedIndexPaths;
// Returns a random index path valid for one of the arrays in arrays. The returned
// index path will not be in the set of excludedIndexPaths.
//
// Returns nil if:
//      - arrays is nil
//      - any of the arrays in arrays is empty
//      - the number of items in excludedIndexPaths is greater than or equal to the
//          total number of elements for all the arrays in arrays
//
// The order of the arrays in arrays is important. The first array is section 0, the
// second array is section 1, and so on. The size of the arrays can vary but an array
// cannot be empty. 
//
// This method will take longer to return as the number of items in excludedIndexPaths
// grows as a percent of the total number of elements for all the arrays in arrays.

@end
