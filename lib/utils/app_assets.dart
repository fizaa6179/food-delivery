import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Central place that computes asset paths from names, so restaurants and
/// food items don't need image columns in the database. Just drop matching
/// image files into the folders below (see assets/images/README.txt) and
/// they'll show up automatically. Until then, AppImage shows a tasteful
/// fallback icon so the app never looks broken.
class AppAssets {
  AppAssets._();

  static String slug(String input) {
    return input
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  /// e.g. assets/images/restaurants/urban_bites.png
  static String restaurantImage(String restaurantName) =>
      'assets/images/restaurants/${slug(restaurantName)}.png';

  /// e.g. assets/images/food/urban_bites/zinger_burger.png
  static String foodImage(String restaurantName, String foodName) =>
      'assets/images/food/${slug(restaurantName)}/${slug(foodName)}.png';

  /// e.g. assets/images/banners/banner_1.png
  static String banner(int index) => 'assets/images/banners/banner_$index.png';

  static const String logo = 'assets/images/logo.png';
}

/// Drop-in replacement for Image.asset that falls back to a soft icon tile
/// when the asset hasn't been added yet, instead of crashing/red-screening.
class AppImage extends StatelessWidget {
  final String path;
  final IconData fallbackIcon;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const AppImage({
    super.key,
    required this.path,
    this.fallbackIcon = Icons.restaurant_rounded,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: backgroundColor ?? AppColors.primary.withOpacity(0.1),
        alignment: Alignment.center,
        child: Icon(
          fallbackIcon,
          color: AppColors.primary,
          size: (width != null && width! < 60) ? 20 : 32,
        ),
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
