// ==============Asmael Asid ====================================

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'add_delete.dart';
import 'search.dart';
import '../main.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  AddTransactionPageState createState() => AddTransactionPageState();
}

class AddTransactionPageState extends State<AddTransactionPage> {
  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _detailsFocusNode = FocusNode();

  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0; // الصفحة الحالية

  bool _isSearchActive = false;
  bool _saveTtansaAccount = true;

  String _searchQuery = ''; // لتخزين نص البحث

  int? selectedAgentId; // ID الوكيل المختار
  int? selectedClientId; // ID العميل المختار

  String _selectedView = 'customers'; // عرض العمليات الحالية (عملاء أو وكلاء)
  String _transactionType = ''; //  تخزين نوع العمليه

  List<Map<String, dynamic>> matchingAgents =
      []; // قائمة اسماء الوكلاء المطابقين
  List<Map<String, dynamic>> matchingClients =
      []; // قائمة اسماء العملاء المطابقة

  String? selectedTypeFull;
  String? selectedTypeDolomgo;
  DateTime? _selectedDate; // للتاريخ المحدد (اليوم، الأمس، يوم محدد)
  DateTime? _startDate; // لنطاق التاريخ (بداية الفترة)
  DateTime? _endDate; // لنطاق التاريخ (نهاية الفترة)
  List<Map<String, dynamic>> _recentCustomerTransactions = [];
  List<Map<String, dynamic>> _recentAgentTransactions = [];
  int numberOperationsCust = 0;
  int numberOperationsAgn = 0;

  // =========  تفاعلات الواجهة الواجهه  ===========
  @override
  void initState() {
    super.initState();
    selectedTypeFull = 'اليوم';

    selectedTypeDolomgo = 'اليوم';
    _fetchTransactionsByDate(DateTime.now());
    // تحريك المؤشر إلى نهاية النص عند التركيز على الحقل
    _nameFocusNode.addListener(() {
      if (_nameFocusNode.hasFocus) {
        _moveCursorToEnd(_nameController);
      }
    });

    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus) {
        _moveCursorToEnd(_amountController);
      }
    });

    _detailsFocusNode.addListener(() {
      if (_detailsFocusNode.hasFocus) {
        _moveCursorToEnd(_detailsController);
      }
    });
  }

// =========  نقل المواشر الى اخر حرف ===========
  void _moveCursorToEnd(TextEditingController controller) {
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  }

  // التخلص من الـControllers والـFocusNodes
  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _detailsController.dispose();
    _nameFocusNode.dispose();
    _amountFocusNode.dispose();
    _detailsFocusNode.dispose();
    super.dispose();
  }

/*
   =======================================
        $$$== استرجاع العمليات ==$$$
   =======================================
*/
// جلب العمليات   بناءً على التاريخ المحدد
  Future<void> _fetchTransactionsByDate(DateTime date) async {
    final transactions = await DatabaseHelper().getOperationsByDate(date);
    final transactionsAg =
        await DatabaseHelper().getAgentOperationsByDate(date);

    setState(() {
      _recentCustomerTransactions = transactions;
      _recentAgentTransactions = transactionsAg;
      numberOperationsCust = _recentCustomerTransactions.length;
      numberOperationsAgn = _recentAgentTransactions.length;
      _selectedDate = date;
    });
  }

// جلب العمليات للأسبوع الحالي
  Future<void> _fetchTransactionsByWeek() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final transactions = await DatabaseHelper().getOperationsByDateRange(
      startOfWeek,
      now,
    );
    final transactionsAg = await DatabaseHelper().getAgentOperationsByDateRange(
      startOfWeek,
      now,
    );
    setState(() {
      _recentCustomerTransactions = transactions;
      _recentAgentTransactions = transactionsAg;
      numberOperationsCust = _recentCustomerTransactions.length;
      numberOperationsAgn = _recentAgentTransactions.length;
      _selectedDate = null; // لا يوجد تاريخ محدد
    });
  }

// جلب العمليات للشهر الحالي أو شهر معين
  Future<void> _fetchTransactionsByMonth(DateTime date) async {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 0);
    final transactions = await DatabaseHelper().getOperationsByDateRange(
      startOfMonth,
      endOfMonth,
    );
    final transactionsAg = await DatabaseHelper().getAgentOperationsByDateRange(
      startOfMonth,
      endOfMonth,
    );
    setState(() {
      _recentCustomerTransactions = transactions;
      _recentAgentTransactions = transactionsAg;
      numberOperationsCust = _recentCustomerTransactions.length;
      numberOperationsAgn = _recentAgentTransactions.length;
      _selectedDate = null;
    });
  }

  // جلب كل العمليات
  Future<void> _fetchAllTransactions() async {
    final transactionsCu = await DatabaseHelper().getAllOperations();
    final transactionsAg = await DatabaseHelper().getAgentAllOperations();
    setState(() {
      _recentCustomerTransactions = transactionsCu;
      _recentAgentTransactions = transactionsAg;
      numberOperationsCust = _recentCustomerTransactions.length;
      numberOperationsAgn = _recentAgentTransactions.length;
      _selectedDate = null;
    });
  }

