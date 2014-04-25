//
//  NSPredicate+TNKWhereClause.h
//  Pods
//
//  Created by David Beck on 4/24/14.
//
//

#import <Foundation/Foundation.h>

@interface NSPredicate (TNKWhereClause)

/** A WHERE clause for an sqlite SELECT, INSERT or DELETE query
 
 This method is used internally by TNKData to generate SQL statements.
 
 @warning *Warning:* This method throws exceptions any time it encounters an NSPredicate option that cannot be converted into SQL.
 
 @return A WHERE clause generated from the predicate (without the WHERE keyword).
 */
- (NSString *)sqliteWhereClause;

/** The arguments used in `sqliteWhereClause`
 
 This method is used internally by TNKData to generate SQL statements. The returned objects **must** be in the same order as
 question marks appear in the clause returned from `sqliteWhereClause`.
 
 @warning *Warning:* This method throws exceptions any time it encounters an NSPredicate option that cannot be converted into SQL.
 
 @return An array of arguments for an SQL WHERE clause.
 */
- (NSArray *)sqliteWhereClauseArguments;

@end

@interface NSExpression (TNKWhereClause)

/** A WHERE clause for an sqlite SELECT, INSERT or DELETE query
 
 This method is used internally by TNKData to generate SQL statements.
 
 @warning *Warning:* This method throws exceptions any time it encounters an NSPredicate option that cannot be converted into SQL.
 
 @return A WHERE clause generated from the predicate (without the WHERE keyword).
 */
- (NSString *)sqliteWhereClause;

/** The arguments used in `sqliteWhereClause`
 
 This method is used internally by TNKData to generate SQL statements. The returned objects **must** be in the same order as
 question marks appear in the clause returned from `sqliteWhereClause`.
 
 @warning *Warning:* This method throws exceptions any time it encounters an NSPredicate option that cannot be converted into SQL.
 
 @return An array of arguments for an SQL WHERE clause.
 */
- (NSArray *)sqliteWhereClauseArguments;

@end
