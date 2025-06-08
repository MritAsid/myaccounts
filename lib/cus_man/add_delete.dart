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

final primaryColorCustomer = Colors.blue.shade600;
final primaryColorAgen = Colors.teal.shade700;
final lightColorCustomer = Colors.blue.shade100;
final lightColoAgenr = Colors.teal.shade100;
final redTextColor = Colors.redAccent.shade700;
const greenTextColor = Color(0xFF00933D);

class AddDeletePage extends StatefulWidget {
  const AddDeletePage({super.key});

  @override
  State<AddDeletePage> createState() => _AddDeletePageState();
}

class _AddDeletePageState extends State<AddDeletePage> {
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

  // التحكم في عرض واجهات الاخراج
  String _selectedView = 'customers';
  bool _showBars = true;
  final PageController _pageControllerTwo = PageController(initialPage: 0);
  final ScrollController _scrollController = ScrollController();

  // التحكم في عرض واجهات الادخال
  bool inputInterfaceType = true;

  final iconCustomer = Icons.person;

  final iconAgeen = Icons.business_rounded;
  //    حقل البحث
  bool _showSearchField = false;
  String _searchQuery = '';
  String _transactionType = ''; //  تخزين نوع العمليه

  //  اختيار ترتيب الاسماء
  String _sortBy = 'افتراضي';

  // المتغيرات لك وعليك من المستحق
  double onMyCou = 0;
  double toMyCou = 0;
  double onMyAgn = 0;
  double toMyAgn = 0;

  double _lastDirectionOffset = 0;
  ScrollDirection? _lastDirection;

  //   تفاعلات الواجهة
  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadAgents();
    _scrollController.addListener(_handleScroll);

    _sortBy = 'الافتراضي';

