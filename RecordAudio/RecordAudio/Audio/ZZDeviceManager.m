//
//  ZZDeviceManager.m
//  RecordAudio
//
//  Created by 赵铭 on 16/10/10.
//  Copyright © 2016年 zziazm. All rights reserved.
//

#import "ZZDeviceManager.h"
#import "ZZAudioPlayerUtil.h"
#import "ZZAudioRecorderUtil.h"

typedef NS_ENUM(NSUInteger, ZZAudioSession) {
    ZZ_DEFAULT = 0,
    ZZ_AUDIOPLAYER,
    ZZ_AUDIORECORDER,
};

@interface ZZDeviceManager()

@end

@implementation ZZDeviceManager
+ (ZZDeviceManager *)shareInstance{
    static dispatch_once_t onceToken;
    static ZZDeviceManager * manager;
    dispatch_once(&onceToken, ^{
        manager = [[ZZDeviceManager alloc] init];
    });
    return manager;
}

#pragma mark -- AudioPlayer
// 播放音频
- (void)playAudioWithPath:(NSString *)aFilePath
               completion:(void(^)(NSError *error))completon{
    BOOL isNeedSetActive = YES;
    // 如果正在播放音频，停止当前播放。
    if([ZZAudioPlayerUtil shareInstance].audioPlayer.isPlaying){
        [[ZZAudioPlayerUtil shareInstance] stopCurrentPlaying];
        isNeedSetActive = NO;
    }
    
    if (isNeedSetActive) {
        // 设置播放时需要的category
        [self setupAudioSessionCategory:ZZ_AUDIOPLAYER
                               isActive:YES];
    }
    NSString *wavFilePath = [[aFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"wav"];
    //如果转换后的wav文件不存在, 则去转换一下
    [ZZAudioPlayerUtil playAudioWithPath:wavFilePath
                                 completion:^(NSError *error)
     {
         [self setupAudioSessionCategory:ZZ_DEFAULT
                                isActive:NO];
         if (completon) {
             completon(error);
         }
     }];
}

// 停止播放
- (void)stopPlaying{
    [ZZAudioPlayerUtil stopCurrentPlaying];
    [self setupAudioSessionCategory:ZZ_DEFAULT
                           isActive:NO];

}

//- (void)stopPlayingWithChangeCategory:(BOOL)isChange;
// 当前是否正在播放
-(BOOL)isPlaying{
    return [ZZAudioPlayerUtil shareInstance].audioPlayer.isPlaying;
}




#pragma mark - AudioRecorder
+(NSTimeInterval)recordMinDuration{
    return 1.0;
}

// 开始录音
- (void)startRecordingWithFileName:(NSString *)fileName
                        completion:(void(^)(NSError *error))completion{
    NSError *error = nil;
    if (![[ZZDeviceManager shareInstance] checkMicrophoneAvailability]) {
        NSLog(@"麦克风不可用");
        return;
    }
   
    // 判断当前是否是录音状态
    if ([self isRecording]) {
        if (completion) {
            error = [NSError errorWithDomain:@"Record voice is not over yet"
                                        code:0
                                    userInfo:nil];
            completion(error);
        }
        return ;
    }
    
    // 文件名不存在
    if (!fileName || [fileName length] == 0) {
        error = [NSError errorWithDomain:@"File path not exist"
                                    code:0
                                userInfo:nil];
        completion(error);
        return ;
    }
    
    BOOL isNeedSetActive = YES;
    if ([self isRecording]) {
        [[ZZAudioRecorderUtil shareInstance] cancelCurrentRecording];
        isNeedSetActive = NO;
    }
    [self setupAudioSessionCategory:ZZ_AUDIORECORDER
                           isActive:YES];
    _recorderStartDate = [NSDate date];
    NSString *recordPath = NSHomeDirectory();
    recordPath = [NSString stringWithFormat:@"%@/Library/appdata/%@",recordPath,fileName];
    NSFileManager *fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:[recordPath stringByDeletingLastPathComponent]]){
        [fm createDirectoryAtPath:[recordPath stringByDeletingLastPathComponent]
      withIntermediateDirectories:YES
                       attributes:nil
                            error:nil];
    }
    ZZAudioRecorderUtil * recorderUtil = [ZZAudioRecorderUtil shareInstance];
    [recorderUtil startRecoredWithPath:recordPath completion:completion];
}

