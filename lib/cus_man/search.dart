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
  List<Map<String, dynamic>> _transactions =
      []; // لتخزين العمليات المرتبطة بالاسم المدخل
  List<String> _suggestedNames = []; // قائمة الأسماء المشابهة

  final FocusNode _nameFocusNode = FocusNode();
  bool _showCustomersTable = true; // متغير للتبديل بين الجداول

  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
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

// ========= استرجاع الاسماء للعملاء===========
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

// ========= استرجاع الاسماء للعملاء===========
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

// ========= استرجاع عمليات العملاء عبر الاسم ===========
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
        _transactions = transactions;
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

// ========= استرجاع عمليات الوكلاء عبر الاسم ===========
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
        _transactions = transactions;
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

/* 
  void _showSearchDialogBox() {
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
                          color: Colors.cyan,
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

                      const SizedBox(height: 10.0),

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
 */

// ========= نافذة بحث  حسابات العملاء عبر الاسم ===========
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

// ========= نافذة بحث حسابات الوكلاء عبر الاسم ===========
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

                      // const SizedBox(height: 10.0),

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

// ===============  انشاء الحقل والقائمة المشابهة للعميل ==================
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
                  //  _searchTransactions,
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
                // borderRadius: BorderRadius.circular(8.0),
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

// ===============  انشاء الحقل والقائمة المشابهة للوكيل ==================
  Widget _buildAgeentNameFieldWithSuggestions(
      void Function(void Function()) setState) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.orange, width: 5)),
          ),
          // padding: const EdgeInsets.all(10.0),
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
                  //  _searchTransactions,
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
                // borderRadius: BorderRadius.circular(8.0),
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

  @override
  Widget build(BuildContext context) {
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
                    // العنوان
                    Container(
                      decoration: BoxDecoration(
                        color:
                            _showCustomersTable ? Colors.blue : Colors.orange,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: const [
                          Expanded(
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
                          Expanded(
                            flex: 5,
                            child: Text(
                              'التفاصيل',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
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

                    Expanded(
                      child: ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];
                          Color iconColor = (transaction['type'] == 'قرض' ||
                                  transaction['type'] == 'إضافة')
                              ? const Color(0xFFFF4134) // أحمر
                              : const Color(0xFF66EE6B); //

                          return Container(
                            decoration: BoxDecoration(
                              color: index % 2 == 0
                                  ? const Color(0xFFF1F1F1)
                                  : Colors.white,
                              border: Border(
                                bottom: BorderSide(
                                    color: _showCustomersTable
                                        ? Colors.blue
                                        : Colors.orange,
                                    width: 2.0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      transaction['amount'].toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                            color: _showCustomersTable
                                                ? Colors.blue
                                                : Colors.orange,
                                            width: 2.0),
                                        right: BorderSide(
                                            color: _showCustomersTable
                                                ? Colors.blue
                                                : Colors.orange,
                                            width: 2.0),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                        horizontal: 2,
                                      ),
                                      child: Text(
                                        transaction['details'],
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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
                        // _isSearchActive
                        // ? Icons.close_sharp
                        // : Icons.search_sharp,
                        color: Colors.green,
                        size: 25,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showSearchClientOrAgentDialogBox,
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
                    onTap:
                        _showCustomersTable ? _showSummary : _showAgeenSummary,

                    //  () async {
                    //   _showCustomersTable ? _showSummary : _showAgeenSummary;
                    //   // استدعاء الدالة بشكل صحيح
                    // },
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
            /*       Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Color(0x8300BBD4),
                border: Border(top: BorderSide(width: 3, color: Colors.cyan)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.print_rounded,
                      size: 38.0,
                      // color: Colors.blue,
                    ),
                    onPressed: () {
                      _generatePDF(context);
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.cyan,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search,
                          size: 30, color: Colors.white),
                      onPressed: _showSearchClientOrAgentDialogBox,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 40,
                    ),

                    //تمرير الدالة كمرجع دون استدعائها
                    onPressed:
                        _showCustomersTable ? _showSummary : _showAgeenSummary,
                    // onPressed: () async {
                    //   _showSummary(); // استدعاء الدالة بشكل صحيح
                    // },
                  ),
                ],
              ),
            ),
           */
          ],
        ),
      ),
    );
  }

  void _toggleTable(bool showCustomers) {
    setState(() {
      _showCustomersTable = showCustomers;
    });
  }

// ===============  نافذة اختيار نوع الحساب  ==================
  void _showSearchClientOrAgentDialogBox() {
/*     showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'بحث عن حساب',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.cyan,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر البحث عن عميل
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // إغلاق النافذة
                    _showSearchClientDialogBox(); // تنفيذ دالة البحث عن عميل
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'عميل',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16), // مسافة بين الزرين
                // زر البحث عن وكيل
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // إغلاق النافذة
                    _showSearchAgentDialogBox(); // تنفيذ دالة البحث عن وكيل
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'وكيل',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  */

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
                  'بحث عن حساب',
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
                    // زر البحث عن عميل
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // إغلاق النافذة
                        _showSearchClientDialogBox(); // تنفيذ دالة البحث عن عميل
                        _toggleTable(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'عميل',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Text(
                      'او',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.cyan,
                      ),
                    ),

                    // زر البحث عن وكيل
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // إغلاق النافذة
                        _showCustomersTable = false;
                        _showSearchAgentDialogBox(); // تنفيذ دالة البحث عن وكيل
                        _toggleTable(false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'وكيل',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

//  ========= انشاء صفوف لتفاصيل العملية ===========
  TableRow _buildInfoRow(String title, dynamic value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value.toString(),
            style: const TextStyle(
                fontSize: 16.0,
                color: Colors.black87,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

//  ========= نافذة عرض تفاصيل العملية ===========
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

                const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3), // عرض العمود الأول 20%
                      1: FlexColumnWidth(7), // عرض العمود الثاني 80%
                    },
                    border: TableBorder.all(
                      color: Colors.cyan, // لون الحدود
                      width: 2.0,
                    ),
                    children: [
                      _buildInfoRow('المبلغ', transaction['amount']),
                      _buildInfoRow('التفاصيل', transaction['details']),
                      _buildInfoRow('النوع', transaction['type']),
                      _buildInfoRow(
                          'التاريخ', formattedDate), // عرض التاريخ فقط
                      _buildInfoRow('الوقت', formattedTime), // عرض الوقت
                    ],
                  ),
                ),
                // الجدول

                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // حذف العملية
                        Navigator.of(context).pop();

                        _deleteTransaction(transaction);
                      },
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text('حذف'),
                      style: ElevatedButton.styleFrom(
                        // primary: Colors.red, // لون الزر
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 12.0),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // تعديل العملية
                        _editTransaction(transaction);
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text('تعديل'),
                      style: ElevatedButton.styleFrom(
                        // primary: Colors.blue, // لون الزر
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 12.0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // زر الإغلاق
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'إغلاق',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

//  =========  فتح نافذة ملخص العمليات ===========
  void _showSummary() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showErrorMessage('يرجى إدخال اسم العميل أولاً');

      return;
    }
    try {
      final databaseHelper = DatabaseHelper();
      final summary = await databaseHelper.getSummaryByName(name);
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
                      'تفاصيل العملية',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(5.0), // الكلمات التعريفية 20%
                          1: FlexColumnWidth(5.0), // البيانات 80%
                        },
                        border: TableBorder.all(
                          color: Colors.cyan,
                          width: 1.5,
                        ),
                        children: [
                          _buildInfoRow('الاسم', name),
                          _buildInfoRow(
                              'الإضافات', '${summary['totalAdditions']}'),
                          _buildInfoRow(
                              ' التسديدات', '${summary['totalPayments']}'),
                          _buildInfoRow(
                              'المبلغ المستحق', '${summary['outstanding']}'),
                        ]),
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
    } catch (error) {
      _showErrorMessage('حدث خطأ أثناء استرجاع البيانات');
    }
  }

//  =========  فتح نافذة ملخص العمليات ===========
  void _showAgeenSummary() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showErrorMessage('يرجى إدخال اسم العميل أولاً');

      return;
    }
    try {
      final databaseHelper = DatabaseHelper();
      final summary = await databaseHelper.getSummaryAgeentByName(name);
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
                      'تفاصيل العملية',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(5.0), // الكلمات التعريفية 20%
                          1: FlexColumnWidth(5.0), // البيانات 80%
                        },
                        border: TableBorder.all(
                          color: Colors.cyan,
                          width: 1.5,
                        ),
                        children: [
                          _buildInfoRow('الاسم', name),
                          _buildInfoRow(
                              'الإضافات', '${summary['totalAdditions']}'),
                          _buildInfoRow(
                              ' التسديدات', '${summary['totalPayments']}'),
                          _buildInfoRow(
                              'المبلغ المستحق', '${summary['outstanding']}'),
                        ]),
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
    } catch (error) {
      _showErrorMessage('حدث خطأ أثناء استرجاع البيانات');
    }
  }

