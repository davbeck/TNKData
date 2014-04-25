//
//  NSPredicate+TNKWhereClause.m
//  Pods
//
//  Created by David Beck on 4/24/14.
//
//

#import "NSPredicate+TNKWhereClause.h"

@implementation NSPredicate (TNKWhereClause)

- (NSString *)sqliteWhereClause
{
    NSAssert(NO, @"Unsupported predicate for sqlite: %@", self);
    return nil;
}

- (NSArray *)sqliteWhereClauseArguments
{
    NSAssert(NO, @"Unsupported predicate for sqlite: %@", self);
    return nil;
}

@end

@implementation NSCompoundPredicate (TNKWhereClause)

- (NSString *)sqliteWhereClause
{
    switch (self.compoundPredicateType) {
        case NSAndPredicateType: {
            return [NSString stringWithFormat:@"(%@)", [[self.subpredicates valueForKey:@"sqliteWhereClause"] componentsJoinedByString:@" AND "]];
        } case NSOrPredicateType: {
            return [NSString stringWithFormat:@"(%@)", [[self.subpredicates valueForKey:@"sqliteWhereClause"] componentsJoinedByString:@" OR "]];
        } case NSNotPredicateType: {
            return [NSString stringWithFormat:@"(NOT %@)", [self.subpredicates.firstObject sqliteWhereClause]];
        }
    }
}

- (NSArray *)sqliteWhereClauseArguments
{
    return [self.subpredicates valueForKeyPath:@"@unionOfArrays.sqliteWhereClauseArguments"];
}

@end

@implementation NSComparisonPredicate (TNKWhereClause)

// http://www.sqlite.org/lang_expr.html
- (NSString *)sqliteWhereClause
{
    switch (self.comparisonPredicateModifier) {
        case NSDirectPredicateModifier: {
            NSString *operator = nil;
            switch (self.predicateOperatorType) {
                case NSLessThanPredicateOperatorType: {
                    operator = @"<";
                    break;
                } case NSLessThanOrEqualToPredicateOperatorType: {
                    operator = @"<=";
                    break;
                } case NSGreaterThanPredicateOperatorType: {
                    operator = @">";
                    break;
                } case NSGreaterThanOrEqualToPredicateOperatorType: {
                    operator = @">=";
                    break;
                } case NSEqualToPredicateOperatorType: {
                    operator = @"==";
                    break;
                } case NSNotEqualToPredicateOperatorType: {
                    operator = @"!=";
                    break;
                } default: {
                    break;
                }
            }
            NSAssert(operator != nil, @"Unsupported predicate for sqlite (unsupported predicateOperatorType): %@", self);
            
            return [NSString stringWithFormat:@"(%@ %@ %@)", [self.leftExpression sqliteWhereClause], operator, [self.rightExpression sqliteWhereClause]];
        } default: {
            NSAssert(NO, @"Unsupported predicate for sqlite: %@", self);
            return nil;
        }
    }
}

- (NSArray *)sqliteWhereClauseArguments
{
    NSArray *sqliteWhereClauseArguments = [self.leftExpression sqliteWhereClauseArguments] ?: @[];
    sqliteWhereClauseArguments = [sqliteWhereClauseArguments arrayByAddingObjectsFromArray:[self.rightExpression sqliteWhereClauseArguments] ?: @[]];
    
    return sqliteWhereClauseArguments;
}

@end

@implementation NSExpression (TNKWhereClause)

- (NSString *)sqliteWhereClause
{
    switch (self.expressionType) {
        case NSConstantValueExpressionType: {
            return @"?";
        } case NSKeyPathExpressionType: {
            return self.keyPath;
        } default: {
            NSAssert(NO, @"Unsupported predicate expression for sqlite: %@", self);
            return nil;
        }
    }
}

- (NSArray *)sqliteWhereClauseArguments
{
    switch (self.expressionType) {
        case NSConstantValueExpressionType: {
            return @[ self.constantValue ?: [NSNull null] ];
        } default: {
            return @[];
        }
    }
}

@end
