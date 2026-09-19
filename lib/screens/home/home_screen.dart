import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/cart_item_model.dart';
import '../../models/restaurant_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/combo_card.dart';
import '../../widgets/promo_banner.dart';
import '../../widgets/restaurant_card.dart';
import '../cart/cart_screen.dart';
import '../favorites/favorites_screen.dart';
import '../orders/order_history_screen.dart';
import '../profile/profile_screen.dart';
import '../restaurant/food_menu_screen.dart';
import '../restaurant/restaurant_list_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeBody(user: widget.user),
      OrderHistoryScreen(user: widget.user, embedded: true),
      FavoritesScreen(user: widget.user, embedded: true),
      ProfileScreen(user: widget.user, embedded: true),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_navIndex]),
      bottomNavigationBar: BottomNav(currentIndex: _navIndex, onTap: (i) => setState(() => _navIndex = i)),
    );
  }
}

class _HomeBody extends StatefulWidget {
  final UserModel user;
  const _HomeBody({required this.user});

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  List<RestaurantModel> _restaurants = [];
  List<Map<String, dynamic>> _popularItems = [];
  int _cartCount = 0;
  bool _loading = true;

  final _bannerController = PageController();
  int _bannerIndex = 0;

  static const _banners = [
    {
      'tag': 'HOT & CRISPY',
      'title': 'Crave the\ncrispy perfection!',
      'subtitle': 'Fresh, hand-cooked meals every time.',
      'colors': [AppColors.accent, Color(0xFF3D0D06)],
    },
    {
      'tag': 'SPICY DEALS',
      'title': 'Up to 30% OFF\non combos',
      'subtitle': 'Selected combos across all restaurants.',
      'colors': [AppColors.primary, AppColors.primaryDark],
    },
    {
      'tag': 'FRESH & FAST',
      'title': 'Delivered hot\nin 30 minutes',
      'subtitle': 'Order now and track it live.',
      'colors': [Color(0xFF8A3B10), Color(0xFF3D0D06)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final restaurants = await DatabaseHelper.instance.getRestaurants();
    final popular = await DatabaseHelper.instance.getPopularItems();
    final cart = await DatabaseHelper.instance.getCartItems(widget.user.id!);
    setState(() {
      _restaurants = restaurants;
      _popularItems = popular;
      _cartCount = cart.fold(0, (sum, c) => sum + c.quantity);
      _loading = false;
    });
  }

  Future<void> _quickAdd(Map<String, dynamic> item) async {
    await DatabaseHelper.instance.addToCart(
      CartItemModel(
        userId: widget.user.id!,
        foodItemId: item['id'] as int,
        foodName: item['name'] as String,
        price: (item['price'] as num).toDouble(),
        quantity: 1,
        restaurantId: item['restaurantId'] as int,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} added to cart'), duration: const Duration(seconds: 1)),
    );
    _load();
  }

  void _openCart() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CartScreen(user: widget.user)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.user.name.split(' ').first;
    const badgeTags = ['BESTSELLER', 'POPULAR', 'SAVE 15%'];
    const badgeColors = [AppColors.accent, AppColors.primary, AppColors.success];

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- HEADER ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 26),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hi, $firstName! 👋',
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            const Text('Crispy. Juicy.\nAlways delicious.',
                                style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, height: 1.2)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _iconBadge(icon: Icons.notifications_none_rounded, showDot: true, onTap: () {}),
                          const SizedBox(width: 10),
                          _iconBadge(icon: Icons.shopping_bag_outlined, count: _cartCount, onTap: _openCart),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SearchScreen(user: widget.user)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Search for your favorite food...',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5)),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- CATEGORIES ----------------
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 0, 0),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 24),
                    child: Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 24, right: 12),
                children: [
                  CategoryChip(
                    label: 'All Items',
                    icon: Icons.grid_view_rounded,
                    selected: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => RestaurantListScreen(user: widget.user, category: null)),
                    ),
                  ),
                  ...kAllCategories.map(
                    (cat) => CategoryChip(
                      label: cat,
                      selected: false,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => RestaurantListScreen(user: widget.user, category: cat)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- BANNER CAROUSEL ----------------
            const SizedBox(height: 22),
            SizedBox(
              height: 196,
              child: PageView.builder(
                controller: _bannerController,
                itemCount: _banners.length,
                onPageChanged: (i) => setState(() => _bannerIndex = i),
                itemBuilder: (context, i) {
                  final b = _banners[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: PromoBanner(
                      tag: b['tag'] as String,
                      title: b['title'] as String,
                      subtitle: b['subtitle'] as String,
                      gradientColors: b['colors'] as List<Color>,
                      imageIndex: i + 1,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => RestaurantListScreen(user: widget.user, category: null)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_banners.length, (i) {
                  final active = _bannerIndex == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // ---------------- POPULAR PICKS ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Popular Picks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => RestaurantListScreen(user: widget.user, category: null)),
                    ),
                    child: const Text('View all',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12.5)),
                  ),
                ],
              ),
            ),
            _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SizedBox(
                    height: ComboCard.cardHeight,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _popularItems.length,
                      itemBuilder: (context, index) {
                        final item = _popularItems[index];
                        return ComboCard(
                          name: item['name'] as String,
                          restaurantName: item['restaurantName'] as String,
                          price: (item['price'] as num).toDouble(),
                          badge: badgeTags[index % badgeTags.length],
                          badgeColor: badgeColors[index % badgeColors.length],
                          onAdd: () => _quickAdd(item),
                        );
                      },
                    ),
                  ),

            // ---------------- SPICY DEAL STRIP ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RestaurantListScreen(user: widget.user, category: null)),
                ),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('🔥 ', style: TextStyle(fontSize: 14)),
                                Text('Spicy Deals', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 12.5)),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text('Up to 30% OFF on selected combos',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                        child: const Text('Order Now',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ---------------- TOP RESTAURANTS ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Top restaurants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => RestaurantListScreen(user: widget.user, category: null)),
                    ),
                    child: const Text('View all',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12.5)),
                  ),
                ],
              ),
            ),
            _loading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: _restaurants
                          .map((r) => RestaurantCard(
                                restaurant: r,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => FoodMenuScreen(user: widget.user, restaurant: r),
                                    ),
                                  );
                                  _load();
                                },
                              ))
                          .toList(),
                    ),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _iconBadge({required IconData icon, VoidCallback? onTap, int count = 0, bool showDot = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                child: Text('$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textDark, fontSize: 9.5, fontWeight: FontWeight.w800)),
              ),
            )
          else if (showDot)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
