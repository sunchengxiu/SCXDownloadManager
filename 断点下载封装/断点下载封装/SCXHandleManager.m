//
//  SCXHandleManager.m
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/8.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import "SCXHandleManager.h"
#import "SCXDownloadSessionManager.h"
@implementation SCXHandleManager

shareInstanceM(HandleManager);

/**
 将字节大小 转化为文字

 @param progress progressModel
 @return 字节字符串
 */
- (NSString *)detailTextForDownloadProgress:(SCXDownloadProgressModel *)progress
{
    NSString *fileSizeInUnits = [NSString stringWithFormat:@"%.2f %@",
                                 [SCXCalculateTool calculateFileSizeInUnit:(unsigned long long)progress.totalBytesExpectedToWritten],
                                 [SCXCalculateTool calculateUnit:(unsigned long long)progress.totalBytesExpectedToWritten]];
    
    NSMutableString *detailLabelText = [NSMutableString stringWithFormat:@"File Size: %@\nDownloaded: %.2f %@ (%.2f%%)\nSpeed: %.2f %@/sec\nLeftTime: %dsec",fileSizeInUnits,
                                        [SCXCalculateTool calculateFileSizeInUnit:(unsigned long long)progress.totalBytesWritten],
                                        [SCXCalculateTool calculateUnit:(unsigned long long)progress.totalBytesWritten],progress.progress*100,
                                        [SCXCalculateTool calculateFileSizeInUnit:(unsigned long long) progress.spreed],
                                        [SCXCalculateTool calculateUnit:(unsigned long long)progress.spreed]
                                        ,progress.remainTime];
    if (progress.totalBytesWritten - 0 == 0) {
        return @"";
    }
    return detailLabelText;
}

/**
 将状态对应相应的状态文字

 @param state 状态
 @return 状态文字
 */
- (NSString *)stateTitleWithState:(SCXDownloadState)state
{
    switch (state) {
        case SCXDownloadStateReadying:
            return @"等待下载";
            break;
        case SCXDownloadStateFailed:
            return @"下载失败";
            break;
        case SCXDownloadStateCompleted:
            return @"下载完成，重新下载";
            break;
        case SCXDownloadStateRunning:
            return @"暂停下载";
            break;
        default:
            return @"开始下载";
            break;
    }
}
/**
 开始下载，cell通过点击按钮调用此方法，然后通过此方法调用manager下载然后manager将状态返回给此方法，此方法再返回给cell，此方法是中间方法，传递作用
 */
#pragma mark -------------- 开始下载 -----------------
- (void)startDownLoad:(SCXDownloadModel *)model progress:(SCXDownloadProgressBlock)progressBlock state:(SCXDownloadStateBlock)stateBlock{
    SCXDownloadDataManager *manager = [SCXDownloadDataManager sharemanager];
    manager.maxDownloadedCount = 1;
    manager.delegate = self;
    __weak typeof(self) weakSelf = self;
    if (model != nil) {
        [manager SCX_StartDownloadWithDownloadModel:model progressBlock:^(SCXDownloadProgressModel *progress) {
            progressBlock(progress);
            
        } stateBlock:^(SCXDownloadState state, NSString *filePath, NSError *error) {
            stateBlock(state , filePath , error);
            if (state == SCXDownloadStateCompleted) {
                NSLog(@"下载成功了%@",filePath);
            }
        }];
    }
    
}

/**
 开始session任务下载
 */
- (void)startSessionDownLoad:(SCXDownloadModel *)model progress:(SCXDownloadProgressBlock)progressBlock state:(SCXDownloadStateBlock)stateBlock{
    SCXDownloadSessionManager *manager = [SCXDownloadSessionManager shareSessionManager];
    manager.maxDownloadedCount = 1;
    manager.delegate = self;
    __weak typeof(self) weakSelf = self;
    if (model != nil) {
        [manager SCX_StartDownloadWithDownloadModel:model progressBlock:^(SCXDownloadProgressModel *progress) {
            progressBlock(progress);
            
        } stateBlock:^(SCXDownloadState state, NSString *filePath, NSError *error) {
            stateBlock(state , filePath , error);
            if (state == SCXDownloadStateCompleted) {
                NSLog(@"下载成功了%@",filePath);
            }
        }];
    }
    
}

/**
 当点击cell的下载按钮的时候，对不同人物状态做不同处理

 @param _model 模型
 */
- (void)judgeDownloadState:(SCXDownloadModel *)_model{

    SCXDownloadDataManager *manager = [SCXDownloadDataManager sharemanager];
    
    if (_model.downLoadState == SCXDownloadStateReadying) {
        [manager SCX_CancelDownload:_model];
        return;
    }
    
    if (_model.downLoadState == SCXDownloadStateCompleted || [[SCXFileManager sharefileManager] isDownloadedCompletedWithDownloadModel:_model]) {
        [manager SCX_DeleteFileAndTaskWithDownloadModel:_model];
        _model.downLoadState = SCXDownloadStateNone;
        _model.progress = [[SCXDownloadProgressModel alloc] init];
        
    }
    
    if (_model.downLoadState == SCXDownloadStateRunning) {
        [manager SCX_SuspendDownload:_model];
        return;
    }
}
@end
