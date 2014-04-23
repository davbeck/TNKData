//
//  TNKEvent.m
//  TNKDataDemo
//
//  Created by David Beck on 4/23/14.
//  Copyright (c) 2014 ThinkUltimate. All rights reserved.
//

#import "TNKEvent.h"

@implementation TNKEvent

@dynamic date;

+ (NSSet *)persistentKeys
{
    return [NSSet setWithArray:@[@"id", @"date"]];
}

@end
