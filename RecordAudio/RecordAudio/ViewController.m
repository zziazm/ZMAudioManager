//
//  ViewController.m
//  RecordAudio
//
//  Created by 赵铭 on 16/8/29.
//  Copyright © 2016年 zziazm. All rights reserved.
//

#import "ViewController.h"
#import "CustomCell.h"
#import <AVFoundation/AVFoundation.h>
#import "CustomCellModel.h"
@interface ViewController ()<AVAudioRecorderDelegate, UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate>
@property (nonatomic, strong) AVAudioRecorder * audioRecorder;
@property (nonatomic, strong) AVAudioPlayer * audioPlayer;
@property (nonatomic, strong) AVAudioSession * audioSession;
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (nonatomic, strong) NSMutableArray * datasource;
@property (nonatomic, strong) CustomCellModel * previousSelectedModel;
@property (nonatomic, strong) NSTimer * metesTimer;
@property (nonatomic, strong) UIImageView * recoredAnimationView;
@property (nonatomic, strong) UILabel * label;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _recoredAnimationView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    _recoredAnimationView.center = self.view.center;
    [self.view addSubview:_recoredAnimationView];
    _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
    _label.center = CGPointMake(_recoredAnimationView.center.x, _recoredAnimationView.center.y + 70);
    _recoredAnimationView.hidden = YES;
    _label.text= @"长按按钮开始录音";
    [self.view addSubview:_label];
    _audioSession = [AVAudioSession sharedInstance];
    [self.tableview registerNib:[UINib nibWithNibName:@"CustomCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"cell"];
    self.tableview.tableFooterView = [UIView new];
    _datasource = @[].mutableCopy;
   }

#pragma mark -- UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _datasource.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    CustomCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    CustomCellModel * model = _datasource[indexPath.row];
    if (model.isPlaying) {
        [cell.playImageView startAnimating];
    }
    else{
        [cell.playImageView stopAnimating];
    }
    return cell;
}

#pragma mark -- UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    CustomCellModel * model = _datasource[indexPath.row];
    if (self.audioPlayer.isPlaying) {
        if (model == _previousSelectedModel) {//选中的是正在播放的语音
            model.isPlaying = NO;
            [self.audioPlayer stop];
        }
        else{
            _previousSelectedModel.isPlaying = NO;
            model.isPlaying = YES;
            _previousSelectedModel = model;
            [self.audioPlayer stop];
            [self playAudioWithURL:model.audioURL];
           
        }
    }
    else{
        _previousSelectedModel = model;
        _previousSelectedModel.isPlaying = YES;
        [self playAudioWithURL:model.audioURL];
    }
    [tableView reloadData];
}
- (void)playAudioWithURL:(NSURL *)url{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    NSError * error;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    self.audioPlayer.delegate = self;
    BOOL success = [self.audioPlayer play];
    if (success) {
        NSLog(@"播放成功");
    }else{
        NSLog(@"播放失败");
    }
}
#pragma mark -- Action
- (IBAction)touchDown:(id)sender {
    NSLog(@"%s", __func__);
    NSError * error;
    NSString * url = NSTemporaryDirectory();
    url = [url stringByAppendingString:[NSString stringWithFormat:@"%f.wav", [[NSDate date] timeIntervalSince1970]]];
    NSMutableDictionary * settings = @{}.mutableCopy;
    [settings setObject:[NSNumber numberWithFloat:8000.0] forKey:AVSampleRateKey];//采样率，8000是电话采样率，对一般的录音已经足够了
    [settings setObject:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey:AVFormatIDKey];    [settings setObject:@1 forKey:AVNumberOfChannelsKey];//设置成一个通道，iPnone只有一个麦克风，一个通道已经足够了
    [settings setObject:@16 forKey:AVLinearPCMBitDepthKey];//采样的位数
    self.audioRecorder = [[AVAudioRecorder  alloc] initWithURL:[NSURL fileURLWithPath:url] settings:settings error:&error];
    self.audioRecorder.meteringEnabled = YES;
    self.audioRecorder.delegate = self;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
    BOOL success = [self.audioRecorder record];
    if (success) {
        _metesTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(setVoiceImage) userInfo:nil repeats:YES];
        _label.text = @"手指上划，取消录音";
        NSLog(@"录音开始成功");
    }else{
        NSLog(@"录音开始失败");
    }
}

- (IBAction)touchUpInside:(id)sender {
    NSLog(@"%s", __func__);
    [self.audioRecorder stop];
}

- (IBAction)touchUpOutside:(id)sender {
    NSLog(@"%s", __func__);
    _label.text = @"长按按钮开始录音";
    self.audioRecorder.delegate = nil;
    [self.audioRecorder stop];
    self.audioRecorder = nil;
}

- (IBAction)touchDragEnter:(id)sender {
    _label.text = @"手指上划，取消录音";
    NSLog(@"%s", __func__);

}

- (IBAction)touchDragExit:(id)sender {
    _label.text = @"松开手指，取消录音";
    NSLog(@"%s", __func__);
    
}

- (IBAction)touchDragInside:(id)sender {
    NSLog(@"%s", __func__);
    
}
- (IBAction)touchDragOutside:(id)sender {
    NSLog(@"%s", __func__);
}

- (void)setVoiceImage{
    if (self.audioRecorder.isRecording) {
        [self.audioRecorder updateMeters];
        _recoredAnimationView.hidden = NO;
        float peakPower = [self.audioRecorder peakPowerForChannel:0];
//        NSLog(@"aaaaaa%f", peakPower);
        double voiceSound = pow(10, (0.05 * peakPower));
        if (0 < voiceSound <= 0.05) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback001"]];
        }else if (0.05<voiceSound<=0.10) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback002"]];
        }else if (0.10<voiceSound<=0.15) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback003"]];
        }else if (0.15<voiceSound<=0.20) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback004"]];
        }else if (0.20<voiceSound<=0.25) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback005"]];
        }else if (0.25<voiceSound<=0.30) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback006"]];
        }else if (0.30<voiceSound<=0.35) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback007"]];
        }else if (0.35<voiceSound<=0.40) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback008"]];
        }else if (0.40<voiceSound<=0.45) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback009"]];
        }else if (0.45<voiceSound<=0.50) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback010"]];
        }else if (0.50<voiceSound<=0.55) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback011"]];
        }else if (0.55<voiceSound<=0.60) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback012"]];
        }else if (0.60<voiceSound<=0.65) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback013"]];
        }else if (0.65<voiceSound<=0.70) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback014"]];
        }else if (0.70<voiceSound<=0.75) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback015"]];
        }else if (0.75<voiceSound<=0.80) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback016"]];
        }else if (0.80<voiceSound<=0.85) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback017"]];
        }else if (0.85<voiceSound<=0.90) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback018"]];
        }else if (0.90<voiceSound<=0.95) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback019"]];
        }else {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback020"]];
        }
    }
}
#pragma mark -- AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    NSLog(@"%s", __func__);
    _recoredAnimationView.hidden = YES;
    NSString * url = recorder.url.path;
    self.audioRecorder.delegate = nil;
    self.audioRecorder = nil;
    CustomCellModel * model = [[CustomCellModel alloc] init];
    model.audioURL = recorder.url;
    [_datasource addObject:model];
    [_tableview insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_datasource.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error{
    NSLog(@"%@", error);
}

#pragma mark -- AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"%s", __func__);
    self.audioPlayer.delegate = nil;
    self.audioPlayer = nil;
    _previousSelectedModel.isPlaying = NO;
    [self.tableview reloadData];
    
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error{
    NSLog(@"%@", error);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
