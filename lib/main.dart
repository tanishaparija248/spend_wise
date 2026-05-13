import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_wise/models/expense.dart';
import 'package:spend_wise/models/todo.dart';
import 'package:spend_wise/screens/dashboard_screen.dart';
import 'package:spend_wise/screens/expense_screen.dart';
import 'package:spend_wise/screens/todo_screen.dart';

void main() {
  runApp(const SpendWiseApp());
}

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple.shade100,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
        ),
      ),
      home: const SpendWiseHome(),
    );
  }
}

class SpendWiseHome extends StatefulWidget {
  const SpendWiseHome({super.key});

  @override
  State<SpendWiseHome> createState() => _SpendWiseHomeState();
}

class _SpendWiseHomeState extends State<SpendWiseHome> {
  static const String _expenseKey = 'spendwise_expenses';
  static const String _todosKey = 'spendwise_todos';

  int _selectedTab = 0;

  final List<Expense> _expenses = <Expense>[];
  final List<Todo> _todos = <Todo>[];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    final List<String> savedExpenses =
        prefs.getStringList(_expenseKey) ?? <String>[];

    final List<String> savedTodos =
        prefs.getStringList(_todosKey) ?? <String>[];

    final List<Expense> parsedExpenses =
    savedExpenses.map((String item) {
      final dynamic decoded = jsonDecode(item);

      return Expense.fromJson(
        decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{},
      );
    }).toList();

    final List<Todo> parsedTodos =
    savedTodos.map((String item) {
      final dynamic decoded = jsonDecode(item);

      return Todo.fromJson(
        decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{},
      );
    }).toList();

    setState(() {
      _expenses.clear();
      _expenses.addAll(parsedExpenses);

      _todos.clear();
      _todos.addAll(parsedTodos);
    });
  }

  Future<void> _saveData() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    final List<String> expenseJson = _expenses
        .map((Expense item) => jsonEncode(item.toJson()))
        .toList();

    final List<String> todoJson = _todos
        .map((Todo item) => jsonEncode(item.toJson()))
        .toList();

    await prefs.setStringList(_expenseKey, expenseJson);
    await prefs.setStringList(_todosKey, todoJson);
  }

  void _openDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DashboardScreen(
          expenses: _expenses,
          todos: _todos,
        ),
      ),
    );
  }

  // ACTION METHODS

  void _addExpense(Expense expense) {
    setState(() {
      _expenses.add(expense);

      _expenses.sort(
            (Expense a, Expense b) =>
            b.date.compareTo(a.date),
      );
    });

    _saveData();
  }

  void _deleteExpense(int index) {
    setState(() {
      _expenses.removeAt(index);
    });

    _saveData();
  }

  void _addTodo(String title) {
    setState(() {
      _todos.add(
        Todo(
          title: title,
          createdAt: DateTime.now(),
        ),
      );
    });

    _saveData();
  }

  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });

    _saveData();
  }

  void _toggleTodo(int index) {
    setState(() {
      _todos[index].isDone =
      !_todos[index].isDone;
    });

    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> titles = <String>[
      'Expenses',
      'Todo List',
    ];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple.shade100,
          title: Text(
            titles[_selectedTab],
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _openDashboard,
              icon: const Icon(
                Icons.dashboard_outlined,
                color: Colors.black,
              ),
            ),
          ],
        ),
        body: _selectedTab == 0
            ? ExpenseScreen(
          expenses: _expenses,
          onAddExpense: _addExpense,
          onDeleteExpense: _deleteExpense,
        )
            : TodoScreen(
          todos: _todos,
          onAddTodo: _addTodo,
          onToggleTodo: _toggleTodo,
          onDeleteTodo: _deleteTodo,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (int index) {
            setState(() {
              _selectedTab = index;
            });
          },
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(
                Icons.account_balance_wallet_outlined,
              ),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist_outlined),
              label: 'Todo',
            ),
          ],
        ),
      ),
    );
  }
}