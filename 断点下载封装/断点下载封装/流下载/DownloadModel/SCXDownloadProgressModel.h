//
//  SCXDownloadProgressModel.h
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/7.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class SCXDownloadModel;

@interface SCXDownloadProgressModel : NSObject

/*************  续传大小 ***************/
@property ( nonatomic , assign )int64_t resumeBytesWritten;

/*************  本次写入大小 ***************/
@property ( nonatomic , assign )int64_t bytesWritten;

/*************  一共写入大小 ***************/
@property ( nonatomic , assign )int64_t totalBytesWritten;

/*************  文件总大小 ***************/
@property ( nonatomic , assign )int64_t totalBytesExpectedToWritten;

/*************  进度 ***************/
@property ( nonatomic , assign )CGFloat progress;

/*************  速度 ***************/
@property ( nonatomic , assign )CGFloat spreed;

/*************  剩余时间 ***************/
@property ( nonatomic , assign )int remainTime;


shareInstanceH(ProgressModel);

/**
 获取model对应的progress模型
 
 @param model 下载模型
 */
- (SCXDownloadProgressModel *)SCX_GetProgressModelWithDownloadModel:(SCXDownloadModel *)model;

@end
