import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/my_transaction.dart';
import '../providers/transaction_provider.dart';
import 'add_edit_transaction_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  late Future<void> _loading;

  @override
  void initState() {
    super.initState();
    _loading = context.read<TransactionProvider>().fetchAndSetTransactions();
  }

  void _openForm([MyTransaction? tx]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(transaction: tx),
      ),
    );
  }

  Future<void> _runImport(bool useBatch) async {
    final provider = context.read<TransactionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final elapsed = useBatch
        ? await provider.importBatch()
        : await provider.importOneByOne();
    final label = useBatch ? 'batch ใน transaction' : 'ทีละรายการ';
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'นำเข้า 100 รายการแบบ$label ใช้เวลา ${elapsed.inMilliseconds} ms',
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAll() async {
    final provider = context.read<TransactionProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบทั้งหมด'),
        content: const Text('ต้องการลบรายการทั้งหมดหรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await provider.deleteAllTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายรับรายจ่าย'),
        actions: [
          PopupMenuButton<bool>(
            icon: const Icon(Icons.download),
            onSelected: _runImport,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: false,
                child: Text('นำเข้า 100 รายการ (ทีละรายการ)'),
              ),
              PopupMenuItem(
                value: true,
                child: Text('นำเข้า 100 รายการ (batch)'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'ลบทั้งหมด',
            onPressed: _confirmDeleteAll,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Consumer<TransactionProvider>(
            builder: (context, provider, _) {
              final balance = provider.balance;
              final money = NumberFormat('#,##0.00');
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Text(
                      'ยอดคงเหลือ ${money.format(balance)} บาท',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      'SQL ${money.format(balance)} | '
                      'Dart ${money.format(provider.dartBalance)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: FutureBuilder(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Consumer<TransactionProvider>(
            builder: (context, provider, _) {
              final items = provider.transactions;
              if (items.isEmpty) {
                return const Center(child: Text('ยังไม่มีรายการ'));
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final tx = items[i];
                  final isIncome = tx.type == TransactionType.income;
                  final color = isIncome ? Colors.green : Colors.red;
                  final sign = isIncome ? '+' : '-';
                  return ListTile(
                    leading: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                    ),
                    title: Text(tx.title),
                    subtitle: Text(dateFormat.format(tx.date)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$sign${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => provider.deleteTransaction(tx.id!),
                        ),
                      ],
                    ),
                    onTap: () => _openForm(tx),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
