// =====================================
//  --------------- البداية
// ---------------  2024/6/10
// ---------------  Asmael Asid
// =====================================

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../database/database_helper.dart';
import 'add_transaction.dart';
import 'search.dart';
import '../frontend/front_help.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class AddDeletePage extends StatefulWidget {
  const AddDeletePage({super.key});

  @override
  State<AddDeletePage> createState() => _AddDeletePageState();
}

class _AddDeletePageState extends State<AddDeletePage> {
  final pagColor = Colors.blue.shade400.withGreen(120);
  final primaryColorCustomer = Colors.blue.shade600;
  final primaryColorAgen = Colors.teal.shade700;
  final lightColorCustomer = Colors.blue.shade100;
  final lightColoAgenr = Colors.teal.shade100;
  final redTextColor = Colors.redAccent.shade700;
  final greenTextColor = const Color(0xFF00933D);
  final iconCustomer = Icons.person;
  final iconAgeen = Icons.business_rounded;
  // حقول الادخال
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  //  كلاس قاعدة البيانات
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // قوائم  لتخزين الاسماء وترتيبها
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _originalCustomers = [];
  List<Map<String, dynamic>> _originalAgents = [];

  // التحكم في عرض الوجهات
  String _selectedView = 'customers';
  bool selectedView = true;
  bool _showBars = true;
  final PageController _pageController = PageController(initialPage: 0);
  final ScrollController _scrollController = ScrollController();
  final ScrollController _scrollAgntController = ScrollController();

  //    حقل البحث
  bool _showSearchField = false;
  String _searchQuery = '';
  String _transactionType = ''; //  تخزين نوع العمليه

  //  اختيار ترتيب الاسماء
  String _sortBy = 'default';

  // المتغيرات لك وعليك من المستحق

  //  على العملاء
  double onCustomers = 0;
  //   للعملاء
  double forrCustomers = 0;
  //     عليك للموردين
  double forrDealers = 0;
  // علي الموردين
  double onDealers = 0;

  // التمرير
  double _lastDirectionOffset = 0;
  ScrollDirection? _lastDirection;

  //   انشاء الواجهة
  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadAgents();
    _scrollController.addListener(_handleScroll);
    _scrollAgntController.addListener(_handleScroll);
    // _sortBy = 'الافتراضي';
    _pageController.addListener(() {
      setState(() {
        _selectedView = _pageController.page! < 0.5 ? 'customers' : 'agents';
        selectedView = _selectedView == 'customers';
      });
    });
  }

  //   تدمير الواجهة
  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollAgntController.removeListener(_handleScroll);
    _scrollController.dispose();
    _scrollAgntController.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  //  التحكم في التمرير
  void _handleScroll() {
    double threshold = 300;
    double thresholdBotton = 50;

    final currentDirection = selectedView
        ? _scrollController.position.userScrollDirection
        : _scrollAgntController.position.userScrollDirection;
    final currentOffset =
        selectedView ? _scrollController.offset : _scrollAgntController.offset;

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
      if (!_showBars && diff > thresholdBotton) {
        setState(() {
          _showBars = true;
          _lastDirectionOffset = currentOffset;
        });
      }
    }
  }

  // اضهار عناصر التمرير
  void showHandl() {
    setState(() {
      if (_showBars == false) {
        _showBars = true;
      }
    });
  }

  // تحميل العملاء
  void _loadCustomers() async {
    final data = await _dbHelper.getAllCustomersAndMount();
    //  على العملاء
    onCustomers = 0.0;
    // للعملاء
    forrCustomers = 0.0;

    for (var customer in data) {
      final outstanding = customer['outstanding'];

      if (outstanding > 0) {
        //  اذ كان المستحق على العميل  اكبر من 0 اضف قيمته الى متغير  //  على العملاء
        onCustomers += outstanding;
      } else if (outstanding < 0) {
        //  اذ كان المستحق على العميل  اصغر  من 0 اضف قيمته الى متغير  // للعملاء
        forrCustomers += outstanding;
      }
    }
    //  تحويل قيمة للعملاء الى موجب
    forrCustomers = -forrCustomers;
    setState(() {
      _customers = data;
      _originalCustomers = List.from(data);

      _applySorting();
    });
  }

  // تحميل الموردين
  void _loadAgents() async {
    final data = await _dbHelper.getAllAgentsAndMount();
    //  عليك للموردين
    forrDealers = 0.0;
    // على الموردين
    onDealers = 0.0;

    setState(() {
      _agents = data;
      _originalAgents = List.from(data);

      _applySorting();
    });

    // حساب الإجماليات
    for (var agent in data) {
      final outstanding = agent['outstanding'];

      if (outstanding > 0) {
        //  اذ كان المستحق للمورد  اكبر من 0 اضف قيمته الى متغير  //   عليك للموردين
        forrDealers += outstanding;
      } else if (outstanding < 0) {
        //  اذ كان المستحق للمورد  اصغر من 0 اضف قيمته الى متغير  //   على الموردين
        onDealers += outstanding;
      }
    }
    //  تحويل قيمة على الموردين الى موجب

    onDealers = -onDealers;
  }

