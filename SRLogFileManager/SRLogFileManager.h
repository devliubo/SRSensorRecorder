//
//  SRLogFileManager.h
//  SRSensorRecorder
//
//  Created by liubo on 2017/7/31.
//  Copyright © 2017年 devliubo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

#define kSRLogFileManagerDir  @"SRLogFiles"

#pragma mark - SRLogFileManager

@interface SRLogFileManager : NSObject

+ (SRLogFileManager *)logFileManagerWithFolderName:(NSString *)folderName;

@property (nonatomic, readonly) NSString *locationFilePath;
@property (nonatomic, readonly) NSString *motionFilePath;

- (BOOL)addLogString:(NSString *)logString toFile:(NSString *)filePath;

- (BOOL)addLocationLogString:(NSString *)logString;
- (BOOL)addMotionLogString:(NSString *)logString;

@end

#pragma mark - SRLogFileManagerUtility

@interface SRLogFileManagerUtility : NSObject

//Location
+ (NSString *)logStringFormCLLocation:(CLLocation *)aLocation;
+ (CLLocation *)CLLocationFromLogString:(NSString *)logString;

//Motion
+ (NSString *)logStringFromCMDeviceMotion:(CMDeviceMotion *)deviceMotion;
+ (void)attitudeValueFromLogString:(NSString *)logString
                              roll:(double *)roll
                             pitch:(double *)pitch
                               yaw:(double *)yaw
                    rotationMatrix:(CMRotationMatrix *)martix
                        quaternion:(CMQuaternion *)quaternion;
+ (CMRotationRate)rotationRateFromLogString:(NSString *)logString;
+ (CMAcceleration)accelerationFromLogString:(NSString *)logString;
+ (CMAcceleration)userAccelerationFromLogString:(NSString *)logString;
+ (CMCalibratedMagneticField)magneticFieldFromLogString:(NSString *)logString;

@end

#pragma mark - SRLocationLogPlayback

typedef void(^SRLocationLogPlaybackBlock)(CLLocation *location, NSUInteger index, BOOL *stop);

@interface SRLocationLogPlayback : NSObject

@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) NSString *logFilePath;

- (BOOL)loadLogFileAtPath:(NSString *)logFilePath;
- (void)startPlaybackUsingLocationBlock:(SRLocationLogPlaybackBlock)locationBlock;
- (void)stopPlayback;

@end
