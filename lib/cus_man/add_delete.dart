// ==============Asmael Asid ====================================

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../database/database_helper.dart';
import 'add_transaction.dart';
import 'search.dart';

class AddDeletePage extends StatefulWidget {
  const AddDeletePage({super.key});

  @override
  State<AddDeletePage> createState() => _AddDeletePageState();
}

class _AddDeletePageState extends State<AddDeletePage> {
  // حقول الادخال
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  //  كلاس قاعدة البيانات
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // قوائم  لتخزين الاسماء وترتيبها
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _originalCustomers = [];
  List<Map<String, dynamic>> _originalAgents = [];

  // قوائم لتخزين المبالغ
  final Map<int, double> _customerOutstanding = {};
  final Map<int, double> _agentOutstanding = {};

  // ===================================
  // التحكم في عرض واجهات الاخراج     =
  String _selectedView = 'customers'; // =
  bool _showBars = true;
  final PageController _pageControllerTwo = PageController(initialPage: 0);
  // التحكم في عرض واجهات الادخال   =
  bool _saveAccount = true; //  =
  // ===================================

  //    حقل البحث
  bool _showSearchField = false;
  String _searchQuery = '';

  //  اختيار ترتيب الاسماء
  String _sortBy = 'افتراضي';

  // المتغيرات لك وعليك من المستحق
  double onMyCou = 0;
  double toMyCou = 0;
  double onMyAgn = 0;
  double toMyAgn = 0;

  //   تفاعلات الواجهة
  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadAgents();
    _sortBy = 'الافتراضي';

    _pageControllerTwo.addListener(() {
      setState(() {
        _selectedView = _pageControllerTwo.page! < 0.3 ? 'customers' : 'agents';
      });
    });
  }

  //  نقل المواشر الى اخر حرف
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  // تحميل العملاء
  void _loadCustomers() async {
    final data = await _dbHelper.getAllCustomers();

    // تخزين المبالغ
    for (var customer in data) {
      final summary = await _dbHelper.getSummaryByName(customer['name']);

      _customerOutstanding[customer['id']] = summary['outstanding'];

      if (summary['outstanding'] > 0) {
        final addOutstanding = summary['outstanding'];
        toMyCou += addOutstanding;
      } else if (summary['outstanding'] < 0) {
        final payOutstanding = summary['outstanding'];
        onMyCou += payOutstanding;
      }
    }

    setState(() {
      _customers = data;
      _originalCustomers = List.from(data); // حفظ نسخة أصلية
    });
  }

  // تحميل الموردين
  void _loadAgents() async {
    final data = await _dbHelper.getAllAgents();

    // تخزين المبالغ
    for (var agent in data) {
      final summary = await _dbHelper.getSummaryAgeentByName(agent['name']);
      _agentOutstanding[agent['id']] = summary['outstanding'];
      if (summary['outstanding'] > 0) {
        final addOutstanding = summary['outstanding'];
        toMyAgn += addOutstanding;
      } else if (summary['outstanding'] < 0) {
        final payOutstanding = summary['outstanding'];
        onMyAgn += payOutstanding;
      }
    }

    setState(() {
      _agents = data;
      _originalAgents = List.from(data); // حفظ نسخة أصلية
    });
  }

