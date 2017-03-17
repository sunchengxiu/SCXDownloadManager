//
//  ViewController.m
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/7.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()



@end

@implementation ViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setUpButton];
}

- (void)setUpButton{
    UIButton *btn = ({
        UIButton *btn = [[UIButton alloc]init];
        [btn setTitle:@"通过文件流下载" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(downloadUseStream:) forControlEvents:UIControlEventTouchUpInside];
        btn;
    });
    [self.view addSubview:btn];
    
    UIButton *btn1 = ({
        UIButton *btn = [[UIButton alloc]init];
        [btn setTitle:@"通过session会话下载" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(downloadUseSession:) forControlEvents:UIControlEventTouchUpInside];
        btn;
    });
    [self.view addSubview:btn1];
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view).offset(200);
        make.centerX.mas_equalTo(self.view);
    }];
    [btn1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view).offset(400);
        make.centerX.mas_equalTo(self.view);
    }];
}
- (void)downloadUseSession:(UIButton *)btn{
    SCXSessionViewController *session = [[SCXSessionViewController alloc]init];
    
    [self.navigationController pushViewController:session animated:YES];
}
-(void)downloadUseStream:(UIButton *)btn{
    SCXDataViewController *stream = [[SCXDataViewController alloc]init];
    
    [self.navigationController pushViewController:stream animated:YES];

}

@end
