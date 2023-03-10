//
//  LoginController.m
//  MyCloudMusic
//
//  Created by 林立伟 on 2023/1/12.
//

#import "LoginController.h"
#import "RegisterController.h"

@interface LoginController ()
@property (nonatomic, strong) UIButton *otherButton;

@end

@implementation LoginController

- (void)viewDidLoad {
    [super viewDidLoad];
    //纯代码方式添加一个按钮，其他控件也类似
    self.otherButton = [UIButton buttonWithType:UIButtonTypeSystem];
    
    //设置标题
    [self.otherButton setTitle:@"纯代码方式添加按钮" forState:UIControlStateNormal];
    [self.otherButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.otherButton setTitleColor:[UIColor greenColor] forState:UIControlStateHighlighted];
    
    //设置点击事件
    // UIControlEventTouchUpInside - 按下在抬起事件
    [self.otherButton addTarget:self action:@selector(otherClcik:) forControlEvents:UIControlEventTouchUpInside ];
    
    self.otherButton.backgroundColor = [UIColor redColor];
    self.otherButton.layer.cornerRadius = 5;
    
    //添加到容器
    [self.view addSubview: self.otherButton];
}

// 布局完成后调用
// 在这里才能获取到控件实际尺寸
-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    //设置按钮宽高
    //在这里才能获取到控件真正布局后的尺寸
    //当然还可以在代码中使用类似可视化中的那种约束
    //只是在iOS很少在代码中直接用系统提供的约束
    //而是使用第三方框架，因为用起来更方便
    self.otherButton.frame = CGRectMake(16, 600, self.view.frame.size.width - 32, 41);
}

-(void)otherClcik:(UIButton *)sender {
    NSLog(@"LoginController otherClcik");
    // 创建一个控制器
    // 写法1
    RegisterController *target = [RegisterController new];
    // 写法2
    // RegisterController *target = [[RegisterController alloc] init];
    
    // 传递参数
    target.nickname = @"爱学呀";
    
    [self.navigationController pushViewController:target animated:YES];
}

@end
