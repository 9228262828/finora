import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String appVersion = '1.0.0+1';
const String darkModeKey = 'darkMode';
const String transactionsKey = 'transactions';
const double maxTransactionAmount = 999999999.99;

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
    if (!mounted) return;
    setState(() => darkMode = prefs.getBool(darkModeKey) ?? false);
  }

  Future<void> updateTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(darkModeKey, value);
    if (!mounted) return;
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
    final amount = json['amount'];

    return TransactionItem(
      title: (json['title'] as String?)?.trim() ?? '',
      amount: amount is num ? amount.toDouble() : double.nan,
      type: json['type'] == 'income' ? 'income' : 'expense',
      category: (json['category'] as String?)?.trim().isNotEmpty == true
          ? (json['category'] as String).trim()
          : 'General',
      date: (json['date'] as String?)?.trim() ?? '',
    );
  }

  bool get isValid =>
      title.trim().isNotEmpty &&
      amount.isFinite &&
      amount > 0 &&
      amount <= maxTransactionAmount &&
      (type == 'income' || type == 'expense') &&
      category.trim().isNotEmpty &&
      date.trim().isNotEmpty;
}

class SplashScreen extends StatelessWidget {
  final Function(bool) onThemeChanged;

  const SplashScreen({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF052E2B),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 52,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      label: 'Finora app logo',
                      image: true,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD166),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: const Image(
                            image: AssetImage('assets/logo.png'),
                            width: 50,
                          ),
                        ),
                      ),
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
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .75),
                        fontSize: 18,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 42),
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
            );
          },
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
    final data = prefs.getString(transactionsKey);

    if (data == null || data.isEmpty) return;

    try {
      final decoded = jsonDecode(data);
      if (decoded is! List) return;

      final loadedItems = decoded
          .whereType<Map<String, dynamic>>()
          .map(TransactionItem.fromJson)
          .where((item) => item.isValid)
          .toList();

      if (!mounted) return;
      setState(() => items = loadedItems);
    } on FormatException {
      return;
    }
  }

  Future<void> saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      transactionsKey,
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
      await saveItems();
    }
  }

  Future<void> deleteTransaction(int index) async {
    final removedItem = items[index];
    setState(() => items.removeAt(index));
    await saveItems();

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removedItem.title} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final insertIndex = index.clamp(0, items.length).toInt();
            setState(() => items.insert(insertIndex, removedItem));
            await saveItems();
          },
        ),
      ),
    );
  }

  Future<bool> confirmDelete(TransactionItem item) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete transaction?'),
            content: Text(
              'Remove "${item.title}" for \$${item.amount.toStringAsFixed(2)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add transaction',
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
                  tooltip: 'Open settings',
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
                  FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '\$${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final boxes = [
                        MoneyBox(
                          title: 'Income',
                          amount: income,
                          icon: Icons.south_west_rounded,
                          color: const Color(0xFF10B981),
                        ),
                        MoneyBox(
                          title: 'Expense',
                          amount: expense,
                          icon: Icons.north_east_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                      ];

                      if (constraints.maxWidth < 300) {
                        return Column(
                          children: [
                            boxes.first,
                            const SizedBox(height: 12),
                            boxes.last,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: boxes.first),
                          const SizedBox(width: 12),
                          Expanded(child: boxes.last),
                        ],
                      );
                    },
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
                confirmDismiss: (_) => confirmDelete(item),
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
                  child: Semantics(
                    label:
                        '${isIncome ? 'Income' : 'Expense'} transaction, ${item.title}, ${item.category}, ${item.date}, ${isIncome ? 'plus' : 'minus'} \$${item.amount.toStringAsFixed(2)}. Swipe left to delete.',
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? Colors.green.withValues(alpha: .12)
                                  : Colors.red.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.category} • ${item.date}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${isIncome ? '+' : '-'}\$${item.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '\$${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
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
  String? titleError;
  String? amountError;

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
    String? nextTitleError;
    String? nextAmountError;

    if (title.isEmpty) {
      nextTitleError = 'Enter a transaction title.';
    } else if (title.length > 60) {
      nextTitleError = 'Keep the title under 60 characters.';
    }

    if (amountController.text.trim().isEmpty) {
      nextAmountError = 'Enter an amount.';
    } else if (amount == null || !amount.isFinite) {
      nextAmountError = 'Enter a valid amount.';
    } else if (amount <= 0) {
      nextAmountError = 'Amount must be greater than zero.';
    } else if (amount > maxTransactionAmount) {
      nextAmountError = 'Amount is too large.';
    }

    setState(() {
      titleError = nextTitleError;
      amountError = nextAmountError;
    });

    if (titleError != null || amountError != null) return;

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
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isExpense
                  ? Colors.red.withValues(alpha: .08)
                  : Colors.green.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: SegmentedButton<String>(
              selected: {type},
              onSelectionChanged: (v) => setState(() => type = v.first),
              segments: const [
                ButtonSegment(
                  value: 'expense',
                  label: Text('Expense'),
                  icon: Icon(Icons.north_east_rounded),
                ),
                ButtonSegment(
                  value: 'income',
                  label: Text('Income'),
                  icon: Icon(Icons.south_west_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: titleController,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: 'Transaction title',
              errorText: titleError,
              prefixIcon: const Icon(Icons.edit_note_rounded),
              filled: true,
            ),
            onChanged: (_) {
              if (titleError != null) setState(() => titleError = null);
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                final text = newValue.text;
                if (text.isEmpty ||
                    RegExp(r'^\d{0,9}(\.\d{0,2})?$').hasMatch(text)) {
                  return newValue;
                }
                return oldValue;
              }),
            ],
            decoration: InputDecoration(
              labelText: 'Amount',
              hintText: '0.00',
              errorText: amountError,
              prefixIcon: const Icon(Icons.attach_money_rounded),
              filled: true,
            ),
            onChanged: (_) {
              if (amountError != null) setState(() => amountError = null);
            },
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
    if (!mounted) return;
    setState(() => darkMode = prefs.getBool(darkModeKey) ?? false);
  }

  Future<void> changeTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(darkModeKey, value);
    if (!mounted) return;
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
            child: Row(
              children: [
                Semantics(
                  label: 'Finora logo',
                  image: true,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: const Image(
                      image: AssetImage('assets/logo.png'),
                      width: 50,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
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
            subtitle: const Text('Use Finora with a darker color theme.'),
            secondary: const Icon(Icons.dark_mode_rounded),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_rounded),
            title: const Text('Privacy Policy'),
            subtitle: const Text('How local app data is handled'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.article_rounded),
            title: const Text('Terms & Conditions'),
            subtitle: const Text('Personal-use terms for Finora'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsScreen()),
            ),
          ),
          const SizedBox(height: 22),
          const Center(
            child: Text(
              'Version $appVersion',
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
      text: '''
Finora is a simple local expense tracking app for personal use.

Data stored on your device
Finora stores the transactions you enter, including titles, amounts, transaction type, categories, dates, balance totals, and dark mode preference in local app storage on your device.

No accounts or cloud sync
Finora does not require account creation, login, backend servers, Firebase, or cloud synchronization. Your financial tracking data is not uploaded by Finora.

No ads or third-party selling
Finora does not include ads and does not sell, rent, or share your personal finance entries with advertisers or data brokers.

Your control
Because data is stored locally, you can remove Finora data by deleting transactions in the app, clearing app data from your device settings, or uninstalling the app.

Device responsibility
Anyone with access to your unlocked device may be able to view information in Finora. Use your device passcode and backup settings responsibly.

Policy updates
If Finora changes how data is stored or handled, this policy should be updated before release.''',
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TextPage(
      title: 'Terms & Conditions',
      text: '''
By using Finora, you agree to these terms.

Personal expense tracking only
Finora is provided as a simple tool to help you record and review personal income and expenses. It is not a banking, payment, lending, investment, tax, or accounting service.

No financial advice
Finora does not provide financial, investment, tax, legal, or professional advice. You are responsible for your financial decisions and for verifying any information before relying on it.

User-entered data
You are responsible for entering accurate transaction information. Finora calculates balances from the information you provide and cannot guarantee that user-entered data is complete or correct.

Local storage
Finora stores app data locally on your device. You are responsible for protecting your device, maintaining backups if needed, and understanding that uninstalling the app or clearing app data may delete your stored transactions.

No warranties
Finora is provided as-is without warranties or guarantees. To the fullest extent allowed by law, the app developer is not responsible for losses, missed payments, incorrect entries, device issues, or decisions made using the app.

Acceptable use
Use Finora only for lawful personal tracking purposes and do not attempt to misuse, reverse engineer, or disrupt the app.

Changes to terms
These terms may be updated as Finora changes. Continued use of the app means you accept the current terms.''',
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
              text.trim(),
              style: const TextStyle(fontSize: 16, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}