//
//  WTCoreDataObjectContext.m
//  WTCoreData
//
//  Created by walter on 14/08/2017.
//

#import "WTCoreDataContext.h"
#import "WTCoreDataFMDB.h"
#import "WTCoreDataObject.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"

@interface WTCoreDataContext()
{
    BOOL isCheckTable;
}

@property(nonatomic, strong) WTCoreDataObject *objectModel;
@property(nonatomic, strong) Class mappingObjectClass;
@property(nonatomic, copy) NSString *version;

@end

@implementation WTCoreDataContext

-(instancetype)initWithObjectClass:(Class)objectClass version:(NSString*)version
{
    return [self initWithFMDB:[WTCoreDataFMDB shareInstance] objectClass:objectClass version:version];
}

-(instancetype)initWithFMDB:(WTCoreDataFMDB *)coreDataFMDB objectClass:(Class)objectClass version:(NSString*)version
{
    self = [super init];
    if(self){
        self.mappingObjectClass = objectClass;
        _coreDataFMDB = coreDataFMDB;
        self.objectModel = [[WTCoreDataObject alloc] initWithObjectClass:[self objectClass]];
        self.version = version;
    }
    return self;
}

-(void)checkTableCreateAndUpgrade
{
    if(!isCheckTable){
        isCheckTable = YES;
        isCheckTable = [self createAndUpgradeTable];
    }
}

-(BOOL)createAndUpgradeTable
{
    NSString *tableName = [self tableName];
    BOOL result = YES;
    if([self.coreDataFMDB isNeedCreateTable:tableName]){
        NSString *createTableSql = [self.objectModel createTableSqlString];
        result = [self executeUpdate:createTableSql withArgumentsInArray:nil];
    }
    if(!result){
        return NO;
    }
    BOOL isNeedUpgrade = [self.coreDataFMDB isNeedUpgradeForTable:tableName compareVersion:self.version];
    if(isNeedUpgrade){
        [self doUpgradeTable];
    }
    return [self.coreDataFMDB updateTableToLastestVersion:self.version forTable:tableName];
}

- (NSDictionary *)databaseTableColumnInfo
{
    NSString *tableName = [self tableName];
    NSMutableDictionary *columnDic = [NSMutableDictionary dictionary];
    NSArray *resultArray = [self executeQuery:[NSString stringWithFormat:@"pragma table_info(%@)", tableName] withArgumentsInArray:nil];
    for(NSDictionary *columnParis in resultArray){
        WTCoreDataColumnParis *pairs = [[WTCoreDataColumnParis alloc] init];
        pairs.columnName = [columnParis objectForKey:@"name"];
        pairs.columnType = [columnParis objectForKey:@"type"];
        if([pairs.columnName length] > 0 && [pairs.columnType length] > 0){
            [columnDic setObject:pairs forKey:pairs.columnName];
        }
    }
    
    return columnDic;
}

- (void)doUpgradeTable
{
    NSMutableArray *result = [NSMutableArray array];
    NSString *tableName = [self tableName];
    NSDictionary *newPairs = [self.objectModel tableColumnMap];
    NSDictionary *tableParis = [self databaseTableColumnInfo];
    NSMutableArray *deleteColumns = [NSMutableArray arrayWithArray:[tableParis allKeys]];
    NSMutableString *selectSql = [NSMutableString stringWithFormat:@"SELECT "];
    BOOL hasAddColumns = NO;
    for (NSInteger i = 0 ; i < [[newPairs allKeys] count] ; i++) {
        WTCoreDataColumnParis *pair = [newPairs objectForKey:[[newPairs allKeys] objectAtIndex:i]];
        NSString *colmunName = [pair columnName];
        BOOL isFind = NO;
        NSArray *allTablePariKeys = [tableParis allKeys];
        for(NSString *tablePairKey in allTablePariKeys){
            WTCoreDataColumnParis *tablePair = [tableParis objectForKey:tablePairKey];
            if([[tablePair columnName] isEqualToString:colmunName]){
                isFind = YES;
                break;
            }
        }
        if(!isFind) {
            hasAddColumns = YES;
            NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@",tableName,colmunName,[pair columnType]];
            [result addObject:sql];
        }
        else{
            [deleteColumns removeObject:colmunName];
        }
        if(i == 0 ){
            [selectSql appendFormat:@"%@",colmunName];
        }else{
            [selectSql appendFormat:@",%@",colmunName];
        }
    }
    if ( [deleteColumns count] > 0 ) {
        if ( hasAddColumns ) {
            for(NSString *sql in result ) {
                [self executeUpdate:sql withArgumentsInArray:nil];
            }
        }
        //改名为临时表
        NSString *tmpTableName = @"TMP";
        NSString *renameSql = [NSString stringWithFormat:@"ALTER TABLE %@ RENAME TO %@",tableName,tmpTableName];
        [self executeUpdate:renameSql withArgumentsInArray:nil];
        //创建新表
        [self executeUpdate:[self.objectModel createTableSqlString] withArgumentsInArray:nil];
        //拷贝数据
        NSString *copyDataSql = [NSString stringWithFormat:@"INSERT INTO %@ %@ FROM %@",tableName,selectSql,tmpTableName];
        [self executeUpdate:copyDataSql withArgumentsInArray:nil];
        //删除临时表
        [self executeUpdate:[NSString stringWithFormat:@"DROP TABLE %@",tmpTableName] withArgumentsInArray:nil];
        result = nil;
    }
    if(result.count > 0 ){
        for(NSString *sql in result ) {
            [self executeUpdate:sql withArgumentsInArray:nil];
        }
    }
}

