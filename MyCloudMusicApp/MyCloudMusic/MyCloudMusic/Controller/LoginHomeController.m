//
//  LoginHomeController.m
//  MyCloudMusic
//
//  Created by 林立伟 on 2023/1/5.
//

#import "LoginHomeController.h"

@interface LoginHomeController ()
 

/// 主按钮
@property (weak, nonatomic) IBOutlet UIButton *primaryButton;

@end

@implementation LoginHomeController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 圆角
    self.primaryButton.layer.cornerRadius = 21; // 可参考按钮高度的一般
    
    // 边框
    self.primaryButton.layer.borderColor = [UIColor colorNamed: @"Primary"].CGColor;
    self.primaryButton.layer.borderWidth = 1;
}


/// 主按钮
/// - Parameter sender: <#sender description#>
- (IBAction)primaryClick:(UIButton *)sender {
    NSLog(@"LoginHomeController primaryClick");
}

@end
