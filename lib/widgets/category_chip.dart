import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const List<String> kAllCategories = [
  'Fast Food',
  'Pizza',
  'Pakistani',
  'Chinese',
  'Cafe',
  'Shawarma & Wraps',
  'Desserts',
  'Desi Food',
];

IconData categoryIconFor(String category) {
  switch (category) {
    case 'Fast Food':
      return Icons.lunch_dining_rounded;
    case 'Pizza':
      return Icons.local_pizza_rounded;
    case 'Pakistani':
      return Icons.dinner_dining_rounded;
    case 'Chinese':
      return Icons.ramen_dining_rounded;
    case 'Cafe':
      return Icons.coffee_rounded;
    case 'Shawarma & Wraps':
      return Icons.kebab_dining_rounded;
    case 'Desserts':
      return Icons.icecream_rounded;
    case 'Desi Food':
      return Icons.rice_bowl_rounded;
    default:
      return Icons.restaurant_rounded;
  }
}

class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade200),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon ?? categoryIconFor(label), color: selected ? Colors.white : AppColors.primary, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.15,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