-(Class)objectClass
{
    return self.mappingObjectClass;
}

-(NSString *)tableName
{
    return [self.objectModel tableName];
}

-(NSUInteger)countOfContext
{
    return [self countOfContextWithWhereSql:@"" withArgumentsInArray:nil];
}

-(NSUInteger)countOfContextWithWhereSql:(NSString *)whereSql
{
    return [self countOfContextWithWhereSql:whereSql withArgumentsInArray:nil];
}

-(NSUInteger)countOfContextWithWhereSql:(NSString *)whereSql withArgumentsInArray:(NSArray *)arguments
{
    [self checkTableCreateAndUpgrade];
    __block NSUInteger count = 0;
    [self.coreDataFMDB.databaseQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT COUNT(*) FROM %@",[self tableName]];
        if([whereSql length] > 0){
            [sql appendFormat:@" WHERE %@",whereSql];
        }
        FMResultSet *resultSet = [db executeQuery:sql withArgumentsInArray:arguments];
        if([resultSet next]){
            count = [resultSet intForColumnIndex:0];
        }
        [resultSet close];
    }];
    return count;
}

-(BOOL)insertOrReplaceObject:(id)object
{
    [self checkTableCreateAndUpgrade];
    BOOL result = YES;
    NSArray *paramArray = nil;
    NSString *insertSql = [self.objectModel insertSqlForObject:object paramsArray:&paramArray];
    if([insertSql length] > 0){
        result = [self executeUpdate:insertSql withArgumentsInArray:paramArray];
    }
    if([self.objectModel associateObjectArray].count > 0){
        for(WTCoreDataAssociateObject *associateObject in self.objectModel.associateObjectArray){
            WTCoreDataContext *context = [[WTCoreDataContext alloc] initWithObjectClass:associateObject.associateClass version:self.version];
            id value = nil;
            if([object respondsToSelector:NSSelectorFromString(associateObject.propertyName)]){
                value = [object valueForKey:associateObject.propertyName];
            }
            result = result && [context insertOrReplaceObject:value];
        }
    }
    return result;
}

-(BOOL)insertOrReplaceObjects:(NSArray *)objectArray
{
    [self checkTableCreateAndUpgrade];
    __block BOOL result = YES;
    [self.coreDataFMDB.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for(id object in objectArray){
            NSArray *paramArray = nil;
            NSString *insertSql = [self.objectModel insertSqlForObject:object paramsArray:&paramArray];
            if([insertSql length] > 0){
                result = result && [db executeUpdate:insertSql withArgumentsInArray:paramArray];
            }
            if([self.objectModel associateObjectArray].count > 0){
                for(WTCoreDataAssociateObject *associateObject in self.objectModel.associateObjectArray){
                    WTCoreDataContext *context = [[WTCoreDataContext alloc] initWithObjectClass:associateObject.associateClass version:self.version];
                    id value = nil;
                    if([object respondsToSelector:NSSelectorFromString(associateObject.propertyName)]){
                        value = [object valueForKey:associateObject.propertyName];
                    }
                    result = result && [context insertOrReplaceObject:value];
                }
            }
        }
    }];
    return result;
}

-(BOOL)deleteAllObject
{
    return [self deleteObjectWithWhereSql:nil withArgumentsInArray:nil];
}

-(BOOL)deleteObjectWithWhereSql:(NSString *)whereSql
{
    return [self deleteObjectWithWhereSql:whereSql withArgumentsInArray:nil];
}

