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

  final TextEditingController _agentNameController = TextEditingController();
  final FocusNode _agentNameFocusNode = FocusNode();
  int? selectedAgentId; // ID الوكيل المختار
  List<Map<String, dynamic>> matchingAgents = []; // قائمة الوكلاء المطابقين
  String _selectedView = 'customers'; // عرض العمليات الحالية (عملاء أو وكلاء)
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0; // الصفحة الحالية
  String _transactionType = '';
  int? selectedClientId; // ID العميل المختار
  List<Map<String, dynamic>> matchingClients = []; // قائمة الأسماء المطابقة
  DateTime? _selectedDate; // للتاريخ المحدد (اليوم، الأمس، يوم محدد)
  DateTime? _startDate; // لنطاق التاريخ (بداية الفترة)
  DateTime? _endDate; // لنطاق التاريخ (نهاية الفترة)
  List<Map<String, dynamic>> _recentTransactions = [];
  int number_opritor = 0;
// // =========  تفاعلات الواجهة الواجهه  ===========
  @override
  void initState() {
    super.initState();

    _fetchTransactionsByDate(DateTime.now());
    // تحريك المؤشر إلى نهاية النص عند التركيز على الحقل
    //   _nameFocusNode.addListener(() {
    //     if (_nameFocusNode.hasFocus) {
    //       _moveCursorToEnd(_nameController);
    //     }
    //   });

    //   _amountFocusNode.addListener(() {
    //     if (_amountFocusNode.hasFocus) {
    //       _moveCursorToEnd(_amountController);
    //     }
    //   });

    //   _detailsFocusNode.addListener(() {
    //     if (_detailsFocusNode.hasFocus) {
    //       _moveCursorToEnd(_detailsController);
    //     }
    //   });
  }

// =========  نقل المواشر الى اخر حرف ===========
  // @override
  // void dispose() {
  // التخلص من الـControllers والـFocusNodes
  // _nameController.dispose();
  // _amountController.dispose();
  // _detailsController.dispose();
  // _nameFocusNode.dispose();
  // _amountFocusNode.dispose();
  // _detailsFocusNode.dispose();
  // استدعاء super.dispose() في النهاية
  // super.dispose();
  // }

// ========= استرجاع الاسماء للعملاء===========
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

// ========= استرجاع الاسماء للوكلاء===========
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

// ==================بداية===================
// ============ تصفيت العرض =================
// ============================================
  // جلب العمليات  للعملاء بناءً على التاريخ المحدد
  Future<void> _fetchTransactionsByDate(DateTime date) async {
    final transactions = await DatabaseHelper().getOperationsByDate(date);
    setState(() {
      _recentTransactions = transactions;
      _selectedDate = date;
    });
  }

//  عرض خيارات العرض
  Future<void> _selectDate(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'اختر الفترة الزمنية',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('يوم محدد'),
                onTap: () async {
                  Navigator.pop(context);
                  await _selectDateViwe(context);
                },
              ),
              ListTile(
                title: const Text('كل العمليات'),
                onTap: () async {
                  Navigator.pop(context);
                  setState(() {
                    _selectedDate = null;
                    _startDate = null;
                    _endDate = null;
                  });
                  await _fetchAllTransactions();
                },
              ),
              ListTile(
                title: const Text('اليوم'),
                onTap: () async {
                  Navigator.pop(context);
                  setState(() {
                    _selectedDate = DateTime.now();
                    _startDate = null;
                    _endDate = null;
                  });
                  await _fetchTransactionsByDate(DateTime.now());
                },
              ),
              ListTile(
                title: const Text('الأمس'),
                onTap: () async {
                  Navigator.pop(context);
                  setState(() {
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
              ListTile(
                title: const Text('الأسبوع الحالي'),
                onTap: () async {
                  Navigator.pop(context);
                  final now = DateTime.now();
                  final startOfWeek =
                      now.subtract(Duration(days: now.weekday - 1));
                  setState(() {
                    _selectedDate = null;
                    // _startDate = startOfWeek;
                    _startDate = now.subtract(Duration(days: now.weekday));
                    _endDate = now;
                  });
                  await _fetchTransactionsByWeek();
                },
              ),
              ListTile(
                title: const Text('الشهر الحالي'),
                onTap: () async {
                  Navigator.pop(context);
                  final now = DateTime.now();
                  final startOfMonth = DateTime(now.year, now.month, 1);
                  final endOfMonth = DateTime(now.year, now.month + 1, 0);
                  setState(() {
                    _selectedDate = null;
                    _startDate = startOfMonth;
                    _endDate = endOfMonth;
                  });
                  await _fetchTransactionsByMonth(now);
                },
              ),
              ListTile(
                title: const Text('الشهر الماضي'),
                onTap: () async {
                  Navigator.pop(context);
                  final now = DateTime.now();
                  final lastMonth = DateTime(now.year, now.month - 1, 1);
                  final startOfMonth =
                      DateTime(lastMonth.year, lastMonth.month, 1);
                  final endOfMonth =
                      DateTime(lastMonth.year, lastMonth.month + 1, 0);
                  setState(() {
                    _selectedDate = null;
                    _startDate = startOfMonth;
                    _endDate = endOfMonth;
                  });
                  await _fetchTransactionsByMonth(lastMonth);
                },
              ),
            ],
          ),
        );
      },
    );
  }

