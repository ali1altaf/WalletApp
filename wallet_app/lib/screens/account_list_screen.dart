import 'package:flutter/material.dart';
import '../database_helper.dart';

class AccountListScreen extends StatefulWidget {
  @override
  _AccountListScreenState createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true; // To manage loading state

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
    _fetchTransactions();
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

  void _transactionDialog() {
    int? selectedAccountId;
    int? destinationAccountId;
    TextEditingController _amountController = TextEditingController();
    String transactionType = "Expense";
    TextEditingController _descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Transaction'),
              content: Column(
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
                    decoration:
                        InputDecoration(labelText: 'Transaction Amount'),
                  ),
                  TextField(
                    controller: _descriptionController,
                    decoration:
                        InputDecoration(labelText: 'Transaction Description'),
                  ),
                ],
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
                        _amountController.text.isNotEmpty &&
                        (transactionType != "Transfer" ||
                            destinationAccountId != null)) {
                      double transactionAmount =
                          double.parse(_amountController.text);

                      String description = _descriptionController.text;

                      // Insert transaction record into the database
                      String date =
                          DateTime.now().toIso8601String(); // Current date
                      await DatabaseHelper.instance.insertTransaction(
                        selectedAccountId!,
                        description,
                        transactionAmount,
                        date,
                        transactionType,
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
                      _fetchTransactions();
                      _fetchAccounts();
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: _transactionDialog,
            label: Text('Transaction'),
            icon: Icon(Icons.add),
          ),
          SizedBox(height: 10),
          FloatingActionButton.extended(
            onPressed: _addAccountDialog,
            label: Text('Account'),
            icon: Icon(Icons.add),
            heroTag: 'addAccount',
          ),
        ],
      ),
    );
  }
}
