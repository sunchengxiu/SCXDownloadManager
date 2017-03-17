//
//  SCXDownloadSessionManager.m
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/8.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import "SCXDownloadSessionManager.h"
@interface SCXDownloadSessionManager()



@end

@implementation SCXDownloadSessionManager
shareInstanceM(SessionManager);

/**
 初始化

 @return 返回sessionManager
 */
-(instancetype)init{

    if (self = [super init]) {
        
        self.maxDownloadedCount = 1;
        self.isDownloadFIFO = YES;
        self.isBatchDownload = NO;
        self.backgroundConfigure = @"SCXDowanloadBackgroundConfigure";
        self.resumeDownload = YES;
    }
    return self;
}

/**
 配置后台
 */
- (void)configBackgroundSession{
    if (!_backgroundConfigure) {
        return;
    }
    [self session];
}
#pragma mark -------------- 懒加载 -----------------

/**
 配置session
 */
-(NSURLSession *)session{

    if (!_session) {
        if (_backgroundConfigure) {
            if (IOS_8) {
                NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:_backgroundConfigure];
                _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:self.downloadQueue];
            }
            else{
            
                _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration backgroundSessionConfiguration:_backgroundConfigure] delegate:self delegateQueue:self.downloadQueue];
            }
        }
        else{
            _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.downloadQueue];
        }
        
    }
    return _session;
}

#pragma mark -------------- 重写下载入口 -----------------
-(void)SCX_StartDownloadWithDownloadModel:(SCXDownloadModel *)model{

    // 这样写的目的是，假如说返回上个界面任务暂停了，在进入任务继续的额话，那么保存的是上一次状态，继续还得继续，等待还得等待
    // 准备中
    if (model.downLoadState == SCXDownloadStateReadying) {
        [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateReadying filePath:model.filePath error:nil];
        return ;
    }
    
    // 检查是否正在下载
    if (model.downLoadState == SCXDownloadStateRunning && model.sessionTask) {
        [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateRunning filePath:model.filePath error:nil];
        return;
    }
    
    // 检查是否下载完成
    if (model.downLoadState == SCXDownloadStateCompleted || [[SCXFileManager sharefileManager] isDownloadedCompletedWithDownloadModel:model]) {
        [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateCompleted filePath:model.filePath error:nil];
        return;
    }
    [self configBackgroundDownloadSessionWithDownloadModel:model];
    // 开始下载
    [self SCX_ResumeDownloadWithDownloadModel:model];


}
#pragma mark -------------- 主要方法 -----------------

/**
 重写父类下载方法

 @param model 下载模型
 */
-(void)SCX_ResumeDownloadWithDownloadModel:(SCXDownloadModel *)model{

    if (!model) {
        return;
    }
    if (![self isBatchToDownloadWithDownloadModel:model]) {
        return;
    }
    if (model.sessionTask == nil || model.sessionTask.state == NSURLSessionTaskStateCanceling) {
        
        // 获取续传大小
        NSData *resumeData = [self resumeDataFromFileWithDownloadModel:model];
        
        // 创建任务
        if ([self isAllowResumeDownload:resumeData]) {
            if (IOS_10) {
                model.sessionTask = [self.session downloadTaskWithResumeData:resumeData];
            }
            else{
                model.sessionTask = [self.session downloadTaskWithResumeData:resumeData];
            }
        }
        else{
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:model.downloadUrl]];
            model.sessionTask = [self.session downloadTaskWithRequest:request];
        }
        
        model.sessionTask.taskDescription = model.downloadUrl;
        model.downloadDate = [NSDate date];
        

    }
    if (!model.downloadDate) {
        model.downloadDate = [NSDate date];
    }
    if (self.downloadingModelsDic[model.downloadUrl] == nil) {
        self.downloadingModelsDic[model.downloadUrl] = model;
    }
    
    // 开始任务下载
    [model.sessionTask resume];
    
    // 处理下载状态
    model.downLoadState = SCXDownloadStateRunning;
    [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateRunning filePath:model.fileName error:nil];
}

/**
 重写父类取消下载方法

 @param model 下载模型
 */
-(void)SCX_CancelDownload:(SCXDownloadModel *)model{

    if (!model) {
        return;
    }
    if (model.downLoadState != SCXDownloadStateCompleted && model.downLoadState != SCXDownloadStateFailed) {
        [self cancelDownload:model deleteResumeData:NO];
    }

}

/**
 重写暂停方法

 @param model 下载模型
 */
-(void)SCX_SuspendDownload:(SCXDownloadModel *)model{

    if (!model.manualCancel) {
        model.manualCancel = YES;
        [self cancelDownload:model deleteResumeData:NO];
    }

}

