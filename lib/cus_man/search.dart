// ==============Asmael Asid ====================================

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import 'add_transaction.dart';
import 'add_delete.dart';
import '../frontend/front_help.dart';

import 'bdfviwo/bdf.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class SearchClientPage extends StatefulWidget {
  final String? customerName;
  const SearchClientPage({
    super.key,
    this.customerName,
    this.iscontun,
  });
  final bool? iscontun;

  @override
  SearchClientPageState createState() => SearchClientPageState();
}

class SearchClientPageState extends State<SearchClientPage> {
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> _transactions = [];
  // لتخزين العمليات المرتبطة بالاسم المدخل
  List<String> _suggestedNames = []; // قائمة الأسماء المشابهة
  List<String> _suggestedNamesAgent = []; // قائمة الأسماء المشابهة
  bool? acconutTeyp;

  //  كلاس قاعدة البيانات
  final DatabaseHelper _dbHelper = DatabaseHelper();
  // متغيرات لحفظ القيم
  String name = '';
  String serviceType = '';
  String address = '';
  String phoneNumber = '';
  double tupeAllMomnt = 0;
  int numberOperations = 0;

  final iconCustomer = Icons.person;
  final iconAgeen = Icons.business_rounded;

  final primaryColorCustomer = Colors.blue.shade600;
  final primaryColorAgen = Colors.teal.shade600;
  final lightColorCustomer = Colors.blue.shade100;
  final lightColoAgenr = Colors.teal.shade100;
  final redTextColor = Colors.redAccent.shade700;
  final greenTextColor = const Color(0xFF00933D);
  final FocusNode _nameFocusNode = FocusNode();
  bool _showCustomersTable = true; // متغير للتبديل بين الجداول
  bool _showBars = true;
  final ScrollController _scrollController = ScrollController();
  double _lastDirectionOffset = 0;
  ScrollDirection? _lastDirection;
  @override
  void initState() {
    super.initState();
    if (widget.customerName != null) {
      _nameController.text = widget.customerName!;
      acconutTeyp = widget.iscontun!;
      _showCustomersTable = acconutTeyp! ? true : false;
      _searchTransactionsAllCcunty();
    }

    _loadSavedData();
    _scrollController.addListener(_handleScroll);

    _nameFocusNode.addListener(() {
      if (_nameFocusNode.hasFocus) {
        _nameController.selection = TextSelection.fromPosition(
          TextPosition(offset: _nameController.text.length),
        );
      }
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

  /* ======================================= */
  //       $$$== استرجاع العمليات ==$$$
  /* ======================================= */

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
        _suggestedNamesAgent = [];
      });
      return;
    }

