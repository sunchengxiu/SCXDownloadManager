//
//  SCXDownloadSessionManager.h
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/8.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCXDownloadDataManager.h"
#import "SCXFileManager.h"
@interface SCXDownloadSessionManager : SCXDownloadDataManager<NSURLSessionDownloadDelegate>

// 后台session configure
@property (nonatomic, strong) NSString *backgroundConfigure;


/*************  是否续传 ***************/
@property ( nonatomic , assign )BOOL resumeDownload;

/*************  后台下载完成并且重启时候block ***************/
@property ( nonatomic , copy )NSString *(^backgroundSessionDownloadCompleted)(NSString *filePath);

/*************  后台完成调用block ***************/
@property ( nonatomic , copy )void (^backgroundSessionDownloadComplementBlock)();

shareInstanceH(SessionManager);

/**
 配置后台
 */
- (void)configBackgroundSession;

/**
 这个模型是否正在后台下载
 
 @param model 下载模型
 @return 正在下载的任务
 */
- (NSURLSessionDownloadTask *)SCX_BackgroundDownloadSessionTaskWithModel:(SCXDownloadModel *)model;



@end
