import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/my_transaction.dart';

class TransactionProvider with ChangeNotifier {
  Database? _db;
  List<MyTransaction> _transactions = [];
  double _balance = 0;
  double _dartBalance = 0;

  List<MyTransaction> get transactions => List.unmodifiable(_transactions);

  double get balance => _balance;

  double get dartBalance => _dartBalance;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbFile = kIsWeb
        ? 'expenses.db'
        : join(await getDatabasesPath(), 'expenses.db');
    _db = await openDatabase(
      dbFile,
      version: 2,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE transactions('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'title TEXT, amount REAL, date TEXT, type TEXT, note TEXT)',
        );
        await _insertStarterData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE transactions ADD COLUMN note TEXT');
        }
      },
    );
    return _db!;
  }

  Future<void> fetchAndSetTransactions() async {
    final db = await database;
    final rows = await db.query('transactions', orderBy: 'date DESC');
    _transactions = rows.map(MyTransaction.fromMap).toList();
    final result = await db.rawQuery(
      'SELECT SUM(CASE WHEN type = ? THEN amount ELSE -amount END) AS total '
      'FROM transactions',
      [TransactionType.income.name],
    );
    _balance = (result.first['total'] as num?)?.toDouble() ?? 0;
    _dartBalance = _transactions.fold(
      0.0,
      (sum, tx) =>
          tx.type == TransactionType.income ? sum + tx.amount : sum - tx.amount,
    );
    notifyListeners();
  }

  Future<void> addTransaction(MyTransaction tx) async {
    final db = await database;
    await db.insert('transactions', tx.toMap());
    await fetchAndSetTransactions();
  }

  Future<void> updateTransaction(int id, MyTransaction tx) async {
    final db = await database;
    final data = tx.toMap()..remove('id');
    await db.update('transactions', data, where: 'id = ?', whereArgs: [id]);
    await fetchAndSetTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    await fetchAndSetTransactions();
  }

  Future<void> deleteAllTransactions() async {
    final db = await database;
    await db.delete('transactions');
    await fetchAndSetTransactions();
  }

  Future<void> _insertStarterData(Database db) async {
    final today = DateTime.now();
    final starters = [
      MyTransaction(
        title: 'เงินเดือน',
        amount: 18000,
        date: today.subtract(const Duration(days: 7)),
        type: TransactionType.income,
        note: 'เดือนนี้',
      ),
      MyTransaction(
        title: 'ค่าหอพัก',
        amount: 3500,
        date: today.subtract(const Duration(days: 6)),
        type: TransactionType.expense,
      ),
      MyTransaction(
        title: 'ข้าวเย็น',
        amount: 65,
        date: today.subtract(const Duration(days: 4)),
        type: TransactionType.expense,
        note: 'กะเพราหมูกรอบ',
      ),
      MyTransaction(
        title: 'ขายของมือสอง',
        amount: 800,
        date: today.subtract(const Duration(days: 3)),
        type: TransactionType.income,
      ),
      MyTransaction(
        title: 'ค่าน้ำมัน',
        amount: 300,
        date: today.subtract(const Duration(days: 1)),
        type: TransactionType.expense,
      ),
      MyTransaction(
        title: 'กาแฟ',
        amount: 55,
        date: today,
        type: TransactionType.expense,
      ),
    ];
    final batch = db.batch();
    for (final tx in starters) {
      batch.insert('transactions', tx.toMap());
    }
    await batch.commit(noResult: true);
  }

  List<MyTransaction> _sampleData(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final isIncome = i % 4 == 0;
      return MyTransaction(
        title: isIncome ? 'รายรับตัวอย่าง ${i + 1}' : 'รายจ่ายตัวอย่าง ${i + 1}',
        amount: isIncome ? 500.0 + i : 20.0 + i,
        date: now.subtract(Duration(days: i)),
        type: isIncome ? TransactionType.income : TransactionType.expense,
      );
    });
  }

  Future<Duration> importOneByOne([int count = 100]) async {
    final db = await database;
    final items = _sampleData(count);
    final watch = Stopwatch()..start();
    for (final tx in items) {
      await db.insert('transactions', tx.toMap());
    }
    watch.stop();
    await fetchAndSetTransactions();
    return watch.elapsed;
  }

  Future<Duration> importBatch([int count = 100]) async {
    final db = await database;
    final items = _sampleData(count);
    final watch = Stopwatch()..start();
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final tx in items) {
        batch.insert('transactions', tx.toMap());
      }
      await batch.commit(noResult: true);
    });
    watch.stop();
    await fetchAndSetTransactions();
    return watch.elapsed;
  }
}
