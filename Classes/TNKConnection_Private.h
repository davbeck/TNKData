//
//  TNKConnection_Private.h
//  Pods
//
//  Created by David Beck on 4/23/14.
//
//

#import "TNKConnection.h"

@class TNKObject;


@interface TNKConnection ()

- (void)insertObject:(TNKObject *)object;
- (void)updateObject:(TNKObject *)object;
- (void)deleteObject:(TNKObject *)object;

@end
