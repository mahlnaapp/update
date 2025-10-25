// File: delivery_screen.dart

import 'dart:convert'; // لاستخدام JSON للتخزين المؤقت للمتاجر

import 'package:appfotajer/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appwrite/appwrite.dart';

import 'cart_provider.dart';
import 'store_screen.dart';
import 'store_model.dart';
import 'store_service.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'settings_screen.dart';
import 'auth_screen.dart';

// 🟢 شاشة لعرض المتاجر المفضلة فقط
class FavoritesScreen extends StatelessWidget {
  final List<Store> favoriteStores;

  const FavoritesScreen({super.key, required this.favoriteStores});

  @override
  Widget build(BuildContext context) {
    if (favoriteStores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'لا توجد متاجر مفضلة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'أضف متجرك المفضل للوصول السريع إليه.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: favoriteStores.length,
      itemBuilder: (context, index) {
        final store = favoriteStores[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.store),
            title: Text(store.name),
            subtitle: Text(store.category),
            trailing: store.isOpen
                ? const Text('مفتوح', style: TextStyle(color: Colors.green))
                : const Text('مغلق', style: TextStyle(color: Colors.red)),
            onTap: store.isOpen
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoreScreen(
                        storeName: store.name,
                        storeId: store.id,
                        isStoreOpen: store.isOpen,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

// ===================== DeliveryScreen =====================

class DeliveryScreen extends StatefulWidget {
  final String deliveryCity;
  final String? zoneId;

  const DeliveryScreen({super.key, required this.deliveryCity, this.zoneId});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  double? _userLat;
  double? _userLon;
  List<Store> _stores = [];
  int _currentIndex = 0;

  // 🟢 لتخزين IDs المتاجر المفضلة
  Set<String> _favoriteStoreIds = {};

  final List<String> _categories = [
    'الكل',
    'سوبرماركت',
    'البان واجبان',
    'أفران',
    'حلويات وكرزات',
    'مواد غذائية',
    'مطاعم',
    'عطارية',
    'مرطبات',
  ];

  // 🟢 قائمة الصفحات
  List<Widget> get _pages {
    final List<Store> favoriteStores = _stores
        // التحقق الآمن من الـ null (لمعالجة الخطأ)
        .where((store) => _favoriteStoreIds?.contains(store.id) ?? false)
        .toList();

    return [
      const CartScreen(), // index 1
      FavoritesScreen(favoriteStores: favoriteStores), // index 2
      const SettingsScreen(), // index 3
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _getUserLocation();
    _loadInitialStores(); // تحميل البيانات من الكاش ثم من الخادم
  }

  // -------------------------------------------------------------------
  // 🟢 وظائف التخزين المؤقت للمتاجر

  Future<List<Store>> _loadStoresFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('cachedStores');
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        // يجب أن يحتوي StoreModel على دالة .fromJson
        return jsonList.map((json) => Store.fromJson(json)).toList();
      } catch (e) {
        // إذا فشل فك التشفير، يتم العودة إلى قائمة فارغة
        return [];
      }
    }
    return [];
  }

  Future<void> _cacheStores(List<Store> stores) async {
    final prefs = await SharedPreferences.getInstance();
    // يجب أن يحتوي StoreModel على دالة .toJson
    final List<Map<String, dynamic>> jsonList = stores
        .map((store) => store.toJson())
        .toList();
    final String jsonString = jsonEncode(jsonList);
    await prefs.setString('cachedStores', jsonString);
  }

  Future<void> _loadInitialStores() async {
    setState(() => _isLoading = true);

    // 1. محاولة التحميل من الكاش أولاً
    final cachedStores = await _loadStoresFromCache();
    if (cachedStores.isNotEmpty) {
      setState(() {
        _stores = cachedStores;
        _isLoading = false;
      });
    }

    // 2. جلب البيانات من الخادم (تحديث صامت)
    try {
      final storeService = Provider.of<StoreService>(context, listen: false);
      // استخدام limit كبير (مثل 1000) لجلب كل المتاجر دفعة واحدة للتخزين المؤقت
      final freshStores = await storeService.getStores(
        userLat: _userLat,
        userLon: _userLon,
        zoneId: widget.zoneId,
        limit: 1000,
        offset: 0,
      );

      // 3. إذا كانت البيانات الجديدة مختلفة، يتم تحديث الكاش والواجهة
      if (_stores.length != freshStores.length ||
          _stores.any((s) => !freshStores.map((fs) => fs.id).contains(s.id))) {
        await _cacheStores(freshStores);

        setState(() {
          _stores = freshStores;
        });

        // 💡 إظهار إشعار بأن البيانات قد تم تحديثها
        if (mounted && cachedStores.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث قائمة المتاجر بنجاح.')),
          );
        }
      }
    } catch (e) {
      // إظهار الخطأ فقط إذا لم يكن هناك بيانات مخزنة مؤقتاً لعرضها
      if (cachedStores.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في تحميل المتاجر: $e. جرب مرة أخرى.')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // -------------------------------------------------------------------
  // 🟢 وظائف المتاجر المفضلة (تم الإبقاء عليها)

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites = prefs.getStringList('favoriteStores') ?? [];
    setState(() {
      _favoriteStoreIds = favorites.toSet();
    });
  }

  Future<void> _toggleFavorite(Store store) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteStoreIds.contains(store.id)) {
        _favoriteStoreIds.remove(store.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${store.name} أُزيل من المفضلة')),
        );
      } else {
        _favoriteStoreIds.add(store.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${store.name} أُضيف إلى المفضلة')),
        );
      }
      prefs.setStringList('favoriteStores', _favoriteStoreIds.toList());
    });
  }
  // -------------------------------------------------------------------

