//
//  TAPKitObjc.h
//  TAPKitUnityBridge
//
//  Created by Shahar Biran on 11/04/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TAPKit/TAPKit-Swift.h>


NS_ASSUME_NONNULL_BEGIN

typedef void (*UnityCallbackTapped)(const char* identifier, int combination);
typedef void (*UnityCallbackBluetoothState)(bool state);
typedef void (*UnityCallbackTapConnected)(const char* identifier, const char* name, int fw);
typedef void (*UnityCallbackTapDisconnected)(const char* identifier);
typedef void (*UnityCallbackTapFailedtoConnect)(const char* identifier, const char* name);
typedef void (*UnityCallbackMoused)(const char* identifier, int vx, int vy, bool is_mouse);
typedef void (*UnityCallbackAirGestured)(const char* identifier, int gesture);
typedef void (*UnityCallbackChangedAirGestureState)(const char* identifier, bool is_air_gesture);
typedef void (*UnityCallbackRawSensorDataReceived)(const char* identifier, const char* rawSensorData, const char* delimeter);
@interface TAPKitObjc : NSObject<TAPKitDelegate>

@property (nonatomic) TAPKitLog* _Nonnull log;

+ (instancetype)sharedKit;

- (void)start;
- (void)setUnityCallbackForTapped:(UnityCallbackTapped)c;
- (void)setUnityCallbackForBluetoothState:(UnityCallbackBluetoothState)c;
- (void)setUnityCallbackForTapConnected:(UnityCallbackTapConnected)c;
- (void)setUnityCallbackForTapDisconnected:(UnityCallbackTapDisconnected)c;
- (void)setUnityCallbackForTapFailedtoConnect:(UnityCallbackTapFailedtoConnect)c;
- (void)setUnityCallbackForMoused:(UnityCallbackMoused)c;
- (void)setUnityCallbackForAirGestured:(UnityCallbackAirGestured)c;
- (void)setUnityCallbackForChangedAirGestureState:(UnityCallbackChangedAirGestureState)c;
- (void)setUnityCallbackForRawSensorDataReceived:(UnityCallbackRawSensorDataReceived)c;
- (void)setControllerModeForTapIdentifier:(NSString*)tapIdentifier;
- (void)setTextModeForTapIdentifier:(NSString*)tapIdentifier;
- (void)setControllerWithMouseHIDModeForTapIdentifier:(NSString*)tapIdentifier;
- (void)setRawSensorModeForTapIdentifier:(NSString*)tapIdentifier sensitivitiesDeviceAccelerometer:(int)devAccel imuGyro:(int)imuGyro imuAccelerometer:(int)imuAccel;
- (void)vibrateTapIdentifier:(NSString*)tapIdentifier durations:(NSString*)durationsString delimeter:(NSString*)delimeter;
NS_ASSUME_NONNULL_END

//- (void)vibrateTapIdentifier:(nullable NSString*)tapIdentifier withDurations:(int* _Nonnull)durations andLength:(int)length;
@end
