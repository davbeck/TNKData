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

/**---------------------------------------------------------------------------------------
 * @name Persistent key information
 *  ---------------------------------------------------------------------------------------
 */

/** The keys that should be persisted to the database
 
 Use this method in your subclasses to mark properties as persistent. This method is called often, and shouldn't do much work.
 
 @return An `NSSet` of `NSString`s matching property names.
 */
+ (NSSet *)persistentKeys;

/** The keys that should be used to uniquely identifiy the object
 
 All of these keys should also be in `persistentKeys`. This method is called often, and shouldn't do much work.
 
 @return An `NSSet` of `NSString`s matching property names.
 */
+ (NSSet *)primaryKeys;


/**---------------------------------------------------------------------------------------
 * @name SQLite interaction
 *  ---------------------------------------------------------------------------------------
 */

/** The table name to use for the class
 
 By default returns the name of the class.
 
 @return An SQLite table name.
 */
+ (NSString *)sqliteTableName;

/** The SQLite column type for a given persistent key
 
 By default the property will be used to generate the type.
 
 See http://www.sqlite.org/datatype3.html.
 
 @param persistentKey The persistent key for the type.
 @return An SQLite column type or nil.
 */
+ (NSString *)sqliteTypeForPersistentKey:(NSString *)persistentKey;

/** SQLite column constraints for a given persistent key
 
 Returns "PRIMARY KEY" for primary keys, and an empty string for other keys by default. Override this to add indexes to columns
 
 @param persistentKey The key for the column constraints.
 @return The column constraints for the key.
 */
+ (NSString *)sqliteColumnConstraintsForPersistentKey:(NSString *)persistentKey;

/** SQLite where clause for the receiver
 
 By default this method returns a clause that looks for the objects primary keys.
 
 @return A where clause for an SQL SELECT, UPDATE or DELETE query.
 */
- (NSString *)sqliteWhereClause;

/** Create a table for the class
 
 This is called when the connection is created. The table may already exist, and this method should handle that. It should also
 take care of any database updates. You should not need to call this directly, and may not need to override it in your subclass.
 
 @param db The database to create the table in.
 */
+ (void)createTableInDatabase:(FMDatabase *)db;

/** Execute an SQL query to insert the object into the database
 
 This is called by the connection on save to persist the object to the database for the first time.
 
 @param db The database to insert the object into.
 */
- (void)insertIntoDatabase:(FMDatabase *)db;

/** Execute an SQL query to update the object in the database
 
 This is called by the connection on save to persist changes to an object to the database after a change.
 
 @param db The database to update the object in.
 */
- (void)updateInDatabase:(FMDatabase *)db;

/** Execute an SQL query to delete the object from the database
 
 This is called by the connection on save to remove the object from the database.
 
 @param db The database to delete the object from.
 */
- (void)deleteFromDatabase:(FMDatabase *)db;

/** Execute an SQL query to retrieve objects from the database
 
 This is called from a `TNKObjectQuery` to get the objects from the database. If you override this method you should return a
 real NSArray, with the actual objects, as `TNKObjectQuery` will handle paging results.
 
 @param objectQuery The query to use to generate the SQL query.
 @param db The database retrieve the objects from.
 @return An array of objects matching the query.
 */
+ (NSArray *)executeQuery:(TNKObjectQuery *)objectQuery inDatabase:(FMDatabase *)db;


/**---------------------------------------------------------------------------------------
 * @name Getting objects
 *  ---------------------------------------------------------------------------------------
 */

/** Find objects by primary keys
 
 Finds a specific object, either from the in memory store of objects, or from the database. Use `-[TNKObject find:usingQuery:]`
 to specify how the object is queried from the database if needed.
 
 @param values A dictionary with all the primary keys for the class.
 @return An TNKObject matching the primary keys.
 */
+ (instancetype)find:(NSDictionary *)values;

/** Find objects by primary keys
 
 Finds a specific object, either from the in memory store of objects, or from the database. Use If a queryBlock is provide, and
 the object needs to be fetched from the database, the block will be called with a default query that you can modify. For
 instance, you can use this to specify that the objects should be returned as faults.
 
 @param values A dictionary with all the primary keys for the class.
 @param queryBlock A block that will be called with the query to fetch the objects from the database.
 @return An TNKObject matching the primary keys.
 */
+ (instancetype)find:(NSDictionary *)values usingQuery:(void(^)(TNKObjectQuery *query))queryBlock;

/** Create a new object and insert it into the database
 
 The object will be inserted into the database on the next save. If you want to garuntee that values are set on the object before
 the object is saved, you can pass an initialization block to set default values on the new object.
 
 @param initialization Block used to initialize the values on the object.
 @return A new object.
 */
+ (instancetype)insertObjectWithInitialization:(void(^)(id object))initialization;

/** Delete the object from the database
 
 The object will be deleted from the database on the next save. Note that if you keep a reference to the object after deleting
 it, you can still use it as normal, but changes won't be persisted. Queries matching the primary keys *will* return the deleted
 object. The `isDeleted` flag will return `YES`. If you then insert a new object with the same primary key, the object will be
 reserected from the dead. Once the object is deallocated, subsequent queries for it will return nil.
 */
- (void)deleteObject;


/**---------------------------------------------------------------------------------------
 * @name Status information
 *  ---------------------------------------------------------------------------------------
 */

/** The connection for the object
 
 The connection that the object was inserted into, or fetched from.
 */
@property (nonatomic, weak, readonly) TNKConnection *connection;

/** If the object has been created but not inserted into the database yet.
 */
@property (nonatomic, readonly) BOOL isInserted;

/** If the object has changes that have not been saved to the database yet.
 */
@property (nonatomic, readonly) BOOL isUpdated;

/** If the object has been deleted.
 
 It may not have been saved to the database yet. This will be true even after a database save.
 */
@property (nonatomic, readonly) BOOL isDeleted;

/** The properties, and their values, that have been faulted in
 
 This copies it's internal dictionary every time you call this, so you may want to assign it to a local variable for repeated
 use.
 */
@property (nonatomic, readonly) NSDictionary *faultedValues;

/** Values that have been changed but not persisted to the database.
 */
@property (nonatomic, readonly) NSDictionary *changedValues;


/**---------------------------------------------------------------------------------------
 * @name Persistent Properties
 *  ---------------------------------------------------------------------------------------
 */

/** A default ID for the object.
 
 While subclasses do not need to use this property, if they use an auto incrementing id, they should use this, as the value
 will be assigned after an insert.
 
 To not use this property in your subclasses, don't return it in `persistentKeys` or `primaryKeys`.
 */
@property (nonatomic) NSUInteger objectID;

/** Convenience finder for objects identified solely by objectID
 
 If your only primary key is objectID, you can use this method instead of `-[TNKObject find:]` as a convenience. It is
 recomended that you create your own convenience finder if you use a different primary key.
 
 @param objectID The objectID to use to find an object.
 @return An object with the given objectID, or nil if one does not exist.
 */
+ (instancetype)findByServerID:(NSUInteger)objectID;

@end
