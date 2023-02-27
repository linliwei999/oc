//
//  SettingController.m
//  TestMyLayout
//
//  Created by 林立伟 on 2023/2/18.
//

#import "SettingController.h"
#import "SettingView.h"

@interface SettingController ()
@property(nonatomic, strong) SettingView *settingView;
@property(nonatomic, strong) SettingView *collectView;

@end

@implementation SettingController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"设置";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    
    // 创建一个容器
    MyBaseLayout *container = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
    
    // 从安全区开始
    container.leadingPos.equalTo(@(MyLayoutPos.safeAreaMargin));
    container.trailingPos.equalTo(@(MyLayoutPos.safeAreaMargin));
    container.topPos.equalTo(@(MyLayoutPos.safeAreaMargin)).offset(16);
    container.myHeight = MyLayoutSize.wrap;
    
    container.subviewSpace = 0.5;
    
    [self.view addSubview: container];
    
    [container addSubview: self.settingView];
    [container addSubview: self.collectView];
}

#pragma mark - 控件
// 设置Item
-(SettingView *)settingView {
    if(!_settingView){
        _settingView = [SettingView new];
        _settingView.titleView.text = @"设置";
        // 设置点击事件
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(settingTapGestureRecognizer:)];
        [_settingView addGestureRecognizer:tapGestureRecognizer];
    }
    return _settingView;
}

// 收藏Item
-(SettingView *)collectView {
    if(!_collectView){
        _collectView = [SettingView new];
        _collectView.titleView.text = @"收藏";
        // 设置点击事件
        
    }
    return _collectView;
}

// 点击事件
-(void)settingTapGestureRecognizer:(UIButton *)sender {
    NSLog(@"SettingController settingTapGestureRecognizer");
}

@end