// 停止录音
-(void)stopRecordingWithCompletion:(void(^)(NSString *recordPath,
                                            NSInteger aDuration,
                                            NSError *error))completion{
    NSError *error = nil;
    // 当前是否在录音
    if(![self isRecording]){
        if (completion) {
            error = [NSError errorWithDomain:@"Recording has not yet begun"
                                        code:0
                                    userInfo:nil];
            completion(nil,0,error);
            return;
        }
    }
    
    __weak typeof(self) weakSelf = self;
    _recorderEndDate = [NSDate date];
    
    if([_recorderEndDate timeIntervalSinceDate:_recorderStartDate] < [ZZDeviceManager recordMinDuration]){
        if (completion) {
            error = [NSError errorWithDomain:@"Recording time is too short"
                                        code:0
                                    userInfo:nil];
            completion(nil,0,error);
        }
        
        // 如果录音时间较短，延迟1秒停止录音（iOS中，如果快速开始，停止录音，UI上会出现红条,为了防止用户又迅速按下，UI上需要也加一个延迟，长度大于此处的延迟时间，不允许用户循序重新录音。PS:研究了QQ和微信，就这么玩的,聪明）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([ZZDeviceManager recordMinDuration] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            ZZAudioRecorderUtil * ru = [ZZAudioRecorderUtil shareInstance];
            [ru stopRecorderWithCompletion:^(NSString *recoredPath) {
                [weakSelf setupAudioSessionCategory:ZZ_DEFAULT isActive:NO];

            }];
            
        });
        return ;
    }
    ZZAudioRecorderUtil * ru = [ZZAudioRecorderUtil shareInstance];
    [ru stopRecorderWithCompletion:^(NSString *recoredPath) {
        if (completion) {
            if (recoredPath) {
                completion(recoredPath,(int)[self->_recorderEndDate timeIntervalSinceDate:self->_recorderStartDate],nil);
            }
            [weakSelf setupAudioSessionCategory:ZZ_DEFAULT isActive:NO];
        }

    }];
}
// 取消录音
-(void)cancelCurrentRecording{
    ZZAudioRecorderUtil * ru = [ZZAudioRecorderUtil shareInstance];
    [ru cancelCurrentRecording];
}


// 当前是否正在录音
-(BOOL)isRecording{
    ZZAudioRecorderUtil * ru = [ZZAudioRecorderUtil shareInstance];
    return  ru.audioRecorder.recording;
}

#pragma mark - Private
-(NSError *)setupAudioSessionCategory:(ZZAudioSession)session
                             isActive:(BOOL)isActive{
    BOOL isNeedActive = NO;
    if (isActive != _currActive) {
        isNeedActive = YES;
        _currActive = isActive;
    }
    NSError *error = nil;
    NSString *audioSessionCategory = nil;
    switch (session) {
        case ZZ_AUDIOPLAYER:
            // 设置播放category
            audioSessionCategory = AVAudioSessionCategoryPlayback;
            break;
        case ZZ_AUDIORECORDER:
            // 设置录音category
            audioSessionCategory = AVAudioSessionCategoryRecord;
            break;
        default:
            // 还原category
            audioSessionCategory = AVAudioSessionCategoryAmbient;
            break;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    // 如果当前category等于要设置的，不需要再设置
    if (![_currCategory isEqualToString:audioSessionCategory]) {
        [audioSession setCategory:audioSessionCategory error:nil];
    }
    if (isNeedActive) {
        BOOL success = [audioSession setActive:isActive
                                   withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                         error:&error];
        if(!success || error){
            error = [NSError errorWithDomain:@"Failed to initialize AVAudioPlayer"
                                        code:0
                                    userInfo:nil];
            return error;
        }
    }
    _currCategory = audioSessionCategory;
    
    return error;
}
// 判断麦克风是否可用
- (BOOL)checkMicrophoneAvailability{
    __block BOOL ret = NO;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if ([session respondsToSelector:@selector(requestRecordPermission:)]) {
        [session performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            ret = granted;
        }];
    } else {
        ret = YES;
    }
    
    return ret;

}

// 获取录制音频时的音量(0~1)
- (double)peekRecorderVoiceMeter{
    double ret = 0.0;
    if ([ZZAudioRecorderUtil audioRecorder].isRecording) {
        [[ZZAudioRecorderUtil audioRecorder] updateMeters];
        //获取音量的平均值  [recorder averagePowerForChannel:0];
        //音量的最大值  [recorder peakPowerForChannel:0];
        double lowPassResults = pow(10, (0.05 * [[ZZAudioRecorderUtil audioRecorder] peakPowerForChannel:0]));
        ret = lowPassResults;
    }
    return ret;

}

@end
