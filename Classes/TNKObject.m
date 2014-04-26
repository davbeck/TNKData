//
//  TNKObject.m
//  Pods
//
//  Created by David Beck on 4/22/14.
//
//

#import "TNKObject.h"

#import <objc/runtime.h>

#import "TNKData.h"
#import "TNKConnection_Private.h"


#define TNKInObjectQueueThreadKey @"TNKInObjectQueue"


@interface TNKObject ()
{
    NSMutableDictionary *_faultedValues;
    NSMutableDictionary *_changedValues;
    dispatch_queue_t _propertyQueue;
    
    BOOL _initializing;
}

@property (nonatomic, weak, readwrite) TNKConnection *connection;

@end


@implementation TNKObject

@dynamic objectID;


#pragma mark - Properties

- (NSDictionary *)faultedValues
{
    __block NSDictionary *faultedValues = nil;
    [self performBlockAndWait:^{
        faultedValues = [_faultedValues copy];
    }];
    
    return faultedValues;
}

- (NSDictionary *)changedValues
{
    __block NSDictionary *changedValues = nil;
    [self performBlockAndWait:^{
        changedValues = [_changedValues copy];
    }];
    
    return changedValues;
}

- (BOOL)isInserted
{
    return _initializing || [self.connection.insertedObjects containsObject:self];
}

- (BOOL)isUpdated
{
    return [self.connection.updatedObjects containsObject:self];
}

- (BOOL)isDeleted
{
    return [self.connection.deletedObjects containsObject:self];
}


#pragma mark - Property Convenience Methods

+ (SEL)_getterForPersistentKey:(NSString *)key
{
    objc_property_t property = class_getProperty(self, [key UTF8String]);
    
    if (property == NULL) {
        return NULL;
    }
    
    char *getterString = property_copyAttributeValue(property, "G");
    SEL getter = NULL;
    if (getterString != NULL) {
        getter = sel_getUid(getterString);
        free(getterString);
    } else {
        getter = NSSelectorFromString(key);
    }
    
    return getter;
}

+ (SEL)_setterForPersistentKey:(NSString *)key
{
    objc_property_t property = class_getProperty(self, [key UTF8String]);
    
    if (property == NULL) {
        return NULL;
    }
    
    char *setterString = property_copyAttributeValue(property, "S");
    SEL setter = NULL;
    if (setterString != NULL) {
        setter = sel_getUid(setterString);
        free(setterString);
    } else {
        NSString *capitalizedKey = [key stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[key substringToIndex:1] capitalizedString]];
        setter = NSSelectorFromString([NSString stringWithFormat:@"set%@:", capitalizedKey]);
    }
    
    return setter;
}

+ (BOOL)_persistentKeyIsReadonly:(NSString *)key
{
    objc_property_t property = class_getProperty(self, [key UTF8String]);
    
    if (property == NULL) {
        return YES;
    }
    
    char *readonlyUTF8 = property_copyAttributeValue(property, "R");
    BOOL readonly = readonlyUTF8 != NULL;
    free(readonlyUTF8);
    
    return readonly;
}

+ (NSString *)_typeForPersistentKey:(NSString *)key
{
    objc_property_t property = class_getProperty(self, [key UTF8String]);
    
    if (property == NULL) {
        return nil;
    }
    
    char *typeUTF8 = property_copyAttributeValue(property, "T");
    NSString *type = [NSString stringWithUTF8String:typeUTF8];
    free(typeUTF8);
    
    return type;
}

+ (Class)_classForPersistentKey:(NSString *)key
{
    NSString *type = [self _typeForPersistentKey:key];
    
    if ([type characterAtIndex:0] == '@') {
        if (type.length > 3) {
            // formatted as @"NSClass"
            NSString *className = [type substringWithRange:NSMakeRange(2, type.length - 3)];
            Class class = NSClassFromString(className);
            
            if (class != Nil) {
                return class;
            }
        }
    } else {
        return [NSNumber class];
    }
    
    return Nil;
}