// اضافة حساب
  void _showAddAccountDialog() {
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
                          _saveAccount = true;

                          Navigator.pop(context);
                          _showAddCustomerDialog();
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
                          _saveAccount = false;

                          Navigator.pop(context);
                          _showAddCustomerDialog();
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

// إضافة حساب عميل او المور
  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: const Color(0xFFEEEBEB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            insetPadding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _saveAccount
                            ? [Colors.blue.shade700, Colors.blue.shade500]
                            : [Colors.orange.shade700, Colors.orange.shade500],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                            _saveAccount
                                ? Icons.person_add_alt_1
                                : Icons.add_business_rounded,
                            size: 25,
                            color: Colors.white),
                        Text(
                          _saveAccount ? 'إضافة عميل جديد' : 'إضافة مورد جديد',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Fields
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInputField(
                          controller: _nameController,
                          label: 'الاسم الكامل',
                          icon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () =>
                              FocusScope.of(context).nextFocus(),
                        ),
                        const SizedBox(height: 18),
                        _buildInputField(
                          controller: _phoneController,
                          label: 'رقم الهاتف',
                          icon: Icons.phone_android,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onEditingComplete: () =>
                              FocusScope.of(context).unfocus(),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 3,
                    color: _saveAccount
                        ? Colors.blue.shade700
                        : Colors.orange.shade700,
                  ),
                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: 'الغاء',
                            icon: Icons.close,
                            color: Colors.red.shade600,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            label: _saveAccount ? 'حفظ العميل' : 'حفظ المورد',
                            icon: Icons.save,
                            color: Colors.green.shade600,
                            onPressed:
                                _saveAccount ? _saveCustomer : _saveAgent,
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
        );
      },
    ).then((_) {
      _nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nameController.text.length),
      );
    });
  }

// حفظ حساب عميل
  void _saveCustomer() async {
    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      final nuem = _nameController.text;

      await _dbHelper.insertCustomer(
        nuem,
        _phoneController.text,
      );

      _nameController.clear();
      _phoneController.clear();
      _showSuccessMessage('تم حفظ العميل بنجاح');
      _loadCustomers();
      if (_selectedView != 'customers') {
        _pageControllerTwo.animateToPage(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      }
    } else {
      _showErrorMessage('يرجى إدخال جميع البيانات');
    }
    if (!mounted) return;

    Navigator.pop(context);
  }

// حفظ حساب المور
  void _saveAgent() async {
    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      final nuem = _nameController.text;

      await _dbHelper.insertAgent(
        nuem,
        _phoneController.text,
      );
      _nameController.clear();
      _phoneController.clear();
      _showSuccessMessage('تم حفظ الوكيل بنجاح');
      _loadAgents();
      if (_selectedView == 'customers') {
        _pageControllerTwo.animateToPage(1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      }
    } else {
      _showErrorMessage('يرجى إدخال جميع البيانات');
    }
    if (!mounted) return;

    Navigator.pop(context);
  }

// حذف حساب عميل
  void _deleteCustomer(int id) async {
    await _dbHelper.deleteCustomer(id);
    _showSuccessMessage('تم حذف العميل بنجاح');
    _loadCustomers();
  }

// حذف حساب المور
  void _deleteAgent(int id) async {
    await _dbHelper.deleteAgent(id);
    _showSuccessMessage('تم حذف الوكيل بنجاح');
    _loadAgents();
  }

// تعديل حساب عميل
  void _updateCustomer(int id, String name, String phone) async {
    _nameController.text = name;
    _phoneController.text = phone;

    showDialog(
      context: context,
      builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: const Color(0xFFEEEBEB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            insetPadding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  child: Column(children: const [
                    Icon(Icons.person_add_disabled,
                        size: 25, color: Colors.white),
                    Text(
                      'تعديل بيانات عميل',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ]),
                ),
                Container(
                  width: double.infinity,
                  height: 3,
                  color: Colors.blue,
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10.0),
                      _buildInputField(
                        controller: _nameController,
                        label: 'الاسم',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () =>
                            FocusScope.of(context).nextFocus(),
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: _phoneController,
                        label: 'رقم الهاتف',
                        icon: Icons.phone_android,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () =>
                            FocusScope.of(context).unfocus(),
                      ),
                      const SizedBox(height: 10.0),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 3,
                  color: Colors.blue,
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: _buildActionButton(
                        label: 'إغلاق',
                        icon: Icons.close,
                        color: Colors.red.shade600,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 20.0),
                    Expanded(
                        child: _buildActionButton(
                      label: 'حفظ',
                      icon: Icons.save_as_outlined,
                      color: Colors.green.shade600,
                      onPressed: () {
                        Navigator.pop(context);
                        _dbHelper.updateCustomer(
                          id,
                          _nameController.text,
                          _phoneController.text,
                        );
                        _showSuccessMessage('تم تعديل بيانات العميل بنجاح');
                        _loadCustomers();
                      },
                    )),
                    const SizedBox(width: 10.0),
                  ],
                ),
                const SizedBox(height: 10.0),
              ],
            )),
          )),
    );
  }

