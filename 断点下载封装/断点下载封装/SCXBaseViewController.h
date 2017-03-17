//
//  SCXBaseViewController.h
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/7.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SCXDownloadProgressModel.h"
#import "SCXDownloadModel.h"
#import "SCXCalculateTool.h"
#import "SCXTableViewCell.h"
@interface SCXBaseViewController : UITableViewController


/*************  url数组 ***************/
@property ( nonatomic , strong )NSArray *urlArr;

/*************  model数组 ***************/
@property ( nonatomic , strong )NSMutableArray *modelArr;

/*************  downloadModel ***************/
@property ( nonatomic , strong )SCXDownloadModel *model;

/**
 获取进度信息
 */
- (SCXDownloadModel *)getProgressInfo:(NSString *)downloadUrl;
/**
 获取session进度信息
 */
- (SCXDownloadModel *)getSessionDownloadTaskProgressInfo:(NSString *)downloadUrl;
@end