+ (NSString *)_keyForSelector:(SEL)selector
{
    __block NSString *keyForSelector = nil;
    [[self persistentKeys] enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *key, BOOL *stop) {
        if (selector == [self _getterForPersistentKey:key]) {
            keyForSelector = key;
        } else if (selector == [self _setterForPersistentKey:key]) {
            keyForSelector = key;
        }
        
        *stop = keyForSelector != nil;
    }];
    
    return keyForSelector;
}


#pragma mark - Property Swizzling

- (char)_persistentGetter_char
{
    return [[self primitiveValueForKey:[self.class _keyForSelector:_cmd]] charValue];
}

- (short)_persistentGetter_short
{
    return [[self primitiveValueForKey:[self.class _keyForSelector:_cmd]] shortValue];
}

- (int)_persistentGetter_int
{
    return [[self primitiveValueForKey:[self.class _keyForSelector:_cmd]] intValue];
}

- (long)_persistentGetter_long
{
    return [[self primitiveValueForKey:[self.class _keyForSelector:_cmd]] longValue];
}

- (long long)_persistentGetter_long_long
{
    return [[self primitiveValueForKey:[self.class _keyForSelector:_cmd]] longLongValue];
}

- (unsigned char)_persistentGetter_unsigned_char
{
    return [[self primitiveValueForKey:[self.class _keyForSelector:_cmd]] unsignedCharValue];
}

- (unsigned short)_persistentGetter_unsigned_short
{
    return [[self primitiveValueForKey:[self.class _keyForSelector:_cmd]] unsignedShortValue];
}

- (unsigned int)_persistentGetter_unsigned_int
{
    return [[self primitiveValueForKey:[self.class _keyForSelector:_cmd]] unsignedIntValue];
}

- (unsigned long)_persistentGetter_unsigned_long
{
    return [[self primitiveValueForKey:[self.class _keyForSelector:_cmd]] unsignedLongValue];
}

- (unsigned long long)_persistentGetter_unsigned_long_long
{
    return [[self primitiveValueForKey:[self.class _keyForSelector:_cmd]] unsignedLongLongValue];
}

- (bool)_persistentGetter_bool
{
    return [[self primitiveValueForKey:[self.class _keyForSelector:_cmd]] boolValue];
}

- (float)_persistentGetter_float
{
    return [[self primitiveValueForKey:[self.class _keyForSelector:_cmd]] floatValue];
}

- (double)_persistentGetter_double
{
    return [[self primitiveValueForKey:[self.class _keyForSelector:_cmd]] doubleValue];
}

- (id)_persistentGetter_id
{
    return [self primitiveValueForKey:[self.class _keyForSelector:_cmd]];
}

+ (SEL)_primativeGetterForKey:(NSString *)key
{
    NSString *type = [self _typeForPersistentKey:key];
    
    switch ([type characterAtIndex:0]) {
        case 'c':
            return @selector(_persistentGetter_char);
        case 's':
            return @selector(_persistentGetter_short);
        case 'i':
            return @selector(_persistentGetter_int);
        case 'l':
            return @selector(_persistentGetter_long);
        case 'q':
            return @selector(_persistentGetter_long_long);
        case 'C':
            return @selector(_persistentGetter_unsigned_char);
        case 'I':
            return @selector(_persistentGetter_unsigned_int);
        case 'S':
            return @selector(_persistentGetter_unsigned_short);
        case 'L':
            return @selector(_persistentGetter_unsigned_long);
        case 'Q':
            return @selector(_persistentGetter_unsigned_long_long);
        case 'B':
            return @selector(_persistentGetter_bool);
        case 'f':
            return @selector(_persistentGetter_float);
        case 'd':
            return @selector(_persistentGetter_double);
        default:
            return @selector(_persistentGetter_id);
    }
}

