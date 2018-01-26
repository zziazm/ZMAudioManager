//
//  ZMDeviceManager.m
//  RecordAudio
//
//  Created by 赵铭 on 16/10/10.
//  Copyright © 2016年 ZMiazm. All rights reserved.
//

#import "ZMDeviceManager.h"
#import "ZMAudioPlayerUtil.h"
#import "ZMAudioRecorderUtil.h"

typedef NS_ENUM(NSUInteger, ZMAudioSession) {
    ZM_DEFAULT = 0,
    ZM_AUDIOPLAYER,
    ZM_AUDIORECORDER,
};

@interface ZMDeviceManager()

@end

@implementation ZMDeviceManager
{
    // recorder
    NSDate              *_recorderStartDate;
    NSDate              *_recorderEndDate;
    NSString            *_currCategory;
    BOOL                _currActive;
    
    // proximitySensor
    BOOL _isSupportProximitySensor;
    BOOL _isCloseToUser;
}

+ (ZMDeviceManager *)shareInstance{
    static dispatch_once_t onceToken;
    static ZMDeviceManager * manager;
    dispatch_once(&onceToken, ^{
        manager = [[ZMDeviceManager alloc] init];
    });
    return manager;
}
- (id)init{
    if (self = [super init]) {
        [self determineSupportProximitySensor];
        [self registerNotifications];
    }
    return self;
}
#pragma mark -- AudioPlayer
// 播放音频
- (void)playAudioWithPath:(NSString *)aFilePath
               completion:(void(^)(NSError *error))completon{
    BOOL isNeedSetActive = YES;
    // 如果正在播放音频，停止当前播放。
    if([ZMAudioPlayerUtil shareInstance].audioPlayer.isPlaying){
        [[ZMAudioPlayerUtil shareInstance] stopCurrentPlaying];
        isNeedSetActive = NO;
    }
    
    if (isNeedSetActive) {
        // 设置播放时需要的category
        [self setupAudioSessionCategory:ZM_AUDIOPLAYER
                               isActive:YES];
    }
    NSString *wavFilePath = [[aFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"wav"];
    //如果转换后的wav文件不存在, 则去转换一下
    [ZMAudioPlayerUtil playAudioWithPath:wavFilePath
                                 completion:^(NSError *error)
     {
         [self setupAudioSessionCategory:ZM_DEFAULT
                                isActive:NO];
         if (completon) {
             completon(error);
         }
     }];
}

// 停止播放
- (void)stopPlaying{
    [ZMAudioPlayerUtil stopCurrentPlaying];
    [self setupAudioSessionCategory:ZM_DEFAULT
                           isActive:NO];

}

//- (void)stopPlayingWithChangeCategory:(BOOL)isChange;
// 当前是否正在播放
-(BOOL)isPlaying{
    return [ZMAudioPlayerUtil shareInstance].audioPlayer.isPlaying;
}




#pragma mark - AudioRecorder
+(NSTimeInterval)recordMinDuration{
    return 1.0;
}

// 开始录音
- (void)startRecordingWithFileName:(NSString *)fileName
                        completion:(void(^)(NSError *error))completion{
    NSError *error = nil;
    if (![[ZMDeviceManager shareInstance] checkMicrophoneAvailability]) {
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
        [[ZMAudioRecorderUtil shareInstance] cancelCurrentRecording];
        isNeedSetActive = NO;
    }
    [self setupAudioSessionCategory:ZM_AUDIORECORDER
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
    ZMAudioRecorderUtil * recorderUtil = [ZMAudioRecorderUtil shareInstance];
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
    
    if([_recorderEndDate timeIntervalSinceDate:_recorderStartDate] < [ZMDeviceManager recordMinDuration]){
        if (completion) {
            error = [NSError errorWithDomain:@"Recording time is too short"
                                        code:0
                                    userInfo:nil];
            completion(nil,0,error);
        }
        
        // 如果录音时间较短，延迟1秒停止录音（iOS中，如果快速开始，停止录音，UI上会出现红条,为了防止用户又迅速按下，UI上需要也加一个延迟，长度大于此处的延迟时间，不允许用户循序重新录音。PS:研究了QQ和微信，就这么玩的,聪明）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([ZMDeviceManager recordMinDuration] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            ZMAudioRecorderUtil * ru = [ZMAudioRecorderUtil shareInstance];
            [ru stopRecorderWithCompletion:^(NSString *recoredPath) {
                [weakSelf setupAudioSessionCategory:ZM_DEFAULT isActive:NO];

            }];
            
        });
        return ;
    }
    ZMAudioRecorderUtil * ru = [ZMAudioRecorderUtil shareInstance];
    [ru stopRecorderWithCompletion:^(NSString *recoredPath) {
        if (completion) {
            if (recoredPath) {
                completion(recoredPath,(int)[self->_recorderEndDate timeIntervalSinceDate:self->_recorderStartDate],nil);
            }
            [weakSelf setupAudioSessionCategory:ZM_DEFAULT isActive:NO];
        }

    }];
}
// 取消录音
-(void)cancelCurrentRecording{
    ZMAudioRecorderUtil * ru = [ZMAudioRecorderUtil shareInstance];
    [ru cancelCurrentRecording];
}


