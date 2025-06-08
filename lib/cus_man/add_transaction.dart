// ==============Asmael Asid ====================================

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../database/database_helper.dart';
import 'add_delete.dart';
import 'search.dart';
import '../frontend/front_help.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  AddTransactionPageState createState() => AddTransactionPageState();
}

class AddTransactionPageState extends State<AddTransactionPage> {
  final TextEditingController _nameController = TextEditingController();
  final primaryColorCustomer = Colors.blue.shade600;
  final primaryColorAgen = Colors.teal.shade700;
  final lightColorCustomer = Colors.blue.shade100;
  final lightColoAgenr = Colors.teal.shade100;
  final redTextColor = Colors.redAccent.shade700;
  final greenTextColor = const Color(0xFF00933D);

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _detailsFocusNode = FocusNode();

  final ScrollController _scrollController = ScrollController();

  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0; // الصفحة الحالية

  bool _isSearchActive = false;
  bool _saveTtansaAccount = true;

  String _searchQuery = '';

  int? selectedAgentId; // ID الوكيل المختار
  int? selectedClientId; // ID العميل المختار
  bool _showBars = true;

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
  final iconCustomer = Icons.person;
  final iconAgeen = Icons.business_rounded;
  double _lastDirectionOffset = 0;
  ScrollDirection? _lastDirection;

  //  كلاس قاعدة البيانات
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // =========  تفاعلات الواجهة الواجهه  ===========
  @override
  void initState() {
    super.initState();
    selectedTypeFull = 'اليوم';
    _scrollController.addListener(_handleScroll);

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

    _pageController.addListener(() {
      setState(() {
        _selectedView = _pageController.page! <= 0.5 ? 'customers' : 'agents';

        _currentPage = _pageController.page! <= 0.5 ? 0 : 1;
      });
    });
  }

  void _handleScroll() {
    double threshold = 200;
    final currentDirection = _scrollController.position.userScrollDirection;
    final currentOffset = _scrollController.offset;

    // إذا تغير الاتجاه، سجل نقطة البداية الجديدة
    if (_lastDirection != currentDirection) {
      _lastDirection = currentDirection;
      _lastDirectionOffset = currentOffset;
      return;
    }

    double diff = (currentOffset - _lastDirectionOffset).abs();

    if (currentDirection == ScrollDirection.reverse) {
      if (_showBars && diff > threshold) {
        setState(() {
          _showBars = false;
          _lastDirectionOffset = currentOffset;
        });
      }
    } else if (currentDirection == ScrollDirection.forward) {
      if (!_showBars && diff > threshold) {
        setState(() {
          _showBars = true;
          _lastDirectionOffset = currentOffset;
        });
      }
    }
  }

