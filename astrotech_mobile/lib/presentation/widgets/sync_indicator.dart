import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/repositories/intervention_repository.dart';
import '../../injection_container.dart';
import '../../services/background_sync_service.dart';
import '../../services/connectivity_service.dart';

class SyncIndicator extends StatefulWidget {
  const SyncIndicator({super.key});

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> {
  int _pendingCount = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkPendingSync();

    // Listen to connectivity changes
    getIt<ConnectivityService>().connectivityStream.listen((isConnected) {
      if (isConnected) {
        _triggerSync();
      }
    });
  }

  Future<void> _checkPendingSync() async {
    try {
      final count = await getIt<InterventionRepository>().getPendingSyncCount();
      if (mounted) {
        setState(() {
          _pendingCount = count;
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _triggerSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      await BackgroundSyncService.triggerImmediateSync();
      // Wait a bit then check pending count
      await Future.delayed(const Duration(seconds: 2));
      await _checkPendingSync();
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingCount == 0 && !_isSyncing) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: _isSyncing ? null : _triggerSync,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isSyncing
                ? AppColors.syncing.withOpacity(0.2)
                : AppColors.warning.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSyncing)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.syncing),
                  ),
                )
              else
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 16,
                  color: AppColors.warning,
                ),
              const SizedBox(width: 6),
              Text(
                _isSyncing ? 'Sync...' : '$_pendingCount',
                style: TextStyle(
                  color: _isSyncing ? AppColors.syncing : AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