//  فتح جدول اختيار التاريخ للعملاء
  Future<void> _selectDateViwe(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      await _fetchTransactionsByDate(picked);
    }
  }

// جلب العمليات للأسبوع الحالي
  Future<void> _fetchTransactionsByWeek() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday));
    final transactions = await DatabaseHelper().getOperationsByDateRange(
      startOfWeek,
      now,
    );
    setState(() {
      _recentTransactions = transactions;
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
    setState(() {
      _recentTransactions = transactions;
      _selectedDate = null; // لا يوجد تاريخ محدد
    });
  }

  // جلب كل العمليات
  Future<void> _fetchAllTransactions() async {
    final transactions = await DatabaseHelper().getAllOperations();
    setState(() {
      _recentTransactions = transactions;
      _selectedDate = null; // لا يوجد تاريخ محدد
    });
  }

// جلب العمليات للوكلاء بناءً على التاريخ المحدد
  Future<void> _fetchAgentTransactionsByDate(DateTime date) async {
    final transactions = await DatabaseHelper().getAgentOperationsByDate(date);
    setState(() {
      _recentTransactions = transactions;
      _selectedDate = date;
    });
  }

  Future<void> _selectAgentDateViw(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      await _fetchAgentTransactionsByDate(picked);
    }
  }

// فتح جدول اختيار التاريخ للوكلاء
  Future<void> _selectAgentDate(BuildContext context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'اختر الفترة الزمنية',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                title: const Text('يوم محدد'),
                onTap: () async {
                  Navigator.pop(context);
                  await _selectAgentDateViw(context);
                },
              ),
              ListTile(
                title: const Text('كل العمليات'),
                onTap: () async {
                  Navigator.pop(context);
                  setState(() {
                    _selectedDate = null;
                    _startDate = null;
                    _endDate = null;
                  });
                  await _fetchAllAgentTransactions();
                },
              ),
            ]),
          );
        });
  }

