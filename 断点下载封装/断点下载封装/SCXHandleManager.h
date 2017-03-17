//
//  SCXHandleManager.h
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/8.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCXDownloadModel.h"
#import "SCXCalculateTool.h"
#import "SCXDownloadDataManager.h"
@interface SCXHandleManager : NSObject

/*************  单利 ***************/
shareInstanceH(HandleManager);

/**
 将字节大小 转化为文字
 
 @param progress progressModel
 @return 字节字符串
 */
- (NSString *)detailTextForDownloadProgress:(SCXDownloadProgressModel *)progress;

/**
 将状态对应相应的状态文字
 
 @param state 状态
 @return 状态文字
 */
- (NSString *)stateTitleWithState:(SCXDownloadState)state;

/**
 开始下载，cell通过点击按钮调用此方法，然后通过此方法调用manager下载然后manager将状态返回给此方法，此方法再返回给cell，此方法是中间方法，传递作用
 */
- (void)startDownLoad:(SCXDownloadModel *)model progress:(SCXDownloadProgressBlock)progressBlock state:(SCXDownloadStateBlock)stateBlock;

/**
 开始session任务下载
 */
- (void)startSessionDownLoad:(SCXDownloadModel *)model progress:(SCXDownloadProgressBlock)progressBlock state:(SCXDownloadStateBlock)stateBlock;

/**
 当点击cell的下载按钮的时候，对不同人物状态做不同处理
 
 @param _model 模型
 */
- (void)judgeDownloadState:(SCXDownloadModel *)_model;
@end
