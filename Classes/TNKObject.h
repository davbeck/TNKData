//
//  TNKObject.h
//  Pods
//
//  Created by David Beck on 4/22/14.
//
//

#import <Foundation/Foundation.h>

@class FMDatabase;


@interface TNKObject : NSObject

+ (NSSet *)persistentKeys;
+ (NSSet *)primaryKeys;
+ (void)createTableInDatabase:(FMDatabase *)db;
+ (NSString *)sqliteTypeForPersistentKey:(NSString *)persistentKey;
+ (NSString *)sqliteColumnConstraintsForPersistentKey:(NSString *)persistentKey;

@property (nonatomic) NSUInteger id;

@end
