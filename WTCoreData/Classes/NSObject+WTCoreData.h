//
//  NSObject+WTCoreData.h
//  WTCoreData
//
//  Created by walter on 15/08/2017.
//

#import <Foundation/Foundation.h>

@interface NSObject (WTCoreData)

@end

@protocol WTCoreDataProtocol <NSObject>

//主键，支持联合主键，如key1,key2
+(NSString*)primaryKey;

//列描述，如NOT NULL, DEFAULT等
+(NSString*)columnDescrptionForProperty:(NSString*)property;

//是否忽略该属性，如果忽略，就不设为表的一列
+(BOOL)isIgnoreProperty:(NSString*)property;

//是否关联表
+(BOOL)isAssociateProperty:(NSString*)property;

//是否需要包括基类的属性
+(BOOL)isCoverSuper;

@end