//  ========= انشاء ملف bdf ===========
  Future<void> _generatePDF(BuildContext context) async {
    final pdf = pw.Document();
    // استدعاء الدالة والحصول على القيم
    // ignore: non_constant_identifier_names
    String NumAgen = _nameController.text;
    final databaseHelper = DatabaseHelper();
    final summary = await databaseHelper.getSummaryByName(NumAgen);
    final totalAdditions = summary['totalAdditions'];
    final totalPayments = summary['totalPayments'];
    final outstanding = summary['outstanding'];
    // تحميل الخط العربي
    final arabicFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Amiri-Regular.ttf'),
    );
    final dbHelper = DatabaseHelper(); // إنشاء كائن من الكلاس

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(10),
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(0),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                  color: PdfColors.black, width: 2), // مربع حول العناوين
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(height: 5),

                        pw.Text(
                          '  Report of Operations',
                          style: const pw.TextStyle(fontSize: 16),
                          textDirection: pw.TextDirection.ltr,
                        ),
                        pw.SizedBox(height: 15),
                        pw.Text(
                          '  771282337 ',
                          style: const pw.TextStyle(fontSize: 13),
                          textDirection: pw.TextDirection.ltr,
                        ),
                        pw.SizedBox(height: 15),

                        // إضافة التاريخ هنا باستخدام الدالة
                        pw.Text(
                          '  ${dbHelper.getFormattedDate()}', // استدعاء الدالة
                          style: const pw.TextStyle(
                            fontSize: 13,
                          ),
                          textDirection: pw.TextDirection.ltr,
                        ),
                      ],
                    ),

                    // إضافة النص "كشف حساب تفطيلي" باللون الأحمر الداكن
                    pw.Center(
                      child: pw.Text(
                        'كشف حساب تفطيلي',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 20,
                          color: PdfColors.red, // لون أحمر داكن
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ),

                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          '  مريط عصيد',
                          style: pw.TextStyle(font: arabicFont, fontSize: 18),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          '  لجمع أعمال ',
                          style: pw.TextStyle(font: arabicFont, fontSize: 14),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          '  صنعاء اليمن شارع خولان',
                          style: pw.TextStyle(font: arabicFont, fontSize: 14),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),

                // خط فاصل
                pw.Divider(height: 1, thickness: 2, color: PdfColors.black),

                pw.SizedBox(height: 15),

                // توسيط اسم العميل
                pw.Center(
                  child: pw.Text(
                    'اسم العميل / $NumAgen',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 1),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(5),
              2: const pw.FlexColumnWidth(1.5),
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
                ],
              ),
              ..._transactions.map((transaction) {
                final isAddition = transaction['type'] == 'إضافة';
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
                    pw.Text(
                      transaction['amount'].toString(),
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                        color: isAddition ? PdfColors.red : PdfColors.green,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
          pw.SizedBox(height: 20),
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
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Text(
                      'إجمالي الإضافات',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'إجمالي التسديدات',
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
                        fontSize: 14,
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
        ],
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

// =========  تحديث الواجهه ===========
  void _refreshTransactions() async {
    final databaseHelper = DatabaseHelper();
    final name = _nameController.text.trim();

    final newTransactions =
        await databaseHelper.getOperationsByClientName(name);
    setState(() {
      _transactions = newTransactions;
    });
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

      // استدعِ دالة الحذف باستخدام المثيل
      int rowsAffected = await databaseHelper.deleteOperation(transactionId);

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

//  =========  تعديل عملية ===========
  Future<void> _editTransaction(Map<String, dynamic> transaction) async {
    // التحقق من أن transaction غير null
    // ignore: unnecessary_null_comparison
    if (transaction == null) {
      return;
    }

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

    // باقي الكود...

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                backgroundColor: const Color.fromARGB(
                    255, 236, 232, 232), // خلفية النافذة بيضاء
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

                      // فراغ
                      const SizedBox(height: 20.0),

                      // مربع بحواف زرقاء
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.cyan, width: 2.0),
                            bottom: BorderSide(color: Colors.cyan, width: 2.0),
                          ),
                        ),
                        child: Column(
                          children: [
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
                                  borderSide:
                                      const BorderSide(color: Colors.cyan),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Colors.cyan, width: 2),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Colors.cyan, width: 2),
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
                                  borderSide:
                                      const BorderSide(color: Colors.cyan),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Colors.cyan, width: 2),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Colors.cyan, width: 2),
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
                      const SizedBox(height: 10.0),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 0.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFFF665B), width: 2.0),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'إضافة',
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w800),
                                ),
                                Radio<String>(
                                  value: 'إضافة',
                                  focusColor: Colors.red,
                                  hoverColor: Colors.red,
                                  activeColor: Colors.red,
                                  // fillColor: Colors.red,
                                  groupValue: selectedType,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedType = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 0.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFF70FF75), width: 2.0),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'تسديد',
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w800),
                                ),
                                Radio<String>(
                                  value: 'تسديد',
                                  focusColor: Colors.green,
                                  hoverColor: Colors.green,
                                  activeColor: Colors.green,
                                  groupValue: selectedType,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedType = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      // الحد العلوي بعرض 3 بكسل
                      Container(
                        width: double.infinity,
                        height: 3,
                        color: Colors.cyan,
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              // التحقق من صحة المدخلات
                              if (amountController.text.isEmpty ||
                                  detailsController.text.isEmpty) {
                                _showErrorMessage('يرجى تعبئة جميع الحقول');
                                return;
                              }

                              try {
                                final databaseHelper = DatabaseHelper();
                                int rowsAffected =
                                    await databaseHelper.updateOperation(
                                  transaction['operation_id'], // نفس ID العملية
                                  double.parse(amountController.text),
                                  detailsController.text,
                                  selectedType,
                                );

                                if (rowsAffected > 0) {
                                  // التحقق من أن الـ BuildContext لا يزال صالحًا
                                  if (!mounted) return;
                                  Navigator.of(context).pop();
                                  _refreshTransactions();

                                  _showSuccessMessage('تم تعديل العملية بنجاح');
                                } else {
                                  _showErrorMessage('فشل في تعديل العملية');
                                }
                              } catch (error) {
                                Navigator.of(context).pop();

                                _showErrorMessage(
                                    'حدث خطأ أثناء تعديل العملية');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              // primary: Colors.cyan,
                              // onPrimary: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 25, vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 4,
                            ),
                            child: const Text('حفظ'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              // primary: Colors.cyan,
                              // onPrimary: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 25, vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 4,
                            ),
                            child: const Text('إلغاء'),
                          ),
                        ],
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

