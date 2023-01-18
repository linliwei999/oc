//
//  AppDelegate.m
//  MyCloudMusic
//
//  Created by 林立伟 on 2023/1/5.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate
// 这里在全局只执行一次

+ (instancetype)shared{
    // sceneDelegate下的写法
    //connectedScenes类型是NSSet，保存的元素不重复，无序，不是NSArray
    //allObjects方法是转为数组，然后取值
    //    UIScene *scene = [UIApplication.sharedApplication.connectedScenes allObjects][0];
    //    return scene.delegate;
    
    // AppDelegate下的写法
    return UIApplication.sharedApplication.delegate;
}

- (void)toLoginHome{
    [self setRootViewController:@"LoginHome"];
}

/// 设置跟控制器
/// @param data data description
- (void)setRootViewController:(NSString *)data{
    //获取到Main.storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName: @"Main" bundle: nil];
    //实例化场景
    //因为场景关联了控制器
    //所以说也可以说实例化了一个控制
    //只是这个过程是系统创建的
    //不是我们手动完成
    UIViewController
    *target = [storyboard instantiateViewControllerWithIdentifier: data];
     
    //替换掉原来的根控制器
    //目的是，我们不希望用户还能返回到原来的界面
    self.window.rootViewController = target;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}


@end
