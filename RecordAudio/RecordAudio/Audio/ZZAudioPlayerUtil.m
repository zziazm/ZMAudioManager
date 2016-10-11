//
//  ZZAudioPlayerUtil.m
//  RecordAudio
//
//  Created by 赵铭 on 16/10/9.
//  Copyright © 2016年 zziazm. All rights reserved.
//

#import "ZZAudioPlayerUtil.h"

@interface ZZAudioPlayerUtil ()<AVAudioPlayerDelegate>
@property (nonatomic, copy) void(^playFinish)(NSError * error);
@end

@implementation ZZAudioPlayerUtil

+ (ZZAudioPlayerUtil *)shareInstance{
    static dispatch_once_t onceToken;
    static ZZAudioPlayerUtil *audioPlayerUtil = nil;
    dispatch_once(&onceToken, ^{
        audioPlayerUtil = [[self alloc] init];
    });
    return audioPlayerUtil;
}

// 播放指定路径下音频（wav）
+ (void)playAudioWithPath:(NSString *)aFilePath
                  completion:(void(^)(NSError *error))completon{
    [[ZZAudioPlayerUtil shareInstance] playAudioWithPath:aFilePath completion:completon];
}
- (void)playAudioWithPath:(NSString *)aFilePath
                  completion:(void(^)(NSError *error))completon{
    NSFileManager * fm = [NSFileManager defaultManager];
    _playFinish = completon;
    NSError *error = nil;
    if (![fm fileExistsAtPath:aFilePath]) {
        error = [NSError errorWithDomain:@"file path not exist" code:0 userInfo:nil];
        if (_playFinish) {
            _playFinish(error);
        }

        return;
    }
    NSURL *wavUrl = [[NSURL alloc] initFileURLWithPath:aFilePath];
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:wavUrl error:&error];
    if (error || !_audioPlayer) {
        error = [NSError errorWithDomain:NSLocalizedString(@"error.initPlayerFail", @"Failed to initialize AVAudioPlayer")
                                    code:0
                                userInfo:nil];
        if (_playFinish) {
            _playFinish(error);
        }
        _playFinish = nil;
        return;
    }
    _audioPlayer.delegate = self;
    [_audioPlayer prepareToPlay];
    [_audioPlayer play];
    
}
// 停止当前播放
+ (void)stopCurrentPlaying{
    [[ZZAudioPlayerUtil shareInstance] stopCurrentPlaying];
}
- (void)stopCurrentPlaying{
    if(_audioPlayer){
        _audioPlayer.delegate = nil;
        [_audioPlayer stop];
        _audioPlayer = nil;
    }
    if (_playFinish) {
        _playFinish = nil;
    }
}
#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
                       successfully:(BOOL)flag{
    if (_playFinish) {
        _playFinish(nil);
    }
    if (_audioPlayer) {
        _audioPlayer.delegate = nil;
        _audioPlayer = nil;
    }
    _playFinish = nil;
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player
                                 error:(NSError *)error{
    if (_playFinish) {
        NSError *error = [NSError errorWithDomain:NSLocalizedString(@"error.palyFail", @"Play failure")
                                             code:0
                                         userInfo:nil];
        _playFinish(error);
    }
    if (_audioPlayer) {
        _audioPlayer.delegate = nil;
        _audioPlayer = nil;
    }
}



@end
