//
//  WTCoreDataObject.h
//  WTCoreData
//
//  Created by walter on 14/08/2017.
//

#import <Foundation/Foundation.h>

@class WTCoreDataAssociateObject;
@class WTCoreDataColumnParis;

@interface WTCoreDataObject : NSObject

@property(nonatomic,strong,readonly)NSMutableArray *associateObjectArray;

- (instancetype)initWithObjectClass:(Class)objectClass;

- (NSString*)tableName;

- (NSDictionary*)tableColumnMap;

- (NSString*)createTableSqlString;

- (id)objectForTableInfo:(NSDictionary*)tableInfo;

- (NSString *)insertSqlForObject:(id)object paramsArray:(NSArray *__autoreleasing *)array;

- (NSString*)columnNameForAssociateObject:(WTCoreDataAssociateObject *)object;

@end


@interface WTCoreDataColumnParis : NSObject

@property(nonatomic,copy)NSString *columnName;
@property(nonatomic,copy)NSString *columnType;

@end


@interface WTCoreDataAssociateObject : NSObject

@property(nonatomic,strong)Class associateClass;
@property(nonatomic,strong)NSString *propertyName;

@end

