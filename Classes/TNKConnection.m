//
//  TNKConnection.m
//  Pods
//
//  Created by David Beck on 4/22/14.
//
//

#import "TNKConnection.h"

#import "TNKData.h"


@implementation TNKConnection
{
    FMDatabaseQueue *_databaseQueue;
    NSSet *_classes;
}

static TNKConnection *_defaultConnection = nil;

+ (void)setDefaultConnection:(TNKConnection *)connection
{
    _defaultConnection = connection;
}

+ (TNKConnection *)defaultConnection
{
    return _defaultConnection;
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

@end