// تعديل حساب المور
  void _updateAgent(int id, String name, String phone) async {
    _nameController.text = name;
    _phoneController.text = phone;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: const Color(0xFFEEEBEB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                child: Column(children: const [
                  Icon(Icons.store_mall_directory_outlined,
                      size: 25, color: Colors.white),
                  Text(
                    'تعديل بيانات وكيل',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
              Container(
                width: double.infinity,
                height: 3,
                color: Colors.orange,
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10.0),
                    _buildInputField(
                      controller: _nameController,
                      label: 'الاسم',
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _phoneController,
                      label: 'رقم الهاتف',
                      icon: Icons.phone_android,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onEditingComplete: () => FocusScope.of(context).unfocus(),
                    ),
                    const SizedBox(height: 10.0),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                height: 3,
                color: Colors.orange,
              ),
              Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: _buildActionButton(
                          label: 'إغلاق',
                          icon: Icons.close,
                          color: Colors.red.shade600,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 20.0),
                      Expanded(
                          child: _buildActionButton(
                        label: 'حفظ',
                        icon: Icons.save_as_outlined,
                        color: Colors.green.shade600,
                        onPressed: () {
                          Navigator.pop(context);
                          _dbHelper.updateAgent(
                            id,
                            _nameController.text,
                            _phoneController.text,
                          );
                          _showSuccessMessage('تم تعديل بيانات الوكيل بنجاح');
                          _loadAgents();
                        },
                      )),
                      const SizedBox(width: 10.0),
                    ],
                  )),
            ],
          )),
        ),
      ),
    );
  }

