import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../main.dart';

class MyBoxScreen extends StatefulWidget {
  const MyBoxScreen({super.key});

  @override
  MyBoxScreenState createState() => MyBoxScreenState();
}

class MyBoxScreenState extends State<MyBoxScreen> {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _transactions = [];
  final _formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final detailsController = TextEditingController();
  DateTime? _selectedDate; // للتاريخ المحدد (اليوم، الأمس، يوم محدد)

  String? selectedType;
  String? selectedTypeFull;

  final amountFocusNode = FocusNode();
  final detailsFocusNode = FocusNode();
  double profitpegsho = 0;
  final formatter = NumberFormat('#,###');
  @override
  void initState() {
    super.initState();
    _refreshTransactions(); // تحديث البيانات عند بدء الواجهة
    _filterTransactionsByDate(DateTime.now());
    _selectedDate = DateTime.now();
    selectedTypeFull = 'اليوم';

    amountFocusNode.requestFocus();
  }

  @override
  void dispose() {
    amountFocusNode.dispose();
    detailsFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 8, // إضافة ظل للنافذة
            child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    decoration: const BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        topRight: Radius.circular(16.0),
                      ),
                    ),
                    child: const Text(
                      'اختر الفترة الزمنية',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.all(6),
                    color: const Color(0xFFEAEAEA),
                    child: Wrap(
                      spacing: 10.0, // المسافة الأفقية بين الخيارات
                      runSpacing: 18.0, // المسافة العمودية بين الصفوف
                      alignment: WrapAlignment.spaceAround, // محاذاة الخيارات
                      children: [
                        _buildOptionTile(
                          icon: Icons.calendar_today,
                          text: 'يوم محدد',
                          onTap: () async {
                            Navigator.pop(context);
                            await _selectDateViwe(context);
                            selectedTypeFull = 'عرض عمليات يوم        ';
                          },
                        ),
                        _buildOptionTile(
                          icon: Icons.today,
                          text: 'اليوم',
                          onTap: () async {
                            Navigator.pop(context);
                            _selectedDate = DateTime.now();

                            _filterTransactionsByDate(DateTime.now());
                            selectedTypeFull = 'اليوم ';
                          },
                        ),
                        _buildOptionTile(
                          icon: Icons.calendar_view_week,
                          text: 'الأسبوع الحالي',
                          onTap: () async {
                            _selectedDate = null;

                            selectedTypeFull = 'عرض عمليات الأسبوع الحالي ';
                            Navigator.pop(context);
                            _filterTransactionsByWeek(); // تنفيذ فلترة الأسبوع
                          },
                        ),
                        _buildOptionTile(
                          icon: Icons.calendar_month,
                          text: 'الشهر الحالي',
                          onTap: () async {
                            _selectedDate = null;

                            selectedTypeFull = 'عرض عمليات الشهر الحالي ';

                            Navigator.pop(context);
                            _filterTransactionsByMonth(); // تنفيذ فلترة الشهر
                          },
                        ),
                        _buildOptionTile(
                          icon: Icons.list_alt,
                          text: 'كل العمليات',
                          onTap: () async {
                            _selectedDate = null;

                            selectedTypeFull = 'عرض كل العمليات';

                            Navigator.pop(context);
                            _refreshTransactions();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  )
                ])),
          );
        });
  }

// دالة مساعدة لإنشاء عنصر خيار أنيق
  Widget _buildOptionTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 25,
              color: Colors.cyan,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

// دالة لفلترة العمليات حسب الشهر
  void _filterTransactionsByMonth() async {
    final transactions = await dbHelper.getMyBoxTransactions();

    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    final filteredTransactions = transactions.where((transaction) {
      final transactionDate = DateTime.parse(transaction['date']);
      return transactionDate.month == currentMonth &&
          transactionDate.year == currentYear;
    }).toList();

    if (filteredTransactions.isEmpty) {
      _showErrorMessage('لا يوجد عمليات لهذا الشهر');
    }

    setState(() {
      _transactions = filteredTransactions;
    });
  }

