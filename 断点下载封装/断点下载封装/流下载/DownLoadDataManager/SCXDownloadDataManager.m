//
//  SCXDownloadDataManager.m
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/7.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import "SCXDownloadDataManager.h"
@interface SCXDownloadDataManager()
/*************  等待下次的数组 ***************/
@property ( nonatomic , strong )NSMutableArray *waitingDownloadModels;

/*************  下载中的数组 ***************/
@property ( nonatomic , strong )NSMutableArray *downloadingModels;

/*************  下载模型字典 ***************/
@property ( nonatomic , strong )NSMutableDictionary *downloadingModelsDic;
@end

@implementation SCXDownloadDataManager

#pragma mark -------------- 单例 -----------------
shareInstanceM(manager);
#pragma mark -------------- 初始化 -----------------
-(instancetype)init{

    if (self = [super init]) {
        // 默认进行一些设置
        self.maxDownloadedCount = 1;
        self.isBatchDownload = NO;
        self.isDownloadFIFO = YES;
    }
    return self;
}
-(void)setMaxDownloadedCount:(NSInteger)maxDownloadedCount{

    _maxDownloadedCount = maxDownloadedCount;

}
-(void)setIsDownloadFIFO:(BOOL)isDownloadFIFO{

    _isDownloadFIFO = isDownloadFIFO;

}
-(void)setIsBatchDownload:(BOOL)isBatchDownload{

    _isBatchDownload = isBatchDownload;
}
#pragma mark --------------- 懒加载 -----------------
-(NSURLSession *)session{

    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.downloadQueue];
    }
    return _session;
}
-(NSOperationQueue *)downloadQueue{

    if (!_downloadQueue) {
        _downloadQueue = [[NSOperationQueue alloc] init];
    }
    return _downloadQueue;
}
-(NSMutableArray *)downloadingModels{

    if (!_downloadingModels) {
        _downloadingModels = [NSMutableArray array];
    }
    return _downloadingModels;

}
-(NSMutableDictionary *)downloadingModelsDic{

    if (!_downloadingModelsDic) {
        _downloadingModelsDic = [NSMutableDictionary dictionary];
    }
    return _downloadingModelsDic;

}
-(NSMutableArray *)waitingDownloadModels{

    if (!_waitingDownloadModels) {
        _waitingDownloadModels = [NSMutableArray array];
    }
    return _waitingDownloadModels;

}
-(NSString *)directoryPath{

    if (!_directoryPath) {
        _directoryPath = [[SCXFileManager sharefileManager] getDownloadCacheFilePath];
    }
    return _directoryPath;
}
#pragma mark -------------- 处理方法 -----------------

/**
 根据URLKEy查看是否已经存在该下载任务

 @param key urlKey
 @return 是否存在模型
 */
- (SCXDownloadModel *)SCX_GetDownloadModelWithUrlKey:(NSString *)key{
    
    return [self.downloadingModelsDic objectForKey:key];
    
}

/**
 移除当前下载对象

 */
- (void)SCX_RemoveDownloadModelFromDownloadDicWithKey:(NSString *)key{
    [self.downloadingModelsDic removeObjectForKey:key];

}

/**
 停止任务和关闭流

 @param model 数据模型
 */
- (void)cancelTaskAndCloseStream:(SCXDownloadModel *)model{

    if (model.task) {
        [model.task cancel];
    }
    model.task = nil;
    model.task.taskDescription = nil;
    if (model.stream) {
        if (model.stream.streamStatus > NSStreamStatusOpening && model.stream.streamStatus < NSStreamStatusClosed) {
            [model.stream close];
        }
    }
    model.stream = nil;
}

#pragma mark -------------- 下载入口 -----------------
/*************  通过url和目的路径来下载 ***************/
-(SCXDownloadModel *)SCX_StartDownloadWithUrlString:(NSString *)urlString directoryPath:(NSString *)directoryPath progressBlock:(SCXDownloadProgressBlock)progressBlock stateBlock:(SCXDownloadStateBlock)stateBlock{
    if (!urlString) {
        NSLog(@"url不能为空");
        return nil;
    }
    // 查看本地下载字典中是否含有这个模型
    SCXDownloadModel *model = [self SCX_GetDownloadModelWithUrlKey:urlString];
    
    // 如果不存在
    if (!model || ![model.filePath isEqualToString:directoryPath]) {
        model = [[SCXDownloadModel alloc] initWithUrlString:urlString filepath:directoryPath];
    }
    // 通过模型下载
    [self SCX_StartDownloadWithDownloadModel:model progressBlock:progressBlock stateBlock:stateBlock];
    return model;

}
/*************  通过传入模型下载 ***************/
- (void)SCX_StartDownloadWithDownloadModel:(SCXDownloadModel *)model progressBlock:(SCXDownloadProgressBlock)progressBlock stateBlock:(SCXDownloadStateBlock)stateBlock{
    
    model.progressBlock = progressBlock;
    model.stateBlock = stateBlock;
    [self SCX_StartDownloadWithDownloadModel:model];
    
}

