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
@class TNKObjectQuery;


@interface TNKObject : NSObject

+ (NSSet *)persistentKeys;
+ (NSSet *)primaryKeys;

+ (void)createTableInDatabase:(FMDatabase *)db;
+ (NSString *)sqliteTableName;
+ (NSString *)sqliteTypeForPersistentKey:(NSString *)persistentKey;
+ (NSString *)sqliteColumnConstraintsForPersistentKey:(NSString *)persistentKey;
- (NSString *)sqliteWhereClause;
- (void)insertIntoDatabase:(FMDatabase *)db;
- (void)updateInDatabase:(FMDatabase *)db;
- (void)deleteFromDatabase:(FMDatabase *)db;
+ (NSArray *)executeQuery:(TNKObjectQuery *)objectQuery inDatabase:(FMDatabase *)db;

+ (instancetype)find:(NSDictionary *)values;
+ (instancetype)find:(NSDictionary *)values usingQuery:(void(^)(TNKObjectQuery *query))queryBlock;
+ (instancetype)insertObjectWithInitialization:(void(^)(id object))initialization;
- (void)deleteObject;

@property (nonatomic, weak, readonly) TNKConnection *connection;
@property (nonatomic, readonly) BOOL isInserted;
@property (nonatomic, readonly) BOOL isUpdated;
@property (nonatomic, readonly) BOOL isDeleted;

@property (nonatomic, readonly) NSDictionary *faultedValues;
@property (nonatomic, readonly) NSDictionary *changedValues;

@property (nonatomic) NSUInteger objectID;
+ (instancetype)findByServerID:(NSUInteger)serverID;

@end
