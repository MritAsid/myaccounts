import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import 'add_transaction.dart';
import 'add_delete.dart';
import '../main.dart';
import 'bdfviwo/bdf.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class SearchClientPage extends StatefulWidget {
  const SearchClientPage({super.key});

  @override
  SearchClientPageState createState() => SearchClientPageState();
}

class SearchClientPageState extends State<SearchClientPage> {
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> _transactions = [];
  // لتخزين العمليات المرتبطة بالاسم المدخل
  List<String> _suggestedNames = []; // قائمة الأسماء المشابهة

  // متغيرات لحفظ القيم
  String name = '';
  String serviceType = '';
  String address = '';
  String phoneNumber = '';
  double tupeAllMomnt = 0;
  int numberOperations = 0;

  final FocusNode _nameFocusNode = FocusNode();
  bool _showCustomersTable = true; // متغير للتبديل بين الجداول
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();

    _nameFocusNode.addListener(() {
      if (_nameFocusNode.hasFocus) {
        _nameController.selection = TextSelection.fromPosition(
          TextPosition(offset: _nameController.text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  // دالة لتحميل البيانات المحفوظة من البيانات الشخصيه
  Future<void> _loadSavedData() async {
    final info = await DatabaseHelper().getPersonalInfo();
    if (info != null) {
      setState(() {
        name = info['name'] ?? '';
        serviceType = info['serviceType'] ?? '';
        address = info['address'] ?? '';
        phoneNumber = info['phoneNumber'] ?? '';
      });
    }
  }

/*
   =======================================
        $$$== استرجاع العمليات ==$$$
   =======================================
*/

  //   استرجاع الاسماء للعملاء
  void _fetchSuggestedNames(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestedNames = [];
      });
      return;
    }

    final names = await DatabaseHelper().getClientNames(query);
    setState(() {
      _suggestedNames = names;
    });
  }

  //   استرجاع الاسماء للموردين
  void _fetchSuggestedAgeentNames(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestedNames = [];
      });
      return;
    }

    final names = await DatabaseHelper().getAgentNames(query);
    setState(() {
      _suggestedNames = names;
    });
  }

  //   استرجاع عمليات العملاء عبر الاسم
  Future<void> _searchTransactions() async {
    FocusScope.of(context).unfocus(); // إخفاء لوحة المفاتيح

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showErrorMessage('يرجى إدخال اسم العميل للبحث');

      return;
    }

    setState(() {
      _isLoading = true; // عرض مؤشر التحميل
    });

    try {
      final databaseHelper = DatabaseHelper();
      List<Map<String, dynamic>> transactions =
          await databaseHelper.getOperationsByClientName(name);
      setState(() {
        _transactions = transactions.reversed.toList();
        _isLoading = false; // إخفاء مؤشر التحميل
      });

      if (transactions.isEmpty) {
        _showErrorMessage('لم يتم العثور على عمليات لهذا العميل');
      } else {
        numberOperations = transactions.length + 1;
        _showSuccessMessage('تم العثور على ${transactions.length} عملية');
      }
    } catch (error) {
      String errorMessage = 'حدث خطأ أثناء البحث';
      if (error.toString().contains("timeout")) {
        errorMessage = 'انتهى وقت الانتظار، يرجى التحقق من اتصال الإنترنت';
      } else if (error.toString().contains("no database")) {
        errorMessage = 'قاعدة البيانات غير متوفرة';
      }

      _showErrorMessage(errorMessage);

      setState(() {
        _isLoading = false; // إخفاء مؤشر التحميل
      });
    }
  }

  //   استرجاع عمليات الوكلاء عبر الاسم
  Future<void> _searchTransacageent() async {
    FocusScope.of(context).unfocus(); // إخفاء لوحة المفاتيح

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showErrorMessage('يرجى إدخال اسم الوكيل للبحث');
      return;
    }

    setState(() {
      _isLoading = true; // عرض مؤشر التحميل
    });

    try {
      final databaseHelper = DatabaseHelper();
      List<Map<String, dynamic>> transactions =
          await databaseHelper.getOperationsByAgenntName(name);

      setState(() {
        _transactions = transactions.reversed.toList();

        _isLoading = false; // إخفاء مؤشر التحميل
      });

      if (transactions.isEmpty) {
        _showErrorMessage('لم يتم العثور على عمليات لهذا العميل');
      } else {
        _showSuccessMessage('تم العثور على ${transactions.length} عملية');
      }
    } catch (error) {
      String errorMessage = 'حدث خطأ أثناء البحث';
      if (error.toString().contains("timeout")) {
        errorMessage = 'انتهى وقت الانتظار، يرجى التحقق من اتصال الإنترنت';
      } else if (error.toString().contains("no database")) {
        errorMessage = 'قاعدة البيانات غير متوفرة';
      }

      _showErrorMessage(errorMessage);

      setState(() {
        _isLoading = false; // إخفاء مؤشر التحميل
      });
    }
  }

  //    تحديث الواجهه  اعادة استرجاع العمليات
  void _refreshTransactions() async {
    final databaseHelper = DatabaseHelper();
    final name = _nameController.text.trim();

    final newTransactions = _showCustomersTable
        ? await databaseHelper.getOperationsByClientName(name)
        : await databaseHelper.getOperationsByAgenntName(name);
    setState(() {
      _transactions = newTransactions;
    });
  }

