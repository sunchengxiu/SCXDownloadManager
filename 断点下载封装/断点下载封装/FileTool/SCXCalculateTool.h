//
//  SCXCalculateTool.h
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/8.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCXCalculateTool : NSObject
/**
 切割计算文件大小
 
 @param contentLength 文件总大小
 @return 切割后的
 */
+ (float)calculateFileSizeInUnit:(unsigned long long)contentLength;

/**
 给文件大小添加单位
 
 @param contentLength 文件总大小
 @return 文件大小名称
 */
+ (NSString *)calculateUnit:(unsigned long long)contentLength;
@end
