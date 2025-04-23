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
  DateTime? _selectedDate; // للتاريخ المحدد (اليوم، الأمس، يوم محدد)
  DateTime? _startDate; // لنطاق التاريخ (بداية الفترة)
  DateTime? _endDate; // لنطاق التاريخ (نهاية الفترة)
  List<Map<String, dynamic>> _recentCustomerTransactions = [];
  List<Map<String, dynamic>> _recentAgentTransactions = [];

  // // =========  تفاعلات الواجهة الواجهه  ===========
  @override
  void initState() {
    super.initState();
    selectedTypeFull = 'اليوم';

    _fetchTransactionsByDate(DateTime.now());
    // _fetchAgentTransactionsByDate(DateTime.now());
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

// ============ اضافة عمليه  ================
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

// ===============   نافذة اضافة عملية  ==================
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

// ===============  انشاء الحقوال والقائمة المشابهة ==================
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
                // onEditingComplete: () => FocusScope.of(context).unfocus(),
              ),
              /*    // حقل المبلغ
              TextFormField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'المبلغ',
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
              ),
              */
              const SizedBox(height: 14),

              _buildInputField(
                controller: _detailsController,
                label: 'تفاصيل العملية',
                icon: Icons.description,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                textInputAction: TextInputAction.done,
              ),
              // حقل التفاصيل
              /*  TextFormField(
                controller: _detailsController,
                focusNode: _detailsFocusNode,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  labelText: 'تفاصيل العملية',
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
              ),
               */
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
                              horizontal: 16, vertical: 0),
                          title: Text(
                            client['name'],
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 16,
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

// دالة مساعدة لإنشاء حقول الإدخال بنفس النمط
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

// ================  حفظ العملية للعملاء===============
  void _saveTransactionToDatabase() async {
    double? amount = double.tryParse(_amountController.text.trim());
    String details = _detailsController.text.trim();
    // String type = 'كسب';
    // String detailsNum = '🙎‍♂️ ${_nameController.text}';

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

    // if (_transactionType == 'تسديد') {
    //   final dbHelper = DatabaseHelper();
    //   await dbHelper.insertDailyTransaction(amount, detailsNum, type);
    // }
    // await _fetchTransactionsByDate(_selectedDate!);

    _nameController.clear();
    _amountController.clear();
    _detailsController.clear();
    _transactionType = '';
    // تحديث البيانات بناءً على الصفحة الحالية
    if (_currentPage == 0) {
      await fetchTransactions();
    } else if (_currentPage == 1) {
      _pageController.animateToPage(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }

    _showSuccessMessage('تم حفظ العملية بنجاح');
  }

// ================  حفظ العملية للوكلاء===============
  void _saveAgentOperation() async {
    //  double? amount = double.tryParse(_amountController.text.trim());
    // String details = _detailsController.text.trim();
    // String type = 'صرف';
    // String detailsNum = '🙎‍♂️ تسديد  ${_agentNameController.text}';

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
      // if (_transactionType == 'تسديد') {
      //   final dbHelper = DatabaseHelper();
      //   await dbHelper.insertDailyTransaction(amount, detailsNum, type);
      // }

      _nameController.clear();
      _amountController.clear();
      _detailsController.clear();
      _transactionType = '';
      // تحديث البيانات بناءً على الصفحة الحالية
      if (_currentPage == 0) {
        _pageController.animateToPage(1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      } else if (_currentPage == 1) {
        await fetchTransactions();
      }

      // await fetchAgentTransactions(); // جلب عمليات الوكلاء
      _showSuccessMessage('تم حفظ العملية بنجاح');
    } else {
      _showErrorMessage('يرجى اختيار نوع العملية');
    }
  }

  // ============ تصفيت العرض =================
//  عرض خيارات العرض
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
                          },
                        ),
                        _buildOptionTile(
                          icon: Icons.today,
                          text: 'اليوم',
                          onTap: () async {
                            Navigator.pop(context);
                            setState(() {
                              selectedTypeFull = 'اليوم ';

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
                              selectedTypeFull = 'الامس ';

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
                              selectedTypeFull = 'عرض عمليات الأسبوع الحالي ';

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

//  فتح جدول اختيار التاريخ
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

// جلب العمليات   بناءً على التاريخ المحدد
  Future<void> _fetchTransactionsByDate(DateTime date) async {
    final transactions = await DatabaseHelper().getOperationsByDate(date);
    final transactionsAg =
        await DatabaseHelper().getAgentOperationsByDate(date);

    setState(() {
      _recentCustomerTransactions = transactions;
      _recentAgentTransactions = transactionsAg;
      _selectedDate = date;
    });
  }

  // جلب كل العمليات
  Future<void> _fetchAllTransactions() async {
    final transactionsCu = await DatabaseHelper().getAllOperations();
    final transactionsAg = await DatabaseHelper().getAgentAllOperations();
    setState(() {
      _recentCustomerTransactions = transactionsCu;
      _recentAgentTransactions = transactionsAg;
      _selectedDate = null; // لا يوجد تاريخ محدد
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
      _selectedDate = null; // لا يوجد تاريخ محدد
    });
  }

//  ========= تحديث الواجهه ===========
  Future<void> fetchTransactions() async {
    if (_selectedDate != null) {
      await _fetchTransactionsByDate(_selectedDate!);
    } else if (_startDate != null && _endDate != null) {
      // إذا كان هناك نطاق زمني محدد (_startDate و _endDate)
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
        Icons.info_outline,
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
        // if (_selectedView == 'customers') {
        await fetchTransactions();
        // } else if (_selectedView == 'agents') {
        // await fetchAgentTransactions(); // تحديث عمليات الوكلاء
        // }
        _showSuccessMessage('تم حذف العملية بنجاح');
      } else {
        _showErrorMessage('فشل في حذف العملية');
      }
    } catch (error) {
      _showErrorMessage('حدث خطأ أثناء حذف العملية');
    }
  }

/* //  =========  تعديل عملية ===========
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
                                    // if (_selectedView == 'customers') {
                                    await fetchTransactions();
                                    // } else if (_selectedView == 'agents') {
                                    //   await fetchAgentTransactions();
                                    // }

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
 */
  //  =========   حقل البحث ===========
  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.fromLTRB(80.0, 8.0, 8.0, 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: TextField(
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'ابحث عن اسم...',
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide.none,
          ),
          prefixIcon: IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent),
            onPressed: () {
              setState(() {
                _isSearchActive = false;
                _searchQuery = '';
              });
            },
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
        ),
        onChanged: (query) {
          setState(() {
            _searchQuery = query; // تحديث نص البحث
          });
        },
      ),
    );
  }

  //  ========= تطبيق الفلتره ===========
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

  //  ========= نافذة تفاصيل العملية ===========
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
    // (transaction['type'] == 'قرض' || transaction['type'] == 'إضافة')

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
                          vertical: 8, horizontal: 8), // تقليل الهوامش الجانبية
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
                                value: DatabaseHelper()
                                    .getNumberFormat(transaction['amount']!),
                                //      ??
                                // 'غير معروف',
                                color: teypColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.type_specimen,
                                title: 'النوع',
                                // value: transaction['type'] ?? 'غير معروف',
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
    );
  }

