import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app_theme.dart';
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
  final _levelController = TextEditingController(text: '0.00');
  final _latController = TextEditingController(text: '40.4168');
  final _lngController = TextEditingController(text: '-3.7038');
  MeasurementResultModel? _result;
  String? _errorMessage;
  bool _isLoading = false;
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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _levelController.dispose();
    _latController.dispose();
    _lngController.dispose();
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

  Future<void> _recordMeasurement() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });
    _pulseController.stop();

    final level = double.tryParse(_levelController.text);
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    if (level == null || lat == null || lng == null) {
      setState(() {
        _errorMessage = 'Introduce valores numéricos válidos.';
        _isLoading = false;
      });
      return;
    }

    try {
      final repo = ref.read(measurementRepositoryProvider);
      final result = await repo.recordMeasurement(
        level: level,
        lat: lat,
        lng: lng,
      );

      // Invalidate the history provider to fetch new measurements on next load
      ref.invalidate(historyProvider);

      setState(() => _result = result);
      if (result.color != TrafficLightColor.green) {
        _pulseController.repeat(reverse: true);
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medición de Alcohol'),
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
                const SizedBox(height: 16),
                // Traffic light indicator
                _buildTrafficLight(),
                const SizedBox(height: 32),

                // Result info
                if (_result != null) _buildResultInfo(),
                if (_result != null) const SizedBox(height: 24),

                // Input fields
                Container(
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
                        'Datos de medición',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _levelController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Nivel de alcohol (mg/l)',
                          prefixIcon: Icon(
                            Icons.science_outlined,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _latController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Latitud',
                                prefixIcon: Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _lngController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Longitud',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _recordMeasurement,
                          icon: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            _isLoading ? 'Enviando...' : 'Registrar Medición',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Error
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
