//
//  SplashController.m
//  MyCloudMusic
//
//  Created by 林立伟 on 2023/1/5.
//

#import "SplashController.h"
#import "AppDelegate.h"

@interface SplashController ()

@end

@implementation SplashController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // [[SceneDelegate shared] toLoginHome];
    // [SceneDelegate.shared toLoginHome];
    // 延时3秒执行
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [AppDelegate.shared toLoginHome];
    });
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
