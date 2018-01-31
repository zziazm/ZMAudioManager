# TestAudioDemo

开始录音

```
[[ZMAudioManager shareInstance] startRecordingWithFileName:[NSString stringWithFormat:@"%f.wav", [[NSDate date] timeIntervalSince1970]] completion:^(NSError *error) {
    if (error) {

    else{

    }
}];
```
 
 停止录音,recordPath是录音文件存放的路径，aDuration是录音时长
```
 [[ZMAudioManager  shareInstance] stopRecordingWithType:ZMAudioRecordeWAVType completion:^(NSString *recordPath, NSInteger aDuration, NSError *error) {
        if (error) {
            UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"error" message:error.domain delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
            [a show];
        }else{
       
        }
    }];
```
 播放录音,audioPath是录音文件存放的路径，录音播放完后会走completion回调
```
 [[ZMAudioManager shareInstance] playAudioWithPath:audioPath completion:^(NSError *error) {
 
 
  }];
```

