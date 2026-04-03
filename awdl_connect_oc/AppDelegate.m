//
//  AppDelegate.m
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/4/3.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    
    //创建ViewController
    ViewController *vc = [[ViewController alloc] init];
    
    //将此window的根控制器设置为创建的Contoller
    self.window.rootViewController = vc;
    
    //让window成为keywindow并可见
    [self.window makeKeyAndVisible];
    return YES;
}


@end
