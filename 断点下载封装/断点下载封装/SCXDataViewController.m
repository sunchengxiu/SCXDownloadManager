//
//  SCXDataViewController.m
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/7.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import "SCXDataViewController.h"
#import "SCXDownloadDataManager.h"
#import "SCXDownloadModel.h"
static NSString * const downloadUrl = @"http://baobab.wdjcdn.com/1456117847747a_x264.mp4";
static NSString * const downloadUrl1 = @"http://baobab.wdjcdn.com/14525705791193.mp4";
static NSString * const downloadUrl2 = @"http://baobab.wdjcdn.com/1456459181808howtoloseweight_x264.mp4";

@interface SCXDataViewController ()




@end

@implementation SCXDataViewController
shareInstanceM(DataController);
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];

    self.urlArr = @[downloadUrl , downloadUrl1 , downloadUrl2];
    for (NSString *url in self.urlArr) {
        SCXDownloadModel *model = [self getProgressInfo:url];
        [self.modelArr addObject:model];
    }

}

#pragma mark -------------- tableViewDelegate -----------------
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
   
    SCXTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[SCXTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    [cell setModel:self.modelArr[indexPath.row]];
    cell.delegate = self;
    return cell;
    
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    //动态获取cell的高度，进行设置
    SCXTableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    [cell layoutIfNeeded];
    return CGRectGetMaxY(cell.streamButton.frame) ;
}

#pragma mark -------------- cellDelegate -----------------

/**
 更新cell 的时候只能写在这里，虽然写在cell里面的时候更简单，但是如果关闭了这个界面，再次打开的时候，cell上的就不会改变，不会刷新，所以通过此方法实时找到对应的那个cell

 @param cell 旧cell
 @param progress 进度
 */
-(void)updateCell:(SCXTableViewCell *)cell progress:(SCXDownloadProgressModel *)progress{
    NSInteger index = [self.modelArr indexOfObject:cell.model];
    
    SCXTableViewCell *cell1 = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    BOOL reload = NO;
    if ([cell1.fileInfoLabel.text isEqualToString:@""]) {
        reload = YES;
    }
    cell1.fileInfoLabel.text = [[SCXHandleManager shareHandleManager] detailTextForDownloadProgress:progress];
    NSLog(@"%f",progress.progress);
    cell1.progressView.progress = progress.progress;
   // 当第一次进入的时候，肯定没有详细信息，只有一个开始按钮，那么有进度的时候，高度就和之间不一样，所以刷线一次高度就行,cell的高度动态布局了.
    if (reload) {
        [self.tableView reloadData];
       
    }
    
    
}

@end
