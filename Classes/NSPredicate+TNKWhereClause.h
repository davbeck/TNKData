//
//  NSPredicate+TNKWhereClause.h
//  Pods
//
//  Created by David Beck on 4/24/14.
//
//

#import <Foundation/Foundation.h>

@interface NSPredicate (TNKWhereClause)

- (NSString *)sqliteWhereClause;
- (NSArray *)sqliteWhereClauseArguments;

@end

@interface NSExpression (TNKWhereClause)

- (NSString *)sqliteWhereClause;
- (NSArray *)sqliteWhereClauseArguments;

@end
