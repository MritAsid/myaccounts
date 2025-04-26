import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'database/database_helper.dart';
import 'cus_man/add_delete.dart';
import 'cus_man/add_transaction.dart';
// import 'cus_man/translithelp.dart';
import 'cus_man/search.dart';
import 'dily_cont/daily_account_page.dart';
import 'dily_cont/my_box.dart';
import 'backjes/backjes.dart';
import 'my_data/personal_info_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Cairo', // تعيين خط كايرو كخط افتراضي
        brightness: isDarkMode
            ? Brightness.dark
            : Brightness.light, // التحكم بالوضع المظلم/الفاتح
        primarySwatch: Colors.cyan, // لون افتراضي للعناصر مثل AppBar
        scaffoldBackgroundColor:
            isDarkMode ? Colors.grey[900] : Colors.grey[100], // لون الخلفية
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontFamily: 'Cairo',
          ),
          bodyMedium: TextStyle(fontFamily: 'Cairo'),
          bodySmall: TextStyle(fontFamily: 'Cairo'),
          headlineLarge: TextStyle(fontFamily: 'Cairo'),
          headlineMedium: TextStyle(fontFamily: 'Cairo'),
          headlineSmall: TextStyle(fontFamily: 'Cairo'),
          titleLarge: TextStyle(fontFamily: 'Cairo'),
          titleMedium: TextStyle(fontFamily: 'Cairo'),
          titleSmall: TextStyle(fontFamily: 'Cairo'),
          labelLarge: TextStyle(fontFamily: 'Cairo'),
          labelMedium: TextStyle(fontFamily: 'Cairo'),
          labelSmall: TextStyle(
            fontFamily: 'Cairo',
          ),
        ),
      ),
      locale: const Locale('ar', 'SA'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'),
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(
          onThemeToggle: () {
            setState(() {
              isDarkMode = !isDarkMode;
            });
          },
          isDarkMode: isDarkMode,
        ),
      ),
    );
  }
}

// ===================EsmaelAsid=====================
// ===================MritAsid=====================
class HomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const HomePage(
      {super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // var _transactions = <Map<String, dynamic>>[];
  // double profitpegsho = 0;

  Widget _buildDefaultPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'مرحبًا',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.black26,
          child: Icon(Icons.account_circle, size: 70, color: Colors.white),
        ),
        SizedBox(height: 10),
        Text(
          'اضغط على "البيانات الشخصية" لإضافة بياناتك',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color.fromARGB(255, 223, 221, 255),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo(Map<String, dynamic> personalInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text(
          'مرحبًا',
          style: TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        const CircleAvatar(
          radius: 35,
          backgroundColor: Colors.grey,
          child: Icon(Icons.account_circle, size: 70, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(
          personalInfo['name'] ?? 'الاسم',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // دالة لتحديث قائمة العمليات
  // Future<void> _refreshTransactions() async {
  //   final summary = await DatabaseHelper().getTotalSummary();
  //   setState(() {
  //     _transactions = summary as List<Map<String, dynamic>>;

  //     // حساب مجموع الكسب
  //     final totalIncome = _transactions
  //         .where((transaction) => transaction['type'] == 'ادخار')
  //         .fold(0.0, (sum, transaction) => sum + transaction['amount']);

  //     // حساب مجموع الصرف
  //     final totalExpense = _transactions
  //         .where((transaction) => transaction['type'] == 'سحب')
  //         .fold(0.0, (sum, transaction) => sum + transaction['amount']);
  //     final profitpeg = totalIncome - totalExpense;
  //     profitpegsho = profitpeg;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // final summary =

    //  final outstanding = summary['totalOutstanding'].toDouble();

    return Scaffold(
      key: _scaffoldKey,

      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            size: 30,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        backgroundColor: Colors.cyan.shade600,
        elevation: 4,
        title: const Text(
          'حساباتي',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              // color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(3, 4),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyBoxScreen(),
                  ),
                );
              },

              child: Image.asset(
                'images/mybox.png', // استبدل بالمسار الصحيح للصورة
                width: 40,
                // height: 30,
              ),
              // IconButton(
              //   icon: const Icon(Icons.monitor_weight_rounded,
              //       color: Color(0xFF999999), size: 28),
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => const MyBoxScreen(),
              //       ),
              //     );
              //   },
              // ),
            ),
          ),
          // ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.cyan.shade900,
                Colors.cyan.shade800,
                Colors.cyan.shade700,
              ],
            ),
          ),
          child: Column(
            children: [
              // الجزء العلوي الثابت (اسم التطبيق وحاوية الصورة والمعلومات)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // اسم التطبيق مع زر الإغلاق
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'حساباتي', // اسم التطبيق
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                            size: 30,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // خط فاصل أسفل اسم التطبيق
                  const Divider(
                    color: Colors.white,
                    thickness: 3.5,
                    height: 0,
                  ),

                  // حاوية الصورة مع المعلومات الشخصية
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('images/icon.png'), // صورة الخلفية
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      color: Colors.black
                          .withOpacity(0.7), // طبقة شفافة فوق الصورة
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: FutureBuilder<Map<String, dynamic>?>(
                        future: DatabaseHelper().getPersonalInfo(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            );
                          } else if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return _buildDefaultPersonalInfo();
                          } else {
                            final personalInfo = snapshot.data!;
                            final name =
                                personalInfo['name']?.toString().trim() ?? '';
                            if (name.isEmpty) {
                              return _buildDefaultPersonalInfo();
                            } else {
                              return _buildPersonalInfo(personalInfo);
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  // خط فاصل أسفل الصورة
                  const Divider(
                    color: Colors.white,
                    thickness: 3.5,
                    height: 0,
                  ),
                ],
              ),
              // الجزء القابل للتمرير (عناصر القائمة)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDrawerItem(
                        icon: Icons.brightness_6,
                        title:
                            widget.isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
                        onTap: widget.onThemeToggle,
                      ),
                      const Divider(
                        color: Colors.white,
                        thickness: 1.5,
                        height: 1,
                        indent: 30,
                        endIndent: 30,
                      ),
                      _buildDrawerItem(
                        icon: Icons.my_library_books_rounded,
                        title: 'البيانات الشخصية',
                        onTap: () async {
                          Navigator.pop(context);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const PersonalInfoPage()),
                          );
                          setState(() {});
                        },
                      ),
                      const Divider(
                        color: Colors.white,
                        thickness: 1.5,
                        height: 1,
                        indent: 30,
                        endIndent: 30,
                      ),
                      _buildDrawerItem(
                        icon: Icons.system_update,
                        title: 'التحقق من التحديث',
                        onTap: () => checkForUpdate(context),
                      ),
                      const Divider(
                        color: Colors.white,
                        thickness: 1.5,
                        height: 1,
                        indent: 30,
                        endIndent: 30,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'إصدار التطبيق: 1.0.0',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      //  ==============================
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child:

            //  Column(
            // children: [
            // Container(
            //   child: Row(
            //     children: [
            //       // Text(
            //       //   DatabaseHelper().getNumberFormat(profitpegsho),
            //       // )
            //     ],
            //   ),
            // ),
            GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildIconCard(context, Icons.assignment_ind_outlined,
                'إدارة الحسابات', Colors.blue),
            _buildIconCard(context, Icons.account_balance_wallet,
                'إضافة عملية مالية', Colors.orange),
            _buildIconCard(
                context, Icons.search, 'البحث عن حساب', Colors.green),
            _buildIconCard(context, Icons.attach_money_sharp, 'حسابي الشخصي',
                Colors.tealAccent),
            _buildIconCard(context, Icons.backup_outlined, 'النسخ والاستعادة',
                Colors.brown),
            _buildIconCard(
                context, Icons.book_rounded, 'مذكرتي', Colors.redAccent),
          ],
        ),
        // ],
        // ),
      ),
    );
  }

  Widget _buildIconCard(
      BuildContext context, IconData icon, String label, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (label == 'إدارة الحسابات') {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AddDeletePage()));
          } else if (label == 'إضافة عملية مالية') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddTransactionPage()));
          } else if (label == 'البحث عن حساب') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SearchClientPage()));
          } else if (label == 'حسابي الشخصي') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DailyAccountPage()));
          } else if (label == 'النسخ والاستعادة') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BackupRestorePage()));
          } else if (label == 'مذكرتي') {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const MyBoxScreen()));
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 26),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      trailing: const Icon(Icons.arrow_left, color: Colors.white70),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      tileColor: Colors.transparent,
      hoverColor: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

