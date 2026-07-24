//
//  rootViewController.m
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/7/24.
//
#import "rootViewController.h"
#import "colorViewController.h"

@interface rootViewController ()

@property (nonatomic, strong) UITabBarController *tabBarController;

@end

@implementation rootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    // ============================================================
    // 容器视图控制器演示：
    // 1. UITabBarController 作为子容器 —— 管理多个 Tab 页面的切换
    // 2. UINavigationController 包裹每个 Tab —— 管理页面 push/pop 导航
    // ============================================================
    
    // 创建 4 个不同颜色的 Tab 页面
    colorViewController *redVC    = [[colorViewController alloc] initWithColor:[UIColor systemRedColor]    title:@"Red"];
    colorViewController *greenVC  = [[colorViewController alloc] initWithColor:[UIColor systemGreenColor]  title:@"Green"];
    colorViewController *blueVC   = [[colorViewController alloc] initWithColor:[UIColor systemBlueColor]   title:@"Blue"];
    colorViewController *orangeVC = [[colorViewController alloc] initWithColor:[UIColor systemOrangeColor] title:@"Orange"];
    
    // 用 UINavigationController 包裹每个页面，用于后续 push 跳转
    UINavigationController *redNav    = [[UINavigationController alloc] initWithRootViewController:redVC];
    UINavigationController *greenNav  = [[UINavigationController alloc] initWithRootViewController:greenVC];
    UINavigationController *blueNav   = [[UINavigationController alloc] initWithRootViewController:blueVC];
    UINavigationController *orangeNav = [[UINavigationController alloc] initWithRootViewController:orangeVC];
    
    // 设置 NavigationBar 不透明，避免布局偏移
    redNav.navigationBar.translucent    = NO;
    greenNav.navigationBar.translucent  = NO;
    blueNav.navigationBar.translucent   = NO;
    orangeNav.navigationBar.translucent = NO;
    
    // 为每个 Tab 设置标题和系统图标
    redVC.tabBarItem    = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemFavorites   tag:0];
    greenVC.tabBarItem  = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemContacts    tag:1];
    blueVC.tabBarItem   = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemRecents     tag:2];
    orangeVC.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemHistory     tag:3];
    
    // 创建 UITabBarController 并设置子控制器数组
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = @[redNav, greenNav, blueNav, orangeNav];
    
    // ============================================================
    // 容器视图控制器模式：将 UITabBarController 添加为子控制器
    // 这是标准的 View Controller Containment 做法
    // ============================================================
    [self addChildViewController:self.tabBarController];
    self.tabBarController.view.frame = self.view.bounds;
    self.tabBarController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tabBarController.view];
    [self.tabBarController didMoveToParentViewController:self];
}

@end
