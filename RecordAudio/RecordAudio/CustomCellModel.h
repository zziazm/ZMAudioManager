//
//  CustomCellModel.h
//  RecordAudio
//
//  Created by 赵铭 on 16/8/29.
//  Copyright © 2016年 zziazm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomCellModel : NSObject
@property (nonatomic, copy) NSString * audioPath;
@property (nonatomic, copy) NSURL * audioURL;
@property (nonatomic, assign) BOOL isPlaying;
@end
