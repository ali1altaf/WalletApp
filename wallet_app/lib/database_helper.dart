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
      version: 2, // Increment version to trigger onUpgrade
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
        description TEXT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL, -- 'credit' or 'debit'
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');
  }

  /// Upgrade the database schema
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          account_id INTEGER NOT NULL,
          description TEXT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          type TEXT NOT NULL, -- 'credit' or 'debit'
          FOREIGN KEY (account_id) REFERENCES accounts (id)
        )
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
  Future<int> insertTransaction(int accountId, String description, double amount, String date, String type) async {
    final db = await database;
    return db.insert('transactions', {
      'account_id': accountId,
      'description': description,
      'amount': amount,
      'date': date,
      'type': type,
    });
  }

  /// Fetch transactions for a specific account
  Future<List<Map<String, dynamic>>> getTransactionsByAccount(int accountId) async {
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
}
