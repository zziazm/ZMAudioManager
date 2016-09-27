//
//  tViewController.m
//  RecordAudio
//
//  Created by 赵铭 on 16/9/19.
//  Copyright © 2016年 zziazm. All rights reserved.
//

#import "tViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>

@interface tViewController ()

@end

@implementation tViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [self configAuthButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - config

- (void)configAuthButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"请验证指纹" forState:UIControlStateNormal];
    [btn setFrame:CGRectMake(CGRectGetWidth(self.view.frame)/2-100, 100, 200, 30)];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(authBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

#pragma mark - event

- (void)authBtnTouch:(UIButton *)sender {
    NSError *error = nil;
    NSString *reason = @"验证touchID";
    //No.1
    LAContext *context = [LAContext new];

    //开始写代码，实现TouchID的验证，用警告框进行提示。
    if (![context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil]) {
        NSLog(@"对不起, 指纹识别技术暂时不可用");
    }
    
    //4. 开始使用指纹识别
    //localizedReason: 指纹识别出现时的提示文字, 一般填写为什么使用指纹识别
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"开启了指纹识别, 将打开隐藏功能" reply:^(BOOL success, NSError * _Nullable error) {
        
        if (success) {
            NSLog(@"指纹识别成功");
            // 指纹识别成功，回主线程更新UI,弹出提示框
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"指纹识别成功" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
                [alertView show];
            });
            
        }
        
        if (error) {
            
            // 错误的判断chuli
            
            if (error.code == -2) {
                NSLog(@"用户取消了操作");
                
                // 取消操作，回主线程更新UI,弹出提示框
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"用户取消了操作" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
                    [alertView show];
                    
                });
                
            } else {
                NSLog(@"错误: %@",error);
                // 指纹识别出现错误，回主线程更新UI,弹出提示框
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:error delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
                [alertView show];
            }
            
        }
        
    }];

    
    
    
    
    
    
    
    
    //end_code
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