//  نافذة  ملخص العملاء او الموردين
  void _showTotalSummaryDialog() async {
    final summary = _selectedView == 'customers'
        ? await _dbHelper.getTotalSummary()
        : await _dbHelper.getTotalAgeensSummary();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        final outstanding = summary['totalOutstanding']!.toDouble();
        final isDebt = outstanding > 0;
        final isCredit = outstanding < 0;

        final textColor = isDebt
            ? Colors.red.shade700
            : isCredit
                ? Colors.green.shade700
                : Colors.grey.shade800;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _selectedView == 'customers'
                            ? [Colors.blue.shade700, Colors.blue.shade500]
                            : [Colors.orange.shade700, Colors.orange.shade500],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                            _selectedView == 'customers'
                                ? Icons.person_outline
                                : Icons.business,
                            size: 32,
                            color: Colors.white),
                        // const SizedBox(height: 4),
                        Text(
                          _selectedView == 'customers'
                              ? 'تفاصيل حسابات العملاء'
                              : ' تفاصيل حسابات الموردين',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'عدد الحسابات :  ${summary['totalCustomers']} ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Summary Cards
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildSummaryCard(
                          icon: _selectedView == 'customers'
                              ? Icons.monetization_on_rounded
                              : Icons.money_rounded,
                          title: _selectedView == 'customers'
                              ? 'اجمالي الديون'
                              : 'اجمالي القروض المستحقة',
                          value: _dbHelper
                              .getNumberFormat(summary['totalAdditions']),
                          color: Colors.red.shade100,
                          valueColor: Colors.red.shade700,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryCard(
                          icon: _selectedView == 'customers'
                              ? Icons.money_off_csred
                              : Icons.monetization_on_rounded,
                          title: 'اجمالي المدفوعات النقدية',
                          value: _dbHelper
                              .getNumberFormat(summary['totalPayments']),
                          color: Colors.green.shade100,
                          valueColor: Colors.green.shade700,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: isDebt
                                ? Colors.red.shade100
                                : isCredit
                                    ? Colors.green.shade100
                                    : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _selectedView == 'customers'
                                    ? Colors.blue
                                    : Colors.orange.shade400,
                                width: 2),
                          ),
                          child: _buildSummaryCard(
                            icon: isDebt
                                ? Icons.warning_amber
                                : isCredit
                                    ? Icons.info_outline
                                    : Icons.no_meeting_room_rounded,
                            title: _selectedView == 'customers'
                                ? isDebt
                                    ? 'المبلغ المستحق  على العملاء'
                                    : isCredit
                                        ? 'المبلغ المستحق للعملاء عليك'
                                        : 'لا يوجد مستحقات'
                                : isCredit
                                    ? 'المبلغ المستحق لك من الموردين'
                                    : isDebt
                                        ? 'المبلغ المستحق  عليك  للموردين'
                                        : 'لا يوجد مستحقات',
                            value: _dbHelper.getNumberFormat(outstanding),
                            color: isDebt
                                ? Colors.red.shade100
                                : isCredit
                                    ? Colors.green.shade100
                                    : Colors.grey.shade300,
                            valueColor: textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                icon: Icons.remove_circle,
                                title: 'عليك من المستحق',
                                value: _dbHelper.getNumberFormat(
                                    _selectedView == 'customers'
                                        ? onMyCou
                                        : toMyAgn),
                                color: Colors.red.shade100,
                                valueColor: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSummaryCard(
                                icon: Icons.add_circle,
                                title: 'لك من المستحق',
                                value: _dbHelper.getNumberFormat(
                                    _selectedView == 'customers'
                                        ? toMyCou
                                        : onMyAgn),
                                color: Colors.green.shade100,
                                valueColor: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildActionButton(
                      label: 'إغلاق',
                      icon: Icons.close,
                      color: _selectedView == 'customers'
                          ? Colors.blue.shade600
                          : Colors.orange.shade600,
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

// نافذة تفاصيل  العميل او المور
  void _showCustomerDetails(String name, String phone, int id) async {
    final summary = _selectedView == 'customers'
        ? await _dbHelper.getSummaryByName(name)
        : await _dbHelper.getSummaryAgeentByName(name);
    if (!mounted) return;

/* 
                        *
                          * 
                            * 
                              * 
                                * 
                      أكبر       *
                                *
                              * 
                            * 
                          * 
                        * 
                                  *
                                *
                              * 
                            * 
                          * 
                اصغر    * 
                          *
                            * 
                              * 
                                * 
                                  * 
                            

 */

    showDialog(
      context: context,
      builder: (context) {
        final isDebt = double.parse(summary['outstanding'].toString()) > 0;
        final isDebtCust =
            double.parse(summary['outstanding'].toString()) < 0 ? 'له' : 'علية';
        final isDebtAgnt =
            double.parse(summary['outstanding'].toString()) < 0 ? 'علية' : 'له';

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
                  // Header
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 12), // تقليل الحشو
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _selectedView == 'customers'
                            ? [Colors.blue.shade700, Colors.blue.shade500]
                            : [Colors.orange.shade700, Colors.orange.shade500],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                            _selectedView == 'customers'
                                ? Icons.person_outline
                                : Icons.business,
                            size: 32,
                            color: Colors.white), // تصغير الأيقونة
                        const SizedBox(height: 4), // تقليل المسافة
                        Text(
                          _selectedView == 'customers'
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

                  // Customer
                  Padding(
                    padding: const EdgeInsets.all(12), // تقليل الهوامش الداخلية
                    child: Column(
                      children: [
                        _buildInfoCard(
                          icon: Icons.person,
                          title: 'الاسم',
                          value: name,
                          color: Colors.blue.shade100,
                        ),
                        const SizedBox(height: 8), // تقليل المسافة بين البطاقات
                        _buildInfoCard(
                          icon: Icons.phone,
                          title: 'الهاتف',
                          value: phone,
                          color: Colors.green.shade100,
                        ),
                      ],
                    ),
                  ),

                  // Financial Summary
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
                          _selectedView == 'customers'
                              ? 'اجمالي الديون'
                              : 'اجمالي القروض المستحقة',
                          _dbHelper.getNumberFormat(summary['totalAdditions']),
                          icon: Icons.add_circle_outline,
                          color: Colors.red,
                        ),
                        Divider(
                            height: 1,
                            color: Colors.grey.shade300,
                            thickness: 0.5), // خط فاصل أرفع
                        _buildSummaryRow(
                          'اجمالي المدفوعات النقدية',
                          // 'كل التسديدات',
                          _dbHelper.getNumberFormat(summary['totalPayments']),
                          icon: Icons.remove_circle_outline,
                          color: Colors.green,
                        ),
                        Divider(
                            height: 1,
                            color: Colors.grey.shade300,
                            thickness: 0.5),
                        _buildSummaryRow(
                          _selectedView == 'customers'
                              ? 'اجمالي المستحق $isDebtCust' //
                              : ' اجمالي المستحق $isDebtAgnt',
                          _dbHelper.getNumberFormat(summary['outstanding']),
                          icon: isDebt
                              ? Icons.warning_amber
                              : Icons.check_circle_outline,
                          color: isDebt ? Colors.red : Colors.green,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.all(12), // تقليل الهوامش
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: 'حذف',
                            icon: Icons.delete,
                            color: Colors.red.shade600,
                            onPressed: () {
                              Navigator.of(context).pop();
                              _selectedView == 'customers'
                                  ? _deleteCustomer(id)
                                  : _deleteAgent(id);
                            },
                          ),
                        ),
                        const SizedBox(width: 8), // تقليل المسافة بين الأزرار
                        Expanded(
                          child: _buildActionButton(
                            label: 'تعديل',
                            icon: Icons.edit,
                            color: Colors.orange.shade600,
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (_selectedView == 'customers') {
                                _saveAccount = true;

                                _updateCustomer(id, name, phone);
                              } else {
                                _saveAccount = false;

                                _updateAgent(id, name, phone);
                              }
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

//  تنفيذ الترتيب
  void _applySorting() {
    setState(() {
      _customers = List.from(_originalCustomers);
      _agents = List.from(_originalAgents);

      if (_sortBy == 'الاسم من أ-ي') {
        // الترتيب حسب الاسم من الألف إلى الياء
        _customers.sort((a, b) => a['name'].compareTo(b['name']));
        _agents.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (_sortBy == 'الأحدث أولاً') {
        // الترتيب حسب الأحدث أولاً (حسب ID)
        _customers.sort((a, b) => b['id'].compareTo(a['id']));
        _agents.sort((a, b) => b['id'].compareTo(a['id']));
      } else if (_sortBy == 'المبلغ الأكبر أولاً') {
        // الترتيب حسب المبلغ الأكبر أولاً
        _customers.sort((a, b) {
          final outstandingA = _customerOutstanding[a['id']] ?? 0.0;
          final outstandingB = _customerOutstanding[b['id']] ?? 0.0;
          return outstandingB.compareTo(outstandingA); // ترتيب تنازلي
        });

        _agents.sort((a, b) {
          final outstandingA = _agentOutstanding[a['id']] ?? 0.0;
          final outstandingB = _agentOutstanding[b['id']] ?? 0.0;
          return outstandingB.compareTo(outstandingA); // ترتيب تنازلي
        });
      }
    });
  }

//  اختيار الترتيب
  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String tempSortBy = _sortBy; // تخزين مؤقت للاختيار الحالي

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                  backgroundColor: const Color(0xFFEEEBEB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: SingleChildScrollView(
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
                            'ترتيب حسب',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(16.0),
                            child: Column(children: [
                              _buildSortOption(
                                context,
                                title: 'الاسم من أ-ي',
                                icon: Icons.sort_by_alpha,
                                isActive: tempSortBy == 'الاسم من أ-ي',
                                onTap: () {
                                  setStateDialog(
                                      () => tempSortBy = 'الاسم من أ-ي');
                                },
                              ),
                              _buildSortOption(
                                context,
                                title: 'الأحدث أولاً',
                                icon: Icons.access_time,
                                isActive: tempSortBy == 'الأحدث أولاً',
                                onTap: () {
                                  setStateDialog(
                                      () => tempSortBy = 'الأحدث أولاً');
                                },
                              ),
                              _buildSortOption(
                                context,
                                title: 'المبلغ الأكبر أولاً',
                                icon: Icons.monetization_on_outlined,
                                isActive: tempSortBy == 'المبلغ الأكبر أولاً',
                                onTap: () {
                                  setStateDialog(
                                      () => tempSortBy = 'المبلغ الأكبر أولاً');
                                },
                              ),
                              _buildSortOption(
                                context,
                                title: 'الافتراضي',
                                icon: Icons.restore,
                                isActive: tempSortBy == 'الافتراضي',
                                onTap: () {
                                  setStateDialog(
                                      () => tempSortBy = 'الافتراضي');
                                },
                              ),
                            ])),
                        const SizedBox(height: 10.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: _buildActionButton(
                                label: 'إغلاق',
                                icon: Icons.close,
                                color: Colors.red.shade600,
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            const SizedBox(width: 20.0),
                            Expanded(
                              child: _buildActionButton(
                                label: 'حفظ الترتيب',
                                icon: Icons.save,
                                color: Colors.green.shade600,
                                onPressed: () {
                                  setState(() {
                                    _sortBy = tempSortBy;
                                    _applySorting();
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            const SizedBox(width: 10.0),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                      ],
                    ),
                  )),
            );
          },
        );
      },
    );
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

//  فشل العملية
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
                _saveAccount ? Colors.blue.shade400 : Colors.orange.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color:
                  _saveAccount ? Colors.blue.shade400 : Colors.orange.shade400,
              width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color:
                  _saveAccount ? Colors.blue.shade400 : Colors.orange.shade400,
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

  // دالة مساعدة   لإنشاء بطاقات المعلومات
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10), // تقليل الحشو الداخلي
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10), // زوايا أقل استدارة
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue.shade800), // تصغير الأيقونة
          const SizedBox(width: 8), // تقليل المسافة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13, // تصغير حجم الخط
                    color: Colors.blue.shade800,
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

  // دالة مساعدة   لإنشاء صفوف الملخص المالي
  Widget _buildSummaryRow(
    String label,
    String value, {
    required IconData icon,
    required Color color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 8, horizontal: 12), // تقليل الحشو
      child: Row(
        children: [
          Icon(icon, size: 20, color: color), // تصغير الأيقونة
          const SizedBox(width: 8), // تقليل المسافة
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14, // تصغير حجم الخط
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14, // تصغير حجم الخط
              fontWeight: FontWeight.w700,
              fontFamily: 'Amiri',

              color: color,
            ),
          ),
        ],
      ),
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

  // دالة مساعدة لإنشاء بطاقات الملخص (بنفس نمط الدوال السابقة)
  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: valueColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                    fontFamily: 'Amiri',
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

  //  انشا رائس الصفحة
  AppBar _buildAppBar() {
    return AppBar(
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade600,
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
          ' إدارة الحسابات   ',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16.0,
            color: Colors.white,
          ),
        ),
      ),
      backgroundColor: const Color(0xFF008091),
      elevation: 0,
      leading: _buildActionButtonTow(
        icon: Icons.home,
        color: Colors.cyan,
        onTap: () {
          Navigator.of(context).pop();
        },
      ),
      actions: [
        _buildActionButtonTow(
          icon: Icons.account_balance_wallet,
          color: Colors.orange.shade700,
          onTap: () {
            Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTransactionPage(),
              ),
            );
          },
        ),
        _buildActionButtonTow(
          icon: Icons.search_rounded,
          color: Colors.green,
          onTap: () {
            Navigator.of(context).pop();

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

  // انشا صندوق التحكم
  Widget _buildToolbar() {
    return SingleChildScrollView(
        child: Container(
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
      padding: _showSearchField
          ? const EdgeInsets.all(2)
          : const EdgeInsets.symmetric(vertical: 4),
      margin: const EdgeInsets.fromLTRB(30, 6, 30, 0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showSearchField ? _buildSearchField() : _buildActions(),
      ),
    ));
  }

  // حقل البحث
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
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
                      _showSearchField = false;
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

  // ايقونات التحكم
  Widget _buildActions() {
    return Row(
      mainAxisAlignment: _showSearchField
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceAround,
      children: [
        GestureDetector(
          onTap: () => _showSortDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.cyan,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: const [
                Icon(
                  Icons.sort_by_alpha,
                  color: Colors.white,
                  size: 28,
                ),
                Text(
                  'ترتيب',
                  style: TextStyle(
                    fontSize: 10.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => {
            _pageControllerTwo.animateToPage(0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut),
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: _selectedView == 'customers'
                  ? Colors.blue
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
                      _selectedView == 'customers' ? Colors.white : Colors.grey,
                  size: 28,
                ),
                Text(
                  'العملاء',
                  style: TextStyle(
                    fontSize: 10.0,
                    color: _selectedView == 'customers'
                        ? Colors.white
                        : Colors.grey,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => {
            _pageControllerTwo.animateToPage(1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut),
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: _selectedView == 'agents'
                  ? Colors.orange
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
                  color: _selectedView == 'agents' ? Colors.white : Colors.grey,
                  size: 28,
                ),
                Text(
                  'الموردين',
                  style: TextStyle(
                    fontSize: 9.5,
                    color:
                        _selectedView == 'agents' ? Colors.white : Colors.grey,
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

  //  ايقونات الرائس والفوتر
  Widget _buildActionButtonTow({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: color,
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
          icon: Icon(icon, color: Colors.white, size: 25),
          onPressed: onTap,
        ),
      ),
    );
  }

  //  انشا ايقونات الترتيب
  Widget _buildSortOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.cyan.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.cyan.shade400 : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.cyan : Colors.black),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
                    color: isActive ? Colors.cyan : Colors.black,
                  )),
            ),
            if (isActive)
              const Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
                size: 30,
              ),
          ],
        ),
      ),
    );
  }

  //  جدول العملاء
  Widget _buildTableCustomers() {
    final originalData = _customers;
    final filteredList = originalData
        .where((item) =>
            item['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final primaryColor = Colors.blue.shade700;
    final lightColor = Colors.blue.shade100;

    return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is UserScrollNotification) {
            if (notification.direction == ScrollDirection.reverse &&
                _showBars) {
              setState(() => _showBars = false);
            } else if (notification.direction == ScrollDirection.forward &&
                !_showBars) {
              setState(() => _showBars = true);
            }
          }
          return true;
        },
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: primaryColor.withOpacity(0.8), width: 2),
          ),
          margin: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0.0),
          child: Column(children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Expanded(
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      'الاسم',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'المستحق لك',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
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

            // Table Body
            Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'لا توجد بيانات متاحة',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          final outstanding =
                              _customerOutstanding[item['id']] ?? 0.0;
                          final textColor = outstanding > 0
                              ? Colors.red.shade700
                              : outstanding < 0
                                  ? Colors.green.shade700
                                  : Colors.grey.shade800;
                          return Container(
                              decoration: BoxDecoration(
                                color: index % 2 == 0
                                    ? Colors.white
                                    : lightColor.withOpacity(0.3),
                                border: Border(
                                  bottom: BorderSide(
                                    color: primaryColor.withOpacity(0.8),
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  _showCustomerDetails(
                                      item['name'], item['phone'], item['id']);
                                },
                                child: Row(
                                  children: [
                                    // Info Button
                                    Expanded(
                                      child: Icon(
                                        Icons.info_outline_rounded,
                                        color: primaryColor,
                                      ),
                                    ),

                                    // Name
                                    Expanded(
                                      flex: 5,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 8),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            left: BorderSide(
                                              color:
                                                  primaryColor.withOpacity(0.8),
                                              width: 2.0,
                                            ),
                                            right: BorderSide(
                                              color:
                                                  primaryColor.withOpacity(0.8),
                                              width: 2.0,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          textAlign: TextAlign.start,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    // Outstanding Amount
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        _dbHelper.getNumberFormat(outstanding),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'Amiri',
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ));
                        })),
          ]),
        ));
  }

  //  جدول الموردين
  Widget _buildTableAgents() {
    final originalData = _agents;
    final filteredList = originalData
        .where((item) =>
            item['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final primaryColor = Colors.orange.shade700;
    final lightColor = Colors.orange.shade100;
    return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is UserScrollNotification) {
            if (notification.direction == ScrollDirection.reverse &&
                _showBars) {
              setState(() => _showBars = false);
            } else if (notification.direction == ScrollDirection.forward &&
                !_showBars) {
              setState(() => _showBars = true);
            }
          }
          return true;
        },
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
            child: Column(children: [
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Expanded(
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(
                        'الاسم',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'المستحق عليك',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
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

              // Table Body
              Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'لا توجد بيانات متاحة',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            final outstanding =
                                _agentOutstanding[item['id']] ?? 0.0;
                            final textColor = outstanding > 0
                                ? Colors.red.shade700
                                : outstanding < 0
                                    ? Colors.green.shade700
                                    : Colors.grey.shade800;
                            return Container(
                                decoration: BoxDecoration(
                                  color: index % 2 == 0
                                      ? Colors.white
                                      : lightColor.withOpacity(0.3),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: primaryColor.withOpacity(0.8),
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    _showCustomerDetails(item['name'],
                                        item['phone'], item['id']);
                                  },
                                  child: Row(
                                    children: [
                                      // Info Button
                                      Expanded(
                                        child: Icon(
                                          Icons.info_outline_rounded,
                                          color: primaryColor,
                                        ),
                                      ),

                                      // Name
                                      Expanded(
                                        flex: 5,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 8),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                color: primaryColor
                                                    .withOpacity(0.8),
                                                width: 2.0,
                                              ),
                                              right: BorderSide(
                                                color: primaryColor
                                                    .withOpacity(0.8),
                                                width: 2.0,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            item['name'],
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            textAlign: TextAlign.start,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      // Outstanding Amount
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          _dbHelper
                                              .getNumberFormat(outstanding),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Amiri',
                                            fontWeight: FontWeight.w800,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ));
                          })),
            ])));
  }

  // الواجهه
  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
            backgroundColor: Colors.cyan.shade400,
            resizeToAvoidBottomInset: false,
            appBar: _buildAppBar(),
            body: Column(
              children: [
                // صندوق التحكم
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _showBars ? 63 : 0,
                  child: _showBars ? _buildToolbar() : const SizedBox.shrink(),
                ),

                // الجداول
                Expanded(
                  child: PageView(
                    controller: _pageControllerTwo,
                    onPageChanged: (index) {
                      // setState(() {
                      //   _selectedView = index == 1 ? 'customers' : 'agents';
                      // });
                    },
                    children: [
                      _buildTableCustomers(),
                      _buildTableAgents(),
                    ],
                  ),
                ),
              ],
            ),

            //  بار سفلي
            floatingActionButtonLocation:
                FloatingActionButtonLocation.miniCenterDocked,
            floatingActionButton: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: _showBars
                    ? FloatingActionButton(
                        onPressed: () => _showAddAccountDialog(),
                        backgroundColor: const Color(0xFF008091),
                        elevation: 0,
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 32),
                      )
                    : null),
            bottomNavigationBar: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showBars ? 54 : 0,
              child: _showBars
                  ? BottomAppBar(
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
                                _showSearchField = !_showSearchField;
                                _searchQuery = '';
                              });
                            },
                          ),

                          const SizedBox(width: 48), // مساحة للأيقونة الوسطى
                          _buildActionButtonTow(
                              icon: Icons.info_outline,
                              color: _selectedView == 'customers'
                                  ? Colors.blue
                                  : Colors.orange,
                              onTap: _showTotalSummaryDialog),
                        ],
                      ),
                    )
                  : null,
            )));
  }
}

// ============== النهاية   2025/5/8==========================
