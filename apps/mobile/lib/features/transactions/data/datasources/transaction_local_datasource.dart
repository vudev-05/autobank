import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/normalized_transaction.dart';
import '../../domain/entities/transaction_type.dart';

class TransactionLocalDataSource {
  static const String _dbName = 'autobank.db';
  static const String _tableName = 'transactions';
  static Database? _database;

  // In-memory list for web preview & hot-reloading without native Android SQLite
  static final List<NormalizedTransaction> _inMemoryList = [];

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            bank_code TEXT,
            account_number TEXT,
            amount REAL,
            type TEXT,
            content TEXT,
            order_code TEXT,
            transaction_time TEXT,
            raw_content TEXT,
            fingerprint TEXT UNIQUE,
            is_synced INTEGER DEFAULT 0,
            category TEXT,
            note TEXT
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_transactions_time ON $_tableName (transaction_time DESC)',
        );
        await db.execute(
          'CREATE INDEX idx_transactions_fingerprint ON $_tableName (fingerprint)',
        );
      },
    );
  }

  /// Cập nhật danh mục phân loại chi tiêu và ghi chú cho 1 giao dịch
  Future<bool> updateTransactionCategory(String id, String category, {String? note}) async {
    final idx = _inMemoryList.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _inMemoryList[idx] = _inMemoryList[idx].copyWith(category: category, note: note);
    }
    if (!kIsWeb) {
      try {
        final db = await database;
        final updateData = <String, Object?>{'category': category};
        if (note != null) updateData['note'] = note;
        await db.update(
          _tableName,
          updateData,
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (_) {}
    }
    return true;
  }

  /// Chèn giao dịch mới vào Database.
  /// Trả về true nếu chèn thành công, false nếu giao dịch đã tồn tại (trùng fingerprint).
  Future<bool> insertTransaction(NormalizedTransaction transaction) async {
    if (kIsWeb) {
      if (_inMemoryList.any((t) => t.fingerprint == transaction.fingerprint)) {
        return false;
      }
      _inMemoryList.insert(0, transaction);
      return true;
    }

    final db = await database;

    // Kiểm tra fingerprint trước để phát hiện trùng lặp
    final existing = await db.query(
      _tableName,
      where: 'fingerprint = ?',
      whereArgs: [transaction.fingerprint],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Đã tồn tại giao dịch này trong cơ sở dữ liệu -> Bỏ qua
      return false;
    }

    final id = await db.insert(
      _tableName,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    return id > 0;
  }

  /// Lấy danh sách giao dịch sắp xếp theo thời gian mới nhất
  Future<List<NormalizedTransaction>> getTransactions({
    int limit = 100,
    int offset = 0,
  }) async {
    if (kIsWeb) {
      return List<NormalizedTransaction>.from(_inMemoryList);
    }

    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: 'transaction_time DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((m) => NormalizedTransaction.fromMap(m)).toList();
  }

  /// Tính tổng số tiền nhận được trong ngày hôm nay (CREDIT)
  Future<double> getTodayTotalReceived() async {
    if (kIsWeb) {
      final now = DateTime.now();
      return _inMemoryList
          .where((t) => t.type == TransactionType.credit && t.transactionTime.year == now.year && t.transactionTime.month == now.month && t.transactionTime.day == now.day)
          .fold<double>(0.0, (sum, t) => sum + t.amount);
    }

    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM $_tableName
      WHERE type = 'credit' AND transaction_time >= ?
    ''', [startOfDay]);

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// Đếm số lượng giao dịch nhận tiền trong ngày hôm nay
  Future<int> getTodayTransactionCount() async {
    if (kIsWeb) {
      final now = DateTime.now();
      return _inMemoryList
          .where((t) => t.type == TransactionType.credit && t.transactionTime.year == now.year && t.transactionTime.month == now.month && t.transactionTime.day == now.day)
          .length;
    }

    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM $_tableName
      WHERE type = 'credit' AND transaction_time >= ?
    ''', [startOfDay]);

    if (result.isNotEmpty && result.first['count'] != null) {
      return (result.first['count'] as num).toInt();
    }
    return 0;
  }

  /// Xóa toàn bộ lịch sử (dùng khi cần reset data để test)
  Future<void> clearAll() async {
    if (kIsWeb) {
      _inMemoryList.clear();
      return;
    }

    final db = await database;
    await db.delete(_tableName);
  }
}
