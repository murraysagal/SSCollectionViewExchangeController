//
//  NSMutableArray+SSCollectionViewExchangeControllerAdditions.h
//  Exchanger
//
//  Created by Murray Sagal on 1/10/2014.
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


// This category on NSMutableArray implements a class method that exchange objects
// which can be in two different NSMutableArray objects.



#import <Foundation/Foundation.h>

@interface NSMutableArray (SSCollectionViewExchangeControllerAdditions)

+ (void)exchangeObjectInArray:(NSMutableArray *)array       atIndex:(NSUInteger)index
       withObjectInOtherArray:(NSMutableArray *)otherArray  atIndex:(NSUInteger)indexInOtherArray;

@end
