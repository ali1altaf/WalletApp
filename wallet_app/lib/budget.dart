// lib/budget.dart
class Budget {
  final String name;
  final double amount;

  // Constructor
  Budget({required this.name, required this.amount});

  // Convert a Map from SQLite into a Budget object
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      name: map['name'],
      amount: map['amount'],
    );
  }

  // Convert a Budget object into a Map to save into SQLite
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
    };
  }
}
