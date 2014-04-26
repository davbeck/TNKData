//
//  TNKTestObject.m
//  TNKDataDemo
//
//  Created by David Beck on 4/25/14.
//  Copyright (c) 2014 ThinkUltimate. All rights reserved.
//

#import "TNKTestObject.h"

@implementation TNKTestObject

@dynamic stringProperty;
@dynamic numberProperty;
@dynamic dateProperty;

@dynamic charProperty;
@dynamic shortProperty;
@dynamic intProperty;
@dynamic longProperty;
@dynamic longLongProperty;
@dynamic unsigned_charProperty;
@dynamic unsigned_shortProperty;
@dynamic unsigned_intProperty;
@dynamic unsigned_longProperty;
@dynamic unsigned_longLongProperty;
@dynamic integerProperty;

@dynamic floatProperty;
@dynamic doubleProperty;
@dynamic timeIntervalProperty;

+ (NSSet *)persistentKeys
{
    return [NSSet setWithArray:@[
                                 @"objectID",
                                 
                                 @"stringProperty",
                                 @"numberProperty",
                                 @"dateProperty",
                                 
                                 @"charProperty",
                                 @"shortProperty",
                                 @"intProperty",
                                 @"longProperty",
                                 @"longLongProperty",
                                 @"unsigned_charProperty",
                                 @"unsigned_shortProperty",
                                 @"unsigned_intProperty",
                                 @"unsigned_longProperty",
                                 @"unsigned_longLongProperty",
                                 @"integerProperty",
                                 
                                 @"floatProperty",
                                 @"doubleProperty",
                                 @"timeIntervalProperty",
                                 ]];
}

@end
