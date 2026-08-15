import 'package:sqflite/sqflite.dart';
import 'package:smart_landmarks2/core/constants/app_constants.dart';
import 'package:smart_landmarks2/data/local/database/database_helper.dart';
import 'package:smart_landmarks2/data/models/landmark_model.dart';

class LandmarkDao {
  final DatabaseHelper _helper;
  LandmarkDao(this._helper);

  Future<List<LandmarkModel>> getAll() async {
    final db = await _helper.database;
    final rows = await db.query(AppConstants.landmarksTable);
    return rows.map(LandmarkModel.fromMap).toList();
  }

  Future<List<LandmarkModel>> getActive() async {
    final db = await _helper.database;
    final rows = await db.query(
      AppConstants.landmarksTable,
      where: 'is_deleted = 0',
    );
    return rows.map(LandmarkModel.fromMap).toList();
  }

  Future<void> upsertAll(List<LandmarkModel> landmarks) async {
    final db = await _helper.database;
    final batch = db.batch();
    for (final lm in landmarks) {
      batch.insert(
        AppConstants.landmarksTable,
        lm.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> softDelete(int id) async {
    final db = await _helper.database;
    await db.update(
      AppConstants.landmarksTable,
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restore(int id) async {
    final db = await _helper.database;
    await db.update(
      AppConstants.landmarksTable,
      {'is_deleted': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
