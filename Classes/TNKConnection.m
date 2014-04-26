//
//  TNKConnection.m
//  Pods
//
//  Created by David Beck on 4/22/14.
//
//

#import "TNKConnection.h"

#import "TNKData.h"
#import "TNKConnection_Private.h"


#define TNKCurrentConnectionThreadKey @"TNKCurrentConnection"
#define TNKInPropertyQueueThreadKey @"TNKInPropertyQueue"


// http://www.blackdogfoundry.com/blog/supporting-regular-expressions-in-sqlite/
static void TNKSQLiteRegexp(sqlite3_context *context, int argc, sqlite3_value **argv)
{
	NSUInteger numberOfMatches = 0;
	if (argc == 2) {
		NSString *pattern = [NSString stringWithUTF8String:(const char *)sqlite3_value_text(argv[0])];
		NSString *value = [NSString stringWithUTF8String:(const char *)sqlite3_value_text(argv[1])];
        
		if (pattern != nil && value != nil) {
            static NSCache *cache = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                cache = [NSCache new];
            });
            
            NSRegularExpression *regex = [cache objectForKey:pattern];
            if (regex == nil) {
                NSError *error = nil;
                // assumes that it is case sensitive. If you need case insensitivity, then prefix your regex with (?i)
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:kNilOptions error:&error];
                
                if (regex == nil) {
                    sqlite3_result_error(context, [[error localizedDescription] UTF8String], -1);
                    return;
                }
                
                [cache setObject:regex forKey:pattern];
            }
            
			if (regex != nil) {
				numberOfMatches = [regex numberOfMatchesInString:value options:0 range:NSMakeRange(0, [value length])];
            }
		}
	}
    
	sqlite3_result_int(context, (int)numberOfMatches);
}

static void TNKSQLiteLike(sqlite3_context *context, int argc, sqlite3_value **argv)
{
	BOOL matches = NO;
	if (argc == 3) {
		NSString *value = [NSString stringWithUTF8String:(const char *)sqlite3_value_text(argv[0])];
		NSString *pattern = [NSString stringWithUTF8String:(const char *)sqlite3_value_text(argv[1])];
        NSComparisonPredicateOptions options = sqlite3_value_int(argv[2]);
        
		if (pattern != nil && value != nil) {
            NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForEvaluatedObject]
                                                                        rightExpression:[NSExpression expressionForConstantValue:pattern]
                                                                               modifier:NSDirectPredicateModifier
                                                                                   type:NSLikePredicateOperatorType
                                                                                options:options];
            matches = [predicate evaluateWithObject:value];
		}
	}
    
	sqlite3_result_int(context, (int)matches);
}


@interface TNKConnection ()
{
    NSSet *_classes;
    
    NSMapTable *_registeredObjects;
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
    [self performBlockAndWait:^{
        insertedObjects = [_insertedObjects copy];
    }];
    
    return insertedObjects;
}

- (NSSet *)updatedObjects
{
    __block NSSet *updatedObjects = nil;
    [self performBlockAndWait:^{
        updatedObjects = [_updatedObjects copy];
    }];
    
    return updatedObjects;
}

- (NSSet *)deletedObjects
{
    __block NSSet *deletedObjects = nil;
    [self performBlockAndWait:^{
        deletedObjects = [_deletedObjects copy];
    }];
    
    return deletedObjects;
}

- (id)existingObjectWithClass:(Class)objectClass primaryValues:(NSDictionary *)primaryValues
{
    return [_registeredObjects objectForKey:[self.class _keyForObjectClass:objectClass primaryValues:primaryValues]];
}


