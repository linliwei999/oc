//
//  SettingView.h
//  TestMyLayout
//
//  Created by 林立伟 on 2023/2/18.
//

#import <MyLayout/MyLayout.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingView : MyLinearLayout

@property (nonatomic, strong) UIImageView *iconView; // 左侧图标
@property (nonatomic, strong) UILabel *titleView; // 标题
@property (nonatomic, strong) UIImageView *moreIconView; // 右侧图标

@end

NS_ASSUME_NONNULL_END
