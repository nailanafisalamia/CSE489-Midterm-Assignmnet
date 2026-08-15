import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:smart_landmarks2/core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();
  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, AppConstants.dbName),
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.landmarksTable} (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        lat REAL NOT NULL,
        lon REAL NOT NULL,
        image TEXT NOT NULL,
        visit_count INTEGER NOT NULL DEFAULT 0,
        avg_distance REAL NOT NULL DEFAULT 0,
        score REAL NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.visitHistoryTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        landmark_id INTEGER NOT NULL,
        landmark_title TEXT NOT NULL,
        job_id TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        distance REAL,
        visited_at INTEGER NOT NULL,
        user_lat REAL NOT NULL,
        user_lon REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.pendingVisitsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        landmark_id INTEGER NOT NULL,
        user_lat REAL NOT NULL,
        user_lon REAL NOT NULL,
        created_at INTEGER NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
}
