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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('รายรับรายจ่าย')),
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
