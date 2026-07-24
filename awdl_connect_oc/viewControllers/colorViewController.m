//
//  colorViewController.m
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/7/24.
//

#import "colorViewController.h"
#import "ViewController.h"

@interface colorViewController ()

@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, copy)   NSString *tabTitle;

@end

@implementation colorViewController

- (instancetype)initWithColor:(UIColor *)color title:(NSString *)title {
    self = [super init];
    if (self) {
        _bgColor  = color;
        _tabTitle = [title copy];
        self.title = title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置背景色，区分不同 Tab
    self.view.backgroundColor = self.bgColor;
    
    // 添加一个标签显示当前页面的颜色名称
    UILabel *label = [[UILabel alloc] init];
    label.text = self.tabTitle;
    label.font = [UIFont boldSystemFontOfSize:28];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:label];
    
    // 添加跳转到主功能页面的按钮
    UIButton *pushButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [pushButton setTitle:@"Push to AWDL Demo" forState:UIControlStateNormal];
    [pushButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    pushButton.titleLabel.font = [UIFont systemFontOfSize:18];
    pushButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    pushButton.layer.cornerRadius = 12;
    pushButton.translatesAutoresizingMaskIntoConstraints = NO;
    [pushButton addTarget:self
                   action:@selector(pushButtonTapped:)
         forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pushButton];
    
    // 布局约束
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-40],
        
        [pushButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [pushButton.topAnchor constraintEqualToAnchor:label.bottomAnchor constant:30],
        [pushButton.widthAnchor constraintEqualToConstant:220],
        [pushButton.heightAnchor constraintEqualToConstant:50],
    ]];
}

#pragma mark - Actions

- (void)pushButtonTapped:(UIButton *)sender {
    // 通过 UINavigationController push 到主功能页
    ViewController *vc = [[ViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
