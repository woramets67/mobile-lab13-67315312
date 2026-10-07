import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/my_transaction.dart';
import '../providers/transaction_provider.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final MyTransaction? transaction;

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late TransactionType _type;
  late DateTime _date;

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _titleController = TextEditingController(text: tx?.title ?? '');
    _amountController = TextEditingController(
      text: tx == null ? '' : tx.amount.toString(),
    );
    _type = tx?.type ?? TransactionType.expense;
    _date = tx?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TransactionProvider>();
    final tx = MyTransaction(
      id: widget.transaction?.id,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      date: _date,
      type: _type,
    );
    if (_isEdit) {
      await provider.updateTransaction(widget.transaction!.id!, tx);
    } else {
      await provider.addTransaction(tx);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'แก้ไขรายการ' : 'เพิ่มรายการ')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'ชื่อรายการ'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกชื่อรายการ';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                if (amount == null || amount <= 0) {
                  return 'กรุณากรอกตัวเลขที่มากกว่า 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('รายรับ'),
                ),
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('รายจ่าย'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('วันที่: ${DateFormat('dd/MM/yyyy').format(_date)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('บันทึก')),
          ],
        ),
      ),
    );
  }
}
