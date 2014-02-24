//
//  MSStringifyMacros_Archiving.h
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

#define encodeBool(BOOL)            [aCoder encodeBool:BOOL forKey:NS_STRINGIFY(BOOL)]
#define decodeBool(BOOL)            BOOL = [aDecoder decodeBoolForKey:NS_STRINGIFY(BOOL)]

#define encodeDouble(double)        [aCoder encodeDouble:double forKey:NS_STRINGIFY(double)]
#define decodeDouble(double)        double = [aDecoder decodeDoubleForKey:NS_STRINGIFY(double)]

#define encodeFloat(float)          [aCoder encodeFloat:float forKey:NS_STRINGIFY(float)]
#define decodeFloat(float)          float = [aDecoder decodeFloatForKey:NS_STRINGIFY(float)]

#define encodeInt(int)              [aCoder encodeInt:int forKey:NS_STRINGIFY(int)]
#define decodeInt(int)              int = [aDecoder decodeIntForKey:NS_STRINGIFY(int)]

#define encodeInt32(int32_t)        [aCoder encodeInt32:int32_t forKey:NS_STRINGIFY(int32_t)]
#define decodeInt32(int32_t)        int32_t = [aDecoder decodeInt32ForKey:NS_STRINGIFY(int32_t)]

#define encodeInt64(int64_t)        [aCoder encodeInt64:int64_t forKey:NS_STRINGIFY(int64_t)]
#define decodeInt64(int64_t)        int64_t = [aDecoder decodeInt64ForKey:NS_STRINGIFY(int64_t)]

#define encodeObject(object)        [aCoder encodeObject:object forKey:NS_STRINGIFY(object)]
#define decodeObject(object)        object = [aDecoder decodeObjectForKey:NS_STRINGIFY(object)]

#define containsValue(value)        [aDecoder containsValueForKey:NS_STRINGIFY(value)]