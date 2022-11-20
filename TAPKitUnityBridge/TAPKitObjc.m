//
//  TAPKitObjc.m
//  TAPKitUnityBridge
//
//  Created by Shahar Biran on 11/04/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

#import "TAPKitObjc.h"

@interface TAPKitObjc () {
    
    TAPKit* _tapKit;
    UnityCallbackTapped _unityCallbackTapped;
    UnityCallbackBluetoothState _unityCallbackBluetoothState;
    UnityCallbackTapConnected _unityCallbackTapConnected;
    UnityCallbackTapDisconnected _unityCallbackTapDisconnected;
    UnityCallbackTapFailedtoConnect _unityCallbackTapFailedToConnect;
    UnityCallbackAirGestured _unityCallbackAirGestured;
    UnityCallbackChangedAirGestureState _unityCallbackChangedAirGestureState;
    UnityCallbackMoused _unityCallbackMoused;
    UnityCallbackRawSensorDataReceived _unityCallbackRawSensorDataReceived;
}

@end

@implementation TAPKitObjc

static TAPKitObjc* instance = nil;

+(instancetype)sharedKit {
    @synchronized(self) {
        if (instance == nil) {
            instance = [[TAPKitObjc alloc] init];
        }
    }
    return instance;
}

- (id)init {
    if (self = [super init]) {
        
        self.log = TAPKitLog.sharedLog;
        _tapKit = TAPKit.sharedKit;
//        [_central addWithDelegate:self];
        [_tapKit addDelegate:self];
    }
    return self;
}

- (void)start {
    [_tapKit start];
}

- (void)setUnityCallbackForTapped:(UnityCallbackTapped)c {
    self->_unityCallbackTapped = c;
}

- (void)setUnityCallbackForBluetoothState:(UnityCallbackBluetoothState)c {
    self->_unityCallbackBluetoothState = c;
}

- (void)setUnityCallbackForTapConnected:(UnityCallbackTapConnected)c {
    self->_unityCallbackTapConnected = c;
}

- (void)setUnityCallbackForTapDisconnected:(UnityCallbackTapDisconnected)c {
    self->_unityCallbackTapDisconnected = c;
}

- (void)setUnityCallbackForTapFailedtoConnect:(UnityCallbackTapFailedtoConnect)c {
    self->_unityCallbackTapFailedToConnect = c;
}

- (void)setUnityCallbackForMoused:(UnityCallbackMoused)c {
    self->_unityCallbackMoused = c;
}

- (void)setUnityCallbackForAirGestured:(UnityCallbackAirGestured)c {
    self->_unityCallbackAirGestured = c;
}

- (void)setUnityCallbackForChangedAirGestureState:(UnityCallbackChangedAirGestureState)c {
    self->_unityCallbackChangedAirGestureState = c;
}

- (void)setUnityCallbackForRawSensorDataReceived:(UnityCallbackRawSensorDataReceived)c {
    self->_unityCallbackRawSensorDataReceived = c;
}
                                                                                        

- (void)setControllerModeForTapIdentifier:(NSString*)tapIdentifier {
    
    [_tapKit setTAPInputMode:[TAPInputMode controller] forIdentifiers:@[tapIdentifier]];
}
                                       
- (void)setTextModeForTapIdentifier:(NSString*)tapIdentifier {
    [_tapKit setTAPInputMode:[TAPInputMode text] forIdentifiers:@[tapIdentifier]];
}

- (void)setControllerWithMouseHIDModeForTapIdentifier:(NSString*)tapIdentifier {
    [_tapKit setTAPInputMode:[TAPInputMode controllerWithMouseHID] forIdentifiers:@[tapIdentifier]];
}

- (void)setRawSensorModeForTapIdentifier:(NSString*)tapIdentifier sensitivitiesDeviceAccelerometer:(int)devAccel imuGyro:(int)imuGyro imuAccelerometer:(int)imuAccel {
    [_tapKit setTAPInputMode:[TAPInputMode rawSensorWithSensitivity:[[TAPRawSensorSensitivity alloc] initWithDeviceAccelerometer:devAccel imuGyro:imuGyro imuAccelerometer:imuAccel]] forIdentifiers:@[tapIdentifier]];
}


- (void)tapDisconnectedWithIdentifier:(NSString *)identifier {
    if (self->_unityCallbackTapDisconnected) {
        _unityCallbackTapDisconnected([identifier cStringUsingEncoding:NSUTF8StringEncoding]);
    }
}

