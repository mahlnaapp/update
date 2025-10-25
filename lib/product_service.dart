// product_service.dart

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'appwrite_service.dart';
import 'store_model.dart'; // تأكد من وجود ملف store_model.dart
import 'product_cache_service.dart'; // 💡 إضافة خدمة التخزين المؤقت

class ProductService {
  final Databases _databases;
  final ProductCacheService _cacheService; // 💡 إضافة خدمة الكاش

  ProductService(this._databases)
    : _cacheService = ProductCacheService(); // 💡 تهيئة الكاش

  // 🚀 دالة موحدة لجلب المنتجات بناءً على معرف المتجر والتصنيف الاختياري
  // 💡 إضافة خيار استخدام الكاش
  Future<List<Product>> getProducts({
    required String storeId,
    String? categoryId,
    int limit = 100, // حد معقول للتقسيم الصفحي
    int offset = 0,
    bool forceRefresh = false, // 💡 حقل جديد
  }) async {
    final cacheKey = storeId; // نستخدم storeId كمفتاح للكاش الرئيسي
    // 💡 محاولة جلب المنتجات من الكاش إذا لم تكن هناك فلترة بالتصنيف ولم نطلب تحديثاً إجبارياً
    if (!forceRefresh &&
        (categoryId == null || categoryId.isEmpty) &&
        offset == 0) {
      final cachedProducts = await _cacheService.getProducts(cacheKey);
      if (cachedProducts != null && cachedProducts.isNotEmpty) {
        debugPrint('✅ Products loaded from cache for store: $storeId');
        return cachedProducts;
      }
    }

    // -----------------------------------------------------------------
    // 💡 منطق جلب البيانات من Appwrite (تحديث بسيط)
    // -----------------------------------------------------------------

    try {
      final queries = <String>[
        Query.equal('storeId', storeId),
        // 💡 نستخدم Limit:10000 لجلب جميع المنتجات في حال كنا نقوم بالتخزين المؤقت للصفحة الأولى/الكل
        // في حالتنا: سنبقي على الـ Paging لضمان جلب البيانات بشكل صحيح لـ StoreScreen
        Query.limit(limit),
        Query.offset(offset),
      ];

      // إضافة شرط التصنيف فقط إذا تم تمريره
      if (categoryId != null && categoryId.isNotEmpty) {
        queries.add(Query.equal('categoryId', categoryId));
      }

      // 💡 إضافة الترتيب الافتراضي (مثلاً حسب الاسم) إذا لم يكن هناك ترتيب آخر
      queries.add(Query.orderAsc('name'));

      final response = await _databases.listDocuments(
        databaseId: 'mahllnadb',
        collectionId: 'Products',
        queries: queries,
      );

      final products = response.documents
          .map((doc) => Product.fromMap(doc.data))
          .toList();

      // 💡 إذا كنا في الصفحة الأولى ولم تكن هناك فلترة بالتصنيف، نقوم بتخزين النتائج مؤقتاً
      if (offset == 0 &&
          (categoryId == null || categoryId.isEmpty) &&
          products.isNotEmpty) {
        // نستخدم ProductService لجلب جميع المنتجات لغرض التخزين المؤقت
        // (إذا كانت الـ limit صغيرة، نحتاج إلى جلب كل شيء للتخزين المؤقت الكامل)
        // الحل العملي: إذا كانت عدد المنتجات مساوياً للـ limit، يجب افتراض وجود صفحات أخرى، لذا لا نخزن مؤقتاً إلا إذا جلبنا كل شيء.
        // الحل الأسهل الآن: تخزين الصفحة الأولى فقط، مع العلم أن البحث والصفحات الأخرى ستتطلب استدعاء API
        if (products.length < limit) {
          _cacheService.saveProducts(cacheKey, products);
          debugPrint('✅ Products cached for store: $storeId');
        }
      }

      return products;
    } catch (e) {
      debugPrint('Error fetching products: $e');
      throw Exception('فشل في تحميل المنتجات');
    }
  }
}