-(BOOL)deleteObjectWithWhereSql:(NSString *)whereSql withArgumentsInArray:(NSArray *)arguments
{
    [self checkTableCreateAndUpgrade];
    __block BOOL result = YES;
    [self.coreDataFMDB.databaseQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *deleteSql = [NSMutableString stringWithFormat:@"DELETE FROM %@",[self tableName]];
        if([whereSql length] > 0){
            [deleteSql appendFormat:@" WHERE %@",whereSql];
        }
        result = [db executeUpdate:deleteSql withArgumentsInArray:arguments];
    }];
    return result;
}

-(NSArray*)fetchAllObjects
{
    return [self fetchWithWhereSql:@"" withArgumentsInArray:nil];
}

-(NSArray *)fetchWithWhereSql:(NSString *)whereSql
{
    return [self fetchWithWhereSql:whereSql withArgumentsInArray:nil];
}

-(NSArray*)fetchWithWhereSql:(NSString*)whereSql withArgumentsInArray:(NSArray *)arguments
{
    if(whereSql == nil){
        whereSql = @"";
    }
    [self checkTableCreateAndUpgrade];
    NSMutableArray *resultArray = [NSMutableArray array];
    [self.coreDataFMDB.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = nil;
        if([self.objectModel associateObjectArray].count > 0){
            NSMutableString *associateSql = [NSMutableString stringWithFormat:@"SELECT * FROM %@",[self tableName]];
            for(WTCoreDataAssociateObject *associateObject in [self.objectModel associateObjectArray]){
                WTCoreDataContext *context = [[WTCoreDataContext alloc] initWithObjectClass:associateObject.associateClass version:self.version];
                NSString *associateColumnName = [self.objectModel columnNameForAssociateObject:associateObject];
                [associateSql appendFormat:@" LEFT JOIN %@ ON %@.%@ = %@.%@ ",[context.objectModel tableName],[self tableName],associateColumnName,[context.objectModel tableName],associateColumnName];
            }
            sql = associateSql;
        }else {
            sql = [NSString stringWithFormat:@"SELECT * FROM %@",[self tableName]];
        }
        if([whereSql length] > 0){
            sql = [NSString stringWithFormat:@"%@ WHERE %@",sql, whereSql];
        }
        FMResultSet *set = [db executeQuery:sql withArgumentsInArray:arguments];
        while([set next]){
            id object = [self.objectModel objectForTableInfo:[set resultDictionary]];
            if(object){
                [resultArray addObject:object];
            }
        }
        [set close];
    }];
    return resultArray;
}

-(BOOL)executeUpdate:(NSString*)sql withArgumentsInArray:(NSArray *)arguments
{
    [self checkTableCreateAndUpgrade];
    __block BOOL result = NO;
    [self.coreDataFMDB.databaseQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql withArgumentsInArray:arguments];
    }];
    return result;
}

-(NSArray *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments
{
    [self checkTableCreateAndUpgrade];
    NSMutableArray *resultArray = [NSMutableArray array];
    [self.coreDataFMDB.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:sql withArgumentsInArray:arguments];
        while([set next]){
            [resultArray addObject:[set resultDictionary]];
        }
        [set close];
    }];
    return resultArray;
}

#pragma mark -
#pragma mark - Transactions

- (BOOL)rollback
{
    [self checkTableCreateAndUpgrade];
    __block BOOL result = NO;
    [self.coreDataFMDB.databaseQueue inDatabase:^(FMDatabase *db) {
        result = [db rollback];
    }];
    return result;
}

- (BOOL)commit
{
    [self checkTableCreateAndUpgrade];
    __block BOOL result = NO;
    [self.coreDataFMDB.databaseQueue inDatabase:^(FMDatabase *db) {
        result = [db commit];
    }];
    return result;
}

- (BOOL)beginDeferredTransaction
{
    [self checkTableCreateAndUpgrade];
    __block BOOL result = NO;
    [self.coreDataFMDB.databaseQueue inDatabase:^(FMDatabase *db) {
        result = [db beginDeferredTransaction];
    }];
    return result;
}

- (BOOL)beginTransaction
{
    [self checkTableCreateAndUpgrade];
    __block BOOL result = NO;
    [self.coreDataFMDB.databaseQueue inDatabase:^(FMDatabase *db) {
        result = [db beginTransaction];
    }];
    return result;
}

- (BOOL)inTransaction
{
    [self checkTableCreateAndUpgrade];
    __block BOOL result = NO;
    [self.coreDataFMDB.databaseQueue inDatabase:^(FMDatabase *db) {
        result = [db isInTransaction];
    }];
    return result;
}
@end
