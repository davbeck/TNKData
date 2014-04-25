//
//  TNKQuery.h
//  Pods
//
//  Created by David Beck on 4/24/14.
//
//

#import <Foundation/Foundation.h>


@interface TNKObjectQuery : NSObject

- (instancetype)initWithObjectClass:(Class)objectClass;

@property (nonatomic, readonly) Class objectClass;
@property (nonatomic, copy) NSSet *keysToFetch;
@property (nonatomic) BOOL returnObjectsAsFaults;
@property (nonatomic) NSUInteger limit;
@property (nonatomic, copy) NSPredicate *predicate;

- (NSArray *)run;

@end
