//
//  SCXSessionManager.h
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/8.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCXDownloadModel.h"
@interface SCXSessionModel : SCXDownloadModel
/*************  下载任务 ***************/
@property ( nonatomic , strong )NSURLSessionDownloadTask *downloadTask;

/*************  续传数据 ***************/
@property ( nonatomic , strong )NSData *resumeData;
@end
