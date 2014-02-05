//
//  NSMutableArrayCategoryTests.m
//  Exchanger
//
//  Created by Murray Sagal on 2/3/2014.
//  Copyright (c) 2014 Murray Sagal. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSMutableArray+SSCollectionViewExchangeControllerAdditions.h"

@interface NSMutableArrayCategoryTests : XCTestCase

@property (strong, nonatomic) NSArray *originalArray1;
@property (strong, nonatomic) NSArray *originalArray2;

@property (strong, nonatomic) NSMutableArray *testArray1;
@property (strong, nonatomic) NSMutableArray *testArray2;

@end

@implementation NSMutableArrayCategoryTests

- (void)setUp {
    
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
    
    self.originalArray1 = @[ @0, @1, @2, @3, @4 ];
    self.originalArray2 = @[ @5, @6, @7, @8, @9 ];

}

- (void)tearDown {
    
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)resetArrays {
    
    self.testArray1 = [self.originalArray1 mutableCopy];
    self.testArray2 = [self.originalArray2 mutableCopy];
    
}

- (void)testExchangeObjectWithNilArrays {
    
    [self resetArrays];
    
    
    // first array nil...
    [NSMutableArray exchangeObjectInArray:nil
                                  atIndex:0
                   withObjectInOtherArray:self.testArray2
                                  atIndex:0];

    XCTAssertTrue([self.testArray1 isEqual:self.originalArray1], @"testArray1 modified when array1 parameter nil");
    XCTAssertTrue([self.testArray2 isEqual:self.originalArray2], @"testArray2 modified when array1 parameter nil");
    [self resetArrays];
    
    
    // second array nil...
    [NSMutableArray exchangeObjectInArray:self.testArray1
                                  atIndex:0
                   withObjectInOtherArray:nil
                                  atIndex:0];
    
    XCTAssertTrue([self.testArray1 isEqual:self.originalArray1], @"testArray1 modified when array2 parameter nil");
    XCTAssertTrue([self.testArray2 isEqual:self.originalArray2], @"testArray2 modified when array2 parameter nil");
    [self resetArrays];
    
    
    // both arrays nil...
    [NSMutableArray exchangeObjectInArray:nil
                                  atIndex:0
                   withObjectInOtherArray:nil
                                  atIndex:0];
    
    XCTAssertTrue([self.testArray1 isEqual:self.originalArray1], @"testArray1 modifed when both array parameters nil");
    XCTAssertTrue([self.testArray2 isEqual:self.originalArray2], @"testArray2 modifed when both array parameters nil");
    [self resetArrays];
}

- (void)testExchangeObjectWithEmptyArrays {
    
    [self resetArrays];
    
    [NSMutableArray exchangeObjectInArray:[@[] mutableCopy]
                                  atIndex:1
                   withObjectInOtherArray:self.testArray2
                                  atIndex:1];
    
    XCTAssertTrue([self.testArray2 isEqual:self.originalArray2], @"testArray2 modified when array1 was empty");
    [self resetArrays];
    
    
    [NSMutableArray exchangeObjectInArray:self.testArray1
                                  atIndex:1
                   withObjectInOtherArray:[@[] mutableCopy]
                                  atIndex:1];
    
    XCTAssertTrue([self.testArray1 isEqual:self.originalArray1], @"testArray1 modified when array2 was empty");
    [self resetArrays];
    
    
    XCTAssertNoThrow([NSMutableArray exchangeObjectInArray:[@[] mutableCopy]
                                                   atIndex:0
                                    withObjectInOtherArray:[@[] mutableCopy]
                                                   atIndex:0],
                     @"method throws exception when both arrays are empty");
    
}

