import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class SyncQueueDatasource {
  static const String _syncQueueBox = 'sync_queue';
  static const int maxRetries = 5;

  Box? _boxInstance;
  final _uuid = const Uuid();

  Future<Box> _getBox() async {
    _boxInstance ??= await Hive.openBox(_syncQueueBox);
    return _boxInstance!;
  }

  Future<String> enqueue(SyncItem item) async {
    final box = await _getBox();
    final id = _uuid.v4();
    await box.put(id, item.toJson());
    return id;
  }

  Future<List<SyncItem>> getPendingItems() async {
    final box = await _getBox();
    final items = <SyncItem>[];

    for (final key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final item = SyncItem.fromJson(Map<String, dynamic>.from(data));
        if (item.status == SyncStatus.pending && item.retryCount < maxRetries) {
          items.add(item.copyWith(id: key.toString()));
        }
      }
    }

    // Sort by creation time
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  Future<void> markCompleted(String id) async {
    final box = await _getBox();
    final data = box.get(id);
    if (data != null) {
      final item = SyncItem.fromJson(Map<String, dynamic>.from(data));
      await box.put(id, item.copyWith(
        status: SyncStatus.completed,
        syncedAt: DateTime.now(),
      ).toJson());
    }
  }

  Future<void> markFailed(String id, String error) async {
    final box = await _getBox();
    final data = box.get(id);
    if (data != null) {
      final item = SyncItem.fromJson(Map<String, dynamic>.from(data));
      await box.put(id, item.copyWith(
        status: item.retryCount >= maxRetries - 1 ? SyncStatus.failed : SyncStatus.pending,
        retryCount: item.retryCount + 1,
        lastError: error,
      ).toJson());
    }
  }

  Future<void> remove(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<void> clearCompleted() async {
    final box = await _getBox();
    final keysToRemove = <dynamic>[];

    for (final key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final item = SyncItem.fromJson(Map<String, dynamic>.from(data));
        if (item.status == SyncStatus.completed) {
          keysToRemove.add(key);
        }
      }
    }

    for (final key in keysToRemove) {
      await box.delete(key);
    }
  }

  Future<int> getPendingCount() async {
    final items = await getPendingItems();
    return items.length;
  }
}

enum SyncStatus {
  pending,
  syncing,
  completed,
  failed,
}

enum SyncItemType {
  workflow,
  photo,
  status,
  signature,
  interruption,
}

class SyncItem {
  final String? id;
  final SyncItemType type;
  final int interventionId;
  final Map<String, dynamic> data;
  final SyncStatus status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final String? lastError;

  SyncItem({
    this.id,
    required this.type,
    required this.interventionId,
    required this.data,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    DateTime? createdAt,
    this.syncedAt,
    this.lastError,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'intervention_id': interventionId,
      'data': jsonEncode(data),
      'status': status.name,
      'retry_count': retryCount,
      'created_at': createdAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'last_error': lastError,
    };
  }

  factory SyncItem.fromJson(Map<String, dynamic> json) {
    return SyncItem(
      id: json['id'] as String?,
      type: SyncItemType.values.byName(json['type'] as String),
      interventionId: json['intervention_id'] as int,
      data: jsonDecode(json['data'] as String) as Map<String, dynamic>,
      status: SyncStatus.values.byName(json['status'] as String),
      retryCount: json['retry_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
      lastError: json['last_error'] as String?,
    );
  }

  SyncItem copyWith({
    String? id,
    SyncItemType? type,
    int? interventionId,
    Map<String, dynamic>? data,
    SyncStatus? status,
    int? retryCount,
    DateTime? createdAt,
    DateTime? syncedAt,
    String? lastError,
  }) {
    return SyncItem(
      id: id ?? this.id,
      type: type ?? this.type,
      interventionId: interventionId ?? this.interventionId,
      data: data ?? this.data,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      lastError: lastError ?? this.lastError,
    );
  }
}
