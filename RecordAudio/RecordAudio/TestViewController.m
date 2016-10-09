//
//  TestViewController.m
//  RecordAudio
//
//  Created by 赵铭 on 16/9/27.
//  Copyright © 2016年 zziazm. All rights reserved.
//

#import "TestViewController.h"
#import "ZZAudioRecorderUtil.h"
#import "ZZAudioPlayerUtil.h"
#import "CustomCellModel.h"
#import "CustomCell.h"
@interface TestViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) NSMutableArray * datasource;
@property (nonatomic, strong) CustomCellModel * previousSelectedModel;

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height -44) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
       
    UIToolbar * toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 44, [UIScreen mainScreen].bounds.size.width, 44)];
    [self.view addSubview:toolbar];
    UIButton * button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, 0, 100, 30);
    button.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, 22);
    [button setTitle:@"开始录音" forState:UIControlStateNormal];
    [toolbar addSubview:button];
    [button addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(touchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
    [button addTarget:self action:@selector(touchDragEnter:) forControlEvents:UIControlEventTouchDragEnter];
    [button addTarget:self action:@selector(touchDragExit:) forControlEvents:UIControlEventTouchDragExit];
    [button addTarget:self action:@selector(touchDragInside:) forControlEvents:UIControlEventTouchDragInside];
    [button addTarget:self action:@selector(touchDragOutside:) forControlEvents:UIControlEventTouchDragOutside];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"CustomCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"cell"];
    _datasource = @[].mutableCopy;

    // Do any additional setup after loading the view.
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
    if ([ZZAudioPlayerUtil shareInstance].audioPlayer.isPlaying) {
        if (model == _previousSelectedModel) {//选中的是正在播放的语音
            model.isPlaying = NO;
            [[ZZAudioPlayerUtil shareInstance] stopCurrentPlaying];
        }
        else{
            _previousSelectedModel.isPlaying = NO;
            model.isPlaying = YES;
            _previousSelectedModel = model;
            [[ZZAudioPlayerUtil shareInstance] stopCurrentPlaying];
            [self playAudioWithModel:model];
            //            [self playAudioWithURL:model.audioURL];
            
        }
    }
    else{
        _previousSelectedModel = model;
        _previousSelectedModel.isPlaying = YES;
        //        _previousSelectedModel.isPlaying = YES;
        [self playAudioWithModel:model];
        //        [self playAudioWithURL:model.audioURL];
    }
    //    [tableView reloadData];
}
- (void)playAudioWithModel:(CustomCellModel *)model{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.tableView reloadData];
    [[ZZAudioPlayerUtil shareInstance] asyncPlayingWithPath:model.audioPath completion:^(NSError *error) {
        _previousSelectedModel.isPlaying = NO;
        [self.tableView reloadData];
    }];
}

#pragma mark -- Action
- (IBAction)touchDown:(id)sender {
    NSString * url = NSTemporaryDirectory();
    url = [url stringByAppendingString:[NSString stringWithFormat:@"%f.wav", [[NSDate date] timeIntervalSince1970]]];
    ZZAudioRecorderUtil * util = [ZZAudioRecorderUtil shareInstance];
    [util startRecoredWithPath:url completion:^(NSError *error) {
       
    }];
}

- (IBAction)touchUpInside:(id)sender {
    NSLog(@"%s", __func__);
    ZZAudioRecorderUtil * util = [ZZAudioRecorderUtil  shareInstance];
    [util stopRecorderWithCompletion:^(NSString *recoredPath) {
        CustomCellModel * model = [[CustomCellModel alloc] init];
//        model.audioURL = [NSURL fileURLWithPath:recoredPath];
        model.audioPath = recoredPath;
        [_datasource addObject:model];
        [_tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_datasource.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];

    }];
}

- (IBAction)touchUpOutside:(id)sender {

}

- (IBAction)touchDragEnter:(id)sender {
//    _label.text = @"手指上划，取消录音";
//    NSLog(@"%s", __func__);
    
}

- (IBAction)touchDragExit:(id)sender {
//    _label.text = @"松开手指，取消录音";
//    NSLog(@"%s", __func__);
    
}

- (IBAction)touchDragInside:(id)sender {
    NSLog(@"%s", __func__);
    
}
- (IBAction)touchDragOutside:(id)sender {
    NSLog(@"%s", __func__);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
