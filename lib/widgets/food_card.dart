import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_assets.dart';

/// Menu-item card used inside a 2-column GridView on the restaurant menu
/// screen: image fills the top (flexes to whatever height the grid cell
/// gives it), name/price/favorite/add sit in a fixed-height footer below -
/// so it never overflows regardless of the cell's exact aspect ratio.
class FoodCard extends StatelessWidget {
  final String name;
  final double price;
  final String restaurantName;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback onAdd;

  const FoodCard({
    super.key,
    required this.name,
    required this.price,
    required this.restaurantName,
    required this.onAdd,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image fills all remaining space in the cell.
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(
                  path: AppAssets.foodImage(restaurantName, name),
                  fallbackIcon: Icons.fastfood_rounded,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 15,
                        color: isFavorite ? AppColors.primary : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Fixed-height footer.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rs. ${price.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13.5)),
                    GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(9)),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
