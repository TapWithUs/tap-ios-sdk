# TAPKit React Native

React Native module for TAPKit BLE SDK. This module provides a bridge between your React Native application and the native TAPKit SDK for both iOS and Android.

## Installation

1. Install the package:
```bash
npm install tapkit-react-native
# or
yarn add tapkit-react-native
```

2. Link the native modules:
```bash
cd ios && pod install && cd ..
```

3. Add required permissions to your Android app's `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

## Usage

```typescript
import TAPKit, { DeviceFoundEvent, CharacteristicChangedEvent } from 'tapkit-react-native';

// Start scanning for TAP devices
await TAPKit.startScanning();

// Listen for discovered devices
const deviceFoundSubscription = TAPKit.addListener('onDeviceFound', (event: DeviceFoundEvent) => {
  console.log('Device found:', event.deviceId, event.name, event.rssi);
});

// Connect to a specific device
await TAPKit.connect('device-id');

// Listen for connection events
const connectedSubscription = TAPKit.addListener('onConnected', () => {
  console.log('Device connected');
});

const disconnectedSubscription = TAPKit.addListener('onDisconnected', () => {
  console.log('Device disconnected');
});

// Listen for characteristic changes
const characteristicSubscription = TAPKit.addListener('onCharacteristicChanged', (event: CharacteristicChangedEvent) => {
  console.log('Characteristic changed:', event.characteristicUuid, event.data);
});

// Send a command to the device
await TAPKit.sendCommand({
  type: 'COMMAND_TYPE',
  data: {
    // command specific data
  }
});

// Disconnect from the device
await TAPKit.disconnect();

// Stop scanning
await TAPKit.stopScanning();

// Clean up listeners when done
deviceFoundSubscription.remove();
connectedSubscription.remove();
disconnectedSubscription.remove();
characteristicSubscription.remove();
```

## API Reference

### Methods

#### startScanning()
Starts scanning for TAP devices in range.

#### stopScanning()
Stops scanning for TAP devices.

#### connect(deviceId: string)
Connects to a specific TAP device using its ID.

#### disconnect()
Disconnects from the currently connected TAP device.

#### sendCommand(command: { type: string, data?: any })
Sends a command to the connected TAP device.

#### addListener(eventName: string, callback: (event: any) => void)
Adds an event listener for BLE events.

#### removeListener(subscription: EmitterSubscription)
Removes an event listener.

### Events

#### onDeviceFound
Emitted when a new device is discovered during scanning.
```typescript
interface DeviceFoundEvent {
  deviceId: string;
  name: string;
  rssi: number;
}
```

#### onConnected
Emitted when a device is successfully connected.

#### onDisconnected
Emitted when a device is disconnected.

#### onCharacteristicChanged
Emitted when a characteristic value changes.
```typescript
interface CharacteristicChangedEvent {
  characteristicUuid: string;
  data: string;
}
```

## Requirements

- React Native 0.60 or higher
- iOS 11.0 or higher
- Android 5.0 (API level 21) or higher
- Xcode 12 or higher
- Android Studio 4.0 or higher

## License

MIT 