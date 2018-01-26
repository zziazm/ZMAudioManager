//
//  ZMAudioPlayerUtil.h
//  RecordAudio
//
//  Created by 赵铭 on 16/10/9.
//  Copyright © 2016年 ZMiazm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface ZMAudioPlayerUtil : NSObject
@property (nonatomic, strong) AVAudioPlayer * audioPlayer;
+ (ZMAudioPlayerUtil *)shareInstance;
// 播放指定路径下音频（wav）
+ (void)playAudioWithPath:(NSString *)aFilePath
                  completion:(void(^)(NSError *error))completon;
- (void)playAudioWithPath:(NSString *)aFilePath
                  completion:(void(^)(NSError *error))completon;

// 停止当前播放音频
+ (void)stopCurrentPlaying;
- (void)stopCurrentPlaying;
@end
