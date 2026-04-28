import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

/// BLE Service for communicating with the alcoholometer hardware device.
/// This service is only available on mobile platforms (Android/iOS).
/// On web, all operations return empty results or throw UnsupportedError.
///
/// Note: flutter_blue_plus is used for BLE communication. The actual
/// integration depends on hardware availability and platform permissions.
class BleService {
  BleService();

  static const String targetServiceUuidStr =
      '0000ffe0-0000-1000-8000-00805f9b34fb';
  static const String targetCharacteristicUuidStr =
      '0000ffe1-0000-1000-8000-00805f9b34fb';

  bool get isAvailable => !kIsWeb;

  /// Simulates scanning for BLE devices.
  /// In production, this would use flutter_blue_plus to scan for nearby
  /// alcoholometer devices. Returns device names and IDs.
  Future<List<Map<String, String>>> scanDevices({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (kIsWeb) return [];
    // BLE scanning will be done when connecting real hardware.
    // This is a placeholder for the BLE integration.
    await Future<void>.delayed(timeout);
    return [];
  }

  Future<void> stopScan() async {
    if (kIsWeb) return;
  }

  /// Parses an alcohol level reading from raw BLE data.
  double? parseAlcoholLevel(List<int> rawBytes) {
    try {
      final rawValue = utf8.decode(rawBytes);
      return double.tryParse(rawValue.trim());
    } catch (_) {
      return null;
    }
  }
}