- (void)_persistentSetter_char:(char)value
{
    [self setPrimativeValue:@(value) forKey:[self.class _keyForSelector:_cmd]];
}

- (void)_persistentSetter_short:(short)value
{
    [self setPrimativeValue:@(value) forKey:[self.class _keyForSelector:_cmd]];
}

- (void)_persistentSetter_int:(int)value
{
    [self setPrimativeValue:@(value) forKey:[self.class _keyForSelector:_cmd]];
}

- (void)_persistentSetter_long:(long)value
{
    [self setPrimativeValue:@(value) forKey:[self.class _keyForSelector:_cmd]];
}

- (void)_persistentSetter_long_long:(long long)value
{
    [self setPrimativeValue:@(value) forKey:[self.class _keyForSelector:_cmd]];
}

- (void)_persistentSetter_unsigned_char:(unsigned char)value
{
    [self setPrimativeValue:@(value) forKey:[self.class _keyForSelector:_cmd]];
}

- (void)_persistentSetter_unsigned_short:(unsigned short)value
{
    [self setPrimativeValue:@(value) forKey:[self.class _keyForSelector:_cmd]];
}

- (void)_persistentSetter_unsigned_int:(unsigned int)value
{
    [self setPrimativeValue:@(value) forKey:[self.class _keyForSelector:_cmd]];
}

- (void)_persistentSetter_unsigned_long:(unsigned long)value
{
    [self setPrimativeValue:@(value) forKey:[self.class _keyForSelector:_cmd]];
}

- (void)_persistentSetter_unsigned_long_long:(unsigned long long)value
{
    [self setPrimativeValue:@(value) forKey:[self.class _keyForSelector:_cmd]];
}

- (void)_persistentSetter_bool:(bool)value
{
    [self setPrimativeValue:@(value) forKey:[self.class _keyForSelector:_cmd]];
}

- (void)_persistentSetter_float:(float)value
{
    [self setPrimativeValue:@(value) forKey:[self.class _keyForSelector:_cmd]];
}

- (void)_persistentSetter_double:(double)value
{
    [self setPrimativeValue:@(value) forKey:[self.class _keyForSelector:_cmd]];
}

- (void)_persistentSetter_id:(id)value
{
    [self setPrimativeValue:value forKey:[self.class _keyForSelector:_cmd]];
}

+ (SEL)_primativeSetterForKey:(NSString *)key
{
    NSString *type = [self _typeForPersistentKey:key];
    
    switch ([type characterAtIndex:0]) {
        case 'c':
            return @selector(_persistentSetter_char:);
        case 's':
            return @selector(_persistentSetter_short:);
        case 'i':
            return @selector(_persistentSetter_int:);
        case 'l':
            return @selector(_persistentSetter_long:);
        case 'q':
            return @selector(_persistentSetter_long_long:);
        case 'C':
            return @selector(_persistentSetter_unsigned_char:);
        case 'I':
            return @selector(_persistentSetter_unsigned_int:);
        case 'S':
            return @selector(_persistentSetter_unsigned_short:);
        case 'L':
            return @selector(_persistentSetter_unsigned_long:);
        case 'Q':
            return @selector(_persistentSetter_unsigned_long_long:);
        case 'B':
            return @selector(_persistentSetter_bool:);
        case 'f':
            return @selector(_persistentSetter_float:);
        case 'd':
            return @selector(_persistentSetter_double:);
        default:
            return @selector(_persistentSetter_id:);
    }
}

+ (BOOL)resolveInstanceMethod:(SEL)selector
{
    NSString *key = [self _keyForSelector:selector];
    if (key != nil) {
        if (selector == [self _getterForPersistentKey:key]) {
            Method method = class_getInstanceMethod(self, [self _primativeGetterForKey:key]);
            return class_addMethod(self, selector, method_getImplementation(method), method_getTypeEncoding(method));
        } else {
            Method method = class_getInstanceMethod(self, [self _primativeSetterForKey:key]);
            return class_addMethod(self, selector, method_getImplementation(method), method_getTypeEncoding(method));
        }
    }
    
    return [super resolveInstanceMethod:selector];
}


