import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/my_transaction.dart';

class TransactionProvider with ChangeNotifier {
  Database? _db;
  List<MyTransaction> _transactions = [];

  List<MyTransaction> get transactions => List.unmodifiable(_transactions);

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'expenses.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE transactions('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'title TEXT, amount REAL, date TEXT, type TEXT)',
        );
      },
    );
    return _db!;
  }

  Future<void> fetchAndSetTransactions() async {
    final db = await database;
    final rows = await db.query('transactions', orderBy: 'date DESC');
    _transactions = rows.map(MyTransaction.fromMap).toList();
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
}
