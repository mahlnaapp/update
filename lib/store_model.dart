class Store {
  final String id;
  final String name;
  final String category;
  final String image;
  final bool isOpen;
  final bool isActive; // 💡 تم إضافة حقل حالة النشاط
  final double latitude;
  final double longitude;
  final String? address;
  final String? phone;
  final String? zoneId; // <-- حقل القاطع / المنطقة
  double? distance;

  Store({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.isOpen,
    required this.isActive, // 💡 تحديث الدالة البانية
    required this.latitude,
    required this.longitude,
    this.address,
    this.phone,
    this.zoneId,
    this.distance,
  });

  // =============================================================
  // 🟢 دوال Appwrite (من Map)
  // تستخدم عند جلب البيانات من قاعدة بيانات Appwrite
  factory Store.fromMap(Map<String, dynamic> map) {
    // دالة مساعدة للتعامل مع القيم المنطقية المخزنة كـ String
    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      return true; // القيمة الافتراضية
    }

    return Store(
      id: map['\$id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      image: map['image'] ?? '',
      isOpen: parseBool(map['isOpen']),
      // 💡 قراءة is_active مباشرة كقيمة منطقية
      isActive: map['is_active'] ?? true,
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'],
      phone: map['phone'],
      zoneId: map['zoneId'], // <-- قراءة القاطع من Appwrite
    );
  }

  // دالة Appwrite (إلى Map)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'image': image,
      'isOpen': isOpen,
      'is_active': isActive, // 💡 حفظ is_active
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (zoneId != null) 'zoneId': zoneId, // <-- حفظ القاطع في Appwrite
    };
  }

  // =============================================================
  // 🟢 دوال التخزين المؤقت (من/إلى JSON)
  // تستخدم لحفظ واسترجاع البيانات من SharedPreferences (حل مشكلة fromJson/toJson)

  factory Store.fromJson(Map<String, dynamic> json) {
    // يمكننا استخدام fromMap بشرط أن يتم تمرير مفتاح 'id' بدلاً من '$id'
    // أو نقوم بالبناء يدوياً ليتناسب مع صيغة التخزين المحلي
    return Store(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      image: json['image'] as String,
      isOpen: json['isOpen'] as bool,
      isActive: json['isActive'] as bool,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      zoneId: json['zoneId'] as String?,
      distance: json['distance'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'image': image,
      'isOpen': isOpen,
      'isActive': isActive,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'phone': phone,
      'zoneId': zoneId,
      'distance': distance,
    };
  }
}

// ===================== Product Class (بدون تغيير كبير) =====================

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final bool isAvailable;
  final bool isPopular;
  final bool hasOffer;
  final String image;
  final String storeId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.isAvailable,
    required this.isPopular,
    required this.hasOffer,
    required this.image,
    required this.storeId,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['\$id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      categoryId: map['categoryId'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      isPopular: map['isPopular'] ?? false,
      hasOffer: map['hasOffer'] ?? false,
      image: map['image'] ?? '',
      storeId: map['storeId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'isAvailable': isAvailable,
      'isPopular': isPopular,
      'hasOffer': hasOffer,
      'image': image,
      'storeId': storeId,
    };
  }
}
