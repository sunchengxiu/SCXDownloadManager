//
//  SCXDownloadModel.m
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/7.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import "SCXDownloadModel.h"
#import "SCXFileManager.h"
@implementation SCXDownloadModel
#pragma mark -------------- 初始化 -----------------

/**
 初始化

 @param url 下载url
 @return downloadModel
 */
-(instancetype)initWithUrlString:(NSString *)url {
    
    return [self initWithUrlString:url filepath:nil];
    
}
-(instancetype)initWithUrlString:(NSString *)url filepath:(NSString *)filePath{

    if (self = [super init]) {
        if (filePath == nil) {
            filePath = self.filePath;
        }
        self.filePath = filePath;
        self.downloadUrl = url;
        self.fileName = filePath.lastPathComponent;
        self.directorypath = filePath.stringByDeletingLastPathComponent;
    }
    return self;

}
-(NSString *)fileName
{
    if (!_fileName) {
        _fileName = _downloadUrl.lastPathComponent;
    }
    return _fileName;
}

- (NSString *)directorypath
{
    if (!_directorypath) {
        _directorypath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:SCX_CachePath];
        if (![[SCXFileManager fileManager] fileExistsAtPath:_directorypath]) {
            [[SCXFileManager fileManager] createDirectoryAtPath:_directorypath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return _directorypath;
}

- (NSString *)filePath
{
    if (!_filePath) {
        _filePath = [self.directorypath stringByAppendingPathComponent:self.fileName];
    }
    return _filePath;
}
- (SCXDownloadProgressModel *)progress{
    if (!_progress) {
        _progress = [[SCXDownloadProgressModel alloc]init];
    }
    return _progress;
}
@end