/*
   =======================================
        $$$🔎🔎 بحث الحسابات 🔎🔎$$$
   =======================================
*/

  // بحث حساب عميل او وكيل
  void _showSearchAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'إضافة حساب جديد',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24.0),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: _buildActionButton(
                        label: 'عميل',
                        icon: Icons.person_outline,
                        color: Colors.blue.shade600,
                        onPressed: () {
                          Navigator.of(context).pop(); // إغلاق النافذة
                          _showSearchClientDialogBox(); // تنفيذ دالة البحث عن عميل
                          _toggleTable(true);
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
                          Navigator.of(context).pop(); // إغلاق النافذة
                          _showCustomersTable = false;
                          _showSearchAgentDialogBox(); // تنفيذ دالة البحث عن وكيل
                          _toggleTable(false);
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

  //   نافذة بحث  حسابات العملاء عبر الاسم
  void _showSearchClientDialogBox() {
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
                          color: Colors.blue,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12.0),
                            topRight: Radius.circular(12.0),
                          ),
                        ),
                        child: const Text(
                          'بحث عن عميل',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // حقل البحث عن اسم العميل
                      _buildClientNameFieldWithSuggestions(setState),

                      const SizedBox(height: 16.0),
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

  //   نافذة بحث حسابات الوكلاء عبر الاسم
  void _showSearchAgentDialogBox() {
    Visibility(
      visible: _isLoading,
      child: const CircularProgressIndicator(),
    );
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
                          'بحث عن مورد',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // حقل البحث عن اسم العميل
                      _buildAgeentNameFieldWithSuggestions(setState),

                      const SizedBox(height: 16.0),
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

  //    انشاء الحقل والقائمة المشابهة للعميل
  Widget _buildClientNameFieldWithSuggestions(
      void Function(void Function()) setState) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.blue, width: 5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10.0),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child:
                    // حقل الاسم
                    Row(
                  children: [
                    const Text(
                      'الاسم: ',
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
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _fetchSuggestedNames(
                                value); // تحديث القائمة المقترحة
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 140.0), // فراغ بمقدار 130 بكسل
              Container(
                height: 3,
                color: Colors.blue,
              ),
              const SizedBox(height: 10.0),

              // زر البحث
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await _searchTransactions(); // انتظار انتهاء البحث
                    if (_transactions.isNotEmpty) {
                      // التحقق من أن الـ BuildContext لا يزال صالحًا
                      if (!mounted) return;
                      Navigator.of(context).pop(); // إغلاق النافذة بعد البحث
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'بحث',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // قائمة العملاء المطابقة
        if (_suggestedNames.isNotEmpty)
          Positioned(
            top: 55.0,
            left: 10,
            right: 55,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue, width: 2.0),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _suggestedNames.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 0.0,
                        ),
                        title: Text(
                          _suggestedNames[index],
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _nameController.text = _suggestedNames[index];
                            _suggestedNames = [];
                          });
                        },
                      ),
                      if (index < _suggestedNames.length - 1)
                        const Divider(
                          color: Colors.blue,
                          height: 0.0,
                          thickness: 2.0,
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

  //    انشاء الحقل والقائمة المشابهة للوكيل
  Widget _buildAgeentNameFieldWithSuggestions(
      void Function(void Function()) setState) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.orange, width: 5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10.0),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child:
                    // حقل الاسم
                    Row(
                  children: [
                    const Text(
                      'الاسم: ',
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
                            borderSide: BorderSide(color: Colors.orange),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.orange, width: 2.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.orange, width: 2.0),
                          ),
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _fetchSuggestedAgeentNames(
                                value); // تحديث القائمة المقترحة
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 140.0), // فراغ بمقدار 130 بكسل
              Container(
                height: 3,
                color: Colors.orange,
              ),
              const SizedBox(height: 10.0),
              // زر البحث
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await _searchTransacageent(); // انتظار انتهاء البحث
                    if (_transactions.isNotEmpty) {
                      // التحقق من أن الـ BuildContext لا يزال صالحًا
                      if (!mounted) return;
                      Navigator.of(context).pop(); // إغلاق النافذة بعد البحث
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'بحث',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // قائمة العملاء المطابقة
        if (_suggestedNames.isNotEmpty)
          Positioned(
            top: 55.0,
            left: 10,
            right: 55,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.orange, width: 2.0),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _suggestedNames.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 0.0,
                        ),
                        title: Text(
                          _suggestedNames[index],
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _nameController.text = _suggestedNames[index];
                            _suggestedNames = [];
                          });
                        },
                      ),
                      if (index < _suggestedNames.length - 1)
                        const Divider(
                          color: Colors.orange,
                          height: 0.0,
                          thickness: 2.0,
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

      if (_showCustomersTable) {
        // حذف العملية من جدول العملاء
        rowsAffected = await databaseHelper.deleteOperation(transactionId);
      } else {
        // حذف العملية من جدول الوكلاء
        rowsAffected = await databaseHelper.deleteAgentOperation(transactionId);
      }

      if (rowsAffected > 0) {
        _refreshTransactions(); // تحديث البيانات بعد الحذف

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

    final isCustomers = _showCustomersTable;
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
                                        _refreshTransactions();
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

  //    نافذة تفاصيل العملية ===========
  void _buildTransactionDetailsDialog(Map<String, dynamic> transaction) {
    final primaryColor =
        _showCustomersTable ? Colors.blue.shade700 : Colors.orange.shade700;
    final lightColor =
        _showCustomersTable ? Colors.blue.shade100 : Colors.orange.shade100;

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
                              borderRadius: BorderRadius.circular(
                                  10), // زوايا أقل استدارة
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
          );
        });
  }

  //     نافذة تفاصيل  العميل اوالوكيل
  void _showCustomerDetails() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showErrorMessage('يرجى إدخال اسم العميل أولاً');

      return;
    }
    try {
      final databaseHelper = DatabaseHelper();
      final summary = _showCustomersTable
          ? await databaseHelper.getSummaryByName(name)
          : await databaseHelper.getSummaryAgeentByName(name);

      // التحقق من أن الـ BuildContext لا يزال صالحًا
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          final isDebt = double.parse(summary['outstanding'].toString()) > 0;
          final isDebtCust = double.parse(summary['outstanding'].toString()) < 0
              ? 'له'
              : 'علية';
          final isDebtAgnt = double.parse(summary['outstanding'].toString()) < 0
              ? 'علية'
              : 'له';

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(12), // تقليل الهوامش الخارجية
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16), // تقليل استدارة الزوايا
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
                    // Header with gradient (أصغر حجمًا)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12), // تقليل الحشو
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _showCustomersTable
                              ? [Colors.blue.shade700, Colors.blue.shade500]
                              : [
                                  Colors.orange.shade700,
                                  Colors.orange.shade500
                                ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                              _showCustomersTable
                                  ? Icons.person_outline
                                  : Icons.business,
                              size: 32,
                              color: Colors.white), // تصغير الأيقونة
                          const SizedBox(height: 4), // تقليل المسافة
                          Text(
                            _showCustomersTable
                                ? 'تفاصيل العميل'
                                : 'تفاصيل المورد',
                            style: const TextStyle(
                              fontSize: 18, // تصغير حجم الخط
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Customer Info Section (أصغر حجمًا)
                    Padding(
                      padding:
                          const EdgeInsets.all(12), // تقليل الهوامش الداخلية
                      child: Column(
                        children: [
                          _buildInfoCard(
                            icon: Icons.person,
                            title: 'الاسم',
                            value: name,
                            color: Colors.blue.shade100,
                          ),
                          const SizedBox(
                              height: 8), // تقليل المسافة بين البطاقات
                        ],
                      ),
                    ),
                    Text(' عدد العمليات        ${numberOperations.toString()}'),
                    // Financial Summary (أكثر إحكاما)
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12), // تقليل الهوامش الجانبية
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius:
                            BorderRadius.circular(10), // زوايا أقل استدارة
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            _showCustomersTable
                                ? 'اجمالي الديون'
                                : 'اجمالي القروض المستحقة',
                            databaseHelper
                                .getNumberFormat(summary['totalAdditions']),
                            icon: Icons.add_circle_outline,
                            color: Colors.red,
                          ),
                          Divider(
                              height: 1,
                              color: Colors.grey.shade300,
                              thickness: 0.5), // خط فاصل أرفع
                          _buildSummaryRow(
                            _showCustomersTable
                                ? 'اجمالي التسديدات'
                                : 'اجمالي المدفوعات النقدية',
                            // 'كل التسديدات',
                            databaseHelper
                                .getNumberFormat(summary['totalPayments']),
                            icon: Icons.remove_circle_outline,
                            color: Colors.green,
                          ),
                          Divider(
                              height: 1,
                              color: Colors.grey.shade300,
                              thickness: 0.5),
                          _buildSummaryRow(
                            _showCustomersTable
                                ? 'اجمالي المستحق $isDebtCust' //
                                : ' اجمالي المستحق $isDebtAgnt',
                            databaseHelper
                                .getNumberFormat(summary['outstanding']),
                            icon: isDebt
                                ? Icons.warning_amber
                                : Icons.check_circle_outline,
                            color: isDebt ? Colors.red : Colors.green,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),

                    // Action Buttons (أزرار أكثر إحكاما)
                    Padding(
                      padding: const EdgeInsets.all(12), // تقليل الهوامش
                      child: Row(
                        children: [
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
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (error) {
      _showErrorMessage('حدث خطأ أثناء استرجاع البيانات');
    }
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
            color: _showCustomersTable
                ? Colors.blue.shade400
                : Colors.orange.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: _showCustomersTable
                  ? Colors.blue.shade400
                  : Colors.orange.shade400,
              width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: _showCustomersTable
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
              color: _showCustomersTable
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
                    color: _showCustomersTable
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

  // دالة مساعدة معدلة لإنشاء صفوف الملخص المالي (أكثر إحكاما)
  Widget _buildSummaryRow(
    String label,
    String value, {
    required IconData icon,
    required Color color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 0, horizontal: 12), // تقليل الحشو
      child: Row(
        children: [
          Icon(icon, size: 20, color: color), // تصغير الأيقونة
          const SizedBox(width: 8), // تقليل المسافة
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14, // تصغير حجم الخط
                color: Colors.grey.shade800,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14, // تصغير حجم الخط
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        ],
      ),
    );
  }

  //   الواجهه
  @override
  Widget build(BuildContext context) {
    final primaryColor =
        _showCustomersTable ? Colors.blue.shade700 : Colors.orange.shade700;
    final lightColor =
        _showCustomersTable ? Colors.blue.shade100 : Colors.orange.shade100;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text(
            'كشوفات الحسابات',
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
                icon: const Icon(Icons.account_balance_wallet,
                    color: Colors.orange, size: 25),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTransactionPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 0.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 3.0,
                    color: _showCustomersTable ? Colors.blue : Colors.orange,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10)),
                      ),
                      child: Row(
                        children: const [
                          Expanded(
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
                          Expanded(
                            flex: 5,
                            child: Text(
                              'التفاصيل',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
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
                    Expanded(
                      child: _transactions.isEmpty
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
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = _transactions[index];
                                Color iconColor =
                                    (transaction['type'] == 'قرض' ||
                                            transaction['type'] == 'إضافة')
                                        ? const Color(0xFFFF4134) // أحمر
                                        : const Color(0xFF66EE6B); //
                                return InkWell(
                                  onTap: () {
                                    _buildTransactionDetailsDialog(transaction);
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
                                        // Amount Column
                                        Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            child: Text(
                                              DatabaseHelper().getNumberFormat(
                                                  transaction['amount']),
                                              // ??'غير معروف',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: transaction['type'] ==
                                                        'تسديد'
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Name Column
                                        Expanded(
                                          flex: 5,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                left: BorderSide(
                                                    color: primaryColor,
                                                    width: 2),
                                                right: BorderSide(
                                                    color: primaryColor,
                                                    width: 2),
                                              ),
                                            ),
                                            child: Text(
                                              transaction['details'].toString(),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),

                                        Expanded(
                                          flex: 2,
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.info,
                                              color: iconColor,
                                            ),
                                            onPressed: () {
                                              _buildTransactionDetailsDialog(
                                                  transaction);
                                            },
                                          ),
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
                      _generatePDF(context);
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
                        Icons.print_rounded,
                        color: Colors.green,
                        size: 25,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showSearchAccountDialog,
                    child: Container(
                      width: 45, // زيادة العرض
                      height: 45, // زيادة الارتفاع
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
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
                          Icons.search_rounded,
                          color: Colors
                              .white, // لون الأيقونة أبيض لتتناسب مع التدرج
                          size: 30, // حجم أكبر للأيقونة
                        ),
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: _showCustomerDetails,
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
                            _showCustomersTable ? Colors.blue : Colors.orange,
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
    );
  }

  //  تغيير العرض
  void _toggleTable(bool showCustomers) {
    setState(() {
      _showCustomersTable = showCustomers;
    });
  }

  //  ========= انشاء ملف bdf ===========
  Future<void> _generatePDF(BuildContext context) async {
    final pdf = pw.Document();

    String numAgen = _nameController.text;
    final databaseHelper = DatabaseHelper();

    final summary = _showCustomersTable
        ? await databaseHelper.getSummaryByName(numAgen)
        : await databaseHelper.getSummaryAgeentByName(numAgen);
    final totalAdditions = summary['totalAdditions'];
    final totalPayments = summary['totalPayments'];
    final outstanding = summary['outstanding'];

    String numShwo =
        _showCustomersTable ? '   اسم العميل /  ' : '   اسم المورد /  ';

    // تحميل الخط العربي
    final arabicFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Amiri-Regular.ttf'),
    );
    final dbHelper = DatabaseHelper(); // إنشاء كائن من الكلاس
    tupeAllMomnt = 0;

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(10),
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          // عرض رأس الصفحة فقط في الصفحة الأولى
          if (context.pageNumber == 1) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(0),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 2),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0.0),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Report of Operations',
                              style: const pw.TextStyle(fontSize: 16),
                              textDirection: pw.TextDirection.ltr,
                            ),
                            pw.SizedBox(height: 15),
                            pw.Text(
                              phoneNumber,
                              style: const pw.TextStyle(fontSize: 13),
                              textDirection: pw.TextDirection.ltr,
                            ),
                            pw.SizedBox(height: 18),
                            pw.Text(
                              dbHelper.getFormattedDate(),
                              style: const pw.TextStyle(fontSize: 13),
                              textDirection: pw.TextDirection.ltr,
                            ),
                          ],
                        ),
                        pw.Column(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Container(
                                child: pw.Text(
                                  'الصفحة : ${context.pageNumber}',
                                  style: pw.TextStyle(
                                    font: arabicFont,
                                    fontSize: 12,
                                  ),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                              ),
                              pw.SizedBox(height: 15),
                              pw.SizedBox(height: 15),
                              pw.Center(
                                child: pw.Text(
                                  'كشف حساب تفطيلي',
                                  style: pw.TextStyle(
                                    font: arabicFont,
                                    fontSize: 20,
                                    color: PdfColors.red,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                              ),
                            ]),
                        pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              name,
                              style:
                                  pw.TextStyle(font: arabicFont, fontSize: 16),
                              textDirection: pw.TextDirection.rtl,
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              serviceType,
                              style:
                                  pw.TextStyle(font: arabicFont, fontSize: 13),
                              textDirection: pw.TextDirection.rtl,
                            ),
                            pw.SizedBox(height: 18),
                            pw.Text(
                              address,
                              style:
                                  pw.TextStyle(font: arabicFont, fontSize: 13),
                              textDirection: pw.TextDirection.rtl,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(height: 1, thickness: 2, color: PdfColors.black),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        numAgen,
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.Text(
                        numShwo,
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                ],
              ),
            );
          } else {
            // إرجاع رأس فارغ للصفحات الأخرى
            return pw.Column(children: [
              pw.Center(
                child: pw.Text(
                  'الصفحة : ${context.pageNumber}',
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontSize: 12,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ),

              // رأس الجدول
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.8),
                  1: const pw.FlexColumnWidth(1.7),
                  2: const pw.FlexColumnWidth(2.0),
                  3: const pw.FlexColumnWidth(4.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.cyan),
                    children: [
                      pw.Text(
                        'التاريخ',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 16.0,
                        ),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'الرصيد التراكمي',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 16.0,
                        ),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'المبلغ',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 16.0,
                        ),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'التفاصيل',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 16.0,
                        ),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ]);
          }
        },
        build: (pw.Context context) {
          // إضافة رأس الجدول في بداية كل صفحة
          return [
            // رأس الجدول
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.8),
                1: const pw.FlexColumnWidth(1.7),
                2: const pw.FlexColumnWidth(2.0),
                3: const pw.FlexColumnWidth(4.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.cyan),
                  children: [
                    pw.Text(
                      'التاريخ',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 16.0,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'الرصيد التراكمي',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 16.0,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'المبلغ',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 16.0,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'التفاصيل',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 16.0,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
            // بيانات الجدول
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.8),
                1: const pw.FlexColumnWidth(1.7),
                2: const pw.FlexColumnWidth(2.0),
                3: const pw.FlexColumnWidth(4.5),
              },
              children: _transactions.map((transaction) {
                final isAddition = transaction['type'] == 'إضافة' ||
                    transaction['type'] == 'قرض';
                if (isAddition) {
                  tupeAllMomnt += transaction['amount'];
                } else {
                  tupeAllMomnt -= transaction['amount'];
                }
                return pw.TableRow(
                  children: [
                    pw.Text(
                      transaction['date'].split(' ')[0],
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      DatabaseHelper().getNumberFormat(tupeAllMomnt),
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                        color:
                            tupeAllMomnt > 0 ? PdfColors.red : PdfColors.green,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      DatabaseHelper().getNumberFormat(transaction['amount']),
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                        color: isAddition ? PdfColors.red : PdfColors.green,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 10),
                      child: pw.Text(
                        transaction['details'],
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 14,
                        ),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            // تذييل الصفحة
            pw.Container(
              alignment: pw.Alignment.bottomCenter,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
              ),
              child: pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Text(
                        'إجمالي الديون',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'إجمالي الديون المسددة',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'المبلغ المستحق',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Text(
                        totalAdditions.toString(),
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 18,
                          color: PdfColors.red700,
                        ),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        totalPayments.toString(),
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 18,
                          color: PdfColors.green,
                        ),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        outstanding.toString(),
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 20,
                          color:
                              outstanding > 0 ? PdfColors.red : PdfColors.green,
                        ),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
    // حفظ الملف مؤقتًا في التخزين
    final output = await getTemporaryDirectory();
    final filePath = '${output.path}/transactions_report.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // عرض الملف داخل التطبيق
    // التحقق من أن الـ BuildContext لا يزال صالحًا
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(filePath: filePath),
      ),
    );
  }
}
    // =   ===============