  void showHandl() {
    setState(() {
      // قيد المراجعة
      if (_showBars == false) {
        _showBars = true;
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
    _scrollController.dispose();

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
                        color: primaryColorCustomer,
                        onPressed: () {
                          _saveTtansaAccount = true;

                          Navigator.pop(context);
                          _showAddCustomerOperationDialog();
                        },
                      ),
                    ),
                    const SizedBox(width: 20.0),
                    Expanded(
                      child: _buildActionButton(
                        label: 'مورد',
                        icon: Icons.person_outline,
                        color: primaryColorAgen,
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
      matchingClients = [];
    });
    final iconFunction = _saveTtansaAccount ? iconCustomer : iconAgeen;

    final primaryColor =
        _saveTtansaAccount ? primaryColorCustomer : primaryColorAgen;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
                textDirection: TextDirection.rtl,
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    iconFunction,
                                    color: Colors.white,
                                    size: 24.0,
                                  ),
                                  Text(
                                    _saveTtansaAccount
                                        ? 'اضافة عملية الى حساب عميل'
                                        : 'اضافة عملية الى حساب مورد',
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                            child: _buildNameFieldWithSuggestions(setState),
                          )
                        ],
                      ),
                    ),
                  ),
                ));
          },
        );
      },
    );
  }

  //    انشاء الحقوال والقائمة المشابهة
  Widget _buildNameFieldWithSuggestions(
      void Function(void Function()) setState) {
    final primaryColor =
        _saveTtansaAccount ? primaryColorCustomer : primaryColorAgen;
    final borderColor =
        _saveTtansaAccount ? primaryColorCustomer : primaryColorAgen;
    final typetransaction = _saveTtansaAccount ? 'إضافة' : 'قرض';
    final typetransactionViw = _saveTtansaAccount ? ' دين ' : 'قرض';
    final iconFunction = _saveTtansaAccount ? iconCustomer : iconAgeen;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10.0),
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: _saveTtansaAccount ? 'اسم العميل' : 'اسم المورد',
                labelStyle: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w600),
                prefixIcon: Icon(iconFunction,
                    color: _saveTtansaAccount
                        ? primaryColorCustomer
                        : primaryColorAgen),
                floatingLabelStyle: TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: _saveTtansaAccount
                          ? primaryColorCustomer
                          : primaryColorAgen,
                      width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: _saveTtansaAccount
                          ? primaryColorCustomer
                          : primaryColorAgen,
                      width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _saveTtansaAccount
                      ? _searchClients(value)
                      : _searchAgents(value);
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال اسم العميل';
                }
                return null;
              },
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20.0),
            _buildInputField(
              controller: _amountController,
              label: 'المبلغ',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20.0),
            _buildInputField(
              controller: _detailsController,
              label: 'تفاصيل العملية',
              icon: Icons.description,
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
            const SizedBox(height: 10.0),
          ],
        ),
        if (matchingClients.isNotEmpty)
          Positioned(
            top: 70,
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
        if (matchingAgents.isNotEmpty)
          Positioned(
            top: 70,
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
                          Divider(
                            color: primaryColorAgen,
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
    // for (var i = 0; i < 10; i++) {
    await DatabaseHelper().insertOperation(
      selectedClientId!,
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
    if (_transactionType.isNotEmpty) {
      double? amount = double.tryParse(_amountController.text.trim());
      String details = _detailsController.text.trim();

      if (selectedAgentId == null || amount == null || amount <= 0) {
        _showErrorMessage('يرجى اختيار وكيل صحيح ومبلغ أكبر من 0');

        return;
      }

      // for (var i = 0; i < 10; i++) {
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
    final primaryColor = isCustomers ? primaryColorCustomer : primaryColorAgen;

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
                insetPadding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.edit, size: 30, color: Colors.white),
                              // SizedBox(height: 8),
                              Text(
                                'تعديل العملية',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
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
    final primaryColor =
        _selectedView == 'customers' ? primaryColorCustomer : primaryColorAgen;

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
    CustomDialog.show(
        context: context,
        headerColor: Colors.cyan,
        icon: Icons.calendar_month,
        title: 'اختر الفترة الزمنية',
        contentChildren: [
          Wrap(
            spacing: 10.0,
            runSpacing: 18.0,
            alignment: WrapAlignment.spaceAround,
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

                    _selectedDate =
                        DateTime.now().subtract(const Duration(days: 1));
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
                  final startOfMonth = DateTime(now.year, now.month, 1);
                  final endOfMonth = DateTime(now.year, now.month + 1, 0);
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
                  final lastMonth = DateTime(now.year, now.month - 1, 1);
                  final startOfMonth =
                      DateTime(lastMonth.year, lastMonth.month, 1);
                  final endOfMonth =
                      DateTime(lastMonth.year, lastMonth.month + 1, 0);
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
          const SizedBox(
            height: 10,
          )
        ]);
  }

  //  نافذة ملخص العمليات
  Future<void> _showSummaryDialog(BuildContext context) async {
    Map<String, double> summary;
    final isCustomers = _selectedView == 'customers';
    final primaryColor = isCustomers ? primaryColorCustomer : primaryColorAgen;

    String typeText = isCustomers ? 'ديون العملاء' : 'القروض';
    String boxText = isCustomers ? 'رصيد صندوق العملاء' : 'رصيد صندوق الموردين';

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
    CustomDialog.show(
        context: context,
        headerColor: primaryColor,
        icon: Icons.calendar_month,
        title: 'ملخص عمليات  $selectedTypeDolomgo',
        infoText: _selectedDate != null
            ? '${_selectedDate!.toLocal().toString().split(' ')[0]}         عدد العمليات :  ${numberOperationsCust.toString()}'
            : '   عدد العمليات :  ${numberOperationsCust.toString()}',
        contentChildren: [
          const SizedBox(height: 8),
          _buildSummaryCard(
            icon: Icons.payment,
            title: 'المدفوعات النقديه',
            value: DatabaseHelper().getNumberFormat(summary['total_payments']!),
            color: Colors.green.shade100,
            valueColor: Colors.green.shade700,
          ),
          const SizedBox(height: 8),
          _buildSummaryCard(
            icon: isCustomers ? Icons.money_off : Icons.money,
            title: typeText,
            value:
                DatabaseHelper().getNumberFormat(summary['total_additions']!),
            color: Colors.red.shade100,
            valueColor: Colors.red.shade700,
          ),
          const SizedBox(height: 8),
          _buildSummaryCard(
            icon: Icons.account_balance_wallet,
            title: boxText,
            value: DatabaseHelper().getNumberFormat(summary['balance']!),
            color: summary['balance']! >= 0
                ? Colors.green.shade100
                : Colors.red.shade100,
            valueColor: summary['balance']! >= 0
                ? Colors.green.shade700
                : Colors.red.shade700,
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            label: 'إغلاق',
            icon: Icons.close,
            color: primaryColor,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 8),
        ]);
  }

  //    نافذة تفاصيل العملية
  void _buildTransactionDetailsDialog(Map<String, dynamic> transaction) {
    final isAconnt = _selectedView == 'customers';

    final primaryColor = isAconnt ? primaryColorCustomer : primaryColorAgen;

    final teypColor =
        transaction['type'] == 'تسديد' ? greenTextColor : redTextColor;
    final teypbakColor = transaction['type'] == 'تسديد'
        ? greenTextColor.withOpacity(0.3)
        : redTextColor.withOpacity(0.2);

    // معالجة التاريخ والوقت
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(transaction['date'] ?? '');
    } catch (e) {
      parsedDate = DateTime.now();
    }

    final formattedDate =
        '${parsedDate.year}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.day.toString().padLeft(2, '0')}';
    final formattedTime =
        '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';

    final iconFunction =
        _selectedView == 'customers' ? iconCustomer : iconAgeen;
    CustomDialog.show(
        context: context,
        headerColor: primaryColor,
        icon: Icons.receipt_long_rounded,
        title: 'تفاصيل العملية',
        contentChildren: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            decoration: BoxDecoration(
              color: isAconnt ? lightColorCustomer : lightColoAgenr,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: primaryColor,
                            border: Border.all(color: primaryColor, width: 1)),
                        child: const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          textBaseline: TextBaseline.alphabetic,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Amiri',
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'زمن العملية',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: primaryColor,
                            border: Border.all(color: primaryColor, width: 1)),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Amiri',
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildSummaryCard(
            icon: iconFunction,
            title: 'الاسم',
            value: transaction[isAconnt ? 'client_name' : 'agent_name'] ??
                'غير معروف',
            color: isAconnt ? lightColorCustomer : lightColoAgenr,
            valueColor: isAconnt ? primaryColorCustomer : primaryColorAgen,
          ),
          const SizedBox(height: 8),
          _buildSummaryCard(
            icon: Icons.description,
            title: 'التفاصيل',
            value: transaction['details'] ?? 'غير معروف',
            color: isAconnt ? lightColorCustomer : lightColoAgenr,
            valueColor: isAconnt ? primaryColorCustomer : primaryColorAgen,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow('نوع العملية', transaction['type'],
              icon: transaction['type'] == 'تسديد'
                  ? Icons.price_check_rounded
                  : Icons.price_change_outlined,
              color: teypColor,
              valueColor: teypbakColor),
          const SizedBox(height: 8),
          _buildSummaryRow('المبلغ',
              DatabaseHelper().getNumberFormat(transaction['amount']!),
              icon: isAconnt
                  ? transaction['type'] == 'تسديد'
                      ? Icons.money_off_csred
                      : Icons.monetization_on_rounded
                  : transaction['type'] == 'تسديد'
                      ? Icons.monetization_on_rounded
                      : Icons.money_rounded,
              color: teypColor,
              valueColor: teypbakColor),
          const SizedBox(height: 8),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        label: '',
                        icon: Icons.edit,
                        color: Colors.green.shade400,
                        onPressed: () {
                          if (!_showBars) {
                            setState(() {
                              _showBars = true;
                            });
                          }
                          _saveTtansaAccount = isAconnt;
                          Navigator.of(context).pop();
                          _editTransaction(transaction);
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildActionButton(
                        label: '',
                        icon: Icons.delete,
                        color: Colors.red.shade600,
                        onPressed: () {
                          if (!_showBars) {
                            setState(() {
                              _showBars = true;
                            });
                          }
                          Navigator.of(context).pop();
                          _deleteTransaction(transaction);
                        },
                      ),
                    ),
                  ])),
          const SizedBox(height: 8),
          _buildActionButton(
            label: 'إغلاق',
            icon: Icons.close,
            color: isAconnt ? primaryColorCustomer : primaryColorAgen,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 8),
        ]);
  }

  //  نجاح العملية
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
        backgroundColor: Colors.greenAccent.shade700,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
        margin: const EdgeInsets.all(16),
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
        elevation: 6,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

