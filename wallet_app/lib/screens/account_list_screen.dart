import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class AccountListScreen extends StatefulWidget {
  @override
  _AccountListScreenState createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _categories = [];

  int? _defaultAccountId;
  bool _isLoading = true; // To manage loading state


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
    final transactions = await DatabaseHelper.instance
        .getLastTransactions(4); // Fetch the last 4 transactions
    setState(() {
      _transactions = transactions;
      if (transactions.isNotEmpty) {
        _defaultAccountId = transactions[0]['account_id']; // Set the default account to the last used account
      }
      _isLoading = false; // Stop loading after fetching
    });
  }

  Future<void> _fetchCategories() async {
    final Categories = await DatabaseHelper.instance.getCategories();
    setState(() {
      _categories = Categories;
      _isLoading = false; // Stop loading after fetching
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
                String accountName = _nameController.text.trim();
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
              onPressed: () {
                Navigator.pop(context);
              },
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
    TextEditingController _customCategoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Custom Category'),
          content: TextField(
            controller: _customCategoryController,
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
                String categoryName = _customCategoryController.text.trim();
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
    int? selectedAccountId =_defaultAccountId;
    int? selectedCategoryId;
    int? destinationAccountId;
    TextEditingController _amountController = TextEditingController();
    TextEditingController _descriptionController = TextEditingController();
    String transactionType = "Expense";
    String _amountLabelText = 'Transaction Amount';
    String _CategoryLabelText = 'Select Category';
    String _AccountLabelText = 'Select Account';


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
                      items: _accounts
                          .map((account) => DropdownMenuItem<int>(
                        value: account['id'],
                        child: Text(account['name']),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAccountId = value;
                        });
                      },
                      hint: Text(_AccountLabelText),
                    ),
                    DropdownButtonFormField<String>(
                      value: transactionType,
                      items: ["Expense", "Income", "Transfer"]
                          .map((type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          transactionType = value!;
                          if (transactionType != "Transfer") {
                            destinationAccountId = null;
                          }
                        });
                      },
                      hint: Text('Select Transaction Type'),
                    ),
                    if (transactionType == "Transfer")
                      DropdownButtonFormField<int>(
                        value: destinationAccountId,
                        items: _accounts
                            .where(
                                (account) => account['id'] != selectedAccountId)
                            .map((account) => DropdownMenuItem<int>(
                          value: account['id'],
                          child: Text(account['name']),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            destinationAccountId = value!;
                          });
                        },
                        hint: Text('Select Destination Account'),
                      ),


                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: _amountLabelText),
                    ),

                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      items: _categories
                          .map((category) => DropdownMenuItem<int>(
                        value: category['id'],
                        child: Text(category['name']),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryId = value;
                        });
                      },
                      hint: Text(_CategoryLabelText),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Transaction Description'),
                    ),
                    TextButton(
                      onPressed: () {
                        _showAddCategoryDialog();
                      },
                      child: Text('Add Custom Category'),
                    ),
                  ],
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

                    if (selectedAccountId != null &&
                        selectedCategoryId != null &&
                        _amountController.text.isNotEmpty) {
                      double transactionAmount = double.parse(_amountController.text);
                      String description = _descriptionController.text;
                      String date = DateTime.now().toIso8601String();

                      // Insert transaction record into the database
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
                        await _updateBalance(
                            selectedAccountId!, updatedBalance);
                      } else if (transactionType == "Income") {
                        final account = _accounts.firstWhere(
                                (account) => account['id'] == selectedAccountId);
                        double updatedBalance =
                            account['balance'] + transactionAmount;
                        await _updateBalance(
                            selectedAccountId!, updatedBalance);
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

                      // Update account balance
                      _fetchTransactions();
                      _fetchAccounts();

                      Navigator.pop(context);
                    }

                    else{

                      if (selectedAccountId == null ) {
                        setState(() {
                          _AccountLabelText='Account is required';
                        });
                        return;
                      }

                      else if (_amountController.text.isEmpty) {
                        setState(() {
                          _amountLabelText = 'Amount is required!'; // Update label text to error message
                        });
                        return;
                      }

                      else if (selectedCategoryId == null) {
                        setState(() {
                          _CategoryLabelText = 'Category is required';
                        });
                        return;
                      }

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
        ],
      ),
    );
  }
}