    final names = await DatabaseHelper().getAgentNames(query);
    setState(() {
      _suggestedNamesAgent = names;
    });
  }

  // استرجاع عمليات الحساباتء عبر الاسم
  Future<void> _searchTransactionsAllCcunty() async {
    final bool? isAconnt;
    final nameCless = widget.customerName;
    final String? name;

    double tupeAllMomnt = 0;
    if (widget.customerName == null) {
      name = _nameController.text;
      isAconnt = _showCustomersTable;
    } else {
      name = nameCless;
      isAconnt = widget.iscontun;
    }

    final databaseHelper = DatabaseHelper();
    List<Map<String, dynamic>> transactions = isAconnt!
        ? await databaseHelper.getOperationsByClientName(name!)
        : await databaseHelper.getOperationsByAgenntName(name!);

    // قائمة جديدة مع إضافة الرصيد المرحلي لكل عنصر
    List<Map<String, dynamic>> transactionsWithMoment = [];
    setState(() {
      transactions = transactions.reversed.toList();
    });

    for (var customer in transactions) {
      final typOutstanding = customer['type'] == 'تسديد';
      final outstanding = customer['amount'];

      if (!typOutstanding) {
        tupeAllMomnt += outstanding;
      } else {
        tupeAllMomnt -= outstanding;
      }
      // أضف الرصيد المرحلي للعنصر
      final customerWithMoment = {
        ...customer,
        'tupeAllMomnt': tupeAllMomnt,
      };
      transactionsWithMoment.add(customerWithMoment);
    }

    setState(() {
      _transactions = transactionsWithMoment.reversed.toList();
    });
    numberOperations = _transactions.length;
  }

  //    تحديث الواجهه  اعادة استرجاع العمليات
  void _refreshTransactions() async {
    _searchTransactionsAllCcunty();
  }

  /* ======================================= */
  //        $$$🔎🔎 بحث الحسابات 🔎🔎$$$
  /* ======================================= */

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
                  'بحث عن حساب  ',
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
                        color: primaryColorCustomer,
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showCustomersTable = true;

                          _toggleTable(true);

                          _showSearchAccountDialogBox();
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
                          Navigator.of(context).pop();
                          _showCustomersTable = false;
                          _showSearchAccountDialogBox();
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

  void _showSearchAccountDialogBox() {
    final iconFunction = _showCustomersTable ? iconCustomer : iconAgeen;

    final primaryColor =
        _showCustomersTable ? primaryColorCustomer : primaryColorAgen;
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
                                    _showCustomersTable
                                        ? 'بحث حساب عميل'
                                        : 'بحث حساب مورد',
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
                            child:
                                _buildClientNameFieldWithSuggestions(setState),
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

  //    انشاء الحقل والقائمة المشابهة للعميل
  Widget _buildClientNameFieldWithSuggestions(
      void Function(void Function()) setState) {
    final primaryColor =
        _showCustomersTable ? primaryColorCustomer : primaryColorAgen;
    final borderColor =
        _showCustomersTable ? primaryColorCustomer : primaryColorAgen;

    final iconFunction = _showCustomersTable ? iconCustomer : iconAgeen;
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10.0),
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: _showCustomersTable ? 'اسم العميل' : 'اسم المورد',
                labelStyle: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w600),
                prefixIcon: Icon(iconFunction,
                    color: _showCustomersTable
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
                      color: _showCustomersTable
                          ? primaryColorCustomer
                          : primaryColorAgen,
                      width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: _showCustomersTable
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
                  _showCustomersTable
                      ? _fetchSuggestedNames(value)
                      : _fetchSuggestedAgeentNames(value);
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
            const SizedBox(height: 180.0),
            _buildActionButton(
              label: 'بحث',
              icon: Icons.search_sharp,
              color: primaryColor,
              onPressed: () async {
                await _searchTransactionsAllCcunty(); // انتظار انتهاء البحث
                if (_transactions.isNotEmpty) {
                  if (!mounted) return;
                  Navigator.of(context).pop(); // إغلاق النافذة بعد البحث
                }
              },
            ),
          ],
        ),

        // قائمة العملاء المطابقة
        if (_suggestedNames.isNotEmpty)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 1.5),
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
                            horizontal: 16,
                          ),
                          title: Text(
                            _suggestedNames[index],
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
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
        // قائمة الموردين المطابقة
        if (_suggestedNamesAgent.isNotEmpty)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: _suggestedNamesAgent.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                          ),
                          title: Text(
                            _suggestedNamesAgent[index],
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _nameController.text =
                                  _suggestedNamesAgent[index];
                              _suggestedNamesAgent = [];
                            });
                          },
                        ),
                        if (index < _suggestedNamesAgent.length - 1)
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

