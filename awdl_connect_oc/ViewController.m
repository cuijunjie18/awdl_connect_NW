//
//  ViewController.m
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/4/3.
//

#import "ViewController.h"
#import <Foundation/Foundation.h>
#import "models/Advertiser.h"

#define Width 200
#define Height 50

@interface ViewController ()

@property (nonatomic, assign) CGFloat buttonWidth;
@property (nonatomic, assign) CGFloat buttonHeight;
@property (nonatomic, strong) Advertiser* advertiser;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.buttonWidth = Width;
    self.buttonHeight = Height;
    self.advertiser = [[Advertiser alloc] init];
    
    UIButton* AdvertiserStartButton = [self getBaseButton: @"Advertise start"];
    UIButton* AdvertiserStopButton = [self getBaseButton: @"Advertise stop"];
    UIButton* BrowserStartButton = [self getBaseButton: @"Browser start"];
    UIButton* BrowserStopButton = [self getBaseButton: @"Browser stop"];
    
    [self.view addSubview: AdvertiserStartButton];
    [self.view addSubview: AdvertiserStopButton];
    [self.view addSubview: BrowserStartButton];
    [self.view addSubview: BrowserStopButton];
    
    [AdvertiserStartButton addTarget:self
    action: @selector(buttonForAdvertiseStartTapped:)
    forControlEvents: UIControlEventTouchUpInside];
    
    [AdvertiserStopButton addTarget:self
    action: @selector(buttonForAdvertiseStopTapped:)
    forControlEvents: UIControlEventTouchUpInside];
    
    [BrowserStartButton addTarget:self
    action: @selector(buttonTapped:)
    forControlEvents: UIControlEventTouchUpInside];
    
    [BrowserStopButton addTarget:self
    action: @selector(buttonTapped:)
    forControlEvents: UIControlEventTouchUpInside];
}

- (UIButton*) getBaseButton: (NSString*)name {
    static int counter = 0;
    counter++;
    UIButton *button = [[UIButton alloc] init];
    [button setTitle: name forState: UIControlStateNormal];
    [button setTitleColor: [UIColor blueColor] forState: UIControlStateNormal];
//    button.layer.borderWidth = 1;
//    button.layer.borderColor = [UIColor redColor].CGColor;
    [self AssginPositionForButton: button Counter: counter];
    return button;
}

- (void) AssginPositionForButton: (UIButton*)button Counter: (int)counter {
    CGFloat x = (self.view.bounds.size.width - Width) / 2;
    CGFloat y = (self.view.bounds.size.height - Height) / 2 - 3 * Height;
    y += counter * self.buttonHeight;
    button.frame = CGRectMake(x, y, self.buttonWidth, self.buttonHeight);
}


- (void)buttonTapped:(UIButton*) sender {
    NSLog(@"Button's name is %@", sender.currentTitle);
}

- (void)buttonForAdvertiseStartTapped:(UIButton*) sender {
    [self.advertiser startAdvertising];
}

- (void)buttonForAdvertiseStopTapped:(UIButton*) sender {
    [self.advertiser stopAdvertising];
}

@end