/**
 重写删除文件的方法

 @param model 文件模型
 */
-(void)SCX_DeleteFileAndTaskWithDownloadModel:(SCXDownloadModel *)model{

    if (!model) {
        return;
    }
    [self cancelDownload:model deleteResumeData:YES];
    [[SCXFileManager sharefileManager] deleFileWithFilePath:model.filePath];

}

/**
 出血删除所有文件方法

 @param directoryPath 目的目录
 */
-(void)SCX_DeleteAllDownloadFileWithDirectoryPath:(NSString *)directoryPath{

    if (!directoryPath) {
        directoryPath = self.directoryPath;
    }
    for (SCXDownloadModel *model in self.downloadingModelsDic.allValues) {
        if ([model.directorypath isEqualToString:directoryPath]) {
            [self cancelDownload:model deleteResumeData:YES];
        }
    }
    [[SCXFileManager sharefileManager] deleFileWithFilePath:directoryPath];
}

- (void)cancelDownload:(SCXDownloadModel *)model deleteResumeData:(BOOL)delete{

    if (model.downLoadState == SCXDownloadStateReadying && !model.sessionTask) {
        model.downLoadState = SCXDownloadStateNone;
        [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateNone filePath:model.filePath error:nil];
        @synchronized (self) {
            [self.downloadingModelsDic removeObjectForKey:model.downloadUrl];
            [self.waitingDownloadModels removeObject:model];
        }
        return;
       
    }
    
    // 如果已经下载一部分了，是否删除缓存
    if (delete || self.resumeDownload) {
        
        // 删除续传路径下的续传内容
        [[SCXFileManager sharefileManager] deleFileWithFilePath:[[SCXFileManager sharefileManager] resumeDataPathWithDownloadModel:model]];
        
        model.downLoadState = SCXDownloadStateNone;
        model.resumeData = nil;
        [model.sessionTask cancel];
        
    }
    else{
    
        [model.sessionTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            
        }];
        
    }

}

#pragma mark -------------- 续传操作 -----------------

/**
 根据model从文件获取续传大小

 @param model 下载模型
 @return 续传大小
 */
- (NSData *)resumeDataFromFileWithDownloadModel:(SCXDownloadModel *)model{

    NSString *resumepath = [[SCXFileManager sharefileManager] resumeDataPathWithDownloadModel:model];
    if ([[SCXFileManager fileManager] fileExistsAtPath:resumepath]) {
        NSData *data = [NSData dataWithContentsOfFile:resumepath];
        return data;
    }
    else return nil;
    

}
- (BOOL)isAllowResumeDownload:(NSData *)data{

    if (!data || data.length == 0) {
        return NO;
    }
    return YES;

}
#pragma mark -------------- 后台配置 -----------------
/**
 获取后台的任务，暂停任务
 
 @param model 下载模型
 */
- (void)configBackgroundDownloadSessionWithDownloadModel:(SCXDownloadModel *)model{
    
    if (!_backgroundConfigure) {
        return;
    }
    
    NSURLSessionDownloadTask *task = [self SCX_BackgroundDownloadSessionTaskWithModel:model];
    if (task == nil ) {
        return;
    }
    model.sessionTask = task;
    if (model.downLoadState == SCXDownloadStateRunning) {
        [task resume];
    }
}

/**
 这个模型是否正在后台下载
 
 @param model 下载模型
 @return 正在下载的任务
 */
- (NSURLSessionDownloadTask *)SCX_BackgroundDownloadSessionTaskWithModel:(SCXDownloadModel *)model{
    
    NSArray *arr = [self backgroundAllSessionTasks];
    for (NSURLSessionDownloadTask *task in arr) {
        if (task.state == NSURLSessionTaskStateRunning || task.state == NSURLSessionTaskStateSuspended) {
            if ([task.taskDescription isEqualToString:model.downloadUrl]) {
                return task;
            }
        }
       
    }
    return nil;
}

/**
 获取后台总的任务数

 @return 任务数组
 */
- (NSArray *)backgroundAllSessionTasks{

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSArray *tasts;
    [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        tasts =downloadTasks;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return tasts;
}

/**
 取消所有后台任务
 */
- (void)cancelAllBackgroundTask{

    if (!_backgroundConfigure) {
        return;
    }
    for (NSURLSessionDownloadTask * tast in [self backgroundAllSessionTasks]) {
        [tast cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            
        }];
    }

}

#pragma mark -------------- urlsessionDelegate -----------------

