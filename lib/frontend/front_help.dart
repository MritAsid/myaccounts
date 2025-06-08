import 'package:flutter/material.dart';

final redTextColor = Colors.redAccent.shade700;
const greenTextColor = Color(0xFF00933D);

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color colorTitle;
  final VoidCallback onBackPress;
  final VoidCallback onIcon1Press;
  final IconData icon1Press;
  final Color color1Press;
  final VoidCallback onIcon2Press;
  final IconData icon2Press;
  final Color color2Press;

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.colorTitle,
    required this.onBackPress,
// =================1
    required this.onIcon1Press,
    required this.color1Press,
    required this.icon1Press,
// =================2
    required this.onIcon2Press,
    required this.icon2Press,
    required this.color2Press,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // var colorTitle;
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF59CEE3), // أزرق فاتح مائل للنعناع

              Color(0xFF00B4D8), // أزرق سماوي متوسط
              Color(0xFF008091), // أزرق مخضر داكن
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          //  decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
            // colorTitle.withOpacity(0.3).withGreen(0),
            colorTitle,
            colorTitle.withGreen(120),
          ]),
          // color: colorTitle,
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
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16.0,
            color: Colors.white,
          ),
        ),
      ),
      elevation: 3,
      leading: _buildActionButtonTow(
        icon: Icons.home,
        color: Colors.cyan.shade600,
        onTap: () {
          Navigator.pop(context);
        },
      ),
      centerTitle: true,
      actions: [
        _buildActionButtonTow(
          icon: icon1Press,
          color: color1Press,
          onTap: onIcon1Press,
        ),
        _buildActionButtonTow(
          icon: icon2Press,
          color: color2Press,
          onTap: onIcon2Press,
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ActionButtonL extends StatelessWidget implements PreferredSizeWidget {
  final bool showBars;

  final VoidCallback onIcon1Press;
  final IconData icon1Press;
  final Color color1Press;
  final VoidCallback onIcon2Press;
  final IconData icon2Press;
  final Color color2Press;

  const ActionButtonL({
    Key? key,

    // =================1
    required this.showBars,
    required this.onIcon1Press,
    required this.color1Press,
    required this.icon1Press,
// =================2
    required this.onIcon2Press,
    required this.icon2Press,
    required this.color2Press,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: showBars ? 62 : 0,
      child: showBars
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF59CEE3), // أزرق فاتح مائل للنعناع

                    Color(0xFF00B4D8), // أزرق سماوي متوسط

                    Color(0xFF008091), //
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: BottomAppBar(
                  // color: Colors.transparent,
                  elevation: 0,
                  notchMargin: 8.0,
                  shape:
                      const CircularNotchedRectangle(), // إنشاء فراغ دائري للزر العام

                  color: const Color(0x28004C58),
                  // color: Color(0x00FBFBFB),
                  // shape: const CircularNotchedRectangle(),
                  // notchMargin: 6,
                  child: SingleChildScrollView(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButtonTow(
                          icon: icon1Press,
                          color: color1Press,
                          onTap: onIcon1Press,
                        ),
                        const SizedBox(width: 48), // مساحة للأيقونة الوسطى

                        _buildActionButtonTow(
                          icon: icon2Press,
                          color: color2Press,
                          onTap: onIcon2Press,
                        ),
                      ],
                    ),
                  )))
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomerTable extends StatelessWidget {
  final bool one;
  final bool shcerPage;

  final List<Map<String, dynamic>> customers;
  final String searchQuery;
  final ScrollController scrollController;
  final Function(Map<String, dynamic> customer) onTap;

  final dynamic dbHelper;

  const CustomerTable({
    super.key,
    required this.customers,
    required this.searchQuery,
    required this.scrollController,
    required this.onTap,
    required this.dbHelper,
    required this.one,
    required this.shcerPage,
  });

  @override
  Widget build(BuildContext context) {
    final filteredList = customers
        .where((item) => item[one
                ? 'name'
                : !shcerPage
                    ? 'client_name'
                    : 'details']
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();
    final primaryColorCustomer = Colors.blue.shade600;

    final lightColorCustomer = Colors.blue.shade100;
    // double tupeAllMomnt = 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCFFFFFFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: primaryColorCustomer, width: 2),
      ),
      margin: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: primaryColorCustomer,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Expanded(
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    !shcerPage ? 'الاسم' : 'التفاصيل',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    one ? 'المستحق لك' : 'المبلغ',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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
                    controller: scrollController,
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];

                      final outstanding =
                          one ? item['outstanding'] : item['amount'];
                      final textColor = one
                          ? outstanding > 0
                              ? redTextColor
                              : outstanding < 0
                                  ? greenTextColor
                                  : Colors.black87
                          : item['type'] == 'تسديد'
                              ? greenTextColor
                              : redTextColor;
                      double finlOgstin = 0;
                      if (outstanding == 0) {
                        finlOgstin = -outstanding.toDouble();
                      }
                      // حساب الرصيد المرحلي
                      // if (shcerPage) {
                      //   final isAddition =
                      //       item['type'] == 'إضافة' || item['type'] == 'قرض';
                      //   if (isAddition) {
                      //     tupeAllMomnt += item['amount'];
                      //   } else {
                      //     tupeAllMomnt -= item['amount'];
                      //   }
                      // }

                      // إضافة الرصيد المرحلي إلى العنصر
                      // final itemWithMoment = shcerPage
                      //     ? {...item, 'tupeAllMomnt': tupeAllMomnt}
                      //     : item;
                      return Container(
                        decoration: BoxDecoration(
                          color: index % 2 == 0
                              ? lightColorCustomer.withOpacity(0.3)
                              : const Color(0x8DFFFFFF),
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
                            // onTap(itemWithMoment);
                            onTap(item);
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Icon(
                                  Icons.info_rounded,
                                  color: one ? primaryColorCustomer : textColor,
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
                                    item[one
                                        ? 'name'
                                        : !shcerPage
                                            ? 'client_name'
                                            : 'details'],
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
                                  outstanding != 0
                                      ? dbHelper.getNumberFormat(outstanding)
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
        ],
      ),
    );
  }
}

class AgentTable extends StatelessWidget {
  final bool one;
  final bool shcerPage;
  final List<Map<String, dynamic>> agents;
  final String searchQuery;
  final ScrollController scrollController;
  final Function(Map<String, dynamic> agent) onTap;

  final dynamic dbHelper;

  const AgentTable({
    super.key,
    required this.agents,
    required this.searchQuery,
    required this.scrollController,
    required this.onTap,
    required this.dbHelper,
    required this.one,
    required this.shcerPage,
  });

  @override
  Widget build(BuildContext context) {
    final filteredList = agents
        .where((item) => item[one
                ? 'name'
                : !shcerPage
                    ? 'agent_name'
                    : 'details']
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();
    final lightColoAgenr = Colors.teal.shade100;
    // double tupeAllMomnt = 0;

    final primaryColorAgen = Colors.teal.shade600;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCFFFFFFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: primaryColorAgen, width: 2),
      ),
      margin: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: primaryColorAgen,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Expanded(
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    !shcerPage ? 'الاسم' : 'التفاصيل',
                    // 'الاسم',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    one ? 'المستحق عليك' : 'المبلغ',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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
                    controller: scrollController,
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final outstanding =
                          one ? item['outstanding'] : item['amount'];
                      final textColor = one
                          ? outstanding > 0
                              ? redTextColor
                              : outstanding < 0
                                  ? greenTextColor
                                  : Colors.black87
                          : item['type'] == 'تسديد'
                              ? greenTextColor
                              : redTextColor;

                      double finlOgstin = 0;
                      if (outstanding < 0) {
                        finlOgstin = -outstanding.toDouble();
                      }
                      /*    if (shcerPage) {
                        final isAddition =
                            item['type'] == 'إضافة' || item['type'] == 'قرض';
                        if (isAddition) {
                          tupeAllMomnt += item['amount'];
                        } else {
                          tupeAllMomnt -= item['amount'];
                        }
                      } */

                      // حساب الرصيد المرحلي
                      // if (shcerPage) {
                      //   final isAddition =
                      //       item['type'] == 'إضافة' || item['type'] == 'قرض';
                      //   if (isAddition) {
                      //     tupeAllMomnt += item['amount'];
                      //   } else {
                      //     tupeAllMomnt -= item['amount'];
                      //   }
                      // }

                      // // إضافة الرصيد المرحلي إلى العنصر
                      // final itemWithMoment = shcerPage
                      //     ? {...item, 'tupeAllMomnt': tupeAllMomnt}
                      //     : item;
                      return Container(
                        decoration: BoxDecoration(
                          color: index % 2 == 0
                              ? lightColoAgenr.withOpacity(0.3)
                              : const Color(0x8DFFFFFF),
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
                            onTap(item);
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Icon(
                                  Icons.info_rounded,
                                  color: one ? primaryColorAgen : textColor,
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
                                          color: primaryColorAgen, width: 1.4),
                                      right: BorderSide(
                                          color: primaryColorAgen, width: 1.4),
                                    ),
                                  ),
                                  child: Text(
                                    item[one
                                        ? 'name'
                                        : !shcerPage
                                            ? 'agent_name'
                                            : 'details'],
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
                                  outstanding > 0
                                      ? dbHelper.getNumberFormat(outstanding)
                                      : finlOgstin.toInt().toString(),
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
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class TabBarBody extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final bool showSearchField;

  final VoidCallback onBackPress;
  final Color color1Press;
  final Color color1PressChildrn;

  final VoidCallback onBack2Press;
  final Color color2Press;
  final Color color2PressChildrn;
  final Color color3Press;

  final VoidCallback onBack3Press;
  final IconData icon3Press;
  final String title;

  final VoidCallback onBackShears;
  final ValueChanged<String> onSearchChanged;
  final String searchQuery;

  const TabBarBody({
    Key? key,
    required this.height,
    required this.showSearchField,
    required this.onBackPress,
    required this.color1Press,
    required this.color1PressChildrn,
    required this.onBack2Press,
    required this.color2Press,
    required this.color2PressChildrn,
    required this.onBack3Press,
    required this.icon3Press,
    required this.color3Press,
    required this.title,
    required this.onBackShears,
    required this.onSearchChanged,
    required this.searchQuery,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: height,
      child: SingleChildScrollView(
        child: Container(
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
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: showSearchField ? _buildSearchField() : _buildActions(),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  onPressed: onBackShears,
                ),
              ),
              onChanged: onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      // أيقونة عرض العملاء
      GestureDetector(
        onTap: onBackPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: color1Press,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.black54.withOpacity(0.6), width: 1.0),
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
                color: color1PressChildrn,
                size: 25,
              ),
              Text(
                'العملاء',
                style: TextStyle(
                  fontSize: 10.0,
                  color: color1PressChildrn,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),

      GestureDetector(
        onTap: onBack3Press,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            // color: color3Press,
            gradient: LinearGradient(colors: [
              // colorTitle.withOpacity(0.3).withGreen(0),
              color3Press,
              color3Press.withGreen(120),
            ]),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.black54.withOpacity(0.6), width: 1.0),
          ),
          child: Column(
            children: [
              Icon(
                icon3Press,
                color: Colors.white,
                size: 25,
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),

      // أيقونة عرض الوكلاء
      GestureDetector(
        onTap: onBack2Press,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: color2Press,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.black54.withOpacity(0.6), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.business_rounded,
                color: color2PressChildrn,
                size: 28,
              ),
              Text(
                'الموردين',
                style: TextStyle(
                  fontSize: 9.5,
                  color: color2PressChildrn,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}

// import 'package:flutter/material.dart';
// import 'package:bootstrap_icons/bootstrap_icons.dart';

class CustomDialog extends StatelessWidget implements PreferredSizeWidget {
  final IconData icon;
  final String title;
  final String? infoText;
  final List<Widget> contentChildren;
  final Color headerColor;

  const CustomDialog({
    Key? key,
    required this.icon,
    required this.title,
    this.infoText,
    required this.contentChildren,
    this.headerColor = const Color(0xFF007BFF), // لون افتراضي
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
              // رأس النافذة
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // أيقونة إجبارية
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 24.0,
                    ),
                    // عنوان النافذة إجباري
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    // معلومة نص اختيارية
                    if (infoText != null)
                      Text(
                        infoText!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              // محتويات النافذة
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: contentChildren,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // دالة مساعدة لعرض النافذة
  static Future<T?> show<T>({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? infoText,
    required List<Widget> contentChildren,
    Color headerColor = const Color(0xFF007BFF),
  }) {
    return showDialog<T>(
      context: context,
      builder: (context)
          //  {
          //   return StatefulBuilder(
          //     builder: (context, setState) {
          //       return CustomDialog(
          //         icon: icon,
          //         title: title,
          //         infoText: infoText,
          //         contentChildren: contentChildren,
          //         headerColor: headerColor,
          //       );
          //     },
          //   );
          // }

          =>
          CustomDialog(
        icon: icon,
        title: title,
        infoText: infoText,
        contentChildren: contentChildren,
        headerColor: headerColor,
      ),
    );
  }
}

//  ايقونات الرائس والفوتر
Widget _buildActionButtonTow({
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    child: Container(
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black54.withOpacity(0.2), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.4),
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
 
 
// ================================