- (void)testExchangeObjectWithInvalidIndex {
    
    [self resetArrays];
    
    
    // first index < 0...
    [NSMutableArray exchangeObjectInArray:self.testArray1
                                  atIndex:-1
                   withObjectInOtherArray:self.testArray2
                                  atIndex:0];
    
    XCTAssertTrue([self.testArray1 isEqual:self.originalArray1], @"testArray1 modified when index for array1 < 0");
    XCTAssertTrue([self.testArray2 isEqual:self.originalArray2], @"testArray2 modified when index for array1 < 0");
    [self resetArrays];
    
    
    // second index < 0...
    [NSMutableArray exchangeObjectInArray:self.testArray1
                                  atIndex:0
                   withObjectInOtherArray:self.testArray2
                                  atIndex:-1];
    
    XCTAssertTrue([self.testArray1 isEqual:self.originalArray1], @"testArray1 modified when index for array2 < 0");
    XCTAssertTrue([self.testArray2 isEqual:self.originalArray2], @"testArray2 modified when index for array2 < 0");
    [self resetArrays];
    
    
    // both index < 0...
    [NSMutableArray exchangeObjectInArray:self.testArray1
                                  atIndex:-1
                   withObjectInOtherArray:self.testArray2
                                  atIndex:-1];
    
    XCTAssertTrue([self.testArray1 isEqual:self.originalArray1], @"testArray1 modified when both indices < 0");
    XCTAssertTrue([self.testArray2 isEqual:self.originalArray2], @"testArray2 modified when both indices < 0");
    [self resetArrays];
    
    
    // first index above upper bounds...
    [NSMutableArray exchangeObjectInArray:self.testArray1
                                  atIndex:self.testArray1.count
                   withObjectInOtherArray:self.testArray2
                                  atIndex:0];
    
    XCTAssertTrue([self.testArray1 isEqual:self.originalArray1], @"testArray1 modified when index for array1 above upper bounds");
    XCTAssertTrue([self.testArray2 isEqual:self.originalArray2], @"testArray2 modified when index for array1 above upper bounds");
    [self resetArrays];
    
    
    // second index above upper bounds...
    [NSMutableArray exchangeObjectInArray:self.testArray1
                                  atIndex:0
                   withObjectInOtherArray:self.testArray2
                                  atIndex:self.testArray2.count];
    
    XCTAssertTrue([self.testArray1 isEqual:self.originalArray1], @"testArray1 modified when index for array2 above upper bounds");
    XCTAssertTrue([self.testArray2 isEqual:self.originalArray2], @"testArray2 modified when index for array2 above upper bounds");
    [self resetArrays];
    
    
    // both index above upper bounds...
    [NSMutableArray exchangeObjectInArray:self.testArray1
                                  atIndex:self.testArray1.count
                   withObjectInOtherArray:self.testArray2
                                  atIndex:self.testArray2.count];
    
    XCTAssertTrue([self.testArray1 isEqual:self.originalArray1], @"testArray1 modified when both indices above upper bounds");
    XCTAssertTrue([self.testArray2 isEqual:self.originalArray2], @"testArray2 modified when both indices above upper bounds");
    [self resetArrays];
}

- (void)testExchangeObjectInSameArrayWithSameIndexes {

    [self resetArrays];
    
    // both indices zero...
    [NSMutableArray exchangeObjectInArray:self.testArray1
                                  atIndex:0
                   withObjectInOtherArray:self.testArray1
                                  atIndex:0];
    
    XCTAssertTrue([self.testArray1 isEqual:self.originalArray1], @"testArray1 modified when arrays same and indices 0");
    XCTAssertTrue([self.testArray2 isEqual:self.originalArray2], @"testArray2 modified when arrays same and indices 0");
    [self resetArrays];
    
    // both indices inside...
    [NSMutableArray exchangeObjectInArray:self.testArray1
                                  atIndex:2
                   withObjectInOtherArray:self.testArray1
                                  atIndex:2];
    
    XCTAssertTrue([self.testArray1 isEqual:self.originalArray1], @"testArray1 modified when arrays same and indices 2");
    XCTAssertTrue([self.testArray2 isEqual:self.originalArray2], @"testArray2 modified when arrays same and indices 2");
    [self resetArrays];
    
    
    // both indices at array count - 1...
    [NSMutableArray exchangeObjectInArray:self.testArray1
                                  atIndex:self.testArray1.count - 1
                   withObjectInOtherArray:self.testArray1
                                  atIndex:self.testArray2.count - 1];
    
    XCTAssertTrue([self.testArray1 isEqual:self.originalArray1], @"testArray1 modified when arrays same and indices max");
    XCTAssertTrue([self.testArray2 isEqual:self.originalArray2], @"testArray2 modified when arrays same and indices max");
    [self resetArrays];
}

