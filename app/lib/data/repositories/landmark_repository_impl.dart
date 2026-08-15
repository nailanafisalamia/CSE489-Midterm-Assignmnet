import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:smart_landmarks2/data/local/dao/landmark_dao.dart';
import 'package:smart_landmarks2/data/local/dao/visit_dao.dart';
import 'package:smart_landmarks2/data/models/landmark_model.dart';
import 'package:smart_landmarks2/data/models/pending_visit_model.dart';
import 'package:smart_landmarks2/data/models/visit_history_model.dart';
import 'package:smart_landmarks2/data/remote/api_service.dart';
import 'package:smart_landmarks2/domain/repositories/landmark_repository.dart';

class LandmarkRepositoryImpl implements LandmarkRepository {
  final ApiService _api;
  final LandmarkDao _landmarkDao;
  final VisitDao _visitDao;

  LandmarkRepositoryImpl(this._api, this._landmarkDao, this._visitDao);

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  @override
  Future<List<LandmarkModel>> getLandmarks(
      {bool forceRefresh = false}) async {
    Object? fetchError;
    if (forceRefresh || await _isOnline()) {
      try {
        final remote = await _api.getLandmarks();
        await _landmarkDao.upsertAll(remote);
      } catch (e) {
        fetchError = e;
      }
    }
    final cached = await _landmarkDao.getActive();
    // Only surface the error if the cache is also empty (fresh install)
    if (cached.isEmpty && fetchError != null) throw fetchError;
    return cached;
  }

  @override
  Future<VisitHistoryModel> visitLandmark(
      int id, double lat, double lon) async {
    final landmarkList = await _landmarkDao.getAll();
    final landmark = landmarkList.firstWhere(
      (l) => l.id == id,
      orElse: () => LandmarkModel(
          id: id, title: 'Unknown', lat: 0, lon: 0, image: '',
          visitCount: 0, avgDistance: 0, score: 0),
    );

    if (await _isOnline()) {
      final res = await _api.visitLandmark(id, lat, lon);
      final jobId = res['job_id']?.toString();
      final visit = VisitHistoryModel(
        landmarkId: id,
        landmarkTitle: landmark.title,
        jobId: jobId,
        status: 'pending',
        visitedAt: DateTime.now().millisecondsSinceEpoch,
        userLat: lat,
        userLon: lon,
      );
      final dbId = await _visitDao.insertHistory(visit);
      return VisitHistoryModel(
        id: dbId,
        landmarkId: visit.landmarkId,
        landmarkTitle: visit.landmarkTitle,
        jobId: visit.jobId,
        status: visit.status,
        visitedAt: visit.visitedAt,
        userLat: visit.userLat,
        userLon: visit.userLon,
      );
    } else {
      final pending = PendingVisitModel(
        landmarkId: id,
        userLat: lat,
        userLon: lon,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _visitDao.insertPending(pending);
      final visit = VisitHistoryModel(
        landmarkId: id,
        landmarkTitle: landmark.title,
        jobId: null,
        status: 'offline',
        visitedAt: DateTime.now().millisecondsSinceEpoch,
        userLat: lat,
        userLon: lon,
      );
      final dbId = await _visitDao.insertHistory(visit);
      return VisitHistoryModel(
        id: dbId,
        landmarkId: visit.landmarkId,
        landmarkTitle: visit.landmarkTitle,
        jobId: visit.jobId,
        status: visit.status,
        visitedAt: visit.visitedAt,
        userLat: visit.userLat,
        userLon: visit.userLon,
      );
    }
  }

  @override
  Future<List<VisitHistoryModel>> getVisitHistory() =>
      _visitDao.getHistory();

  @override
  Future<void> deleteLandmark(int id) async {
    await _api.deleteLandmark(id);
    await _landmarkDao.softDelete(id);
  }

  @override
  Future<void> restoreLandmark(int id) async {
    await _api.restoreLandmark(id);
    await _landmarkDao.restore(id);
  }

  @override
  Future<LandmarkModel> createLandmark(
      String title, double lat, double lon, File? image) async {
    final model = await _api.createLandmark(title, lat, lon, image);
    await _landmarkDao.upsertAll([model]);
    return model;
  }

  @override
  Future<void> syncPendingVisits() async {
    final pending = await _visitDao.getPending();
    for (final p in pending) {
      try {
        final res = await _api.visitLandmark(p.landmarkId, p.userLat, p.userLon);
        final jobId = res['job_id']?.toString();
        if (jobId != null) {
          final offlineHistory = await _visitDao.getHistory();
          final match = offlineHistory.where((v) =>
              v.landmarkId == p.landmarkId &&
              v.status == 'offline' &&
              v.jobId == null).toList();
          if (match.isNotEmpty && match.first.id != null) {
            await _visitDao.updateJobId(match.first.id!, jobId);
          }
        }
        await _visitDao.deletePending(p.id!);
      } catch (_) {
        await _visitDao.incrementRetry(p.id!);
      }
    }
  }
}
