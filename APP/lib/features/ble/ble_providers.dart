import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ble_service.dart';

final bleServiceProvider = Provider<BleService>((ref) {
  final svc = BleService();
  ref.onDispose(() {
    svc.dispose();
  });
  return svc;
});

final bleConnectionStateProvider =
    StreamProvider.autoDispose<BluetoothConnectionState>((ref) {
  final svc = ref.watch(bleServiceProvider);
  return svc.connectionState;
});

final bleMeasurementStreamProvider = StreamProvider.autoDispose<double>((ref) {
  final svc = ref.watch(bleServiceProvider);
  return svc.measurements;
});

@immutable
class BleControllerState {
  const BleControllerState({
    this.device,
    this.isScanning = false,
    this.isConnecting = false,
    this.isConnected = false,
    this.isMeasuring = false,
    this.error,
    this.lastReading,
  });

  final BluetoothDevice? device;
  final bool isScanning;
  final bool isConnecting;
  final bool isConnected;
  final bool isMeasuring;
  final String? error;
  final double? lastReading;

  BleControllerState copyWith({
    BluetoothDevice? device,
    bool clearDevice = false,
    bool? isScanning,
    bool? isConnecting,
    bool? isConnected,
    bool? isMeasuring,
    String? error,
    bool clearError = false,
    double? lastReading,
    bool clearLastReading = false,
  }) {
    return BleControllerState(
      device: clearDevice ? null : (device ?? this.device),
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      isMeasuring: isMeasuring ?? this.isMeasuring,
      error: clearError ? null : (error ?? this.error),
      lastReading:
          clearLastReading ? null : (lastReading ?? this.lastReading),
    );
  }
}

class BleController extends StateNotifier<BleControllerState> {
  BleController(this._service) : super(const BleControllerState()) {
    _connStateSub = _service.connectionState.listen((cs) {
      final connected = cs == BluetoothConnectionState.connected;
      state = state.copyWith(
        isConnected: connected,
        isConnecting: connected ? false : state.isConnecting,
        clearDevice: !connected && state.device == null,
      );
      if (!connected) {
        state = state.copyWith(
          isConnected: false,
          isConnecting: false,
        );
      }
    });
  }

  final BleService _service;
  StreamSubscription<BluetoothConnectionState>? _connStateSub;

  BleService get service => _service;

  Future<void> connect(BluetoothDevice device) async {
    state = state.copyWith(
      isConnecting: true,
      clearError: true,
      device: device,
    );
    try {
      await _service.connect(device);
      state = state.copyWith(
        isConnecting: false,
        isConnected: true,
        device: device,
      );
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        clearDevice: true,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      await _service.disconnect();
    } finally {
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        clearDevice: true,
      );
    }
  }

  void setScanning(bool scanning) {
    state = state.copyWith(isScanning: scanning);
  }

  /// Sends `INICIAR` and waits for the next reading from the TX stream.
  /// Returns the value or throws on timeout / no connection.
  Future<double> triggerMeasurement({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!state.isConnected) {
      throw StateError('No device connected');
    }
    state = state.copyWith(isMeasuring: true, clearError: true);
    try {
      // Listen first, then send command, to avoid missing fast replies.
      final future = _service.measurements.first.timeout(timeout);
      await _service.startMeasurement();
      final reading = await future;
      state = state.copyWith(isMeasuring: false, lastReading: reading);
      return reading;
    } catch (e) {
      state = state.copyWith(isMeasuring: false, error: e.toString());
      rethrow;
    }
  }

  @override
  void dispose() {
    _connStateSub?.cancel();
    super.dispose();
  }
}

final bleControllerProvider =
    StateNotifierProvider<BleController, BleControllerState>((ref) {
  return BleController(ref.watch(bleServiceProvider));
});