//  ========= نافذة اختيار  الاضافة لعميل او لوكيل  ===========
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
                    fontSize: 18.0,
                    fontWeight: FontWeight.w800,
                    color: Colors.cyan,
                  ),
                ),
                const SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // إغلاق النافذة الحالية
                        _showAddCustomerOperationDialog(); // فتح نافذة إضافة عملية لعميل
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('عميل'),
                    ),
                    const Text(
                      'او',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.cyan,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // إغلاق النافذة الحالية
                        // فتح نافذة إضافة عملية لوكيل
                        _showAddAgentOperationDialog(); // فتح نافذة إضافة عملية لوكيل
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('وكيل'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // جلب كل العمليات
  Future<void> _fetchAllAgentTransactions() async {
    final transactions = await DatabaseHelper().getAgentAllOperations();
    setState(() {
      _recentTransactions = transactions;
      _selectedDate = null; // لا يوجد تاريخ محدد
    });
  }

// ===============   نافذة اضافة عملية لعميل ==================
  void _showAddCustomerOperationDialog() {
    setState(() {
      matchingClients = []; // إعادة تعيين القائمة المقترحة
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                backgroundColor: const Color(0xFFF5F5F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // العنوان
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12.0),
                            topRight: Radius.circular(12.0),
                          ),
                        ),
                        child: const Text(
                          'اضافة عملية الى حساب عميل',
                          style: TextStyle(
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

// ===============  انشاء الحقوال والقائمة المشابهة للعملاء==================
  Widget _buildNameFieldWithSuggestions(
      void Function(void Function()) setState) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // حقل الاسم
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.blue, width: 2.0),
                    bottom: BorderSide(color: Colors.blue, width: 2.0),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'الاسم :   ',
                          style: TextStyle(
                              fontSize: 18.0, fontWeight: FontWeight.w800),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.blue, width: 2.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.blue, width: 2.0),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchClients(value); // تحديث القائمة المقترحة
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال الاسم';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),

                    // حقل المبلغ
                    Row(
                      children: [
                        const Text(
                          'المبلغ :    ',
                          style: TextStyle(
                              fontSize: 18.0, fontWeight: FontWeight.w800),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            focusNode: _amountFocusNode,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.blue, width: 2.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.blue, width: 2.0),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),

                    // حقل التفاصيل
                    Row(
                      children: [
                        const Text(
                          'تفاصيل : ',
                          style: TextStyle(
                              fontSize: 18.0, fontWeight: FontWeight.w800),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _detailsController,
                            focusNode: _detailsFocusNode,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              // إزالة التركيز عند الانتهاء
                              FocusScope.of(context).unfocus();
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.blue, width: 2.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.blue, width: 2.0),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),
                  ],
                ),
              ),
              const SizedBox(height: 10.0),

              // اختيار نوع العملية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // خيار "اظافة"
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _transactionType = 'إضافة';
                        _amountFocusNode.unfocus();
                        _detailsFocusNode.unfocus();
                      });
                      _saveTransactionToDatabase();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: _transactionType == 'إضافة'
                            ? Colors.red
                            : Colors.white,
                        border: Border.all(
                          color: const Color(0xFFFF665B),
                          width: 2.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'إضافة',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w800,
                            color: _transactionType == 'إضافة'
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _transactionType = 'تسديد';
                        _amountFocusNode.unfocus();
                        _detailsFocusNode.unfocus();
                      });
                      _saveTransactionToDatabase();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: _transactionType == 'تسديد'
                            ? Colors.green
                            : Colors.white,
                        border: Border.all(
                          color: const Color(0xFF70FF75),
                          width: 2.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'تسديد',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w800,
                            color: _transactionType == 'تسديد'
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
            ],
          ),
        ),
        // قائمة الأسماء المقترحة
        if (matchingClients.isNotEmpty)
          Positioned(
            top: 60.0, // تحديد موقع القائمة بالنسبة لحقل الإدخال
            left: 10,
            right: 70,
            child: Container(
              constraints: const BoxConstraints(
                  maxHeight: 140), // الحد الأقصى لارتفاع القائمة
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border.all(color: Colors.blue, width: 3.0), // تحديد الحواف
                borderRadius: BorderRadius.circular(8.0), // زوايا مستديرة
              ),
              child: ListView.builder(
                itemCount: matchingClients.length,
                itemBuilder: (context, index) {
                  final client = matchingClients[index];
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 0.0,
                        ),
                        title: Text(
                          client['name'], // عرض اسم العميل
                          textAlign: TextAlign.right, // محاذاة النص إلى اليمين
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _nameController.text =
                                client['name']; // تحديث حقل النص
                            selectedClientId = client['id']; // تخزين ID العميل
                            matchingClients = []; // إخفاء القائمة بعد الاختيار
                          });
                        },
                      ),
                      // إضافة فاصل بين العناصر
                      if (index < matchingClients.length - 1)
                        const Divider(
                          color: Colors.blue,
                          height: 0.0,
                          thickness: 1.7,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

// ===============   نافذة اضافة عملية لوكيل ==================
  void _showAddAgentOperationDialog() {
    setState(() {
      matchingAgents = []; // إعادة تعيين قائمة الاقتراحات
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                backgroundColor: const Color(0xFFF6F6F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // عنوان النافذة
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12.0),
                            topRight: Radius.circular(12.0),
                          ),
                        ),
                        child: const Text(
                          'إضافة عملية الى حساب وكيل',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // حقل البحث عن اسم الوكيل
                      _buildAgentNameFieldWithSuggestions(setState),

                      const SizedBox(height: 10.0),
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

// ===============  انشاء الحقوال والقائمة المشابهة لوكيل==================
  Widget _buildAgentNameFieldWithSuggestions(
      void Function(void Function()) setState) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.orange, width: 2.0),
                      bottom: BorderSide(color: Colors.orange, width: 2.0),
                    ),
                  ),
                  child: Column(
                    children: [
                      // حقل الاسم
                      Row(
                        children: [
                          const Text(
                            'الاسم :    ',
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.w800),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _agentNameController,
                              focusNode: _agentNameFocusNode,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.orange, width: 2.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.orange, width: 2.0),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchAgents(
                                      value); // تحديث القائمة المقترحة
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10.0),

                      // حقل المبلغ
                      Row(
                        children: [
                          const Text(
                            'المبلغ :    ',
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.w800),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              focusNode: _amountFocusNode,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.orange, width: 2.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.orange, width: 2.0),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10.0),

                      // حقل التفاصيل
                      Row(
                        children: [
                          const Text(
                            'تفاصيل : ',
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.w800),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _detailsController,
                              focusNode: _detailsFocusNode,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.orange, width: 2.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.orange, width: 2.0),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10.0),
                    ],
                  )),
              const SizedBox(height: 10.0),

              // اختيار نوع العملية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _transactionType = 'قرض'; // اختيار نوع العملية قرض
                        _amountFocusNode.unfocus();
                        _detailsFocusNode.unfocus();
                      });
                      _saveAgentOperation();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: _transactionType == 'قرض'
                            ? Colors.red
                            : Colors.white,
                        border: Border.all(
                          color: Colors.red,
                          width: 2.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'قرض',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w800,
                            color: _transactionType == 'قرض'
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _transactionType = 'تسديد'; // اختيار نوع العملية تسديد
                        _amountFocusNode.unfocus();
                        _detailsFocusNode.unfocus();
                      });
                      _saveAgentOperation();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: _transactionType == 'تسديد'
                            ? Colors.green
                            : Colors.white,
                        border: Border.all(
                          color: Colors.green,
                          width: 2.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'تسديد',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w800,
                            color: _transactionType == 'تسديد'
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
            ],
          ),
        ),

        // قائمة الوكلاء المطابقة
        if (matchingAgents.isNotEmpty)
          Positioned(
            top: 60.0,
            left: 10,
            right: 55.0,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 140),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.orange, width: 2.0),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListView.builder(
                itemCount: matchingAgents.length,
                itemBuilder: (context, index) {
                  final agent = matchingAgents[index];
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        title: Text(
                          agent['name'],
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _agentNameController.text = agent['name'];
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
      ],
    );
  }

