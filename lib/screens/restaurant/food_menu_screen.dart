import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/cart_item_model.dart';
import '../../models/favorite_model.dart';
import '../../models/food_item_model.dart';
import '../../models/restaurant_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_assets.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/food_card.dart';
import '../cart/cart_screen.dart';

class FoodMenuScreen extends StatefulWidget {
  final UserModel user;
  final RestaurantModel restaurant;

  const FoodMenuScreen({super.key, required this.user, required this.restaurant});

  @override
  State<FoodMenuScreen> createState() => _FoodMenuScreenState();
}

class _FoodMenuScreenState extends State<FoodMenuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FoodItemModel> _items = [];
  Set<int> _favoriteIds = {};
  bool _loading = true;
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final items = await DatabaseHelper.instance.getFoodItemsForRestaurant(widget.restaurant.id!);
    final favorites = await DatabaseHelper.instance.getFavorites(widget.user.id!);
    final cart = await DatabaseHelper.instance.getCartItems(widget.user.id!);

    setState(() {
      _items = items;
      _favoriteIds = favorites.map((f) => f.foodItemId).toSet();
      _cartCount = cart.fold(0, (sum, c) => sum + c.quantity);
      _loading = false;
    });
  }

  Map<String, List<FoodItemModel>> get _groupedItems {
    final map = <String, List<FoodItemModel>>{};
    for (final item in _items) {
      map.putIfAbsent(item.section, () => []).add(item);
    }
    return map;
  }

  Future<void> _addToCart(FoodItemModel item) async {
    await DatabaseHelper.instance.addToCart(
      CartItemModel(
        userId: widget.user.id!,
        foodItemId: item.id!,
        foodName: item.name,
        price: item.price,
        quantity: 1,
        restaurantId: widget.restaurant.id!,
      ),
    );
    await _load();
    if (!mounted) return;
    _showAddedPopup(item);
  }

  void _showAddedPopup(FoodItemModel item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 38),
              ),
              const SizedBox(height: 16),
              const Text('Added to cart', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(item.name, style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5)),
              Text('Rs. ${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 20),
              CustomButton(text: 'OK', onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(FoodItemModel item) async {
    final isFav = _favoriteIds.contains(item.id);
    if (isFav) {
      await DatabaseHelper.instance.removeFavorite(widget.user.id!, item.id!);
    } else {
      await DatabaseHelper.instance.addFavorite(
        FavoriteModel(
          userId: widget.user.id!,
          foodItemId: item.id!,
          foodName: item.name,
          restaurantName: widget.restaurant.name,
          price: item.price,
        ),
      );
    }
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.restaurant.name),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CartScreen(user: widget.user)),
                  );
                  _load();
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$_cartCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [Tab(text: 'Menu'), Tab(text: 'Reviews'), Tab(text: 'Info')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _menuTab(),
                _reviewsTab(),
                _infoTab(),
              ],
            ),
    );
  }

  Widget _menuTab() {
    final grouped = _groupedItems;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        _menuHeaderCard(),
        const SizedBox(height: 24),
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entry.value.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  final item = entry.value[index];
                  return FoodCard(
                    name: item.name,
                    price: item.price,
                    restaurantName: widget.restaurant.name,
                    isFavorite: _favoriteIds.contains(item.id),
                    onFavoriteToggle: () => _toggleFavorite(item),
                    onAdd: () => _addToCart(item),
                  );
                },
              ),
              const SizedBox(height: 22),
            ],
          );
        }),
      ],
    );
  }

  Widget _menuHeaderCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppImage(
              path: AppAssets.restaurantImage(widget.restaurant.name),
              fallbackIcon: categoryIconFor(widget.restaurant.category),
              fit: BoxFit.cover,
              backgroundColor: AppColors.gold.withOpacity(0.25),
            ),
            // Scrim so the overlaid text stays readable over any photo.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.72),
                  ],
                  stops: const [0.3, 0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.restaurant.name,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.1)),
                  const SizedBox(height: 4),
                  Text(widget.restaurant.category,
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13.5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(9)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.white, size: 13),
                            const SizedBox(width: 3),
                            Text(widget.restaurant.rating.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded, color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text('${widget.restaurant.deliveryMinLow}-${widget.restaurant.deliveryMinHigh} min',
                                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      if (widget.restaurant.freeDelivery) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Text('Free delivery',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewsTab() {
    final reviews = [
      {'name': 'Ayesha K.', 'comment': 'Great taste and quick delivery!', 'rating': 5},
      {'name': 'Hamza R.', 'comment': 'Good food but packaging could improve.', 'rating': 4},
      {'name': 'Sara M.', 'comment': 'Loved it, ordering again soon.', 'rating': 5},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final r = reviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  Row(
                    children: List.generate(
                      r['rating'] as int,
                      (i) => const Icon(Icons.star_rounded, color: AppColors.accent, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(r['comment'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
            ],
          ),
        );
      },
    );
  }

  Widget _infoTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.category_rounded, 'Category', widget.restaurant.category),
          _infoRow(Icons.star_rounded, 'Rating', '${widget.restaurant.rating} / 5.0'),
          _infoRow(Icons.access_time_rounded, 'Delivery time',
              '${widget.restaurant.deliveryMinLow}-${widget.restaurant.deliveryMinHigh} min'),
          _infoRow(Icons.delivery_dining_rounded, 'Delivery fee',
              widget.restaurant.freeDelivery ? 'Free' : 'Rs. 100'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}