//
//  CustomCell.m
//  RecordAudio
//
//  Created by 赵铭 on 16/8/29.
//  Copyright © 2016年 zziazm. All rights reserved.
//

#import "CustomCell.h"

@implementation CustomCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.playImageView.animationImages = @[[UIImage imageNamed:@"p-1"], [UIImage imageNamed:@"p-2"],[UIImage imageNamed:@"p-3"]];
    self.playImageView.animationDuration = 2;
    self.playImageView.image= [UIImage imageNamed:@"p-3"];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
