//
//  SettingView.h
//  TestMasonry
//
//  Created by 林立伟 on 2023/2/16.
//

#import <UIKit/UIKit.h>

// 布局框架
#import <Masonry.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingView : UIView
// 左侧图标
@property (nonatomic, strong) UIImageView *iconView;
// 标题
@property (nonatomic, strong) UILabel *titleView;
// 右侧图标
@property (nonatomic, strong) UIImageView *moreView;

@end

NS_ASSUME_NONNULL_END
