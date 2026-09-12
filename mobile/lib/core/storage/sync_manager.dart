import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../domain/models/session_record.dart';
import '../../domain/models/profile_record.dart';
import '../network/api_client.dart';
import 'app_database.dart';

class SyncResult {
  final bool synced;
  final String? message;
  final Map<String, dynamic>? serverResponse;

  SyncResult({required this.synced, this.message, this.serverResponse});
}

class SyncManager {
  final ApiClient apiClient;

  SyncManager(this.apiClient);

  Future<SyncResult> saveAndSyncSession(SessionRecord session) async {
    final db = await AppDatabase.instance;

    // 1. Insert session record in SQLite
    await db.insert(
      'local_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 2. Insert attempts in SQLite
    final batch = db.batch();
    for (final att in session.attempts) {
      batch.insert(
        'local_attempts',
        att.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);

    // 3. Update local cached profile immediately
    await _updateLocalProfileFromSession(session);

    // 4. Try syncing with backend
    try {
      final isHealthy = await apiClient.checkHealth();
      if (!isHealthy) {
        await _enqueueForSync(session);
        return SyncResult(
          synced: false,
          message: 'Saved locally. Will sync when back online.',
        );
      }

      // First create/register session
      await apiClient.createSession({
        'id': session.id,
        'game_mode': session.gameMode,
        'started_at': session.startedAt.toIso8601String(),
        'level': session.level,
      });

      // Complete session
      final completeRes = await apiClient.completeSession(
        session.id,
        session.toCompleteJson(),
      );

      if (completeRes.isSuccess && completeRes.data != null) {
        // Mark session synced in SQLite
        await db.update(
          'local_sessions',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [session.id],
        );
        // Remove from sync queue if exists
        await db.delete(
          'sync_queue',
          where: 'session_id = ?',
          whereArgs: [session.id],
        );

        return SyncResult(
          synced: true,
          message: 'Session synced with server.',
          serverResponse: completeRes.data,
        );
      } else {
        await _enqueueForSync(session);
        return SyncResult(
          synced: false,
          message: 'Saved locally. Synced queued (${completeRes.errorMessage ?? "Network error"}).',
        );
      }
    } catch (e) {
      await _enqueueForSync(session);
      return SyncResult(
        synced: false,
        message: 'Saved locally. Will sync when connection returns.',
      );
    }
  }

  Future<void> _enqueueForSync(SessionRecord session) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'sync_queue',
      {
        'session_id': session.id,
        'payload_json': jsonEncode(session.toCompleteJson()),
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> syncPendingQueue() async {
    final db = await AppDatabase.instance;
    final queued = await db.query('sync_queue');
    if (queued.isEmpty) return 0;

    final isHealthy = await apiClient.checkHealth();
    if (!isHealthy) return 0;

    int syncedCount = 0;
    for (final row in queued) {
      final sessionId = row['session_id'] as String;
      final payload = jsonDecode(row['payload_json'] as String) as Map<String, dynamic>;

      try {
        final res = await apiClient.completeSession(sessionId, payload);
        if (res.isSuccess) {
          await db.update(
            'local_sessions',
            {'is_synced': 1},
            where: 'id = ?',
            whereArgs: [sessionId],
          );
          await db.delete(
            'sync_queue',
            where: 'session_id = ?',
            whereArgs: [sessionId],
          );
          syncedCount++;
        }
      } catch (_) {
        // Will retry next cycle
      }
    }
    return syncedCount;
  }

  Future<void> _updateLocalProfileFromSession(SessionRecord session) async {
    final db = await AppDatabase.instance;
    final existing = await db.query('cached_profile', limit: 1);

    int totalSessions = 1;
    int totalTime = session.duration;
    int totalXp = (session.score * 0.1).floor();
    int currentStreak = 1;
    int bestStreak = 1;
    double overallAccuracy = session.accuracy;
    double avgRt = session.averageReactionTime;

    if (existing.isNotEmpty) {
      final row = existing.first;
      totalSessions = (row['total_sessions'] as int) + 1;
      totalTime = (row['total_play_time'] as int) + session.duration;
      totalXp = (row['total_xp'] as int) + (session.score * 0.1).floor();
      
      final oldAcc = (row['overall_accuracy'] as num).toDouble();
      overallAccuracy = ((oldAcc * (totalSessions - 1) + session.accuracy) / totalSessions * 10).round() / 10.0;

      final oldRt = (row['average_reaction_time'] as num).toDouble();
      if (session.averageReactionTime > 0) {
        avgRt = ((oldRt + session.averageReactionTime) / 2 * 10).round() / 10.0;
      }

      currentStreak = (row['current_streak'] as int) + 1;
      final oldBest = row['best_streak'] as int;
      bestStreak = currentStreak > oldBest ? currentStreak : oldBest;
    }

    final int calculatedLevel = (totalXp ~/ 500) + 1;

    await db.insert(
      'cached_profile',
      {
        'user_id': session.userId,
        'display_name': 'Focus Athlete',
        'current_level': calculatedLevel,
        'total_xp': totalXp,
        'total_sessions': totalSessions,
        'total_play_time': totalTime,
        'overall_accuracy': overallAccuracy,
        'average_reaction_time': avgRt,
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'last_played_date': DateTime.now().toIso8601String().split('T')[0],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ProfileRecord?> getLocalProfile() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('cached_profile', limit: 1);
    if (rows.isNotEmpty) {
      return ProfileRecord.fromMap(rows.first);
    }
    return null;
  }

  Future<List<SessionRecord>> getLocalSessions({int limit = 20}) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'local_sessions',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map((r) => SessionRecord.fromMap(r)).toList();
  }
}
