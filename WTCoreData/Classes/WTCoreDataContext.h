//
//  WTCoreDataContext.h
//  WTCoreData
//
//  Created by walter on 14/08/2017.
//

#import <Foundation/Foundation.h>

@class WTCoreDataFMDB;
@class WTCoreDataObject;

@interface WTCoreDataContext : NSObject

@property(nonatomic, strong, readonly) WTCoreDataFMDB *coreDataFMDB;
@property(nonatomic, strong, readonly) WTCoreDataObject *objectModel;

- (instancetype)initWithObjectClass:(Class)objectClass version:(NSString*)version;

- (Class)objectClass;

- (NSString*)tableName;

#pragma mark - 表内接口

- (NSUInteger)countOfContext;

- (NSUInteger)countOfContextWithWhereSql:(NSString*)whereSql;

- (NSUInteger)countOfContextWithWhereSql:(NSString*)whereSql withArgumentsInArray:(NSArray *)arguments;

- (BOOL)insertOrReplaceObject:(id)object;

- (BOOL)insertOrReplaceObjects:(NSArray*)objectArray;

- (BOOL)deleteAllObject;

- (BOOL)deleteObjectWithWhereSql:(NSString*)whereSql;

- (BOOL)deleteObjectWithWhereSql:(NSString*)whereSql withArgumentsInArray:(NSArray *)arguments;

- (NSArray*)fetchAllObjects;

- (NSArray*)fetchWithWhereSql:(NSString*)whereSql;

- (NSArray*)fetchWithWhereSql:(NSString*)whereSql withArgumentsInArray:(NSArray *)arguments;

#pragma mark - 通用接口

- (BOOL)executeUpdate:(NSString*)sql withArgumentsInArray:(NSArray *)arguments;

- (NSArray*)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments;

#pragma mark - Transactions

- (BOOL)rollback;

- (BOOL)commit;

- (BOOL)beginDeferredTransaction;

- (BOOL)beginTransaction;

- (BOOL)inTransaction;
@end