- (void)testExchangeObjectInSameArray {

    [self resetArrays];
    NSUInteger firstIndex;
    NSUInteger secondIndex;
    id objectAtFirstIndex;
    id objectAtFirstIndexShouldBe;
    id objectAtSecondIndex;
    id objectAtSecondIndexShouldBe;
    
    // outer edge indices...
    firstIndex = 0;
    secondIndex = self.testArray1.count - 1;
    
    [NSMutableArray exchangeObjectInArray:self.testArray1
                                  atIndex:firstIndex
                   withObjectInOtherArray:self.testArray1
                                  atIndex:secondIndex];
    
    objectAtFirstIndex = [self.testArray1 objectAtIndex:firstIndex];                 // will be @4 if it worked
    objectAtFirstIndexShouldBe = [self.originalArray1 objectAtIndex:secondIndex];    // @4
    XCTAssertTrue([objectAtFirstIndex isEqual:objectAtFirstIndexShouldBe], @"testArray1 object at index %@ is %@ after exchange, should be: %@",
                  [NSNumber numberWithInteger:firstIndex], [self.testArray1 objectAtIndex:firstIndex], [self.originalArray1 objectAtIndex:secondIndex]);
    
    objectAtSecondIndex = [self.testArray1 objectAtIndex:secondIndex];               // will be @0 if it worked
    objectAtSecondIndexShouldBe = [self.originalArray1 objectAtIndex:firstIndex];    // @0
    XCTAssertTrue([objectAtSecondIndex isEqual:objectAtSecondIndexShouldBe], @"testArray1 object at index %@ is %@ after exchange, should be: %@",
                  [NSNumber numberWithInteger:secondIndex], [self.testArray1 objectAtIndex:secondIndex], [self.originalArray1 objectAtIndex:firstIndex]);
    [self resetArrays];
    
    
    // lower edge and beside...
    firstIndex = 0;
    secondIndex = 1;
    
    [NSMutableArray exchangeObjectInArray:self.testArray1
                                  atIndex:firstIndex
                   withObjectInOtherArray:self.testArray1
                                  atIndex:secondIndex];
    
    objectAtFirstIndex = [self.testArray1 objectAtIndex:firstIndex];                 // will be @1 if it worked
    objectAtFirstIndexShouldBe = [self.originalArray1 objectAtIndex:secondIndex];    // @1
    XCTAssertTrue([objectAtFirstIndex isEqual:objectAtFirstIndexShouldBe], @"testArray1 object at index %@ is %@ after exchange, should be: %@",
                  [NSNumber numberWithInteger:firstIndex], [self.testArray1 objectAtIndex:firstIndex], [self.originalArray1 objectAtIndex:secondIndex]);
    
    objectAtSecondIndex = [self.testArray1 objectAtIndex:secondIndex];               // will be @0 if it worked
    objectAtSecondIndexShouldBe = [self.originalArray1 objectAtIndex:firstIndex];    // @0
    XCTAssertTrue([objectAtSecondIndex isEqual:objectAtSecondIndexShouldBe], @"testArray1 object at index %@ is %@ after exchange, should be: %@",
                  [NSNumber numberWithInteger:secondIndex], [self.testArray1 objectAtIndex:secondIndex], [self.originalArray1 objectAtIndex:firstIndex]);
    [self resetArrays];
    
    
    // upper edge and beside...
    firstIndex = self.testArray1.count - 1;  // 4
    secondIndex = self.testArray1.count - 2; // 3
    
    [NSMutableArray exchangeObjectInArray:self.testArray1
                                  atIndex:firstIndex
                   withObjectInOtherArray:self.testArray1
                                  atIndex:secondIndex];
    
    objectAtFirstIndex = [self.testArray1 objectAtIndex:firstIndex];                 // will be @3 if it worked
    objectAtFirstIndexShouldBe = [self.originalArray1 objectAtIndex:secondIndex];    // @3
    XCTAssertTrue([objectAtFirstIndex isEqual:objectAtFirstIndexShouldBe], @"testArray1 object at index %@ is %@ after exchange, should be: %@",
                  [NSNumber numberWithInteger:firstIndex], [self.testArray1 objectAtIndex:firstIndex], [self.originalArray1 objectAtIndex:secondIndex]);
    
    objectAtSecondIndex = [self.testArray1 objectAtIndex:secondIndex];               // will be @4 if it worked
    objectAtSecondIndexShouldBe = [self.originalArray1 objectAtIndex:firstIndex];    // @4
    XCTAssertTrue([objectAtSecondIndex isEqual:objectAtSecondIndexShouldBe], @"testArray1 object at index %@ is %@ after exchange, should be: %@",
                  [NSNumber numberWithInteger:secondIndex], [self.testArray1 objectAtIndex:secondIndex], [self.originalArray1 objectAtIndex:firstIndex]);
    [self resetArrays];
    
    
    // inside indices...
    firstIndex = 1; // 1
    secondIndex = self.testArray1.count - 2; // 3
    
    [NSMutableArray exchangeObjectInArray:self.testArray1
                                  atIndex:firstIndex
                   withObjectInOtherArray:self.testArray1
                                  atIndex:secondIndex];
    
    objectAtFirstIndex = [self.testArray1 objectAtIndex:firstIndex];                 // will be @3 if it worked
    objectAtFirstIndexShouldBe = [self.originalArray1 objectAtIndex:secondIndex];    // @3
    XCTAssertTrue([objectAtFirstIndex isEqual:objectAtFirstIndexShouldBe], @"testArray1 object at index %@ is %@ after exchange, should be: %@",
                  [NSNumber numberWithInteger:firstIndex], [self.testArray1 objectAtIndex:firstIndex], [self.originalArray1 objectAtIndex:secondIndex]);
    
    objectAtSecondIndex = [self.testArray1 objectAtIndex:secondIndex];               // will be @1 if it worked
    objectAtSecondIndexShouldBe = [self.originalArray1 objectAtIndex:firstIndex];    // @1
    XCTAssertTrue([objectAtSecondIndex isEqual:objectAtSecondIndexShouldBe], @"testArray1 object at index %@ is %@ after exchange, should be: %@",
                  [NSNumber numberWithInteger:secondIndex], [self.testArray1 objectAtIndex:secondIndex], [self.originalArray1 objectAtIndex:firstIndex]);
    [self resetArrays];
    
    
    // random indices
    for (int i=0; i<1000; i++) {
        
        [self resetArrays];
        
        firstIndex = arc4random_uniform(self.testArray1.count);
        secondIndex = arc4random_uniform(self.testArray1.count);
        
        [NSMutableArray exchangeObjectInArray:self.testArray1
                                      atIndex:firstIndex
                       withObjectInOtherArray:self.testArray1
                                      atIndex:secondIndex];
        
        objectAtFirstIndex = [self.testArray1 objectAtIndex:firstIndex];
        objectAtFirstIndexShouldBe = [self.originalArray1 objectAtIndex:secondIndex];
        XCTAssertTrue([objectAtFirstIndex isEqual:objectAtFirstIndexShouldBe], @"testArray1 object at index %@ is %@ after exchange, should be: %@",
                      [NSNumber numberWithInteger:firstIndex], [self.testArray1 objectAtIndex:firstIndex], [self.originalArray1 objectAtIndex:secondIndex]);
        
        objectAtSecondIndex = [self.testArray1 objectAtIndex:secondIndex];
        objectAtSecondIndexShouldBe = [self.originalArray1 objectAtIndex:firstIndex];
        XCTAssertTrue([objectAtSecondIndex isEqual:objectAtSecondIndexShouldBe], @"testArray1 object at index %@ is %@ after exchange, should be: %@",
                      [NSNumber numberWithInteger:secondIndex], [self.testArray1 objectAtIndex:secondIndex], [self.originalArray1 objectAtIndex:firstIndex]);

    }
    
}

