import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/cart_item_model.dart';
import '../../models/favorite_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_assets.dart';

class FavoritesScreen extends StatefulWidget {
  final UserModel user;
  final bool embedded;

  const FavoritesScreen({super.key, required this.user, this.embedded = false});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<FavoriteModel> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final favs = await DatabaseHelper.instance.getFavorites(widget.user.id!);
    setState(() {
      _favorites = favs;
      _loading = false;
    });
  }

  Future<void> _removeFavorite(FavoriteModel favorite) async {
    await DatabaseHelper.instance.removeFavorite(widget.user.id!, favorite.foodItemId);
    _load();
  }

  Future<void> _quickAddToCart(FavoriteModel favorite) async {
    // FavoriteModel doesn't store restaurantId, so look the real one up
    // from the food item instead of guessing - avoids orphaning the cart
    // row against a restaurant that doesn't exist.
    final foodItem = await DatabaseHelper.instance.getFoodItemById(favorite.foodItemId);
    if (foodItem == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This item is no longer available.')),
      );
      return;
    }
    await DatabaseHelper.instance.addToCart(
      CartItemModel(
        userId: widget.user.id!,
        foodItemId: favorite.foodItemId,
        foodName: favorite.foodName,
        price: favorite.price,
        quantity: 1,
        restaurantId: foodItem.restaurantId,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${favorite.foodName} added to cart'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const Center(child: CircularProgressIndicator())
        : _favorites.isEmpty
            ? _emptyState()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 90),
                itemCount: _favorites.length,
                itemBuilder: (context, index) => _favoriteTile(_favorites[index]),
              );

    if (widget.embedded) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Favorite foods',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 22)),
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Foods')),
      body: content,
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No favorite foods yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 6),
          Text('Tap the heart icon on any food item', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _favoriteTile(FavoriteModel favorite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          AppImage(
            path: AppAssets.foodImage(favorite.restaurantName, favorite.foodName),
            fallbackIcon: Icons.fastfood_rounded,
            width: 54,
            height: 54,
            borderRadius: BorderRadius.circular(14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(favorite.foodName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(favorite.restaurantName, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 3),
                Text('Rs. ${favorite.price.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
            onPressed: () => _removeFavorite(favorite),
          ),
          Container(
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              onPressed: () => _quickAddToCart(favorite),
            ),
          ),
        ],
      ),
    );
  }
}