/**
 续传下载，只有设置了续传才会调用这个方法，否则不会调用
 */
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes{

    // 设置续传大小
    SCXDownloadModel *model = [self SCX_GetDownloadModelWithUrlKey:downloadTask.taskDescription];
    if (!model || model.downLoadState == SCXDownloadStateSuspend) {
        return;
    }
    model.progress.resumeBytesWritten = fileOffset;

}

/**
 下载进度监听

 */
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    SCXDownloadModel *model = [self SCX_GetDownloadModelWithUrlKey:downloadTask.taskDescription];
    if (!model || model.downLoadState == SCXDownloadStateSuspend) {
        return;
    }
    NSTimeInterval time = -1 * [model.downloadDate timeIntervalSinceNow];
    model.progress.spreed = (totalBytesWritten - model.progress.resumeBytesWritten) / time;
    model.progress.progress = 1.0 * (totalBytesWritten) / totalBytesExpectedToWrite;
    model.progress.remainTime = ceil((totalBytesExpectedToWrite - totalBytesWritten ) / model.progress.spreed) ;
    model.progress.bytesWritten = bytesWritten;
    model.progress.totalBytesWritten = totalBytesWritten;
    model.progress.totalBytesExpectedToWritten = totalBytesExpectedToWrite;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self SCX_UpdateProgressWithDownloadModel:model progress:model.progress];
    });
}

/**
 下载完成
 */
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    SCXDownloadModel *model = [self SCX_GetDownloadModelWithUrlKey:downloadTask.taskDescription];
    // 这种情况是，当我们后台下载，并且下载完成了，并且强制退出了程序，那么下次重启程序的时候就会调用下面的方法
    if (!model && _backgroundSessionDownloadCompleted) {
        NSString *filePath = _backgroundSessionDownloadCompleted(downloadTask.taskDescription);
        [[SCXFileManager sharefileManager] removeItemAtPath:location aimPath:filePath];
        return;
    }
    if (location) {
        [[SCXFileManager sharefileManager] removeItemAtPath:location aimPath:model.filePath];
    }

}
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{

    SCXDownloadModel *model = [self SCX_GetDownloadModelWithUrlKey:task.taskDescription];
    if (!model) {
        NSData *data = error ? [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData] : nil;
        if (data) {
            [data writeToFile:[[SCXFileManager sharefileManager] resumeDataPathWithUrl:task.taskDescription] atomically:YES];
        }
        else{
            [[SCXFileManager sharefileManager] deleFileWithFilePath:[[SCXFileManager sharefileManager] resumeDataPathWithUrl:task.taskDescription]];
        }
        return;
    }
    NSData *resumeData = nil;
    NSString *resumePath = [[SCXFileManager sharefileManager] resumeDataPathWithUrl:task.taskDescription];
    if (error) {
        model.resumeData = resumeData;
        resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
    }
    if (resumeData) {
        model.resumeData = nil;
        [resumeData writeToFile:resumePath atomically:YES];
    }
    else{
        [[SCXFileManager sharefileManager] deleFileWithFilePath:resumePath];
    }
    model.progress.resumeBytesWritten = 0;
    model.sessionTask = nil;
    [self SCX_RemoveDownloadModelFromDownloadDicWithKey:model.downloadUrl];
    
    if (model.manualCancel) {
        dispatch_async(dispatch_get_main_queue(), ^{
            model.manualCancel = NO;
            model.downLoadState = SCXDownloadStateSuspend;
            [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateSuspend filePath:model.filePath error:nil];
            [self SCX_WillResumeDownloadWithModel:model];
 
        });
    }
    else if (error){
    
        if (model.downLoadState == SCXDownloadStateNone) {
            dispatch_async(dispatch_get_main_queue(), ^{
                model.downLoadState = SCXDownloadStateNone;
                [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateNone filePath:model.filePath error:nil];
                [self SCX_WillResumeDownloadWithModel:model];
            });
        }
        else{
        dispatch_async(dispatch_get_main_queue(), ^{
            model.downLoadState = SCXDownloadStateFailed;
            [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateFailed filePath:model.filePath error:error];
            [self SCX_WillResumeDownloadWithModel:model];
        });
        }
    }
    else {
        // 下载完成
        dispatch_async(dispatch_get_main_queue(), ^(){
            model.downLoadState = SCXDownloadStateCompleted;
            [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateCompleted filePath:model.filePath error:error];
            [self SCX_WillResumeDownloadWithModel:model];
        });
    }
    
}

/**
 后台下载完成

 */
-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{
    if (self.backgroundSessionDownloadComplementBlock) {
        self.backgroundSessionDownloadComplementBlock();
    }

}
@end
