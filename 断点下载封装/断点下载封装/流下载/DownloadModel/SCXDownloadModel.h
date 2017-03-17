//
//  SCXDownloadModel.h
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/7.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SCXDownloadProgressModel.h"
typedef NS_ENUM(NSInteger , SCXDownloadState) {

    SCXDownloadStateNone ,
    SCXDownloadStateReadying ,
    SCXDownloadStateRunning ,
    SCXDownloadStateSuspend ,
    SCXDownloadStateCompleted ,
    SCXDownloadStateFailed

};
typedef void(^SCXDownloadProgressBlock)(SCXDownloadProgressModel *progress);
typedef void(^SCXDownloadStateBlock)(SCXDownloadState state , NSString *filePath , NSError *error);
@interface SCXDownloadModel : NSObject
/*************  是否已经存在任务了，存在就直接下载 ***************/
@property ( nonatomic , assign )BOOL exists;

/*************  下载状态 ***************/
@property ( nonatomic , assign )SCXDownloadState downLoadState;

/*************  文件流 ***************/
@property ( nonatomic , strong )NSOutputStream *stream;

/*************  下载日期 ***************/
@property ( nonatomic , strong )NSDate *downloadDate;

// 断点续传需要设置这个数据
@property (nonatomic, strong) NSData *resumeData;

/*************  下载任务 ***************/
@property ( nonatomic , strong )NSURLSessionDataTask *task;

/*************  下载任务 ***************/
@property ( nonatomic , strong )NSURLSessionDownloadTask *sessionTask;

/*************  是否手动暂停 ***************/
@property ( nonatomic , assign )BOOL manualCancel;

/*************  文件最终保存路径 ***************/
@property ( nonatomic , copy )NSString *filePath;

/*************  下载URL ***************/
@property ( nonatomic , copy )NSString *downloadUrl;

/*************  fileName ***************/
@property ( nonatomic , copy )NSString *fileName;

/*************  文件根目录directoryPath ***************/
@property ( nonatomic , copy )NSString *directorypath;

/*************  进度block ***************/
@property ( nonatomic , copy )SCXDownloadProgressBlock progressBlock;

/*************  状态block ***************/
@property ( nonatomic , copy )SCXDownloadStateBlock stateBlock;

/*************  进度模型 ***************/
@property ( nonatomic , strong )SCXDownloadProgressModel *progress;

/*************  判断当前是哪个界面的model ***************/
@property ( nonatomic , strong )NSString *idenId;

/*************  初始化 ***************/
-(instancetype)initWithUrlString:(NSString *)url filepath:(NSString *)filePath;

/**
 初始化
 
 @param url 下载url
 @return downloadModel
 */
-(instancetype)initWithUrlString:(NSString *)url;

@end
