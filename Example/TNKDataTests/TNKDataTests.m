//
//  TNKDataDemoTests.m
//  TNKDataDemoTests
//
//  Created by David Beck on 4/22/14.
//  Copyright (c) 2014 ThinkUltimate. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <TNKData/TNKData.h>
#import <TNKData/TNKConnection_Private.h>
#import <FMDB/FMDatabase.h>

#import "TNKTestObject.h"


@interface TNKDataDemoTests : XCTestCase
{
    TNKConnection *_connection;
}

@end

@implementation TNKDataDemoTests

- (void)setUp
{
    [super setUp];
    
    _connection = [TNKConnection connectionWithURL:nil classes:[NSSet setWithObject:[TNKTestObject class]]];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTableCreation
{
    [_connection.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:@"SELECT name FROM sqlite_master WHERE type='table';"];
        while ([resultSet next]) {
            XCTAssertEqualObjects([resultSet stringForColumn:@"name"], NSStringFromClass([TNKTestObject class]), @"The connection creates a table for the class.");
        }
    }];
}

- (void)testColumnCreation
{
    [_connection.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"PRAGMA table_info(%@)", [TNKTestObject class]]];
        NSMutableDictionary *columns = [NSMutableDictionary new];
        while ([resultSet next]) {
            columns[[resultSet stringForColumn:@"name"]] = [resultSet resultDictionary];
        }
        
        XCTAssertNotEqualObjects(columns[@"objectID"], nil, @"The connection creates a column for objectID.");
        XCTAssertEqualObjects(columns[@"objectID"][@"type"], @"INTEGER", @"objectID should be an INTEGER.");
        XCTAssert([columns[@"objectID"][@"pk"] boolValue], @"objectID should be a primary key.");
        
        XCTAssertNotEqualObjects(columns[@"stringProperty"], nil, @"The connection creates a column for stringProperty.");
        XCTAssertEqualObjects(columns[@"stringProperty"][@"type"], @"TEXT", @"stringProperty should be an INTEGER.");
        
        XCTAssertNotEqualObjects(columns[@"numberProperty"], nil, @"The connection creates a column for numberProperty.");
        XCTAssertEqualObjects(columns[@"numberProperty"][@"type"], @"REAL", @"numberProperty should be a REAL.");
        
        XCTAssertNotEqualObjects(columns[@"dateProperty"], nil, @"The connection creates a column for dateProperty.");
        XCTAssertEqualObjects(columns[@"dateProperty"][@"type"], @"REAL", @"dateProperty should be a REAL.");
        
        
        NSArray *integerTypes = @[
                                  @"charProperty",
                                  @"shortProperty",
                                  @"intProperty",
                                  @"longProperty",
                                  @"longLongProperty",
                                  @"unsigned_charProperty",
                                  @"unsigned_shortProperty",
                                  @"unsigned_intProperty",
                                  @"unsigned_longProperty",
                                  @"unsigned_longLongProperty",
                                  @"integerProperty",
                                  ];
        for (NSString *property in integerTypes) {
            XCTAssertNotEqualObjects(columns[property], nil, @"The connection creates a column for %@.", property);
            XCTAssertEqualObjects(columns[property][@"type"], @"INTEGER", @"%@ should be a INTEGER.", property);
        }
        
        
        NSArray *floatTypes = @[
                                @"floatProperty",
                                @"doubleProperty",
                                @"timeIntervalProperty",
                                  ];
        for (NSString *property in floatTypes) {
            XCTAssertNotEqualObjects(columns[property], nil, @"The connection creates a column for %@.", property);
            XCTAssertEqualObjects(columns[property][@"type"], @"REAL", @"%@ should be a REAL.", property);
        }
    }];
}

@end