- (void)testExchangeObjectInDifferentArrays {
    
    NSUInteger indexInArray1;
    NSUInteger indexInArray2;
    id objectAtIndexInFirstArray;
    id objectAtIndexInFirstArrayShouldBe;
    id objectAtIndexInSecondArray;
    id objectAtIndexInSecondArrayShouldBe;
    
    for (int i=0; i<1000; i++) {
    
        [self resetArrays];

        indexInArray1 = arc4random_uniform(self.testArray1.count);
        indexInArray2 = arc4random_uniform(self.testArray2.count);

        [NSMutableArray exchangeObjectInArray:self.testArray1
                                      atIndex:indexInArray1
                       withObjectInOtherArray:self.testArray2
                                      atIndex:indexInArray2];
        
        objectAtIndexInFirstArray = [self.testArray1 objectAtIndex:indexInArray1];
        objectAtIndexInFirstArrayShouldBe = [self.originalArray2 objectAtIndex:indexInArray2];
        XCTAssertTrue([objectAtIndexInFirstArray isEqual:objectAtIndexInFirstArrayShouldBe], @"testArray1 object at index %@ is %@ after exchange, should be: %@",
                      [NSNumber numberWithInteger:indexInArray1], [self.testArray1 objectAtIndex:indexInArray1], [self.originalArray2 objectAtIndex:indexInArray2]);
        
        objectAtIndexInSecondArray = [self.testArray2 objectAtIndex:indexInArray2];
        objectAtIndexInSecondArrayShouldBe = [self.originalArray1 objectAtIndex:indexInArray1];
        XCTAssertTrue([objectAtIndexInSecondArray isEqual:objectAtIndexInSecondArrayShouldBe], @"testArray2 object at index %@ is %@ after exchange, should be: %@",
                      [NSNumber numberWithInteger:indexInArray2], [self.testArray2 objectAtIndex:indexInArray2], [self.originalArray1 objectAtIndex:indexInArray1]);
    }
}

@end
