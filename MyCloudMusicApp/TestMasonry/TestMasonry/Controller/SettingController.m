//
//  SettingController.m
//  TestMasonry
//
//  Created by 林立伟 on 2023/2/16.
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
    [self.view addSubview:self.settingView];
    [self.view addSubview:self.collectView];
    
    //添加约束，只有添加当前控件，内部的约束在控件内部就添加了
    [self.settingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(16);
//        make.height.equalTo(@(55));
        make.height.mas_equalTo(55);
    }];
    
    [self.collectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.top.equalTo(self.settingView.mas_bottom).offset(1);
        make.height.mas_equalTo(55);
    }];
}

-(void)settingTapGestureRecognizer:(UITapGestureRecognizer *)recoginzer{
    NSLog(@"SettingController settingTapGestureRecognizer");
}

#pragma mark - 控件
// 设置Item
- (SettingView *)settingView {
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
- (SettingView *)collectView {
    if(!_collectView){
        _collectView = [SettingView new];
        _collectView.titleView.text = @"收藏";
    }
    return _collectView;
}



@end
