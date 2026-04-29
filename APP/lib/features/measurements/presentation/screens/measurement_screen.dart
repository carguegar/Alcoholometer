import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/ble/ble_providers.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement_models.dart';
import 'package:app/features/measurements/presentation/screens/history_screen.dart';

class MeasurementScreen extends ConsumerStatefulWidget {
  const MeasurementScreen({super.key});

  @override
  ConsumerState<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends ConsumerState<MeasurementScreen>
    with SingleTickerProviderStateMixin {
  MeasurementResultModel? _result;
  String? _errorMessage;
  bool _isSubmitting = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Prompt for BLE / location permissions on entry; don't block UI.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: discarded_futures
      ref.read(bleServiceProvider).requestPermissions();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getTrafficColor(TrafficLightColor color) {
    switch (color) {
      case TrafficLightColor.green:
        return AppColors.trafficGreen;
      case TrafficLightColor.yellow:
        return AppColors.trafficYellow;
      case TrafficLightColor.red:
        return AppColors.trafficRed;
    }
  }

  IconData _getTrafficIcon(TrafficLightColor color) {
    switch (color) {
      case TrafficLightColor.green:
        return Icons.check_circle_rounded;
      case TrafficLightColor.yellow:
        return Icons.warning_rounded;
      case TrafficLightColor.red:
        return Icons.dangerous_rounded;
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--';
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : null,
      ),
    );
  }

  Future<void> _openDevicePicker() async {
    final svc = ref.read(bleServiceProvider);
    final ok = await svc.requestPermissions();
    if (!ok) {
      _showSnack(
        'Se requieren permisos de Bluetooth y ubicación.',
        error: true,
      );
      return;
    }
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _DevicePickerSheet(),
    );
  }

  Future<void> _takeMeasurement() async {
    final controller = ref.read(bleControllerProvider.notifier);
    final state = ref.read(bleControllerProvider);
    if (!state.isConnected) {
      _showSnack('Conecta primero un dispositivo.', error: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _result = null;
    });
    _pulseController.stop();

    try {
      // 1. Location permission.
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _showSnack(
          'Se requiere ubicación para registrar la medición',
          error: true,
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // 2. Resolve current position.
      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } on TimeoutException {
        _showSnack('No se pudo obtener ubicación', error: true);
        setState(() => _isSubmitting = false);
        return;
      }

      // 3. Trigger measurement (writes INICIAR, awaits TX notification).
      _showSnack('Soplando... espera 5 segundos');
      final reading = await controller.triggerMeasurement(
        timeout: const Duration(seconds: 15),
      );

      // 4. POST to API.
      if (!mounted) return;
      final repo = ref.read(measurementRepositoryProvider);
      final result = await repo.recordMeasurement(
        level: reading,
        lat: pos.latitude,
        lng: pos.longitude,
      );

      ref.invalidate(historyProvider);

      if (!mounted) return;
      setState(() => _result = result);
      if (result.color != TrafficLightColor.green) {
        _pulseController.repeat(reverse: true);
      }
      _showSnack('Medición registrada: ${reading.toStringAsFixed(2)} mg/L');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registrar Medición'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                if (ble.isConnected) _buildStatusChip(ble.device),
                const SizedBox(height: 16),
                _buildTrafficLight(),
                const SizedBox(height: 32),

                if (_result != null) _buildResultInfo(),
                if (_result != null) const SizedBox(height: 24),

                _buildBleSection(ble),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.danger,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BluetoothDevice? device) {
    final name = (device?.platformName.isNotEmpty ?? false)
        ? device!.platformName
        : (device?.advName.isNotEmpty ?? false)
            ? device!.advName
            : (device?.remoteId.str ?? 'Dispositivo');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bluetooth_connected,
              size: 16, color: AppColors.success),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Conectado a $name',
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => ref.read(bleControllerProvider.notifier).disconnect(),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, size: 16, color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBleSection(BleControllerState ble) {
    if (ble.isConnecting) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Conectando...'),
          ],
        ),
      );
    }

    if (!ble.isConnected) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.surfaceLight.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.bluetooth_searching,
                color: AppColors.primary, size: 36),
            const SizedBox(height: 12),
            const Text(
              'Conecta tu alcoholímetro por Bluetooth para comenzar',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _openDevicePicker,
                icon: const Icon(Icons.search),
                label: const Text('Buscar dispositivos'),
              ),
            ),
            const SizedBox(height: 8),
            // Disabled "Registrar Medición" button (gated until connected).
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Registrar Medición'),
              ),
            ),
          ],
        ),
      );
    }

    // Connected & idle.
    final busy = _isSubmitting || ble.isMeasuring;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Listo para medir',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Pulsa el botón para iniciar el soplido y registrar la medición.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: busy ? null : _takeMeasurement,
              icon: busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.air),
              label: Text(busy ? 'Midiendo...' : 'Tomar medición'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficLight() {
    final color = _result != null
        ? _getTrafficColor(_result!.color)
        : AppColors.surfaceLight;
    final icon = _result != null
        ? _getTrafficIcon(_result!.color)
        : Icons.traffic_rounded;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale =
            _result != null && _result!.color != TrafficLightColor.green
            ? _pulseAnimation.value
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(icon, size: 80, color: color),
          ),
        );
      },
    );
  }

  Widget _buildResultInfo() {
    final color = _getTrafficColor(_result!.color);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            _result!.message,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_result!.estimatedTimeToGreen != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Tiempo estimado: ${_formatDuration(_result!.estimatedTimeToGreen)}',
                  style: TextStyle(color: color, fontSize: 15),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DevicePickerSheet extends ConsumerStatefulWidget {
  const _DevicePickerSheet();

  @override
  ConsumerState<_DevicePickerSheet> createState() => _DevicePickerSheetState();
}

class _DevicePickerSheetState extends ConsumerState<_DevicePickerSheet> {
  late final Stream<List<BluetoothDevice>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = ref
        .read(bleServiceProvider)
        .scanDevices(timeout: const Duration(seconds: 8));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.bluetooth_searching,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Dispositivos cercanos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320, minHeight: 80),
              child: StreamBuilder<List<BluetoothDevice>>(
                stream: _stream,
                builder: (context, snap) {
                  final devices = snap.data ?? const <BluetoothDevice>[];
                  if (snap.connectionState == ConnectionState.waiting &&
                      devices.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (devices.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Buscando alcoholímetros...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: devices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final d = devices[i];
                      final name = d.platformName.isNotEmpty
                          ? d.platformName
                          : d.advName.isNotEmpty
                              ? d.advName
                              : d.remoteId.str;
                      return ListTile(
                        leading: const Icon(Icons.bluetooth,
                            color: AppColors.primary),
                        title: Text(name),
                        subtitle: Text(
                          d.remoteId.str,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () async {
                          final controller =
                              ref.read(bleControllerProvider.notifier);
                          Navigator.of(ctx).pop();
                          try {
                            await controller.connect(d);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al conectar: $e'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
