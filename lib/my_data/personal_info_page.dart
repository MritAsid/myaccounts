import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({Key? key}) : super(key: key);

  @override
  PersonalInfoPageState createState() => PersonalInfoPageState();
}

class PersonalInfoPageState extends State<PersonalInfoPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // متغيرات لحفظ القيم
  String name = '';
  String serviceType = '';
  String address = '';
  String phoneNumber = '';

  // حالة التعديل
  bool isEditing = false;

  // FocusNodes للتركيز على الحقول
  final FocusNode nameFocusNode = FocusNode();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode serviceFocusNode = FocusNode();
  final FocusNode addressFocusNode = FocusNode();

  // Controllers للحقول
  final TextEditingController nameController = TextEditingController();
  final TextEditingController serviceTypeController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // دالة لتحميل البيانات المحفوظة
  Future<void> _loadSavedData() async {
    final info = await _dbHelper.getPersonalInfo();
    if (info != null) {
      setState(() {
        name = info['name'] ?? '';
        serviceType = info['serviceType'] ?? '';
        address = info['address'] ?? '';
        phoneNumber = info['phoneNumber'] ?? '';

        nameController.text = name;
        serviceTypeController.text = serviceType;
        addressController.text = address;
        phoneNumberController.text = phoneNumber;
      });
    }
  }

  // دالة لحفظ البيانات
  Future<void> _saveData() async {
    final info = {
      'name': nameController.text,
      'serviceType': serviceTypeController.text,
      'address': addressController.text,
      'phoneNumber': phoneNumberController.text,
    };

    await _dbHelper.insertOrUpdatePersonalInfo(info);

    setState(() {
      isEditing = false;
    });
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تم حفظ البيانات بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }

/* 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'البيانات الشخصية',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.cyan,
        elevation: 4,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            // onPressed: () => Navigator.pop(context),
            onPressed: () {
              Navigator.pop(context);
              DatabaseHelper().getPersonalInfo();
            }),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.cyan.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان الصفحة مع أيقونة
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.account_circle, size: 40, color: Colors.cyan),
                    SizedBox(width: 10),
                    Text(
                      'معلوماتك الشخصية',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // بطاقة تحتوي على الحقول
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // حقل الاسم
                      _buildTextField(
                        controller: nameController,
                        focusNode: nameFocusNode,
                        label: 'الاسم',
                        icon: Icons.person,
                        enabled: isEditing,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 16),

                      // حقل رقم الهاتف
                      _buildTextField(
                        controller: phoneNumberController,
                        focusNode: phoneFocusNode,
                        label: 'رقم الهاتف',
                        icon: Icons.phone,
                        enabled: isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // حقل نوع الخدمة
                      _buildTextField(
                        controller: serviceTypeController,
                        focusNode: serviceFocusNode,
                        label: 'نوع الخدمة',
                        icon: Icons.work,
                        enabled: isEditing,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 16),

                      // حقل العنوان
                      _buildTextField(
                        controller: addressController,
                        focusNode: addressFocusNode,
                        label: 'العنوان',
                        icon: Icons.location_on,
                        enabled: isEditing,
                        keyboardType: TextInputType.text,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // زر التعديل أو الحفظ
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isEditing
                      ? ElevatedButton.icon(
                          onPressed: _saveData,
                          icon: const Icon(Icons.save),
                          label: const Text('حفظ'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              isEditing = true;
                              nameFocusNode.requestFocus();
                            });
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('تعديل'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.cyan,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 */
  @override
  Widget build(BuildContext context) {
    // print(MediaQuery.of(context).textScaleFactor); // طباعة textScaleFactor
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'البيانات الشخصية',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.cyan,
        elevation: 4,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            // onPressed: () => Navigator.pop(context),
            onPressed: () {
              Navigator.pop(context);
              DatabaseHelper().getPersonalInfo();
            }),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.cyan.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان الصفحة مع أيقونة
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.account_circle, size: 40, color: Colors.cyan),
                    SizedBox(width: 10),
                    Text(
                      'معلوماتك الشخصية',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // بطاقة تحتوي على الحقول
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // حقل الاسم
                      _buildTextField(
                        controller: nameController,
                        focusNode: nameFocusNode,
                        label: 'الاسم',
                        icon: Icons.person,
                        enabled: isEditing,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 16),

                      // حقل رقم الهاتف
                      _buildTextField(
                        controller: phoneNumberController,
                        focusNode: phoneFocusNode,
                        label: 'رقم الهاتف',
                        icon: Icons.phone,
                        enabled: isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // حقل نوع الخدمة
                      _buildTextField(
                        controller: serviceTypeController,
                        focusNode: serviceFocusNode,
                        label: 'نوع الخدمة',
                        icon: Icons.work,
                        enabled: isEditing,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 16),

                      // حقل العنوان
                      _buildTextField(
                        controller: addressController,
                        focusNode: addressFocusNode,
                        label: 'العنوان',
                        icon: Icons.location_on,
                        enabled: isEditing,
                        keyboardType: TextInputType.text,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // زر التعديل أو الحفظ
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isEditing
                      ? ElevatedButton.icon(
                          onPressed: _saveData,
                          icon: const Icon(Icons.save),
                          label: const Text('حفظ'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              isEditing = true;
                              nameFocusNode.requestFocus();
                            });
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('تعديل'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.cyan,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لإنشاء حقول النصوص بشكل موحد
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl, // لدعم اللغة العربية
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.cyan),
        prefixIcon: Icon(icon, color: Colors.cyan),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyan),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyan),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyan, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      style: const TextStyle(fontSize: 16),
    );
  }
}












