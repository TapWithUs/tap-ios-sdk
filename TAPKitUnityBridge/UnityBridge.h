//
//  UnityBridge.h
//  tap-unity-ios-sdk
//
//  Created by Shahar Biran on 10/04/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "TAPKitObjc.h"

#ifdef __cplusplus
extern "C" {
#endif
    
    void TAPKit_start();
    void TAPKit_setUnityCallbackForTapped(UnityCallbackTapped c);
    void TAPKit_setUnityCallbackForMoused(UnityCallbackMoused c);
    void TAPKit_setUnityCallbackForBluetoothState(UnityCallbackBluetoothState c);
    void TAPKit_setUnityCallbackForTapConnected(UnityCallbackTapConnected c);
    void TAPKit_setUnityCallbackForTapDisconnected(UnityCallbackTapDisconnected c);
    void TAPKit_setUnityCallbackForTapFailedtoConnect(UnityCallbackTapFailedtoConnect c);
    void TAPKit_setUnityCallbackForAirGestured(UnityCallbackAirGestured c);
    void TAPKit_setUnityCallbackForChangedAirGestureState(UnityCallbackChangedAirGestureState c);
    void TAPKit_setUnityCallbackForRawSensorDataReceived(UnityCallbackRawSensorDataReceived c);
    void TAPKit_setControllerMode(const char* identifier);
    void TAPKit_setTextMode(const char* identifier);
    void TAPKit_setControllerWithMouseHIDMode(const char* identifier);
    void TAPKit_setRawSensorMode(const char* identifier, int devAccel, int imuGyro, int imuAccel);
    void TAPKit_vibrate(const char* identifier, const char* durationsString, const char* delimeter);
//    void TAPKit_vibrate(const char* identifier, int durations[], int length);
//    void TAPKit_vibrateAllTaps(int durations[], int length);
    void TAPKit_enableDebug();
    void TAPKit_disableDebug();
#ifdef __cplusplus
}
#endif

