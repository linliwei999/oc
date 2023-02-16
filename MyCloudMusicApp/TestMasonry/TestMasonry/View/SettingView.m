//
//  SettingView.m
//  设置itemView
//
//  Created by 林立伟 on 2023/2/16.
//

#import "SettingView.h"

@implementation SettingView

- (instancetype)init{
    self = [super init];
    if(self){
        [self innerInit];
    }
    return self;
}

- (void)innerInit{
    self.backgroundColor = [UIColor whiteColor];
    [self addSubview: self.iconView];
    [self addSubview: self.titleView];
    [self addSubview: self.moreView];
}

// 当视图加入父视图时 / 当视图从父视图移除时调用
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
    
    [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(16);
        make.centerY.equalTo(self);
        make.width.mas_equalTo(20);
        make.height.mas_equalTo(20);
    }];
    
    [self.titleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.iconView.mas_right).offset(16);
        make.centerY.equalTo(self);
    }];
    
    [self.moreView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-16);
        make.centerY.equalTo(self);
        make.width.mas_equalTo(20);
        make.height.mas_equalTo(20);
    }];
}


#pragma mark - 创建控件
- (UIImageView *)iconView{
    if(!_iconView) {
        _iconView = [UIImageView new];
        _iconView.image = [UIImage imageNamed:@"Setting"];
    }
    return _iconView;
}

- (UILabel *)titleView{
    if(!_titleView) {
        _titleView = [UILabel new];
        _titleView.text = @"设置";
    }
    return _titleView;
}

- (UIImageView *)moreView{
    if(!_moreView) {
        _moreView = [UIImageView new];
        _moreView.image = [UIImage imageNamed:@"Arrow"];
    }
    return _moreView;
}



@end
