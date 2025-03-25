import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  BackupRestorePageState createState() => BackupRestorePageState();
}

class BackupRestorePageState extends State<BackupRestorePage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final google_sign_in.GoogleSignIn _googleSignIn =
      google_sign_in.GoogleSignIn(scopes: ['email']);
  Map<String, String?>? _currentUserData;

  bool _isLocalBackupLoading = false;
  bool _isLocalRestoreLoading = false;
  bool _isDriveBackupLoading = false;
  bool _isDriveRestoreLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserFromLocalStorage();
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// ✅ تحميل بيانات المستخدم المخزنة محليًا
  Future<void> _loadUserFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('user_email');
    String? displayName = prefs.getString('user_name');
    String? photoUrl = prefs.getString('user_photo');

    if (email != null) {
      setState(() {
        _currentUserData = {
          "email": email,
          "displayName": displayName,
          "photoUrl": photoUrl,
        };
      });
    }
  }

  /// ✅ حفظ بيانات المستخدم عند تسجيل الدخول
  Future<void> _saveUserToLocalStorage(
      google_sign_in.GoogleSignInAccount user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_name', user.displayName ?? '');
    await prefs.setString('user_photo', user.photoUrl ?? '');

    setState(() {
      _currentUserData = {
        "email": user.email,
        "displayName": user.displayName,
        "photoUrl": user.photoUrl,
      };
    });
  }

  /// **التحقق من الاتصال بالإنترنت** (اقتراحك)
  Future<bool> _isConnectedToInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// 🟢 تسجيل الدخول مع فحص الاتصال
  Future<void> _handleSignIn() async {
    if (!await _isConnectedToInternet()) {
      if (!mounted) return;

      Navigator.pop(context);

      _showErrorMessage('⚠️ لا يوجد اتصال بالإنترنت');
      return;
    }

    try {
      final google_sign_in.GoogleSignInAccount? user =
          await _googleSignIn.signIn();

      if (user == null) {
        return;
      }

      await _saveUserToLocalStorage(user);

      // هنا نضيف التأخير لمدة 3 ثوانٍ
      await Future.delayed(const Duration(seconds: 3)); // تأخير 3 ثوانٍ
      if (!mounted) return;

      Navigator.pop(context); // إغلاق النافذة بعد التأخير
      _showSuccessMessage('✅ تم تسجيل الدخول بنجاح: ${user.displayName}');
    } catch (error) {
      _showErrorMessage('⚠️ فشل تسجيل الدخول: $error');
    }
  }

  /// 🔴 تسجيل الخروج مع فحص الاتصال
  Future<void> _handleSignOut() async {
    if (!await _isConnectedToInternet()) {
      if (!mounted) return;

      Navigator.pop(context);

      _showErrorMessage('⚠️ لا يوجد اتصال بالإنترنت');
      return;
    }

    try {
      await _googleSignIn.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      setState(() {
        _currentUserData = null;
      });
      if (!mounted) return;

      Navigator.pop(context);
      _showSuccessMessage('✅ تم تسجيل الخروج بنجاح');
    } catch (error) {
      _showErrorMessage('⚠️ فشل تسجيل الخروج: $error');
    }
  }

  /// طلب إذن التخزين
  Future<void> requestStoragePermission(BuildContext context) async {
    if (await Permission.storage.request().isGranted) {
      // إذن الوصول ممنوح
    } else {
      _showErrorMessage('⚠️ تم رفض إذن الوصول إلى الذاكرة الخارجية');
    }
  }

  /// عمليات النسخ والاستعادة
  Future<void> _createBackup(BuildContext context) async {
    setState(() => _isLocalBackupLoading = true);
    try {
      await requestStoragePermission(context);
      final backupFile = await dbHelper.exportDatabase();
      if (!mounted) return;
      _showSuccessMessage('✅ تم إنشاء النسخة الاحتياطية: ${backupFile.path}');
    } catch (e) {
      _showErrorMessage('⚠️ فشل إنشاء النسخة الاحتياطية: $e');
    } finally {
      setState(() => _isLocalBackupLoading = false);
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    setState(() => _isLocalRestoreLoading = true);
    try {
      await requestStoragePermission(context);
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null) {
        final file = File(result.files.single.path!);
        if (await file.exists()) {
          await dbHelper.importDatabase(file);
          _showSuccessMessage('✅ تم استعادة النسخة الاحتياطية بنجاح');
        } else {
          _showErrorMessage('⚠️ الملف غير موجود');
        }
      }
    } catch (e) {
      _showErrorMessage('⚠️ فشل استعادة النسخة الاحتياطية: $e');
    } finally {
      setState(() => _isLocalRestoreLoading = false);
    }
  }

  Future<void> _backupToGoogleDrive(BuildContext context) async {
    if (!await _isConnectedToInternet()) {
      _showErrorMessage('⚠️ لا يوجد اتصال بالإنترنت');
      return;
    }

    setState(() => _isDriveBackupLoading = true);
    try {
      String result = await dbHelper.backupToGoogleDrive();
      if (!mounted) return;
      result.contains('✅')
          ? _showSuccessMessage(result)
          : _showErrorMessage(result);
    } catch (e) {
      _showErrorMessage('⚠️ فشل النسخ إلى Google Drive: $e');
    } finally {
      setState(() => _isDriveBackupLoading = false);
    }
  }

  Future<void> _restoreBackupFromGoogleDrive(BuildContext context) async {
    if (!await _isConnectedToInternet()) {
      _showErrorMessage('⚠️ لا يوجد اتصال بالإنترنت');

      return;
    }

    setState(() => _isDriveRestoreLoading = true);
    try {
      String result = await dbHelper.restoreBackupFromGoogleDrive();
      if (!mounted) return;
      result.contains('✅')
          ? _showSuccessMessage(result)
          : _showErrorMessage(result);
    } catch (e) {
      _showErrorMessage('⚠️ فشل الاستعادة من Google Drive: $e');
    } finally {
      setState(() => _isDriveRestoreLoading = false);
    }
  }

  // قائمة بالألوان المخصصة
  final List<Color> predefinedColors = [
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF9C27B0), // Light Blue
    const Color(0xFF673AB7), // Deep Purple
    const Color(0xFF795548), // Brown
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFF009688), // Blue Grey
    const Color(0xFFFFC107), // Blue Grey
  ];

  /// ✅ دالة لإرجاع لون محدد بناءً على البريد الإلكتروني
  Color getColorFromEmail(String email) {
    int hash = email.hashCode;
    int index = hash % predefinedColors.length; // اختيار لون من القائمة
    return predefinedColors[index];
  }

  /// دالة لإرجاع الحرف الأول من الاسم
  String getInitials(String name) {
    if (name.isEmpty) return '';
    List<String> parts = name.split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    } else {
      return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'النسخ الاحتياطي والاستعادة',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.cyan,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.menu), // أيقونة الـ Drawer في الجهة اليسرى
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward,
                color: Colors.white), // أيقونة العودة في الجهة اليمنى
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xB92195F3),
                Color(0x7AF44336),
                Color(0xB3FFEB3B),
                Color(0xB92195F3),
                Color(0x7AF44336),
              ],
            ),
          ),
          child: Column(
            children: [
              Container(
                color: const Color(0x5F00BBD4),
                padding: const EdgeInsets.fromLTRB(2, 36, 10, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '  معلومات  Google',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_outlined,
                        color: Colors.redAccent,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                    colors: [
                      Colors.blueAccent,
                      Colors.redAccent,
                      Colors.yellowAccent,
                      Colors.blueAccent,
                      Colors.redAccent,
                    ],
                  ),
                ),
              ),
              if (_currentUserData != null) ...[
                Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                      color: const Color.fromARGB(183, 255, 255, 255),
                      borderRadius: BorderRadius.circular(22)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'تم تسجيل دخول     ',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Image.asset(
                        'images/googlelogo.png', // استبدل بالمسار الصحيح للصورة
                        width: 120,
                        height: 40,
                      ),
                      const Text(
                        '  بواسطة                        ',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: double.infinity,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.topRight,
                            colors: [
                              Colors.blueAccent,
                              Colors.redAccent,
                              Colors.yellowAccent,
                              Colors.blueAccent,
                              Colors.redAccent,
                            ],
                          ),
                        ),
                      ),
                      Card(
                        color: Colors.white,
                        elevation: 8,
                        margin: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(children: [
                          const SizedBox(height: 10),
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue, // اللون الأول
                                  Colors.red, // اللون الثالث
                                  Colors.yellow, // اللون الثاني
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                            padding: const EdgeInsets.all(4), // سماكة الحدود
                            child: CircleAvatar(
                              radius: 34,
                              backgroundColor:
                                  _currentUserData!["photoUrl"] == null ||
                                          !_currentUserData!["photoUrl"]!
                                              .startsWith("http")
                                      ? getColorFromEmail(
                                          _currentUserData!["email"] ?? '')
                                      : null,
                              backgroundImage: _currentUserData!["photoUrl"] !=
                                          null &&
                                      _currentUserData!["photoUrl"]!
                                          .startsWith("http")
                                  ? NetworkImage(_currentUserData!["photoUrl"]!)
                                  : null,
                              child: _currentUserData!["photoUrl"] == null ||
                                      !_currentUserData!["photoUrl"]!
                                          .startsWith("http")
                                  ? Text(
                                      getInitials(
                                          _currentUserData!["displayName"] ??
                                              ''),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _currentUserData!["displayName"] ??
                                'مستخدم غير معروف',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              _currentUserData!["email"] ?? 'بريد غير متاح',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.topRight,
                      colors: [
                        Colors.blueAccent,
                        Colors.redAccent,
                        Colors.yellowAccent,
                        Colors.blueAccent,
                        Colors.redAccent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: _handleSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 10),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                      color: const Color.fromARGB(183, 255, 255, 255),
                      borderRadius: BorderRadius.circular(22)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'لم يتم تسجيل الدخول',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Image.asset(
                        'images/googlelogo.png', // استبدل بالمسار الصحيح للصورة
                        width: 120,
                        height: 40,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: double.infinity,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.topRight,
                            colors: [
                              Colors.blueAccent,
                              Colors.redAccent,
                              Colors.yellowAccent,
                              Colors.blueAccent,
                              Colors.redAccent,
                            ],
                          ),
                        ),
                      ),
                      Card(
                        color: Colors.white,
                        elevation: 8,
                        margin: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(children: [
                          const SizedBox(height: 6),
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.error_outline,
                              size: 50,
                              color: Colors.redAccent,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: const Text(
                              ' قم بتسجيل الدخول من خلال الزر اسفل   لتتمكن من حفظ بياتاتك على قوقل',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.topRight,
                      colors: [
                        Colors.blueAccent,
                        Colors.redAccent,
                        Colors.yellowAccent,
                        Colors.blueAccent,
                        Colors.redAccent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _handleSignIn,
                    icon: const Icon(Icons.login),
                    label: const Text(
                      'تسجيل دخول  Google',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromARGB(255, 102, 213, 105),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Container(
                width: double.infinity,
                height: 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                    colors: [
                      Colors.blueAccent,
                      Colors.redAccent,
                      Colors.yellowAccent,
                      Colors.blueAccent,
                      Colors.redAccent,
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'إصدار التطبيق: 1.0.0',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.cyan.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'محلي',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyan,
                              ),
                            ),
                            const Divider(color: Colors.cyan, thickness: 2),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _isLocalBackupLoading
                                  ? null
                                  : () => _createBackup(context),
                              icon: _isLocalBackupLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.backup),
                              label: Text(
                                _isLocalBackupLoading
                                    ? 'جارٍ إنشاء النسخة...'
                                    : 'إنشاء نسخة احتياطية محليًا',
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.cyan,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _isLocalRestoreLoading
                                  ? null
                                  : () => _restoreBackup(context),
                              icon: _isLocalRestoreLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.restore),
                              label: Text(
                                _isLocalRestoreLoading
                                    ? 'جارٍ الاستعادة...'
                                    : 'استعادة نسخة احتياطية محليًا',
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.cyan,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Image.asset(
                              'images/google-drive.png', // استبدل بالمسار الصحيح للصورة
                              width: 30,
                              height: 30,
                            ),
                            const Text(
                              'Google Drive',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyan,
                              ),
                            ),
                            const Divider(color: Colors.cyan, thickness: 2),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _isDriveBackupLoading
                                  ? null
                                  : () => _backupToGoogleDrive(context),
                              icon: _isDriveBackupLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.cloud_upload),
                              label: Text(
                                _isDriveBackupLoading
                                    ? 'جارٍ الرفع...'
                                    : 'رفع النسخة إلى Google Drive',
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.cyan,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _isDriveRestoreLoading
                                  ? null
                                  : () =>
                                      _restoreBackupFromGoogleDrive(context),
                              icon: _isDriveRestoreLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.cloud_download),
                              label: Text(
                                _isDriveRestoreLoading
                                    ? 'جارٍ الاستعادة...'
                                    : 'استعادة من Google Drive',
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.cyan,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
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
      ),
    );
  }
}
