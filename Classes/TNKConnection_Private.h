//
//  TNKConnection_Private.h
//  Pods
//
//  Created by David Beck on 4/23/14.
//
//

#import "TNKConnection.h"

@class TNKObject;
@class FMDatabaseQueue;


@interface TNKConnection ()

/** Register an object with the connection
 
 This is called when an object is fetched from the database or inserted into the database.
 
 @param object The object to be registered for quicker lookup later and uniquing accross the connection.
 */
- (void)registerObject:(TNKObject *)object;

/** Insert a new object into the database.
 
 This is called when a new object is created.
 
 @param object The object that should be inserted into the database on the next save.
 */
- (void)insertObject:(TNKObject *)object;

/** Mark an object as needing to be updated
 
 This is called when a change is made to an objects persistent values.
 
 @param object The object that was updated.
 */
- (void)updateObject:(TNKObject *)object;

/** Mark an object for deletion
 
 An object added here will be removed from the database on the next save.
 
 @param object The object that should be deleted on the next save.
 */
- (void)deleteObject:(TNKObject *)object;


/** The internal database queue all queries must be run in
 */
@property (nonatomic, readonly) FMDatabaseQueue *databaseQueue;

@end
