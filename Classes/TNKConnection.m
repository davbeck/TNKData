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
    NSMutableSet *_updatedObjects;
    NSMutableSet *_deletedObjects;
    
    BOOL _needsSave;
    
    dispatch_queue_t _propertyQueue;
#ifdef TARGET_OS_IPHONE
    UIBackgroundTaskIdentifier _saveTask;
#endif
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

- (NSSet *)updatedObjects
{
    __block NSSet *updatedObjects = nil;
    dispatch_sync(_propertyQueue, ^{
        updatedObjects = [_updatedObjects copy];
    });
    
    return updatedObjects;
}

- (NSSet *)deletedObjects
{
    __block NSSet *deletedObjects = nil;
    dispatch_sync(_propertyQueue, ^{
        deletedObjects = [_deletedObjects copy];
    });
    
    return deletedObjects;
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
        _updatedObjects = [NSMutableSet new];
        _deletedObjects = [NSMutableSet new];
        
        _propertyQueue = dispatch_queue_create("TNKConnection-property-accessor", NULL);
        _saveInterval = 1.0;
        
        _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:URL.path];
        _classes = [classes copyWithZone:nil];
        
        [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            for (Class class in _classes) {
                [class createTableInDatabase:db];
            }
        }];
        
        
#ifdef TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
#else
#endif
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

- (void)updateObject:(TNKObject *)object
{
    dispatch_async(_propertyQueue, ^{
        [_updatedObjects addObject:object];
        [self setNeedsSave];
    });
}

- (void)deleteObject:(TNKObject *)object
{
    dispatch_async(_propertyQueue, ^{
        [_deletedObjects addObject:object];
        [self setNeedsSave];
    });
}


#pragma mark - Saving

- (void)setNeedsSave
{
    dispatch_async(_propertyQueue, ^{
        if (!_needsSave) {
            _needsSave = YES;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, self.saveInterval * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                [self triggerSave];
            });
        }
    });
}

- (void)triggerSave
{
    dispatch_async(_propertyQueue, ^{
        if (_needsSave) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self save];
                
                if (_saveTask != UIBackgroundTaskInvalid) {
                    [[UIApplication sharedApplication] endBackgroundTask:_saveTask];
                }
            });
        } else {
            if (_saveTask != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:_saveTask];
            }
        }
    });
}

- (void)save
{
    NSLog(@"saving");
    
    __block NSSet *insertedObjects = nil;
    __block NSSet *updatedObjects = nil;
    __block NSSet *deletedObjects = nil;
    dispatch_async(_propertyQueue, ^{
        _needsSave = NO;
        
        insertedObjects = [_insertedObjects copy];
        _insertedObjects = [NSMutableSet new];
        
        updatedObjects = [_updatedObjects copy];
        _updatedObjects = [NSMutableSet new];
        
        deletedObjects = [_deletedObjects copy];
        _deletedObjects = [NSMutableSet new];
    });
    
    [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (TNKObject *object in insertedObjects) {
            [object insertIntoDatabase:db];
        }
        
        for (TNKObject *object in updatedObjects) {
            [object updateInDatabase:db];
        }
        
        for (TNKObject *object in deletedObjects) {
            [object deleteFromDatabase:db];
        }
    }];
}


#pragma mark - Notifications

#ifdef TARGET_OS_IPHONE
- (void)applicationWillResignActive:(NSNotification *)notification
{
    _saveTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"TNKConnection-save" expirationHandler:nil];
    [self triggerSave];
}
#endif

@end
