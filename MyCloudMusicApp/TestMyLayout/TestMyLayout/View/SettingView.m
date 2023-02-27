//
//  SettingView.m
//  TestMyLayout
//
//  Created by 林立伟 on 2023/2/18.
//

#import "SettingView.h"

@implementation SettingView

-(instancetype)init{
    self = [super initWithOrientation:MyOrientation_Horz];
    if(self){
        [self innerInit];
    }
    return self;
}

-(void)innerInit{
    self.myWidth = MyLayoutSize.fill;
    self.myHeight = 55;
    self.padding = UIEdgeInsetsMake(16, 16, 16, 16);
    self.subviewSpace = 10;
//    self.margin = UIEdgeInsetsMake(0, 0, 10, 0);
    
    self.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.iconView];
    [self addSubview:self.titleView];
    [self addSubview:self.moreIconView];
}


#pragma mark - 创建控件
- (UIImageView *)iconView{
    if(!_iconView) {
        _iconView = [UIImageView new];
        _iconView.image = [UIImage imageNamed:@"Setting"];
        
        _iconView.myWidth = 20;
        _iconView.myHeight = 20;
    }
    return _iconView;
}

- (UILabel *)titleView{
    if(!_titleView) {
        _titleView = [UILabel new];
        _titleView.text = @"设置";
        
        _titleView.myWidth = MyLayoutSize.fill;
        _titleView.myHeight = MyLayoutSize.wrap;
        _titleView.weight = 1;
    }
    return _titleView;
}

- (UIImageView *)moreIconView{
    if(!_moreIconView) {
        _moreIconView = [UIImageView new];
        _moreIconView.image = [UIImage imageNamed:@"Arrow"];
        
        _moreIconView.myWidth = 20;
        _moreIconView.myHeight = 20;
    }
    return _moreIconView;
}

@end