/*
   =======================================
    $$$((دوال مساعده لانشاء الواجهات))$$$
   =======================================
*/

  // دالة مساعدة لإنشاء بطاقات الملخص (بنفس نمط الدوال السابقة)
  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: valueColor,
                border: Border.all(color: valueColor, width: 1)),
            child: Icon(
              icon,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة   لإنشاء صفوف الملخص المالي
  Widget _buildSummaryRow(
    String label,
    String value, {
    required IconData icon,
    required Color color,
    required Color valueColor,
    // bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: valueColor,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: color,
                border: Border.all(color: color, width: 1)),
            child: Icon(
              icon,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.black87,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'Amiri',
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لإنشاء حقول الإدخال
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
            color:
                _saveTtansaAccount ? primaryColorCustomer : primaryColorAgen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color:
                  _saveTtansaAccount ? primaryColorCustomer : primaryColorAgen,
              width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color:
                  _saveTtansaAccount ? primaryColorCustomer : primaryColorAgen,
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
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
      },
      style: const TextStyle(fontSize: 15),
    );
  }

  // دالة مساعدة   لإنشاء أزرار التحكم
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

  Widget buildUnifiedTable() {
    final transactions = _recentCustomerTransactions;

    return CustomerTable(
      one: false,
      shcerPage: false,
      customers: transactions,
      searchQuery: _searchQuery,
      scrollController: _scrollController,
      dbHelper: _dbHelper,
      onTap: (customer) {
        _buildTransactionDetailsDialog(customer);
      },
    );
  }

  //  جدول الموردين
  Widget _buildTableAgents() {
    final transactions = _recentAgentTransactions;

    return AgentTable(
      one: false,
      shcerPage: false,
      agents: transactions,
      searchQuery: _searchQuery,
      scrollController: _scrollController,
      dbHelper: _dbHelper,
      onTap: (agent) {
        _buildTransactionDetailsDialog(agent);
      },
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
            appBar: CustomAppBar(
              title: 'إضافة عملية مالية',
              colorTitle: const Color(0xFFFF9800),
              onBackPress: () => Navigator.pop(context),
              onIcon1Press: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddDeletePage(),
                  ),
                );
              },
              icon1Press: Icons.assignment_ind,
              color1Press: primaryColorCustomer,
              onIcon2Press: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchClientPage(),
                  ),
                );
              },
              icon2Press: Icons.search_rounded,
              color2Press: const Color(0xFF07BEAC),
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade600,
                    Colors.green.shade500,
                    Colors.blue.shade500,
                    Colors.green.shade500,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  TabBarBody(
                    height: _showBars ? 55 : 0,
                    showSearchField: _isSearchActive,
                    onBackPress: () {
                      _pageController.animateToPage(0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    },
                    color1Press: _currentPage == 0
                        ? primaryColorCustomer
                        : const Color(0xABFFFFFF),
                    color1PressChildrn:
                        _currentPage == 0 ? Colors.white : Colors.grey,
                    onBack2Press: () {
                      _pageController.animateToPage(1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    },
                    color2Press: _currentPage == 1
                        ? primaryColorAgen
                        : const Color(0xABFFFFFF),
                    color2PressChildrn:
                        _currentPage == 1 ? Colors.white : Colors.grey,
                    color3Press: const Color(0xFFFF9800),
                    onBack3Press: () => _selectDate(context),
                    icon3Press: Icons.date_range_rounded,
                    title: '  تحديد  ',
                    onBackShears: () {
                      setState(() {
                        _isSearchActive = false;
                        _searchQuery = '';
                      });
                    },
                    onSearchChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    searchQuery: _searchQuery,
                  ),
                  Container(
                      decoration: BoxDecoration(
                          color: const Color(0xFF008091),
                          border: BorderDirectional(
                              top: BorderSide(
                                  width: 1, color: Colors.cyan.shade300))),
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
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 4.0,
                                      color: Colors.cyanAccent,
                                    ),
                                  ]),
                            ),
                            if (_selectedDate != null)
                              Text(
                                _selectedDate!
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 4.0,
                                        color: Colors.cyanAccent,
                                      ),
                                    ]),
                              ),
                          ],
                        ),
                      )),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        // print(index);

                        // setState(() {
                        //   _currentPage = index;
                        //   _selectedView = index == 0 ? 'customers' : 'agents';
                        //   //   // _showBars = true;
                        // });

                        showHandl();
                      },
                      children: [
                        // الجدول الأول - العملاء
                        buildUnifiedTable(),
                        _buildTableAgents(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.miniCenterDocked,
            floatingActionButton: AnimatedSwitcher(
                duration: const Duration(milliseconds: 100),
                child: _showBars
                    ? FloatingActionButton(
                        backgroundColor: const Color(0xFFFF9800),
                        onPressed: () => _showAddOperationDialog(),
                        elevation: 4,
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 30),
                      )
                    : null),
            bottomNavigationBar: ActionButtonL(
              showBars: _showBars,
              icon1Press: Icons.search_outlined,
              color1Press: const Color(0xFFFF9800),
              onIcon1Press: () {
                _isSearchActive = !_isSearchActive;

                setState(() {
                  _searchQuery = '';
                });
              },
              icon2Press: Icons.info_outline,
              color2Press: _selectedView == 'customers'
                  ? primaryColorCustomer
                  : primaryColorAgen,
              onIcon2Press: () async {
                await _showSummaryDialog(context);
              },
            )));
  }

// =======================
}

//  النهاية

  // =================================
