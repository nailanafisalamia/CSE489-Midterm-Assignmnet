import 'package:smart_landmarks2/core/constants/app_constants.dart';
import 'package:smart_landmarks2/data/local/database/database_helper.dart';
import 'package:smart_landmarks2/data/models/pending_visit_model.dart';
import 'package:smart_landmarks2/data/models/visit_history_model.dart';

class VisitDao {
  final DatabaseHelper _helper;
  VisitDao(this._helper);

  Future<int> insertHistory(VisitHistoryModel visit) async {
    final db = await _helper.database;
    return db.insert(AppConstants.visitHistoryTable, visit.toMap());
  }

  Future<List<VisitHistoryModel>> getHistory() async {
    final db = await _helper.database;
    final rows = await db.query(
      AppConstants.visitHistoryTable,
      orderBy: 'visited_at DESC',
    );
    return rows.map(VisitHistoryModel.fromMap).toList();
  }

  Future<List<VisitHistoryModel>> getPendingJobs() async {
    final db = await _helper.database;
    final rows = await db.query(
      AppConstants.visitHistoryTable,
      where: "status = 'pending' AND job_id IS NOT NULL",
    );
    return rows.map(VisitHistoryModel.fromMap).toList();
  }

  Future<void> updateHistory(int id, String status, double? distance) async {
    final db = await _helper.database;
    await db.update(
      AppConstants.visitHistoryTable,
      {'status': status, 'distance': distance},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateJobId(int id, String jobId) async {
    final db = await _helper.database;
    await db.update(
      AppConstants.visitHistoryTable,
      {'job_id': jobId, 'status': 'pending'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertPending(PendingVisitModel pending) async {
    final db = await _helper.database;
    return db.insert(AppConstants.pendingVisitsTable, pending.toMap());
  }

  Future<List<PendingVisitModel>> getPending() async {
    final db = await _helper.database;
    final rows = await db.query(AppConstants.pendingVisitsTable,
        orderBy: 'created_at ASC');
    return rows.map(PendingVisitModel.fromMap).toList();
  }

  Future<void> deletePending(int id) async {
    final db = await _helper.database;
    await db.delete(
      AppConstants.pendingVisitsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementRetry(int id) async {
    final db = await _helper.database;
    await db.rawUpdate(
      'UPDATE ${AppConstants.pendingVisitsTable} SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }
}
