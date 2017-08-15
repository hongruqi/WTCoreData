//
//  WTCoreDataFMDB.h
//  WTCoreData
//
//  Created by walter on 14/08/2017.
//

#import <Foundation/Foundation.h>

@class FMDatabaseQueue;

@interface WTCoreDataFMDB : NSObject

+ (instancetype)shareInstance;

- (FMDatabaseQueue*)databaseQueue;

- (BOOL)isNeedCreateTable:(NSString*)table;

- (BOOL)isNeedUpgradeForTable:(NSString*)isNeedUpgradeForTable compareVersion:(NSString*)compareVersion;

- (BOOL)dropTable:(NSString*)dropTable;

- (BOOL)updateTableToLastestVersion:(NSString*)version forTable:(NSString*)table;
@end
