//
//  TNKObject.m
//  Pods
//
//  Created by David Beck on 4/22/14.
//
//

#import "TNKObject.h"

#import <objc/runtime.h>

#import "TNKData.h"


@implementation TNKObject

@dynamic id;


+ (NSSet *)persistentKeys
{
    return [NSSet setWithObject:@"id"];
}

+ (NSSet *)primaryKeys
{
    return [NSSet setWithObject:@"id"];
}

+ (NSString *)sqliteTypeForPersistentKey:(NSString *)persistentKey
{
    objc_property_t property = class_getProperty(self, [persistentKey UTF8String]);
    if (property != NULL) {
        NSString *attributes = [NSString stringWithUTF8String:property_getAttributes(property)];
        NSString *type = [attributes substringWithRange:NSMakeRange(1, [attributes rangeOfString:@","].location - 1)];
        
        if ([type characterAtIndex:0] == '@') {
            if (type.length > 3) {
                // formatted as @"NSClass"
                NSString *className = [type substringWithRange:NSMakeRange(2, type.length - 3)];
                Class class = NSClassFromString(className);
                
                if (class != Nil) {
                    if ([class isSubclassOfClass:[NSString class]]) {
                        return @"TEXT";
                    } else if ([class isSubclassOfClass:[NSNumber class]]) {
                        return @"REAL";
                    } else if ([class isSubclassOfClass:[NSDate class]]) {
                        return @"REAL";
                    }
                }
            }
            
            return @"BLOB";
        } else {
            switch ([type characterAtIndex:0]) {
                case 'c':
                case 'i':
                case 's':
                case 'l':
                case 'q':
                case 'C':
                case 'I':
                case 'S':
                case 'L':
                case 'Q':
                case 'B':
                    return @"INTEGER";
                case 'f':
                case 'd':
                    return @"REAL";
                case '*':
                    return @"TEXT";
            }
        }
    }
    
    return nil;
}

+ (NSString *)sqliteColumnConstraintsForPersistentKey:(NSString *)persistentKey
{
    if ([[self primaryKeys] containsObject:persistentKey]) {
        return @"PRIMARY KEY";
    }
    
    return nil;
}

+ (void)createTableInDatabase:(FMDatabase *)db
{
    NSSet *persistentKeys = [self persistentKeys];
    NSMutableArray *columnDefinitions = [NSMutableArray new];
    for (NSString *key in persistentKeys) {
        NSString *type = [self sqliteTypeForPersistentKey:key] ?: @"";
        NSString *columnConstraints = [self sqliteColumnConstraintsForPersistentKey:key] ?: @"";
        
        [columnDefinitions addObject:[NSString stringWithFormat:@"%@ %@ %@", key, type, columnConstraints]];
    }
    
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@)", NSStringFromClass([self class]), [columnDefinitions componentsJoinedByString:@", "]];
    NSLog(@"sql: %@", sql);
    [db executeUpdate:sql];
}

@end
