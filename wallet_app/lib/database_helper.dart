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
      version: 1, // Increment version to trigger onUpgrade
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
          subcategory TEXT,
          FOREIGN KEY (account_id) REFERENCES accounts (id),
          FOREIGN KEY (category_id) REFERENCES CategoryTable (id)
);

      )
    ''');

    await db.execute('''
      CREATE TABLE Category (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  subcategory TEXT,
  UNIQUE(name, subcategory) ON CONFLICT IGNORE
)
    ''');
  }

  /// Upgrade the database schema
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {

    await db.execute('''
      CREATE TABLE Category (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  subcategory TEXT,
  UNIQUE(name, subcategory) ON CONFLICT IGNORE
)
    ''');

    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE transactions ADD COLUMN category_id INTEGER NOT NULL DEFAULT 1 REFERENCES Category (id)
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

  // Modify insertTransaction to include subcategory
  Future<int> insertTransaction(int accountId, String description, double amount,
      String date, String type, int categoryId, String? subcategory) async {
    final db = await database;
    return db.insert('transactions', {
      'account_id': accountId,
      'description': description,
      'amount': amount,
      'date': date,
      'type': type,
      'category_id': categoryId,
      'subcategory': subcategory,
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
    //await db.delete('CategoryTable');


    // List of default categories with subcategories
    List<Map<String, dynamic>> defaultCategories = [
      {
        'name': 'Food & Drinks',
        'subcategories': ['Groceries', 'Restaurant', 'Fast Food', 'Meals']
      },
      {
        'name': 'Shopping',
        'subcategories': [
          'Clothes',
          'Shoes',
          'Jewels',
          'Accessories',
          'Beauty/Apparels',
          'Kids',
          'Home',
          'Pets/Animals',
          'Electronics',
          'Gifts',
          'Stationery/Tools'
        ]
      },
      {
        'name': 'Housing',
        'subcategories': [
          'Rent',
          'Mortgage',
          'Energy/Utilities',
          'Services',
          'Maintenance/Repairs',
          'Property Insurance'
        ]
      },
      {
        'name': 'Transportation',
        'subcategories': ['Trips', 'Public Transport', 'Taxi/Cab', 'Flight']
      },
      {
        'name': 'Vehicle',
        'subcategories': [
          'Fuel/Petrol',
          'Parking',
          'Vehicle Maintenance',
          'Rental',
          'Vehicle Insurance',
          'Lease'
        ]
      },
      {
        'name': 'Medical',
        'subcategories': [
          'Chemist',
          'Check-up/OPD',
          'Surgery/Treatment',
          'Healthcare'
        ]
      },
      {
        'name': 'Life & Entertainment',
        'subcategories': [
          'Life Events',
          'Holidays/Trips/Hotels',
          'TV/Streaming',
          'Alcohol/Tobacco',
          'Hobbies',
          'Gambling'
        ]
      },
      {
        'name': 'Sports',
        'subcategories': ['Active Sports/Fitness', 'Sports Events']
      },
      {
        'name': 'Communication & PC',
        'subcategories': [
          'Phone/Cell Phone',
          'Internet/WiFi',
          'Software/Apps/Games',
          'Postal Service'
        ]
      },
      {
        'name': 'Financial Expense',
        'subcategories': [
          'Taxes',
          'Insurance',
          'Loan/Interest',
          'Fines',
          'Advisory',
          'Charges/Fee'
        ]
      },
      {
        'name': 'Investment',
        'subcategories': [
          'Real Estate',
          'Collectables',
          'Financial Investments',
          'Savings'
        ]
      },
      {
        'name': 'Income',
        'subcategories': [
          'Wage/Income',
          'Interest/Dividends',
          'Sales (Assets)',
          'Rental Income',
          'Dues & Grants',
          'Lending/Renting',
          'Checks/Coupons',
          'Lottery',
          'Refunds (Tax/Purchase)',
          'Gifts'
        ]
      },
      {
        'name': 'Transfer',
        'subcategories': ['Friends', 'Family', 'General']
      }
    ];

    // Insert default categories and subcategories
    for (var category in defaultCategories) {
      String categoryName = category['name'];
      List<String> subcategories = category['subcategories'];

      // Insert category and its associated subcategories
      try {
        for (var subcategoryName in subcategories) {
          await db.insert(
            'Category',
            {
              'name': categoryName,
              'subcategory': subcategoryName
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      } catch (e) {
        // Handle insertion error (if any)
        print('Error inserting category or subcategory: $e');
      }
    }
  }




  /// insert new categories
  Future<int> insertCategory(String name) async {
    final db = await database;
    return db.insert(
      'Category',
      {'name': name},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Fetch all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return db.query('Category');

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
      Category.name AS category_name,
      SUM(transactions.amount) AS total_amount
    FROM 
      transactions
    INNER JOIN 
      Category
    ON 
      transactions.category_id = Category.id
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
