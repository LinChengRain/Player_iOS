//
//  VideoCacheListModel.h
//  Pods
//
//  Created by 路鹏 on 2022/3/7.
//  Copyright © 2022年 Tencent. All rights reserved.

#import <Foundation/Foundation.h>
@class TXVodDownloadMediaInfo;

NS_ASSUME_NONNULL_BEGIN

@interface VideoCacheListModel : NSObject

/// cover
/// 封面
@property (nonatomic, strong) NSString *coverImageStr;
/// duration
/// 时长
@property (nonatomic, strong) NSString *durationStr;
/// video name
/// 视频名称
@property (nonatomic, strong) NSString *videoName;
/// Media information
/// 媒体信息
@property (nonatomic, strong) TXVodDownloadMediaInfo *mediaInfo;

@end

NS_ASSUME_NONNULL_END
