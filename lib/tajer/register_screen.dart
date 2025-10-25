import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tajer/merchant_provider.dart';
import 'merchant_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  final Databases databases;
  final Storage storage;

  const RegisterScreen({
    super.key,
    required this.databases,
    required this.storage,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController =
      TextEditingController(); // 🔹 لليوزر نيم (تسجيل الدخول)
  final _nameController = TextEditingController(); // 🔹 اسم المتجر
  final _passController = TextEditingController();
  final _phoneController = TextEditingController();

  String? selectedCategory;
  String? selectedZoneId;
  String? selectedNeighborhood;
  double? latitude;
  double? longitude;

  bool _isLoading = false;

  final List<String> categories = [
    'سوبرماركت',
    'البان واجبان',
    'أفران',
    'حلويات وكرزات',
    'مواد غذائية',
    'مطاعم',
    'عطارية',
    'مرطبات',
  ];

  List<Map<String, dynamic>> zones = [];
  List<String> neighborhoods = [];

  @override
  void initState() {
    super.initState();
    _fetchZones();
  }

  Future<void> _fetchZones() async {
    try {
      final res = await widget.databases.listDocuments(
        databaseId: 'mahllnadb',
        collectionId: 'zoneid',
      );

      setState(() {
        zones = res.documents.map((doc) {
          final data = doc.data;
          data['\$id'] = doc.$id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint("Error fetching zones: $e");
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تفعيل الموقع في الإعدادات')),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم رفض إذن الموقع')));
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('إذن الموقع مرفوض دائمًا')),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في الحصول على الموقع: $e')));
      }
    }
  }

  Future<void> _registerAndSetup() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCategory == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار تصنيف المتجر')),
        );
      }
      return;
    }

    if (selectedZoneId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('الرجاء اختيار القاطع')));
      }
      return;
    }

    if (selectedNeighborhood == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('الرجاء اختيار الحي')));
      }
      return;
    }

    if (latitude == null || longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تحديد الموقع الجغرافي')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final zone = zones.firstWhere((z) => z['\$id'] == selectedZoneId);

      final newStore = await widget.databases.createDocument(
        databaseId: 'mahllnadb',
        collectionId: 'Stores',
        documentId: ID.unique(),
        data: {
          'username':
              _usernameController.text, // 🔹 يوزر نيم مخصص لتسجيل الدخول
          'name': _nameController.text, // 🔹 اسم المتجر
          'stpass': _passController.text,
          'phone': _phoneController.text,
          'isOpen': true,
          'is_active': false, // 🛑 تم التعديل هنا لجعله FALSE كما طلبت
          'latitude': latitude!,
          'longitude': longitude!,
          'category': selectedCategory!,
          'zoneId': zone['name'],
          'neighborhood': selectedNeighborhood!,
          'image': '',
        },
      );

      final storeId = newStore.$id;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('storeId', storeId);
      await prefs.setString('zoneId', zone['name']);
      await prefs.setString('neighborhood', selectedNeighborhood!);

      if (mounted) {
        // بما أن 'is_active' الآن هي false، سيتم توجيه المستخدم إلى PaymentDueScreen
        // عند محاولة تسجيل الدخول من شاشة LoginScreen
        // ولكن للتأكد من خروج المستخدم بشكل واضح، يمكن توجيهه إلى شاشة لوحة القيادة
        // (إذا كانت لوحة القيادة مصممة للتعامل مع الحالة غير النشطة)، أو ببساطة العودة لشاشة تسجيل الدخول

        // **الخيار الأفضل:** العودة لشاشة تسجيل الدخول مع رسالة توضيحية للمراجعة.
        Navigator.pop(context); // العودة لشاشة تسجيل الدخول
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إنشاء الحساب بنجاح! سيتم مراجعته وتفعيله قريباً.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Registration Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ في إنشاء الحساب: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب وإعداد المتجر')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🔹 إدخال اليوزر نيم
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم (لتسجيل الدخول)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'الرجاء إدخال اسم المستخدم' : null,
              ),
              const SizedBox(height: 16),

              // 🔹 إدخال اسم المتجر
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المتجر',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'الرجاء إدخال اسم المتجر' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passController,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'الرجاء إدخال كلمة المرور' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'الرجاء إدخال رقم الهاتف' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) => setState(() => selectedCategory = val),
                decoration: const InputDecoration(
                  labelText: 'اختر تصنيف المتجر',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedZoneId,
                items: zones.map((zone) {
                  return DropdownMenuItem<String>(
                    value: zone['\$id'],
                    child: Text(zone['name'] ?? 'بدون اسم'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedZoneId = val;
                    final zone = zones.firstWhere((z) => z['\$id'] == val);
                    neighborhoods = List<String>.from(
                      zone['neighborhoods'] ?? [],
                    );
                    selectedNeighborhood = null;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'اختر القاطع',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedNeighborhood,
                items: neighborhoods.map((n) {
                  return DropdownMenuItem<String>(value: n, child: Text(n));
                }).toList(),
                onChanged: (val) => setState(() => selectedNeighborhood = val),
                decoration: const InputDecoration(
                  labelText: 'اختر الحي',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              ListTile(
                title: const Text('الموقع الجغرافي'),
                subtitle: Text(
                  latitude != null && longitude != null
                      ? 'خط العرض: ${latitude!.toStringAsFixed(4)}, خط الطول: ${longitude!.toStringAsFixed(4)}'
                      : 'غير محدد',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _getLocation,
                ),
              ),
              const SizedBox(height: 24),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _registerAndSetup,
                      child: const Text('إنشاء الحساب وانتظار التفعيل'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
