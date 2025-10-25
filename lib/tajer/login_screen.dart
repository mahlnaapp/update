import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tajer/merchant_provider.dart';
import 'merchant_dashboard.dart';
import 'payment_due_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final Databases databases;
  final Storage storage;

  const LoginScreen({
    super.key,
    required this.databases,
    required this.storage,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  bool _checkingLoginStatus = true; // حالة للتحقق من حالة التسجيل

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // التحقق من حالة تسجيل الدخول عند البدء
  }

  // دالة للتحقق من حالة تسجيل الدخول
  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedStoreId = prefs.getString('storeId');

      // إذا كان هناك متجر مسجل، توجه مباشرة إلى Dashboard
      if (storedStoreId != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) => MerchantProvider(
                widget.databases,
                widget.storage,
                storedStoreId,
              ),
              child: MerchantDashboard(
                databases: widget.databases,
                storage: widget.storage,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking login status: $e');
    } finally {
      if (mounted) {
        setState(() => _checkingLoginStatus = false);
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final res = await widget.databases.listDocuments(
          databaseId: 'mahllnadb',
          collectionId: 'Stores',
          queries: [
            Query.equal('username', _usernameController.text),
            Query.equal('stpass', _passController.text),
          ],
        );

        if (res.documents.isNotEmpty) {
          final storeData = res.documents.first.data;
          final storeStatus = storeData['is_active'] ?? false;

          if (storeStatus) {
            final storeId = res.documents.first.$id;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('storeId', storeId);

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (_) => MerchantProvider(
                      widget.databases,
                      widget.storage,
                      storeId,
                    ),
                    child: MerchantDashboard(
                      databases: widget.databases,
                      storage: widget.storage,
                    ),
                  ),
                ),
              );
            }
          } else {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PaymentDueScreen()),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('اسم المستخدم أو كلمة المرور غير صحيحة'),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Login Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ في تسجيل الدخول: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // 🗑️ تم إلغاء التحقق من رمز الدخول - يتجه مباشرة لشاشة التسجيل
  Future<void> _navigateToRegisterScreen() async {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterScreen(
            databases: widget.databases,
            storage: widget.storage,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // عرض شاشة تحميل أثناء التحقق من حالة التسجيل
    if (_checkingLoginStatus) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري التحقق من حالة التسجيل...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل دخول التاجر')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'الرجاء إدخال اسم المستخدم' : null,
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
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('تسجيل الدخول'),
                    ),
              const SizedBox(height: 16),
              TextButton(
                // 🔄 تم تغيير الدالة المستدعاة هنا
                onPressed: _navigateToRegisterScreen,
                child: const Text('إنشاء حساب جديد'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
