//
//  SCXFileManager.h
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/7.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCXDownloadModel.h"
@interface SCXFileManager : NSObject

/*************  文件管理者 ***************/
@property ( nonatomic , strong )NSFileManager *fileManager;

/*************  文件总路径 ***************/
@property ( nonatomic , copy )NSString *fileDirectory;

/*************  缓存根目录 ***************/
@property ( nonatomic , copy )NSString *directoryPath;

/*************  创建文件管理者 ***************/
+ (NSFileManager *)fileManager;

shareInstanceH(fileManager)

/*************  获取缓存路径 ***************/
- (NSString *)getDownloadCacheFilePath;


/*************  获取缓存大小plist文件路径 ***************/
- (NSString *)getCachePlistpath:(SCXDownloadModel *)model;

/*************  判断是否下载完成 ***************/
- (BOOL)isDownloadedCompletedWithDownloadModel:(SCXDownloadModel *)model;

/*************  获取缓存plist中的文件大小 ***************/
- (long long)getCachePlistFileSize:(SCXDownloadModel *)model;

/*************  通过downloadModel的目的路径直接获取文件大小 ***************/
-(long long)getDownloadModelFilePathSize:(SCXDownloadModel *)model;

/**
 删除plist中model对应的那条数据
 
 @param model 要输出的数据模型
 */
- (void)deletePlistFileWIthDownloadModel:(SCXDownloadModel *)model;

/**
 md5加密
 
 @param str 加密字符串
 @return 加密完成字符串
 */
+ (NSString *)md5:(NSString *)str;

/**
 获取续传路径
 
 @param model 下载模型
 */
- (NSString *)resumeDataPathWithDownloadModel:(SCXDownloadModel *)model;

/**
 删除某个路径下的文件
 
 @param filePath 文件路径
 */
- (void)deleFileWithFilePath:(NSString *)filePath;

/**
 获取续传路径
 
 
 */
- (NSString *)resumeDataPathWithUrl:(NSString *)url;

/**
 将原路径下的文件移动到目的路径
 
 @param srcUrl 原路径
 @param aimPath 目的路径
 */
- (void)removeItemAtPath:(NSURL *)srcUrl aimPath:(NSString *)aimPath;
@end