/*    $$$✍✍ التحكم في العمليات ✍✍$$$
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
        // _refreshTransactions(); // تحديث البيانات بعد الحذف

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

  //    نافذة تفاصيل العملية
  void _buildTransactionDetailsDialog(Map<String, dynamic> transaction) {
    final isAconnt = _showCustomersTable;

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
    double totall = transaction['tupeAllMomnt'];

    final iconFunction = isAconnt ? iconCustomer : iconAgeen;
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
          _buildSummaryRow(
            'الرصيد بعد العملية',
            DatabaseHelper().getNumberFormat(totall),
            icon: transaction['type'] == 'تسديد'
                ? Icons.price_check_rounded
                : Icons.price_change_outlined,
            color: totall > 0 ? redTextColor : greenTextColor,
            valueColor: totall > 0
                ? redTextColor.withOpacity(0.2)
                : greenTextColor.withOpacity(0.3),
          ),
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
                          // _saveTtansaAccount = isAconnt;
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
      final isDebt = double.parse(summary['outstanding'].toString()) > 0;
      final isDebtCust =
          double.parse(summary['outstanding'].toString()) < 0 ? 'له' : 'علية';
      final isDebtAgnt =
          double.parse(summary['outstanding'].toString()) < 0 ? 'علية' : 'له';
      final isAconnt = _showCustomersTable;
      final iconFunction = isAconnt ? iconCustomer : iconAgeen;

      final colorFunction = isAconnt ? primaryColorCustomer : primaryColorAgen;
      if (!mounted) return;

      CustomDialog.show(
          context: context,
          headerColor: colorFunction,
          icon: isAconnt ? iconCustomer : iconAgeen,
          title: isAconnt ? 'تفاصيل العميل' : 'تفاصيل المورد',
          contentChildren: [
            const SizedBox(height: 8),
            _buildSummaryCard(
              icon: iconFunction,
              title: 'الاسم',
              value: name,
              color: isAconnt ? lightColorCustomer : lightColoAgenr,
              valueColor: isAconnt ? primaryColorCustomer : primaryColorAgen,
            ),
            const SizedBox(height: 8),
            _buildSummaryCard(
              icon: Icons.receipt_long_rounded,
              title: ' عدد العمليات ',
              value: numberOperations.toString(),
              color: isAconnt ? lightColorCustomer : lightColoAgenr,
              valueColor: isAconnt ? primaryColorCustomer : primaryColorAgen,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
                _showCustomersTable
                    ? 'اجمالي الديون'
                    : 'اجمالي القروض المستحقة',
                databaseHelper.getNumberFormat(summary['totalAdditions']),
                icon: Icons.add_circle_outline,
                color: redTextColor,
                valueColor: redTextColor.withOpacity(0.2)),
            const SizedBox(height: 8),
            _buildSummaryRow(
                _showCustomersTable
                    ? 'اجمالي التسديدات'
                    : 'اجمالي المدفوعات النقدية',
                databaseHelper.getNumberFormat(summary['totalPayments']),
                icon: Icons.remove_circle_outline,
                color: greenTextColor,
                valueColor: greenTextColor.withOpacity(0.3)),
            const SizedBox(height: 8),
            _buildSummaryRow(
              _showCustomersTable
                  ? 'اجمالي المستحق $isDebtCust'
                  : ' اجمالي المستحق $isDebtAgnt',
              databaseHelper.getNumberFormat(summary['outstanding']),
              icon: isDebt ? Icons.warning_amber : Icons.check_circle_outline,
              color: isDebt ? redTextColor : greenTextColor,
              valueColor: isDebt
                  ? redTextColor.withOpacity(0.2)
                  : greenTextColor.withOpacity(0.3),
              isBold: true,
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: _buildActionButton(
                label: 'إغلاق',
                icon: Icons.close,
                color: colorFunction,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ]);
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
            color:
                _showCustomersTable ? Colors.blue.shade400 : primaryColorAgen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color:
                  _showCustomersTable ? Colors.blue.shade400 : primaryColorAgen,
              width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color:
                  _showCustomersTable ? Colors.blue.shade400 : primaryColorAgen,
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

  // دالة مساعدة لإنشاء بطاقات الملخص
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
    bool isBold = false,
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

  Widget _buildTableCustomers() {
    final transactions = _transactions;

    return CustomerTable(
      one: false,
      shcerPage: true,
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
    final transactions = _transactions;

    return AgentTable(
      one: false,
      shcerPage: true,
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
          backgroundColor: Colors.cyan.shade600,
          resizeToAvoidBottomInset: false,
          appBar: acconutTeyp == null
              ? CustomAppBar(
                  title: 'كشوف الحسابات',
                  colorTitle: const Color(0xFF07BEAC),
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
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddTransactionPage(),
                      ),
                    );
                  },
                  icon2Press: Icons.account_balance_wallet,
                  color2Press: Colors.orange.shade700,
                )
              :
              // ====================================
              AppBar(
                  flexibleSpace: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF00B4D8), // أزرق سماوي متوسط
                          Color(0xFF008091), // أزرق مخضر داكن
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                  ),
                  title: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 10),
                    margin: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF07BEAC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.black.withOpacity(0.6), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'كشوف الحسابات',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  elevation: 3,
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
                acconutTeyp == null || _showSearchField
                    ? TabBarBody(
                        height: _showBars ? 55 : 0,
                        showSearchField: _showSearchField,

                        //  1
                        onBackPress: () {},
                        color1Press: _showCustomersTable
                            ? primaryColorCustomer
                            : const Color(0xABFFFFFF),
                        color1PressChildrn:
                            _showCustomersTable ? Colors.white : Colors.grey,

                        // 2
                        onBack2Press: () {},
                        color2Press: !_showCustomersTable
                            ? primaryColorAgen
                            : const Color(0xABFFFFFF),
                        color2PressChildrn:
                            !_showCustomersTable ? Colors.white : Colors.grey,

                        // 3
                        color3Press: const Color(0xFF07BEAC),
                        onBack3Press: () => _generatePDF(context),
                        icon3Press: Icons.print,
                        title: '  طباعه  ',
                        onBackShears: () {
                          setState(() {
                            _showSearchField = false;
                            _searchQuery = '';
                          });
                        },
                        onSearchChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        searchQuery: _searchQuery,
                      )
                    : AnimatedContainer(
                        width: double.infinity,
                        height: 55,
                        duration: const Duration(milliseconds: 300),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF59CEE3), // أزرق فاتح مائل للنعناع

                              Color(0xFF00B4D8), // أزرق سماوي متوسط
                              Color(0xFF008091), // أزرق مخضر داكن
                            ],
                            begin: Alignment.bottomRight,
                            end: Alignment.topLeft,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.only(right: 12),
                          alignment: Alignment.centerRight,
                          child: Text(
                            'كشف حساب ${_showCustomersTable ? 'العميل  : ' : 'المورد  : '} ${_nameController.text}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 4.0,
                                    color: Colors.black38,
                                  ),
                                ]),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ),
                _showCustomersTable
                    ? Expanded(child: _buildTableCustomers())
                    : Expanded(
                        child: _buildTableAgents(),
                      ),
              ],
            ),
          ), //  بار سفلي
          floatingActionButtonLocation:
              FloatingActionButtonLocation.miniCenterDocked,
          floatingActionButton: AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              child: acconutTeyp == null
                  ? _showBars
                      ? FloatingActionButton(
                          backgroundColor: const Color(0xFF07BEAC),
                          onPressed: () => _showSearchAccountDialog(),
                          elevation: 8,
                          child: const Icon(Icons.search,
                              color: Colors.white, size: 30),
                        )
                      : null
                  :
                  // SizedBox()

                  _showBars
                      ? FloatingActionButton(
                          backgroundColor: const Color(0xFF07BEAC),
                          onPressed: () => _generatePDF(context),
                          elevation: 8,
                          child: const Icon(Icons.print,
                              color: Colors.white, size: 30),
                        )
                      : null),
          bottomNavigationBar: ActionButtonL(
            showBars: _showBars,
            icon1Press: Icons.search_outlined,
            color1Press: const Color(0xFF07BEAC),
            onIcon1Press: () {
              setState(() {
                _showSearchField = !_showSearchField;
                _searchQuery = '';
              });
            },
            icon2Press: Icons.info_outline,
            color2Press:
                _showCustomersTable ? primaryColorCustomer : primaryColorAgen,
            onIcon2Press: _showCustomerDetails,
          ),
        ));
  }

  //  تغيير العرض
  void _toggleTable(bool showCustomers) {
    setState(() {
      _showCustomersTable = showCustomers;
    });
  }

  Future<void> _generatePDF(BuildContext context) async {
    final pdf = pw.Document();
    final databaseHelper = DatabaseHelper();
    String numAgen = _nameController.text;

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

    final dbHelper = DatabaseHelper();

    // إنشاء الرأس بشكل منفصل
    pw.Widget buildTableHeader() {
      return pw.Table(
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
              pw.Center(
                child: pw.Text('التاريخ',
                    style: pw.TextStyle(
                        font: arabicFont,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 16),
                    textDirection: pw.TextDirection.rtl),
              ),
              pw.Center(
                child: pw.Text('الرصيد التراكمي',
                    style: pw.TextStyle(
                        font: arabicFont,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 16),
                    textDirection: pw.TextDirection.rtl),
              ),
              pw.Center(
                child: pw.Text('المبلغ',
                    style: pw.TextStyle(
                        font: arabicFont,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 16),
                    textDirection: pw.TextDirection.rtl),
              ),
              pw.Center(
                child: pw.Text('التفاصيل',
                    style: pw.TextStyle(
                        font: arabicFont,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 16),
                    textDirection: pw.TextDirection.rtl),
              ),
            ],
          ),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
          margin: const pw.EdgeInsets.all(10),
          pageFormat: PdfPageFormat.a4,
          maxPages: 30,
          header: (context) {
            return pw.Column(
              children: [
                if (context.pageNumber == 1)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 2),
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
                                pw.Text('Report of Operations',
                                    style: const pw.TextStyle(fontSize: 16),
                                    textDirection: pw.TextDirection.ltr),
                                pw.SizedBox(height: 8),
                                pw.Text(phoneNumber,
                                    style: const pw.TextStyle(fontSize: 13),
                                    textDirection: pw.TextDirection.ltr),
                                pw.SizedBox(height: 8),
                                pw.Text(dbHelper.getFormattedDate(),
                                    style: const pw.TextStyle(fontSize: 13),
                                    textDirection: pw.TextDirection.ltr),
                              ],
                            ),
                            pw.Text('كشف حساب تفصيلي',
                                style: pw.TextStyle(
                                    font: arabicFont,
                                    fontSize: 20,
                                    color: PdfColors.red,
                                    fontWeight: pw.FontWeight.bold),
                                textDirection: pw.TextDirection.rtl),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text(name,
                                    style: pw.TextStyle(
                                        font: arabicFont, fontSize: 16),
                                    textDirection: pw.TextDirection.rtl),
                                pw.SizedBox(height: 8),
                                pw.Text(serviceType,
                                    style: pw.TextStyle(
                                        font: arabicFont, fontSize: 13),
                                    textDirection: pw.TextDirection.rtl),
                                pw.SizedBox(height: 8),
                                pw.Text(address,
                                    style: pw.TextStyle(
                                        font: arabicFont, fontSize: 13),
                                    textDirection: pw.TextDirection.rtl),
                              ],
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 10),
                        pw.Divider(thickness: 2),
                        pw.SizedBox(height: 10),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Text(numAgen,
                                style: pw.TextStyle(
                                    font: arabicFont,
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold),
                                textDirection: pw.TextDirection.rtl),
                            pw.Text(numShwo,
                                style: pw.TextStyle(
                                    font: arabicFont,
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold),
                                textDirection: pw.TextDirection.rtl),
                          ],
                        ),
                        pw.SizedBox(height: 10),
                      ],
                    ),
                  ),
                pw.Center(
                  child: pw.Text('الصفحة : ${context.pageNumber}',
                      style: pw.TextStyle(font: arabicFont, fontSize: 12),
                      textDirection: pw.TextDirection.rtl),
                ),
                pw.SizedBox(height: 10),

                buildTableHeader(), // رأس الجدول
              ],
            );
          },
          build: (context) {
            List<pw.Widget> content = [];

            // جدول العمليات
            content.add(
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

                  return pw.TableRow(
                    children: [
                      pw.Center(
                        child: pw.Text(
                          transaction['date'].split(' ')[0],
                          style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                      pw.Center(
                        child: pw.Text(
                          databaseHelper
                              .getNumberFormat(transaction['tupeAllMomnt']),
                          style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 14,
                              color: transaction['tupeAllMomnt'] > 0
                                  ? PdfColors.red
                                  : PdfColors.green),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                      pw.Center(
                        child: pw.Text(
                          databaseHelper.getNumberFormat(transaction['amount']),
                          style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 14,
                              color:
                                  isAddition ? PdfColors.red : PdfColors.green),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(right: 5),
                        child: pw.Text(
                          transaction['details'],
                          style: pw.TextStyle(font: arabicFont, fontSize: 14),
                          textDirection: pw.TextDirection.rtl,
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );

            return content;
          },
          footer: (context) => context.pageNumber == context.pagesCount
              ? pw.Container(
                  alignment: pw.Alignment.bottomCenter,
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Table(
                    border:
                        pw.TableBorder.all(color: PdfColors.black, width: 1),
                    children: [
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          pw.Center(
                            child: pw.Text('إجمالي الديون',
                                style: pw.TextStyle(
                                    font: arabicFont,
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 14),
                                textDirection: pw.TextDirection.rtl),
                          ),
                          pw.Center(
                            child: pw.Text('إجمالي المسددة',
                                style: pw.TextStyle(
                                    font: arabicFont,
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 14),
                                textDirection: pw.TextDirection.rtl),
                          ),
                          pw.Center(
                            child: pw.Text('المبلغ المستحق',
                                style: pw.TextStyle(
                                    font: arabicFont,
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 14),
                                textDirection: pw.TextDirection.rtl),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Center(
                            child: pw.Text(totalAdditions.toString(),
                                style: pw.TextStyle(
                                    font: arabicFont,
                                    fontSize: 14,
                                    color: PdfColors.red700),
                                textDirection: pw.TextDirection.rtl),
                          ),
                          pw.Center(
                            child: pw.Text(totalPayments.toString(),
                                style: pw.TextStyle(
                                    font: arabicFont,
                                    fontSize: 14,
                                    color: PdfColors.green),
                                textDirection: pw.TextDirection.rtl),
                          ),
                          pw.Center(
                            child: pw.Text(outstanding.toString(),
                                style: pw.TextStyle(
                                    font: arabicFont,
                                    fontSize: 14,
                                    color: PdfColors.blue),
                                textDirection: pw.TextDirection.rtl),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : pw.SizedBox(
                  child: pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        pw.Text('$numShwo $numAgen',
                            style: pw.TextStyle(
                                font: arabicFont,
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold),
                            textDirection: pw.TextDirection.rtl),
                        pw.SizedBox(width: 20),
                        pw.Text('طبع بواسطة تطبيق حساباتي',
                            style: pw.TextStyle(
                                font: arabicFont,
                                color: PdfColors.cyan,
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold),
                            textDirection: pw.TextDirection.rtl),
                      ],
                    ),
                  ),
                )),
    );

    // حفظ الملف مؤقتًا في التخزين
    final output = await getTemporaryDirectory();
    final filePath = '${output.path}/transactions_report.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // عرض الملف داخل التطبيق
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(filePath: filePath),
      ),
    );
  }

  bool _showSearchField = false;
  String _searchQuery = '';

// ==================================
}
