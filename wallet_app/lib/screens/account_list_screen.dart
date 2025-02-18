import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fl_chart/fl_chart.dart';

class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  _AccountListScreenState createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _categories = [];
  Map<String, double> _categoryExpenses = {};
  List<Map<String, dynamic>> _subcategories = [];
  int? _defaultAccountId;
  bool _isLoading = true; // To manage loading state
  String? _selectedCategory;
  double? _selectedCategoryAmount;

// Add these variables to your state class
  String? _selectedCategoryName;
  String? _selectedSubcategory;



  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    await DatabaseHelper.instance.initializeDefaultCategories();
    _fetchAccounts();
    _fetchTransactions();
    _fetchCategories(); // Fetch categories for the dropdown
    _fetchCategoryExpenses();
    setState(() {
      _isLoading = false; // Stop loading after fetching
    });
  }
  Future<void> _fetchAccounts() async {
    final accounts = await DatabaseHelper.instance.getAccounts();
    setState(() {
      _accounts = accounts;
    });
  }


  Future<void> _fetchTransactions() async {
    final transactions = await DatabaseHelper.instance.getLastTransactions(4); // Fetch the last 4 transactions
    setState(() {
      _transactions = transactions;
      if (transactions.isNotEmpty) {
        _defaultAccountId = transactions[0]['account_id']; // Set the default account to the last used account
      }
      _isLoading = false; // Stop loading after fetching
    });
  }

  Future<void> _fetchCategories() async {
    final subcategories = await DatabaseHelper.instance.getCategories();
    setState(() {
      _categories = subcategories;
      _isLoading = false; // Stop loading after fetching
    });
  }




  Future<void> _fetchCategoryExpenses() async {
    // Fetch expenses grouped by category for the current month
    final categoryExpenses = await DatabaseHelper.instance.getMonthlyExpensesByCategory();

    setState(() {
      _categoryExpenses = categoryExpenses;
    });
  }


  void _showDonutChartDialog() {
    if (_categoryExpenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No expenses for the current month!")),
      );
      return;
    }

    final totalExpenses = _categoryExpenses.values.fold(0.0, (sum, amount) => sum + amount);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Monthly Expense Breakdown'),
          content: StatefulBuilder(
            builder: (context, setState) {
              int? touchedIndex;
              final entriesList = _categoryExpenses.entries.toList();

              return Container(
                height: MediaQuery.of(context).size.height * 0.6,
                width: MediaQuery.of(context).size.width * 0.8,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = null;
                                return;
                              }
                              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: entriesList.asMap().entries.map((mapEntry) {
                          final index = mapEntry.key;
                          final entry = mapEntry.value;
                          final isTouched = index == touchedIndex;
                          final categoryName = entry.key;
                          final amount = entry.value;
                          final colorIndex = _categories.indexWhere((c) => c['name'] == categoryName);
                          final color = colorIndex >= 0
                              ? Colors.primaries[colorIndex % Colors.primaries.length]
                              : Colors.grey;

                          return PieChartSectionData(
                            color: color,
                            value: amount,
                            title: isTouched ? '${categoryName}\n₹${amount.toStringAsFixed(2)}' : '',
                            radius: isTouched ? 60 : 50,
                            titleStyle: TextStyle(
                              fontSize: isTouched ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 100,
                      ),
                    ),
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            touchedIndex == null ? 'Total Expenses' : entriesList[touchedIndex!].key,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '₹${touchedIndex == null ? totalExpenses.toStringAsFixed(2) : entriesList[touchedIndex!].value.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addAccountDialog() async {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Account'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Account Name (Optional)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String accountName = nameController.text.trim();
                if (accountName.isEmpty) {
                  accountName = 'Account ${_accounts.length + 1}';
                }
                await DatabaseHelper.instance.insertAccount(accountName, 0.0);
                _fetchAccounts();
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _deleteAccount(int id) async {
    await DatabaseHelper.instance.deleteAccount(id);
    _fetchAccounts();
  }

  Future<void> _updateBalance(int id, double newBalance) async {
    await DatabaseHelper.instance.updateAccountBalance(id, newBalance);
    _fetchAccounts();
  }

  void _changeBalanceDialog(int id, double currentBalance) {
    TextEditingController balanceController =
        TextEditingController(text: currentBalance.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Balance'),
          content: TextField(
            controller: balanceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'New Balance'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                double newBalance = double.parse(balanceController.text);
                await _updateBalance(id, newBalance);
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    TextEditingController customCategoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Custom Category'),
          content: TextField(
            controller: customCategoryController,
            decoration: InputDecoration(labelText: 'Category Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String categoryName = customCategoryController.text.trim();
                if (categoryName.isNotEmpty) {
                  await DatabaseHelper.instance.insertCategory(categoryName);
                  _fetchCategories();
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }


  void _transactionDialog() {
    int? selectedAccountId = _defaultAccountId;
    int? destinationAccountId;
    String transactionType = "Expense";
    TextEditingController amountController = TextEditingController(text: '0');
    TextEditingController descriptionController = TextEditingController();
    String amountLabelText = 'Transaction Amount';
    String categoryLabelText = 'Select Category';
    String accountLabelText = 'Select Account';

    // Get distinct category names
    List<String> distinctCategories = _categories
        .map((c) => c['name'] as String)
        .toSet()
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Record'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Transaction Type Tab Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ["Expense", "Income", "Transfer"]
                          .map((type) => Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            transactionType = type;
                            amountController.text =
                            transactionType == "Expense" ? '-0' : '0';
                          }),
                          child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: transactionType == type
                                  ? Colors.blueAccent
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: transactionType == type
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                    SizedBox(height: 10),

                    // Amount Input with Currency Indicator
                    Row(
                      children: [
                        Container(
                          padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('INR',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: amountLabelText,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              if (transactionType == "Expense" &&
                                  !value.startsWith('-') &&
                                  value.isNotEmpty) {
                                amountController.text = '-$value';
                                amountController.selection =
                                    TextSelection.fromPosition(TextPosition(
                                        offset: amountController.text.length));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),

                    // Account Dropdown
                    DropdownButtonFormField<int>(
                      value: selectedAccountId,
                      items: _accounts
                          .map((account) => DropdownMenuItem<int>(
                        value: account['id'],
                        child: Text(account['name']),
                      ))
                          .toList(),
                      onChanged: (value) => setState(() => selectedAccountId = value),
                      hint: Text(accountLabelText),
                    ),
                    SizedBox(height: 10),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryName,
                      items: distinctCategories
                          .map((category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ))
                          .toList(),
                      onChanged: (value) => setState(() {
                        _selectedCategoryName = value;
                        _selectedSubcategory = null;
                      }),
                      hint: Text(categoryLabelText),
                    ),
                    SizedBox(height: 10),

                    // Subcategory Dropdown (only when category is selected)
                    if (_selectedCategoryName != null)
                      DropdownButtonFormField<String?>(
                        value: _selectedSubcategory,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('No Subcategory'),
                          ),
                          ..._categories
                              .where((c) => c['name'] == _selectedCategoryName)
                              .map((c) => DropdownMenuItem<String?>(
                            value: c['subcategory'],
                            child: Text(c['subcategory'] ?? 'No Subcategory'),
                          )),
                        ],
                        onChanged: (value) => setState(() => _selectedSubcategory = value),
                        hint: Text('Select Subcategory'),
                      ),
                    SizedBox(height: 10),

                    // Description Input
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    // Validation
                    if (selectedAccountId == null) {
                      setState(() => accountLabelText = 'Account is required!');
                      return;
                    }

                    if (amountController.text.isEmpty ||
                        double.tryParse(amountController.text) == null) {
                      setState(() => amountLabelText = 'Valid amount is required!');
                      return;
                    }

                    if (_selectedCategoryName == null) {
                      setState(() => categoryLabelText = 'Category is required!');
                      return;
                    }

                    final category = _categories.firstWhere(
                          (c) => c['name'] == _selectedCategoryName,
                      orElse: () => {'id': 1},
                    );

                    double transactionAmount = double.parse(amountController.text);


                    // Ensure the transaction amount is positive
                    transactionAmount = transactionAmount.abs();

                    // Update account balances based on transaction type


                    if (transactionType == "Income") {
                      // Get the current balance for the account
                      double currentBalance = await DatabaseHelper.instance.getAccountBalance(selectedAccountId!);
                      // Calculate the new balance by adding the income
                      double newBalance = currentBalance + transactionAmount;
                      // Update the account balance with the new amount
                      await DatabaseHelper.instance.updateAccountBalance(selectedAccountId!, newBalance);
                    } else if (transactionType == "Expense") {
                      // Get the current balance for the account
                      double currentBalance = await DatabaseHelper.instance.getAccountBalance(selectedAccountId!);
                      // Calculate the new balance by subtracting the expense
                      double newBalance = currentBalance - transactionAmount;
                      // Update the account balance with the new amount
                      await DatabaseHelper.instance.updateAccountBalance(selectedAccountId!, newBalance);
                    } else if (transactionType == "Transfer" && destinationAccountId != null) {
                      // For transfers, adjust both source and destination accounts

                      // Deduct from source account
                      double sourceCurrentBalance = await DatabaseHelper.instance.getAccountBalance(selectedAccountId!);
                      double newSourceBalance = sourceCurrentBalance - transactionAmount;
                      await DatabaseHelper.instance.updateAccountBalance(selectedAccountId!, newSourceBalance);

                      // Add to destination account
                      double destinationCurrentBalance = await DatabaseHelper.instance.getAccountBalance(destinationAccountId!);
                      double newDestinationBalance = destinationCurrentBalance + transactionAmount;
                      await DatabaseHelper.instance.updateAccountBalance(destinationAccountId!, newDestinationBalance);
                    }



                    // Get category ID
                    final categoryid = _categories.firstWhere(
                          (c) => c['name'] == _selectedCategoryName,
                      orElse: () => {'id': 1},
                    );

                    await DatabaseHelper.instance.insertTransaction(
                      selectedAccountId!,
                      descriptionController.text,
                      double.parse(amountController.text),
                      DateTime.now().toIso8601String(),
                      transactionType,
                      category['id'] as int,
                      _selectedSubcategory,
                    );

                    _fetchTransactions();
                    _fetchAccounts();
                    Navigator.pop(context);
                  },
                  child: Text('Add Transaction'),
                ),
              ],
            );
          },
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Accounts')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two accounts per row
                childAspectRatio: 3, // Adjust for better layout
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              padding: EdgeInsets.all(10),
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      account['name'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Balance: ₹${account['balance'].toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.green),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _changeBalanceDialog(
                              account['id'], account['balance']),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteAccount(account['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Expanded(
                  child: ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        elevation: 2,
                        child: ListTile(
                          title: Text(transaction['type']),
                          subtitle: Text(
                              'Amount: ₹${transaction['amount'].toStringAsFixed(2)}'),
                          trailing: Text(
                            transaction['date'],
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.add_event,
        animatedIconTheme: IconThemeData(size: 22.0),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        curve: Curves.bounceIn,
        elevation: 8.0,
        children: [
          SpeedDialChild(
            child: Icon(Icons.account_balance),
            label: 'Add Account',
            onTap: _addAccountDialog,
          ),
          SpeedDialChild(
            child: Icon(Icons.category),
            label: 'Add Category',
            onTap: _showAddCategoryDialog,
          ),
          SpeedDialChild(
            child: Icon(Icons.currency_rupee),
            label: 'Add Transaction',
            onTap: _transactionDialog,
          ),
          SpeedDialChild(
            child: Icon(Icons.pie_chart),
            label: 'View Donut Chart',
            onTap: _showDonutChartDialog,
          ),
        ],
      ),
    );
  }
}