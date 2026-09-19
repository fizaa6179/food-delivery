import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_assets.dart';

class FoodTile extends StatelessWidget {
  final String name;
  final double price;
  final VoidCallback onAdd;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final String? subtitle;

  /// Restaurant name is used (together with [name]) to compute the expected
  /// image asset path, e.g. assets/images/food/urban_bites/zinger_burger.png
  final String? restaurantName;

  const FoodTile({
    super.key,
    required this.name,
    required this.price,
    required this.onAdd,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.subtitle,
    this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          AppImage(
            path: restaurantName != null
                ? AppAssets.foodImage(restaurantName!, name)
                : 'assets/images/food/unknown.png',
            width: 56,
            height: 56,
            fallbackIcon: Icons.fastfood_rounded,
            borderRadius: BorderRadius.circular(14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
                ],
                const SizedBox(height: 4),
                Text('Rs. ${price.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
          if (onFavoriteToggle != null)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite ? AppColors.primary : Colors.grey.shade400,
                size: 20,
              ),
              onPressed: onFavoriteToggle,
            ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              onPressed: onAdd,
            ),
          ),
        ],
      ),
    );
  }
}
