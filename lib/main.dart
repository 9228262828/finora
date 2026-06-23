import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const FinoraApp());

class FinoraApp extends StatefulWidget {
  const FinoraApp({super.key});

  @override
  State<FinoraApp> createState() => _FinoraAppState();
}

class _FinoraAppState extends State<FinoraApp> {
  bool darkMode = false;

  void updateTheme(bool value) {
    setState(() => darkMode = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finora',
      debugShowCheckedModeBanner: false,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF10B981),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF10B981),
      ),
      home: SplashScreen(onThemeChanged: updateTheme),
    );
  }
}

class TransactionItem {
  final String title;
  final double amount;
  final String type;
  final String category;
  final String date;

  TransactionItem({
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'amount': amount,
    'type': type,
    'category': category,
    'date': date,
  };

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      category: json['category'],
      date: json['date'],
    );
  }
}

class SplashScreen extends StatelessWidget {
  final Function(bool) onThemeChanged;

  const SplashScreen({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062A2D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
                  ),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 66),
              ),
              const SizedBox(height: 26),
              const Text(
                'Finora',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Track. Save. Grow.',
                style: TextStyle(
                  color: Colors.white.withOpacity(.75),
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            HomeScreen(onThemeChanged: onThemeChanged),
                      ),
                    );
                  },
                  child: const Text('Get Started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const HomeScreen({super.key, required this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TransactionItem> items = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('transactions');
    if (data != null) {
      final list = jsonDecode(data) as List;
      setState(() {
        items = list.map((e) => TransactionItem.fromJson(e)).toList();
      });
    }
  }

  Future<void> saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'transactions',
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  double get income => items
      .where((e) => e.type == 'income')
      .fold(0, (sum, e) => sum + e.amount);

  double get expense => items
      .where((e) => e.type == 'expense')
      .fold(0, (sum, e) => sum + e.amount);

  double get balance => income - expense;

  Future<void> addItem() async {
    final result = await Navigator.push<TransactionItem>(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );

    if (result != null) {
      setState(() => items.insert(0, result));
      saveItems();
    }
  }

  void deleteItem(int index) {
    setState(() => items.removeAt(index));
    saveItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finora',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SettingsScreen(onThemeChanged: widget.onThemeChanged),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addItem,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF0F766E)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Balance',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  '\$${balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _MiniStat('Income', income, Icons.arrow_downward)),
                    Expanded(child: _MiniStat('Expense', expense, Icons.arrow_upward)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text('Transactions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('No transactions yet')),
            ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isIncome = item.type == 'income';

            return Dismissible(
              key: ValueKey('${item.title}$index'),
              onDismissed: (_) => deleteItem(index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isIncome
                          ? Colors.green.withOpacity(.12)
                          : Colors.red.withOpacity(.12),
                      child: Icon(
                        isIncome
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style:
                              const TextStyle(fontWeight: FontWeight.w800)),
                          Text('${item.category} • ${item.date}'),
                        ],
                      ),
                    ),
                    Text(
                      '${isIncome ? '+' : '-'}\$${item.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    )
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;

  const _MiniStat(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70)),
            Text('\$${value.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        )
      ],
    );
  }
}

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();

  String type = 'expense';
  String category = 'General';

  final categories = ['General', 'Food', 'Transport', 'Shopping', 'Salary'];

  void save() {
    final title = titleController.text.trim();
    final amount = double.tryParse(amountController.text.trim());

    if (title.isEmpty || amount == null) return;

    Navigator.pop(
      context,
      TransactionItem(
        title: title,
        amount: amount,
        type: type,
        category: category,
        date: DateTime.now().toString().substring(0, 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'expense', label: Text('Expense')),
              ButtonSegment(value: 'income', label: Text('Income')),
            ],
            selected: {type},
            onSelectionChanged: (v) => setState(() => type = v.first),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              filled: true,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount',
              filled: true,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: category,
            items: categories
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => category = v ?? 'General'),
            decoration: const InputDecoration(
              labelText: 'Category',
              filled: true,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: save,
              child: const Text('Save'),
            ),
          )
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => darkMode = prefs.getBool('darkMode') ?? false);
    widget.onThemeChanged(darkMode);
  }

  Future<void> changeTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    setState(() => darkMode = value);
    widget.onThemeChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            value: darkMode,
            onChanged: changeTheme,
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode_rounded),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_rounded),
            title: const Text('Privacy Policy'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.article_rounded),
            title: const Text('Terms & Conditions'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsScreen()),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Finora\nVersion 1.0.0\nSimple local expense tracker.',
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TextPage(
      title: 'Privacy Policy',
      text:
      'Finora stores your income, expense, category, and settings data locally on your device. The app does not require login, does not use a backend server, does not use Firebase, does not show ads, and does not share data with third parties.',
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TextPage(
      title: 'Terms & Conditions',
      text:
      'Finora is provided as a simple personal finance tracking tool. It does not provide financial advice. Users are responsible for their own financial decisions and for keeping their local device data safe.',
    );
  }
}

class TextPage extends StatelessWidget {
  final String title;
  final String text;

  const TextPage({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(text, style: const TextStyle(fontSize: 16, height: 1.6)),
        ],
      ),
    );
  }
}