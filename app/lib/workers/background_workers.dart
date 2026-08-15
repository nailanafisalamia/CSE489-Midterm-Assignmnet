import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'package:smart_landmarks2/core/constants/app_constants.dart';
import 'package:smart_landmarks2/data/local/dao/landmark_dao.dart';
import 'package:smart_landmarks2/data/local/dao/visit_dao.dart';
import 'package:smart_landmarks2/data/local/database/database_helper.dart';
import 'package:smart_landmarks2/data/remote/api_service.dart';
import 'package:smart_landmarks2/data/repositories/landmark_repository_impl.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final db = DatabaseHelper();
    final api = ApiService();
    final landmarkDao = LandmarkDao(db);
    final visitDao = VisitDao(db);
    final repo = LandmarkRepositoryImpl(api, landmarkDao, visitDao);

    switch (taskName) {
      case AppConstants.jobPollingTask:
        return _pollPendingJobs(visitDao, api);
      case AppConstants.offlineSyncTask:
        return _syncOfflineVisits(repo);
    }
    return true;
  });
}

Future<bool> _pollPendingJobs(VisitDao visitDao, ApiService api) async {
  try {
    final pending = await visitDao.getPendingJobs();
    for (final visit in pending) {
      if (visit.jobId == null) continue;
      try {
        final res = await api.getJobStatus(visit.jobId!);
        final status = res['status'] as String;
        if (status == 'done') {
          final dist = (res['distance'] as num?)?.toDouble();
          await visitDao.updateHistory(visit.id!, 'done', dist);
        } else if (status == 'failed') {
          await visitDao.updateHistory(visit.id!, 'failed', null);
        }
      } catch (_) {}
    }
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> _syncOfflineVisits(LandmarkRepositoryImpl repo) async {
  final result = await Connectivity().checkConnectivity();
  if (!result.any((r) => r != ConnectivityResult.none)) return false;
  try {
    await repo.syncPendingVisits();
    return true;
  } catch (_) {
    return false;
  }
}

class BackgroundWorkerManager {
  static void initialize() {
    Workmanager().initialize(callbackDispatcher);
  }

  static void registerPeriodicTasks() {
    Workmanager().registerPeriodicTask(
      AppConstants.jobPollingTask,
      AppConstants.jobPollingTask,
      frequency: const Duration(minutes: AppConstants.pollIntervalMinutes),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
    Workmanager().registerPeriodicTask(
      AppConstants.offlineSyncTask,
      AppConstants.offlineSyncTask,
      frequency: const Duration(minutes: AppConstants.pollIntervalMinutes),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  static void scheduleImmediateJobPoll() {
    Workmanager().registerOneOffTask(
      '${AppConstants.jobPollingTask}_immediate',
      AppConstants.jobPollingTask,
      initialDelay: const Duration(seconds: 5),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
}