- (void)tapConnectedWithIdentifier:(NSString *)identifier name:(NSString *)name fw:(NSInteger)fw {
    if (self->_unityCallbackTapConnected) {
        _unityCallbackTapConnected([identifier cStringUsingEncoding:NSUTF8StringEncoding], [name cStringUsingEncoding:NSUTF8StringEncoding], (int)fw);
    }
}

- (void)tapFailedToConnectWithIdentifier:(NSString *)identifier name:(NSString *)name {
    if (self->_unityCallbackTapFailedToConnect) {
        _unityCallbackTapFailedToConnect([identifier cStringUsingEncoding:NSUTF8StringEncoding], [name cStringUsingEncoding:NSUTF8StringEncoding]);
    }
}

- (void)tappedWithIdentifier:(NSString *)identifier combination:(uint8_t)combination {
    if (self->_unityCallbackTapped) {
        _unityCallbackTapped([identifier cStringUsingEncoding:NSUTF8StringEncoding], (int)combination);
    }
}

- (void)mousedWithIdentifier:(NSString *)identifier velocityX:(int16_t)velocityX velocityY:(int16_t)velocityY isMouse:(BOOL)isMouse {
    if (self->_unityCallbackMoused) {
        _unityCallbackMoused([identifier cStringUsingEncoding:NSUTF8StringEncoding], (int)velocityX, (int)velocityY, isMouse);
    }
}

- (void)centralBluetoothStateWithPoweredOn:(BOOL)poweredOn {
    if (self->_unityCallbackBluetoothState) {
        _unityCallbackBluetoothState(poweredOn);
    }
}

- (void)tapAirGesturedWithIdentifier:(NSString *)identifier gesture:(enum TAPAirGesture)gesture {
    if (self->_unityCallbackAirGestured) {
        _unityCallbackAirGestured([identifier cStringUsingEncoding:NSUTF8StringEncoding], (int)gesture);
    }
}

- (void)tapChangedAirGesturesStateWithIdentifier:(NSString *)identifier isInAirGesturesState:(BOOL)isInAirGesturesState {
    if (self->_unityCallbackChangedAirGestureState) {
        _unityCallbackChangedAirGestureState([identifier cStringUsingEncoding:NSUTF8StringEncoding], isInAirGesturesState);
    }
}

- (void)rawSensorDataReceivedWithIdentifier:(NSString *)identifier data:(RawSensorData *)data {
    if (self->_unityCallbackRawSensorDataReceived) {
        
        _unityCallbackRawSensorDataReceived([identifier cStringUsingEncoding:NSUTF8StringEncoding], [[data rawStringWithDelimeter:@"^"] cStringUsingEncoding:NSUTF8StringEncoding], [@"^" cStringUsingEncoding:NSUTF8StringEncoding]);
    }
}

- (BOOL)isAllDigits:(NSString*)string
{
    NSCharacterSet* nonNumbers = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSRange r = [[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] rangeOfCharacterFromSet: nonNumbers];
    return r.location == NSNotFound && string.length > 0;
}

- (void)vibrateTapIdentifier:(NSString*)tapIdentifier durations:(NSString*)durationsString delimeter:(NSString*)delimeter {
    NSArray<NSString*>* durationsStringArray = [durationsString componentsSeparatedByString:delimeter];
    NSMutableArray<NSNumber*>* durations = [[NSMutableArray alloc] initWithCapacity:durationsStringArray.count];
    for (int i=0; i<durationsStringArray.count; i++) {
        NSString* current = [durationsStringArray objectAtIndex:i];
        if ([self isAllDigits:current]) {
            [durations addObject:[NSNumber numberWithInt:[current intValue]]];
        } else {
            return;
        }
    }
    
    [_tapKit vibrateWithDurations:durations forIdentifiers:@[tapIdentifier]];
    
    
}

//- (void)vibrateTapIdentifier:(nullable NSString*)tapIdentifier withDurations:(int* _Nonnull)durations andLength:(int)length {
//
//    NSMutableArray<NSNumber*>* durs = [[NSMutableArray alloc] initWithCapacity:length];
//    for (int i=0; i<length; i++) {
//        [durs addObject:[NSNumber numberWithInt:durations[i]]];
//    }
//    [_central vibrateWithIdentifier:tapIdentifier durations:durs];
//}

@end
