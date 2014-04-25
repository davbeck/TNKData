//
//  TNKConnection.h
//  Pods
//
//  Created by David Beck on 4/22/14.
//
//

#import <Foundation/Foundation.h>

@interface TNKConnection : NSObject

/** The objects waiting to be inserted into the database
 
 When a `TNKObject` is inserted, it is added here until the connection is saved.
 */
@property (strong, readonly) NSSet *insertedObjects;

/** The objects waiting to be updated in the database
 
 When a `TNKObject` is changed, it is added here until the connection is saved.
 */
@property (strong, readonly) NSSet *updatedObjects;

/** The objects waiting to be deleted from the database
 
 When a `TNKObject` is deleted, it is added here until the connection is saved.
 */
@property (strong, readonly) NSSet *deletedObjects;

/** Returns a registered object for a given class and primary key
 
 When an object is in memory, it is registered with it is connection. This method will return the object if it is in memory. If
 the object is not in memory, this method will return nil. The object may exist in the database, but a request must be made to 
 the database to be sure.
 
 Use `-[TNKObject find:]` to fetch the object from the database if needed.
 
 @param class The `TNKObject` subclass to find.
 @param primaryValues A dictionary of all the primary keys for the given object class.
 @return An `TNKObject` matching the primary keys, or nil if the object is not registered.
 */
- (id)existingObjectWithClass:(Class)objectClass primaryValues:(NSDictionary *)primaryValues;


/** Set the default connection for the current process
 
 You can set a default connection that will be used accross the entire process so you do not have to explicitly set it each time.
 
 @param connection The connection to make the default.
 */
+ (void)setDefaultConnection:(TNKConnection *)connection;

/** The default connection for the current process
 
 You can set a default connection that will be used accross the entire process so you do not have to explicitly set it each time.
 
 @return The default connection.
 */
+ (instancetype)defaultConnection;

/** The current connection to get objects with
 
 If the current thread is inside of a `useConnection:block:` call, this will return that connection. Otherwise it will return the 
 default connection, or nil if no default connection has been set.
 
 @return The current connection to use.
 */
+ (instancetype)currentConnection;

/** Override the default connection
 
 In order to use a specific connection to query objects from, use this method. The block will be called immediately, on the
 current thread, and wait until finished.
 
 @warning *Note:* the connection will only be used on the thread that this method was called on. If your code calls out to another
 thread, the wrong connection will be used.
 
 @param connection The connection to use inside the block.
 @param block A block that uses the connection.
 */
+ (void)useConnection:(TNKConnection *)connection block:(void(^)(TNKConnection *connection))block;


/** Create a new connection
 
 Creates and returns a new connection with an SQLite database at the given URL. If the database does not exist, it will be 
 created. The classes act as a model for the database. All the tables needed for the database will be created when the connection
 is created. Any updates to the database (new tables and or columns) will be done here as well.
 
 @param URL The file URL of the underlying database.
 @param classes All the `TNKObject` subclasses that will be used in the connection.
 @return A new connection.
 */
+ (instancetype)connectionWithURL:(NSURL *)URL classes:(NSSet *)classes;

/** Create a new connection
 
 Creates and returns a new connection with an SQLite database at the given URL. If the database does not exist, it will be
 created. The classes act as a model for the database. All the tables needed for the database will be created when the connection
 is created. Any updates to the database (new tables and or columns) will be done here as well.
 
 This is the designated initializer for this class.
 
 @param URL The file URL of the underlying database.
 @param classes All the `TNKObject` subclasses that will be used in the connection.
 @return A new connection.
 */
- (instancetype)initWithURL:(NSURL *)URL classes:(NSSet *)classes;


/** Mark the connection as needing to be saved
 
 This will schedule a save `saveInterval` seconds from now. If the connection is saved manually before then, it will not save
 again.

 You shouldn't need to call this yourself. When you edit, insert or delete objects this is called automatically.
 */
- (void)setNeedsSave;

/** Trigger a save that was queued with `setNeedsSave`
 
 If the connection has already been saved, this is ignored. The save will be triggered on a background queue and this method 
 returns immediately.
 
 This is automatically called when an iOS app enters the background.
 */
- (void)triggerSave;

/** Manually save the database
 
 While changes are queued for saving automatically, you may wish to manually save the database. This method blocks until the save
 finishes. You may call it on a background thread if you like.
 */
- (void)save;

/** The interval to wait before making automatic saves
 
 When an object is modified, it is automatically saved after a certain time (and all other changes in that time are grouped
 together). You can increase or decrease this time using this property. Shorter times will mean more frequent saves, and thus 
 changes can't be grouped together, however longer times means more data will be lost if the app crashes.
 
 You can also call `save` or `triggerSave` manually to ensure changes are saved immediately.
 */
@property (nonatomic) NSTimeInterval saveInterval;

@end
