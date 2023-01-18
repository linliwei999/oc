//
//  AppDelegate.h
//  MyCloudMusic
//
//  Created by 林立伟 on 2023/1/5.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow * window;

/// 获取单例对象
+(instancetype) shared;

/// 启动登录页
-(void)toLoginHome;

@end

