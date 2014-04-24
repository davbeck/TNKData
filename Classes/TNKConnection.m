//
//  TNKConnection.m
//  Pods
//
//  Created by David Beck on 4/22/14.
//
//

#import "TNKConnection.h"

#import "TNKData.h"


#define TNKCurrentConnectionThreadKey @"TNKCurrentConnection"


@interface TNKConnection ()
{
    FMDatabaseQueue *_databaseQueue;
    NSSet *_classes;
    
    NSMutableSet *_insertedObjects;
    
    BOOL _needsSave;
    
    dispatch_queue_t _propertyQueue;
}

@end


@implementation TNKConnection

- (NSSet *)insertedObjects
{
    __block NSSet *insertedObjects = nil;
    dispatch_sync(_propertyQueue, ^{
        insertedObjects = [_insertedObjects copy];
    });
    
    return insertedObjects;
}

static TNKConnection *_defaultConnection = nil;

+ (void)setDefaultConnection:(TNKConnection *)connection
{
    _defaultConnection = connection;
}

+ (instancetype)defaultConnection
{
    return _defaultConnection;
}

+ (instancetype)currentConnection
{
    return [NSThread currentThread].threadDictionary[TNKCurrentConnectionThreadKey] ?: [self defaultConnection];
}

+ (void)useConnection:(TNKConnection *)connection block:(void(^)(TNKConnection *connection))block
{
    TNKConnection *oldConnection = [NSThread currentThread].threadDictionary[TNKCurrentConnectionThreadKey];
    
    [NSThread currentThread].threadDictionary[TNKCurrentConnectionThreadKey] = connection;
    
    if (block) {
        block(connection);
    }
    
    [NSThread currentThread].threadDictionary[TNKCurrentConnectionThreadKey] = oldConnection;
}


#pragma mark - Initialization

+ (instancetype)connectionWithURL:(NSURL *)URL classes:(NSSet *)classes
{
    return [[self alloc] initWithURL:URL classes:classes];
}

- (instancetype)init
{
    return [self initWithURL:nil classes:nil];
}

- (instancetype)initWithURL:(NSURL *)URL classes:(NSSet *)classes
{
    NSAssert(URL.isFileURL || URL == nil, @"URL must be a file URL.");
    
    self = [super init];
    if (self) {
        _insertedObjects = [NSMutableSet new];
        
        _propertyQueue = dispatch_queue_create("TNKConnection-property-accessor", NULL);
        
        _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:URL.path];
        _classes = [classes copyWithZone:nil];
        
        [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            for (Class class in _classes) {
                [class createTableInDatabase:db];
            }
        }];
    }
    
    return self;
}


#pragma mark - Objects Management

- (void)insertObject:(TNKObject *)object
{
    dispatch_async(_propertyQueue, ^{
        [_insertedObjects addObject:object];
        [self setNeedsSave];
    });
}


#pragma mark - Saving

- (void)setNeedsSave
{
    dispatch_async(_propertyQueue, ^{
        if (!_needsSave) {
            _needsSave = YES;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self save];
            });
        }
    });
}

- (void)save
{
    __block NSSet *insertedObjects = nil;
    dispatch_async(_propertyQueue, ^{
        _needsSave = NO;
        insertedObjects = [_insertedObjects copy];
    });
    
    [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (TNKObject *object in insertedObjects) {
            [object insertIntoDatabase:db];
        }
        
        dispatch_async(_propertyQueue, ^{
            [_insertedObjects minusSet:insertedObjects];
        });
    }];
}

@end
