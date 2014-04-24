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


@interface TNKObject ()
{
    NSMutableDictionary *_faultedValues;
    NSMutableDictionary *_changedValues;
    dispatch_queue_t _propertyQueue;
}

@property (nonatomic, weak, readwrite) TNKConnection *connection;
@property (nonatomic, readwrite) BOOL isInserted;

@end


@implementation TNKObject

@dynamic id;


#pragma mark - Properties

- (NSDictionary *)faultedValues
{
    __block NSDictionary *faultedValues = nil;
    dispatch_sync(_propertyQueue, ^{
        faultedValues = [_faultedValues copy];
    });
    
    return faultedValues;
}

- (NSDictionary *)changedValues
{
    __block NSDictionary *changedValues = nil;
    dispatch_sync(_propertyQueue, ^{
        changedValues = [_changedValues copy];
    });
    
    return changedValues;
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
        setter = NSSelectorFromString([NSString stringWithFormat:@"set%@:", [key capitalizedString]]);
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

- (const char *)_persistentGetter_string
{
    return [[self primitiveValueForKey:[self.class _keyForSelector:_cmd]] UTF8String];
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
        case '*':
            return @selector(_persistentGetter_string);
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

- (void)_persistentSetter_string:(const char *)value
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
        case '*':
            return @selector(_persistentSetter_string:);
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
    return [NSSet setWithObject:@"id"];
}

+ (NSSet *)primaryKeys
{
    return [NSSet setWithObject:@"id"];
}

- (id)primitiveValueForKey:(NSString *)key
{
    __block id value = nil;
    dispatch_sync(_propertyQueue, ^{
        value = _faultedValues[key];
    });
    
    return value;
}

- (void)setPrimativeValue:(id)value forKey:(NSString *)key
{
    value = [value copy];
    dispatch_async(_propertyQueue, ^{
        _faultedValues[key] = value;
        _changedValues[key] = value;
    });
}


#pragma mark - SQLite

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
            case '*':
                return @"TEXT";
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

+ (void)createTableInDatabase:(FMDatabase *)db
{
    NSSet *persistentKeys = [self persistentKeys];
    NSMutableArray *columnDefinitions = [NSMutableArray new];
    for (NSString *key in persistentKeys) {
        NSString *type = [self sqliteTypeForPersistentKey:key] ?: @"";
        NSString *columnConstraints = [self sqliteColumnConstraintsForPersistentKey:key] ?: @"";
        
        [columnDefinitions addObject:[NSString stringWithFormat:@"%@ %@ %@", key, type, columnConstraints]];
    }
    
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@)", NSStringFromClass([self class]), [columnDefinitions componentsJoinedByString:@", "]];
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
    
    NSString *query = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", NSStringFromClass([self class]), [keys componentsJoinedByString:@", "], [keyPlaceholder componentsJoinedByString:@", "]];
    NSLog(@"query: %@", query);
    
    [db executeUpdate:query withParameterDictionary:values];
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

+ (instancetype)insertObjectWithInitialization:(void(^)(id object))initialization
{
    TNKObject *object = [[self alloc] init];
    object.connection = [TNKConnection currentConnection];
    object.isInserted = YES;
    
    if (initialization != nil) {
        initialization(object);
    }
    
    dispatch_sync(object->_propertyQueue, ^{
        [object.connection insertObject:object];
    });
    
    return object;
}

@end