/*************  下载入口 ***************/
- (void)SCX_StartDownloadWithDownloadModel:(SCXDownloadModel *)model{
    
    // 这样写的目的是，假如说返回上个界面任务暂停了，在进入任务继续的额话，那么保存的是上一次状态，继续还得继续，等待还得等待
    // 准备中
    if (model.downLoadState == SCXDownloadStateReadying) {
        [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateReadying filePath:model.filePath error:nil];
        return ;
    }
    
    // 检查是否正在下载
    if (model.downLoadState == SCXDownloadStateRunning && model.task) {
        [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateRunning filePath:model.filePath error:nil];
        return;
    }
    
    // 检查是否下载完成
    if (model.downLoadState == SCXDownloadStateCompleted || [[SCXFileManager sharefileManager] isDownloadedCompletedWithDownloadModel:model]) {
        [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateCompleted filePath:model.filePath error:nil];
        return;
    }
    // 开始下载
    [self SCX_ResumeDownloadWithDownloadModel:model];

}

#pragma mark -------------- 开始正式下载 -----------------

/**
 恢复下载

 @param model 下载模型
 */
- (void)SCX_ResumeDownloadWithDownloadModel:(SCXDownloadModel *)model{

    // 判断一下是否为全部并发或者当前你下载数组是否已经达到全部并发数量了，如果达到，那么久别下载了,继续等待
    if (![self isBatchToDownloadWithDownloadModel:model]) {
       
        return;
    }
    // 没有达到最大并发数，继续下载,如果任务不存在或者被取消了也会走下面的方法，例如手动取消或者重启程序，入伍就会不存在或者cancel
    if (!model.task || model.task.state == NSURLSessionTaskStateCanceling) {
        // 创建请求
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:model.downloadUrl]];
        
        // 获取请求头
        long long fileSize = [[SCXFileManager sharefileManager] getDownloadModelFilePathSize:model];
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-",fileSize];
        
        // 创建请求头
        [request setValue:range forHTTPHeaderField:@"Range"];
        
        // 创建流
        model.stream = [NSOutputStream outputStreamToFileAtPath:model.filePath append:YES];
        
        //创建任务
        model.downloadDate = [NSDate date];
        self.downloadingModelsDic[model.downloadUrl] = model;
        model.task = [self.session dataTaskWithRequest:request];
        model.task.taskDescription = model.downloadUrl;
    }
    [model.task resume];
    
    // 更新下载状态
    model.downLoadState = SCXDownloadStateRunning;
    [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateRunning filePath:model.filePath error:nil];
}

/**
 暂停下载

 @param model 下载模型
 */
- (void)SCX_SuspendDownload:(SCXDownloadModel *)model{

    if (!model.manualCancel) {
        model.manualCancel = YES;
        [model.task cancel];
    }

}

/**
 取消下载

 @param model 下载模型
 */
- (void)SCX_CancelDownload:(SCXDownloadModel *)model{
    
    // 如果是等待中，说明任务还没开始，不存在任务，所以说就没有必要cancel
    if (!model.task && model.downLoadState == SCXDownloadStateReadying) {
        // 从下载字典中删除
        [self SCX_RemoveDownloadModelFromDownloadDicWithKey:model.downloadUrl];
        // 从等待数组中删除
        @synchronized (self) {
            [self.waitingDownloadModels removeObject:model];
        }
        model.downLoadState = SCXDownloadStateNone;
        [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateNone filePath:model.filePath error:nil];
        return;
    }

    // 任务存在，则取消
    if (model.downLoadState != SCXDownloadStateFailed && model.downLoadState != SCXDownloadStateCompleted) {
        [model.task cancel];
    }

}

/**
 删除文件和任务

 @param model 下载模型
 */
- (void)SCX_DeleteFileAndTaskWithDownloadModel:(SCXDownloadModel *)model{

    if (!model || !model.filePath) {
        return;
    }
    if ([[SCXFileManager fileManager] fileExistsAtPath:model.filePath]) {
        // 删除文件
        [[SCXFileManager fileManager] removeItemAtPath:model.filePath error:nil];
        
        // 删除流
        // 删除任务
        [self cancelTaskAndCloseStream:model];
        
        // 从下载字典中删除此条记录
        [self.downloadingModelsDic removeObjectForKey:model.downloadUrl];
        
        // 从plist文件中删除此条信息
        [[SCXFileManager sharefileManager] deletePlistFileWIthDownloadModel:model];
       
        
    }

}

