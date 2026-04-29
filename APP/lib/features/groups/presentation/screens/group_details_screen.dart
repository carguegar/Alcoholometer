import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:app/features/groups/presentation/controllers/groups_controller.dart';
import 'package:app/features/groups/domain/group_models.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  const GroupDetailsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Ensure user profile is loaded so admin checks work
    Future.microtask(
      () => ref.read(userProfileProvider.notifier).loadProfile(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupDetailsControllerProvider(widget.groupId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/groups'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Detalles del Grupo'),
        actions: [
          IconButton(
            onPressed: () => _showLeaveDialog(context),
            icon: const Icon(
              Icons.exit_to_app_rounded,
              color: AppColors.danger,
            ),
            tooltip: 'Abandonar grupo',
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
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
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref
                      .read(
                        groupDetailsControllerProvider(widget.groupId).notifier,
                      )
                      .load(widget.groupId),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (groupState) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildContent(context, groupState),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, GroupDetailsState groupState) {
    final details = groupState.details;
    final ranking = groupState.ranking;
    final currentUserId = ref.watch(userProfileProvider).value?.id;

    return Column(
      children: [
        // Header card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.info.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.group_rounded,
                        color: AppColors.info,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            details.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${details.members.length} miembros',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Invitation and Limit Info
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.vpn_key_outlined,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Código',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  SelectableText(
                                    details.invitationCode,
                                    style: const TextStyle(
                                      color: AppColors.primaryLight,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: details.invitationCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Código copiado'),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.copy_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Límite',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '${details.alertThresholdLevel} mg/l',
                                    style: const TextStyle(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (details.members
                                    .where((m) => m.userId == currentUserId)
                                    .firstOrNull
                                    ?.isAdmin ??
                                false)
                              IconButton(
                                onPressed: () => _showEditLimitDialog(
                                  context,
                                  details.alertThresholdLevel,
                                ),
                                icon: const Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.warning,
                                  size: 18,
                                ),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Tab bar
       
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            // Hace que el indicador se calcule con el tamaño total del tab
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(2),
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            dividerColor: Colors.transparent,

            tabs: const [
              // Más padding horizontal (aire a los lados)
              // Menos padding vertical (arriba/abajo)
              Tab(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text('Miembros'),
                ),
              ),
              Tab(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text('Ranking'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),


        // Tab views
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref
                  .read(groupDetailsControllerProvider(widget.groupId).notifier)
                  .load(widget.groupId);
            },
            child: TabBarView(
              controller: _tabController,
              children: [
                _MembersTab(
                  members: details.members,
                  currentUserId: currentUserId,
                  onKick: (userId) async {
                    await ref
                        .read(
                          groupDetailsControllerProvider(
                            widget.groupId,
                          ).notifier,
                        )
                        .kickMember(widget.groupId, userId);
                    ref.invalidate(groupsControllerProvider);
                  },
                  onPromote: (userId) async {
                    await ref
                        .read(
                          groupDetailsControllerProvider(
                            widget.groupId,
                          ).notifier,
                        )
                        .promoteToAdmin(widget.groupId, userId);
                    ref.invalidate(groupsControllerProvider);
                  },
                ),
                _RankingsTab(
                  rankings: ranking.rankings,
                  threshold: details.alertThresholdLevel,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Abandonar Grupo',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          '¿Estás seguro de que deseas abandonar este grupo?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(
                      groupDetailsControllerProvider(widget.groupId).notifier,
                    )
                    .leaveGroup(widget.groupId);
              } catch (_) {
                // Even if the API response fails to parse, the removal may
                // have succeeded server-side. Navigate away regardless.
              }
              if (context.mounted) {
                context.go('/groups');
                ref.invalidate(groupDetailsControllerProvider(widget.groupId));
                ref.invalidate(groupsControllerProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Has abandonado el grupo'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );
  }

  void _showEditLimitDialog(BuildContext context, double currentLimit) {
    final controller = TextEditingController(text: currentLimit.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Editar Límite',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Límite (mg/l)',
            hintText: 'Ej: 0.25',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newLimit = double.tryParse(
                controller.text.replaceAll(',', '.'),
              );
              if (newLimit != null) {
                Navigator.of(ctx).pop();
                try {
                  await ref
                      .read(
                        groupDetailsControllerProvider(widget.groupId).notifier,
                      )
                      .updateGroupConfig(widget.groupId, newLimit);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab({
    required this.members,
    this.currentUserId,
    required this.onKick,
    required this.onPromote,
  });

  final List<GroupMemberModel> members;
  final String? currentUserId;
  final void Function(String) onKick;
  final void Function(String) onPromote;

  @override
  Widget build(BuildContext context) {
    final isCurrentUserAdmin = (currentUserId != null)
        ? (members
                  .where((m) => m.userId == currentUserId)
                  .firstOrNull
                  ?.isAdmin ??
              false)
        : false;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.surfaceLight.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _showMemberInfoDialog(context, member),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: member.isAdmin
                                ? AppColors.accent.withValues(alpha: 0.2)
                                : AppColors.info.withValues(alpha: 0.15),
                          ),
                          child: Center(
                            child: Text(
                              member.firstName.isNotEmpty
                                  ? member.firstName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: member.isAdmin
                                    ? AppColors.accent
                                    : AppColors.info,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.fullName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                member.isAdmin ? 'Administrador' : 'Miembro',
                                style: TextStyle(
                                  color: member.isAdmin
                                      ? AppColors.accent
                                      : AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (member.isAdmin)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: AppColors.accent,
                      size: 16,
                    ),
                  ),
                ),
              if (isCurrentUserAdmin && member.userId != currentUserId)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                    color: AppColors.surface,
                    onSelected: (value) {
                      if (value == 'kick') {
                        onKick(member.userId);
                      } else if (value == 'promote') {
                        onPromote(member.userId);
                      }
                    },
                    itemBuilder: (context) => [
                      if (!member.isAdmin)
                        const PopupMenuItem(
                          value: 'promote',
                          child: Text('Ascender a admin'),
                        ),
                      const PopupMenuItem(
                        value: 'kick',
                        child: Text(
                          'Expulsar miembro',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showMemberInfoDialog(BuildContext context, GroupMemberModel member) {
    final infoItems = <_InfoRow>[];
    if (member.age != null) {
      infoItems.add(_InfoRow(Icons.cake_rounded, 'Edad', '${member.age} años'));
    }
    if (member.birthDate != null) {
      final d = member.birthDate!;
      infoItems.add(_InfoRow(
        Icons.calendar_today_rounded,
        'Cumpleaños',
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}',
      ));
    }
    if (member.heightCm > 0) {
      infoItems.add(_InfoRow(
        Icons.height_rounded,
        'Altura',
        '${member.heightCm.toStringAsFixed(0)} cm',
      ));
    }
    if (member.weightKg > 0) {
      infoItems.add(_InfoRow(
        Icons.monitor_weight_outlined,
        'Peso',
        '${member.weightKg.toStringAsFixed(1)} kg',
      ));
    }
    if (member.biologicalSex.isNotEmpty) {
      infoItems.add(_InfoRow(
        Icons.person_outline_rounded,
        'Sexo biológico',
        member.biologicalSex,
      ));
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 400.0;
            final dialogWidth = availableWidth > 400 ? 400.0 : availableWidth;
            final contentPadding = dialogWidth < 360 ? 20.0 : 24.0;

            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dialogWidth),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.all(contentPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: member.isAdmin
                              ? AppColors.accent.withValues(alpha: 0.2)
                              : AppColors.info.withValues(alpha: 0.15),
                        ),
                        child: Center(
                          child: Text(
                            member.firstName.isNotEmpty
                                ? member.firstName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: member.isAdmin
                                  ? AppColors.accent
                                  : AppColors.info,
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        member.fullName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: member.isAdmin
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : AppColors.info.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          member.isAdmin ? 'Admin' : 'Miembro',
                          style: TextStyle(
                            color: member.isAdmin
                                ? AppColors.accent
                                : AppColors.info,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (infoItems.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Divider(
                          color: AppColors.surfaceLight.withValues(alpha: 0.4),
                          height: 1,
                        ),
                        const SizedBox(height: 16),
                        ...infoItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 20,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  item.label,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  item.value,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Divider(
                        color: AppColors.surfaceLight.withValues(alpha: 0.4),
                        height: 1,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

class _RankingsTab extends StatelessWidget {
  const _RankingsTab({required this.rankings, required this.threshold});

  final List<RankingMemberModel> rankings;
  final double threshold;

  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              color: AppColors.textMuted.withValues(alpha: 0.4),
              size: 56,
            ),
            const SizedBox(height: 12),
            const Text(
              'Sin datos de ranking',
              style: TextStyle(color: AppColors.textMuted, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: rankings.length,
      itemBuilder: (context, index) {
        final r = rankings[index];
        final position = index + 1;
        Color posColor;
        IconData? posIcon;
        if (position == 1) {
          posColor = const Color(0xFFFFD700);
          posIcon = Icons.emoji_events_rounded;
        } else if (position == 2) {
          posColor = const Color(0xFFC0C0C0);
          posIcon = Icons.emoji_events_rounded;
        } else if (position == 3) {
          posColor = const Color(0xFFCD7F32);
          posIcon = Icons.emoji_events_rounded;
        } else {
          posColor = AppColors.textMuted;
          posIcon = null;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: index == 0
                  ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                  : AppColors.surfaceLight.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              // Position
              SizedBox(
                width: 40,
                child: posIcon != null
                    ? Icon(posIcon, color: posColor, size: 28)
                    : Center(
                        child: Text(
                          '#$position',
                          style: TextStyle(
                            color: posColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.fullName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      dateFormat.format(r.recordTimestamp.toLocal()),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Location button
              if (r.recordLat != 0.0 || r.recordLng != 0.0)
                IconButton(
                  onPressed: () => _openMap(r.recordLat, r.recordLng),
                  icon: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.info,
                  ),
                  tooltip: 'Ver ubicación',
                ),
              const SizedBox(width: 8),
              // Level
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      (r.recordAlcoholLevel >= threshold
                              ? AppColors.trafficRed
                              : AppColors.trafficGreen)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${r.recordAlcoholLevel.toStringAsFixed(2)} mg/l',
                  style: TextStyle(
                    color: r.recordAlcoholLevel >= threshold
                        ? AppColors.trafficRed
                        : AppColors.trafficGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
