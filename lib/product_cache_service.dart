// product_cache_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'store_model.dart'; // نحتاج إلى كلاس Product

class ProductCacheService {
  // المفتاح: 'products_cache_<storeId>'

  Future<void> saveProducts(String storeId, List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    // تحويل قائمة المنتجات إلى قائمة من الخرائط (JSON)
    final jsonList = products.map((p) => p.toMap()).toList();
    // تخزين القائمة كسلسلة نصية
    await prefs.setString('products_cache_$storeId', jsonEncode(jsonList));
  }

  Future<List<Product>?> getProducts(String storeId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('products_cache_$storeId');

    if (jsonString == null) {
      return null;
    }

    try {
      // تحويل السلسلة النصية إلى قائمة من الخرائط
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      // تحويل الخرائط إلى كائنات Product
      return jsonList
          .map((map) => Product.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // في حالة وجود خطأ في تحليل JSON أو تحويل البيانات، يتم تجاهل الكاش
      return null;
    }
  }

  Future<void> clearCache(String storeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('products_cache_$storeId');
  }
}
