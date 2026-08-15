import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_landmarks2/data/models/landmark_model.dart';
import 'package:smart_landmarks2/domain/repositories/landmark_repository.dart';

enum SortOrder { scoreDesc, scoreAsc, nameAsc }

class LandmarkProvider extends ChangeNotifier {
  final LandmarkRepository _repo;
  LandmarkProvider(this._repo);

  List<LandmarkModel> _all = [];
  bool _loading = false;
  String? _error;
  SortOrder _sortOrder = SortOrder.scoreDesc;
  double _minScore = 0;
  String _search = '';

  bool get loading => _loading;
  String? get error => _error;
  SortOrder get sortOrder => _sortOrder;
  double get minScore => _minScore;
  String get search => _search;

  List<LandmarkModel> get landmarks {
    var list = _all
        .where((l) => l.score >= _minScore)
        .where((l) =>
            _search.isEmpty ||
            l.title.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    switch (_sortOrder) {
      case SortOrder.scoreDesc:
        list.sort((a, b) => b.score.compareTo(a.score));
      case SortOrder.scoreAsc:
        list.sort((a, b) => a.score.compareTo(b.score));
      case SortOrder.nameAsc:
        list.sort((a, b) => a.title.compareTo(b.title));
    }
    return list;
  }

  Future<void> fetchLandmarks({bool forceRefresh = false}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _all = await _repo.getLandmarks(forceRefresh: forceRefresh);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSortOrder(SortOrder o) {
    _sortOrder = o;
    notifyListeners();
  }

  void setMinScore(double v) {
    _minScore = v;
    notifyListeners();
  }

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  Future<bool> deleteLandmark(int id) async {
    try {
      await _repo.deleteLandmark(id);
      _all.removeWhere((l) => l.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createLandmark(
      String title, double lat, double lon, File? image) async {
    try {
      await _repo.createLandmark(title, lat, lon, image);
      // Refresh full list — repository already upserted new landmark to DB
      await fetchLandmarks(forceRefresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