#pragma mark - Current Connection

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
    
    if (oldConnection != nil) {
        [NSThread currentThread].threadDictionary[TNKCurrentConnectionThreadKey] = oldConnection;
    }
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
        _registeredObjects = [[NSMapTable alloc] initWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableWeakMemory capacity:0];
        _insertedObjects = [NSMutableSet new];
        _updatedObjects = [NSMutableSet new];
        _deletedObjects = [NSMutableSet new];
        
        _propertyQueue = dispatch_queue_create("TNKConnection-property-accessor", NULL);
        _saveInterval = 1.0;
        
        _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:URL.path];
        _classes = [classes copyWithZone:nil];
        
        [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            sqlite3_create_function_v2(db.sqliteHandle, "REGEXP", 2, SQLITE_ANY, 0, TNKSQLiteRegexp, NULL, NULL, NULL);
            sqlite3_create_function_v2(db.sqliteHandle, "PREDICATE_LIKE", 3, SQLITE_ANY, 0, TNKSQLiteLike, NULL, NULL, NULL);
            
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

+ (NSString *)_keyForObject:(TNKObject *)object
{
    NSMutableDictionary *primaryKeys = [NSMutableDictionary new];
    for (NSString *key in [[[object.class primaryKeys] allObjects] sortedArrayUsingSelector:@selector(compare:)]) {
        primaryKeys[key] = [object valueForKey:key];
    }
    
    return [self _keyForObjectClass:object.class primaryValues:primaryKeys];
}

+ (NSString *)_keyForObjectClass:(Class)objectClass primaryValues:(NSDictionary *)primaryValues
{
    NSMutableString *keyForObject = [NSMutableString stringWithString:[objectClass sqliteTableName]];
    
    [primaryValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [keyForObject appendFormat:@",%@=%@", key, obj];
    }];
    
    return keyForObject;
}

- (void)registerObject:(TNKObject *)object
{
    [self performBlock:^{
        [_registeredObjects setObject:object forKey:[self.class _keyForObject:object]];
    }];
}

- (void)insertObject:(TNKObject *)object
{
    NSString *key = [self.class _keyForObject:object];
    [self performBlock:^{
        [_insertedObjects addObject:object];
        [_registeredObjects setObject:object forKey:key];
        [self setNeedsSave];
    }];
}

- (void)updateObject:(TNKObject *)object
{
    [self performBlock:^{
        [_updatedObjects addObject:object];
        [self setNeedsSave];
    }];
}

- (void)deleteObject:(TNKObject *)object
{
    [self performBlock:^{
        [_deletedObjects addObject:object];
        [self setNeedsSave];
    }];
}


#pragma mark - Concurrency

- (void)performBlock:(void(^)())block
{
    if ([[NSThread currentThread].threadDictionary[TNKInPropertyQueueThreadKey] boolValue]) {
        block();
    } else {
        dispatch_async(_propertyQueue, ^{
            [NSThread currentThread].threadDictionary[TNKInPropertyQueueThreadKey] = @YES;
            block();
            [[NSThread currentThread].threadDictionary removeObjectForKey:TNKInPropertyQueueThreadKey];
        });
    }
}

- (void)performBlockAndWait:(void(^)())block
{
    if ([[NSThread currentThread].threadDictionary[TNKInPropertyQueueThreadKey] boolValue]) {
        block();
    } else {
        dispatch_sync(_propertyQueue, ^{
            [NSThread currentThread].threadDictionary[TNKInPropertyQueueThreadKey] = @YES;
            block();
            [[NSThread currentThread].threadDictionary removeObjectForKey:TNKInPropertyQueueThreadKey];
        });
    }
}


#pragma mark - Saving

- (void)setNeedsSave
{
    [self performBlock:^{
        if (!_needsSave) {
            _needsSave = YES;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, self.saveInterval * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                [self triggerSave];
            });
        }
    }];
}

- (void)triggerSave
{
    [self performBlock:^{
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
    }];
}

- (void)save
{
    NSLog(@"saving");
    
    __block NSSet *insertedObjects = nil;
    __block NSSet *updatedObjects = nil;
    __block NSSet *deletedObjects = nil;
    [self performBlockAndWait:^{
        _needsSave = NO;
        
        insertedObjects = [_insertedObjects copy];
        _insertedObjects = [NSMutableSet new];
        
        updatedObjects = [_updatedObjects copy];
        _updatedObjects = [NSMutableSet new];
        
        deletedObjects = [_deletedObjects copy];
        _deletedObjects = [NSMutableSet new];
    }];
    
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
