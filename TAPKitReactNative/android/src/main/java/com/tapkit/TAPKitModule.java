package com.tapkit;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import android.content.Context;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.util.HashMap;
import java.util.Map;

public class TAPKitModule extends ReactContextBaseJavaModule {
    private final ReactApplicationContext reactContext;
    private BluetoothAdapter bluetoothAdapter;
    private BluetoothLeScanner bluetoothLeScanner;
    private BluetoothGatt bluetoothGatt;
    private Map<String, BluetoothDevice> discoveredDevices = new HashMap<>();

    public TAPKitModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        BluetoothManager bluetoothManager = (BluetoothManager) reactContext.getSystemService(Context.BLUETOOTH_SERVICE);
        bluetoothAdapter = bluetoothManager.getAdapter();
        bluetoothLeScanner = bluetoothAdapter.getBluetoothLeScanner();
    }

    @Override
    public String getName() {
        return "TAPKitModule";
    }

    private final ScanCallback scanCallback = new ScanCallback() {
        @Override
        public void onScanResult(int callbackType, ScanResult result) {
            BluetoothDevice device = result.getDevice();
            String deviceId = device.getAddress();
            discoveredDevices.put(deviceId, device);
            
            WritableMap params = Arguments.createMap();
            params.putString("deviceId", deviceId);
            params.putString("name", device.getName());
            params.putInt("rssi", result.getRssi());
            
            sendEvent("onDeviceFound", params);
        }
    };

    private void sendEvent(String eventName, WritableMap params) {
        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit(eventName, params);
    }

    @ReactMethod
    public void startScanning(Promise promise) {
        try {
            if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled()) {
                promise.reject("BLUETOOTH_ERROR", "Bluetooth is not enabled");
                return;
            }
            bluetoothLeScanner.startScan(scanCallback);
            promise.resolve(null);
        } catch (Exception e) {
            promise.reject("SCAN_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void stopScanning(Promise promise) {
        try {
            bluetoothLeScanner.stopScan(scanCallback);
            promise.resolve(null);
        } catch (Exception e) {
            promise.reject("SCAN_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void connect(String deviceId, Promise promise) {
        try {
            BluetoothDevice device = discoveredDevices.get(deviceId);
            if (device == null) {
                promise.reject("CONNECT_ERROR", "Device not found");
                return;
            }
            
            bluetoothGatt = device.connectGatt(reactContext, false, new BluetoothGattCallback() {
                @Override
                public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
                    if (newState == BluetoothProfile.STATE_CONNECTED) {
                        gatt.discoverServices();
                    } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                        sendEvent("onDisconnected", null);
                    }
                }

                @Override
                public void onServicesDiscovered(BluetoothGatt gatt, int status) {
                    if (status == BluetoothGatt.GATT_SUCCESS) {
                        sendEvent("onConnected", null);
                    }
                }

                @Override
                public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
                    byte[] data = characteristic.getValue();
                    WritableMap params = Arguments.createMap();
                    params.putString("characteristicUuid", characteristic.getUuid().toString());
                    params.putString("data", bytesToHex(data));
                    sendEvent("onCharacteristicChanged", params);
                }
            });
            
            promise.resolve(null);
        } catch (Exception e) {
            promise.reject("CONNECT_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void disconnect(Promise promise) {
        try {
            if (bluetoothGatt != null) {
                bluetoothGatt.disconnect();
                bluetoothGatt = null;
            }
            promise.resolve(null);
        } catch (Exception e) {
            promise.reject("DISCONNECT_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void sendCommand(com.facebook.react.bridge.ReadableMap command, Promise promise) {
        try {
            if (bluetoothGatt == null) {
                promise.reject("COMMAND_ERROR", "Not connected to device");
                return;
            }
            
            String type = command.getString("type");
            // Implement command sending logic based on your protocol
            // This is a placeholder for the actual implementation
            
            promise.resolve(null);
        } catch (Exception e) {
            promise.reject("COMMAND_ERROR", e.getMessage());
        }
    }

    private String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }
} 