#pragma mark - Persistent Key Management

+ (NSSet *)persistentKeys
{
    return [NSSet setWithObject:@"objectID"];
}

+ (NSSet *)primaryKeys
{
    return [NSSet setWithObject:@"objectID"];
}

- (id)primitiveValueForKey:(NSString *)key
{
    __block id value = nil;
    [self performBlockAndWait:^{
        value = _faultedValues[key];
    }];
    
    return value;
}

- (void)setPrimativeValue:(id)value forKey:(NSString *)key
{
    value = [value copy];
    [self performBlock:^{
        _faultedValues[key] = value;
        _changedValues[key] = value;
        if (!self.isInserted && !self.isUpdated && !self.isDeleted) {
            [self.connection updateObject:self];
        }
    }];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    return [self primitiveValueForKey:key] ?: [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if ([[self.class persistentKeys] containsObject:key]) {
        [self setPrimativeValue:value forKey:key];
    } else {
        [super setValue:value forUndefinedKey:key];
    }
}


#pragma mark - SQLite

+ (NSString *)sqliteTableName
{
    return NSStringFromClass([self class]);
}

+ (NSString *)sqliteTypeForPersistentKey:(NSString *)persistentKey
{
    NSString *type = [self _typeForPersistentKey:persistentKey];
    
    if ([type characterAtIndex:0] == '@') {
        if (type.length > 3) {
            // formatted as @"NSClass"
            NSString *className = [type substringWithRange:NSMakeRange(2, type.length - 3)];
            Class class = NSClassFromString(className);
            
            if (class != Nil) {
                if ([class isSubclassOfClass:[NSString class]]) {
                    return @"TEXT";
                } else if ([class isSubclassOfClass:[NSNumber class]]) {
                    return @"REAL";
                } else if ([class isSubclassOfClass:[NSDate class]]) {
                    return @"REAL";
                }
            }
        }
        
        return @"BLOB";
    } else {
        switch ([type characterAtIndex:0]) {
            case 'c':
            case 'i':
            case 's':
            case 'l':
            case 'q':
            case 'C':
            case 'I':
            case 'S':
            case 'L':
            case 'Q':
            case 'B':
                return @"INTEGER";
            case 'f':
            case 'd':
                return @"REAL";
        }
    }
    
    return nil;
}

+ (NSString *)sqliteColumnConstraintsForPersistentKey:(NSString *)persistentKey
{
    if ([[self primaryKeys] containsObject:persistentKey]) {
        return @"PRIMARY KEY";
    }
    
    return nil;
}

- (NSString *)sqliteWhereClause
{
    NSSet *primaryKeys = [self.class primaryKeys];
    NSMutableArray *keyClauses = [[NSMutableArray alloc] initWithCapacity:primaryKeys.count];
    for (NSString *key in primaryKeys) {
        [keyClauses addObject:[NSString stringWithFormat:@"%1$@ = :%1$@", key]];
    }
    
    return [keyClauses componentsJoinedByString:@" AND "];
}

+ (void)createTableInDatabase:(FMDatabase *)db
{
    NSSet *persistentKeys = [self persistentKeys];
    NSMutableArray *columnDefinitions = [NSMutableArray new];
    for (NSString *key in persistentKeys) {
        NSString *type = [self sqliteTypeForPersistentKey:key] ?: @"";
        NSString *columnConstraints = [self sqliteColumnConstraintsForPersistentKey:key] ?: @"";
        
        [columnDefinitions addObject:[NSString stringWithFormat:@"%@ %@ %@", key, type, columnConstraints]];
    }
    
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@)", [self sqliteTableName], [columnDefinitions componentsJoinedByString:@", "]];
    NSLog(@"create table sql: %@", sql);
    [db executeUpdate:sql];
}

