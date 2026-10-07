enum TransactionType { income, expense }

class MyTransaction {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? note;

  MyTransaction({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.note,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
      'note': note,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory MyTransaction.fromMap(Map<String, dynamic> map) {
    return MyTransaction(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      type: TransactionType.values.byName(map['type'] as String),
      note: map['note'] as String?,
    );
  }
}
