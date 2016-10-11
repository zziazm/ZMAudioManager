//
//  ZZDeviceManager.h
//  RecordAudio
//
//  Created by 赵铭 on 16/10/10.
//  Copyright © 2016年 zziazm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface ZZDeviceManager : NSObject{
    // recorder
    NSDate              *_recorderStartDate;
    NSDate              *_recorderEndDate;
    NSString            *_currCategory;
    BOOL                _currActive;
    
    // proximitySensor
    BOOL _isSupportProximitySensor;
    BOOL _isCloseToUser;
}

+ (ZZDeviceManager *)shareInstance;
// 播放音频
- (void)playAudioWithPath:(NSString *)aFilePath
                  completion:(void(^)(NSError *error))completon;
// 停止播放
- (void)stopPlaying;

//- (void)stopPlayingWithChangeCategory:(BOOL)isChange;

// 当前是否正在播放
-(BOOL)isPlaying;

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


@end
