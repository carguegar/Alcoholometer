import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Nordic UART Service (NUS) UUIDs.
const String nusServiceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
const String nusRxCharUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e'; // write
const String nusTxCharUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // notify

/// BLE Service for communicating with the alcoholometer hardware device
/// over the Nordic UART Service (NUS).
///
/// Available on Android/iOS. On other platforms `isAvailable` returns false
/// and operations become no-ops or throw.
class BleService {
  BleService();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxChar; // write -> device

  StreamSubscription<List<int>>? _txSubscription;
  final StreamController<double> _measurementsController =
      StreamController<double>.broadcast();

  bool get isAvailable => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  BluetoothDevice? get connectedDevice => _device;

  // ── Bluetooth Adapter State ──

  /// Stream of adapter state changes (on/off/turningOn/turningOff/etc.).
  Stream<BluetoothAdapterState> get adapterState {
    if (!isAvailable) {
      return Stream<BluetoothAdapterState>.value(
        BluetoothAdapterState.unavailable,
      );
    }
    return FlutterBluePlus.adapterState;
  }

  /// Returns true if the Bluetooth adapter is currently ON.
  Future<bool> isBluetoothOn() async {
    if (!isAvailable) return false;
    try {
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }

  /// Attempt to turn on the Bluetooth adapter.
  /// On Android this shows a system dialog; on iOS it opens settings prompt.
  /// Returns true if BT is on after the request.
  Future<bool> requestBluetoothOn() async {
    if (!isAvailable) return false;
    try {
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      }
      // Wait briefly for state to settle.
      final state = await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 8), onTimeout: () async {
        final current = await FlutterBluePlus.adapterState.first;
        return current;
      });
      return state == BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }

  /// Request the runtime permissions needed for BLE on Android/iOS.
  /// Returns true if all required permissions are granted (or on platforms
  /// where they don't apply). Returns false on web.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    final results = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return results.values.every(
      (s) => s.isGranted || s.isLimited || s.isProvisional,
    );
  }

  /// Scans for devices advertising the NUS service. Emits the cumulative
  /// deduplicated list of [BluetoothDevice]s found while scanning. Stops
  /// the scan when the subscription is cancelled.
  Stream<List<BluetoothDevice>> scanDevices({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    if (!isAvailable) {
      yield <BluetoothDevice>[];
      return;
    }

    // Always stop any previous scan to avoid stale state.
    // This is the key fix for the reconnection bug: after disconnect,
    // FlutterBluePlus can have leftover scan state that prevents new scans.
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    // Small delay to let the adapter fully reset after stopping.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(nusServiceUuid)],
        timeout: timeout,
      );
    } catch (_) {
      yield <BluetoothDevice>[];
      return;
    }

    // Use onScanResults instead of scanResults to get fresh results
    // and avoid issues with cached/stale streams.
    try {
      await for (final results in FlutterBluePlus.onScanResults) {
        if (results.isNotEmpty) {
          final seen = <String>{};
          final devices = <BluetoothDevice>[];
          for (final r in results) {
            final id = r.device.remoteId.str;
            if (seen.add(id)) devices.add(r.device);
          }
          yield devices;
        }
      }
    } finally {
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
    }
  }

  Future<void> stopScan() async {
    if (!isAvailable) return;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  /// Connect to [device], discover services and subscribe to NUS TX
  /// notifications. Throws if the NUS service or characteristics are missing.
  Future<void> connect(BluetoothDevice device) async {
    if (!isAvailable) {
      throw UnsupportedError('BLE not supported on this platform');
    }

    // Make sure scanning is stopped before attempting to connect.
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    await device.connect(license: License.free);

    final services = await device.discoverServices();
    final svcGuid = Guid(nusServiceUuid);
    final rxGuid = Guid(nusRxCharUuid);
    final txGuid = Guid(nusTxCharUuid);

    BluetoothService? nus;
    for (final s in services) {
      if (s.uuid == svcGuid) {
        nus = s;
        break;
      }
    }
    if (nus == null) {
      await device.disconnect();
      throw StateError('NUS service not found on device');
    }

    BluetoothCharacteristic? rx;
    BluetoothCharacteristic? tx;
    for (final c in nus.characteristics) {
      if (c.uuid == rxGuid) rx = c;
      if (c.uuid == txGuid) tx = c;
    }
    if (rx == null || tx == null) {
      await device.disconnect();
      throw StateError('NUS RX/TX characteristics not found');
    }

    await tx.setNotifyValue(true);

    await _txSubscription?.cancel();
    _txSubscription = tx.onValueReceived.listen((bytes) {
      final value = parseAlcoholLevel(bytes);
      if (value != null) {
        _measurementsController.add(value);
      }
    });

    _device = device;
    _rxChar = rx;
  }

  /// Disconnect the current device and tear down subscriptions.
  Future<void> disconnect() async {
    final dev = _device;
    await _txSubscription?.cancel();
    _txSubscription = null;
    _rxChar = null;
    _device = null;
    if (dev != null) {
      try {
        await dev.disconnect();
      } catch (_) {}
    }
  }

  /// Stream of mg/L values parsed from TX notifications. The `READY\n`
  /// heartbeat and any unparsable payloads are filtered out.
  Stream<double> get measurements => _measurementsController.stream;

  /// Send the start-measurement command to the device.
  Future<void> startMeasurement() async {
    final rx = _rxChar;
    if (rx == null) {
      throw StateError('Not connected to a device');
    }
    final bytes = utf8.encode('INICIAR\n');
    await rx.write(bytes, withoutResponse: false);
  }

  /// Connection state of the current device, or a stream that emits
  /// [BluetoothConnectionState.disconnected] when no device is connected.
  Stream<BluetoothConnectionState> get connectionState {
    final dev = _device;
    if (dev == null) {
      return Stream<BluetoothConnectionState>.value(
        BluetoothConnectionState.disconnected,
      );
    }
    return dev.connectionState;
  }

  /// Parse an mg/L value from the raw payload. Returns null for the
  /// `READY\n` heartbeat or any non-numeric content.
  double? parseAlcoholLevel(List<int> bytes) {
    try {
      final raw = utf8.decode(bytes, allowMalformed: true).trim();
      if (raw.isEmpty) return null;
      if (raw.toUpperCase() == 'READY') return null;
      return double.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _txSubscription?.cancel();
    await _measurementsController.close();
  }
}
