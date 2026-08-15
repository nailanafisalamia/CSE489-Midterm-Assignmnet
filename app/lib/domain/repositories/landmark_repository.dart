import 'dart:io';
import 'package:smart_landmarks2/data/models/landmark_model.dart';
import 'package:smart_landmarks2/data/models/visit_history_model.dart';

abstract class LandmarkRepository {
  Future<List<LandmarkModel>> getLandmarks({bool forceRefresh = false});
  Future<VisitHistoryModel> visitLandmark(int id, double lat, double lon);
  Future<List<VisitHistoryModel>> getVisitHistory();
  Future<void> deleteLandmark(int id);
  Future<void> restoreLandmark(int id);
  Future<LandmarkModel> createLandmark(
      String title, double lat, double lon, File? image);
  Future<void> syncPendingVisits();
}
