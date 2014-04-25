//
//  TNKQuery.m
//  Pods
//
//  Created by David Beck on 4/24/14.
//
//

#import "TNKObjectQuery.h"

#import "TNKData.h"
#import "TNKConnection_Private.h"


@implementation TNKObjectQuery

- (NSSet *)keysToFetch
{
    if (!self.returnObjectsAsFaults) {
        return [self.objectClass persistentKeys];
    }
    
    return _keysToFetch;
}

- (instancetype)init
{
    NSAssert(NO, @"You cannot call init on TNKQuery without an object class.");
    return nil;
}

- (instancetype)initWithObjectClass:(Class)objectClass
{
    self = [super init];
    if (self) {
        _objectClass = objectClass;
    }
    
    return self;
}

- (NSArray *)run
{
    __block NSArray *objects = nil;
    [[TNKConnection currentConnection].databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        objects = [self.objectClass executeQuery:self inDatabase:db];
    }];
    
    return objects;
}

@end