- (void)insertIntoDatabase:(FMDatabase *)db
{
    NSDictionary *values = [self.changedValues copy];
    NSArray *keys = [values allKeys];
    NSMutableArray *keyPlaceholder = [[NSMutableArray alloc] initWithCapacity:keys.count];
    for (NSString *key in keys) {
        [keyPlaceholder addObject:[@":" stringByAppendingString:key]];
    }
    
    NSString *query = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", [self.class sqliteTableName], [keys componentsJoinedByString:@", "], [keyPlaceholder componentsJoinedByString:@", "]];
    NSLog(@"insert query: %@", query);
    
    [db executeUpdate:query withParameterDictionary:values];
    
    [self performBlockAndWait:^{
        _faultedValues[@"objectID"] = @([db lastInsertRowId]);
    }];
}

- (void)updateInDatabase:(FMDatabase *)db
{
    NSMutableDictionary *values = [self.changedValues mutableCopy];
    NSArray *keys = [values allKeys];
    NSMutableArray *keyClauses = [[NSMutableArray alloc] initWithCapacity:keys.count];
    for (NSString *key in keys) {
        [keyClauses addObject:[NSString stringWithFormat:@"%1$@ = :%1$@", key]];
    }
    
    for (NSString *key in [self.class primaryKeys]) {
        values[key] = [self valueForKey:key];
    }
    
    NSString *query = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@", [self.class sqliteTableName], [keyClauses componentsJoinedByString:@", "], [self sqliteWhereClause]];
    NSLog(@"update query: %@", query);
    
    [db executeUpdate:query withParameterDictionary:values];
}

- (void)deleteFromDatabase:(FMDatabase *)db
{
    NSMutableDictionary *values = [[NSMutableDictionary alloc] initWithCapacity:[self.class primaryKeys].count];
    for (NSString *key in [self.class primaryKeys]) {
        values[key] = [self valueForKey:key];
    }
    
    NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@", [self.class sqliteTableName], [self sqliteWhereClause]];
    NSLog(@"delete query: %@", query);
    
    [db executeUpdate:query withParameterDictionary:values];
}

+ (NSArray *)executeQuery:(TNKObjectQuery *)objectQuery inDatabase:(FMDatabase *)db
{
    NSString *whereClause = [objectQuery.predicate sqliteWhereClause];
    NSArray *arguments = [objectQuery.predicate sqliteWhereClauseArguments];
    NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@", [[objectQuery.keysToFetch allObjects] componentsJoinedByString:@", "], [self.class sqliteTableName], whereClause];
    NSLog(@"select query: %@, [%@]", query, [arguments componentsJoinedByString:@", "]);
    
    FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:arguments];
    NSMutableArray *objects = [NSMutableArray new];
    while ([resultSet next]) {
        TNKObject *object = [[self alloc] init];
        object.connection = [TNKConnection currentConnection];
        
        NSDictionary *resultDictionary = resultSet.resultDictionary;
        NSMutableDictionary *faultedValues = [[NSMutableDictionary alloc] initWithCapacity:resultDictionary.count];
        [resultDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            Class class = [self _classForPersistentKey:key];
            if ([class isSubclassOfClass:[NSDate class]] && [obj respondsToSelector:@selector(doubleValue)]) {
                faultedValues[key] = [class dateWithTimeIntervalSince1970:[obj doubleValue]];
            } else if ([class isSubclassOfClass:[NSString class]] && ![obj isKindOfClass:class]) {
                faultedValues[key] = [class stringWithString:[obj description]];
            } else if ([class isSubclassOfClass:[NSNumber class]] && ![obj isKindOfClass:class] && [obj respondsToSelector:@selector(doubleValue)]) {
                faultedValues[key] = [class numberWithDouble:[obj doubleValue]];
            } else if ([obj isKindOfClass:class]) {
                faultedValues[key] = obj;
            } else {
                NSLog(@"Warning, ignoring object because it is not able to be converted to the correct type: obj=%@, key=%@, expected class=%@", obj, key, NSStringFromClass(class));
            }
        }];
        object->_faultedValues = faultedValues;
        [object.connection registerObject:object];
        
        [objects addObject:object];
    }
    
    return objects;
}