/* import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({Key? key}) : super(key: key);

  @override
  _PersonalInfoPageState createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // متغيرات لحفظ القيم
  String name = '';
  String serviceType = '';
  String address = '';
  String phoneNumber = '';

  // حالة التعديل
  bool isEditing = false;

  // FocusNode للتركيز على حقل الاسم
  final FocusNode nameFocusNode = FocusNode();

  // Controllers للحقول
  final TextEditingController nameController = TextEditingController();
  final TextEditingController serviceTypeController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedData(); // تحميل البيانات المحفوظة عند فتح الصفحة
  }

  // دالة لتحميل البيانات المحفوظة
  Future<void> _loadSavedData() async {
    final info = await _dbHelper.getPersonalInfo();
    if (info != null) {
      setState(() {
        name = info['name'] ?? '';
        serviceType = info['serviceType'] ?? '';
        address = info['address'] ?? '';
        phoneNumber = info['phoneNumber'] ?? '';

        nameController.text = name;
        serviceTypeController.text = serviceType;
        addressController.text = address;
        phoneNumberController.text = phoneNumber;
      });
    }
  }

  // دالة لحفظ البيانات
  Future<void> _saveData() async {
    final info = {
      'name': nameController.text,
      'serviceType': serviceTypeController.text,
      'address': addressController.text,
      'phoneNumber': phoneNumberController.text,
    };

    await _dbHelper.insertOrUpdatePersonalInfo(info);

    setState(() {
      isEditing = false; // إخفاء زر الحفظ وإظهار زر التعديل
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البيانات الشخصية'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        // لجعل الشاشة مرنة عند ظهور لوحة المفاتيح
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.account_circle, size: 30, color: Colors.white),
            // حقل الاسم
            Row(
              children: [
                const Text(
                  'الاسم:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8), // مسافة بين الـ Label والحقل
                Expanded(
                  child: TextFormField(
                    controller: nameController,
                    focusNode: nameFocusNode,
                    enabled: isEditing,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12), // تقليل الـ Padding
                      border: OutlineInputBorder(),
                      hintText: 'أدخل الاسم',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // حقل رقم الهاتف
            Row(
              children: [
                const Text(
                  'رقم الهاتف  :  ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: TextFormField(
                    controller: phoneNumberController,
                    enabled: isEditing,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      border: OutlineInputBorder(),
                      hintText: 'أدخل رقم الهاتف',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),

            // حقل نوع الخدمة
            Row(
              children: [
                const Text(
                  'نوع الخدمة:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: serviceTypeController,
                    enabled: isEditing,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      border: OutlineInputBorder(),
                      hintText: 'أدخل نوع الخدمة',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // حقل العنوان
            Row(
              children: [
                const Text(
                  'العنوان:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: addressController,
                    enabled: isEditing,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      border: OutlineInputBorder(),
                      hintText: 'أدخل العنوان',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            const SizedBox(height: 24),

            // زر التعديل أو الحفظ
            if (!isEditing)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isEditing = true; // تفعيل التعديل
                      nameFocusNode.requestFocus(); // التركيز على حقل الاسم
                    });
                  },
                  child: const Text('تعديل'),
                ),
              ),
            if (isEditing)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _saveData(); // حفظ البيانات
                  },
                  child: const Text('حفظ'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


 */











