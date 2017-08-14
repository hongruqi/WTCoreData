//
//  WTCoreDataModel.m
//  WTCoreData
//
//  Created by walter on 14/08/2017.
//

#import "WTCoreDataModel.h"
#import <objc/runtime.h>
#import "WTCoreDataProtocol.h"

@interface WTCoreDataModel()
{
    Class _objectClass;
}

@property (nonatomic, strong) NSMutableArray *associateObjectArray;
@property (nonatomic, strong) NSMutableDictionary *columnParisMap;

@end

@implementation WTCoreDataModel

- (instancetype)initWithObjectClass:(Class)objectClass
{
    if (self = [super init]) {
        _objectClass = objectClass;
        _associateObjectArray = [NSMutableArray array];
    }
    
    return self;
}

#pragma mark - API

- (NSString *)tableName
{
    NSString *objectName = [NSString stringWithCString:class_getName(_objectClass) encoding:NSUTF8StringEncoding];
    NSMutableString *tableName = [[NSMutableString alloc] init];
    for(NSInteger i = 0 ; i< objectName.length; i++){
        NSString *oneString = [objectName substringWithRange:NSMakeRange(i, 1)];
        if(![oneString isEqualToString:[oneString lowercaseString]] && i > 0){
            [tableName appendFormat:@"_%@",[oneString uppercaseString]];
        }else {
            [tableName appendString:[oneString uppercaseString]];
        }
    }

    return tableName;
}

- (NSDictionary *)tableColumnMap
{
    if (!self.columnParisMap) {
        self.columnParisMap = [NSMutableDictionary dictionary];
        Class currentClass = _objectClass;
        BOOL isCoverSuper;
        do {
            unsigned int propertyCount = 0;
            objc_property_t *properties = class_copyPropertyList(currentClass, &propertyCount);
            for (NSInteger i = 0; i < propertyCount; i++){
                objc_property_t property = properties[i];
                NSString *columnName = [self propertyName:property];
                if([_objectClass respondsToSelector:@selector(isIgnoreProperty:)]){
                    if([_objectClass isIgnoreProperty:columnName]){
                        continue;
                    }
                }
                
                NSString *properType = [self propertyType:property];
                NSString *columnType = [self columnTypeForPropertyType:properType];
                if ([_objectClass respondsToSelector:@selector(isAssociateProperty:)]) {
                    if([_objectClass isAssociateProperty:columnName] && [properType length] > 3){
                        NSString *className = [properType substringWithRange:NSMakeRange(2, [properType length] - 3)];
                        Class associateClass = NSClassFromString(className);
                        if(associateClass){
                            WTCoreDataAssociateObject *associateObject = [[WTCoreDataAssociateObject alloc] init];
                            associateObject.associateClass = associateClass;
                            associateObject.propertyName = columnName;
                            [self.associateObjectArray addObject:associateObject];
                        }
                    }
                }else{
                    if([columnName length] > 0 && [columnType length] > 0){
                        WTCoreDataColumnParis *pairs = [[WTCoreDataColumnParis alloc] init];
                        pairs.columnName = columnName;
                        pairs.columnType = columnType;
                        [self.columnParisMap setObject:pairs forKey:pairs.columnName];
                    }
                }
//
//                if([_objectClass isAssociateProperty:columnName] && [properType length] > 3){
//                    NSString *className = [properType substringWithRange:NSMakeRange(2, [properType length] - 3)];
//                    Class associateClass = NSClassFromString(className);
//                    if(associateClass && [associateClass isSubclassOfClass:[WTCoreDataObject class]]){
//                        WTCoreDataAssociateObject *associateObject = [[WTCoreDataAssociateObject alloc] init];
//                        associateObject.associateClass = associateClass;
//                        associateObject.propertyName = columnName;
//                        [self.associateObjectArray addObject:associateObject];
//                    }
//                }else {
//                    if([columnName length] > 0 && [columnType length] > 0){
//                        WTCoreDataColumnParis *pairs = [[WTCoreDataColumnParis alloc] init];
//                        pairs.columnName = columnName;
//                        pairs.columnType = columnType;
//                        [self.columnParisMap setObject:pairs forKey:pairs.columnName];
//                    }
//                }
            }
            
            free(properties);
            currentClass = [currentClass superclass];
            if([currentClass respondsToSelector:@selector(isCoverSuper)]){
                isCoverSuper = [currentClass isCoverSuper];
            }
            
        } while (currentClass != [NSObject class] && isCoverSuper);
    }
    
    return self.columnParisMap;
}