// ================  حفظ العملية للعملاء===============
  Future<void> _saveTransactionToDatabase() async {
    double? amount = double.tryParse(_amountController.text.trim());
    String details = _detailsController.text.trim();

    if (selectedClientId == null || amount == null || amount <= 0) {
      _showErrorMessage('يرجى اختيار عميل صحيح ومبلغ أكبر من 0');

      return;
    }

    await DatabaseHelper().insertOperation(
      selectedClientId!, // إرسال ID العميل
      amount,
      details,
      _transactionType,
    );

    await fetchTransactions();

    _pageController.animateToPage(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

// ================  حفظ العملية للوكلاء===============
  void _saveAgentOperation() async {
    if (_transactionType.isNotEmpty) {
      double? amount = double.tryParse(_amountController.text.trim());
      String details = _detailsController.text.trim();

      if (selectedAgentId == null || amount == null || amount <= 0) {
        _showErrorMessage('يرجى اختيار وكيل صحيح ومبلغ أكبر من 0');

        return;
      }

      await DatabaseHelper().insertAgentOperation(
        selectedAgentId!,
        amount,
        details,
        _transactionType,
      );

      _showSuccessMessage('تم حفظ العملية بنجاح');

      // التحقق من أن الـ BuildContext لا يزال صالحًا
      if (!mounted) return;
      Navigator.pop(context);

      await _fetchAgentTransactionsByDate(DateTime.now()); // جلب عمليات الوكلاء

      _pageController.animateToPage(1,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _showErrorMessage('يرجى اختيار نوع العملية');
    }
  }

// ==================بداية===================
// ============ دوال مشتركه  ================
// ===========================================

//  ========= تحديث الواجهه ===========
  Future<void> fetchTransactions() async {
    if (_selectedDate != null) {
      // إذا كانت هناك تاريخ محدد (_selectedDate)
      await _fetchTransactionsByDate(_selectedDate!);
    } else if (_startDate != null && _endDate != null) {
      // إذا كان هناك نطاق زمني محدد (_startDate و _endDate)
      final transactions = await DatabaseHelper().getOperationsByDateRange(
        _startDate!,
        _endDate!,
      );
      setState(() {
        _recentTransactions = transactions;
        _selectedDate = null; // إعادة تعيين التاريخ المحدد
      });
    } else {
      // إذا لم يتم تحديد أي تاريخ أو نطاق زمني
      await _fetchAllTransactions();
    }
  }

//  =========  انشاء عمود معلومات ===========
  Widget _buildInfoCell(Map<String, dynamic> transaction) {
    Color iconColor =
        (transaction['type'] == 'قرض' || transaction['type'] == 'إضافة')
            ? const Color(0xFFFF4134) // أحمر
            : const Color(0xFF66EE6B); // أخضر

    return IconButton(
      icon: Icon(
        Icons.info_sharp,
        color: iconColor,
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => _buildTransactionDetailsDialog(transaction),
        );
      },
    );
  }

//  ========= نافذة عرض تفاصيل العملية ===========
  Widget _buildTransactionDetailsDialog(Map<String, dynamic> transaction) {
    // التحقق من صحة التاريخ قبل التحليل
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(transaction['date'] ?? '');
    } catch (e) {
      parsedDate = DateTime.now(); // تعيين التاريخ الحالي إذا كان هناك خطأ
    }

    // استخراج التاريخ بصيغة يوم/شهر/سنة
    final String formattedDate =
        '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';

    // استخراج الوقت بصيغة ساعات ودقائق
    final String formattedTime =
        '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // العنوان
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              decoration: BoxDecoration(
                color:
                    _selectedView == 'customers' ? Colors.blue : Colors.orange,
                borderRadius: const BorderRadius.only(
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

            // جدول التفاصيل
            Container(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                      color: _selectedView == 'customers'
                          ? Colors.blue
                          : Colors.orange,
                      width: 3.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.5),
                    1: FlexColumnWidth(7.5),
                  },
                  border: TableBorder.all(
                    color: _selectedView == 'customers'
                        ? Colors.blue
                        : Colors.orange,
                    width: 2.5,
                  ),
                  children: [
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'الاسم',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            transaction[_selectedView == 'customers'
                                    ? 'client_name'
                                    : 'agent_name'] ??
                                'غير معروف',
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    _buildInfoRow(
                      transaction['amount']?.toString() ?? 'غير معروف',
                      'المبلغ',
                    ),
                    _buildInfoRow(
                      transaction['details'] ?? 'غير معروف',
                      'تفاصيل',
                    ),
                    _buildInfoRow(
                      transaction['type'] ?? 'غير معروف',
                      'النوع',
                    ),
                    _buildInfoRow(formattedDate, 'التاريخ'),
                    _buildInfoRow(formattedTime, 'الوقت'),
                  ],
                ),
              ),
            ),

            // الأزرار (حذف وتعديل)

            Container(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              decoration: BoxDecoration(
                  color: const Color(0xFFE1E1E1),
                  border: Border(
                    top: BorderSide(
                      width: 3,
                      color: _selectedView == 'customers'
                          ? Colors.blue
                          : Colors.orange,
                    ),
                    bottom: BorderSide(
                      width: 3,
                      color: _selectedView == 'customers'
                          ? Colors.blue
                          : Colors.orange,
                    ),
                  )),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // زر الحذف
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _deleteTransaction(transaction);
                    },
                    child: Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: Colors.white, // لون الخلفية
                        shape: BoxShape.circle, // شكل دائري
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8.0,
                            spreadRadius: 2.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.redAccent,
                        size: 30.0,
                      ),
                    ),
                  ),
                  // زر التعديل
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _editTransaction(transaction);
                    },
                    child: Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: Colors.white, // لون الخلفية
                        shape: BoxShape.circle, // شكل دائري
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8.0,
                            spreadRadius: 2.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.edit,
                        color: Colors.orangeAccent[400],
                        size: 30.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
  }

