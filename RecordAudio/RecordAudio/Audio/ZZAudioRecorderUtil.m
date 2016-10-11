//
//  ZZAudioRecorderUtil.m
//  RecordAudio
//
//  Created by 赵铭 on 16/9/27.
//  Copyright © 2016年 zziazm. All rights reserved.
//

#import "ZZAudioRecorderUtil.h"

@interface ZZAudioRecorderUtil()<AVAudioRecorderDelegate>
@property (nonatomic, copy) void(^recoredFinish)(NSString * recoredPath);
@end


@implementation ZZAudioRecorderUtil
+ (ZZAudioRecorderUtil *)shareInstance{
    static ZZAudioRecorderUtil * instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ZZAudioRecorderUtil alloc] init];
    });
    return instance;
}

// 开始录音
+ (void)startRecordingWithPreparePath:(NSString *)aFilePath
                           completion:(void(^)(NSError *error))completion{
    [[ZZAudioRecorderUtil shareInstance] startRecoredWithPath:aFilePath completion:completion];
}
// 停止录音
+(void)stopRecordingWithCompletion:(void(^)(NSString *recordPath))completion{
    [[ZZAudioRecorderUtil shareInstance] stopRecorderWithCompletion:completion];
}


// 取消录音
+(void)cancelCurrentRecording{
    [[ZZAudioRecorderUtil shareInstance] cancelCurrentRecording];
}
+(AVAudioRecorder *)audioRecorder{
    return [ZZAudioRecorderUtil shareInstance].audioRecorder;
}


- (NSDictionary *)recoredSettings{
    if (!_recoredSettings) {
        _recoredSettings = @{AVSampleRateKey:[NSNumber numberWithFloat:8000],
                             AVFormatIDKey:[NSNumber numberWithInt: kAudioFormatLinearPCM],
                             AVLinearPCMBitDepthKey:[NSNumber numberWithInt:16],
                             AVNumberOfChannelsKey:[NSNumber numberWithInt:1],
                             };
    }
    return _recoredSettings;
}

- (void)startRecoredWithPath:(NSString *)path
                  completion:(void(^)(NSError *error))completion{
    NSError *error = nil;
    NSString *wavFilePath = [[path stringByDeletingPathExtension]
                             stringByAppendingPathExtension:@"wav"];
    NSURL *wavUrl = [[NSURL alloc] initFileURLWithPath:wavFilePath];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:wavUrl
                                            settings:self.recoredSettings
                                               error:&error];
    _audioRecorder.meteringEnabled = YES;
    _audioRecorder.delegate = self;

    if (!_audioRecorder || error ) {
        _audioRecorder = nil;
        if (completion) {
            completion(error);
        }
        return;
    }
    BOOL success = [_audioRecorder record];

    if (completion) {
        completion(nil);
    }
}

- (void)stopRecorderWithCompletion:(void(^)(NSString *recoredPath))completion{
    self.recoredFinish = completion;
    [self.audioRecorder stop];
}
// 取消录音
- (void)cancelCurrentRecording
{
    _audioRecorder.delegate = nil;
    if (_audioRecorder.recording) {
        [_audioRecorder stop];
    }
    _audioRecorder = nil;
    _recoredFinish = nil;
}

#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder
                           successfully:(BOOL)flag
{
    NSString *recordPath = [[recorder url] path];
    if (self.recoredFinish) {
        if (!flag) {
            recordPath = nil;
        }
        self.recoredFinish(recordPath);
    }
    self.audioRecorder = nil;
    self.recoredFinish = nil;
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder
                                   error:(NSError *)error{
    NSLog(@"%@",error);
}



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

@end