  Future<void> _getUserLocation() async {
    try {
      setState(() {
        _userLat = 36.3350;
        _userLon = 43.1150;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل في الحصول على الموقع: $e')));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Store> get _filteredStores {
    final searchText = _searchController.text.toLowerCase();

    return _stores.where((store) {
      final categoryMatch =
          _selectedCategoryIndex == 0 ||
          (store.category == _categories[_selectedCategoryIndex]);
      final searchMatch =
          searchText.isEmpty ||
          store.name.toLowerCase().contains(searchText) ||
          store.category.toLowerCase().contains(searchText);

      return categoryMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('توصيل إلى ${widget.deliveryCity}'),
        centerTitle: true,
        actions: [_buildCartIconWithBadge(context)],
      ),
      body: _currentIndex == 0
          ? _buildHomeContent()
          : _pages[_currentIndex - 1], // صفحات الـ _pages تبدأ من index 1
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ), // 0
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'السلة', // 1
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'المفضلة', // 2
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات', // 3
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildCategoriesBar(),
        Expanded(
          child: _isLoading
              ? _buildLoadingState()
              : _filteredStores.isEmpty
              ? _buildEmptyState()
              : _buildStoresList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث عن متجر أو منتج...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildCategoriesBar() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) => _buildCategoryItem(index),
      ),
    );
  }

  Widget _buildCategoryItem(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(_categories[index]),
        selected: _selectedCategoryIndex == index,
        onSelected: (selected) =>
            setState(() => _selectedCategoryIndex = index),
        selectedColor: Colors.orange,
        labelStyle: TextStyle(
          color: _selectedCategoryIndex == index ? Colors.white : Colors.black,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildStoresList() {
    // تم إزالة دعم التحميل التدريجي (Load More) لأننا نحمل جميع المتاجر ونخزنها مؤقتاً
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _filteredStores.length,
      itemBuilder: (context, index) {
        return _buildStoreItem(_filteredStores[index]);
      },
    );
  }

  Widget _buildStoreItem(Store store) {
    // 🟢 معالجة خطأ الـ null: استخدام التحقق الآمن
    final isFavorite = _favoriteStoreIds?.contains(store.id) ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: store.isOpen
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoreScreen(
                    storeName: store.name,
                    storeId: store.id,
                    isStoreOpen: store.isOpen,
                  ),
                ),
              )
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('المتجر مغلق حالياً')),
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: store.image.isEmpty
                    ? Icon(Icons.store, size: 40, color: Colors.grey[600])
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          store.image,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.store,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // 🟢 زر المفضلة
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _toggleFavorite(store),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    Text(
                      store.category,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        Expanded(
                          child: Text(
                            store.address ?? "الموقع غير متوفر",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: store.isOpen
                                ? Colors.green[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            store.isOpen ? 'مفتوح الآن' : 'مغلق',
                            style: TextStyle(
                              color: store.isOpen ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildLoadingState() =>
      const Center(child: CircularProgressIndicator(color: Colors.orange));

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_mall_directory_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد متاجر متاحة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategoryIndex == 0
                ? 'لا توجد متاجر في منطقتك'
                : 'لا توجد متاجر في هذا التصنيف',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCartIconWithBadge(BuildContext context) {
    // تم تغيير مؤشر السلة من 1 إلى 1
    return Consumer<CartProvider>(
      builder: (context, cart, _) => Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => setState(() => _currentIndex = 1),
          ),
          if (cart.itemCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Text(
                  cart.itemCount.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