/**
 根据传入根目录，删除这个根目录下所有的文件

 @param directoryPath 要删除的根目录
 */
- (void)SCX_DeleteAllDownloadFileWithDirectoryPath:(NSString *)directoryPath{

    if (directoryPath == nil) {
        directoryPath = self.directoryPath;
    }
    // 先将任务关闭
    for (SCXDownloadModel *model in self.downloadingModelsDic.allValues) {
        if ([model.directorypath isEqualToString:directoryPath]) {
            [self cancelTaskAndCloseStream:model];
        }
    }
    
    // 移除这个根目录下的所有文件
    [[SCXFileManager fileManager] removeItemAtPath:directoryPath error:nil];
}

/**
 当一个文件下载完成的时候从等待数组中提取一个文件放到下载数组中。

 @param model 下载完成的文件模型
 */
- (void)SCX_WillResumeDownloadWithModel:(SCXDownloadModel *)model{

    if (self.isBatchDownload) {
        return;
    }
    [self.downloadingModels removeObject:model];
    if (self.waitingDownloadModels.count > 0 ) {
        [self SCX_ResumeDownloadWithDownloadModel:self.isDownloadFIFO ? self.waitingDownloadModels.firstObject : self.waitingDownloadModels.lastObject];
    }
}

#pragma mark -------------- 是否全部并发下载 -----------------

/**
 并发设置，控制下载数量

 @param model 下载模型
 @return 是否允许创建任务下载
 */
- (BOOL)isBatchToDownloadWithDownloadModel:(SCXDownloadModel *)model{

    if (self.isBatchDownload) {
        return YES;
    }
    // 下面分两种情况，一种是最大并发数小于下载的数量,一种是最大并发数大于下载个数，那么也是全部并发
    @synchronized (self) {
        // 如果下载中的数组达到最大并发数了，那么其余文件就添加到等待数组当中
        if (self.downloadingModels.count >= self.maxDownloadedCount) {
            if ([self.waitingDownloadModels indexOfObject:model] == NSNotFound) {
                [self.waitingDownloadModels addObject:model];
                self.downloadingModelsDic[model.downloadUrl ] = model;
            }
            model.downLoadState = SCXDownloadStateReadying;
            [self SCX_DownLoadModel:model didChangeDownloadState:model.downLoadState filePath:model.filePath error:nil];
            return NO;
        }
        
        // 当最大并发数大于下载数量的时候，说明下载中的数组没有达到最大并发数，那么就往下载数组中添加下载数量，知道达到了最大并发数,添加到下载数组，那么就从等待数组中移除.
        if ([self.waitingDownloadModels indexOfObject:model] != NSNotFound) {
            [self.waitingDownloadModels removeObject:model];
        }
        
        // 如果下载数组中没有这个文件，那么添加到这个数组，因为为全并发
        if ([self.downloadingModels indexOfObject:model] == NSNotFound) {
            [self.downloadingModels addObject:model];
        }
        return YES;
    }

}
#pragma mark -------------- 下载状态改变的监听 -----------------
-(void)SCX_DownLoadModel:(SCXDownloadModel *)model didChangeDownloadState:(SCXDownloadState)state filePath:(NSString *)filePah error:(NSError *)error{
    if (_delegate && [_delegate respondsToSelector:@selector(SCX_DownLoadModel:didChangeDownloadState:filePath:error:)]) {
        [_delegate SCX_DownLoadModel:model didChangeDownloadState:state filePath:filePah error:error];
    }
    if (model.stateBlock) {
        model.stateBlock(state , filePah , error);
    }
}

/**
 更新进度

 @return
 */
#pragma mark -------------- 更新进度 -----------------
- (void)SCX_UpdateProgressWithDownloadModel:(SCXDownloadModel *)model progress:(SCXDownloadProgressModel *)progress{

    if (_delegate && [_delegate respondsToSelector:@selector(SCX_UpdateProgressWithDownloadModel:progress:)]) {
        [_delegate SCX_UpdateProgressWithDownloadModel:model progress:progress];
    }
    if (model.progressBlock) {
        model.progressBlock(progress);
    }
}

#pragma mark -------------- NSUrlSessionDelegate -----------------