//  تنظيف الحقول
  void claerInpt() {
    _nameController.clear();
    _phoneController.clear();
  }

  //نافذة اضافة حساب
  void _showAddAccountDialog() {
    // نظّف الحقول
    claerInpt();

    final colorFunction =
        selectedView ? primaryColorCustomer : primaryColorAgen;
    final iconFunction = selectedView ? iconCustomer : iconAgeen;
    CustomDialog.show(
        context: context,
        headerColor: colorFunction,
        icon: iconFunction,
        title: selectedView ? 'إضافة عميل جديد' : 'إضافة مورد جديد',
        contentChildren: [
          const SizedBox(height: 10.0),
          _buildInputField(
            controller: _nameController,
            label: 'الاسم',
            icon: iconFunction,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const SizedBox(width: 20.0),
              Expanded(
                child: _buildActionButton(
                  label: 'الغاء',
                  icon: Icons.close,
                  color: Colors.red.shade600,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 20.0),
              Expanded(
                child: _buildActionButton(
                  label: selectedView ? 'حفظ العميل' : 'حفظ المورد',
                  icon: iconFunction,
                  color: colorFunction,
                  onPressed: _saveAccount,
                ),
              ),
              const SizedBox(width: 20.0),
            ],
          ),
          const SizedBox(height: 10),
        ]);
  }

  //  حفظ الحساب
  void _saveAccount() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      _showErrorMessage('يرجى إدخال جميع البيانات');
      return;
    }

    final isCustomer = selectedView;
    final exists = isCustomer
        ? await _dbHelper.doesClientExist(name)
        : await _dbHelper.doesAgntExist(name);

    if (exists) {
      _showErrorMessage(
          isCustomer ? 'اسم العميل موجود مسبقًا' : 'اسم المورد موجود مسبقًا');
      return;
    }

    // أضف العميل أو المورد
    if (isCustomer) {
      await _dbHelper.insertCustomer(name, phone);
    } else {
      await _dbHelper.insertAgent(name, phone);
    }

    // أغلق النافذة أولًا
    if (!mounted) return;
    Navigator.pop(context);

    _sortBy = 'الأحدث أولاً';

    // حمّل البيانات وأعرض الرسالة
    if (isCustomer) {
      _loadCustomers();
      _showSuccessMessage('تم حفظ العميل بنجاح');
    } else {
      _loadAgents();
      _showSuccessMessage('تم حفظ المورد بنجاح');
    }
  }

  // تغيير العرض
  void _handlePageNavigation(bool isCustomer) {
    final targetPage = isCustomer ? 0 : 1;

    if ((_selectedView == 'customers' && !isCustomer) ||
        (_selectedView != 'customers' && isCustomer)) {
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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

  // تعديل حساب عميل او مورد
  void _updateCustomer(int id, String name, String phone) async {
    _nameController.text = name;
    _phoneController.text = phone;

    final iconFunction = selectedView ? iconCustomer : iconAgeen;
    final colorFunction =
        selectedView ? primaryColorCustomer : primaryColorAgen;

    CustomDialog.show(
        context: context,
        headerColor: colorFunction,
        icon: iconFunction,
        title: selectedView ? 'تعديل بيانات عميل' : 'تعديل بيانات مورد',
        contentChildren: [
          const SizedBox(height: 10.0),
          _buildInputField(
            controller: _nameController,
            label: 'الاسم',
            icon: iconFunction,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const SizedBox(width: 20.0),
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
                icon: iconFunction,
                color: colorFunction,
                onPressed: () {
                  if (selectedView) {
                    Navigator.pop(context);
                    _dbHelper.updateCustomer(
                      id,
                      _nameController.text,
                      _phoneController.text,
                    );
                    _showSuccessMessage('تم تعديل بيانات العميل بنجاح');
                    _loadCustomers();
                  } else {
                    Navigator.pop(context);
                    _dbHelper.updateAgent(
                      id,
                      _nameController.text,
                      _phoneController.text,
                    );
                    _showSuccessMessage('تم تعديل بيانات المورد بنجاح');
                    _loadAgents();
                  }
                  // نظّف الحقول
                  claerInpt();
                },
              )),
              const SizedBox(width: 20.0),
            ],
          ),
          const SizedBox(height: 10.0),
        ]);
  }

  //  نافذة  ملخص العملاء او الموردين
  void _showTotalSummaryDialog() async {
    final summary = selectedView
        ? await _dbHelper.getTotalSummary()
        : await _dbHelper.getTotalAgeensSummary();
    final colorFunction =
        selectedView ? primaryColorCustomer : primaryColorAgen;
    //  عليك للموردين      على العملاء                       المستحق
    final outstanding = selectedView ? onCustomers : forrDealers;
    // للعملاء

    //     على للموردين    عليك العملاء                          المقدمه
    final outstandingRvers = selectedView ? forrCustomers : onDealers;
    if (!mounted) return;
    CustomDialog.show(
      context: context,
      headerColor: colorFunction,
      icon: selectedView ? Icons.people : iconAgeen,
      title: selectedView ? 'تفاصيل حسابات العملاء' : ' تفاصيل حسابات الموردين',
      infoText: 'عدد الحسابات :  ${summary['totalCustomers']} ',
      contentChildren: [
        _buildSummaryCard(
          icon: Icons.price_change_outlined,
          title: selectedView ? 'الديون المستحقة' : 'القروض المستحقة',
          value: _dbHelper.getNumberFormat(summary['totalAdditions']),
          color: Colors.red.shade100,
          valueColor: redTextColor,
        ),
        const SizedBox(height: 8),
        _buildSummaryCard(
          icon: Icons.price_check_rounded,
          title: selectedView ? 'المبالغ المستلمة' : 'المبالغ المسلمة',
          value: outstandingRvers > 0
              ? _dbHelper
                  .getNumberFormat(summary['totalPayments'] - outstandingRvers)
              : _dbHelper.getNumberFormat(summary['totalPayments']),
          color: greenTextColor.withOpacity(0.3),
          valueColor: greenTextColor,
        ),
        const SizedBox(height: 8),
        _buildSummaryCard(
          icon: outstanding > 0
              ? Icons.monetization_on_outlined
              : Icons.money_off,
          title: selectedView
              ? outstanding > 0
                  ? 'المبلغ المستحق  على العملاء لك'
                  : 'لا يوجد مستحقات'
              : outstanding > 0
                  ? 'المبلغ المستحق  عليك  للموردين'
                  : 'لا يوجد مستحقات',
          value: _dbHelper.getNumberFormat(outstanding),
          color: outstanding > 0
              ? redTextColor.withOpacity(0.2)
              : Colors.grey.shade400,
          valueColor: outstanding > 0 ? redTextColor : Colors.black54,
        ),
        if (outstandingRvers > 0) const SizedBox(height: 12),
        if (outstandingRvers > 0)
          Text(
            '*  ملاحظة ',
            style: TextStyle(
                color: redTextColor, fontSize: 16, fontWeight: FontWeight.w800),
          ),
        const SizedBox(height: 8),
        if (outstandingRvers > 0)
          _buildSummaryRow(
              selectedView
                  ? 'مبالغ  دفعها العملاء مقدمأ'
                  : 'مبالغ  دفعتها للموردين مقدمأ',
              _dbHelper.getNumberFormat(outstandingRvers),
              icon: selectedView ? Icons.remove : Icons.add,
              color: redTextColor,
              valueColor: redTextColor.withOpacity(0.2)),
        if (outstandingRvers > 0) const SizedBox(height: 8),
        if (outstandingRvers > 0)
          _buildSummaryRow(
              selectedView
                  ? 'اجمالي المبالغ المستلمة'
                  : 'اجمالي المبالغ المسلمة',
              summary['totalPayments'] > 0
                  ? _dbHelper.getNumberFormat(summary['totalPayments'])
                  : summary['totalPayments'].toString(),
              icon: selectedView ? Icons.add : Icons.remove,
              color: greenTextColor,
              valueColor: greenTextColor.withOpacity(0.3)),
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
      ],
    );
  }

  // نافذة تفاصيل  العميل او المور
  void _showCustomerDetails(String name, String phone, int id,
      final totalAdditions, final totalPayments, final outstanding) async {
    final colorFunction =
        selectedView ? primaryColorCustomer : primaryColorAgen;
    final iconFunction = selectedView ? iconCustomer : iconAgeen;
    final isCredit = outstanding < 0;
    final isDebt = double.parse(outstanding.toString()) > 0;
    final isDebtCust = double.parse(outstanding.toString()) < 0 ? 'له' : 'علية';
    final isDebtAgnt = double.parse(outstanding.toString()) < 0 ? 'علية' : 'له';
    var finlOgstin = outstanding;

    if (finlOgstin < 0) {
      finlOgstin = -finlOgstin;
    }

    if (!mounted) return;
    CustomDialog.show(
        context: context,
        headerColor: colorFunction,
        icon: selectedView ? iconCustomer : iconAgeen,
        title: selectedView ? 'تفاصيل العميل' : 'تفاصيل المورد',
        contentChildren: [
          const SizedBox(height: 8),
          _buildSummaryCard(
            icon: iconFunction,
            title: 'الاسم',
            value: name,
            color: selectedView ? lightColorCustomer : lightColoAgenr,
            valueColor: selectedView ? primaryColorCustomer : primaryColorAgen,
          ),
          const SizedBox(height: 8),
          _buildSummaryCard(
            icon: Icons.phone,
            title: 'الهاتف',
            value: phone,
            color: selectedView ? lightColorCustomer : lightColoAgenr,
            valueColor: selectedView ? primaryColorCustomer : primaryColorAgen,
          ),
          const SizedBox(height: 18),
          _buildSummaryRow(
            selectedView ? 'الديون المستحقة' : 'القروض المستحقة',
            totalAdditions > 0
                ? _dbHelper.getNumberFormat(totalAdditions)
                : totalAdditions.toString(),
            icon: Icons.price_change_outlined,
            color: redTextColor,
            valueColor: redTextColor.withOpacity(0.2),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            selectedView ? 'المبالغ المستلمة' : 'المبالغ المسلمة',
            totalPayments > 0
                ? _dbHelper.getNumberFormat(totalPayments)
                : totalPayments.toString(),
            icon: Icons.price_check_rounded,
            color: greenTextColor,
            valueColor: greenTextColor.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            outstanding == 0
                ? ' لا يوجد مستحقات'
                : selectedView
                    ? 'المستحق $isDebtCust'
                    : 'المستحق $isDebtAgnt',
            finlOgstin != 0
                ? _dbHelper.getNumberFormat(finlOgstin)
                : finlOgstin.toInt().toString(),
            icon: outstanding == 0
                ? Icons.money_off
                : isDebt
                    ? Icons.monetization_on_outlined
                    : Icons.warning_amber_rounded,
            color: selectedView
                ? isDebt
                    ? redTextColor
                    : isCredit
                        ? greenTextColor
                        : Colors.black54
                : isDebt
                    ? redTextColor
                    : isCredit
                        ? greenTextColor
                        : Colors.black54,
            valueColor: isDebt
                ? redTextColor.withOpacity(0.2)
                : isCredit
                    ? greenTextColor.withOpacity(0.3)
                    : Colors.grey.shade100,
            isBold: true,
          ),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildActionButton(
              label: '',
              icon: Icons.edit,
              color: greenTextColor,
              onPressed: () {
                if (!_showBars) {
                  setState(() {
                    _showBars = true;
                  });
                }
                Navigator.of(context).pop();

                _updateCustomer(id, name, phone);
              },
            ),
            _buildActionButton(
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
                selectedView ? _deleteCustomer(id) : _deleteAgent(id);
              },
            ),
            _buildActionButton(
              label: '',
              icon: Icons.account_balance_wallet,
              color: const Color(0xFFFF9800),
              onPressed: () {
                if (!_showBars) {
                  setState(() {
                    _showBars = true;
                  });
                }

                Navigator.of(context).pop();
                _showAddCustomerOperationDialog(id, name);
              },
            ),
            _buildActionButton(
              label: '',
              icon: Icons.receipt_long,
              color: const Color(0xFF07BEAC),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchClientPage(
                      customerName: name,
                      iscontun: selectedView,
                    ),
                  ),
                );
              },
            ),
          ]),
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
  }

  //  تنفيذ الترتيب
  void _applySorting() {
    //
    setState(() {
      _customers = List.from(_originalCustomers);
      _agents = List.from(_originalAgents);

      switch (_sortBy) {
        case 'name_asc':
          _customers.sort((a, b) => a['name'].compareTo(b['name']));
          _agents.sort((a, b) => a['name'].compareTo(b['name']));
          break;
        case 'newest':
          _customers.sort((a, b) => b['id'].compareTo(a['id']));
          _agents.sort((a, b) => b['id'].compareTo(a['id']));
          break;
        case 'debt_desc':
          _customers
              .sort((a, b) => b['outstanding'].compareTo(a['outstanding']));
          _agents.sort((a, b) => b['outstanding'].compareTo(a['outstanding']));
          break;
        case 'additions_desc':
          _customers.sort(
              (a, b) => b['totalAdditions'].compareTo(a['totalAdditions']));
          _agents.sort(
              (a, b) => b['totalAdditions'].compareTo(a['totalAdditions']));
          break;
        case 'default':
          // لا حاجة للفرز، البيانات تم نسخها كما هي
          break;
      }
    });
  }

  //  اختيار الترتيب
  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String tempSortBy = _sortBy;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
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
                        // العنوان
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: pagColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.sort, color: Colors.white, size: 28),
                              Text(
                                'ترتيب العناصر',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // خيارات الترتيب
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 6),
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 12.0,
                            alignment: WrapAlignment.spaceEvenly,
                            children: [
                              _buildSortOption(
                                context,
                                title: 'الاسم',
                                icon: Icons.sort_by_alpha,
                                isActive: tempSortBy == 'name_asc',
                                onTap: () => setStateDialog(
                                    () => tempSortBy = 'name_asc'),
                              ),
                              _buildSortOption(
                                context,
                                title: 'الأحدث',
                                icon: Icons.schedule,
                                isActive: tempSortBy == 'newest',
                                onTap: () =>
                                    setStateDialog(() => tempSortBy = 'newest'),
                              ),
                              _buildSortOption(
                                context,
                                title: '↑المستحق',
                                icon: Icons.trending_up,
                                isActive: tempSortBy == 'debt_desc',
                                onTap: () => setStateDialog(
                                    () => tempSortBy = 'debt_desc'),
                              ),
                              _buildSortOption(
                                context,
                                title: '↑ديون / قروض',
                                icon: Icons.stacked_line_chart,
                                isActive: tempSortBy == 'additions_desc',
                                onTap: () => setStateDialog(
                                    () => tempSortBy = 'additions_desc'),
                              ),
                              _buildSortOption(
                                context,
                                title: 'الافتراضي',
                                icon: Icons.restore,
                                isActive: tempSortBy == 'default',
                                onTap: () => setStateDialog(
                                    () => tempSortBy = 'default'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12.0),

                        // الأزرار
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  label: 'إغلاق',
                                  icon: Icons.close,
                                  color: Colors.red.shade600,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildActionButton(
                                  label: 'حفظ',
                                  icon: Icons.check,
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 12.0),
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

  //  نجاح العملية
  void _showSuccessMessage(String message) {
    playNotificationSound(); // ← هذا هو صوت الإشعار الحقيقي

    Flushbar(
      messageText: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 1)),
            child: const Icon(Icons.check, color: Colors.green, size: 22),
          )
        ],
      ),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(22),
      animationDuration: const Duration(milliseconds: 300),
    ).show(context);
  }

  //  صوت الاشعار
  void playNotificationSound() {
    FlutterRingtonePlayer.playNotification();
  }

  //  فشل العملية
  void _showErrorMessage(String message) {
    playNotificationSound(); // ← هذا هو صوت الإشعار الحقيقي
    Flushbar(
      messageText: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.white,
            ),
            child: const Icon(Icons.error_outline_sharp,
                color: Colors.red, size: 30),
          )
        ],
      ),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 1),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(22),
      animationDuration: const Duration(milliseconds: 200),
    ).show(context);
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
            color: selectedView ? primaryColorCustomer : primaryColorAgen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: selectedView ? primaryColorCustomer : primaryColorAgen,
              width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: selectedView ? primaryColorCustomer : primaryColorAgen,
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
              weight: 800,
              opticalSize: 60,
              grade: 200,
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
          Icon(
            icon,
            size: 24,
            color: Colors.white,
            weight: 60,
          ),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100, // ثبات العرض لأفضل توزيع في Wrap
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
        decoration: BoxDecoration(
          color: isActive ? pagColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.black26 : pagColor,
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  const BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : pagColor,
              size: 28,
              weight: 800,
              opticalSize: 60,
              grade: 200,
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: isActive ? Colors.white : pagColor,
              ),
            ),
          ],
        ),
      ),
      // )
    );
  }

  //  جدول العملاء
  Widget _buildTableCustomers() {
    return CustomerTable(
      one: true,
      searchPage: false,
      customers: _customers,
      searchQuery: _searchQuery,
      scrollController: _scrollController,
      dbHelper: _dbHelper,
      onTap: (customer) {
        _showCustomerDetails(
          customer['name'],
          customer['phone'],
          customer['id'],
          customer['totalAdditions'],
          customer['totalPayments'],
          customer['outstanding'],
        );
      },
    );
  }

  //  جدول الموردين
  Widget _buildTableAgents() {
    return AgentTable(
      one: true,
      shcerPage: false,
      agents: _agents,
      searchQuery: _searchQuery,
      scrollController: _scrollAgntController,
      dbHelper: _dbHelper,
      onTap: (agent) {
        _showCustomerDetails(
          agent['name'],
          agent['phone'],
          agent['id'],
          agent['totalAdditions'],
          agent['totalPayments'],
          agent['outstanding'],
        );
      },
    );
  }

  //     نافذة اضافة عملية
  void _showAddCustomerOperationDialog(int id, String name) {
    // نظّف الحقول
    claerInpt();
    _transactionType = '';
    final typetransaction = selectedView ? 'إضافة' : 'قرض';
    final typetransactionViw = selectedView ? ' دين ' : 'قرض';
    final primaryColor = selectedView ? primaryColorCustomer : primaryColorAgen;
    final iconFunction = selectedView ? iconCustomer : iconAgeen;
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
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
                              children: [
                                Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.only(
                                        top: 8, bottom: 4),
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
                                          selectedView
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
                                    padding:
                                        const EdgeInsets.fromLTRB(16, 8, 16, 2),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 10),
                                        _buildInputField(
                                          controller: _phoneController,
                                          label: 'المبلغ',
                                          icon: Icons.attach_money,
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.next,
                                        ),
                                        const SizedBox(height: 20),
                                        _buildInputField(
                                          controller: _nameController,
                                          label: 'تفاصيل العملية',
                                          icon: Icons.description,
                                          onEditingComplete: () =>
                                              FocusScope.of(context)
                                                  .nextFocus(),
                                          textInputAction: TextInputAction.done,
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    )),
                                Container(
                                  margin: const EdgeInsets.only(
                                      left: 16, right: 16),
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          width: 1.5, color: primaryColor),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(12))),
                                  child: Column(children: [
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          topRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'اختيار نوع العملية',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildTransactionTypeButton(
                                          label: typetransactionViw,
                                          isSelected: _transactionType ==
                                              typetransaction,
                                          color: redTextColor,
                                          onTap: () {
                                            FocusScope.of(context).unfocus();

                                            setState(() {
                                              _transactionType =
                                                  typetransaction;
                                            });
                                          },
                                        ),
                                        _buildTransactionTypeButton(
                                          label: 'تسديد',
                                          isSelected:
                                              _transactionType == 'تسديد',
                                          color: greenTextColor,
                                          onTap: () {
                                            FocusScope.of(context).unfocus();
                                            setState(() {
                                              _transactionType = 'تسديد';
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                  ]),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 10.0),
                                        Expanded(
                                          child: _buildActionButton(
                                            label: 'الغاء',
                                            icon: Icons.close,
                                            color: Colors.red,
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 20.0),
                                        Expanded(
                                          child: _buildActionButton(
                                            label: 'حفظ',
                                            icon: Icons.save_as_outlined,
                                            color: Colors.green,
                                            onPressed: () {
                                              double? amount = double.tryParse(
                                                  _phoneController.text.trim());

                                              if (amount == null ||
                                                  amount <= 0) {
                                                _showErrorMessage(
                                                    'يرجى اختيار مبلغ صحيح أكبر من 0');
                                                return;
                                              } else if (_transactionType
                                                  .isEmpty) {
                                                _showErrorMessage(
                                                    'يرجى اختيار نوع العملية');
                                                return;
                                              } else if (_transactionType ==
                                                  'تسديد') {
                                                _showConfirmDailySaveDialog(
                                                    (bool saveInDaily) {
                                                  _saveTransactionToDatabase(id,
                                                      name: name,
                                                      saveInDaily: saveInDaily);
                                                });
                                                return;
                                              }
                                              _saveTransactionToDatabase(id);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10.0),
                                      ],
                                    )),
                              ],
                            )))));
          });
        });
  }

  //  حفظ العمليه في الحساب اليومي
  void _showConfirmDailySaveDialog(Function(bool) onDecision) {
    CustomDialog.show(
        context: context,
        headerColor: selectedView ? primaryColorCustomer : primaryColorAgen,
        icon: Icons.attach_money_sharp,
        title: 'هل تريد حفظ العملية في الحساب اليومي  ؟',
        contentChildren: [
          const SizedBox(height: 30.0),
          Row(
            children: [
              const SizedBox(width: 10.0),
              Expanded(
                child: _buildActionButton(
                  label: 'الغاء',
                  icon: Icons.close,
                  color: redTextColor.withOpacity(0.8),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDecision(false); // احفظ
                  },
                ),
              ),
              const SizedBox(width: 20.0),
              Expanded(
                child: _buildActionButton(
                  label: 'موافق',
                  icon: Icons.save_as_outlined,
                  color: greenTextColor.withOpacity(0.8),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDecision(true); // احفظ
                  },
                ),
              ),
              const SizedBox(width: 10.0),
            ],
          ),
          const SizedBox(height: 15.0),
        ]);
  }

  //   حفظ العملية في حساب العميل او المورد
  void _saveTransactionToDatabase(int id,
      {String name = '', bool saveInDaily = true}) async {
    double? amount = double.tryParse(_phoneController.text.trim());
    String details = _nameController.text.trim();
    final typetransactionViw =
        _transactionType == 'إضافة' ? ' دين ' : _transactionType;

    if (amount == null || amount <= 0) {
      _showErrorMessage('يرجى اختيار مبلغ صحيح أكبر من 0');
      return;
    } else if (details == '') {
      details =
          'عملية $typetransactionViw  في  ${_dbHelper.getFormattedDate(DateTime.now())}';
    }
    selectedView
        ?
        //   حفظ العملية في حساب العميل او المورد
        await _dbHelper.insertOperation(
            id,
            amount,
            details,
            _transactionType,
          )
        : await DatabaseHelper().insertAgentOperation(
            id,
            amount,
            details,
            _transactionType,
          );

// حفظ العملية في الحساب اليومي
    if (_transactionType == 'تسديد' && saveInDaily) {
      final dbHelper = DatabaseHelper();
      String type = selectedView ? 'كسب' : 'صرف';
      String detailsNum =
          '${selectedView ? "🙎‍♂️ من العميل" : "🏭 تسديد للمورد "}$name';
      await dbHelper.insertDailyTransaction(amount, detailsNum, type);
    }

    _nameController.clear();
    _phoneController.clear();
    _transactionType = '';
    if (!mounted) return;

    Navigator.pop(context);
    selectedView ? _loadCustomers() : _loadAgents();

    _showSuccessMessage('تم حفظ العملية بنجاح');
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  // الواجهه
  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
            backgroundColor: Colors.cyan.shade400,
            resizeToAvoidBottomInset: false,
            appBar: CustomAppBar(
              title: ' إدارة الحسابات   ',
              colorTitle: pagColor,
              onBackPress: () => Navigator.pop(context),
              onIcon1Press: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionPage(),
                  ),
                );
              },
              icon1Press: Icons.account_balance_wallet,
              color1Press: const Color(0xFFFF9800),
              onIcon2Press: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchClientPage(),
                  ),
                );
              },
              icon2Press: Icons.receipt_long,
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
                  // شريط علوي
                  TabBarBody(
                    height: _showBars ? 55 : 0,
                    showSearchField: _showSearchField,
                    onBackPress: () => {
                      if (!selectedView) _handlePageNavigation(true),
                    },
                    color1Press: selectedView
                        ? primaryColorCustomer
                        : const Color(0xABFFFFFF),
                    color1PressChildrn:
                        selectedView ? Colors.white : Colors.grey,
                    onBack2Press: () => {
                      if (selectedView) _handlePageNavigation(false),
                    },
                    color2Press: !selectedView
                        ? primaryColorAgen
                        : const Color(0xABFFFFFF),
                    color2PressChildrn:
                        !selectedView ? Colors.white : Colors.grey,
                    color3Press: pagColor,
                    onBack3Press: () => _showSortDialog(context),
                    icon3Press: Icons.sort_by_alpha_rounded,
                    title: '   ترتيب   ',
                    onBackShears: () {
                      setState(() {
                        _showSearchField = !_showSearchField;
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

                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        showHandl();
                      },
                      children: [
                        _buildTableCustomers(),
                        _buildTableAgents(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            floatingActionButton: AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              child: _showBars
                  ? FloatingActionButton(
                      backgroundColor: selectedView
                          ? primaryColorCustomer
                          : primaryColorAgen,
                      onPressed: () => _showAddAccountDialog(),
                      elevation: 4,
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 30),
                    )
                  : null,
            ),
            bottomNavigationBar: ActionButtonL(
              showBars: _showBars,
              icon1Press: Icons.search_outlined,
              color1Press:
                  selectedView ? primaryColorCustomer : primaryColorAgen,
              onIcon1Press: () {
                setState(() {
                  _showSearchField = !_showSearchField;
                  _searchQuery = '';
                });
              },
              icon2Press: Icons.info_outline,
              color2Press:
                  selectedView ? primaryColorCustomer : primaryColorAgen,
              onIcon2Press: _showTotalSummaryDialog,
            )));
  }
}

// =====================================
//  ------------- النهاية
//  ------------- 2025/5/29
// =====================================
