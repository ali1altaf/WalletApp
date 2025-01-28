import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return openDatabase(
      join(path, 'accounts.db'),
      version: 3, // Increment version to trigger onUpgrade
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  /// Create the database schema
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        balance REAL NOT NULL
      )
    ''');

    await db.execute('''
     CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          account_id INTEGER NOT NULL,
          description TEXT,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          type TEXT NOT NULL, -- 'credit' or 'debit'
          category_id INTEGER NOT NULL DEFAULT 1,
          FOREIGN KEY (account_id) REFERENCES accounts (id),
          FOREIGN KEY (category_id) REFERENCES CategoryTable (id)
);

      )
    ''');

    await db.execute('''
      CREATE TABLE CategoryTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE
      )
    ''');
  }

  /// Upgrade the database schema
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE transactions ADD COLUMN category_id INTEGER NOT NULL DEFAULT 1 REFERENCES CategoryTable (id)
      ''');

    }
  }


  /// Fetch recent transactions
  Future<List<Map<String, dynamic>>> getLastTransactions(int count) async {
    final db = await instance.database;
    return await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: count,
    );
  }

  /// Insert a new account
  Future<int> insertAccount(String name, double balance) async {
    final db = await database;
    return db.insert('accounts', {'name': name, 'balance': balance});
  }

  /// Fetch all accounts
  Future<List<Map<String, dynamic>>> getAccounts() async {
    final db = await database;
    return db.query('accounts');
  }

  /// Update account balance
  Future<int> updateAccountBalance(int id, double balance) async {
    final db = await database;
    return db.update(
      'accounts',
      {'balance': balance},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete an account
  Future<int> deleteAccount(int id) async {
    final db = await database;
    return db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  /// Insert a new transaction
  Future<int> insertTransaction(int accountId, String description, double amount, String date, String type, int categoryId,
      ) async {
    final db = await database;
    return db.insert('transactions', {
      'account_id': accountId,
      'description': description,
      'amount': amount,
      'date': date,
      'type': type,
      'category_id': categoryId,
    });
  }


  /// Fetch transactions for a specific account
  Future<List<Map<String, dynamic>>> getTransactionsByAccount(
      int accountId) async {
    final db = await database;
    return db.query(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
  }

  /// Delete a transaction
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }


  /// Initialize default categories
  Future<void> initializeDefaultCategories() async {
    final db = await database;

    // List of default categories
    List<Map<String, dynamic>> defaultCategories = [
      {'name': 'Food & Drinks'},
      {'name': 'Shopping'},
      {'name': 'Housing'},
      {'name': 'Transportation'},
      {'name': 'Vehicle'},
      {'name': 'Life & Entertainment'},
      {'name': 'Communication & PC'},
      {'name': 'Financial Expense'},
      {'name': 'Investment'},
      {'name': 'Income'},
      {'name': 'Transfer'},
    ];

    // Insert default categories if they don't already exist
    for (var category in defaultCategories) {
      try {
        await db.insert(
          'CategoryTable',
          category,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (e) {
        // Handle insertion error (if any)
      }
    }
  }


  /// insert new categories
  Future<int> insertCategory(String name) async {
    final db = await database;
    return db.insert(
      'CategoryTable',
      {'name': name},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Fetch all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return db.query('CategoryTable');
  }

  Future<Map<String, double>> getMonthlyExpensesByCategory() async {
    final db = await database;

    // Get the first and last days of the current month.
    final currentDate = DateTime.now();
    final firstDayOfMonth = DateTime(currentDate.year, currentDate.month, 1).toIso8601String();
    final lastDayOfMonth = DateTime(currentDate.year, currentDate.month + 1, 0).toIso8601String();

    // Query to get total expenses grouped by category for the current month
    final result = await db.rawQuery('''
    SELECT 
      CategoryTable.name AS category_name,
      SUM(transactions.amount) AS total_amount
    FROM 
      transactions
    INNER JOIN 
      CategoryTable
    ON 
      transactions.category_id = CategoryTable.id
    WHERE 
      transactions.date >= ? AND transactions.date <= ?
    GROUP BY 
      transactions.category_id
  ''', [firstDayOfMonth, lastDayOfMonth]);


    // Map the results into a readable format
    final expensesByCategory = <String, double>{};
    for (final row in result) {
      expensesByCategory[row['category_name'] as String] = (row['total_amount'] as num).toDouble();
    }


    return expensesByCategory;
  }




}
