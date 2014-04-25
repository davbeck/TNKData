//
//  TNKQuery.h
//  Pods
//
//  Created by David Beck on 4/24/14.
//
//

#import <Foundation/Foundation.h>


@interface TNKObjectQuery : NSObject

/** Create a new query
 
 Create a query for a given `TNKObject` subclass.
 
 @param objectClass The `TNKObject` subclass to query.
 @return An instance of `TNKObjectQuery`.
 */
- (instancetype)initWithObjectClass:(Class)objectClass;

/** The class to query.
 
 The value that was passed on initialization.
 */
@property (nonatomic, readonly) Class objectClass;

/** The keys that should be fetched with the object.
 
 Returns all the classes persistent keys when `returnObjectsAsFaults` is set to NO (the default).
 */
@property (nonatomic, copy) NSSet *keysToFetch;

/** Return just stub objects without persistent keys.
 
 Objects returned as faults will need to hit the database again to get any persistent properties. NO by default.
 */
@property (nonatomic) BOOL returnObjectsAsFaults;

/** The maximum number of objects to return.
 
 Use this to limit the number of objects returned by the query.
 */
@property (nonatomic) NSUInteger limit;

/** The predicate to filter the results by.
 
 This will be converted to an SQL where clause. Becasue of this, make sure that you do not use unsupported predicates (such as
 a block based predicate).
 */
@property (nonatomic, copy) NSPredicate *predicate;


/** Execute the query
 
 Executes the query on the database.
 
 @return An array of the results.
 */
- (NSArray *)run;

@end