//  ========= تحديث الواجهه ===========
  Future<void> fetchTransactions() async {
    if (_selectedDate != null) {
      await _fetchTransactionsByDate(_selectedDate!);
    } else if (_startDate != null && _endDate != null) {
      final transactions = await DatabaseHelper().getOperationsByDateRange(
        _startDate!,
        _endDate!,
      );
      final transactionsAg =
          await DatabaseHelper().getAgentOperationsByDateRange(
        _startDate!,
        _endDate!,
      );
      setState(() {
        _recentCustomerTransactions = transactions;
        _recentAgentTransactions = transactionsAg;
        numberOperationsCust = _recentCustomerTransactions.length;
        numberOperationsAgn = _recentAgentTransactions.length;

        _selectedDate = null;
      });
    } else {
      // إذا لم يتم تحديد أي تاريخ أو نطاق زمني
      await _fetchAllTransactions();
    }
  }

/*
   =======================================
        $$$++ اضافة العمليات ++$$$
   =======================================
*/
  //   استرجاع الاسماء للعملاء
  void _searchClients(String query) async {
    if (query.isEmpty) {
      setState(() {
        matchingClients = [];
      });
      return;
    }
    final results = await DatabaseHelper().searchClientsByName(query);
    setState(() {
      matchingClients = results;
    });
  }

  //   استرجاع الاسماء للوكلاء
  void _searchAgents(String query) async {
    if (query.isEmpty) {
      setState(() {
        matchingAgents = [];
      });
      return;
    }
    final results = await DatabaseHelper().searchAgentsByName(query);
    setState(() {
      matchingAgents = results;
    });
  }

  //    نافذة اختيار  الاضافة لعميل او لوكيل
  void _showAddOperationDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: const Color(0xFFF6F6F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'إضافة عملية الى حساب',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: _buildActionButton(
                        label: 'عميل',
                        icon: Icons.person_outline,
                        color: Colors.blue.shade600,
                        onPressed: () {
                          _saveTtansaAccount = true;

                          Navigator.pop(context);
                          _showAddCustomerOperationDialog(); // فتح نافذة إضافة عملية لعميل
                        },
                      ),
                    ),
                    const SizedBox(width: 20.0),
                    Expanded(
                      child: _buildActionButton(
                        label: 'مورد',
                        icon: Icons.person_outline,
                        color: Colors.orange.shade600,
                        onPressed: () {
                          _saveTtansaAccount = false;

                          Navigator.pop(context);
                          _showAddCustomerOperationDialog();
                        },
                      ),
                    ),
                    const SizedBox(width: 10.0),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //     نافذة اضافة عملية
  void _showAddCustomerOperationDialog() {
    setState(() {
      matchingClients = []; // إعادة تعيين القائمة المقترحة
    });
    final primaryColor =
        _saveTtansaAccount ? Colors.blue.shade700 : Colors.orange.shade700;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                backgroundColor: const Color(0xFFEEEBEB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                insetPadding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // العنوان
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12.0),
                            topRight: Radius.circular(12.0),
                          ),
                        ),
                        child: Text(
                          _saveTtansaAccount
                              ? 'اضافة عملية الى حساب عميل'
                              : 'اضافة عملية الى حساب مورد',
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      _buildNameFieldWithSuggestions(setState),
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

  //    انشاء الحقوال والقائمة المشابهة
  Widget _buildNameFieldWithSuggestions(
      void Function(void Function()) setState) {
    final primaryColor =
        _saveTtansaAccount ? Colors.blue.shade700 : Colors.orange.shade700;
    final borderColor =
        _saveTtansaAccount ? Colors.blue.shade400 : Colors.orange.shade400;
    final typetransaction = _saveTtansaAccount ? 'إضافة' : 'قرض';
    final typetransactionViw = _saveTtansaAccount ? ' دين ' : 'قرض';

// قرض
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // حقل الاسم بدون تسمية خارجية
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: _saveTtansaAccount ? 'اسم العميل' : 'اسم المورد',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  floatingLabelStyle: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _saveTtansaAccount
                        ? _searchClients(value)
                        : _searchAgents(value); // تحديث القائمة المقترحة
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم العميل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildInputField(
                controller: _amountController,
                label: 'المبلغ',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 14),

              _buildInputField(
                controller: _detailsController,
                label: 'تفاصيل العملية',
                icon: Icons.description,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                textInputAction: TextInputAction.done,
              ),
              // حقل التفاصيل
              const SizedBox(height: 18),

              // أزرار نوع العملية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // زر الإضافة
                  _buildTransactionTypeButton(
                    label: typetransactionViw,
                    isSelected: _transactionType == typetransaction,
                    color: Colors.red,
                    onTap: () {
                      setState(() {
                        _transactionType = typetransaction;
                        _amountFocusNode.unfocus();
                        _detailsFocusNode.unfocus();
                      });
                      _saveTtansaAccount
                          ? _saveTransactionToDatabase()
                          : _saveAgentOperation();

                      Navigator.pop(context);
                    },
                  ),

                  // زر التسديد
                  _buildTransactionTypeButton(
                    label: 'تسديد',
                    isSelected: _transactionType == 'تسديد',
                    color: Colors.green,
                    onTap: () {
                      setState(() {
                        _transactionType = 'تسديد';
                        _amountFocusNode.unfocus();
                        _detailsFocusNode.unfocus();
                      });
                      _saveTtansaAccount
                          ? _saveTransactionToDatabase()
                          : _saveAgentOperation();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // قائمة الأسماء المقترحة
        if (matchingClients.isNotEmpty)
          Positioned(
            top: 70, // تحديد موقع القائمة بالنسبة لحقل الإدخال
            left: 20,
            right: 20,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: matchingClients.length,
                  itemBuilder: (context, index) {
                    final client = matchingClients[index];
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          title: Text(
                            client['name'],
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _nameController.text = client['name'];
                              selectedClientId = client['id'];
                              matchingClients = [];
                            });
                          },
                        ),
                        if (index < matchingClients.length - 1)
                          Divider(
                            height: 0.0,
                            color: borderColor.withOpacity(0.3),
                            thickness: 1.7,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        // قائمة الوكلاء المطابقة
        if (matchingAgents.isNotEmpty)
          Positioned(
            top: 70, // تحديد موقع القائمة بالنسبة لحقل الإدخال
            left: 20,
            right: 20,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: matchingAgents.length,
                  itemBuilder: (context, index) {
                    final agent = matchingAgents[index];
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                          ),
                          title: Text(
                            agent['name'],
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _nameController.text = agent['name'];
                              selectedAgentId = agent['id'];
                              matchingAgents = [];
                            });
                          },
                        ),
                        if (index < matchingAgents.length - 1)
                          const Divider(
                            color: Colors.orange,
                            height: 1.0,
                            thickness: 1.0,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  //    حفظ العملية للعملاء
  void _saveTransactionToDatabase() async {
    double? amount = double.tryParse(_amountController.text.trim());
    String details = _detailsController.text.trim();

    if (selectedClientId == null || amount == null || amount <= 0) {
      _showErrorMessage('يرجى اختيار عميل صحيح ومبلغ أكبر من 0');
      return;
    }
    // for (var i = 0; i < 5; i++) {
    await DatabaseHelper().insertOperation(
      selectedClientId!, // إرسال ID العميل
      amount,
      details,
      _transactionType,
    );
    // }

    if (_transactionType == 'تسديد') {
      final dbHelper = DatabaseHelper();
      String type = 'كسب';
      String detailsNum = '🙎‍♂️ ${_nameController.text}';
      await dbHelper.insertDailyTransaction(amount, detailsNum, type);
    }

    _nameController.clear();
    selectedClientId = null;
    _amountController.clear();
    _detailsController.clear();
    _transactionType = '';
    selectedTypeFull = 'اليوم ';
    selectedTypeDolomgo = 'اليوم';

    _selectedDate = DateTime.now();
    _startDate = null;
    _endDate = null;
    await _fetchTransactionsByDate(_selectedDate!);

    if (_currentPage == 1) {
      setState(() {
        _pageController.animateToPage(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      });
    }

    _showSuccessMessage('تم حفظ العملية بنجاح');
  }

  //    حفظ العملية للوكلاء
  void _saveAgentOperation() async {
    //  double? amount = double.tryParse(_amountController.text.trim());
    // String details = _detailsController.text.trim();

    if (_transactionType.isNotEmpty) {
      double? amount = double.tryParse(_amountController.text.trim());
      String details = _detailsController.text.trim();

      if (selectedAgentId == null || amount == null || amount <= 0) {
        _showErrorMessage('يرجى اختيار وكيل صحيح ومبلغ أكبر من 0');

        return;
      }

      // for (var i = 0; i < 1; i++) {
      await DatabaseHelper().insertAgentOperation(
        selectedAgentId!,
        amount,
        details,
        _transactionType,
      );
      // }

      if (_transactionType == 'تسديد') {
        String type = 'صرف';
        String detailsNum = '🏭 تسديد  ${_nameController.text}';
        final dbHelper = DatabaseHelper();
        await dbHelper.insertDailyTransaction(amount, detailsNum, type);
      }

      _nameController.clear();
      selectedAgentId = null;
      _amountController.clear();
      _detailsController.clear();
      _transactionType = '';
      // تحديث البيانات بناءً على الصفحة الحالية
      selectedTypeFull = 'اليوم ';
      selectedTypeDolomgo = 'اليوم';

      _selectedDate = DateTime.now();
      _startDate = null;
      _endDate = null;
      await _fetchTransactionsByDate(_selectedDate!);

      if (_currentPage == 0) {
        setState(() {
          _pageController.animateToPage(1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut);
        });
      }

      _showSuccessMessage('تم حفظ العملية بنجاح');
    } else {
      _showErrorMessage('يرجى اختيار نوع العملية');
    }
  }

/*
   =======================================
    $$$✍✍ التحكم في العمليات ✍✍$$$
   =======================================
*/
  //   حذف عملية
  void _deleteTransaction(Map<String, dynamic> transaction) async {
    // احصل على معرف العملية
    final int? transactionId = transaction['operation_id'];

    if (transactionId == null) {
      _showErrorMessage('العملية المحددة غير صالحة للحذف');

      return;
    }

    try {
      // احصل على المثيل
      final databaseHelper = DatabaseHelper();
      int rowsAffected = 0;

      if (_selectedView == 'customers') {
        // حذف العملية من جدول العملاء
        rowsAffected = await databaseHelper.deleteOperation(transactionId);
      } else if (_selectedView == 'agents') {
        // حذف العملية من جدول الوكلاء
        rowsAffected = await databaseHelper.deleteAgentOperation(transactionId);
      }

      if (rowsAffected > 0) {
        await fetchTransactions();

        _showSuccessMessage('تم حذف العملية بنجاح');
      } else {
        _showErrorMessage('فشل في حذف العملية');
      }
    } catch (error) {
      _showErrorMessage('حدث خطأ أثناء حذف العملية');
    }
  }

  //   تعديل عملية
  Future<void> _editTransaction(Map<String, dynamic> transaction) async {
    if (!transaction.containsKey('amount') ||
        !transaction.containsKey('details') ||
        !transaction.containsKey('type')) {
      return;
    }

    final isCustomers = _selectedView == 'customers';
    final primaryColor =
        isCustomers ? Colors.blue.shade700 : Colors.orange.shade700;

    final amountController =
        TextEditingController(text: transaction['amount'].toString());
    final detailsController =
        TextEditingController(text: transaction['details']);
    String selectedType = transaction['type'];
    String typeLabel = isCustomers ? 'إضافة' : 'قرض';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                primaryColor.withOpacity(0.8)
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.edit, size: 32, color: Colors.white),
                              SizedBox(height: 8),
                              Text(
                                'تعديل العملية',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Form Fields
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildInputField(
                                controller: amountController,
                                label: 'المبلغ',
                                icon: Icons.attach_money,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              _buildInputField(
                                controller: detailsController,
                                label: 'تفاصيل العملية',
                                icon: Icons.description,
                                onEditingComplete: () =>
                                    FocusScope.of(context).nextFocus(),
                                textInputAction: TextInputAction.done,
                              ),

                              const SizedBox(height: 16),

                              // Transaction Type
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildTransactionTypeButton(
                                    label: typeLabel,
                                    isSelected: selectedType == typeLabel,
                                    color: Colors.red,
                                    onTap: () => setState(
                                        () => selectedType = typeLabel),
                                  ),
                                  _buildTransactionTypeButton(
                                    label: 'تسديد',
                                    isSelected: selectedType == 'تسديد',
                                    color: Colors.green,
                                    onTap: () =>
                                        setState(() => selectedType = 'تسديد'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  label: 'إلغاء',
                                  icon: Icons.close,
                                  color: Colors.red.shade600,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  label: 'حفظ',
                                  icon: Icons.save_as_outlined,
                                  color: Colors.green.shade600,
                                  onPressed: () async {
                                    if (amountController.text.isEmpty ||
                                        detailsController.text.isEmpty) {
                                      _showErrorMessage(
                                          'يرجى تعبئة جميع الحقول');
                                      return;
                                    }

                                    try {
                                      final databaseHelper = DatabaseHelper();
                                      int rowsAffected = 0;

                                      if (isCustomers) {
                                        rowsAffected = await databaseHelper
                                            .updateOperation(
                                          transaction['operation_id'],
                                          double.parse(amountController.text),
                                          detailsController.text,
                                          selectedType,
                                        );
                                      } else {
                                        rowsAffected = await databaseHelper
                                            .updateAgentOperation(
                                          transaction['operation_id'],
                                          double.parse(amountController.text),
                                          detailsController.text,
                                          selectedType,
                                        );
                                      }

                                      if (rowsAffected > 0 && mounted) {
                                        Navigator.of(context).pop();
                                        await fetchTransactions();
                                        _showSuccessMessage(
                                            'تم تعديل العملية بنجاح');
                                      } else {
                                        _showErrorMessage(
                                            'فشل في تعديل العملية');
                                      }
                                    } catch (error) {
                                      _showErrorMessage(
                                          'حدث خطأ أثناء تعديل العملية');
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

/*
   =======================================
    $$$((دوال لانشاء الواجهات))$$$
   =======================================
*/

  //  نافذة   اختيار التاريخ

  Future<void> _selectDateViwe(BuildContext context) async {
    final primaryColor = _selectedView == 'customers'
        ? Colors.blue.shade700
        : Colors.orange.shade700;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 10,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      await _fetchTransactionsByDate(picked);
    }
  }

  //  نافذة اختيار زمن عرض العمليات
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
                            selectedTypeFull = 'عرض عمليات يوم';
                            selectedTypeDolomgo = 'يوم';

                            _startDate = null;
                            _endDate = null;
                          },
                        ),
                        _buildOptionTile(
                          icon: Icons.today,
                          text: 'اليوم',
                          onTap: () async {
                            Navigator.pop(context);
                            setState(() {
                              selectedTypeFull = 'اليوم ';
                              selectedTypeDolomgo = 'اليوم';

                              _selectedDate = DateTime.now();
                              _startDate = null;
                              _endDate = null;
                            });
                            await _fetchTransactionsByDate(DateTime.now());
                          },
                        ),
                        _buildOptionTile(
                          icon: Icons.arrow_back,
                          text: 'الأمس',
                          onTap: () async {
                            Navigator.pop(context);
                            setState(() {
                              selectedTypeFull = 'عرض عمليات الامس';
                              selectedTypeDolomgo = 'الامس';

                              _selectedDate = DateTime.now()
                                  .subtract(const Duration(days: 1));
                              _startDate = null;
                              _endDate = null;
                            });
                            await _fetchTransactionsByDate(
                              DateTime.now().subtract(const Duration(days: 1)),
                            );
                          },
                        ),
                        _buildOptionTile(
                          icon: Icons.calendar_view_week,
                          text: 'الأسبوع الحالي',
                          onTap: () async {
                            Navigator.pop(context);
                            final now = DateTime.now();
                            final startOfWeek =
                                now.subtract(Duration(days: now.weekday - 1));
                            setState(() {
                              selectedTypeFull = 'عرض عمليات الأسبوع الحالي';
                              selectedTypeDolomgo = 'الأسبوع الحالي';

                              _selectedDate = null;
                              _startDate = startOfWeek;
                              _endDate = now;
                            });
                            await _fetchTransactionsByWeek();
                          },
                        ),
                        _buildOptionTile(
                          icon: Icons.calendar_month,
                          text: 'الشهر الحالي',
                          onTap: () async {
                            Navigator.pop(context);
                            final now = DateTime.now();
                            final startOfMonth =
                                DateTime(now.year, now.month, 1);
                            final endOfMonth =
                                DateTime(now.year, now.month + 1, 0);
                            setState(() {
                              selectedTypeFull = 'عرض عمليات الشهر الحالي ';
                              selectedTypeDolomgo = 'الشهر الحالي';

                              _selectedDate = null;
                              _startDate = startOfMonth;
                              _endDate = endOfMonth;
                            });
                            await _fetchTransactionsByMonth(now);
                          },
                        ),
                        _buildOptionTile(
                          icon: Icons.calendar_month_outlined,
                          text: 'الشهر الماضي',
                          onTap: () async {
                            Navigator.pop(context);
                            final now = DateTime.now();
                            final lastMonth =
                                DateTime(now.year, now.month - 1, 1);
                            final startOfMonth =
                                DateTime(lastMonth.year, lastMonth.month, 1);
                            final endOfMonth = DateTime(
                                lastMonth.year, lastMonth.month + 1, 0);
                            setState(() {
                              selectedTypeFull = 'عرض عمليات الشهر الماضي ';
                              selectedTypeDolomgo = 'الشهر الماضي';

                              _selectedDate = null;
                              _startDate = startOfMonth;
                              _endDate = endOfMonth;
                            });
                            await _fetchTransactionsByMonth(lastMonth);
                          },
                        ),
                        _buildOptionTile(
                          icon: Icons.list_alt,
                          text: 'كل العمليات',
                          onTap: () async {
                            Navigator.pop(context);
                            setState(() {
                              selectedTypeFull = 'كل العمليات';
                              selectedTypeDolomgo = 'كل العمليات';

                              _selectedDate = null;
                              _startDate = null;
                              _endDate = null;
                            });
                            await _fetchAllTransactions();
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

  //  نافذة ملخص العمليات
  Future<void> _showSummaryDialog(BuildContext context) async {
    Map<String, double> summary;
    final isCustomers = _selectedView == 'customers';
    final primaryColor =
        isCustomers ? Colors.blue.shade700 : Colors.orange.shade700;

    String typeText = isCustomers ? 'ديون العملاء' : 'القروض';
    String boxText = isCustomers ? 'صندوق العملاء' : 'صندوق الموردين';

    if (_selectedDate != null) {
      summary = isCustomers
          ? await DatabaseHelper().getSummaryByDateDey(_selectedDate!)
          : await DatabaseHelper().getAgentSummaryByDate(_selectedDate!);
    } else if (_startDate != null && _endDate != null) {
      summary = isCustomers
          ? await DatabaseHelper().getSummaryByDateRange(_startDate!, _endDate!)
          : await DatabaseHelper()
              .getSummaryAgentByDateRange(_startDate!, _endDate!);
    } else {
      summary = isCustomers
          ? await DatabaseHelper().getSummaryForAllOperations()
          : await DatabaseHelper().getSummaryAgentForAllOperations();
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(8.0, 10.0, 8.0, 2.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.summarize,
                            size: 35, color: Colors.white),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              'ملخص عمليات  $selectedTypeDolomgo',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            if (_selectedDate != null)
                              Text(
                                _selectedDate!
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0],
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.0,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            if (isCustomers)
                              Text(
                                'عدد العمليات :  ${numberOperationsCust.toString()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            if (!isCustomers)
                              Text(
                                'عدد العمليات :  ${numberOperationsAgn.toString()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Summary Cards
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSummaryCard(
                          icon: Icons.payment,
                          title: 'المدفوعات النقديه',
                          value: DatabaseHelper()
                              .getNumberFormat(summary['total_payments']!),
                          color: Colors.green.shade100,
                          valueColor: Colors.green.shade700,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryCard(
                          icon: isCustomers ? Icons.money_off : Icons.money,
                          title: typeText,
                          value: DatabaseHelper()
                              .getNumberFormat(summary['total_additions']!),
                          color: Colors.red.shade100,
                          valueColor: Colors.red.shade700,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryCard(
                          icon: Icons.account_balance_wallet,
                          title: boxText,
                          value: DatabaseHelper()
                              .getNumberFormat(summary['balance']!),
                          color: summary['balance']! >= 0
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          valueColor: summary['balance']! >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          valueSize: 22,
                        ),
                      ],
                    ),
                  ),

                  // Close Button
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                    child: _buildActionButton(
                      label: 'إغلاق',
                      icon: Icons.close,
                      color: primaryColor,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  //    نافذة تفاصيل العملية
  Widget _buildTransactionDetailsDialog(Map<String, dynamic> transaction) {
    final primaryColor = _selectedView == 'customers'
        ? Colors.blue.shade700
        : Colors.orange.shade700;
    final lightColor = _selectedView == 'customers'
        ? Colors.blue.shade100
        : Colors.orange.shade100;

    final teypColor = transaction['type'] == 'تسديد'
        ? Colors.green.shade100
        : Colors.red.shade100;

    final textType =
        transaction['type'] == 'إضافة' ? 'دين' : transaction['type'];

    // معالجة التاريخ والوقت
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(transaction['date'] ?? '');
    } catch (e) {
      parsedDate = DateTime.now();
    }

    final formattedDate =
        '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
    final formattedTime =
        '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';

    return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.receipt_long, size: 28, color: Colors.white),
                      SizedBox(height: 2),
                      Text(
                        'تفاصيل العملية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Transaction Details
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildInfoCard(
                        icon: Icons.person,
                        title: 'الاسم',
                        value: transaction[_selectedView == 'customers'
                                ? 'client_name'
                                : 'agent_name'] ??
                            'غير معروف',
                        color: lightColor,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        icon: Icons.description,
                        title: 'التفاصيل',
                        value: transaction['details'] ?? 'غير معروف',
                        color: lightColor,
                      ),
                      const SizedBox(height: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8), // تقليل الهوامش الجانبية
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius:
                                BorderRadius.circular(10), // زوايا أقل استدارة
                            border: Border.all(color: teypColor),
                          ),
                          child: Column(children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    icon: Icons.calendar_month_rounded,
                                    title: 'التاريخ',
                                    value: formattedDate,
                                    color: lightColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildInfoCard(
                                    icon: Icons.access_time,
                                    title: 'الوقت',
                                    value: formattedTime,
                                    color: lightColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    icon: Icons.attach_money,
                                    title: 'المبلغ',
                                    value: DatabaseHelper().getNumberFormat(
                                        transaction['amount']!),
                                    color: teypColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildInfoCard(
                                    icon: Icons.type_specimen,
                                    title: 'النوع',
                                    value: textType,
                                    color: teypColor,
                                  ),
                                ),
                              ],
                            ),
                          ]))
                    ],
                  ),
                ),

                // Action Buttons
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: 'حذف',
                          icon: Icons.delete,
                          color: Colors.red.shade600,
                          onPressed: () {
                            Navigator.of(context).pop();
                            _deleteTransaction(transaction);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          label: 'تعديل',
                          icon: Icons.edit,
                          color: Colors.orange.shade600,
                          onPressed: () {
                            Navigator.of(context).pop();
                            _editTransaction(transaction);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          label: 'إغلاق',
                          icon: Icons.close,
                          color: Colors.blue.shade600,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ));
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'ابحث عن  حساب...',
                hintStyle: TextStyle(color: Colors.grey.shade800),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
                prefixIcon: IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      _isSearchActive = false;
                      _searchQuery = '';
                    });
                  },
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ],
      ),
    );
  }

  //     تصفية العمليات على البحث
  List<Map<String, dynamic>> _filterTransactions(
      List<Map<String, dynamic>> transactions, String view) {
    if (_searchQuery.isEmpty) {
      return transactions; // إرجاع جميع البيانات إذا كان نص البحث فارغًا
    }

    final query = _searchQuery.toLowerCase();
    return transactions.where((transaction) {
      final name =
          transaction[view == 'customers' ? 'client_name' : 'agent_name']
              ?.toString()
              .toLowerCase();
      return name?.contains(query) ?? false;
    }).toList();
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
        duration: const Duration(seconds: 1),
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

/*
   =======================================
    $$$((دوال مساعده لانشاء الواجهات))$$$
   =======================================
*/

  // دالة   لإنشاء حقول الإدخال
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    VoidCallback? onEditingComplete,
  }) {
    return TextField(
      controller: controller,
      autofocus: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon,
            color: _saveTtansaAccount
                ? Colors.blue.shade400
                : Colors.orange.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: _saveTtansaAccount
                  ? Colors.blue.shade400
                  : Colors.orange.shade400,
              width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: _saveTtansaAccount
                  ? Colors.blue.shade400
                  : Colors.orange.shade400,
              width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      onTap: () {
        // ضبط موضع المؤشر عند النقر على الحقل
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
      },
      style: const TextStyle(fontSize: 15),
    );
  }

  // دالة   لإنشاء مربعات المعلومات
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 22,
              color: _selectedView == 'customers'
                  ? Colors.blue.shade700
                  : Colors.orange.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _selectedView == 'customers'
                        ? Colors.blue.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دالة  لإنشاء أزرار التحكم
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لإنشاء أزرار نوع العملية
  Widget _buildTransactionTypeButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  // دالة لإنشاء مربعات الملخص
  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color valueColor,
    double valueSize = 18,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: valueColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: valueSize,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دالة لإنشاء عناصر خيارات العرض
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

  //  انشا الجدوال
  Widget _buildTable(String view, Color borderColor) {
    final isCustomers = view == 'customers';
    final primaryColor =
        isCustomers ? Colors.blue.shade700 : Colors.orange.shade700;
    final lightColor =
        isCustomers ? Colors.blue.shade100 : Colors.orange.shade100;

    final transactions =
        isCustomers ? _recentCustomerTransactions : _recentAgentTransactions;

    final filteredTransactions = _filterTransactions(transactions, view);

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border:
                  Border.all(color: primaryColor.withOpacity(0.8), width: 2),
            ),
            margin: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0.0),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(
                          isCustomers ? 'اسم العميل' : 'اسم المورد',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'المبلغ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Content
                Expanded(
                  child: filteredTransactions.isEmpty
                      ? Center(
                          child: Text(
                            "لا توجد نتائج",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = filteredTransactions[index];

                            return InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      _buildTransactionDetailsDialog(
                                          transaction),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: index % 2 == 0
                                      ? lightColor.withOpacity(0.3)
                                      : Colors.white,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: primaryColor,
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Icon(
                                        Icons.info_outline_rounded,
                                        color: primaryColor,
                                      ),
                                    ),
                                    // Name Column
                                    Expanded(
                                      flex: 5,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 8),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            left: BorderSide(
                                                color: primaryColor, width: 2),
                                            right: BorderSide(
                                                color: primaryColor, width: 2),
                                          ),
                                        ),
                                        child: Text(
                                          transaction[isCustomers
                                                  ? 'client_name'
                                                  : 'agent_name'] ??
                                              'غير معروف',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          textAlign: TextAlign.start,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),

                                    // Amount Column
                                    Expanded(
                                      flex: 3,

                                      child: Text(
                                        DatabaseHelper().getNumberFormat(
                                            transaction['amount']),
                                        // ??'غير معروف',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'Amiri',
                                          fontWeight: FontWeight.w800,
                                          color: transaction['type'] == 'تسديد'
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                      // ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  //   الواجهه
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.cyan.shade400,
        appBar: _buildAppBar(),
        body: Padding(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            children: [
              // شريط علوي
              _buildToolbar(),

              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 80.0),
                  // w
                  decoration: BoxDecoration(
                    color: const Color(0xFF008091),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.black.withOpacity(0.3), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          '$selectedTypeFull ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (_selectedDate != null)
                          Text(
                            _selectedDate!.toLocal().toString().split(' ')[0],
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  )),

              // ==== الجدول =======

              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                      _selectedView = index == 0 ? 'customers' : 'agents';
                    });
                  },
                  children: [
                    // الجدول الأول - العملاء
                    _buildTable('customers', Colors.blue),
                    // الجدول الثاني - الوكلاء
                    _buildTable('agents', Colors.orange),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniCenterDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddOperationDialog(),
          backgroundColor: const Color(0xFF008091),
          elevation: 8,
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
        bottomNavigationBar: BottomAppBar(
          color: const Color(0xFF008091),
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButtonTow(
                icon: Icons.search_outlined,
                color: Colors.greenAccent,
                onTap: () {
                  setState(() {
                    _searchQuery = '';
                    _isSearchActive = !_isSearchActive; // تفعيل عرض حقل البحث
                  });
                },
              ),

              const SizedBox(width: 48), // مساحة للأيقونة الوسطى
              _buildActionButtonTow(
                icon: Icons.info_outline,
                color:
                    _selectedView == 'customers' ? Colors.blue : Colors.orange,
                onTap: () async {
                  await _showSummaryDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF008091),
// #03A9F4    #00BCD4 #9E9E9E
        borderRadius: BorderRadius.circular(24), // تقليل استدارة الزوايا
        border: Border.all(color: Colors.black.withOpacity(0.3), width: 1),

        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 5),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isSearchActive ? _buildSearchField() : _buildActions(),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
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

        // أيقونة عرض العملاء
        GestureDetector(
          onTap: () {
            _pageController.animateToPage(0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: _currentPage == 0 ? Colors.white : const Color(0xABFFFFFF),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.people,
                  color: _currentPage == 0 ? Colors.blue : Colors.grey,
                  size: 32,
                ),
                Text(
                  'العملاء',
                  style: TextStyle(
                    fontSize: 10.0,
                    color: _currentPage == 0 ? Colors.blue : Colors.grey,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),

        // أيقونة عرض الوكلاء
        GestureDetector(
          onTap: () {
            _pageController.animateToPage(1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: _currentPage == 1 ? Colors.white : const Color(0xABFFFFFF),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.business,
                  color: _currentPage == 1 ? Colors.orange : Colors.grey,
                  size: 32,
                ),
                Text(
                  'الموردين',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: _currentPage == 1 ? Colors.orange : Colors.grey,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonTow({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black.withOpacity(0.6), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, color: color, size: 25),
          onPressed: onTap,
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black.withOpacity(0.6), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'إضافة عملية مالية',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16.0,
            color: Colors.cyan,
          ),
        ),
      ),
      backgroundColor: const Color(0xFF008091),
      elevation: 0,
      leading: _buildActionButtonTow(
        icon: Icons.home,
        color: Colors.greenAccent,
        onTap: () {
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
      actions: [
        _buildActionButtonTow(
          icon: Icons.assignment_ind_outlined,
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddDeletePage(),
              ),
            );
          },
        ),
        _buildActionButtonTow(
          icon: Icons.search_rounded,
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchClientPage(),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

// =======================
}

//  النهاية
