//
//  ZZAudioRecorderUtil.h
//  RecordAudio
//
//  Created by 赵铭 on 16/9/27.
//  Copyright © 2016年 zziazm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface ZZAudioRecorderUtil : NSObject
@property (nonatomic, strong) AVAudioRecorder * audioRecorder;
@property (nonatomic, copy) NSDictionary * recoredSettings;
+ (id)shareInstance;

- (void)startRecoredWithPath:(NSString *)path
                  completion:(void(^)(NSError *error))completion;
- (void)stopRecorderWithCompletion:(void(^)(NSString *recoredPath))completion;
- (void)cancelCurrentRecording;

@end
