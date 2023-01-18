//
//  LoginHomeController.m
//  MyCloudMusic
//
//  Created by 林立伟 on 2023/1/5.
//

#import "LoginHomeController.h"
#import "LoginController.h"

@interface LoginHomeController ()
 

/// 主按钮
@property (weak, nonatomic) IBOutlet UIButton *primaryButton;
@property (weak, nonatomic) IBOutlet UIButton *phoneLoginButton;

@end

@implementation LoginHomeController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 圆角
    self.primaryButton.layer.cornerRadius = 21; // 可参考按钮高度的一般
    self.phoneLoginButton.layer.cornerRadius = 21; // 可参考按钮高度的一般
    
    // 边框
    self.primaryButton.layer.borderColor = [UIColor colorNamed: @"Primary"].CGColor;
    self.primaryButton.layer.borderWidth = 1;
}

/// 手机号登录按钮
/// - Parameter sender: <#sender description#>
- (IBAction)phoneLoginButtonClick:(UIButton *)sender {
    NSLog(@"LoginHomeController phoneLoginButtonClick");

}


/// 主按钮
/// - Parameter sender: <#sender description#>
- (IBAction)primaryClick:(UIButton *)sender {
    NSLog(@"LoginHomeController primaryClick");
    
    // 获取到Main.storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    // 实例化控制器
    UIViewController *target = [storyboard instantiateViewControllerWithIdentifier:@"Login"];
    // 跳转登录页
    [self.navigationController pushViewController:target animated:YES];
}

@end
