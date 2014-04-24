//
//  TNKObject.h
//  Pods
//
//  Created by David Beck on 4/22/14.
//
//

#import <Foundation/Foundation.h>

@class FMDatabase;
@class TNKConnection;


@interface TNKObject : NSObject

+ (NSSet *)persistentKeys;
+ (NSSet *)primaryKeys;

+ (void)createTableInDatabase:(FMDatabase *)db;
+ (NSString *)sqliteTypeForPersistentKey:(NSString *)persistentKey;
+ (NSString *)sqliteColumnConstraintsForPersistentKey:(NSString *)persistentKey;
- (void)insertIntoDatabase:(FMDatabase *)db;

+ (instancetype)insertObjectWithInitialization:(void(^)(id object))initialization;

@property (nonatomic, weak, readonly) TNKConnection *connection;
@property (nonatomic, readonly) BOOL isInserted;

@property (nonatomic, readonly) NSDictionary *faultedValues;
@property (nonatomic, readonly) NSDictionary *changedValues;

@property (nonatomic, getter = myCoolGetter, setter = myEvenCoolerSetter:) NSUInteger id;

@end
