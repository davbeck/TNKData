//
//  TNKConnection.h
//  Pods
//
//  Created by David Beck on 4/22/14.
//
//

#import <Foundation/Foundation.h>

@interface TNKConnection : NSObject

+ (void)setDefaultConnection:(TNKConnection *)connection;

+ (instancetype)connectionWithURL:(NSURL *)URL classes:(NSSet *)classes;
- (instancetype)initWithURL:(NSURL *)URL classes:(NSSet *)classes;

@end
