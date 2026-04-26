import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/intervention.dart';
import '../../../injection_container.dart';
import '../../../services/connectivity_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/intervention/intervention_bloc.dart';
import '../../widgets/intervention_card.dart';
import '../../widgets/sync_indicator.dart';
import 'intervention_detail_screen.dart';

class InterventionListScreen extends StatefulWidget {
  const InterventionListScreen({super.key});

  @override
  State<InterventionListScreen> createState() => _InterventionListScreenState();
}

class _InterventionListScreenState extends State<InterventionListScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    context.read<InterventionBloc>().add(const LoadInterventions());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    context
        .read<InterventionBloc>()
        .add(const LoadInterventions(forceRefresh: true));
    await Future.delayed(const Duration(milliseconds: 600));
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.confirmLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(Intervention intervention) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            InterventionDetailScreen(interventionId: intervention.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _AppHeader(onLogout: _handleLogout),
          _OfflineBanner(),
          Expanded(
            child: BlocBuilder<InterventionBloc, InterventionState>(
              builder: (context, state) {
                if (state is InterventionLoading) {
                  return const _LoadingView();
                }

                if (state is InterventionError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: _handleRefresh,
                  );
                }

                List<Intervention> interventions = [];
                bool isRefreshing = false;

                if (state is InterventionsLoaded) {
                  interventions = state.interventions
                      .where((i) =>
                          i.etat != 'termine' &&
                          i.etat != 'terminee' &&
                          !i.isCompleted)
                      .toList();
                  isRefreshing = state.isRefreshing;

                  // Trigger fade-in on first load
                  if (!_fadeController.isCompleted && interventions.isNotEmpty) {
                    _fadeController.forward();
                  }
                }

                if (interventions.isEmpty) {
                  return _EmptyView(onRefresh: _handleRefresh);
                }

                return Column(
                  children: [
                    _SummaryBar(interventions: interventions),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _handleRefresh,
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                        child: Stack(
                          children: [
                            FadeTransition(
                              opacity: _fadeController,
                              child: ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                    16, 8, 16, 24),
                                itemCount: interventions.length,
                                itemBuilder: (ctx, index) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 12),
                                  child: InterventionCard(
                                    intervention: interventions[index],
                                    onTap: () => _navigateToDetail(
                                        interventions[index]),
                                  ),
                                ),
                              ),
                            ),
                            if (isRefreshing)
                              const Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: LinearProgressIndicator(
                                  minHeight: 3,
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── App Header ───────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  final VoidCallback onLogout;

  const _AppHeader({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 14, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF1565C0)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon + titles
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.build_circle_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes Interventions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'AstroTech Mobile',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          const SyncIndicator(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: onLogout,
            tooltip: AppStrings.logout,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Bar ──────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final List<Intervention> interventions;

  const _SummaryBar({required this.interventions});

  @override
  Widget build(BuildContext context) {
    final enCours =
        interventions.where((i) => i.etat == 'en_cours').length;
    final planifiees =
        interventions.where((i) => i.etat == 'planifie').length;
    final urgent = interventions
        .where((i) =>
            i.priorite?.toLowerCase() == 'urgent' ||
            i.priorite?.toLowerCase() == 'urgente')
        .length;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          _SummaryChip(
            icon: Icons.play_circle_rounded,
            label: '$enCours en cours',
            color: AppColors.statusEnCours,
            surface: AppColors.statusEnCoursSurface,
          ),
          const SizedBox(width: 8),
          _SummaryChip(
            icon: Icons.schedule_rounded,
            label: '$planifiees planifiée${planifiees > 1 ? "s" : ""}',
            color: AppColors.statusPlanifie,
            surface: AppColors.statusPlanifieSurface,
          ),
          if (urgent > 0) ...[
            const SizedBox(width: 8),
            _SummaryChip(
              icon: Icons.priority_high_rounded,
              label: '$urgent urgent${urgent > 1 ? "es" : "e"}',
              color: AppColors.priorityUrgent,
              surface: AppColors.priorityUrgentSurface,
            ),
          ],
          const Spacer(),
          Text(
            '${interventions.length} total',
            style: const TextStyle(
              color: AppColors.textHint,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color surface;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Offline Banner ───────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: getIt<ConnectivityService>().connectivityStream,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        if (isOnline) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: AppColors.offline,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 14, color: Colors.white),
              SizedBox(width: 8),
              Text(
                AppStrings.offlineMode,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── State Views ──────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Chargement des interventions…',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Impossible de charger',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(AppStrings.retry),
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.statusPlanifieSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 44,
                color: AppColors.statusPlanifie,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucune intervention',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toutes vos interventions actives\napparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(AppStrings.refresh),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
