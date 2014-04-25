//
//  TNKTestObject.h
//  TNKDataDemo
//
//  Created by David Beck on 4/25/14.
//  Copyright (c) 2014 ThinkUltimate. All rights reserved.
//

#import "TNKObject.h"

@interface TNKTestObject : TNKObject

@property (nonatomic, strong) NSString *stringProperty;
@property (nonatomic, strong) NSNumber *numberProperty;
@property (nonatomic, strong) NSDate *dateProperty;

@property (nonatomic) char charProperty;
@property (nonatomic) short shortProperty;
@property (nonatomic) int intProperty;
@property (nonatomic) long longProperty;
@property (nonatomic) long long longLongProperty;
@property (nonatomic) unsigned char unsigned_charProperty;
@property (nonatomic) unsigned short unsigned_shortProperty;
@property (nonatomic) unsigned int unsigned_intProperty;
@property (nonatomic) unsigned long unsigned_longProperty;
@property (nonatomic) unsigned long long unsigned_longLongProperty;
@property (nonatomic) NSInteger integerProperty;

@property (nonatomic) float floatProperty;
@property (nonatomic) double doubleProperty;
@property (nonatomic) NSTimeInterval timeIntervalProperty;

@end
