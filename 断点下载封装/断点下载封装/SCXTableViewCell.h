//
//  SCXTableViewCell.h
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/8.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SCXCalculateTool.h"
//#import "SCXDownloadProgressModel.h"
#import "SCXDownloadModel.h"
#import "SCXDownloadDataManager.h"
#import "SCXHandleManager.h"
#import "SCXBaseViewController.h"
@protocol SCXCellDelegate;
@protocol SCXSessionCellDelegate;
@interface SCXTableViewCell : UITableViewCell<SCXDownloadDataDelegate>
/*************  文件信息label ***************/
@property ( nonatomic , strong )UILabel *fileInfoLabel;

/*************  下载速度label ***************/
@property ( nonatomic , strong )UILabel *spreedlabel;

/*************  剩余时间label ***************/
@property ( nonatomic , strong )UILabel *remainLabel;

/*************  流下载button ***************/
@property ( nonatomic , strong )UIButton *streamButton;

/*************  progressView ***************/
@property ( nonatomic , strong )UIProgressView *progressView;

/*************  进度模型 ***************/
@property ( nonatomic , strong )SCXDownloadModel *model;

/*************  代理 ***************/
@property ( nonatomic , weak )id <SCXCellDelegate> delegate;

/*************  sessionCell代理 ***************/
@property ( nonatomic , weak )id <SCXSessionCellDelegate> sessionCellDelegate;


@end
@protocol SCXCellDelegate <NSObject>
/**
 更新cell进度
 
 @param cell 已存在的cell，通过这个cell中的model，得到最新对应的cell
 @param progress 进度模型
 */
- (void)updateCell:(SCXTableViewCell *)cell progress:(SCXDownloadProgressModel *)progress;


@end
@protocol SCXSessionCellDelegate <NSObject>

/**
 更新sessionCell进度
 
 @param cell 已存在的cell，通过这个cell中的model，得到最新对应的cell
 @param progress 进度模型
 */
- (void)updateSessionCell:(SCXTableViewCell *)cell progress:(SCXDownloadProgressModel *)progress;

@end
