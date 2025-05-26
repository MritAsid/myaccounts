// ==============Asmael Asid ====================================
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../database/database_helper.dart';
import 'add_transaction.dart';
import 'search.dart';
import '../frontend/front_help.dart';
import 'package:icons_plus/icons_plus.dart';

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
  bool _saveAccount = true;

  final primaryColorCustomer = Colors.blue.shade600;
  final primaryColorAgen = Colors.green.shade600;
  final lightColorCustomer = Colors.blue.shade100;
  final lightColoAgenr = Colors.green.shade100;
  final redTextColor = Colors.red.shade700;
  final greenTextColor = Colors.green.shade700;

  final iconCustomer = Icons.person;

  final iconAgeen = Icons.business_rounded;
  final iconAgeen2 = Bootstrap.building;
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
  // اضهار معلومات المبلغ
  final GlobalKey _debtKey = GlobalKey();

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
      _originalCustomers = List.from(data); // حفظ نسخة أصلية
    });
  }

  // تحميل الموردين
  void _loadAgents() async {
    final data = await _dbHelper.getAllAgentsAndMount();

    toMyAgn = 0.0;
    onMyAgn = 0.0;

    setState(() {
      _agents = data;
      _originalAgents = List.from(data); // حفظ نسخة أصلية
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
                        icon: iconAgeen,
                        color: primaryColorAgen,
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
    final colorFunction =
        _saveAccount ? primaryColorCustomer : primaryColorAgen;
    final iconFunction = _saveAccount ? iconCustomer : iconAgeen;

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
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
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: colorFunction,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(iconFunction, size: 25, color: Colors.white),
                        Text(
                          _saveAccount ? 'إضافة عميل جديد' : 'إضافة مورد جديد',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        const SizedBox(height: 10.0),
                        _buildInputField(
                          controller: _nameController,
                          label: 'الاسم',
                          icon: iconFunction,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () =>
                              FocusScope.of(context).nextFocus(),
                        ),
                        const SizedBox(height: 20),
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
                          label: _saveAccount ? 'حفظ العميل' : 'حفظ المورد',
                          icon: Icons.save,
                          color: Colors.green.shade400,
                          onPressed: _saveAccount ? _saveCustomer : _saveAgent,
                        ),
                      ),
                      const SizedBox(width: 20.0),
                    ],
                  ),
                  const SizedBox(height: 10),
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
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      _showErrorMessage('يرجى إدخال جميع البيانات');
    }
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
      _showSuccessMessage('تم حفظ المورد بنجاح');
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

  // تعديل حساب عميل او مورد
  void _updateCustomer(int id, String name, String phone) async {
    _nameController.text = name;
    _phoneController.text = phone;

    final colorFunction =
        _saveAccount ? primaryColorCustomer : primaryColorAgen;
    final iconFunction = _saveAccount ? iconCustomer : iconAgeen;

    showDialog(
      context: context,
      builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
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
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  decoration: BoxDecoration(
                    color: colorFunction,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                  ),
                  child: Column(children: [
                    Icon(iconFunction, size: 28, color: Colors.white),
                    Text(
                      _selectedView == 'customers'
                          ? 'تعديل بيانات عميل'
                          : 'تعديل بيانات مورد',
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10.0),
                      _buildInputField(
                        controller: _nameController,
                        label: 'الاسم',
                        icon: iconFunction,
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () =>
                            FocusScope.of(context).nextFocus(),
                      ),
                      const SizedBox(height: 20),
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
                      icon: Icons.save_as_rounded,
                      color: Colors.green.shade400,
                      onPressed: () {
                        if (_saveAccount) {
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
              ],
            )),
          )),
    );
  }

  // اضهار معلومات المبالغ
  void _showTooltip(BuildContext context, String message, GlobalKey key) {
    final overlay = Overlay.of(context);
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size;
    final offset = renderBox?.localToGlobal(Offset.zero);

    if (size == null || offset == null) return;

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy - size.height + 15,
        width: size.width,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 5), () {
      entry.remove();
    });
  }

  //  نافذة  ملخص العملاء او الموردين
  void _showTotalSummaryDialog() async {
    final summary = _selectedView == 'customers'
        ? await _dbHelper.getTotalSummary()
        : await _dbHelper.getTotalAgeensSummary();
    final colorFunction =
        _selectedView == 'customers' ? primaryColorCustomer : primaryColorAgen;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        final isAconnt = _selectedView == 'customers';

        final outstanding = isAconnt ? toMyCou : toMyAgn;
        final outstandingRvers = isAconnt ? onMyCou : onMyAgn;

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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: colorFunction,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _selectedView == 'customers'
                              ? Bootstrap.people_fill
                              : Icons.business_rounded,
                          color: Colors.white,
                          size: 24.0,
                          semanticLabel:
                              'Text to announce in accessibility modes',
                        ),
                        Text(
                          _selectedView == 'customers'
                              ? 'تفاصيل حسابات العملاء'
                              : ' تفاصيل حسابات الموردين',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'عدد الحسابات :  ${summary['totalCustomers']} ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(
                          icon: FontAwesome.money_check_dollar,
                          title:
                              isAconnt ? 'الديون المستحقة' : 'القروض المستحقة',
                          value: _dbHelper
                              .getNumberFormat(summary['totalAdditions']),
                          color: Colors.red.shade100,
                          valueColor: redTextColor,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryCard(
                          icon: Icons.money_rounded,
                          title: 'المدفوعات النقدية',
                          value: outstandingRvers > 0
                              ? _dbHelper.getNumberFormat(
                                  summary['totalPayments'] - outstandingRvers)
                              : _dbHelper
                                  .getNumberFormat(summary['totalPayments']),
                          color: Colors.green.shade100,
                          valueColor: greenTextColor,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryCard(
                          icon: outstanding > 0
                              ? FontAwesome.sack_dollar
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
                              ? isAconnt
                                  ? lightColoAgenr
                                  : redTextColor.withOpacity(0.3)
                              : Colors.grey.shade400,
                          valueColor: outstanding > 0
                              ? isAconnt
                                  ? greenTextColor
                                  : redTextColor
                              : Colors.black54,
                        ),
                        if (outstandingRvers > 0) const SizedBox(height: 16),
                        if (outstandingRvers > 0)
                          Text(
                            '*  ملاحظة ',
                            style: TextStyle(
                                color: redTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w800),
                          ),
                        const SizedBox(height: 8),
                        if (outstandingRvers > 0)
                          GestureDetector(
                            key: _debtKey,
                            onTap: () => _showTooltip(
                              context,
                              _selectedView == 'customers'
                                  ? 'إجمالي المبالغ التي يجب أن تدفعها للعملاء'
                                  : 'إجمالي المبالغ التي يجب أن تدفعها للموردين',
                              _debtKey,
                            ),
                            child: _buildSummaryCard(
                                icon: isAconnt
                                    ? Icons.remove_circle
                                    : Icons.add_circle,
                                title: isAconnt
                                    ? 'مبالغ  دفعها العملاء مقدمأ'
                                    : 'مبالغ  دفعتها للموردين مقدمأ',
                                value:
                                    _dbHelper.getNumberFormat(outstandingRvers),
                                valueColor:
                                    isAconnt ? redTextColor : greenTextColor,
                                color: isAconnt
                                    ? redTextColor.withOpacity(0.3)
                                    : lightColoAgenr),
                          ),
                      ],
                    ),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // نافذة تفاصيل  العميل او المور
  void _showCustomerDetails(String name, String phone, int id,
      final totalAdditions, final totalPayments, final outstanding) async {
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

    final isAconnt = _selectedView == 'customers';
    final iconFunction = isAconnt ? iconCustomer : iconAgeen;
    final isCredit = outstanding < 0;

    showDialog(
      context: context,
      builder: (context) {
        final isDebt = double.parse(outstanding.toString()) > 0;
        final isDebtCust =
            double.parse(outstanding.toString()) < 0 ? 'له' : 'علية';
        final isDebtAgnt =
            double.parse(outstanding.toString()) < 0 ? 'علية' : 'له';
        double finlOgstin = 0;

        if (outstanding < 0) {
          finlOgstin = outstanding * -1;
        }
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isAconnt ? primaryColorCustomer : primaryColorAgen,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(iconFunction, size: 28, color: Colors.white),
                        Text(
                          _selectedView == 'customers'
                              ? 'تفاصيل العميل'
                              : 'تفاصيل المورد',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildSummaryCard(
                          icon: iconFunction,
                          title: 'الاسم',
                          value: name,
                          color: isAconnt ? lightColorCustomer : lightColoAgenr,
                          valueColor:
                              isAconnt ? primaryColorCustomer : greenTextColor,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryCard(
                          icon: Icons.phone,
                          title: 'الهاتف',
                          value: phone,
                          color: isAconnt ? lightColorCustomer : lightColoAgenr,
                          valueColor:
                              isAconnt ? primaryColorCustomer : greenTextColor,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black54, width: 1),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          _selectedView == 'customers'
                              ? 'الديون المستحقة'
                              : 'القروض المستحقة',
                          totalAdditions > 0
                              ? _dbHelper.getNumberFormat(totalAdditions)
                              : totalAdditions.toString(),
                          icon: FontAwesome.money_check_dollar,
                          color: redTextColor,
                          valueColor: redTextColor.withOpacity(0.3),
                        ),
                        const Divider(
                            height: 1, color: Colors.black54, thickness: 1.0),
                        _buildSummaryRow(
                          'المدفوعات النقدية',
                          totalPayments > 0
                              ? _dbHelper.getNumberFormat(totalPayments)
                              : totalPayments.toString(),
                          icon: Icons.money_rounded,
                          color: greenTextColor,
                          valueColor: lightColoAgenr,
                        ),
                        const Divider(
                            height: 1, color: Colors.black54, thickness: 1.0),
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
                                  ? FontAwesome.sack_dollar
                                  : Icons.warning_rounded,
                          color: isAconnt
                              ? isDebt
                                  ? greenTextColor
                                  : isCredit
                                      ? redTextColor
                                      : Colors.black54
                              : isDebt
                                  ? redTextColor
                                  : isCredit
                                      ? greenTextColor
                                      : Colors.black54,
                          valueColor: isAconnt
                              ? isDebt
                                  ? lightColoAgenr
                                  : isCredit
                                      ? redTextColor.withOpacity(0.3)
                                      : Colors.grey.shade100
                              : isDebt
                                  ? redTextColor.withOpacity(0.3)
                                  : isCredit
                                      ? lightColoAgenr
                                      : Colors.grey.shade100,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: 'حذف',
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
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            label: 'تعديل',
                            icon: Icons.edit,
                            color: Colors.orange.shade600,
                            onPressed: () {
                              if (!_showBars) {
                                setState(() {
                                  _showBars = true;
                                });
                              }
                              Navigator.of(context).pop();
                              if (_selectedView == 'customers') {
                                _saveAccount = true;
                              } else {
                                _saveAccount = false;
                              }
                              _updateCustomer(id, name, phone);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            label: 'إغلاق',
                            icon: Icons.close,
                            color: Colors.blue.shade400,
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
            color: _saveAccount ? primaryColorCustomer : primaryColorAgen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: _saveAccount ? primaryColorCustomer : primaryColorAgen,
              width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: _saveAccount ? primaryColorCustomer : primaryColorAgen,
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: valueColor,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
                border: Border.all(color: valueColor, width: 1)),
            child: Icon(icon, size: 20, color: valueColor),
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
                const SizedBox(height: 10),
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

  Widget _buildTableCustomers() {
    final originalData = _customers;
    final filteredList = originalData
        .where((item) =>
            item['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: primaryColorCustomer, width: 2),
      ),
      margin: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0.0),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: primaryColorCustomer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                  controller: _scrollController,
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];

                    final outstanding = item['outstanding'];
                    final textColor = outstanding > 0
                        ? greenTextColor
                        : outstanding < 0
                            ? redTextColor
                            : Colors.black87;
                    double finlOgstin = 0;

                    if (outstanding < 0) {
                      finlOgstin = outstanding * -1;
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color:
                            index % 2 == 0 ? lightColorCustomer : Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: primaryColorCustomer,
                            width: 1.4,
                          ),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          _showCustomerDetails(
                            item['name'],
                            item['phone'],
                            item['id'],
                            item['totalAdditions'],
                            item['totalPayments'],
                            item['outstanding'],
                          );
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Icon(
                                Icons.info_rounded,
                                color: primaryColorCustomer,
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                        color: primaryColorCustomer,
                                        width: 1.4),
                                    right: BorderSide(
                                        color: primaryColorCustomer,
                                        width: 1.4),
                                  ),
                                ),
                                child: Text(
                                  item['name'],
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.start,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                item['outstanding'] > 0
                                    ? _dbHelper
                                        .getNumberFormat(item['outstanding'])
                                    : finlOgstin.toInt().toString(),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Amiri',
                                    fontWeight: FontWeight.w800,
                                    color: textColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  //  جدول الموردين
  Widget _buildTableAgents() {
    final originalData = _agents;
    final filteredList = originalData
        .where((item) =>
            item['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: primaryColorAgen, width: 2),
        ),
        margin: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0.0),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: primaryColorAgen,
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
                      controller: _scrollController,
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        final outstanding = item['outstanding'];

                        final textColor = outstanding > 0
                            ? redTextColor
                            : outstanding < 0
                                ? greenTextColor
                                : Colors.black87;
                        return Container(
                            decoration: BoxDecoration(
                              color: index % 2 == 0
                                  ? lightColoAgenr
                                  : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: primaryColorAgen,
                                  width: 1.4,
                                ),
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                FocusScope.of(context).unfocus();

                                _showCustomerDetails(
                                  item['name'],
                                  item['phone'],
                                  item['id'],
                                  item['totalAdditions'],
                                  item['totalPayments'],
                                  item['outstanding'],
                                );
                              },
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Icon(
                                      Icons.info_rounded,
                                      color: primaryColorAgen,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 5,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 8),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                              color: primaryColorAgen,
                                              width: 1.4),
                                          right: BorderSide(
                                              color: primaryColorAgen,
                                              width: 1.4),
                                        ),
                                      ),
                                      child: Text(
                                        item['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.start,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item['outstanding'] > 0
                                          ? _dbHelper.getNumberFormat(
                                              item['outstanding'])
                                          : item['outstanding']
                                              .toInt()
                                              .toString(),
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
        ]));
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
              colorTitle: primaryColorCustomer,
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
              color1Press: Colors.orange.shade700,
              onIcon2Press: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchClientPage(),
                  ),
                );
              },
              icon2Press: Icons.search_rounded,
              color2Press: Colors.greenAccent.shade700,
            ),
            body: Column(
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
                  color1PressChildrn:
                      _selectedView == 'customers' ? Colors.white : Colors.grey,
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
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            floatingActionButton: AnimatedSwitcher(
                duration: const Duration(milliseconds: 100),
                child: _showBars
                    ? FloatingActionButton(
                        backgroundColor:
                            const Color(0xFF01D1FB), // أزرق سماوي متوسط

                        onPressed: () => _showAddAccountDialog(),
                        elevation: 8,
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 30),
                      )
                    : null),
            bottomNavigationBar: ActionButtonL(
              showBars: _showBars,
              icon1Press: Icons.search_outlined,
              color1Press: Colors.greenAccent,
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
}
 
// ============== النهاية   2025/5/8==========================
