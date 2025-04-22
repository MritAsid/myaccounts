// ==============Asmael Asid ====================================

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'add_transaction.dart';
import 'search.dart';
import '../main.dart';

class AddDeletePage extends StatefulWidget {
  const AddDeletePage({super.key});

  @override
  State<AddDeletePage> createState() => _AddDeletePageState();
}

class _AddDeletePageState extends State<AddDeletePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _agents = [];
  bool _showCustomersTable = true;
  bool _saveAccount = true;
  bool _showSearchField = false;
  String _searchQuery = '';
  // متغيرات لتخزين المبالغ
  final Map<int, double> _customerOutstanding = {};
  final Map<int, double> _agentOutstanding = {};

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadAgents();
    _pageController.addListener(() {
      setState(() {
        _showCustomersTable = _pageController.page! < 0.5;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

//  تغيير العرض
  void _toggleTable(bool showCustomers) {
    setState(() {
      _showCustomersTable = showCustomers;
      _pageController.animateToPage(
        showCustomers ? 0 : 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  // تحميل العملاء
  void _loadCustomers() async {
    final data = await _dbHelper.getAllCustomers();

    // تخزين المبالغ
    for (var customer in data) {
      final summary = await _dbHelper.getSummaryByName(customer['name']);
      _customerOutstanding[customer['id']] = summary['outstanding'];
    }

    setState(() {
      _customers = data;
    });
  }

  // تحميل الوكلاء
  void _loadAgents() async {
    final data = await _dbHelper.getAllAgents();

    // تخزين المبالغ
    for (var agent in data) {
      final summary = await _dbHelper.getSummaryAgeentByName(agent['name']);
      _agentOutstanding[agent['id']] = summary['outstanding'];
    }

    setState(() {
      _agents = data;
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

// إضافة حساب عميل او وكيل  (نسخة محسنة)
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
                                : Icons.business,
                            size: 25,
                            color: Colors.white),
                        const SizedBox(height: 4),
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
      await _dbHelper.insertCustomer(
        _nameController.text,
        _phoneController.text,
      );
      _nameController.clear();
      _phoneController.clear();
      _showSuccessMessage('تم حفظ العميل بنجاح');
      _loadCustomers();
    } else {
      _showErrorMessage('يرجى إدخال جميع البيانات');
    }
    if (!mounted) return;

    Navigator.pop(context);
    _toggleTable(true);
  }

// حفظ حساب وكيل
  void _saveAgent() async {
    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      await _dbHelper.insertAgent(
        _nameController.text,
        _phoneController.text,
      );
      _nameController.clear();
      _phoneController.clear();
      _showSuccessMessage('تم حفظ الوكيل بنجاح');
      _loadAgents();
    } else {
      _showErrorMessage('يرجى إدخال جميع البيانات');
    }
    if (!mounted) return;

    Navigator.pop(context);
    _toggleTable(false);
  }

// حذف حساب عميل
  void _deleteCustomer(int id) async {
    await _dbHelper.deleteCustomer(id);
    _showSuccessMessage('تم حذف العميل بنجاح');
    _loadCustomers();
  }

// حذف حساب وكيل
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
                  child: const Text(
                    'تعديل بيانات عميل',
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
      ),
    );
  }

// تعديل حساب وكيل
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
          child: Container(
              padding: const EdgeInsets.all(0.0),
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
                    child: const Text(
                      'تعديل بيانات وكيل',
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
                              _showSuccessMessage(
                                  'تم تعديل بيانات الوكيل بنجاح');
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

// ===========================================================================

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

  void _showCustomerDetails(String name, String phone, int id) async {
    final summary = _showCustomersTable
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
            // double.parse(summary['outstanding'].toString()) < 0 ? 'عليك' : 'لك';

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
                  // Header with gradient (أصغر حجمًا)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 12), // تقليل الحشو
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _showCustomersTable
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
                          _dbHelper.getNumberFormat(summary['totalAdditions']),
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
                          _dbHelper.getNumberFormat(summary['totalPayments']),
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

                  // Action Buttons (أزرار أكثر إحكاما)
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
                              _showCustomersTable
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
                              if (_showCustomersTable) {
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

// دالة مساعدة معدلة لإنشاء بطاقات المعلومات (أصغر حجمًا)
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
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14, // تصغير حجم الخط
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
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

  void _showTotalSummaryDialog() async {
    final summary = _showCustomersTable
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _showCustomersTable
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
                            _showCustomersTable
                                ? Icons.person_outline
                                : Icons.business,
                            size: 32,
                            color: Colors.white),
                        const SizedBox(height: 4),
                        Text(
                          _showCustomersTable
                              ? 'ملخص العملاء'
                              : 'ملخص  الموردين',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'إجمالي العدد: ${summary['totalCustomers']} ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
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
                          icon: Icons.add_circle_outline,
                          title: _showCustomersTable
                              ? 'اجمالي الديون'
                              : 'اجمالي القروض المستحقة',
                          value: _dbHelper
                              .getNumberFormat(summary['totalAdditions']),
                          color: Colors.red.shade100,
                          valueColor: Colors.red.shade700,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryCard(
                          icon: Icons.remove_circle_outline,
                          title: _showCustomersTable
                              ? 'اجمالي التسديدات'
                              : 'اجمالي المدفوعات النقدية',
                          value: _dbHelper
                              .getNumberFormat(summary['totalPayments']),
                          color: Colors.green.shade100,
                          valueColor: Colors.green.shade700,
                        ),
                      ],
                    ),
                  ),

                  // Outstanding Amount
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDebt
                          ? Colors.red.shade50
                          : isCredit
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDebt
                            ? Colors.red.shade200
                            : isCredit
                                ? Colors.green.shade200
                                : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isDebt || isCredit)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Icon(
                              isDebt ? Icons.warning_amber : Icons.info_outline,
                              size: 30,
                              color: textColor,
                            ),
                          ),
                        const SizedBox(
                          width: 20,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _showCustomersTable
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
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _dbHelper.getNumberFormat(outstanding),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Close Button
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildActionButton(
                      label: 'إغلاق',
                      icon: Icons.close,
                      color: _showCustomersTable
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

// دالة مساعدة لإنشاء بطاقات الملخص (بنفس نمط الدوال السابقة)
  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: valueColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

  Widget _buildTable(List<Map<String, dynamic>> data, bool isCustomers) {
    final filteredList = data
        .where((item) =>
            item['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final primaryColor =
        isCustomers ? Colors.blue.shade700 : Colors.orange.shade700;
    final lightColor =
        isCustomers ? Colors.blue.shade100 : Colors.orange.shade100;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    isCustomers ? 'المستحق لك' : 'المستحق عليك',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 5,
                  child: Text(
                    'الاسم',
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
                    size: 30,
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
                      final outstanding = isCustomers
                          ? _customerOutstanding[item['id']] ?? 0.0
                          : _agentOutstanding[item['id']] ?? 0.0;

                      final textColor = outstanding > 0
                          ? Colors.red.shade700
                          : outstanding < 0
                              ? Colors.green.shade700
                              : Colors.grey.shade800;

                      return Container(
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
                        child: InkWell(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            _showCustomerDetails(
                                item['name'], item['phone'], item['id']);
                          },
                          child: Row(
                            children: [
                              // Outstanding Amount
                              Expanded(
                                flex: 3,
                                child: Text(
                                  _dbHelper.getNumberFormat(outstanding),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),

                              // Name
                              Expanded(
                                flex: 5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 4),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: primaryColor,
                                        width: 2.0,
                                      ),
                                      right: BorderSide(
                                        color: primaryColor,
                                        width: 2.0,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    item['name'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.start,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),

                              // Info Button
                              Expanded(
                                flex: 2,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.info_outline,
                                    color: primaryColor,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();
                                    _showCustomerDetails(item['name'],
                                        item['phone'], item['id']);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text(
            'إدارة الحسابات',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20.0,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF00ACC1),
          elevation: 4,
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
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_showSearchField)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'ابحث بالاسم...',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFFEEEBEB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  _showSearchField = false;
                                  _searchQuery = '';
                                });
                              },
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0.0),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14.0, vertical: 4.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleTable(true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: _showCustomersTable
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
                                  color: _showCustomersTable
                                      ? Colors.blue
                                      : Colors.grey,
                                  size: 32,
                                ),
                                Text(
                                  ' العملاء ',
                                  style: TextStyle(
                                    fontSize: 10.0,
                                    color: _showCustomersTable
                                        ? Colors.blue
                                        : Colors.grey,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () => _toggleTable(false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: !_showCustomersTable
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
                                  color: !_showCustomersTable
                                      ? Colors.orange
                                      : Colors.grey,
                                  size: 32,
                                ),
                                Text(
                                  'الموردين',
                                  style: TextStyle(
                                    fontSize: 10.0,
                                    color: !_showCustomersTable
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
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border.all(
                      color: _showCustomersTable ? Colors.blue : Colors.orange,
                      width: 2),
                ),
                margin: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 0.0),
                child: PageView(
                  controller: _pageController,
                  children: [
                    _buildTable(_customers, true), // جدول العملاء
                    _buildTable(_agents, false), // جدول الموردين
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
                      setState(() {
                        _showSearchField = !_showSearchField;
                        _searchQuery = '';
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _showSearchField
                            ? Colors.white
                            : const Color(0xABFFFFFF),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.search_sharp,
                        color: _showSearchField ? Colors.green : Colors.grey,
                        size: 25,
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: _showAddAccountDialog,
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
                    onTap: _showTotalSummaryDialog,
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
}

// ==================================================
