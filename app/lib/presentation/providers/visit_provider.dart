import 'package:flutter/material.dart';
import 'package:smart_landmarks2/data/models/visit_history_model.dart';
import 'package:smart_landmarks2/domain/repositories/landmark_repository.dart';

class VisitProvider extends ChangeNotifier {
  final LandmarkRepository _repo;
  VisitProvider(this._repo);

  List<VisitHistoryModel> _history = [];
  bool _loading = false;
  bool _visiting = false;
  String? _error;
  String? _visitMessage;

  List<VisitHistoryModel> get history => _history;
  bool get loading => _loading;
  bool get visiting => _visiting;
  String? get error => _error;
  String? get visitMessage => _visitMessage;

  Future<void> fetchHistory() async {
    _loading = true;
    notifyListeners();
    try {
      _history = await _repo.getVisitHistory();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> visitLandmark(int landmarkId, double lat, double lon) async {
    _visiting = true;
    _error = null;
    _visitMessage = null;
    notifyListeners();
    try {
      final result = await _repo.visitLandmark(landmarkId, lat, lon);
      _visitMessage = result.status == 'offline'
          ? 'Visit queued (offline). Will sync when connected.'
          : 'Visit submitted! Checking distance in background...';
      await fetchHistory();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _visiting = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _error = null;
    _visitMessage = null;
    notifyListeners();
  }
}
