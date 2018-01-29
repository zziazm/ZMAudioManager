//
//  ZMAudioRecorderUtil.h
//  RecordAudio
//
//  Created by 赵铭 on 16/9/27.
//  Copyright © 2016年 zm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface ZMAudioRecorderUtil : NSObject
@property (nonatomic, strong) AVAudioRecorder * audioRecorder;
@property (nonatomic, copy) NSDictionary * recoredSettings;
+ (ZMAudioRecorderUtil  *)shareInstance;
// 开始录音
+ (void)startRecordingWithPreparePath:(NSString *)aFilePath
                                completion:(void(^)(NSError *error))completion;
// 停止录音
+(void)stopRecordingWithCompletion:(void(^)(NSString *recordPath))completion;

// 取消录音
+(void)cancelCurrentRecording;

+(AVAudioRecorder *)audioRecorder;

- (void)startRecoredWithPath:(NSString *)path
                  completion:(void(^)(NSError *error))completion;
- (void)stopRecorderWithCompletion:(void(^)(NSString *recoredPath))completion;
- (void)cancelCurrentRecording;

@end