//  ========= انشاء صفوف لتفاصيل العملية ===========
  TableRow _buildInfoRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

// ========= حذف عملية ===========
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
        // تحديث العمليات بناءً على نوع العرض الحالي
        if (_selectedView == 'customers') {
          // _refreshTransactions(_selectedDate!); // تحديث عمليات العملاء
          await fetchTransactions();
        } else if (_selectedView == 'agents') {
          await _fetchAgentTransactionsByDate(
              _selectedDate!); // تحديث عمليات الوكلاء
        }
        _showSuccessMessage('تم حذف العملية بنجاح');
      } else {
        _showErrorMessage('فشل في حذف العملية');
      }
    } catch (error) {
      _showErrorMessage('حدث خطأ أثناء حذف العملية');
    }
  }

//  =========  تعديل عملية ===========
  Future<void> _editTransaction(Map<String, dynamic> transaction) async {
    // التحقق من وجود المفاتيح المتوقعة
    if (!transaction.containsKey('amount') ||
        !transaction.containsKey('details') ||
        !transaction.containsKey('type')) {
      return;
    }

    // التحقق من أن القيم غير null
    if (transaction['amount'] == null ||
        transaction['details'] == null ||
        transaction['type'] == null) {
      return;
    }

    // إنشاء controllers وتعيين القيم
    final TextEditingController amountController =
        TextEditingController(text: transaction['amount'].toString());
    final TextEditingController detailsController =
        TextEditingController(text: transaction['details']);
    String selectedType = transaction['type']; // النوع الحالي
    String teypTrens = _selectedView == 'customers' ? 'إضافة' : 'قرض';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 10, // إضافة ظل للنافذة
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // العنوان
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        decoration: BoxDecoration(
                          color: _selectedView == 'customers'
                              ? Colors.blue
                              : Colors.orange,
                          borderRadius: const BorderRadius.only(
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

                      // مربع بحواف زرقاء
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(
                                color: _selectedView == 'customers'
                                    ? Colors.blue
                                    : Colors.orange,
                                width: 2.0),
                            bottom: BorderSide(
                                color: _selectedView == 'customers'
                                    ? Colors.blue
                                    : Colors.orange,
                                width: 2.0),
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 10.0),

                            // حقل تعديل المبلغ
                            TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'المبلغ',
                                labelStyle: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _selectedView == 'customers'
                                        ? Colors.blue
                                        : Colors.orange,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: _selectedView == 'customers'
                                          ? Colors.blue
                                          : Colors.orange,
                                      width: 2),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: _selectedView == 'customers'
                                          ? Colors.blue
                                          : Colors.orange,
                                      width: 2),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 20.0),

                            // حقل تعديل التفاصيل
                            TextField(
                              controller: detailsController,
                              decoration: InputDecoration(
                                labelText: 'التفاصيل',
                                labelStyle: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _selectedView == 'customers'
                                        ? Colors.blue
                                        : Colors.orange,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: _selectedView == 'customers'
                                          ? Colors.blue
                                          : Colors.orange,
                                      width: 2),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: _selectedView == 'customers'
                                          ? Colors.blue
                                          : Colors.orange,
                                      width: 2),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 10.0),
                          ],
                        ),
                      ),

                      // اختيار نوع العملية
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: const BoxDecoration(
                          color: Color(0xFFECE8E8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // الخيار الأول
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedType = teypTrens;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(20.0, 10.0,
                                    20.0, 10.0), // تعديل الحشوة لتناسب النص فقط
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFF665B),
                                    width: 2.0,
                                  ),
                                  color: selectedType == teypTrens
                                      ? Colors.red
                                      : Colors.white, // تغيير لون الخلفية
                                ),
                                child: Text(
                                  teypTrens,
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w800,
                                    color: selectedType == teypTrens
                                        ? Colors.white
                                        : Colors.black, // تغيير لون النص
                                  ),
                                ),
                              ),
                            ),

                            // الخيار الثاني
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedType = 'تسديد';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(20.0, 10.0,
                                    20.0, 10.0), // تعديل الحشوة لتناسب النص فقط
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF70FF75),
                                    width: 2.0,
                                  ),
                                  color: selectedType == 'تسديد'
                                      ? Colors.green
                                      : Colors.white, // تغيير لون الخلفية
                                ),
                                child: Text(
                                  'تسديد',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w800,
                                    color: selectedType == 'تسديد'
                                        ? Colors.white
                                        : Colors.black, // تغيير لون النص
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // أزرار الحفظ والإلغاء
                      Container(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(
                              width: 2,
                              color: _selectedView == 'customers'
                                  ? Colors.blue
                                  : Colors.orange,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'إلغاء',
                                style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                if (amountController.text.isEmpty ||
                                    detailsController.text.isEmpty) {
                                  _showErrorMessage('يرجى تعبئة جميع الحقول');
                                  return;
                                }

                                try {
                                  final databaseHelper = DatabaseHelper();

                                  int rowsAffected = 0;

                                  if (_selectedView == 'customers') {
                                    rowsAffected =
                                        await databaseHelper.updateOperation(
                                      transaction['operation_id'],
                                      double.parse(amountController.text),
                                      detailsController.text,
                                      selectedType,
                                    );
                                  } else if (_selectedView == 'agents') {
                                    rowsAffected = await databaseHelper
                                        .updateAgentOperation(
                                      transaction['operation_id'],
                                      double.parse(amountController.text),
                                      detailsController.text,
                                      selectedType,
                                    );
                                  }

                                  if (rowsAffected > 0) {
                                    // التحقق من أن الـ BuildContext لا يزال صالحًا
                                    if (!mounted) return;
                                    Navigator.of(context).pop();
                                    if (_selectedView == 'customers') {
                                      await fetchTransactions();
                                    } else if (_selectedView == 'agents') {
                                      await _fetchAgentTransactionsByDate(
                                          _selectedDate!);
                                    }

                                    _showSuccessMessage(
                                        'تم تعديل العملية بنجاح');
                                  } else {
                                    _showErrorMessage('فشل في تعديل العملية');
                                  }
                                } catch (error) {
                                  _showErrorMessage(
                                      'حدث خطأ أثناء تعديل العملية');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedView == 'customers'
                                    ? Colors.blue
                                    : Colors.orange,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'حفظ',
                                style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10.0),
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

  // دالة لإنشاء الجدول
  Widget _buildTable(String view, Color borderColor) {
    int number_opritorHlp = 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 0.0),
      decoration: BoxDecoration(
        border: Border.all(
          width: 3.0,
          color: borderColor,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          // العنوان
          Container(
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    view == 'customers' ? 'اسم العميل' : 'اسم المورد',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
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
                const Expanded(
                  flex: 2,
                  child: Text(
                    'تفاصيل',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // المحتوى

          Expanded(
            child: _recentTransactions.isEmpty
                ? const Center(
                    child: Text(
                      "لا توجد عمليات للتاريخ المحدد",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _recentTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _recentTransactions[index];
                      if (_selectedView == 'customers') {
                        number_opritorHlp += 1;
                      }
                      number_opritor = number_opritorHlp;
                      return Container(
                        decoration: BoxDecoration(
                          color:
                              index % 2 == 0 ? Colors.grey[100] : Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: borderColor,
                              width: 2.0,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // عمود الاسم
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                  horizontal: 4,
                                ),
                                child: Text(
                                  transaction[view == 'customers'
                                          ? 'client_name'
                                          : 'agent_name'] ??
                                      'غير معروف',
                                  textAlign: TextAlign.start,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            // عمود المبلغ
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: borderColor,
                                      width: 2.0,
                                    ),
                                    right: BorderSide(
                                      color: borderColor,
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    transaction['amount']?.toString() ??
                                        'غير معروف',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // عمود معلومات
                            Expanded(
                              flex: 2,
                              child: _buildInfoCell(transaction),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

// داله لعرض نافذة ملخص العمليات
  Future<void> _showSummaryDialog(BuildContext context) async {
    Map<String, double> summary;
    String teypTrens = _selectedView == 'customers' ? 'الديون' : 'سحب اجل';
    String boxTrens =
        _selectedView == 'customers' ? 'صندوق العملاء' : 'صندوق الموردين';

    if (_selectedView == 'agents') {
      _selectedDate != null;
      summary = await DatabaseHelper().getAgentSummaryByDate(_selectedDate!);
    } else {
      // إذا كان هناك تاريخ محدد (يوم محدد، اليوم، الأمس)
      if (_selectedDate != null) {
        summary = await DatabaseHelper().getSummaryByDateDey(_selectedDate!);
      }
      // إذا كان هناك نطاق تاريخ (الأسبوع الحالي، الشهر الحالي، الشهر الماضي)
      else if (_startDate != null && _endDate != null) {
        summary = await DatabaseHelper()
            .getSummaryByDateRange(_startDate!, _endDate!);
      }
      // إذا تم اختيار "كل العمليات"
      else {
        summary = await DatabaseHelper().getSummaryForAllOperations();
      }
    }

    // التحقق من أن الـ BuildContext لا يزال صالحًا
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFEEEBEB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: _selectedView == 'customers'
                      ? Colors.blue
                      : Colors.orange,
                  borderRadius: const BorderRadius.only(
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
              if (_selectedDate != null)
                Container(
                  alignment: AlignmentDirectional.center,
                  transformAlignment: AlignmentDirectional.center,
                  padding: const EdgeInsets.all(6.0),
                  width: 120.0,
                  child: Center(
                    child: Text(
                      _selectedDate!.toLocal().toString().split(' ')[0],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10.0),
              // number_opritorHlp
              Text(
                number_opritor.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(5.0), // الكلمات التعريفية 20%
                    1: FlexColumnWidth(5.0), // البيانات 80%
                  },
                  border: TableBorder.all(
                    color: _selectedView == 'customers'
                        ? Colors.blue
                        : Colors.orange,
                    width: 3,
                  ),
                  children: [
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Text(
                            'التسديدات',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            summary['total_payments'].toString(),
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.green,
                                fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            teypTrens,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            summary['total_additions'].toString(),
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.red,
                                fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            boxTrens,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            summary['balance'].toString(),
                            style: TextStyle(
                              color: summary['balance']! >= 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // إغلاق النافذة
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedView == 'customers'
                      ? Colors.blue
                      : Colors.orange, // لون الزر
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                ),
                child: const Text("إغلاق"),
              ),
            ],
          ),
        );
      },
    );
  }

// =============== الواجهه ==================
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text(
            'إضافة عملية مالية',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20.0,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF00ACC1),
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
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
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
                icon: const Icon(Icons.assignment_ind_outlined,
                    color: Colors.blue, size: 25),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddDeletePage(),
                    ),
                  );
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
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
                icon: const Icon(Icons.search_rounded,
                    color: Colors.green, size: 25),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchClientPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E6E6),
                  border: const Border(
                    bottom: BorderSide(
                      color: Color(0xFF0BD4EE),
                      width: 1.6,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_selectedDate != null)
                      Container(
                        width: 100.0,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _selectedDate!.toLocal().toString().split(' ')[0],
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF282828),
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),

                    if (_startDate != null)
                      Container(
                        width: 100.0,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Text(
                            ' ${_startDate!.toLocal().toString().split(' ')[0]}\n  ${_endDate!.toLocal().toString().split(' ')[0]}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF282828),
                                fontWeight: FontWeight.w900),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    if (_selectedDate == null && _startDate == null)
                      Container(
                        width: 100.0,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'كل العمليات',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2ED500),
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),

                    GestureDetector(
                      onTap: () => _currentPage == 0
                          ? _selectDate(
                              context) // اختيار التاريخ لعمليات العملاء
                          : _selectAgentDate(context),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
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
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: _currentPage == 0
                              ? Colors.white
                              : const Color(0xABFFFFFF),
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
                              color:
                                  _currentPage == 0 ? Colors.blue : Colors.grey,
                              size: 32,
                            ),
                            Text(
                              'العملاء',
                              style: TextStyle(
                                fontSize: 10.0,
                                color: _currentPage == 0
                                    ? Colors.blue
                                    : Colors.grey,
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
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: _currentPage == 1
                              ? Colors.white
                              : const Color(0xABFFFFFF),
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
                              color: _currentPage == 1
                                  ? Colors.orange
                                  : Colors.grey,
                              size: 32,
                            ),
                            Text(
                              'الوكلاء',
                              style: TextStyle(
                                fontSize: 10.0,
                                color: _currentPage == 1
                                    ? Colors.orange
                                    : Colors.grey,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // ==== الجدول ==================
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                      _selectedView = index == 0 ? 'customers' : 'agents';
                    });
                    // تحديث البيانات بناءً على الصفحة الحالية
                    if (_currentPage == 0) {
                      fetchTransactions();
                    } else {
                      _startDate = null;
                      _endDate = null;
                      _fetchAgentTransactionsByDate(DateTime.now());
                    }
                  },
                  children: [
                    // الجدول الأول - العملاء
                    _buildTable('customers', Colors.blue),
                    // الجدول الثاني - الوكلاء
                    _buildTable('agents', Colors.orange),
                  ],
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
                      onTap: () {},
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
                      onTap: _showAddOperationDialog,
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

                    GestureDetector(
                      onTap: () async {
                        await _showSummaryDialog(context);
                        // استدعاء الدالة بشكل صحيح
                      },
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
                        child: Icon(
                          Icons.info_outline,
                          color:
                              _currentPage == 0 ? Colors.blue : Colors.orange,
                          size: 25,
                        ),
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
  }

// ===================================
// ===================================
}

// ===================================