// ==================
}











/* import 'package:flutter/material.dart';
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

// ignore_for_file: use_build_context_synchronously, duplicate_ignore, deprecated_member_use, non_constant_identifier_names

// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class SearchClientPage extends StatefulWidget {
  const SearchClientPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SearchClientPageState createState() => _SearchClientPageState();
}

class _SearchClientPageState extends State<SearchClientPage> {
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> _transactions =
      []; // لتخزين العمليات المرتبطة بالاسم المدخل
  List<String> _suggestedNames = []; // قائمة الأسماء المشابهة
  // bool _showInfoIcon = false;
// =============================================
  final FocusNode _nameFocusNode = FocusNode();

// =============================================
  @override
  void initState() {
    super.initState();

    // تحريك المؤشر إلى نهاية النص عند التركيز على الحقل
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

// =============================================
// =============================================

  void _searchTransactions() async {
    FocusScope.of(context).unfocus(); // إخفاء لوحة المفاتيح

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم العميل للبحث')),
      );
      return;
    }

    try {
      final databaseHelper = DatabaseHelper();
      List<Map<String, dynamic>> transactions =
          await databaseHelper.getOperationsByClientName(name);

      setState(() {
        _transactions = transactions;
      });

      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على عمليات لهذا العميل')),
        );
      }
    } catch (error) {
      // طباعة الخطأ لتتبعه أثناء التصحيح
      // ignore: avoid_print
      print('Error during search: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء البحث')),
      );
    }
  }

  void _refreshTransactions() async {
    final databaseHelper = DatabaseHelper();
    final name = _nameController.text.trim();

    final newTransactions =
        await databaseHelper.getOperationsByClientName(name);
    setState(() {
      _transactions = newTransactions;
    });
  }

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

  bool _isReady = false;

// عندما تصبح جاهزة قم بتحديث الحالة
  void _setReady() {
    setState(() {
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false, // إصلاح المشكلة عند ظهور لوحة المفاتيح

        appBar: AppBar(
          title: const Text(
            'كشوفات العملاء',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22.0),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.home,
              size: 35,
              color: Color(0xFFF26157),
            ),
            onPressed: () {
              // Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const MyApp(), // استبدل AddTransactionPage بالصفحة المستهدفة
                ),
              );
            },
          ),
          backgroundColor: Colors.cyan,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
                icon: const Icon(
                  Icons.person,
                  size: 30,
                  color: Color.fromARGB(255, 76, 96, 245),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AddDeletePage(), // استبدل AddTransactionPage بالصفحة المستهدفة
                    ),
                  );
                }),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.account_balance_wallet,
                size: 30,
                color: Color(0xFFFF9334),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const AddTransactionPage(), // استبدل AddTransactionPage بالصفحة المستهدفة
                  ),
                );
              },
            ),
            const SizedBox(width: 18),
          ],
        ),

        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(0.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.cyan, width: 2.0),
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8.0),
                          decoration: const BoxDecoration(
                            color: Colors.cyan,
                          ),
                          child: const Text(
                            'بحث عن حساب عميل',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 6.0),

                        // الحقل وأزرار البحث
                        Row(
                          children: [
                            const SizedBox(width: 10),
                            const Text(
                              'الاسم :',
                              style: TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                onChanged: _fetchSuggestedNames,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.cyan, width: 2.0),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.cyan, width: 2.0),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),

                        const SizedBox(height: 30.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              // onPressed: _isReady
                              //     ? _showSummary
                              //     : null, // تعطيل الزر إذا لم يكن جاهزًا
                              onPressed: _showSummary,

                              icon: const Icon(
                                Icons.info_rounded,
                                color: Colors.blue,
                                // _isReady
                                //     ? Colors.blue
                                //     : Colors.grey, // تغيير اللون حسب الحالة
                                size: 38.0,
                              ),
                            ),
                            // زر البحث
                            ElevatedButton(
                              onPressed: _searchTransactions,
                              style: ElevatedButton.styleFrom(
                                primary: Colors.cyan,
                                onPrimary: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25, vertical: 5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'بحث',
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              onPressed: _transactions.isEmpty
                                  ? null
                                  : () {
                                      _generatePDF(context); // التفاف الدالة
                                    },
                              icon: Icon(
                                Icons.print_rounded,
                                color: _transactions.isEmpty
                                    ? Colors.grey
                                    : Colors.blue, // التحكم في اللون
                                size: 38.0,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16.0),
                      ],
                    ),

                    // قائمة الأسماء المشابهة
                    if (_suggestedNames.isNotEmpty)
                      Positioned(
                        top:
                            95.0, // مكان القائمة بالنسبة إلى الجزء العلوي من الحاوية
                        left: 10.0,
                        right: 60.0,
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 100),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.cyan, width: 2.0),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ListView.builder(
                            itemCount: _suggestedNames.length,
                            itemBuilder: (context, index) {
                              return Column(
                                children: [
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 0.0),
                                    title: Text(
                                      _suggestedNames[index],
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _nameController.text =
                                            _suggestedNames[index];
                                        _suggestedNames = [];
                                      });
                                    },
                                  ),
                                  if (index < _suggestedNames.length - 1)
                                    const Divider(
                                      color: Colors.cyan,
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
                ),
              ),

              const SizedBox(height: 16.0),
              // عنوان الجدول
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 40),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2.0),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.cyan,
                ),
                child: const Text(
                  'جدول العملاء',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyan, width: 3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.cyan,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: const [
                            Expanded(
                              flex: 3, // نسبة 70%
                              child: Text(
                                'المبلغ',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18.0,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 5, // نسبة 30%
                              child: Text(
                                'التفاصيل',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18.0,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2, // نسبة 30%
                              child: Text(
                                'معلومات',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

/*      

                 Expanded(
                        child: ListView.builder(
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _transactions[index];
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
                                      flex: 3, // نسبة 70%
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 10,
                                        ),
                                        child: Text(
                                          transaction['amount'].toString(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // عمود التفاصيل
                                    Expanded(
                                      flex: 5, // نسبة 70%
                                      child: Container(
                                        decoration: const BoxDecoration(
                                            border: Border(
                                          left: BorderSide(
                                              color: Colors.cyan, width: 2.0),
                                          right: BorderSide(
                                              color: Colors.cyan, width: 2.0),
                                        )),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 15,
                                            horizontal: 2,
                                          ),
                                          child: Text(
                                            transaction['details'],
                                            textAlign: TextAlign.start,
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // عمود معلومات
                                    Expanded(
                                      flex: 2, // نسبة 30%

                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.info,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          _showTransactionDetails(transaction);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                      )
       */

                      Expanded(
                        child: ListView.builder(
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];

                            // تحديد لون الأيقونة حسب نوع العملية
                            Color iconColor;
                            if (transaction['type'] == 'إضافة') {
                              iconColor = Colors.red; // لون أحمر للإضافة
                            } else if (transaction['type'] == 'تسديد') {
                              iconColor = Colors.green; // لون أخضر للتسديد
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
                                    flex: 3, // نسبة 70%
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        transaction['amount'].toString(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // عمود التفاصيل
                                  Expanded(
                                    flex: 5, // نسبة 70%
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
                                          vertical: 15,
                                          horizontal: 2,
                                        ),
                                        child: Text(
                                          transaction['details'],
                                          textAlign: TextAlign.start,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // عمود معلومات
                                  Expanded(
                                    flex: 2, // نسبة 30%
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.info,
                                        color:
                                            iconColor, // اللون يعتمد على نوع العملية
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
                      )
                    ],
                  ),
                ),
              )

