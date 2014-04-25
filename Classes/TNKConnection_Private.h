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

- (void)registerObject:(TNKObject *)object;
- (void)insertObject:(TNKObject *)object;
- (void)updateObject:(TNKObject *)object;
- (void)deleteObject:(TNKObject *)object;

@property (nonatomic, readonly) FMDatabaseQueue *databaseQueue;

@end
