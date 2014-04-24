//
//  TNKConnection.h
//  Pods
//
//  Created by David Beck on 4/22/14.
//
//

#import <Foundation/Foundation.h>

@interface TNKConnection : NSObject

@property (strong, readonly) NSSet *insertedObjects;

+ (void)setDefaultConnection:(TNKConnection *)connection;
+ (instancetype)defaultConnection;
+ (instancetype)currentConnection;
+ (void)useConnection:(TNKConnection *)connection block:(void(^)(TNKConnection *connection))block;

+ (instancetype)connectionWithURL:(NSURL *)URL classes:(NSSet *)classes;
- (instancetype)initWithURL:(NSURL *)URL classes:(NSSet *)classes;

- (void)setNeedsSave;
- (void)save;

@end
