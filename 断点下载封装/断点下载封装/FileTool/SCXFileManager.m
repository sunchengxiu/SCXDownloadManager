//
//  SCXFileManager.m
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/7.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import "SCXFileManager.h"
#import <CommonCrypto/CommonDigest.h>
@implementation SCXFileManager
shareInstanceM(fileManager);



+ (NSFileManager *)fileManager{

    return [NSFileManager defaultManager];
}
/*************  获取缓存路径 ***************/
-(NSString *)getDownloadCacheFilePath{

    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:SCX_CachePath];
    [self createDirectoryPath:path];
    
    return path;
}
/*************  检测是否存在路径，不存在则创建，privite ***************/
- (void)createDirectoryPath:(NSString *)path{

    if (![[self fileManager] fileExistsAtPath:path]) {
        [[self fileManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }

}
/*************  判断是否下载完成 ***************/
- (BOOL)isDownloadedCompletedWithDownloadModel:(SCXDownloadModel *)model{
    
    long long fileSize = [self getCachePlistFileSize:model];
    long long fileAimSize = [self getDownloadModelFilePathSize:model];
    if (fileSize > 0 && fileSize == fileAimSize) {
        return YES;
    }
    return NO;

}
/*************  获取缓存plist中保存的文件大小 ***************/
- (long long)getCachePlistFileSize:(SCXDownloadModel *)model{

    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:[self getCachePlistpath:model]];
    return [dic[model.downloadUrl] longLongValue];

}
/*************  通过downloadModel的目的路径直接获取文件大小 ***************/
-(long long)getDownloadModelFilePathSize:(SCXDownloadModel *)model{
    if (![[SCXFileManager fileManager] fileExistsAtPath:model.filePath]) {
        return 0;
    }
    else {
        return [[[SCXFileManager fileManager] attributesOfItemAtPath:model.filePath error:nil] fileSize];
    }
}
- (NSString *)getCachePlistpath:(SCXDownloadModel *)model{
    NSString *path =[model.directorypath stringByAppendingPathComponent:SCX_CachePlistPath];
//    if (![[self fileManager] fileExistsAtPath:path]) {
//        [[self fileManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
//    }
    return path;

}

/**
 删除plist中model对应的那条数据

 @param model 要输出的数据模型
 */
- (void)deletePlistFileWIthDownloadModel:(SCXDownloadModel *)model{
    NSString *plistPath = [self getCachePlistpath:model];

    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    [dic removeObjectForKey:model.downloadUrl];
    [dic writeToFile:plistPath atomically:YES];
}

/**
 删除某个路径下的文件

 @param filePath 文件路径
 */
- (void)deleFileWithFilePath:(NSString *)filePath {

    if (filePath) {
        if ([[ self fileManager] fileExistsAtPath:filePath]) {
            [[self fileManager] removeItemAtPath:filePath error:nil];
        }
    }
}

/**
 md5加密

 @param str 加密字符串
 @return 加密完成字符串
 */
+ (NSString *)md5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    if (cStr == NULL) {
        cStr = "";
    }
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

/**
 获取续传路径

 @param model 下载模型
 */
- (NSString *)resumeDataPathWithDownloadModel:(SCXDownloadModel *)model{
    
    NSString *md5FileName = [SCXFileManager md5:model.downloadUrl];
    return [[self getDownloadCacheFilePath] stringByAppendingString:md5FileName];
    
}

/**
 获取续传路径
 
 
 */
- (NSString *)resumeDataPathWithUrl:(NSString *)url{
    
    NSString *md5FileName = [SCXFileManager md5:url];
    return [[self getDownloadCacheFilePath] stringByAppendingString:md5FileName];
    
}

/**
 将原路径下的文件移动到目的路径

 @param srcUrl 原路径
 @param aimPath 目的路径
 */
- (void)removeItemAtPath:(NSURL *)srcUrl aimPath:(NSString *)aimPath{

    if (!aimPath) {
        NSLog(@"目的路径不存在");
        return;
    }
    NSError *error;
    if ([[self fileManager] fileExistsAtPath:aimPath]) {
        [[self fileManager] removeItemAtPath:aimPath error:&error];
        if (error) {
            NSLog(@"移除目的路径下文件失败%@",error);
        }
    }
    NSURL *aimUrl = [NSURL fileURLWithPath:aimPath];
    [[self fileManager] moveItemAtURL:srcUrl toURL:aimUrl error:&error];
    if (error) {
        NSLog(@"移动错误%@",error);
    }

}
@end
