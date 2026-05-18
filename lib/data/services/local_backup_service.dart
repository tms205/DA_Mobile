import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';

class BackupSnapshotStatus {
  const BackupSnapshotStatus({
    required this.hasBackup,
    this.backedUpAt,
    this.recordCount = 0,
  });

  final bool hasBackup;
  final DateTime? backedUpAt;
  final int recordCount;
}

class BackupRestoreResult {
  const BackupRestoreResult({
    required this.restored,
    required this.recordCount,
    this.backedUpAt,
    this.errorMessage,
  });

  final bool restored;
  final int recordCount;
  final DateTime? backedUpAt;
  final String? errorMessage;
}

class LocalBackupService {
  LocalBackupService({AppDatabase? database}) : _database = database ?? AppDatabase();

  static const _backupKey = 'local_backup_v1';
  static const _backedUpAtKey = 'local_backup_created_at';
  static const _payloadVersion = 2;

  final AppDatabase _database;

  Future<BackupSnapshotStatus> getBackupStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _decodePayload(
      prefs.getString(_backupKey),
      fallbackBackedUpAt: prefs.getString(_backedUpAtKey),
    );
    return payload?.status ?? const BackupSnapshotStatus(hasBackup: false);
  }

  Future<BackupSnapshotStatus> createBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final data = await _database.exportData();
    final now = DateTime.now();
    final recordCount = _countRecords(data);
    final encoded = jsonEncode({
      'version': _payloadVersion,
      'createdAt': now.toIso8601String(),
      'recordCount': recordCount,
      'data': data,
    });

    await prefs.setString(_backupKey, encoded);
    await prefs.setString(_backedUpAtKey, now.toIso8601String());

    return BackupSnapshotStatus(
      hasBackup: true,
      backedUpAt: now,
      recordCount: recordCount,
    );
  }

  Future<BackupRestoreResult> restoreLatestBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _decodePayload(
      prefs.getString(_backupKey),
      fallbackBackedUpAt: prefs.getString(_backedUpAtKey),
    );

    if (payload == null) {
      return const BackupRestoreResult(
        restored: false,
        recordCount: 0,
        errorMessage: 'Chưa có bản sao lưu hợp lệ.',
      );
    }

    try {
      await _database.replaceData(payload.data);
      await prefs.setString(_backedUpAtKey, DateTime.now().toIso8601String());
      return BackupRestoreResult(
        restored: true,
        recordCount: payload.status.recordCount,
        backedUpAt: payload.status.backedUpAt,
      );
    } catch (_) {
      return BackupRestoreResult(
        restored: false,
        recordCount: payload.status.recordCount,
        backedUpAt: payload.status.backedUpAt,
        errorMessage: 'Không thể khôi phục dữ liệu từ bản sao lưu.',
      );
    }
  }

  _BackupPayload? _decodePayload(String? raw, {String? fallbackBackedUpAt}) {
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      if (decoded['data'] is Map<String, dynamic>) {
        final data = _normalizeData(decoded['data'] as Map<String, dynamic>);
        final createdAt = DateTime.tryParse(decoded['createdAt'] as String? ?? '');
        final status = BackupSnapshotStatus(
          hasBackup: true,
          backedUpAt: createdAt ?? DateTime.tryParse(fallbackBackedUpAt ?? ''),
          recordCount: _readRecordCount(decoded, data),
        );
        return _BackupPayload(status: status, data: data);
      }

      if (_looksLikeLegacyTables(decoded)) {
        final data = _normalizeData(decoded);
        final status = BackupSnapshotStatus(
          hasBackup: true,
          backedUpAt: DateTime.tryParse(fallbackBackedUpAt ?? ''),
          recordCount: _countRecords(data),
        );
        return _BackupPayload(status: status, data: data);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  bool _looksLikeLegacyTables(Map<String, dynamic> decoded) {
    return decoded.containsKey('transactions') ||
        decoded.containsKey('categories') ||
        decoded.containsKey('accounts') ||
        decoded.containsKey('budgets');
  }

  Map<String, List<Map<String, dynamic>>> _normalizeData(Map<String, dynamic> decoded) {
    List<Map<String, dynamic>> table(String name) {
      final rows = decoded[name];
      if (rows is! List) return <Map<String, dynamic>>[];
      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    }

    return {
      'transactions': table('transactions'),
      'categories': table('categories'),
      'accounts': table('accounts'),
      'budgets': table('budgets'),
    };
  }

  int _readRecordCount(
    Map<String, dynamic> decoded,
    Map<String, List<Map<String, dynamic>>> data,
  ) {
    final recordCount = decoded['recordCount'];
    if (recordCount is int) return recordCount;
    return _countRecords(data);
  }

  int _countRecords(Map<String, List<Map<String, dynamic>>> data) {
    return data.values.fold<int>(0, (total, rows) => total + rows.length);
  }
}

class _BackupPayload {
  const _BackupPayload({
    required this.status,
    required this.data,
  });

  final BackupSnapshotStatus status;
  final Map<String, List<Map<String, dynamic>>> data;
}
