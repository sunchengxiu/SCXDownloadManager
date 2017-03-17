//
//  SCXDownloadDataManager.h
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/7.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCXDownloadModel.h"
#import "SCXDownloadProgressModel.h"
#import "SCXFileManager.h"
@protocol SCXDownloadDataDelegate;
@interface SCXDownloadDataManager : NSObject<NSURLSessionDataDelegate>
{
    NSURLSession *_session;
    
}
/*************  代理 ***************/
@property ( nonatomic , weak )id <SCXDownloadDataDelegate> delegate;

/*************  文件处理者 ***************/
@property ( nonatomic , strong )SCXFileManager *SCX_FileManager;

/*************  文件总路径 ***************/
@property ( nonatomic , copy )NSString *fileDirectory;

/*************  缓存根目录 ***************/
@property ( nonatomic , copy )NSString *directoryPath;

/*************  等待下次的数组 ***************/
@property ( nonatomic , strong , readonly)NSMutableArray *waitingDownloadModels;

/*************  下载中的数组 ***************/
@property ( nonatomic , strong , readonly)NSMutableArray *downloadingModels;

/*************  下载模型字典 ***************/
@property ( nonatomic , strong , readonly)NSMutableDictionary *downloadingModelsDic;

/*************  下载队列 ***************/
@property ( nonatomic , strong )NSOperationQueue *downloadQueue;

/*************  下载回话 ***************/
@property ( nonatomic , strong )NSURLSession *session;

/*************  最大并发数 ***************/
@property ( nonatomic , assign )NSInteger maxDownloadedCount;

/*************  是否全部并发，如果为YES，葫芦最大并发数 ***************/
@property ( nonatomic , assign )BOOL isBatchDownload;

/*************  下载规则，先进先出还是后进后出,默认先进先出 ***************/
@property ( nonatomic , assign )BOOL isDownloadFIFO;


/*************  单例 ***************/
shareInstanceH(manager);

/*************  通过url和目的路径来下载 ***************/
-(SCXDownloadModel *)SCX_StartDownloadWithUrlString:(NSString *)urlString directoryPath:(NSString *)directoryPath progressBlock:(SCXDownloadProgressBlock)progressBlock stateBlock:(SCXDownloadStateBlock)stateBlock;

/*************  通过传入模型下载 ***************/
- (void)SCX_StartDownloadWithDownloadModel:(SCXDownloadModel *)model progressBlock:(SCXDownloadProgressBlock)progressBlock stateBlock:(SCXDownloadStateBlock)stateBlock;


/*************  下载入口 ***************/
- (void)SCX_StartDownloadWithDownloadModel:(SCXDownloadModel *)model;


/*************  下载状态改变通知 ***************/
-(void)SCX_DownLoadModel:(SCXDownloadModel *)model didChangeDownloadState:(SCXDownloadState)state filePath:(NSString *)filePah error:(NSError *)error;

/*************  正式开始下载 ***************/
- (void)SCX_ResumeDownloadWithDownloadModel:(SCXDownloadModel *)model;

/**
 暂停下载
 
 @param model 下载模型
 */
- (void)SCX_SuspendDownload:(SCXDownloadModel *)model;

/**
 取消下载
 
 @param model 下载模型
 */
- (void)SCX_CancelDownload:(SCXDownloadModel *)model;

/**
 删除文件和任务
 
 @param model 下载模型
 */
- (void)SCX_DeleteFileAndTaskWithDownloadModel:(SCXDownloadModel *)model;

/**
 根据传入根目录，删除这个根目录下所有的文件
 
 @param directoryPath 要删除的根目录
 */
- (void)SCX_DeleteAllDownloadFileWithDirectoryPath:(NSString *)directoryPath;

/**
 当一个文件下载完成的时候从等待数组中提取一个文件放到下载数组中。
 
 @param model 下载完成的文件模型
 */
- (void)SCX_WillResumeDownloadWithModel:(SCXDownloadModel *)model;

/**
 并发设置，控制下载数量
 
 @param model 下载模型
 @return 是否允许创建任务下载
 */
- (BOOL)isBatchToDownloadWithDownloadModel:(SCXDownloadModel *)model;

/**
 更新进度
 
 */
- (void)SCX_UpdateProgressWithDownloadModel:(SCXDownloadModel *)model progress:(SCXDownloadProgressModel *)progress;

/**
 根据URLKEy查看是否已经存在该下载任务
 
 @param key urlKey
 @return 是否存在模型
 */
- (SCXDownloadModel *)SCX_GetDownloadModelWithUrlKey:(NSString *)key;

/**
 移除当前下载对象
 
 */
- (void)SCX_RemoveDownloadModelFromDownloadDicWithKey:(NSString *)key;


@end
@protocol SCXDownloadDataDelegate <NSObject>

-(void)SCX_DownLoadModel:(SCXDownloadModel *)model didChangeDownloadState:(SCXDownloadState)state filePath:(NSString *)filePah error:(NSError *)error;

- (void)SCX_UpdateProgressWithDownloadModel:(SCXDownloadModel *)model progress:(SCXDownloadProgressModel *)progress;

@end
