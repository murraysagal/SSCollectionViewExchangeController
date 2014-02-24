//
//  MSStringifyMacros_UserDefaults.h
//  MSStringifyMacros
//
//  Created by Murray Sagal on 2/20/2014.
//  Copyright (c) 2014 Murray Sagal. All rights reserved.
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
//



#import "MSStringifyMacro.h"

#define SUD                                                 [NSUserDefaults standardUserDefaults]

#define setDefaultForBool(BOOL)                             [SUD setBool:BOOL forKey:NS_STRINGIFY(BOOL)]
#define defaultForBool(BOOL)                                BOOL = [SUD boolForKey:NS_STRINGIFY(BOOL)]

#define setDefaultForDouble(double)                         [SUD setDouble:double forKey:NS_STRINGIFY(double)]
#define defaultForDouble(double)                            double = [SUD doubleForKey:NS_STRINGIFY(double)]

#define setDefaultForFloat(float)                           [SUD setFloat:float forKey:NS_STRINGIFY(float)]
#define defaultForFloat(float)                              float = [SUD floatForKey:NS_STRINGIFY(float)]

#define setDefaultForInteger(integer)                       [SUD setInteger:integer forKey:NS_STRINGIFY(integer)]
#define defaultForInteger(integer)                          integer = [SUD integerForKey:NS_STRINGIFY(integer)]

#define setDefaultForObject(object)                         [SUD setObject:object forKey:NS_STRINGIFY(object)]
#define defaultForObject(object)                            object = [SUD objectForKey:NS_STRINGIFY(object)]
#define removeDefaultForObject(object)                      [SUD removeObjectForKey:NS_STRINGIFY(object)]

#define defaultDoesNotExistForObject(object)                [SUD objectForKey:NS_STRINGIFY(object)] == nil
#define defaultExistsForObject(object)                      [SUD objectForKey:NS_STRINGIFY(object)] != nil

#define defaultForArray(array)                              array = [SUD arrayForKey:NS_STRINGIFY(array)]
#define defaultForMutableArray(mutableArray)                mutableArray = [[SUD arrayForKey:NS_STRINGIFY(mutableArray)] mutableCopy]

#define defaultForData(data)                                data = [SUD dataForKey:NS_STRINGIFY(data)]
#define defaultForMutableData(mutableData)                  mutableData = [[SUD dataForKey:NS_STRINGIFY(mutableData)] mutableCopy]

#define defaultForDictionary(dictionary)                    dictionary = [SUD dictionaryForKey:NS_STRINGIFY(dictionary)]
#define defaultForMutableDictionary(mutableDictionary)      mutableDictionary = [[SUD dictionaryForKey:NS_STRINGIFY(mutableDictionary)] mutableCopy]

#define defaultForString(string)                            string = [SUD stringForKey:NS_STRINGIFY(string)]
#define defaultForMutableString(mutableString)              mutableString = [[SUD stringForKey:NS_STRINGIFY(mutableString)] mutableCopy]

#define defaultForStringArray(stringArray)                  stringArray = [SUD stringArrayForKey:NS_STRINGIFY(stringArray)]
#define defaultForStringArrayMutable(stringArrayMutable)    stringArrayMutable = [[SUD stringArrayForKey:NS_STRINGIFY(stringArrayMutable)] mutableCopy]

#define setDefaultForURL(url)                               [SUD setURL:url forKey:NS_STRINGIFY(url)]
#define defaultForURL(url)                                  url = [SUD URLForKey:NS_STRINGIFY(url)]