#pragma mark - Insertion

- (instancetype)init
{
    self = [super init];
    if (self) {
        _propertyQueue = dispatch_queue_create("TNKObject_property", NULL);
        
        _faultedValues = [NSMutableDictionary new];
        _changedValues = [NSMutableDictionary new];
    }
    
    return self;
}

+ (instancetype)find:(NSDictionary *)values
{
    return [self find:values usingQuery:nil];
}

+ (instancetype)find:(NSDictionary *)values usingQuery:(void(^)(TNKObjectQuery *query))queryBlock
{
    TNKObject *object = [[TNKConnection currentConnection] existingObjectWithClass:self.class primaryValues:values];
    
    if (object == nil) {
        TNKObjectQuery *query = [[TNKObjectQuery alloc] initWithObjectClass:self.class];
        query.limit = 1;
        
        NSMutableArray *predicates = [NSMutableArray new];
        [values enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [predicates addObject:[NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:key]
                                                                     rightExpression:[NSExpression expressionForConstantValue:obj]
                                                                            modifier:NSDirectPredicateModifier
                                                                                type:NSEqualToPredicateOperatorType
                                                                             options:0]];
        }];
        query.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
        
        if (queryBlock != nil) {
            queryBlock(query);
        }
        
        object = [query run].firstObject;
    }
    
    return object;
}

+ (instancetype)findByServerID:(NSUInteger)serverID
{
    return [self find:@{@"objectID": @(serverID)}];
}

+ (instancetype)insertObjectWithInitialization:(void(^)(id object))initialization
{
    TNKObject *object = [[self alloc] init];
    object.connection = [TNKConnection currentConnection];
    object->_initializing = YES;
    
    if (initialization != nil) {
        initialization(object);
    }
    
    [object.connection insertObject:object];
    object->_initializing = NO;
    
    return object;
}

- (void)deleteObject
{
    [self.connection deleteObject:self];
}


#pragma mark - Concurrency

- (void)performBlock:(void(^)())block
{
    if ([[NSThread currentThread].threadDictionary[TNKInObjectQueueThreadKey] boolValue]) {
        block();
    } else {
        dispatch_async(_propertyQueue, ^{
            [NSThread currentThread].threadDictionary[TNKInObjectQueueThreadKey] = @YES;
            block();
            [[NSThread currentThread].threadDictionary removeObjectForKey:TNKInObjectQueueThreadKey];
        });
    }
}

- (void)performBlockAndWait:(void(^)())block
{
    if ([[NSThread currentThread].threadDictionary[TNKInObjectQueueThreadKey] boolValue]) {
        block();
    } else {
        dispatch_sync(_propertyQueue, ^{
            [NSThread currentThread].threadDictionary[TNKInObjectQueueThreadKey] = @YES;
            block();
            [[NSThread currentThread].threadDictionary removeObjectForKey:TNKInObjectQueueThreadKey];
        });
    }
}


#pragma mark - 

- (NSString *)description
{
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"<"];
    [description appendString:NSStringFromClass(self.class)];
    [description appendString:@": "];
    [description appendFormat:@"%p", self];
    [description appendString:@"{"];
    
    NSDictionary *faultedValues = self.faultedValues;
    BOOL first = YES;
    for (NSString *key in [self.class persistentKeys]) {
        if (!first) {
            [description appendString:@", "];
        }
        first = NO;
        
        [description appendString:key];
        [description appendString:@"="];
        if (faultedValues[key] == nil) {
            [description appendString:@"(fault)"];
        } else {
            [description appendString:[faultedValues[key] description]];
        }
    }
    
    [description appendString:@"}>"];
    
    return description;
}

@end
