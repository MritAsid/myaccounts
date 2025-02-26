import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'database/database_helper.dart';
import 'cus_man/add_delete.dart';
import 'cus_man/add_transaction.dart';
import 'cus_man/search.dart';
import 'dily_cont/daily_account_page.dart';
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
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      locale: const Locale('ar', 'SA'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'),
      ],
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

  Widget _buildDefaultPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'مرحبًا',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        SizedBox(
          width: double.infinity,
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.black26,
            child: Icon(Icons.account_circle, size: 60, color: Colors.white),
          ),
        ),
        SizedBox(height: 10),
        Text(
          'قم بإضغط على "البيانات الشخصية" لااضافة بياناتك',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: Color.fromARGB(255, 223, 221, 255),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
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
              fontSize: 24, color: Colors.white, fontWeight: FontWeight.w600),
          textAlign: TextAlign.start,
        ),
        const SizedBox(
          width: double.infinity,
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey,
            child: Icon(Icons.account_circle, size: 60, color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          personalInfo['name'] ?? 'الاسم',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: const Text(
          ' حساباتي',
          style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w800),
        ),
        actions: const [
          Icon(Icons.wallet_outlined, size: 40, color: Colors.tealAccent),
          SizedBox(width: 28),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.cyan,
                Color(0xFF0091A4),
                Color(0xFF00707F),
              ],
            ),
          ),
          child: Column(
            children: [
              // اسم التطبيق مع زر الإغلاق
              Container(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'حساباتي', // اسم التطبيق
                      style: TextStyle(
                        fontSize: 24,
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
                  color: Colors.black.withOpacity(0.7), // طبقة شفافة فوق الصورة
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: DatabaseHelper().getPersonalInfo(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white));
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        // حالة الخطأ أو عدم وجود بيانات
                        return _buildDefaultPersonalInfo();
                      } else {
                        final personalInfo = snapshot.data!;
                        final name = personalInfo['name']?.toString().trim() ??
                            ''; // إزالة المسافات والتحقق من وجود حروف

                        // إذا كان الاسم فارغًا أو يحتوي على مسافات فقط
                        if (name.isEmpty) {
                          return _buildDefaultPersonalInfo();
                        } else {
                          // إذا كان الاسم يحتوي على حروف
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

              // عناصر القائمة
              _buildDrawerItem(
                icon: Icons.brightness_6,
                title: widget.isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
                onTap: widget.onThemeToggle,
              ),
              const Divider(
                  color: Colors.white,
                  thickness: 1.5,
                  height: 1,
                  indent: 30,
                  endIndent: 30),

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
                  setState(() {}); // تحديث الواجهة عند العودة
                },
              ),
              const Divider(
                  color: Colors.white,
                  thickness: 1.5,
                  height: 1,
                  indent: 30,
                  endIndent: 30),

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
                  endIndent: 30),
              // مسافة في الأسفل
              const Spacer(),

              const Text(
                'إصدار التطبيق: 1.0.0',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 16,
          children: [
            _buildIconCard(context, Icons.assignment_ind_outlined,
                'إدارة الحسابات', Colors.blue),
            _buildIconCard(context, Icons.account_balance_wallet,
                'إضافة عملية مالية', Colors.orange),
            _buildIconCard(
                context, Icons.search, 'البحث عن حساب', Colors.green),
            _buildIconCard(context, Icons.attach_money_sharp, 'حسابي الشخصي',
                Colors.tealAccent),
            _buildIconCard(context, Icons.backup_outlined, 'النسخ  والاستعاده',
                Colors.brown),
            _buildIconCard(
                context, Icons.book_rounded, 'مذكرتي', Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildIconCard(
      BuildContext context, IconData icon, String label, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          } else if (label == 'النسخ  والاستعاده') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BackupRestorePage()));
          } else if (label == 'مذكرتي') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BackupRestorePage()));
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لإنشاء عناصر الـ Drawer بشكل موحد
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 28),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      trailing:
          const Icon(Icons.arrow_left, color: Colors.white70), // للغة العربية
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
            title: const Text("التحقق من رقم الإصدار"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("رقم الإصدار المحلي: $currentVersion"),
                const SizedBox(height: 10),
                Text("رقم الإصدار الجديد: $latestVersion"),
                const SizedBox(height: 20),
                if (currentVersion == latestVersion)
                  const Text("✅ تطبيقك محدث إلى آخر إصدار")
                else
                  const Text("⚠️ هناك إصدار جديد متاح!"),
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
                        // تأكد من أن `context` لا يزال متاحًا
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("❌ فشل في فتح الرابط"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text("موافق"),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context), // إغلاق النافذة
                child: const Text("لاحقًا"),
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
