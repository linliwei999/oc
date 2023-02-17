//
//  ViewController.m
//  TestMyLayout
//
//  Created by 林立伟 on 2023/2/17.
//

//提供类似Android中更高层级的布局框架
#import <MyLayout/MyLayout.h>

#import "ViewController.h"

@interface ViewController ()
@property (strong, nonatomic) UIButton *phoneLoginButoon;
@property (strong, nonatomic) UIButton *primaryButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //创建一个相对容器
    MyRelativeLayout *container = [MyRelativeLayout new];
//    container.backgroundColor = [UIColor redColor];
    
    // 从安全区开始
    container.leadingPos.equalTo(@(MyLayoutPos.safeAreaMargin)).offset(16);
    container.trailingPos.equalTo(@(MyLayoutPos.safeAreaMargin)).offset(16);
    container.topPos.equalTo(@(MyLayoutPos.safeAreaMargin)).offset(16);
    container.bottomPos.equalTo(@(MyLayoutPos.safeAreaMargin)).offset(16);
    
    [self.view addSubview: container];
    
    // logo
    UIImageView *logoView = [[UIImageView alloc] init];
    logoView.image = [UIImage imageNamed:@"Logo"];
    [container addSubview:logoView];
    
#pragma mark - logo样式
    // 宽高
    logoView.myWidth = 100;
    logoView.heightSize.equalTo(@(100));
    // 距离顶部
    logoView.myTop = 100;
    // 水平居中
    logoView.myCenterX = 0;
    
#pragma mark - 底部容器
    // 创建一个垂直方向容器，类似Android的LinearLayout控件
    MyLinearLayout *bottomContainer = [[MyLinearLayout alloc] initWithOrientation:MyOrientation_Vert];
  
    // 宽度和父布局一样
    bottomContainer.myWidth = MyLayoutSize.fill;
    
    // 高度包裹内容
    bottomContainer.myHeight = MyLayoutSize.wrap;
    
    bottomContainer.myBottom = 0;
    
    // 内容水平居中
    bottomContainer.gravity = MyGravity_Horz_Center;
    
    // 子控件间距
    bottomContainer.subviewSpace = 30;
    
    [container addSubview: bottomContainer];
    
#pragma mark - 手机号按钮
    self.phoneLoginButoon = [UIButton buttonWithType:UIButtonTypeSystem];

    //设置标题
    [self.phoneLoginButoon setTitle:@"手机号登录" forState:UIControlStateNormal];
    //设置点击事件
    [self.phoneLoginButoon addTarget:self action:@selector(phoneLoginClick:) forControlEvents:UIControlEventTouchUpInside];
    // 设置背景颜色
    self.phoneLoginButoon.backgroundColor = [UIColor redColor];
    // 设置圆角
    self.phoneLoginButoon.layer.cornerRadius = 5;
    [self.phoneLoginButoon setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    //按下文本颜色
    [self.phoneLoginButoon setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [bottomContainer addSubview: self.phoneLoginButoon];
    // 宽高
    self.phoneLoginButoon.myWidth = MyLayoutSize.fill;
    self.phoneLoginButoon.myHeight = 42;

    #pragma mark - 登录按钮
    self.primaryButton = [UIButton buttonWithType:UIButtonTypeSystem];

    //设置标题
    [self.primaryButton setTitle:@"用户名和密码登录" forState:UIControlStateNormal];
    [self.primaryButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];

    //设置点击事件
    [self.primaryButton addTarget:self action:@selector(primaryClick:) forControlEvents:UIControlEventTouchUpInside];

    self.primaryButton.backgroundColor = [UIColor clearColor];
    self.primaryButton.layer.cornerRadius = 21;
    self.primaryButton.layer.borderWidth = 1;
    self.primaryButton.layer.borderColor = [UIColor redColor].CGColor;
    [bottomContainer addSubview: self.primaryButton];
    // 宽高
    self.primaryButton.myWidth = MyLayoutSize.fill;
    self.primaryButton.myHeight = 42;
    
    
}

-(void)phoneLoginClick:(UIButton *)sender {
    NSLog(@"ViewController phoneLoginClick");
}

/// 登录按钮点击
/// @param sender sender descripation
-(void)primaryClick:(UIButton *)sender {
    NSLog(@"ViewController primaryClick");
}


@end