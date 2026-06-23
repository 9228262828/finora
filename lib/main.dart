import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const FinoraApp());
}

class FinoraApp extends StatefulWidget {
  const FinoraApp({super.key});

  @override
  State<FinoraApp> createState() => _FinoraAppState();
}

class _FinoraAppState extends State<FinoraApp> {
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => darkMode = prefs.getBool('darkMode') ?? false);
  }

  Future<void> updateTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
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
        colorSchemeSeed: const Color(0xFF047857),
        scaffoldBackgroundColor: const Color(0xFFF7F5EF),
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
      title: json['title'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] ?? 'expense',
      category: json['category'] ?? 'General',
      date: json['date'] ?? '',
    );
  }
}

class SplashScreen extends StatelessWidget {
  final Function(bool) onThemeChanged;

  const SplashScreen({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF052E2B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD166),
                  borderRadius: BorderRadius.circular(50),
                ),child:
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image(
                      image: const AssetImage("assets/logo.png"),
                      width: 50,
                    ),
                  )
              ),
              const SizedBox(height: 34),
              const Text(
                'Finora',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Simple money tracking\nfor everyday life.',
                style: TextStyle(
                  color: Colors.white.withOpacity(.75),
                  fontSize: 18,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD166),
                    foregroundColor: const Color(0xFF052E2B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            HomeScreen(onThemeChanged: onThemeChanged),
                      ),
                    );
                  },
                  child: const Text(
                    'Start Tracking',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
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
      .fold(0.0, (sum, e) => sum + e.amount);

  double get expense => items
      .where((e) => e.type == 'expense')
      .fold(0.0, (sum, e) => sum + e.amount);

  double get balance => income - expense;

  Future<void> addTransaction() async {
    final result = await Navigator.push<TransactionItem>(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );

    if (result != null) {
      setState(() => items.insert(0, result));
      saveItems();
    }
  }

  void deleteTransaction(int index) {
    setState(() => items.removeAt(index));
    saveItems();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: addTransaction,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          onThemeChanged: widget.onThemeChanged,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B) : const Color(0xFF052E2B),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Balance',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: MoneyBox(
                          title: 'Income',
                          amount: income,
                          icon: Icons.south_west_rounded,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MoneyBox(
                          title: 'Expense',
                          amount: expense,
                          icon: Icons.north_east_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 44),
                    SizedBox(height: 12),
                    Text(
                      'No transactions yet',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tap + to add your first income or expense.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isIncome = item.type == 'income';

              return Dismissible(
                key: ValueKey('${item.title}-${item.date}-$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                onDismissed: (_) => deleteTransaction(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isIncome
                              ? Colors.green.withOpacity(.12)
                              : Colors.red.withOpacity(.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
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
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class MoneyBox extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const MoneyBox({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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

  final categories = [
    'General',
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Salary',
  ];

  void save() {
    final title = titleController.text.trim();
    final amount = double.tryParse(amountController.text.trim());

    if (title.isEmpty || amount == null || amount <= 0) return;

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
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = type == 'expense';

    return Scaffold(
      appBar: AppBar(title: const Text('New Transaction')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isExpense
                  ? Colors.red.withOpacity(.08)
                  : Colors.green.withOpacity(.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: SegmentedButton<String>(
              selected: {type},
              onSelectionChanged: (v) => setState(() => type = v.first),
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'income', label: Text('Income')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Transaction title',
              prefixIcon: Icon(Icons.edit_note_rounded),
              filled: true,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixIcon: Icon(Icons.attach_money_rounded),
              filled: true,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: category,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category_rounded),
              filled: true,
            ),
            items: categories
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => category = v ?? 'General'),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: save,
              child: const Text('Save Transaction'),
            ),
          ),
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
      appBar: AppBar(
        title: const Text('Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF052E2B),
              borderRadius: BorderRadius.circular(28),
            ),
            child:  Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image(
                    image: const AssetImage("assets/logo.png"),
                    width: 50,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Finora\nLocal Expense Tracker',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            value: darkMode,
            onChanged: changeTheme,
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode_rounded),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_rounded),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.article_rounded),
            title: const Text('Terms & Conditions'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsScreen()),
            ),
          ),
          const SizedBox(height: 22),
          const Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
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
      'Finora is a simple local expense tracking app. The app stores your transactions, income, expenses, categories, balance data, and settings locally on your device using local storage. Finora does not require account creation, login, backend servers, Firebase, ads, or third-party data sharing. Your financial tracking data remains on your device. You can remove stored data by clearing app data or uninstalling the app.',
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
      'By using Finora, you agree that the app is provided as a personal expense tracking tool only. Finora does not provide financial, investment, tax, or legal advice. Users are responsible for entering accurate data and making their own financial decisions. The app is provided as-is without guarantees. Since data is stored locally, users are responsible for protecting their device and backups.',
    );
  }
}

class TextPage extends StatelessWidget {
  final String title;
  final String text;

  const TextPage({
    super.key,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}