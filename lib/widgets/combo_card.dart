import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_assets.dart';

/// "Popular Picks" card used in the Home screen horizontal list.
/// Fixed-height card split 80/20 (flex 8 / flex 2) between the image and
/// the name/price/add footer, per design spec.
class ComboCard extends StatelessWidget {
  final String name;
  final String restaurantName;
  final double price;
  final String badge;
  final Color badgeColor;
  final VoidCallback onAdd;
  final VoidCallback? onTap;

  static const double cardHeight = 236;

  const ComboCard({
    super.key,
    required this.name,
    required this.restaurantName,
    required this.price,
    required this.onAdd,
    this.badge = 'POPULAR',
    this.badgeColor = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        height: cardHeight,
        margin: const EdgeInsets.only(right: 14),
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
            // Image block - 80% of the card's height.
            Expanded(
              flex: 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(
                    path: AppAssets.foodImage(restaurantName, name),
                    fallbackIcon: Icons.fastfood_rounded,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                      child: Text(badge,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                    ),
                  ),
                ],
              ),
            ),
            // Info footer - 20% of the card's height.
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, height: 1.1)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text('Rs. ${price.toStringAsFixed(0)}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12, height: 1.1)),
                        ),
                        GestureDetector(
                          onTap: onAdd,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(7)),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
