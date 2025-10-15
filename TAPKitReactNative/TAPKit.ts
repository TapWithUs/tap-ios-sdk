import { NativeModules, NativeEventEmitter, EmitterSubscription } from 'react-native';

const { TAPKitModule } = NativeModules;
const eventEmitter = new NativeEventEmitter(TAPKitModule);

interface TAPKitInterface {
  startScanning(): Promise<void>;
  stopScanning(): Promise<void>;
  connect(deviceId: string): Promise<void>;
  disconnect(): Promise<void>;
  sendCommand(command: {
    type: string;
    data?: any;
  }): Promise<void>;
  addListener(eventName: string, callback: (event: any) => void): EmitterSubscription;
  removeListener(subscription: EmitterSubscription): void;
}

interface DeviceFoundEvent {
  deviceId: string;
  name: string;
  rssi: number;
}

interface CharacteristicChangedEvent {
  characteristicUuid: string;
  data: string;
}

class TAPKit implements TAPKitInterface {
  private static instance: TAPKit;
  private listeners: Map<string, EmitterSubscription[]> = new Map();

  private constructor() {}

  static getInstance(): TAPKit {
    if (!TAPKit.instance) {
      TAPKit.instance = new TAPKit();
    }
    return TAPKit.instance;
  }

  async startScanning(): Promise<void> {
    try {
      await TAPKitModule.startScanning();
    } catch (error) {
      console.error('Failed to start scanning:', error);
      throw error;
    }
  }

  async stopScanning(): Promise<void> {
    try {
      await TAPKitModule.stopScanning();
    } catch (error) {
      console.error('Failed to stop scanning:', error);
      throw error;
    }
  }

  async connect(deviceId: string): Promise<void> {
    try {
      await TAPKitModule.connect(deviceId);
    } catch (error) {
      console.error('Failed to connect to device:', error);
      throw error;
    }
  }

  async disconnect(): Promise<void> {
    try {
      await TAPKitModule.disconnect();
    } catch (error) {
      console.error('Failed to disconnect:', error);
      throw error;
    }
  }

  async sendCommand(command: { type: string; data?: any }): Promise<void> {
    try {
      await TAPKitModule.sendCommand(command);
    } catch (error) {
      console.error('Failed to send command:', error);
      throw error;
    }
  }

  addListener(eventName: string, callback: (event: any) => void): EmitterSubscription {
    const subscription = eventEmitter.addListener(eventName, callback);
    if (!this.listeners.has(eventName)) {
      this.listeners.set(eventName, []);
    }
    this.listeners.get(eventName)?.push(subscription);
    return subscription;
  }

  removeListener(subscription: EmitterSubscription): void {
    subscription.remove();
    this.listeners.forEach((subs, eventName) => {
      const index = subs.indexOf(subscription);
      if (index !== -1) {
        subs.splice(index, 1);
      }
    });
  }
}

export default TAPKit.getInstance();
export type { DeviceFoundEvent, CharacteristicChangedEvent }; 