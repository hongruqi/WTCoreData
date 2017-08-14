//
//  WTUserInfo.h
//  WTCoreData_Example
//
//  Created by walter on 14/08/2017.
//  Copyright © 2017 lbrsilva-allin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WTCoreDataProtocol.h"

@interface WTUserInfo : NSObject <WTCoreDataProtocol>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *contry;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) BOOL male;
@property (nonatomic, strong) NSArray *interest;
@end
