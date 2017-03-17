//
//  SCXTableViewCell.m
//  断点下载封装
//
//  Created by 孙承秀 on 2017/3/8.
//  Copyright © 2017年 孙承秀. All rights reserved.
//

#import "SCXTableViewCell.h"
#import "SCXDownloadSessionManager.h"
@implementation SCXTableViewCell
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
//        [self layoutStreamViews];
    }
    return self;
}

/**
 模型数据，用来搭建界面

 @param model 模型
 */
-(void)setModel:(SCXDownloadModel *)model {
    
    _model = model;
    [self.fileInfoLabel removeFromSuperview];
    self.fileInfoLabel = nil;
    [self.progressView removeFromSuperview];
    self.progressView = nil;
    [self.streamButton removeFromSuperview];
    self.streamButton = nil;

    NSString *text =  [[SCXHandleManager shareHandleManager] detailTextForDownloadProgress:model.progress];
    self.fileInfoLabel.text = text;
   
    self.progressView.progress = model.progress.progress;
 
        if (model.exists) {
            
            [self startDownLoad:model];
        }
}


#pragma mark - 懒加载
-(UILabel *)fileInfoLabel{
    
    if (!_fileInfoLabel) {
        _fileInfoLabel = [[UILabel alloc] init];
        [_fileInfoLabel setBackgroundColor:[UIColor redColor]];
        [_fileInfoLabel setFont:[UIFont systemFontOfSize:15]];
        _fileInfoLabel.numberOfLines = 0;
        
        [self.contentView addSubview:_fileInfoLabel];
    }
    return _fileInfoLabel;
}
-(UILabel *)spreedlabel{
    
    if (!_spreedlabel) {
        _spreedlabel = [[UILabel alloc] init];
        [_spreedlabel setBackgroundColor:[UIColor redColor]];
        [self.contentView addSubview:_spreedlabel];
    }
    return _spreedlabel;
}
-(UILabel *)remainLabel{
    
    if (!_remainLabel) {
        _remainLabel = [[UILabel alloc] init];
        [_remainLabel setBackgroundColor:[UIColor redColor]];
        [self.contentView addSubview:_remainLabel];
    }
    return _remainLabel;
}
-(UIButton *)streamButton{
    
    if (!_streamButton) {
        _streamButton = [[UIButton alloc]init];
        [_streamButton setTitle:@"开始" forState:UIControlStateNormal];
        [_streamButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_streamButton addTarget:self action:@selector(downloadButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_streamButton];
    }
    return _streamButton;
}
-(UIProgressView *)progressView{
    
    if (!_progressView) {
        _progressView = [[UIProgressView alloc]init];
        _progressView.tintColor = [UIColor blueColor];
        [self.contentView addSubview:self.progressView];
    }
    return _progressView;
    
}

/**
 下载按钮点击事件
 */
- (void)downloadButtonClick:(UIButton *)btn{
    SCXDownloadDataManager *manager ;
    if ([self.reuseIdentifier isEqualToString:cellID] ) {
       manager = [SCXDownloadDataManager sharemanager];
    }
    else{
        manager = [SCXDownloadSessionManager shareSessionManager];
    }
    
    
    if (_model.downLoadState == SCXDownloadStateReadying) {
        [manager SCX_CancelDownload:_model];
        return;
    }
    
    if (_model.downLoadState == SCXDownloadStateCompleted || [[SCXFileManager sharefileManager] isDownloadedCompletedWithDownloadModel:_model]) {
        [manager SCX_DeleteFileAndTaskWithDownloadModel:_model];
        _model.downLoadState = SCXDownloadStateNone;
        _model.progress = [[SCXDownloadProgressModel alloc] init];
        
    }
    
    if (_model.downLoadState == SCXDownloadStateRunning) {
        [manager SCX_SuspendDownload:_model];
        return;
    }    NSLog(@"你点击了文件流的下载按钮");
    // 开始下载
    [self startDownLoad:_model];
    
}

/**
 将与下载类沟通交给handle类

 @param model 下载模型
 */
- (void)startDownLoad:(SCXDownloadModel *)model {
    if (self.fileInfoLabel.frame.size.height ==0) {
        
    }
    if ([self.reuseIdentifier isEqualToString:cellID] ) {
        
        [[SCXHandleManager shareHandleManager] startDownLoad:_model progress:^(SCXDownloadProgressModel *progress) {
            // 更新列表交给VC，自己值负责显示
            if ([self.delegate respondsToSelector:@selector(updateCell:progress:)] || [self.sessionCellDelegate respondsToSelector:@selector(updateSessionCell:progress:)]) {
                if ([self.reuseIdentifier isEqualToString:cellID] ) {
                    
                    [self.delegate updateCell:self progress:progress];
                    
                    
                }
                else{
                    
                    [self.sessionCellDelegate updateSessionCell:self progress:progress];
                    
                    
                }
            }
            
        } state:^(SCXDownloadState state, NSString *filePath, NSError *error) {
            [self.streamButton setTitle:[[SCXHandleManager shareHandleManager] stateTitleWithState:state] forState:UIControlStateNormal];
            if (state == SCXDownloadStateCompleted) {
                NSLog(@"下载成功了%@",filePath);
            }
        }];
    }
    else{
        
        [[SCXHandleManager shareHandleManager] startSessionDownLoad:_model progress:^(SCXDownloadProgressModel *progress) {
            // 更新列表交给VC，自己值负责显示
            if ([self.delegate respondsToSelector:@selector(updateCell:progress:)] || [self.sessionCellDelegate respondsToSelector:@selector(updateSessionCell:progress:)]) {
                if ([self.reuseIdentifier isEqualToString:cellID] ) {
                    
                    [self.delegate updateCell:self progress:progress];
                    
                    
                }
                else{
                    
                    [self.sessionCellDelegate updateSessionCell:self progress:progress];
                    
                    
                }
            }
        } state:^(SCXDownloadState state, NSString *filePath, NSError *error) {
            [self.streamButton setTitle:[[SCXHandleManager shareHandleManager] stateTitleWithState:state] forState:UIControlStateNormal];
            if (state == SCXDownloadStateCompleted) {
                NSLog(@"下载成功了%@",filePath);
            }
        }];
    }
    
}

/**
 系统布局
 */
-(void)layoutSubviews{
    [super layoutSubviews];
    // 如果不加这句话，那么点击cell 的时候，label额背景颜色就会被取消
    self.fileInfoLabel.backgroundColor = [UIColor redColor];
    [self.fileInfoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.contentView).offset(10);
        make.top.mas_equalTo(self.contentView).offset(10);
        //make.height.mas_greaterThanOrEqualTo(0.1);
    }];
    [self.spreedlabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.fileInfoLabel);
        make.top.mas_equalTo(self.fileInfoLabel.mas_bottom).offset(10);
        
        
    }];
    [self.remainLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.fileInfoLabel);
        make.top.mas_equalTo(self.spreedlabel.mas_bottom).offset(10);
        
    }];
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.remainLabel);
        make.top.mas_equalTo(self.remainLabel.mas_bottom).offset(10);
        make.width.mas_equalTo(self.fileInfoLabel.mas_width);
        
    }];
    [self.contentView layoutIfNeeded];
    [self.streamButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.progressView.mas_left);
        make.top.mas_equalTo(self.progressView.mas_bottom).offset(10);
        if (self.fileInfoLabel.frame.size.height == 0) {
            make.top.mas_equalTo(self.contentView).offset(10);
        }
        
    }];
    
    
}

@end
