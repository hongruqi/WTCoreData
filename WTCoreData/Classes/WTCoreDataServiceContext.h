//
//  WTCoreDataServiceContext.h
//  WTCoreData
//
//  Created by walter on 14/08/2017.
//

#import <Foundation/Foundation.h>

@class FMDatabaseQueue;

@interface WTCoreDataServiceContext : NSObject

+ (instancetype)shareInstance;

- (FMDatabaseQueue*)databaseQueue;

- (BOOL)isNeedCreateTable:(NSString*)table;

- (BOOL)isNeedUpgradeForTable:(NSString*)table compareVersion:(NSString*)compareVersion;

- (BOOL)dropTable:(NSString*)table;

- (BOOL)updateTableToLastestVersion:(NSString*)version forTable:(NSString*)table;
@end
