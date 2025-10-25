import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cart_provider.dart';
import 'orders_provider.dart';
// import 'onboarding_screen.dart'; // <--- REMOVED
import 'location_screen.dart';
import 'delivery_screen.dart';
import 'store_screen.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'orders_screen.dart';
import 'appwrite_service.dart';
import 'store_service.dart';
import 'order_service.dart';
import 'settings_screen.dart' hide MandopLoginScreen;
// import 'auth_screen.dart'; // <--- REMOVED

// التاجر
import 'tajer/login_screen.dart';
import 'tajer/merchant_dashboard.dart';
import 'tajer/merchant_provider.dart';

// المندوب
import 'mandop/login_screen.dart';
import 'mandop/delivery_provider.dart';
import 'mandop/main_delivery_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppwriteService.init();

  final prefs = await SharedPreferences.getInstance();
  // final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false; // <--- REMOVED
  final String? userId = prefs.getString(
    'userId',
  ); // Still check for user ID for other logic
  final String? selectedZoneId = prefs.getString('selectedZoneId');
  final String? selectedZoneName = prefs.getString('selectedZoneName');
  final storedStoreId = prefs.getString('storeId');

  String initialRoute;
  String? initialDeliveryCity;
  String? initialZoneId;

  // *** START: Modified initial route logic ***

  // 1. **إذا كان الموقع محدداً مسبقاً** (Zone ID and Name are stored), اذهب مباشرة إلى شاشة التوصيل.
  if (selectedZoneId != null && selectedZoneName != null) {
    initialRoute = '/delivery';
    initialDeliveryCity = selectedZoneName;
    initialZoneId = selectedZoneId;
  }
  // 2. **إذا لم يكن الموقع محدداً**، اذهب إلى شاشة الموقع ليتم اختياره وحفظه.
  else {
    initialRoute = '/location';
  }

  // NOTE: I've kept the `userId` check in `main` but it's not used
  // for initial navigation since we're now prioritizing the location state.

  // *** END: Modified initial route logic ***

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(
          create: (_) => DeliveryProvider(
            AppwriteService.databases,
            AppwriteService.client,
          ),
        ),
        Provider(create: (_) => StoreService(AppwriteService.databases)),
        Provider(create: (_) => OrderService(AppwriteService.databases)),
        if (storedStoreId != null)
          ChangeNotifierProvider(
            create: (_) => MerchantProvider(
              AppwriteService.databases,
              AppwriteService.storage,
              storedStoreId,
            ),
          ),
      ],
      child: MyApp(
        initialRoute: initialRoute,
        initialStoreId: storedStoreId,
        initialDeliveryCity: initialDeliveryCity,
        initialZoneId: initialZoneId,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final String? initialStoreId;
  final String? initialDeliveryCity;
  final String? initialZoneId;

  const MyApp({
    super.key,
    required this.initialRoute,
    this.initialStoreId,
    this.initialDeliveryCity,
    this.initialZoneId,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق محلنا',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        // زبون
        // '/': (context) => const OnboardingScreen(), // <--- REMOVED
        // '/auth': (context) => const AuthScreen(), // <--- REMOVED

        // The Location Screen is now the effective entry point if no zone is saved.
        // It should handle navigation to /delivery after a zone is selected and saved.
        '/': (context) => const LocationScreen(), // **NEW DEFAULT ROUTE**
        '/location': (context) => const LocationScreen(),
        '/delivery': (context) => DeliveryScreen(
          // Use 'الموصل' as a default if initialDeliveryCity is still somehow null
          deliveryCity: initialDeliveryCity ?? 'الموصل',
          zoneId: initialZoneId,
        ),
        '/store': (context) =>
            const StoreScreen(storeName: "متجر", storeId: "1"),
        '/cart': (context) => const CartScreen(),
        '/checkout': (context) {
          final total = Provider.of<CartProvider>(
            context,
            listen: false,
          ).totalPrice;
          return CheckoutScreen(totalAmount: total);
        },
        '/orders': (context) => const OrdersScreen(),
        '/settings': (context) => const SettingsScreen(),

        // التاجر
        '/merchant-login': (context) => LoginScreen(
          databases: AppwriteService.databases,
          storage: AppwriteService.storage,
        ),
        '/merchant-dashboard': (context) {
          if (initialStoreId != null) {
            return MerchantDashboard(
              databases: AppwriteService.databases,
              storage: AppwriteService.storage,
              initialTabIndex: 2,
            );
          } else {
            return LoginScreen(
              databases: AppwriteService.databases,
              storage: AppwriteService.storage,
            );
          }
        },

        // المندوب
        '/delivery-login': (context) => MandopLoginScreen(
          databases: AppwriteService.databases,
          storage: AppwriteService.storage,
        ),
        '/mandop-dashboard': (context) => const MainDeliveryScreen(zoneId: '1'),
      },
    );
  }
}