// =================================================
void checkForUpdate(BuildContext context) async {
  const String githubVersionUrl =
      "https://raw.githubusercontent.com/AbdullahAskarEgypt/myaccounts_pro/refs/heads/main/version.json";
  const String updateUrl =
      "https://abdullahaskaregypt.github.io/Html-And-Css-Template-Three/";

  // ✅ إغلاق القائمة الجانبية
  Navigator.pop(context);

  // ✅ التحقق من الاتصال بالإنترنت
  bool isConnected = await DatabaseHelper.isConnectedToInternet();

  if (!isConnected) {
    if (context.mounted) {
      // تأكد من أن `context` لا يزال متاحًا
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ تحقق من الوصول للإنترنت"),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }

  try {
    // ✅ جلب رقم الإصدار الجديد من GitHub
    final response = await http.get(Uri.parse(githubVersionUrl));
    if (response.statusCode == 200) {
      Map<String, dynamic> latestData = jsonDecode(response.body);
      String latestVersion = latestData["latest_version"];

      // ✅ جلب رقم الإصدار المحلي من التطبيق
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // ✅ عرض النافذة
      if (context.mounted) {
        // تأكد من أن `context` لا يزال متاحًا

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // حواف مستديرة
            ),
            title: Row(
              children: const [
                Icon(Icons.info_outline,
                    color: Colors.blue, size: 24), // أيقونة بجانب العنوان
                SizedBox(width: 8),
                Text(
                  "التحقق من رقم الإصدار",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVersionRow("رقم الإصدار المحلي:", currentVersion),
                const SizedBox(height: 10),
                _buildVersionRow("رقم الإصدار الجديد:", latestVersion),
                const SizedBox(height: 20),
                if (currentVersion == latestVersion)
                  Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "✅ تطبيقك محدث إلى آخر إصدار",
                        style:
                            TextStyle(color: Colors.green, fontFamily: 'Cairo'),
                      ),
                    ],
                  )
                else
                  Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "⚠️ هناك إصدار جديد متاح!",
                        style: TextStyle(
                            color: Colors.orange, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
              ],
            ),
            actions: [
              if (currentVersion != latestVersion)
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context); // إغلاق النافذة
                    if (await canLaunchUrl(Uri.parse(updateUrl))) {
                      await launchUrl(Uri.parse(updateUrl));
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("❌ فشل في فتح الرابط",
                                style: TextStyle(fontFamily: 'Cairo')),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    "تحديث الآن",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context), // إغلاق النافذة
                child: Text(
                  "لاحقًا",
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      if (context.mounted) {
        // تأكد من أن `context` لا يزال متاحًا
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ فشل في التحقق من التحديث"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      // تأكد من أن `context` لا يزال متاحًا
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ خطأ أثناء جلب التحديث: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ويدجت مخصص لعرض بيانات الإصدار
Widget _buildVersionRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 14,
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    ],
  );
}