// دالة مساعدة معدلة لإنشاء بطاقات المعلومات (أصغر حجمًا)
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8), // تقليل الحشو الداخلي
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10), // زوايا أقل استدارة
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 22,
              color: _selectedView == 'customers'
                  ? Colors.blue.shade700
                  : Colors.orange.shade500), // تصغير الأيقونة
          const SizedBox(width: 10), // تقليل المسافة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14, // تصغير حجم الخط
                    fontWeight: FontWeight.w600,
                    color: _selectedView == 'customers'
                        ? Colors.blue.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 2), // تقليل المسافة
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15, // تصغير حجم الخط
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// دالة مساعدة معدلة لإنشاء أزرار التحكم (أصغر حجمًا)
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
        padding: const EdgeInsets.symmetric(vertical: 10), // تقليل الارتفاع
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // زوايا أقل استدارة
        ),
        elevation: 1, // تقليل الظل
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.white), // تصغير الأيقونة
          const SizedBox(width: 6), // تقليل المسافة
          Text(
            label,
            style: const TextStyle(
              fontSize: 14, // تصغير حجم الخط
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

//  نافذة ملخص العمليات
  Future<void> _showSummaryDialog(BuildContext context) async {
    Map<String, double> summary;
    final isCustomers = _selectedView == 'customers';
    final primaryColor =
        isCustomers ? Colors.blue.shade700 : Colors.orange.shade700;

    String typeText = isCustomers ? ' اجمالي الديون' : 'اجمالي القروض';
    String boxText = isCustomers ? 'حالة صندوق العملاء' : 'حالة صندوق الموردين';

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
                    children: [
                      const Icon(Icons.summarize,
                          size: 28, color: Colors.white),
                      const SizedBox(height: 8),
                      const Text(
                        'ملخص العمليات ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$selectedTypeFull ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (_selectedDate != null)
                            Text(
                              _selectedDate!.toLocal().toString().split(' ')[0],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                        ],
                      ),
                      /*     const SizedBox(height: 8),
                      if (_startDate != null)
                        Row(
                          children: [
                            Text(
                              '     من يوم  ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            Text(
                              '${_startDate!.toLocal().toString().split(' ')[0]}     الى يوم    ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            Text(
                              _endDate!.toLocal().toString().split(' ')[0],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      if (_selectedDate == null && _startDate == null)
                        Text(
                          'كل العمليات',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ), */
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
                        title: 'التسديدات',
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
        );
      },
    );
  }

