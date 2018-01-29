//
//  ZMDeviceManager.h
//  RecordAudio
//
//  Created by 赵铭 on 16/10/10.
//  Copyright © 2016年 zm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol ZMAudioManagerDelegate <NSObject>

- (void)proximitySensorChanged:(BOOL)isCloseToUser;

@end


@interface ZMAudioManager : NSObject

+ (ZMAudioManager *)shareInstance;

#pragma mark - AudioRecorder
// 开始录音
- (void)startRecordingWithFileName:(NSString *)fileName
                             completion:(void(^)(NSError *error))completion;

// 停止录音
-(void)stopRecordingWithCompletion:(void(^)(NSString *recordPath,
                                                 NSInteger aDuration,
                                                 NSError *error))completion;
// 取消录音
-(void)cancelCurrentRecording;


// 当前是否正在录音
-(BOOL)isRecording;

// 判断麦克风是否可用
- (BOOL)checkMicrophoneAvailability;

// 获取录制音频时的音量(0~1)
- (double)peekRecorderVoiceMeter;

// 播放音频
- (void)playAudioWithPath:(NSString *)aFilePath
               completion:(void(^)(NSError *error))completon;
// 停止播放
- (void)stopPlaying;

// 当前是否正在播放
-(BOOL)isPlaying;

#pragma mark - proximity sensor

@property (nonatomic, weak) id<ZMAudioManagerDelegate>delegate;
@property (nonatomic, readonly) BOOL isSupportProximitySensor;//是否支持距离传感器
@property (nonatomic, readonly) BOOL isCloseToUser;
@property (nonatomic, readonly) BOOL isProximitySensorEnabled;

- (BOOL)enableProximitySensor;
- (BOOL)disableProximitySensor;
- (void)sensorStateChanged:(NSNotification *)notification;


@end
