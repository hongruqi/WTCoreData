//
//  WTViewController.m
//  WTCoreData
//
//  Created by lbrsilva-allin on 08/14/2017.
//  Copyright (c) 2017 lbrsilva-allin. All rights reserved.
//

#import "WTViewController.h"
#import "WTCoreDataObjectContext.h"
#import "WTUserInfo.h"

@interface WTViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation WTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
//    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
//    [self.view addSubview:self.tableView];
//    self.tableView.delegate = self;
//    self.tableView.dataSource = self;
    WTCoreDataObjectContext *context = [[WTCoreDataObjectContext alloc] initWithObjectClass:[WTUserInfo class] version:@"2.0.0"];
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < 100; i++) {
        WTUserInfo *userinfo = [[WTUserInfo alloc] init];
        userinfo.name = @"qihr";
        userinfo.contry = @"china";
        userinfo.age = i;
        userinfo.male = NO;
        userinfo.interest = @[@"1",@"2"];
        [context insertOrReplaceObject:userinfo];
    }
    
//    NSArray *arry = [context fetchAllObjects];
//    NSLog(@"%@", array);
//    [context insertOrReplaceObjects:array];

}

//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    return 5;
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"TableViewCell"];
//    if (cell) {
//
//    }
//    return
//}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