// دالة لفلترة العمليات حسب الأسبوع
  void _filterTransactionsByWeek() async {
    final transactions = await dbHelper.getMyBoxTransactions();
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final filteredTransactions = transactions.where((transaction) {
      final transactionDate = DateTime.parse(transaction['date']);
      return transactionDate
              .isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          transactionDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
    if (filteredTransactions.isEmpty) {
      _showErrorMessage('لا يوجد عمليات لهذا الأسبوع');
    }

    setState(() {
      _transactions = filteredTransactions;
    });
  }

  // دالة لتحديث قائمة العمليات
  Future<void> _refreshTransactions() async {
    final data = await dbHelper.getMyBoxTransactions();
    setState(() {
      _transactions = data;

      // حساب مجموع الكسب
      final totalIncome = _transactions
          .where((transaction) => transaction['type'] == 'ادخار')
          .fold(0.0, (sum, transaction) => sum + transaction['amount']);

      // حساب مجموع الصرف
      final totalExpense = _transactions
          .where((transaction) => transaction['type'] == 'سحب')
          .fold(0.0, (sum, transaction) => sum + transaction['amount']);
      final profitpeg = totalIncome - totalExpense;
      profitpegsho = profitpeg;
    });
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6, // إضافة ظل للرسالة
        margin: const EdgeInsets.all(16), // هامش حول الرسالة
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6, // إضافة ظل للرسالة
        margin: const EdgeInsets.all(16), // هامش حول الرسالة
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _showAddTransactionDialog() async {
    String? selectedType; // تعريف المتغير داخل الدالة
    final amountController = TextEditingController();
    final detailsController = TextEditingController();
    // String details = _detailsController.text.trim();
    String typeDaily = 'كسب';
    String detailDaily = '';
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFFF6F6F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // العنوان
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        decoration: const BoxDecoration(
                          color: Colors.cyan,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12.0),
                            topRight: Radius.circular(12.0),
                          ),
                        ),
                        child: const Text(
                          'إضافة عملية جديدة',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 2,
                        color: Colors.cyan,
                      ),
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: amountController,
                                focusNode: amountFocusNode,
                                decoration: const InputDecoration(
                                  labelText: 'المبلغ',
                                  labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.cyan),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.cyan, width: 2.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.cyan, width: 2.0),
                                  ),
                                ),
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800),
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) {
                                  detailsFocusNode.requestFocus();
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال المبلغ';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20.0),
                              TextFormField(
                                controller: detailsController,
                                focusNode: detailsFocusNode,
                                decoration: const InputDecoration(
                                  labelText: 'التفاصيل',
                                  labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.cyan),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.cyan, width: 2.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.cyan, width: 2.0),
                                  ),
                                ),
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال التفاصيل';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        // 'سحب''ادخار'
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // خيار "صرف"
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedType = 'سحب';
                                amountFocusNode.unfocus();
                                detailsFocusNode.unfocus();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 10.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: selectedType == 'سحب'
                                    ? Colors.red
                                    : Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFFF665B),
                                  width: 2.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'سحب',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w800,
                                    color: selectedType == 'سحب'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // خيار "كسب"
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedType = 'ادخار';
                                amountFocusNode.unfocus();
                                detailsFocusNode.unfocus();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 10.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: selectedType == 'ادخار'
                                    ? Colors.green
                                    : Colors.white,
                                border: Border.all(
                                  color: const Color(0xFF70FF75),
                                  width: 2.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'ادخار',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w800,
                                    color: selectedType == 'ادخار'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      Container(
                        width: double.infinity,
                        height: 2,
                        color: Colors.cyan,
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12.0),
                            bottomRight: Radius.circular(12.0),
                          ),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  Navigator.pop(context);
                                  if (selectedType == null) {
                                    _showErrorMessage(
                                        'يرجى اختيار نوع العملية');

                                    return;
                                  }
                                  final amount =
                                      double.tryParse(amountController.text) ??
                                          0.0;
                                  final details = detailsController.text;
                                  final type = selectedType!;
                                  final dbHelper = DatabaseHelper();
                                  await dbHelper.insertMyBoxTransaction(
                                      amount, details, type);
                                  if (selectedType == 'سحب') {
                                    detailDaily = '🗳 $details';
                                    final dbHelper = DatabaseHelper();
                                    await dbHelper.insertDailyTransaction(
                                        amount, detailDaily, typeDaily);
                                  }
                                  setState(() {
                                    _selectedDate = DateTime.now();
                                    selectedTypeFull = 'اليوم ';
                                    _filterTransactionsByDate(_selectedDate!);
                                  });

                                  _showSuccessMessage(
                                      'تمت إضافة العملية بنجاح');
                                }
                              },
                              child: const Text('حفظ'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('إلغاء'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // دالة لعرض ملخص العمليات
  void _showSummary() {
    // حساب مجموع الكسب
    final totalIncome = _transactions
        .where((transaction) => transaction['type'] == 'ادخار')
        .fold(0.0, (sum, transaction) => sum + transaction['amount']);

    // حساب مجموع الصرف
    final totalExpense = _transactions
        .where((transaction) => transaction['type'] == 'سحب')
        .fold(0.0, (sum, transaction) => sum + transaction['amount']);

    // حساب الربح
    final profit = totalIncome - totalExpense;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFEEEBEB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  decoration: const BoxDecoration(
                    color: Colors.cyan,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'ملخص عمليات',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10.0),

                const SizedBox(height: 16.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(4.0), // الكلمات التعريفية 20%
                      1: FlexColumnWidth(6.0), // البيانات 80%
                    },
                    border: TableBorder.all(
                      color: Colors.cyan,
                      width: 3,
                    ),
                    children: [
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Text(
                              'الكسب',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              totalIncome.toString(),
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Text(
                              'الصرف',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              totalExpense.toString(),
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Text(
                              'الربح',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              profit.toString(),
                              style: TextStyle(
                                color: profit >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                // زر الإغلاق
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'إغلاق',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // دالة لاختيار التاريخ
  Future<void> _selectDateViwe(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ar', 'SA'), // تعيين اللغة العربية
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.cyan, // لون الخلفية
              onPrimary: Colors.white, // لون النص
              surface: Colors.white, // لون الخلفية العامة
              onSurface: Colors.black, // لون النص العام
            ),
            dialogBackgroundColor: Colors.white, // لون خلفية النافذة
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _filterTransactionsByDate(picked);
    }
  }

  // دالة لتصفية العمليات حسب التاريخ
  Future<void> _filterTransactionsByDate(DateTime date) async {
    final transactions = await dbHelper.getMyBoxTransactions();
    final filteredTransactions = transactions.where((transaction) {
      final transactionDate = DateTime.parse(transaction['date']);
      return transactionDate.year == date.year &&
          transactionDate.month == date.month &&
          transactionDate.day == date.day;
    }).toList();

    if (filteredTransactions.isEmpty) {
      _showErrorMessage('لا يوجد عمليات لليوم المحدد');
    }

    setState(() {
      _transactions = filteredTransactions;
    });
  }

  Future<void> _loadTransactions() async {
    if (selectedTypeFull == 'اليوم') {
      setState(() {
        _selectedDate = DateTime.now();
        _filterTransactionsByDate(_selectedDate!);
      });
    } else if (selectedTypeFull == 'عرض عمليات يوم        ') {
      setState(() {
        _filterTransactionsByDate(_selectedDate!);
      });
    } else if (selectedTypeFull == 'عرض عمليات الأسبوع الحالي ') {
      setState(() {
        _filterTransactionsByWeek(); // تنفيذ فلترة الأسبوع
      });
    } else if (selectedTypeFull == 'عرض عمليات الشهر الحالي ') {
      setState(() {
        _filterTransactionsByMonth(); // تنفيذ فلترة الشهر
      });
    } else if (selectedTypeFull == 'عرض كل العمليات') {
      setState(() {
        _refreshTransactions();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'صندوقي',
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 20.0, color: Colors.white),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.home, color: Colors.greenAccent, size: 25),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(
                    isDarkMode: true,
                    onThemeToggle: () {},
                  ),
                ),
              );
            },
          ),
        ),
      ),
      body: Container(
          margin: const EdgeInsets.all(0),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Text('الرصيد',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            )),
                        const Text(' : ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            )),
                        Text(
                          formatter.format(profitpegsho.toInt()),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: profitpegsho < 0.0
                                  ? Colors.red
                                  : Colors.green),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () =>
                          _selectDate(context), // استدعاء نافذة الخيارات
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 244, 244, 244),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.date_range_rounded,
                              color: Colors.cyan,
                              size: 32,
                            ),
                            Text(
                              'تحديد',
                              style: TextStyle(
                                fontSize: 10.0,
                                color: Colors.cyan,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFE6E6E6),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      '       $selectedTypeFull',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    if (_selectedDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Text(
                            '${_selectedDate?.toLocal().toString().split(' ')[0]}',
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF282828),
                                fontWeight: FontWeight.w900),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 0.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 3.0,
                      color: Colors.cyan,
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.cyan,
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 2),
                        child: Row(
                          children: const [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'المبلغ',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  // fontSize: 16.0,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: Text(
                                'التفاصيل',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  // fontSize: 16.0,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'معلومات',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];
                            // تحديد لون الأيقونة حسب نوع العملية
                            Color iconColor;
                            if (transaction['type'] == 'سحب') {
                              iconColor = Colors.red; // لون أحمر للإضافة
                            } else if (transaction['type'] == 'ادخار') {
                              if (transaction['details'].contains('🙎‍♂️')) {
                                iconColor = Colors
                                    .greenAccent; // لون أخضر فاتح إذا كان أول حرف هو
                              } else {
                                iconColor = Colors
                                    .green; // لون أخضر عادي إذا لم يكن أول حرف هو
                              }
                            } else {
                              iconColor = Colors.blue; // لون افتراضي
                            }
                            return Container(
                              decoration: BoxDecoration(
                                color: index % 2 == 0
                                    ? const Color(0xFFF1F1F1)
                                    : Colors.white,
                                border: const Border(
                                  bottom: BorderSide(
                                      color: Colors.cyan, width: 2.0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // عمود المبلغ
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      transaction['amount'].toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: iconColor,
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // عمود التفاصيل
                                  Expanded(
                                    flex: 5,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                              color: Colors.cyan, width: 2.0),
                                          right: BorderSide(
                                              color: Colors.cyan, width: 2.0),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                          horizontal: 5,
                                        ),
                                        child: Text(
                                          transaction['details'],
                                          textAlign: TextAlign.start,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // عمود معلومات
                                  Expanded(
                                    flex: 2,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.info,
                                        color:
                                            iconColor, // اللون يعتمد على نوع العملية
                                        size: 30,
                                      ),
                                      onPressed: () {
                                        _showTransactionDetails(transaction);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00ACC1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // أيقونة البحث
                    GestureDetector(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.search_sharp,
                          color: Colors.green,
                          size: 25,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: _showAddTransactionDialog,
                      child: Container(
                        width: 45, // زيادة العرض
                        height: 45, // زيادة الارتفاع
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(-4, -4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.add_circle,
                            color: Colors
                                .greenAccent, // لون الأيقونة أبيض لتتناسب مع التدرج
                            size: 40, // حجم أكبر للأيقونة
                          ),
                        ),
                      ),
                    ),

                    // أيقونة المعلومات
                    GestureDetector(
                      onTap: _showSummary, // عرض ملخص العمليات

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.redAccent,
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }

  // دالة لحذف عملية
  Future<void> _deleteTransaction(int id) async {
    try {
      // محاولة حذف العملية من قاعدة البيانات
      await dbHelper.deleteBoxTransaction(id);

      // إعادة تحميل العمليات بعد الحذف
      // await _refreshTransactions();
      _loadTransactions();
      // إظهار رسالة نجاح الحذف
      _showSuccessMessage('تم حذف العملية بنجاح');
    } catch (e) {
      // إظهار رسالة فشل الحذف في حالة حدوث خطأ
      _showErrorMessage('فشل في حذف العملية: ${e.toString()}');
    }
  }

  // دالة لعرض تفاصيل العملية في نافذة منبثقة
  void _showTransactionDetails(Map<String, dynamic> transaction) {
    // تحويل النص في صف التاريخ إلى كائن DateTime
    final DateTime parsedDate = DateTime.parse(transaction['date']);

    // استخراج التاريخ بصيغة يوم/شهر/سنة
    final String formattedDate =
        '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';

    // استخراج الوقت بصيغة ساعات ودقائق
    final String formattedTime =
        '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // العنوان
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  decoration: const BoxDecoration(
                    color: Colors.cyan,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'تفاصيل العملية',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3.0), // الكلمات التعريفية 20%
                      1: FlexColumnWidth(7.0), // البيانات 80%
                    },
                    border: TableBorder.all(color: Colors.cyan, width: 3),
                    children: [
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Text(
                              'التاريخ',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13.5),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text(
                              formattedDate,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Text(
                              'الساعة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text(
                              formattedTime,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Text(
                              'تفاصيل',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13.5),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              transaction['details'],
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Text(
                              'المبلغ',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13.5),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text(
                              transaction['amount'].toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: transaction['type'] == 'سحب'
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // تنفيذ عملية الحذف
                        _deleteTransaction(transaction['id']);
                        Navigator.pop(context); // إغلاق النافذة
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'حذف',
                        style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context); // إغلاق النافذة

                        final result = await showDialog(
                          context: context,
                          builder: (context) => EditTransactionDialog(
                            transaction:
                                transaction, // تمرير بيانات العملية الحالية
                          ),
                        );

                        if (result != null && result) {
                          setState(() {
                            _selectedDate = DateTime.now();
                            _loadTransactions();

                            // _filterTransactionsByDate(_selectedDate!);
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'تعديل',
                        style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // إغلاق النافذة
                  },
                  child: const Text('إلغاء'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =====================

// نافذة تعديل العملية
class EditTransactionDialog extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const EditTransactionDialog({Key? key, required this.transaction})
      : super(key: key);

  @override
  EditTransactionDialogState createState() => EditTransactionDialogState();
}

class EditTransactionDialogState extends State<EditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();
  String _selectedType = 'كسب';

  @override
  void initState() {
    super.initState();
    // تعبئة الحقول ببيانات العملية الحالية
    _amountController.text = widget.transaction['amount'].toString();
    _detailsController.text = widget.transaction['details'];
    _selectedType = widget.transaction['type'];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF6F6F6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // العنوان
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: const BoxDecoration(
                  color: Colors.cyan,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.0),
                    topRight: Radius.circular(12.0),
                  ),
                ),
                child: const Text(
                  'تعديل العملية',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // const SizedBox(height: 20.0),
              Container(
                width: double.infinity,
                height: 3,
                color: Colors.cyan,
              ),

              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'المبلغ',
                          labelStyle: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w800),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.cyan),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.cyan, width: 2.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.cyan, width: 2.0),
                          ),
                          contentPadding: EdgeInsets.all(10.0),
                        ),
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w800),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال المبلغ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        controller: _detailsController,
                        decoration: const InputDecoration(
                          labelText: 'التفاصيل',
                          labelStyle: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w800),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.cyan),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.cyan, width: 2.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.cyan, width: 2.0),
                          ),
                          contentPadding: EdgeInsets.all(10.0),
                        ),
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w800),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال التفاصيل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),

                      // اختيار نوع العملية (صرف/كسب)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // خيار "صرف"
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = 'سحب';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 6.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: _selectedType == 'سحب'
                                    ? Colors.red
                                    : Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFFF665B),
                                  width: 2.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'سحب',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w800,
                                    color: _selectedType == 'سحب'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // خيار "كسب"
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = 'ادخار';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 6.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: _selectedType == 'ادخار'
                                    ? Colors.green
                                    : Colors.white,
                                border: Border.all(
                                  color: const Color(0xFF70FF75),
                                  width: 2.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'ادخار',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w800,
                                    color: _selectedType == 'ادخار'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // الحد العلوي بعرض 3 بكسل
              Container(
                width: double.infinity,
                height: 3,
                color: Colors.cyan,
              ),

              // أزرار الحفظ والإلغاء
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12.0),
                    bottomRight: Radius.circular(12.0),
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final amount =
                              double.tryParse(_amountController.text) ?? 0.0;
                          final details = _detailsController.text;
                          final type = _selectedType;

                          final dbHelper = DatabaseHelper();
                          await dbHelper.updateBoxTransaction(
                            widget.transaction['id'], // معرف العملية
                            amount,
                            details,
                            type,
                          );

                          Navigator.pop(context, true); // حفظ وإغلاق النافذة
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تعديل العملية بنجاح'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'حفظ',
                        style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // );
  }
}
