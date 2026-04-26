import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../models/intervention_model.dart';

class LocalDatabase {
  static const String _interventionsBox = 'interventions';
  static const String _workflowsBox = 'workflows';
  static const String _photosBox = 'photos';

  Database? _database;
  Box? _interventionsBoxInstance;
  Box? _workflowsBoxInstance;
  Box? _photosBoxInstance;

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE interventions (
        id INTEGER PRIMARY KEY,
        data TEXT NOT NULL,
        synced_at TEXT,
        modified_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE workflows (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        intervention_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        local_id TEXT,
        pending_sync INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(intervention_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        intervention_id INTEGER NOT NULL,
        photo_type TEXT NOT NULL,
        local_path TEXT NOT NULL,
        local_id TEXT,
        pending_sync INTEGER DEFAULT 1,
        data TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE interruptions (
        id TEXT PRIMARY KEY,
        intervention_id INTEGER NOT NULL,
        reason TEXT NOT NULL,
        custom_reason TEXT,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        duration_minutes INTEGER,
        local_id TEXT,
        pending_sync INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE workflow_branches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        intervention_id INTEGER NOT NULL,
        branch_name TEXT NOT NULL,
        completed_at TEXT,
        data TEXT,
        pending_sync INTEGER DEFAULT 1
      )
    ''');
  }

  Future<void> initialize() async {
    // Initialize Hive boxes
    _interventionsBoxInstance = await Hive.openBox(_interventionsBox);
    _workflowsBoxInstance = await Hive.openBox(_workflowsBox);
    _photosBoxInstance = await Hive.openBox(_photosBox);

    // Initialize SQLite for more complex queries
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'astrotech.db');

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migration from version 1 to 2
          await db.execute('''
            CREATE TABLE IF NOT EXISTS interruptions (
              id TEXT PRIMARY KEY,
              intervention_id INTEGER NOT NULL,
              reason TEXT NOT NULL,
              custom_reason TEXT,
              started_at TEXT NOT NULL,
              ended_at TEXT,
              duration_minutes INTEGER,
              local_id TEXT,
              pending_sync INTEGER DEFAULT 1,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS workflow_branches (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              intervention_id INTEGER NOT NULL,
              branch_name TEXT NOT NULL,
              completed_at TEXT,
              data TEXT,
              pending_sync INTEGER DEFAULT 1
            )
          ''');
        }
      },
    );
  }

  // Interventions
  Future<void> saveInterventions(List<InterventionModel> interventions) async {
    final box = _interventionsBoxInstance ?? await Hive.openBox(_interventionsBox);
    await box.clear();
    for (final intervention in interventions) {
      await box.put(intervention.id.toString(), intervention.toJson());
    }
  }

  Future<List<InterventionModel>> getInterventions() async {
    final box = _interventionsBoxInstance ?? await Hive.openBox(_interventionsBox);
    final List<InterventionModel> interventions = [];
    for (final key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        interventions.add(InterventionModel.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    // Sort by date_prevue DESC
    interventions.sort((a, b) {
      if (a.datePrevue == null && b.datePrevue == null) return 0;
      if (a.datePrevue == null) return 1;
      if (b.datePrevue == null) return -1;
      return b.datePrevue!.compareTo(a.datePrevue!);
    });
    return interventions;
  }

  Future<InterventionModel?> getInterventionById(int id) async {
    final box = _interventionsBoxInstance ?? await Hive.openBox(_interventionsBox);
    final data = box.get(id.toString());
    if (data != null) {
      return InterventionModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<void> saveIntervention(InterventionModel intervention) async {
    final box = _interventionsBoxInstance ?? await Hive.openBox(_interventionsBox);
    await box.put(intervention.id.toString(), intervention.toJson());
  }

  // Workflows
  Future<void> saveWorkflow(int interventionId, Map<String, dynamic> workflowData, {bool pendingSync = true}) async {
    await _database?.insert(
      'workflows',
      {
        'intervention_id': interventionId,
        'data': jsonEncode(workflowData),
        'local_id': workflowData['local_id'],
        'pending_sync': pendingSync ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getWorkflow(int interventionId) async {
    final results = await _database?.query(
      'workflows',
      where: 'intervention_id = ?',
      whereArgs: [interventionId],
      limit: 1,
    );
    if (results != null && results.isNotEmpty) {
      return jsonDecode(results.first['data'] as String);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getPendingWorkflows() async {
    final results = await _database?.query(
      'workflows',
      where: 'pending_sync = 1',
    );
    return results?.map((r) {
      final data = jsonDecode(r['data'] as String) as Map<String, dynamic>;
      data['intervention_id'] = r['intervention_id'];
      return data;
    }).toList() ?? [];
  }

  Future<void> markWorkflowSynced(int interventionId) async {
    await _database?.update(
      'workflows',
      {'pending_sync': 0},
      where: 'intervention_id = ?',
      whereArgs: [interventionId],
    );
  }

  // Photos
  Future<void> savePhotoLocally({
    required int interventionId,
    required String photoType,
    required String localPath,
    required String localId,
    Map<String, dynamic>? metadata,
  }) async {
    await _database?.insert(
      'photos',
      {
        'intervention_id': interventionId,
        'photo_type': photoType,
        'local_path': localPath,
        'local_id': localId,
        'data': metadata != null ? jsonEncode(metadata) : null,
        'pending_sync': 1,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getLocalPhotos(int interventionId, {String? photoType}) async {
    String where = 'intervention_id = ?';
    List<dynamic> whereArgs = [interventionId];

    if (photoType != null) {
      where += ' AND photo_type = ?';
      whereArgs.add(photoType);
    }

    final results = await _database?.query(
      'photos',
      where: where,
      whereArgs: whereArgs,
    );

    return results?.map((r) => {
      'id': r['id'],
      'intervention_id': r['intervention_id'],
      'photo_type': r['photo_type'],
      'local_path': r['local_path'],
      'local_id': r['local_id'],
      'pending_sync': r['pending_sync'] == 1,
      ...?r['data'] != null ? jsonDecode(r['data'] as String) as Map<String, dynamic> : null,
    }).toList() ?? [];
  }

  Future<List<Map<String, dynamic>>> getPendingPhotos() async {
    final results = await _database?.query(
      'photos',
      where: 'pending_sync = 1',
    );
    return results?.map((r) => {
      'id': r['id'],
      'intervention_id': r['intervention_id'],
      'photo_type': r['photo_type'],
      'local_path': r['local_path'],
      'local_id': r['local_id'],
      ...?r['data'] != null ? jsonDecode(r['data'] as String) as Map<String, dynamic> : null,
    }).toList() ?? [];
  }

  Future<void> markPhotoSynced(String localId) async {
    await _database?.update(
      'photos',
      {'pending_sync': 0},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> deleteLocalPhoto(String localId) async {
    await _database?.delete(
      'photos',
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  // Interruptions
  Future<void> saveInterruption({
    required String id,
    required int interventionId,
    required String reason,
    String? customReason,
    required DateTime startedAt,
    DateTime? endedAt,
    int? durationMinutes,
    String? localId,
  }) async {
    await _database?.insert(
      'interruptions',
      {
        'id': id,
        'intervention_id': interventionId,
        'reason': reason,
        'custom_reason': customReason,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'duration_minutes': durationMinutes,
        'local_id': localId,
        'pending_sync': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateInterruption({
    required String id,
    required DateTime endedAt,
    required int durationMinutes,
  }) async {
    await _database?.update(
      'interruptions',
      {
        'ended_at': endedAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'pending_sync': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getInterruptions(int interventionId) async {
    final results = await _database?.query(
      'interruptions',
      where: 'intervention_id = ?',
      whereArgs: [interventionId],
      orderBy: 'started_at DESC',
    );
    return results ?? [];
  }

  Future<Map<String, dynamic>?> getActiveInterruption(int interventionId) async {
    final results = await _database?.query(
      'interruptions',
      where: 'intervention_id = ? AND ended_at IS NULL',
      whereArgs: [interventionId],
      limit: 1,
    );
    return results?.isNotEmpty == true ? results!.first : null;
  }

  Future<List<Map<String, dynamic>>> getPendingInterruptions() async {
    final results = await _database?.query(
      'interruptions',
      where: 'pending_sync = 1',
    );
    return results ?? [];
  }

  Future<void> markInterruptionSynced(String id) async {
    await _database?.update(
      'interruptions',
      {'pending_sync': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clear all local data
  Future<void> clearAll() async {
    await _interventionsBoxInstance?.clear();
    await _workflowsBoxInstance?.clear();
    await _photosBoxInstance?.clear();
    await _database?.delete('interventions');
    await _database?.delete('workflows');
    await _database?.delete('photos');
    await _database?.delete('interruptions');
    await _database?.delete('workflow_branches');
  }
}
