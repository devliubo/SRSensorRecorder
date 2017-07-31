//
//  ViewController.m
//  SRSensorRecorder
//
//  Created by liubo on 2017/7/31.
//  Copyright © 2017年 devliubo. All rights reserved.
//

#import "ViewController.h"
#import "SRLogFileManager.h"
#import "APLGraphView.h"
#import <CoreText/CoreText.h>

@interface ViewController ()<CLLocationManagerDelegate>

@property (nonatomic, strong) SRLogFileManager *logFileManager;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIButton *endButton;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) APLGraphView *graphViewAcc;
@property (nonatomic, strong) APLGraphView *graphViewRot;
@property (nonatomic, strong) UILabel *graphViewLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initLocationManager];
    
    [self initCoreMotionManager];
    
    self.startButton = [self buildButtonForTitle:@"Start"];
    [self.startButton setFrame:CGRectMake(10, 30, 90, 30)];
    [self.startButton addTarget:self action:@selector(startButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startButton];
    
    self.endButton = [self buildButtonForTitle:@"End"];
    [self.endButton setFrame:CGRectMake(110, 30, 90, 30)];
    [self.endButton addTarget:self action:@selector(endButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.endButton];
    
    self.clearButton = [self buildButtonForTitle:@"ClearText"];
    [self.clearButton setFrame:CGRectMake(210, 30, 100, 30)];
    [self.clearButton addTarget:self action:@selector(clearButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.clearButton];
    
    self.startButton.enabled = YES;
    self.endButton.enabled = NO;
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 80, CGRectGetWidth(self.view.bounds)-20, CGRectGetHeight(self.view.bounds)-100-130)];
    self.textView.editable = NO;
    [self.view addSubview:self.textView];
    
    self.graphViewAcc = [[APLGraphView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds)-130, CGRectGetWidth(self.view.bounds)/2.0, 115)];
    [self.view addSubview:self.graphViewAcc];
    
    self.graphViewRot = [[APLGraphView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.bounds)/2.0, CGRectGetHeight(self.view.bounds)-130, CGRectGetWidth(self.view.bounds)/2.0, 115)];
    [self.view addSubview:self.graphViewRot];
    
    self.graphViewLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetHeight(self.view.bounds)-15, CGRectGetWidth(self.view.bounds)-20, 15)];
    [self.graphViewLabel setFont:[UIFont systemFontOfSize:8]];
    [self.graphViewLabel setText:@"X:红;Y:绿;Z:蓝;Ver:0.0.2"];
    [self.view addSubview:self.graphViewLabel];
}

- (UIButton *)buildButtonForTitle:(NSString *)title
{
    UIButton *reBtn = [UIButton buttonWithType:UIButtonTypeInfoDark];
    
    reBtn.layer.borderColor  = [UIColor lightGrayColor].CGColor;
    reBtn.layer.borderWidth  = 1.0;
    reBtn.layer.cornerRadius = 5;
    
    [reBtn setBounds:CGRectMake(0, 0, 80, 30)];
    [reBtn setTitle:title forState:UIControlStateNormal];
    [reBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [reBtn setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    reBtn.titleLabel.font = [UIFont systemFontOfSize:13.0];
    
    return reBtn;
}

- (void)initLocationManager
{
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [self.locationManager setPausesLocationUpdatesAutomatically:NO];
    if ([[UIDevice currentDevice].systemVersion floatValue] > 8.99)
    {
        [self.locationManager setAllowsBackgroundLocationUpdates:YES];
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
    {
        if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        {
            [_locationManager requestAlwaysAuthorization];
        }
    }
}

- (void)startButtonAction:(UIButton *)sender
{
    self.startButton.enabled = NO;
    self.endButton.enabled = YES;
    
    self.logFileManager = [SRLogFileManager logFileManagerWithFolderName:nil];
    
    [self.locationManager startUpdatingLocation];
    
    [self startMotionUpdate];
}

- (void)endButtonAction:(UIButton *)sender
{
    [self.locationManager stopUpdatingLocation];
    
    self.logFileManager = nil;
    
    [self stopMotionUpdate];
    
    self.startButton.enabled = YES;
    self.endButton.enabled = NO;
}

- (void)clearButtonAction:(UIButton *)sender
{
    self.textView.text = nil;
}

#pragma mark - Private: Core Motion

- (void)initCoreMotionManager
{
    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager setDeviceMotionUpdateInterval:0.2];
}

- (void)startMotionUpdate
{
    if (self.motionManager.deviceMotionActive == YES)
    {
        return;
    }
    
    __weak ViewController *weakSelf = self;
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
        
        if (error != nil || motion == nil)
        {
            return;
        }
        
        __strong ViewController *strongSelf = weakSelf;
        if (strongSelf)
        {
            CMAcceleration acceleration = motion.userAcceleration;
            CMRotationRate rotationRate = motion.rotationRate;
            [strongSelf.graphViewAcc addX:acceleration.x y:acceleration.y z:acceleration.z];
            [strongSelf.graphViewRot addX:rotationRate.x y:rotationRate.y z:rotationRate.z];
            
            if (strongSelf.logFileManager)
            {
                [strongSelf.logFileManager addMotionLogString:[SRLogFileManagerUtility logStringFromCMDeviceMotion:motion]];
            }
        }
    }];
    
}

- (void)stopMotionUpdate
{
    if (self.motionManager.deviceMotionActive == NO)
    {
        return;
    }
    
    [self.motionManager stopDeviceMotionUpdates];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation *lastLocation = [locations lastObject];
    
    if (!CLLocationCoordinate2DIsValid(lastLocation.coordinate))
    {
        return;
    }
    
    if (fabs([lastLocation.timestamp timeIntervalSinceNow]) > 10.0)
    {
        return;
    }
    
    NSString *logString = [SRLogFileManagerUtility logStringFormCLLocation:lastLocation];
    
    self.textView.text = [[self.textView.text stringByAppendingString:logString] stringByAppendingString:@"\n"];
    [self.textView scrollRangeToVisible:NSMakeRange(self.textView.text.length-10, 10)];
    
    if (self.logFileManager)
    {
        [self.logFileManager addLocationLogString:logString];
    }
}

@end
