//
//  WTCoreDataFMDB.m
//  WTCoreData
//
//  Created by walter on 14/08/2017.
//

#import "WTCoreDataFMDB.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"

#define WT_COREDATA_DATABASE_NAME     @"wtcoredata.db"
#define WT_COREDATA_FOLDER_PATH       @"wtcoredata"

@interface WTCoreDataFMDB()

@property(nonatomic,strong)FMDatabaseQueue *dbQueue;

@end

@implementation WTCoreDataFMDB

+ (instancetype)shareInstance
{
    static WTCoreDataFMDB *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WTCoreDataFMDB alloc] init];
    });
    return instance;
}

-(instancetype)init
{
    self = [super init];
    if(self){
        _dbQueue = [[FMDatabaseQueue alloc] initWithPath:[WTCoreDataFMDB databasePath]];
        [self createTableInfo];
    }
    return self;
}


-(void)createTableInfo
{
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS WT_TABLE_INFO (WT_TABLE_NAME TEXT PRIMARY KEY, VERSION TEXT)"];
    }];
}

-(FMDatabaseQueue*)databaseQueue
{
    return self.dbQueue;
}

-(BOOL)isNeedCreateTable:(NSString *)table
{
    if([table length] == 0){
        return NO;
    }
    __block BOOL result = YES;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:@"SELECT WT_TABLE_NAME FROM WT_TABLE_INFO WHERE WT_TABLE_NAME = ?" withArgumentsInArray:@[table]];
        if([set next]){
            result = NO;
        }
        [set close];
    }];
    return result;
}

-(BOOL)isNeedUpgradeForTable:(NSString *)table compareVersion:(NSString *)compareVersion
{
    if([table length] == 0){
        return NO;
    }
    __block BOOL result = YES;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:@"SELECT VERSION FROM WT_TABLE_INFO WHERE WT_TABLE_NAME = ?" withArgumentsInArray:@[table]];
        if([set next]){
            NSString *version = [[set resultDictionary] objectForKey:@"VERSION"];
            if([version isEqualToString:compareVersion]){
                result =  NO;
            }
        }
        [set close];
    }];
    return result;
}

-(BOOL)dropTable:(NSString*)table
{
    if([table length] == 0){
        return NO;
    }
    __block BOOL result = YES;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:@"DROP TABLE %@",table];
        result = result && [db executeUpdate:@"DELETE FROM WT_TABLE_INFO WHERE WT_TABLE_NAME = ?",table];
    }];
    return result;
}

-(BOOL)updateTableToLastestVersion:(NSString *)version forTable:(NSString *)table
{
    if([table length] == 0 || [version length] == 0){
        return NO;
    }
    __block BOOL result = NO;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:@"INSERT OR REPLACE INTO WT_TABLE_INFO (WT_TABLE_NAME, VERSION) VALUES(?,?)" withArgumentsInArray:@[table,version]];
    }];
    return result;
}


+ (NSString *)databasePath {
    NSString *folderPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:WT_COREDATA_FOLDER_PATH];
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    NSString *dbPath = [folderPath stringByAppendingPathComponent:WT_COREDATA_DATABASE_NAME];
    return dbPath;
}

@end
