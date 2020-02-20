//
//  UnityBridge.m
//  tap-unity-ios-sdk
//
//  Created by Shahar Biran on 10/04/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

#import "UnityBridge.h"

extern "C" {
void TAPKit_start() {
    [[TAPKitObjc sharedKit] start];
}

void TAPKit_setUnityCallbackForTapped(UnityCallbackTapped c) {
    [[TAPKitObjc sharedKit] setUnityCallbackForTapped:c];
}
    
void TAPKit_setUnityCallbackForMoused(UnityCallbackMoused c) {
    [[TAPKitObjc sharedKit] setUnityCallbackForMoused:c];
}

void TAPKit_setUnityCallbackForBluetoothState(UnityCallbackBluetoothState c) {
    [[TAPKitObjc sharedKit] setUnityCallbackForBluetoothState:c];
}

void TAPKit_setUnityCallbackForTapConnected(UnityCallbackTapConnected c) {
    [[TAPKitObjc sharedKit] setUnityCallbackForTapConnected:c];
}

void TAPKit_setUnityCallbackForTapDisconnected(UnityCallbackTapDisconnected c) {
    [[TAPKitObjc sharedKit] setUnityCallbackForTapDisconnected:c];
}

void TAPKit_setUnityCallbackForTapFailedtoConnect(UnityCallbackTapFailedtoConnect c) {
    [[TAPKitObjc sharedKit] setUnityCallbackForTapFailedtoConnect:c];
}

void TAPKit_setUnityCallbackForAirGestured(UnityCallbackAirGestured c) {
    [[TAPKitObjc sharedKit] setUnityCallbackForAirGestured:c];
}

void TAPKit_setUnityCallbackForChangedAirGestureState(UnityCallbackChangedAirGestureState c) {
    [[TAPKitObjc sharedKit] setUnityCallbackForChangedAirGestureState:c];
}

void TAPKit_setUnityCallbackForRawSensorDataReceived(UnityCallbackRawSensorDataReceived c) {
    [[TAPKitObjc sharedKit] setUnityCallbackForRawSensorDataReceived:c];
}

void TAPKit_setControllerMode(const char* identifier) {
    [[TAPKitObjc sharedKit] setControllerModeForTapIdentifier:[NSString stringWithUTF8String:identifier]];
}

void TAPKit_setTextMode(const char* identifier) {
    [[TAPKitObjc sharedKit] setTextModeForTapIdentifier:[NSString stringWithUTF8String:identifier]];
}

void TAPKit_setControllerWithMouseHIDMode(const char* identifier) {
    [[TAPKitObjc sharedKit] setControllerWithMouseHIDModeForTapIdentifier:[NSString stringWithUTF8String:identifier]];
}

void TAPKit_setRawSensorMode(const char* identifier, int devAccel, int imuGyro, int imuAccel) {
    [[TAPKitObjc sharedKit] setRawSensorModeForTapIdentifier:[NSString stringWithUTF8String:identifier] sensitivitiesDeviceAccelerometer:devAccel imuGyro:imuGyro imuAccelerometer:imuAccel];
}

void TAPKit_vibrate(const char* identifier, const char* durationsString, const char* delimeter) {
    [[TAPKitObjc sharedKit] vibrateTapIdentifier:[NSString stringWithUTF8String:identifier] durations:[NSString stringWithUTF8String:durationsString] delimeter:[NSString stringWithUTF8String:delimeter]];
}
    
void TAPKit_enableDebug() {
    [[TAPKitObjc sharedKit].log enableAllEvents];
}
void TAPKit_disableDebug() {
    [[TAPKitObjc sharedKit].log disableAllEvents];
}

    
    
}
