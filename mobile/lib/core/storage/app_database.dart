import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _database;
  static const String _dbName = 'focus_flow_local.db';
  static const int _dbVersion = 1;

  static Future<Database> get instance async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        // Sessions table
        await db.execute('''
          CREATE TABLE local_sessions (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            game_mode TEXT NOT NULL,
            started_at TEXT NOT NULL,
            completed_at TEXT,
            duration INTEGER NOT NULL DEFAULT 0,
            level REAL NOT NULL DEFAULT 1.0,
            score INTEGER NOT NULL DEFAULT 0,
            accuracy REAL NOT NULL DEFAULT 0.0,
            average_reaction_time REAL NOT NULL DEFAULT 0.0,
            missed_targets INTEGER NOT NULL DEFAULT 0,
            incorrect_targets INTEGER NOT NULL DEFAULT 0,
            distraction_errors INTEGER NOT NULL DEFAULT 0,
            longest_streak INTEGER NOT NULL DEFAULT 0,
            is_synced INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // Attempts table
        await db.execute('''
          CREATE TABLE local_attempts (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            round_number INTEGER NOT NULL,
            target_type TEXT NOT NULL,
            player_action TEXT NOT NULL,
            correct INTEGER NOT NULL,
            reaction_time REAL NOT NULL,
            distraction_present INTEGER NOT NULL DEFAULT 0,
            timestamp TEXT NOT NULL,
            FOREIGN KEY (session_id) REFERENCES local_sessions(id) ON DELETE CASCADE
          )
        ''');

        // Sync Queue table for offline resilience
        await db.execute('''
          CREATE TABLE sync_queue (
            session_id TEXT PRIMARY KEY,
            payload_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            retry_count INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // Cached Profile table
        await db.execute('''
          CREATE TABLE cached_profile (
            user_id TEXT PRIMARY KEY,
            display_name TEXT NOT NULL,
            current_level INTEGER NOT NULL,
            total_xp INTEGER NOT NULL,
            total_sessions INTEGER NOT NULL,
            total_play_time INTEGER NOT NULL,
            overall_accuracy REAL NOT NULL,
            average_reaction_time REAL NOT NULL,
            current_streak INTEGER NOT NULL,
            best_streak INTEGER NOT NULL,
            last_played_date TEXT
          )
        ''');
      },
    );
  }
}
