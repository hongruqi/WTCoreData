//
//  WTViewController.m
//  WTCoreData
//
//  Created by lbrsilva-allin on 08/14/2017.
//  Copyright (c) 2017 lbrsilva-allin. All rights reserved.
//

#import "WTViewController.h"
#import "WTCoreDataContext.h"
#import "WTUserInfo.h"

@interface WTViewController ()

@property (nonatomic, strong) UIButton *insertDB;
@property (nonatomic, strong) UIButton *updateDB;
@property (nonatomic, strong) UIButton *getItemDB;


@end

@implementation WTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.insertDB = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 50)];
    [self.view addSubview:self.insertDB];
    [self.insertDB setTitle:@"insert" forState:UIControlStateNormal];
    [self.insertDB setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.insertDB addTarget:self action:@selector(insert) forControlEvents:UIControlEventTouchUpInside];
    
    self.updateDB = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 100, 50)];
    [self.view addSubview:self.updateDB];
    [self.updateDB setTitle:@"update" forState:UIControlStateNormal];
    [self.updateDB setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.updateDB addTarget:self action:@selector(update) forControlEvents:UIControlEventTouchUpInside];
    
    self.getItemDB = [[UIButton alloc] initWithFrame:CGRectMake(100, 300, 100, 50)];
    [self.view addSubview:self.getItemDB];
    [self.getItemDB setTitle:@"get" forState:UIControlStateNormal];
    [self.getItemDB setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.getItemDB addTarget:self action:@selector(get) forControlEvents:UIControlEventTouchUpInside];
}

- (void)insert
{
    WTCoreDataContext *context = [[WTCoreDataContext alloc] initWithObjectClass:[WTUserInfo class] version:@"2.0.0"];
    for (int i = 0; i < 100; i++) {
        WTUserInfo *userinfo = [[WTUserInfo alloc] init];
        userinfo.name = [NSString stringWithFormat:@"qihr%d", i];
        userinfo.contry = @"china";
        userinfo.age = i;
        userinfo.male = NO;
        userinfo.interest = @[@"1",@"2"];
        [context insertOrReplaceObject:userinfo];
    }
}

- (void)get
{
    WTCoreDataContext *context = [[WTCoreDataContext alloc] initWithObjectClass:[WTUserInfo class] version:@"2.0.0"];
    NSArray *array = [context fetchAllObjects];
    [array enumerateObjectsUsingBlock:^(WTUserInfo *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"obj %@", obj.interest);
    }];
    NSInteger count = [context countOfContext];
    NSLog(@"count = %ld", (long)count);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