    _pageControllerTwo.addListener(() {
      setState(() {
        _selectedView = _pageControllerTwo.page! < 0.5 ? 'customers' : 'agents';
      });
    });
  }

  void _handleScroll() {
    double threshold = 300;
    double thresholdBotton = 100;
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
      if (!_showBars && diff > thresholdBotton) {
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

  //  التركيز
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // تحميل العملاء
  void _loadCustomers() async {
    final data = await _dbHelper.getAllCustomersAndMount();

    toMyCou = 0.0;
    onMyCou = 0.0;

    for (var customer in data) {
      final outstanding = customer['outstanding'];

      if (outstanding > 0) {
        toMyCou += outstanding;
      } else if (outstanding < 0) {
        onMyCou += outstanding;
      }
    }
    onMyCou *= -1;
    setState(() {
      _customers = data;
      _originalCustomers = List.from(data);
    });
  }

  // تحميل الموردين
  void _loadAgents() async {
    final data = await _dbHelper.getAllAgentsAndMount();

    toMyAgn = 0.0;
    onMyAgn = 0.0;

    setState(() {
      _agents = data;
      _originalAgents = List.from(data);
    });

    // حساب الإجماليات
    for (var agent in data) {
      final outstanding = agent['outstanding'];

      if (outstanding > 0) {
        toMyAgn += outstanding;
      } else if (outstanding < 0) {
        onMyAgn += outstanding;
      }
    }
    onMyAgn *= -1;
  }

  //نافذة اختيار نوع اضافة حساب
  void _chooseTypeAccountAdd() {
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
                        icon: iconCustomer,
                        color: primaryColorCustomer,
                        onPressed: () {
                          inputInterfaceType = true;

                          Navigator.pop(context);
                          _showAddAccountDialog();
                        },
                      ),
                    ),
                    const SizedBox(width: 20.0),
                    Expanded(
                      child: _buildActionButton(
                        label: 'مورد',
                        icon: iconAgeen,
                        color: primaryColorAgen,
                        onPressed: () {
                          inputInterfaceType = false;

                          Navigator.pop(context);
                          _showAddAccountDialog();
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

  //نافذة اضافة حساب
  void _showAddAccountDialog() {
    final colorFunction =
        inputInterfaceType ? primaryColorCustomer : primaryColorAgen;
    final iconFunction = inputInterfaceType ? iconCustomer : iconAgeen;
    CustomDialog.show(
        context: context,
        headerColor: colorFunction,
        icon: iconFunction,
        title: inputInterfaceType ? 'إضافة عميل جديد' : 'إضافة مورد جديد',
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
                  label: inputInterfaceType ? 'حفظ العميل' : 'حفظ المورد',
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

  // حفظ حساب
  void _saveAccount() async {
    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      final nuem = _nameController.text;

      if (inputInterfaceType) {
        await _dbHelper.insertCustomer(
          nuem,
          _phoneController.text,
        );
        _loadCustomers();
        _showSuccessMessage('تم حفظ العميل بنجاح');

        if (_selectedView != 'customers') {
          _pageControllerTwo.animateToPage(0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut);
        }
      } else {
        await _dbHelper.insertAgent(
          nuem,
          _phoneController.text,
        );

        _showSuccessMessage('تم حفظ المورد بنجاح');
        _loadAgents();

        if (_selectedView == 'customers') {
          _pageControllerTwo.animateToPage(1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut);
        }
      }

      _nameController.clear();
      _phoneController.clear();

      if (!mounted) return;
      Navigator.pop(context);
    } else {
      _showErrorMessage('يرجى إدخال جميع البيانات');
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

    final iconFunction = inputInterfaceType ? iconCustomer : iconAgeen;
    final isAconnt = _selectedView == 'customers';
    final colorFunction =
        inputInterfaceType ? primaryColorCustomer : primaryColorAgen;

    CustomDialog.show(
        context: context,
        headerColor: colorFunction,
        icon: iconFunction,
        title: isAconnt ? 'تعديل بيانات عميل' : 'تعديل بيانات مورد',
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
                  if (inputInterfaceType) {
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
    final isAconnt = _selectedView == 'customers';

    final summary = isAconnt
        ? await _dbHelper.getTotalSummary()
        : await _dbHelper.getTotalAgeensSummary();
    final colorFunction = isAconnt ? primaryColorCustomer : primaryColorAgen;

    final outstanding = isAconnt ? toMyCou : toMyAgn;
    final outstandingRvers = isAconnt ? onMyCou : onMyAgn;
    if (!mounted) return;
    CustomDialog.show(
      context: context,
      headerColor: colorFunction,
      icon: isAconnt ? Icons.people : iconAgeen,
      title: isAconnt ? 'تفاصيل حسابات العملاء' : ' تفاصيل حسابات الموردين',
      infoText: 'عدد الحسابات :  ${summary['totalCustomers']} ',
      contentChildren: [
        _buildSummaryCard(
          icon: Icons.price_change_outlined,
          title: isAconnt ? 'الديون المستحقة' : 'القروض المستحقة',
          value: _dbHelper.getNumberFormat(summary['totalAdditions']),
          color: Colors.red.shade100,
          valueColor: redTextColor,
        ),
        const SizedBox(height: 8),
        _buildSummaryCard(
          icon: Icons.price_check_rounded,
          title: isAconnt ? 'المبالغ المستلمة' : 'المبالغ المسلمة',
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
          title: isAconnt
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
              isAconnt
                  ? 'مبالغ  دفعها العملاء مقدمأ'
                  : 'مبالغ  دفعتها للموردين مقدمأ',
              _dbHelper.getNumberFormat(outstandingRvers),
              icon: isAconnt ? Icons.remove : Icons.add,
              color: redTextColor,
              valueColor: redTextColor.withOpacity(0.2)),
        if (outstandingRvers > 0) const SizedBox(height: 8),
        if (outstandingRvers > 0)
          _buildSummaryRow(
              isAconnt ? 'اجمالي المبالغ المستلمة' : 'اجمالي المبالغ المسلمة',
              summary['totalPayments'] > 0
                  ? _dbHelper.getNumberFormat(summary['totalPayments'])
                  : summary['totalPayments'].toString(),
              icon: isAconnt ? Icons.add : Icons.remove,
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
    final isAconnt = _selectedView == 'customers';
    final colorFunction = isAconnt ? primaryColorCustomer : primaryColorAgen;
    final iconFunction = isAconnt ? iconCustomer : iconAgeen;
    final isCredit = outstanding < 0;
    final isDebt = double.parse(outstanding.toString()) > 0;
    final isDebtCust = double.parse(outstanding.toString()) < 0 ? 'له' : 'علية';
    final isDebtAgnt = double.parse(outstanding.toString()) < 0 ? 'علية' : 'له';
    double finlOgstin = 0;

    if (outstanding < 0) {
      finlOgstin = outstanding * -1;
    }

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
            icon: Icons.phone,
            title: 'الهاتف',
            value: phone,
            color: isAconnt ? lightColorCustomer : lightColoAgenr,
            valueColor: isAconnt ? primaryColorCustomer : primaryColorAgen,
          ),
          const SizedBox(height: 18),
          _buildSummaryRow(
            isAconnt ? 'الديون المستحقة' : 'القروض المستحقة',
            totalAdditions > 0
                ? _dbHelper.getNumberFormat(totalAdditions)
                : totalAdditions.toString(),
            icon: Icons.price_change_outlined,
            color: redTextColor,
            valueColor: redTextColor.withOpacity(0.2),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            isAconnt ? 'المبالغ المستلمة' : 'المبالغ المسلمة',
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
                : isAconnt
                    ? 'المستحق $isDebtCust'
                    : 'المستحق $isDebtAgnt',
            outstanding > 0
                ? _dbHelper.getNumberFormat(outstanding)
                : finlOgstin.toInt().toString(),
            icon: outstanding == 0
                ? Icons.money_off
                : isDebt
                    ? Icons.monetization_on_outlined
                    : Icons.warning_amber_rounded,
            color: isAconnt
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
                if (_selectedView == 'customers') {
                  inputInterfaceType = true;
                } else {
                  inputInterfaceType = false;
                }
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
                _selectedView == 'customers'
                    ? _deleteCustomer(id)
                    : _deleteAgent(id);
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
                if (_selectedView == 'customers') {
                  inputInterfaceType = true;
                } else {
                  inputInterfaceType = false;
                }
                Navigator.of(context).pop();
                _showAddCustomerOperationDialog(id);
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
                      iscontun: isAconnt,
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
        _customers.sort((a, b) => b['outstanding'].compareTo(a['outstanding']));
        _agents.sort((a, b) => b['outstanding'].compareTo(a['outstanding']));
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
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Color(0xFF03A9F4),
                                Color(0xFF01608B)
                              ]),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Column(children: const [
                              Icon(
                                Icons.sort_by_alpha_rounded,
                                color: Colors.white,
                                size: 24.0,
                              ),
                              Text(
                                'ترتيب حسب',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ])),
                        Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                    isActive:
                                        tempSortBy == 'المبلغ الأكبر أولاً',
                                    onTap: () {
                                      setStateDialog(() =>
                                          tempSortBy = 'المبلغ الأكبر أولاً');
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
                                color: greenTextColor,
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
                  ))),
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
        backgroundColor: Colors.redAccent.shade400,
        duration: const Duration(seconds: 7),
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
                inputInterfaceType ? primaryColorCustomer : primaryColorAgen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color:
                  inputInterfaceType ? primaryColorCustomer : primaryColorAgen,
              width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color:
                  inputInterfaceType ? primaryColorCustomer : primaryColorAgen,
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.cyan.shade700 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.black12 : Colors.cyan.shade700,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.cyan.shade700),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isActive ? Colors.white : Colors.cyan.shade700,
                ),
              ),
            ),
            if (isActive)
              const Icon(
                Icons.check,
                color: Colors.white,
                size: 30,
              ),
            const SizedBox(
              width: 10,
            )
          ],
        ),
      ),
    );
  }

  //  جدول العملاء
  Widget _buildTableCustomers() {
    return CustomerTable(
      one: true,
      shcerPage: false,
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
      scrollController: _scrollController,
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
              colorTitle: const Color(0xFF03A9F4),
              onBackPress: () => Navigator.pop(context),
              onIcon1Press: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionPage(),
                  ),
                );
              },
              icon1Press: Icons.account_balance_wallet,
              color1Press: const Color(0xFFFF9800),
              onIcon2Press: () {
                Navigator.push(
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
                      _pageControllerTwo.animateToPage(0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut),
                    },
                    color1Press: _selectedView == 'customers'
                        ? primaryColorCustomer
                        : const Color(0xABFFFFFF),
                    color1PressChildrn: _selectedView == 'customers'
                        ? Colors.white
                        : Colors.grey,
                    onBack2Press: () => {
                      _pageControllerTwo.animateToPage(1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut),
                    },
                    color2Press: _selectedView == 'agents'
                        ? primaryColorAgen
                        : const Color(0xABFFFFFF),
                    color2PressChildrn:
                        _selectedView == 'agents' ? Colors.white : Colors.grey,
                    color3Press: const Color(0xFF03A9F4),
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
                      controller: _pageControllerTwo,
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
                      backgroundColor: const Color(0xFF03A9F4),
                      onPressed: () => _chooseTypeAccountAdd(),
                      elevation: 4,
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 30),
                    )
                  : null,
            ),
            bottomNavigationBar: ActionButtonL(
              showBars: _showBars,
              icon1Press: Icons.search_outlined,
              color1Press: const Color(0xFF03A9F4),
              onIcon1Press: () {
                setState(() {
                  _showSearchField = !_showSearchField;
                  _searchQuery = '';
                });
              },
              icon2Press: Icons.info_outline,
              color2Press: _selectedView == 'customers'
                  ? primaryColorCustomer
                  : primaryColorAgen,
              onIcon2Press: _showTotalSummaryDialog,
            )));
  }

  //     نافذة اضافة عملية
  void _showAddCustomerOperationDialog(int id) {
    final typetransaction = inputInterfaceType ? 'إضافة' : 'قرض';
    final typetransactionViw = inputInterfaceType ? ' دين ' : 'قرض';
    final primaryColor =
        inputInterfaceType ? primaryColorCustomer : primaryColorAgen;
    final iconFunction = inputInterfaceType ? iconCustomer : iconAgeen;

    CustomDialog.show(
        context: context,
        headerColor: primaryColor,
        icon: iconFunction,
        title: inputInterfaceType
            ? 'اضافة عملية الى حساب عميل'
            : 'اضافة عملية الى حساب مورد',
        contentChildren: [
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
            onEditingComplete: () => FocusScope.of(context).nextFocus(),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTransactionTypeButton(
                label: typetransactionViw,
                isSelected: _transactionType == typetransaction,
                color: redTextColor,
                onTap: () {
                  setState(() {
                    _transactionType = typetransaction;
                  });
                  inputInterfaceType
                      ? _saveTransactionToDatabase(id)
                      : _saveAgentOperation(id);

                  Navigator.pop(context);
                },
              ),
              _buildTransactionTypeButton(
                label: 'تسديد',
                isSelected: _transactionType == 'تسديد',
                color: greenTextColor,
                onTap: () {
                  setState(() {
                    _transactionType = 'تسديد';
                  });
                  inputInterfaceType
                      ? _saveTransactionToDatabase(id)
                      : _saveAgentOperation(id);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
        ]);
  }

  //    حفظ العملية للعملاء
  void _saveTransactionToDatabase(int id) async {
    double? amount = double.tryParse(_phoneController.text.trim());
    String details = _nameController.text.trim();

    if (amount == null || amount <= 0) {
      _showErrorMessage('يرجى اختيار عميل صحيح ومبلغ أكبر من 0');
      return;
    }
    await DatabaseHelper().insertOperation(
      id,
      amount,
      details,
      _transactionType,
    );

    if (_transactionType == 'تسديد') {
      final dbHelper = DatabaseHelper();
      String type = 'كسب';
      String detailsNum = '🙎‍♂️ ${_nameController.text}';
      await dbHelper.insertDailyTransaction(amount, detailsNum, type);
    }
    _nameController.clear();
    _phoneController.clear();
    _transactionType = '';

    _loadCustomers();
    _showSuccessMessage('تم حفظ العملية بنجاح');
  }

  //    حفظ العملية للوكلاء
  void _saveAgentOperation(int id) async {
    if (_transactionType.isNotEmpty) {
      double? amount = double.tryParse(_phoneController.text.trim());
      String details = _nameController.text.trim();

      if (amount == null || amount <= 0) {
        _showErrorMessage('يرجى اختيار وكيل صحيح ومبلغ أكبر من 0');

        return;
      }

      await DatabaseHelper().insertAgentOperation(
        id,
        amount,
        details,
        _transactionType,
      );

      if (_transactionType == 'تسديد') {
        String type = 'صرف';
        String detailsNum = '🏭 تسديد  ${_nameController.text}';
        final dbHelper = DatabaseHelper();
        await dbHelper.insertDailyTransaction(amount, detailsNum, type);
      }

      _nameController.clear();
      _phoneController.clear();
      _transactionType = '';
      _loadAgents();
      _showSuccessMessage('تم حفظ العملية بنجاح');
    } else {
      _showErrorMessage('يرجى اختيار نوع العملية');
    }
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
}

// =====================================
//  ------------- النهاية
//  ------------- 2025/5/29
// =====================================

 