//
//  SCXBaseViewController.m
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/7.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import "SCXBaseViewController.h"
#import "SCXDownloadSessionManager.h"
@interface SCXBaseViewController ()


@end

@implementation SCXBaseViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    
}
#pragma mark -------------- 懒加载 -----------------
-(NSMutableArray *)modelArr{
    
    if (!_modelArr ) {
        _modelArr = [NSMutableArray array];
    }
    return _modelArr;
}

/**
 获取进度信息
 */
- (SCXDownloadModel *)getProgressInfo:(NSString *)downloadUrl{
    _model = [[SCXDownloadDataManager sharemanager] SCX_GetDownloadModelWithUrlKey:downloadUrl];
    if (_model) {
        _model.exists = YES;
        return _model;
    }
    _model = [[SCXDownloadModel alloc]initWithUrlString:downloadUrl];
    SCXDownloadProgressModel *progressModel = [[SCXDownloadProgressModel shareProgressModel] SCX_GetProgressModelWithDownloadModel:_model];
    _model.progress = progressModel;
    return _model;
}
/**
 获取session进度信息
 */
- (SCXDownloadModel *)getSessionDownloadTaskProgressInfo:(NSString *)downloadUrl{
    _model = [[SCXDownloadDataManager sharemanager] SCX_GetDownloadModelWithUrlKey:downloadUrl];
    if (_model) {
        _model.exists = YES;
        return _model;
    }
    _model = [[SCXDownloadModel alloc]initWithUrlString:downloadUrl];
    if (!_model.sessionTask &&[[SCXDownloadSessionManager shareSessionManager] SCX_BackgroundDownloadSessionTaskWithModel:_model] ) {
        _model.exists = YES;
    }
    return _model;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}

@end
