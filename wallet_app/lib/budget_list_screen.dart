import 'package:flutter/material.dart';
import '../database_helper.dart';

class AccountListScreen extends StatefulWidget {
  @override
  _AccountListScreenState createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    await DatabaseHelper.instance.initializeDefaultCategories();
    await _fetchAccounts();
    await _fetchTransactions();
    await _fetchCategories();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchAccounts() async {
    final accounts = await DatabaseHelper.instance.getAccounts();
    setState(() {
      _accounts = accounts;
    });
  }

  Future<void> _fetchTransactions() async {
    final transactions = await DatabaseHelper.instance.getLastTransactions(4);
    setState(() {
      _transactions = transactions;
    });
  }

  Future<void> _fetchCategories() async {
    final categories = await DatabaseHelper.instance.getCategories();
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _addAccountDialog() async {
    TextEditingController _nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Account'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Account Name (Optional)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String accountName = _nameController.text.trim();
                if (accountName.isEmpty) {
                  accountName = 'Account ${_accounts.length + 1}';
                }
                await DatabaseHelper.instance.insertAccount(accountName, 0.0);
                await _fetchAccounts();
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
    await _fetchAccounts();
  }

  Future<void> _updateBalance(int id, double newBalance) async {
    await DatabaseHelper.instance.updateAccountBalance(id, newBalance);
    await _fetchAccounts();
  }

  void _changeBalanceDialog(int id, double currentBalance) {
    TextEditingController _balanceController =
        TextEditingController(text: currentBalance.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Balance'),
          content: TextField(
            controller: _balanceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'New Balance'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                double newBalance = double.parse(_balanceController.text);
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
    TextEditingController _categoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Category'),
          content: TextField(
            controller: _categoryController,
            decoration: InputDecoration(labelText: 'Category Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String categoryName = _categoryController.text.trim();
                if (categoryName.isNotEmpty) {
                  await DatabaseHelper.instance.insertCategory(categoryName);
                  await _fetchCategories();
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
    int? selectedAccountId;
    int? destinationAccountId;
    int? selectedCategoryId;
    TextEditingController _amountController = TextEditingController();
    TextEditingController _descriptionController = TextEditingController();
    String transactionType = "Expense";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Transaction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedAccountId,
                      items: _accounts.map((account) {
                        return DropdownMenuItem<int>(
                          value: account['id'],
                          child: Text(account['name']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() {
                        selectedAccountId = value;
                      }),
                      hint: Text('Select Account'),
                    ),
                    DropdownButtonFormField<String>(
                      value: transactionType,
                      items: ["Expense", "Income", "Transfer"]
                          .map((type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() {
                        transactionType = value!;
                        if (transactionType != "Transfer") {
                          destinationAccountId = null;
                        }
                      }),
                      hint: Text('Select Transaction Type'),
                    ),
                    if (transactionType == "Transfer")
                      DropdownButtonFormField<int>(
                        value: destinationAccountId,
                        items: _accounts
                            .where((account) => account['id'] != selectedAccountId)
                            .map((account) => DropdownMenuItem<int>(
                                  value: account['id'],
                                  child: Text(account['name']),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() {
                          destinationAccountId = value;
                        }),
                        hint: Text('Select Destination Account'),
                      ),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Transaction Amount'),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Transaction Description'),
                    ),
                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      items: _categories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category['id'],
                          child: Text(category['name']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() {
                        selectedCategoryId = value;
                      }),
                      hint: Text('Select Category'),
                    ),
                    TextButton(
                      onPressed: _showAddCategoryDialog,
                      child: Text('Add Custom Category'),
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
                    if (selectedAccountId != null &&
                        _amountController.text.isNotEmpty &&
                        selectedCategoryId != null &&
                        (transactionType != "Transfer" ||
                            destinationAccountId != null)) {
                      double transactionAmount =
                          double.parse(_amountController.text);
                      String description = _descriptionController.text;
                      String date = DateTime.now().toIso8601String();

                      await DatabaseHelper.instance.insertTransaction(
                        selectedAccountId!,
                        description,
                        transactionAmount,
                        date,
                        transactionType,
                        selectedCategoryId!,
                      );

                      if (transactionType == "Expense") {
                        final account = _accounts.firstWhere(
                            (account) => account['id'] == selectedAccountId);
                        double updatedBalance =
                            account['balance'] - transactionAmount;
                        await _updateBalance(selectedAccountId!, updatedBalance);
                      } else if (transactionType == "Income") {
                        final account = _accounts.firstWhere(
                            (account) => account['id'] == selectedAccountId);
                        double updatedBalance =
                            account['balance'] + transactionAmount;
                        await _updateBalance(selectedAccountId!, updatedBalance);
                      } else if (transactionType == "Transfer") {
                        final sourceAccount = _accounts.firstWhere(
                            (account) => account['id'] == selectedAccountId);
                        final destinationAccount = _accounts.firstWhere(
                            (account) => account['id'] == destinationAccountId);

                        double updatedSourceBalance =
                            sourceAccount['balance'] - transactionAmount;
                        double updatedDestinationBalance =
                            destinationAccount['balance'] + transactionAmount;

                        await _updateBalance(
                            selectedAccountId!, updatedSourceBalance);
                        await _updateBalance(
                            destinationAccountId!, updatedDestinationBalance);
                      }

                      await _fetchTransactions();
                      await _fetchAccounts();
                      Navigator.pop(context);
                    }
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 2,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3,
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
                Divider(thickness: 1),
                Text('Recent Transactions', style: TextStyle(fontSize: 16)),
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    padding: EdgeInsets.all(10),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                        child: ListTile(
                          title: Text(transaction['description']),
                          subtitle: Text(
                              'Type: ${transaction['transactionType']} - ₹${transaction['amount']}'),
                          trailing: Text(
                              '${DateTime.parse(transaction['date']).toLocal().toString().split(' ')[0]}'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _transactionDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
