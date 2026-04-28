import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/storage/secure_storage_service.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement_models.dart';

class HistoryNotifier
    extends AutoDisposeAsyncNotifier<List<MeasurementHistoryModel>> {
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<MeasurementHistoryModel>> build() async {
    _page = 1;
    final initialItems = await _fetchPage(1);
    _hasMore = initialItems.length >= 20;
    return initialItems;
  }

  Future<List<MeasurementHistoryModel>> _fetchPage(int page) async {
    final storage = ref.read(secureStorageServiceProvider);
    final repo = ref.read(measurementRepositoryProvider);
    final userId = await storage.readUserId();
    if (userId == null) return [];
    return repo.getMeasurementsByUser(userId, page: page, pageSize: 20);
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    try {
      final nextPage = _page + 1;
      final newItems = await _fetchPage(nextPage);

      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _page = nextPage;
        _hasMore = newItems.length >= 20;
        final currentItems = state.value ?? [];
        state = AsyncValue.data([...currentItems, ...newItems]);
      }
    } finally {
      _isLoadingMore = false;
    }
  }
}

final historyProvider =
    AsyncNotifierProvider.autoDispose<
      HistoryNotifier,
      List<MeasurementHistoryModel>
    >(HistoryNotifier.new);

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Historial',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Registro de tus mediciones',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: historyState.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.danger,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              error.toString().replaceAll('Exception: ', ''),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => ref.invalidate(historyProvider),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (measurements) {
                      if (measurements.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                color: AppColors.textMuted.withValues(
                                  alpha: 0.4,
                                ),
                                size: 64,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Sin mediciones aún',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tus mediciones aparecerán aquí',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async {
                          ref.invalidate(historyProvider);
                          await ref.read(historyProvider.future);
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount:
                              measurements.length +
                              (ref.read(historyProvider.notifier).hasMore
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index == measurements.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            }
                            final m = measurements[index];
                            return _MeasurementCard(measurement: m);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({required this.measurement});

  final MeasurementHistoryModel measurement;

  Color _getLevelColor(double level) {
    if (level < 0.25) return AppColors.trafficGreen;
    if (level < 0.5) return AppColors.trafficYellow;
    return AppColors.trafficRed;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getLevelColor(measurement.alcoholLevel);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final localTime = measurement.timestamp.toLocal();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Level indicator
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
            ),
            child: Center(
              child: Text(
                measurement.alcoholLevel.toStringAsFixed(2),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${measurement.alcoholLevel.toStringAsFixed(2)} mg/l',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dateFormat.format(localTime)} · ${timeFormat.format(localTime)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Location
          if (measurement.latitude != 0.0 || measurement.longitude != 0.0)
            InkWell(
              onTap: () async {
                final uri = Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=${measurement.latitude},${measurement.longitude}',
                );
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.info,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Ver en Mapa',
                      style: TextStyle(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