- (NSString *)createTableSqlString
{
    NSMutableString *tableString = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (", [self tableName]];
    NSArray *columnArray = [[self tableColumnMap] allKeys];
    for(NSInteger i = 0; i < [columnArray count]; i++){
        WTCoreDataColumnParis *columnPairs = [[self tableColumnMap] objectForKey:[columnArray objectAtIndex:i]];
        [tableString appendFormat:@" %@ %@ ",columnPairs.columnName,columnPairs.columnType];
        NSString *propertyDescrption;
        
        if ([_objectClass respondsToSelector:@selector(columnDescrptionForProperty:)]) {
            propertyDescrption  = [_objectClass columnDescrptionForProperty:columnPairs.columnName];
        }
        
        if([propertyDescrption length] > 0){
            [tableString appendFormat:@" %@ ",propertyDescrption];
        }
        
        if(i != [columnArray count] - 1){
            [tableString appendString:@","];
        }
    }
    //primary key
    NSString *primaryKey;
    if ([_objectClass respondsToSelector:@selector(primaryKey)]) {
        primaryKey = [_objectClass primaryKey];
    }
    
    if([primaryKey length] > 0){
        [tableString appendFormat:@", PRIMARY KEY (%@)",primaryKey];
    }
    
    [tableString appendString:@")"];
    return tableString;
}

- (id)objectForTableInfo:(NSDictionary *)tableInfo
{
    id object = [[_objectClass alloc] init];
    NSMutableArray *propertyObjectInitArray = [NSMutableArray array];
    NSMutableArray *propertyObjectArray = [NSMutableArray array];
    for(WTCoreDataAssociateObject *associateObject in self.associateObjectArray){
        id mapObject = [[associateObject.associateClass alloc] init];
        [propertyObjectArray addObject:mapObject];
    }
    for(NSString *key in [tableInfo allKeys]){
        if(![[tableInfo valueForKey:key] isKindOfClass:[NSNull class]]){
            id value = [tableInfo valueForKey:key];
            if([[self columnTypeForColumnName:key] isEqualToString:@"BLOB"]){
                NSException *exception = nil;
                value = [self safeUnarchiveObject:value exception:&exception];
                NSAssert(exception == nil, [exception description]);
            }
            if(value != nil){
                if([object respondsToSelector:NSSelectorFromString(key)]){
                    [object setValue:value forKey:key];
                }
                for(id mapObject in propertyObjectArray){
                    if([mapObject respondsToSelector:NSSelectorFromString(key)]){
                        [mapObject setValue:value forKey:key];
                        if(![propertyObjectInitArray containsObject:mapObject]){
                            [propertyObjectInitArray addObject:mapObject];
                        }
                    }
                }
            }
        }
    }
    for(NSInteger i = 0; i < propertyObjectArray.count; i++){
        WTCoreDataAssociateObject *associateObject = [self.associateObjectArray objectAtIndex:i];
        NSString *propertyName = associateObject.propertyName;
        id mapObject = [propertyObjectArray objectAtIndex:i];
        if([propertyObjectInitArray containsObject:mapObject]){
            [object setValue:mapObject forKey:propertyName];
        }
    }
    return object;
    
}

- (NSString *)insertSqlForObject:(id)object paramsArray:(NSArray *__autoreleasing *)array
{
    if(![object isKindOfClass:_objectClass] && ![_objectClass isSubclassOfClass:[object class]]){
        return nil;
    }
    NSMutableArray *paramArray = [NSMutableArray array];
    NSMutableString *insertString = [[NSMutableString alloc] initWithFormat:@"INSERT OR REPLACE INTO %@(",[self tableName]];
    NSArray *columnArray = [[self tableColumnMap] allKeys];
    NSInteger count = [columnArray count];
    for(NSInteger i = 0; i < count; i++){
        WTCoreDataColumnParis *columnPairs = [[self tableColumnMap] objectForKey:[columnArray objectAtIndex:i]];
        [insertString appendString:columnPairs.columnName];
        if(i != count - 1){
            [insertString appendString:@","];
        }
        id value = nil;
        if([object respondsToSelector:NSSelectorFromString(columnPairs.columnName)]){
            value = [object valueForKey:columnPairs.columnName];
        }
        if([columnPairs.columnType isEqualToString:@"BLOB"]){
            NSException *exception = nil;
            value = [self safeArchiveObject:value exception:&exception];
            NSAssert(exception == nil, [exception description]);
        }
        if(value == nil){
            value = [NSNull null];
        }
        [paramArray addObject:value];
    }
    [insertString appendString:@") values("];
    for(NSInteger i = 0; i < count; i++){
        [insertString appendString:@"?"];
        if(i != count - 1){
            [insertString appendString:@","];
        }
    }
    [insertString appendString:@")"];
    *array = [paramArray copy];
    return insertString;
    
}
- (NSData*)safeArchiveObject:(id)object exception:(NSException *__autoreleasing *)caughtException
{
    if(object == nil){
        return nil;
    }
    NSData *data = nil;
    @try {
        data = [NSKeyedArchiver archivedDataWithRootObject:object];
    }
    @catch (NSException *exception) {
        data = nil;
        *caughtException = exception;
    }
    @finally {}
    return data;
}

- (id)safeUnarchiveObject:(NSData*)data exception:(NSException *__autoreleasing *)caughtException
{
    if(data == nil){
        return nil;
    }
    id object = nil;
    @try {
        object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    @catch (NSException *exception) {
        object = nil;
        *caughtException = exception;
    }
    @finally {}
    return object;
}

- (NSMutableArray *)associateObjectArray
{
    if(_associateObjectArray.count == 0){
        [self tableColumnMap];
    }
    
    return _associateObjectArray;
}

-(NSArray*)propertyNameArrayForClass:(Class)objectClass
{
    Class findClass = objectClass;
    NSMutableArray *propertyArray = [NSMutableArray array];
    do {
        unsigned int propertyCount = 0;
        objc_property_t *properties = class_copyPropertyList(findClass, &propertyCount);
        for (NSInteger i = 0; i < propertyCount; i++){
            objc_property_t property = properties[i];
            NSString *propertyName = [self propertyName:property];
            if(propertyName)
                [propertyArray addObject:propertyName];
        }
        free(properties);
        findClass = [findClass superclass];
    } while (findClass != [NSObject class]);
    return propertyArray;
}

-(NSString*)columnNameForAssociateObject:(WTCoreDataAssociateObject*)object
{
    NSArray *propertyArray1 = [self propertyNameArrayForClass:object.associateClass];
    NSArray *propertyArray2 = [self propertyNameArrayForClass:_objectClass];
    for (NSString *propertyName1 in propertyArray1){
        for(NSString *propertyName2 in propertyArray2){
            if([propertyName1 isEqualToString:propertyName2]){
                return propertyName1;
            }
        }
    }
    return @"";
}

-(NSString*)columnTypeForColumnName:(NSString*)columnName
{
    WTCoreDataColumnParis *paris = [[self tableColumnMap] objectForKey:columnName];
    return paris.columnType;
}

-(NSString*)propertyName:(objc_property_t)property
{
    const char* char_p_name = property_getName(property);
    NSString *propertyName = [NSString stringWithUTF8String:char_p_name];
    return propertyName;
}

-(NSString*)propertyType:(objc_property_t)property
{
    const char* char_p_attributes = property_getAttributes(property);
    NSString *attributesString = [NSString stringWithUTF8String:char_p_attributes];
    NSArray *attributtesArray = [attributesString componentsSeparatedByString:@","];
    if(attributtesArray.count > 0){
        return [[attributtesArray firstObject] substringFromIndex:1];
    }
    return nil;
}

-(NSString*)columnTypeForPropertyType:(NSString*)propertyType
{
    if ([propertyType isEqualToString:@"i"] || // int
        [propertyType isEqualToString:@"I"] || // unsigned int
        [propertyType isEqualToString:@"l"] || // long
        [propertyType isEqualToString:@"L"] || // usigned long
        [propertyType isEqualToString:@"q"] || // long long
        [propertyType isEqualToString:@"Q"] || // unsigned long long
        [propertyType isEqualToString:@"s"] || // short
        [propertyType isEqualToString:@"S"] || // unsigned short
        [propertyType isEqualToString:@"B"] || // bool or BOOL
        [propertyType isEqualToString:@"c"] || // char
        [propertyType isEqualToString:@"C"])   // unsigned char
    {
        return @"INTEGER";
    }
    else if ([propertyType isEqualToString:@"f"] || // float
             [propertyType isEqualToString:@"d"])  // double
    {
        return @"REAL";
    }
    else if([propertyType isEqualToString:@"@"])//id
    {
        return @"BLOB";
    }
    else if ([propertyType hasPrefix:@"@"] && propertyType.length > 3) // object
    {
        NSString *className = [propertyType substringWithRange:NSMakeRange(2, [propertyType length] - 3)];
        if ([className isEqualToString:@"NSNumber"])
            return @"REAL";
        
        if ([className isEqualToString:@"NSString"])
            return @"TEXT";
        
        //其他都用块,必须支持encode和decode
        return @"BLOB";
    }
    return nil;
}

@end

@implementation WTCoreDataColumnParis
@end

@implementation WTCoreDataAssociateObject
@end

