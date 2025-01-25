import 'package:flutter/material.dart';
import 'screens/account_list_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Account Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AccountListScreen(),
    );
  }
}