// ===========================================================================
            ],
          ),
        ),
      ),
    );
  }

// =========== =====================================================
// =========== =====================================================
  TableRow _buildInfoRow(String title, dynamic value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value.toString(),
            style: const TextStyle(
                fontSize: 16.0,
                color: Colors.black87,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16.0,
              // color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

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

                const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(7), // عرض العمود الأول 20%
                      1: FlexColumnWidth(3), // عرض العمود الثاني 80%
                    },
                    border: TableBorder.all(
                      color: Colors.cyan, // لون الحدود
                      width: 2.0,
                    ),
                    children: [
                      _buildInfoRow('المبلغ', transaction['amount']),
                      _buildInfoRow('التفاصيل', transaction['details']),
                      _buildInfoRow('النوع', transaction['type']),
                      _buildInfoRow(
                          'التاريخ', formattedDate), // عرض التاريخ فقط
                      _buildInfoRow('الوقت', formattedTime), // عرض الوقت
                    ],
                  ),
                ),
                // الجدول

                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // حذف العملية
                        Navigator.of(context).pop();

                        _deleteTransaction(transaction);
                      },
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text('حذف'),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.red, // لون الزر
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 12.0),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // تعديل العملية
                        _editTransaction(transaction);
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text('تعديل'),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue, // لون الزر
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 12.0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // زر الإغلاق
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'إغلاق',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// =========== =====================================================
// =========== =====================================================
  void _showSummary() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم العميل أولاً')),
      );
      return;
    }
    try {
      final databaseHelper = DatabaseHelper();
      final summary = await databaseHelper.getSummaryByName(name);

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
                      'تفاصيل العملية',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(6.5), // الكلمات التعريفية 20%
                          1: FlexColumnWidth(3.5), // البيانات 80%
                        },
                        border: TableBorder.all(
                          color: Colors.cyan,
                          width: 1.5,
                        ),
                        children: [
                          _buildInfoRow('الاسم', name),
                          _buildInfoRow(
                              'الإضافات', '${summary['totalAdditions']}'),
                          _buildInfoRow(
                              ' التسديدات', '${summary['totalPayments']}'),
                          _buildInfoRow(
                              'المبلغ المستحق', '${summary['outstanding']}'),
                        ]),
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
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء استرجاع البيانات')),
      );
    }
  }

  Future<void> _generatePDF(BuildContext context) async {
    final pdf = pw.Document();
    // استدعاء الدالة والحصول على القيم
    String NumAgen = _nameController.text;
    final databaseHelper = DatabaseHelper();
    final summary = await databaseHelper.getSummaryByName(NumAgen);
    final totalAdditions = summary['totalAdditions'];
    final totalPayments = summary['totalPayments'];
    final outstanding = summary['outstanding'];
    // تحميل الخط العربي
    final arabicFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Amiri-Regular.ttf'),
    );
    final dbHelper = DatabaseHelper(); // إنشاء كائن من الكلاس

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(10),
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(0),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                  color: PdfColors.black, width: 2), // مربع حول العناوين
            ),
            child:

                // =========================================================================
                // =========================================================================

                pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(height: 5),

                        pw.Text(
                          '  Report of Operations',
                          style: pw.TextStyle(fontSize: 16),
                          textDirection: pw.TextDirection.ltr,
                        ),
                        pw.SizedBox(height: 15),
                        pw.Text(
                          '  771282337 ',
                          style: pw.TextStyle(fontSize: 13),
                          textDirection: pw.TextDirection.ltr,
                        ),
                        pw.SizedBox(height: 15),

                        // إضافة التاريخ هنا باستخدام الدالة
                        pw.Text(
                          '  ${dbHelper.getFormattedDate()}', // استدعاء الدالة
                          style: pw.TextStyle(
                            // font: arabicFont,
                            fontSize: 13,
                          ),
                          textDirection: pw.TextDirection.ltr,
                        ),
                      ],
                    ),

                    // إضافة النص "كشف حساب تفطيلي" باللون الأحمر الداكن
                    pw.Center(
                      child: pw.Text(
                        'كشف حساب تفطيلي',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 20,
                          color: PdfColors.red, // لون أحمر داكن
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ),

                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          '  مريط عصيد',
                          style: pw.TextStyle(font: arabicFont, fontSize: 18),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          '  لجمع أعمال ',
                          style: pw.TextStyle(font: arabicFont, fontSize: 14),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          '  صنعاء اليمن شارع خولان',
                          style: pw.TextStyle(font: arabicFont, fontSize: 14),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),

                // خط فاصل
                pw.Divider(height: 1, thickness: 2, color: PdfColors.black),

                pw.SizedBox(height: 15),

                // توسيط اسم العميل
                pw.Center(
                  child: pw.Text(
                    'اسم العميل / $NumAgen',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
              ],
            ),

            // =========================================================================
            // =========================================================================
          );
        },
        build: (pw.Context context) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 1),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(5),
              2: const pw.FlexColumnWidth(1.5),
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
                ],
              ),
              ..._transactions.map((transaction) {
                final isAddition = transaction['type'] == 'إضافة';
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
                    pw.Text(
                      transaction['amount'].toString(),
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                        color: isAddition ? PdfColors.red : PdfColors.green,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
          pw.SizedBox(height: 20),
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
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Text(
                      'إجمالي الإضافات',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'إجمالي التسديدات',
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
                        fontSize: 14,
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
        ],
      ),
    );

    // حفظ الملف مؤقتًا في التخزين
    final output = await getTemporaryDirectory();
    final filePath = '${output.path}/transactions_report.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // عرض الملف داخل التطبيق
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(filePath: filePath),
      ),
    );
  }

  void _deleteTransaction(Map<String, dynamic> transaction) async {
    // احصل على معرف العملية
    final int? transactionId = transaction['operation_id'];

    if (transactionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('العملية المحددة غير صالحة للحذف'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // احصل على المثيل
      final databaseHelper = DatabaseHelper();

      // استدعِ دالة الحذف باستخدام المثيل
      int rowsAffected = await databaseHelper.deleteOperation(transactionId);

      if (rowsAffected > 0) {
        _refreshTransactions(); // تحديث البيانات بعد الحذف

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف العملية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في حذف العملية'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء حذف العملية'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editTransaction(Map<String, dynamic> transaction) async {
    // التحقق من أن transaction غير null
    if (transaction == null) {
      print('خطأ: الكائن transaction غير موجود أو null.');
      return;
    }

    // التحقق من وجود المفاتيح المتوقعة
    if (!transaction.containsKey('amount') ||
        !transaction.containsKey('details') ||
        !transaction.containsKey('type')) {
      print('خطأ: الكائن transaction لا يحتوي على المفاتيح المتوقعة.');
      return;
    }

    // التحقق من أن القيم غير null
    if (transaction['amount'] == null ||
        transaction['details'] == null ||
        transaction['type'] == null) {
      print('خطأ: إحدى القيم في transaction هي null.');
      return;
    }

    // إنشاء controllers وتعيين القيم
    final TextEditingController amountController =
        TextEditingController(text: transaction['amount'].toString());
    final TextEditingController detailsController =
        TextEditingController(text: transaction['details']);
    String selectedType = transaction['type']; // النوع الحالي

    // باقي الكود...
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                backgroundColor:
                    Color.fromARGB(255, 236, 232, 232), // خلفية النافذة بيضاء
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 10, // إضافة ظل للنافذة
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /*                   // العنوان بخلفية زرقاء
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
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
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 233, 232, 232),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
 */
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
                          'تعديل العملية',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // فراغ
                      const SizedBox(height: 20.0),

                      // مربع بحواف زرقاء
                      Container(
                        // margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.cyan, width: 2.0),
                            bottom: BorderSide(color: Colors.cyan, width: 2.0),
                          ),
                        ),
                        child: Column(
                          children: [
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
                                  borderSide:
                                      const BorderSide(color: Colors.cyan),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Colors.cyan, width: 2),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Colors.cyan, width: 2),
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
                                  borderSide:
                                      const BorderSide(color: Colors.cyan),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Colors.cyan, width: 2),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Colors.cyan, width: 2),
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
/* 
                          // اختيار نوع العملية (مربع)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 1.2,
                                    child: Radio<String>(
                                      value: 'إضافة',
                                      groupValue: selectedType,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedType = value!;
                                        });
                                      },
                                      activeColor: Colors.blue, // لون المربع عند الاختيار
                                    ),
                                  ),
                                  const Text(
                                    'إضافة',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 1.2,
                                    child: Radio<String>(
                                      value: 'تسديد',
                                      groupValue: selectedType,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedType = value!;
                                        });
                                      },
                                      activeColor: Colors.blue, // لون المربع عند الاختيار
                                    ),
                                  ),
                                  const Text(
                                    'تسديد',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      

 */
                      const SizedBox(height: 10.0),

                      // =================================================
                      // =================================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            // padding: const EdgeInsets.all(8.0),
                            padding:
                                const EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 0.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFFF665B), width: 2.0),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'إضافة',
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w800),
                                ),
                                Radio<String>(
                                  value: 'إضافة',
                                  focusColor: Colors.red,
                                  hoverColor: Colors.red,
                                  activeColor: Colors.red,
                                  // fillColor: Colors.red,
                                  groupValue: selectedType,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedType = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 0.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFF70FF75), width: 2.0),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'تسديد',
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w800),
                                ),
                                Radio<String>(
                                  value: 'تسديد',
                                  focusColor: Colors.green,
                                  hoverColor: Colors.green,
                                  activeColor: Colors.green,
                                  groupValue: selectedType,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedType = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      // الحد العلوي بعرض 3 بكسل
                      Container(
                        width: double.infinity,
                        height: 3,
                        color: Colors.cyan,
                      ),
                      const SizedBox(height: 10.0),

                      // =================================================
                      // =================================================

                      /*                   // مربع أسفل النافذة للأزرار
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12.0),
                          bottomRight: Radius.circular(12.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              // التحقق من صحة المدخلات
                              if (amountController.text.isEmpty ||
                                  detailsController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('يرجى تعبئة جميع الحقول'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              try {
                                print('Attempting to update operation: ID=${transaction['operation_id']}, '
                                    'Amount=${amountController.text}, Details=${detailsController.text}, '
                                    'Type=$selectedType');
                                print('===================================');
                                final databaseHelper = DatabaseHelper();
                                int rowsAffected = await databaseHelper.updateOperation(
                                  transaction['operation_id'], // نفس ID العملية
                                  double.parse(amountController.text),
                                  detailsController.text,
                                  selectedType,
                                );

                                if (rowsAffected > 0) {
                                  Navigator.of(context).pop();
                                  _refreshTransactions();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم تعديل العملية بنجاح'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('فشل في تعديل العملية'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (error) {
                                print('Error occurred while updating operation: $error');
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('حدث خطأ أثناء تعديل العملية'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, // لون زر الحفظ
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            child: const Text(
                              'حفظ',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey, // لون زر الإلغاء
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                 */
                      //  ==============================================================================
                      // أزرار الحفظ والإلغاء
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              // التحقق من صحة المدخلات
                              if (amountController.text.isEmpty ||
                                  detailsController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('يرجى تعبئة جميع الحقول'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              try {
                                print(
                                    'Attempting to update operation: ID=${transaction['operation_id']}, '
                                    'Amount=${amountController.text}, Details=${detailsController.text}, '
                                    'Type=$selectedType');
                                print('===================================');
                                final databaseHelper = DatabaseHelper();
                                int rowsAffected =
                                    await databaseHelper.updateOperation(
                                  transaction['operation_id'], // نفس ID العملية
                                  double.parse(amountController.text),
                                  detailsController.text,
                                  selectedType,
                                );

                                if (rowsAffected > 0) {
                                  Navigator.of(context).pop();
                                  _refreshTransactions();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم تعديل العملية بنجاح'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('فشل في تعديل العملية'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (error) {
                                print(
                                    'Error occurred while updating operation: $error');
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('حدث خطأ أثناء تعديل العملية'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              // ignore: deprecated_member_use
                              primary: Colors.cyan,
                              // ignore: deprecated_member_use
                              onPrimary: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 25, vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 4,
                            ),
                            child: const Text('حفظ'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              // ignore: deprecated_member_use
                              primary: Colors.cyan,
                              // ignore: deprecated_member_use
                              onPrimary: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 25, vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 4,
                            ),
                            child: const Text('إلغاء'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10.0),

                      //  ==============================================================================
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
}
 */
// =  ======================================================================================================
