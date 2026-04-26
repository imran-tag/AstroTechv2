import 'package:workmanager/workmanager.dart';

import '../injection_container.dart';
import '../domain/repositories/intervention_repository.dart';
import 'connectivity_service.dart';

const String syncTaskName = 'astrotech.sync';
const String syncTaskUniqueName = 'astrotech.sync.unique';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Re-initialize dependencies for background isolate
      await configureDependencies();

      final connectivityService = getIt<ConnectivityService>();
      final isConnected = await connectivityService.isConnected;

      if (!isConnected) {
        return Future.value(true); // Will retry later
      }

      final interventionRepository = getIt<InterventionRepository>();
      await interventionRepository.syncOfflineData();

      return Future.value(true);
    } catch (e) {
      print('Background sync error: $e');
      return Future.value(false);
    }
  });
}

class BackgroundSyncService {
  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );

      // Register periodic task (every 15 minutes)
      await Workmanager().registerPeriodicTask(
        syncTaskUniqueName,
        syncTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e) {
      // WorkManager initialization can fail on some devices
      // The app will still work but background sync won't be available
      print('Background sync service initialization failed: $e');
    }
  }

  static Future<void> triggerImmediateSync() async {
    await Workmanager().registerOneOffTask(
      '${syncTaskUniqueName}_immediate_${DateTime.now().millisecondsSinceEpoch}',
      syncTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }
}