/**
 收到响应了

 @param session 回话
 @param dataTask 任务
 @param response 返回的数据
 @param completionHandler 回调
 */
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{

    SCXDownloadModel *model = [self SCX_GetDownloadModelWithUrlKey:dataTask.taskDescription];
    if (!model) {
        return;
    }
    // 获取并创建一下缓存跟路径
    NSString *cachePaht = [[SCXFileManager sharefileManager] getDownloadCacheFilePath];
    
    // 打开流
    [model.stream open];
    
    // 检查是否已经下载过一部分
    long long totalBytesWritten = [[SCXFileManager sharefileManager] getDownloadModelFilePathSize:model];
    long long totalBytesExceptToWritten = totalBytesWritten + dataTask.countOfBytesExpectedToReceive;
    model.progress.totalBytesWritten = totalBytesWritten;
    model.progress.totalBytesExpectedToWritten = totalBytesExceptToWritten;
    model.progress.resumeBytesWritten = totalBytesWritten;
    // 将文件大小保存到plist，用来判断是否下载完成
    @synchronized (self) {
        
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:[[SCXFileManager sharefileManager] getCachePlistpath:model]];
        if (!dic) {
            dic = [NSMutableDictionary dictionary];
        }
            dic[model.downloadUrl] = @(totalBytesExceptToWritten);
            [dic writeToFile:[[SCXFileManager sharefileManager] getCachePlistpath:model] atomically:YES];
        
        
    }
    
    completionHandler(NSURLSessionResponseAllow);

}

/**
 收到数据结构

 @param session 会话
 @param dataTask 任务
 @param data 数据
 */
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    SCXDownloadModel *model = [self SCX_GetDownloadModelWithUrlKey:dataTask.taskDescription];
    if (!model || model.downLoadState == SCXDownloadStateSuspend) {
        return;
    }
    // 写入数据
    [model.stream open];
    [model.stream write:data.bytes maxLength:data.length];
    
    // 下载进度
    long long bytesWritten = data.length;
    
    model.progress.bytesWritten = bytesWritten;
    model.progress.totalBytesWritten += bytesWritten;
    model.progress.progress = MIN(1.0, 1.0 * (model.progress.totalBytesWritten / model.progress.totalBytesExpectedToWritten));

    
    
    // 下载速度
    NSTimeInterval time = -1 * [model.downloadDate timeIntervalSinceNow];
    model.progress.spreed = (model.progress.totalBytesWritten - model.progress.resumeBytesWritten) / time;
    model.progress.progress = MIN(1.0, 1.0 * model.progress.totalBytesWritten / model.progress.totalBytesExpectedToWritten);
    
    // 估计下载剩余时间
    long long otherSize = model.progress.totalBytesExpectedToWritten - model.progress.totalBytesWritten;
    NSTimeInterval remainTime = ceil((otherSize) / model.progress.spreed);
    model.progress.remainTime = remainTime;
    
    // 更新进度
    dispatch_async(dispatch_get_main_queue(), ^{
        [self SCX_UpdateProgressWithDownloadModel:model progress:model.progress];
    });
}

/**
 完成或者失败

 @param session 会话
 @param task 任务
 @param error 是否成功
 */
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    SCXDownloadModel *model = [self SCX_GetDownloadModelWithUrlKey:task.taskDescription];
    if (!model || model.downLoadState == SCXDownloadStateSuspend) {
        return;
    }
    // 关闭流
    [model.stream close];
    model.stream = nil;
    model.task = nil;
    [self SCX_RemoveDownloadModelFromDownloadDicWithKey:task.taskDescription];

    // 处理各种成功或者失败的情况
    // 当手动暂停的时候
    if (model.manualCancel) {
        dispatch_async(dispatch_get_main_queue(), ^{
            model.manualCancel = NO;
            model.downLoadState = SCXDownloadStateSuspend;
            [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateSuspend filePath:model.filePath error:nil];
            [self SCX_WillResumeDownloadWithModel:model];
        });
       
    }
    // 当出现错误的时候
    else if (error != nil){
        dispatch_async(dispatch_get_main_queue(), ^{
            model.downLoadState = SCXDownloadStateFailed;
            [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateFailed filePath:model.filePath error:nil];
            [self SCX_WillResumeDownloadWithModel:model];
        });
       
    }
    // 完成的时候
    else if ([[SCXFileManager sharefileManager] isDownloadedCompletedWithDownloadModel:model]){
        dispatch_async(dispatch_get_main_queue(), ^{
            model.downLoadState = SCXDownloadStateCompleted;
            [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateCompleted filePath:model.filePath error:nil];
            [self SCX_WillResumeDownloadWithModel:model];
        });
        
    }
    else{
        dispatch_async(dispatch_get_main_queue(), ^{
            model.downLoadState = SCXDownloadStateCompleted;
            [self SCX_DownLoadModel:model didChangeDownloadState:SCXDownloadStateCompleted filePath:model.filePath error:nil];
            [self SCX_WillResumeDownloadWithModel:model];
        });
    }
}

@end