// 当前是否正在录音
-(BOOL)isRecording{
    ZMAudioRecorderUtil * ru = [ZMAudioRecorderUtil shareInstance];
    return  ru.audioRecorder.recording;
}

#pragma mark - Private
-(NSError *)setupAudioSessionCategory:(ZMAudioSession)session
                             isActive:(BOOL)isActive{
    BOOL isNeedActive = NO;
    if (isActive != _currActive) {
        isNeedActive = YES;
        _currActive = isActive;
    }
    NSError *error = nil;
    NSString *audioSessionCategory = nil;
    switch (session) {
        case ZM_AUDIOPLAYER:
            // 设置播放category
            audioSessionCategory = AVAudioSessionCategoryPlayback;
            break;
        case ZM_AUDIORECORDER:
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
    if ([ZMAudioRecorderUtil audioRecorder].isRecording) {
        [[ZMAudioRecorderUtil audioRecorder] updateMeters];
        //获取音量的平均值  [recorder averagePowerForChannel:0];
        //音量的最大值  [recorder peakPowerForChannel:0];
        double lowPassResults = pow(10, (0.05 * [[ZMAudioRecorderUtil audioRecorder] peakPowerForChannel:0]));
        ret = lowPassResults;
    }
    return ret;

}


#pragma mark - proximity sensor
//判断是否支持距离传感器
//不是所有的设备都有距离传感器，为了判断设备是否支持距离监测，可以先把proximityMonitoringEnabled设为YES，然后再取出这个值，如果是支持的，则这个值为YES；如果不支持，则这个值始终是NO
- (void)determineSupportProximitySensor
{
    UIDevice *device = [UIDevice currentDevice];
    [device setProximityMonitoringEnabled:YES];
    _isSupportProximitySensor = device.proximityMonitoringEnabled;
    if (_isSupportProximitySensor) {
        [device setProximityMonitoringEnabled:NO];
    } else {
        
    }
}
- (void)registerNotifications
{
    [self unregisterNotifications];
    if (_isSupportProximitySensor) {
        static NSString *notif = @"UIDeviceProximityStateDidChangeNotification";
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sensorStateChanged:)
                                                     name:notif
                                                   object:nil];
    }
}

- (void)unregisterNotifications {
    if (_isSupportProximitySensor) {
        static NSString *notif = @"UIDeviceProximityStateDidChangeNotification";
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:notif
                                                      object:nil];
    }
}


- (BOOL)isProximitySensorEnabled {
    BOOL ret = NO;
    ret = self.isSupportProximitySensor && [UIDevice currentDevice].proximityMonitoringEnabled;
    
    return ret;
}

- (BOOL)enableProximitySensor {
    BOOL ret = NO;
    if (_isSupportProximitySensor) {
        [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
        ret = YES;
    }
    
    return ret;
}

- (BOOL)disableProximitySensor {
    BOOL ret = NO;
    if (_isSupportProximitySensor) {
        [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
        _isCloseToUser = NO;
        ret = YES;
    }
    
    return ret;
}

- (void)sensorStateChanged:(NSNotification *)notification {
    BOOL ret = NO;
    if ([[UIDevice currentDevice] proximityState] == YES) {
        ret = YES;
    }
    _isCloseToUser = ret;
    if([self.delegate respondsToSelector:@selector(proximitySensorChanged:)]){
        [self.delegate proximitySensorChanged:_isCloseToUser];
    }
}

#pragma mark - getter
- (BOOL)isCloseToUser {
    return _isCloseToUser;
}

- (BOOL)isSupportProximitySensor {
    return _isSupportProximitySensor;
}

- (void)dealloc{
    [self unregisterNotifications];
}


@end