// دالة مساعدة لإنشاء بطاقات الملخص (بنفس نمط الدوال السابقة)
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
                    fontSize: valueSize,
                    fontWeight: FontWeight.bold,
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
        if (_isSearchActive) _buildSearchField(),
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
              border: Border.all(color: primaryColor, width: 2),
            ),
            margin: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 0.0),
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
                      Expanded(
                        flex: 5,
                        child: Text(
                          isCustomers ? 'اسم العميل' : 'اسم المورد',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 24,
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
                                    // Name Column
                                    Expanded(
                                      flex: 5,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Text(
                                          transaction[isCustomers
                                                  ? 'client_name'
                                                  : 'agent_name'] ??
                                              'غير معروف',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),

                                    // Amount Column
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            left: BorderSide(
                                                color: primaryColor, width: 2),
                                            right: BorderSide(
                                                color: primaryColor, width: 2),
                                          ),
                                        ),
                                        child: Text(
                                          DatabaseHelper().getNumberFormat(
                                              transaction['amount']),
                                          // ??'غير معروف',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                transaction['type'] == 'تسديد'
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Info Column
                                    Expanded(
                                      flex: 2,
                                      child: _buildInfoCell(transaction),
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

// =============== الواجهه ==================
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
                      onTap: () => _selectDate(context),
                      // اختيار التاريخ لعمليات العملاء

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
                    // if (_currentPage == 0) {
                    //   fetchTransactions();
                    // } else {
                    //   fetchAgentTransactions();
                    // }
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
                      onTap: () {
                        setState(() {
                          _isSearchActive =
                              !_isSearchActive; // تفعيل عرض حقل البحث
                        });
                      },
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

  Future<void> _editTransaction(Map<String, dynamic> transaction) async {
    if (!transaction.containsKey('amount') ||
        !transaction.containsKey('details') ||
        !transaction.containsKey('type')) {
      return;
    }

    final isCustomers = _selectedView == 'customers';
    final primaryColor =
        isCustomers ? Colors.blue.shade700 : Colors.orange.shade700;
    final lightColor =
        isCustomers ? Colors.blue.shade100 : Colors.orange.shade100;

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
                            children: [
                              const Icon(Icons.edit,
                                  size: 32, color: Colors.white),
                              const SizedBox(height: 8),
                              const Text(
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
                              /*      // Amount Field
                            TextFormField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'المبلغ',
                                labelStyle:
                                    TextStyle(color: Colors.grey.shade600),
                                floatingLabelStyle: TextStyle(
                                  color: primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                prefixIcon: Icon(Icons.attach_money,
                                    color: primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: primaryColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: primaryColor, width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: primaryColor, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 16),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          */
                              _buildInputField(
                                controller: amountController,
                                label: 'المبلغ',
                                icon: Icons.attach_money,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                // onEditingComplete: () => FocusScope.of(context).unfocus(),
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
                              /*  // Details Field
                            TextFormField(
                              controller: detailsController,
                              decoration: InputDecoration(
                                labelText: 'التفاصيل',
                                labelStyle:
                                    TextStyle(color: Colors.grey.shade600),
                                floatingLabelStyle: TextStyle(
                                  color: primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                prefixIcon: Icon(Icons.description,
                                    color: primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: primaryColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: primaryColor, width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: primaryColor, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 16),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                           */
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

/* // دالة مساعدة لإنشاء أزرار نوع العملية
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
        border: Border.all(color: color, width: 2),
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

// دالة مساعدة لإنشاء أزرار التحكم
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 2,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}
 */
}

// ===================================
