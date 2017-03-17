//
//  SCXDownloadProgressModel.m
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/7.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import "SCXDownloadProgressModel.h"
#import "SCXFileManager.h"
@implementation SCXDownloadProgressModel
shareInstanceM(ProgressModel);

/**
 获取model对应的progress模型

 @param model 下载模型
 */
- (SCXDownloadProgressModel *)SCX_GetProgressModelWithDownloadModel:(SCXDownloadModel *)model{
    SCXDownloadProgressModel *progress = [[SCXDownloadProgressModel alloc]init];
    progress.totalBytesExpectedToWritten = [[SCXFileManager sharefileManager] getCachePlistFileSize:model];
    progress.totalBytesWritten = [[SCXFileManager sharefileManager] getDownloadModelFilePathSize:model];
    progress.progress = 1.0 * (progress.totalBytesWritten) / (progress.totalBytesExpectedToWritten);
    return progress;
    
}
@end
