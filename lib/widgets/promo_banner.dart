import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_assets.dart';

/// Big hero promo banner used in the Home carousel — mirrors the
/// "Hot & Crispy" style banner from the design reference: tag chip,
/// bold headline, subtext, and a CTA button, with a background image.
class PromoBanner extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;
  final String ctaText;
  final VoidCallback onTap;
  final int imageIndex;
  final List<Color> gradientColors;

  const PromoBanner({
    super.key,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.ctaText = 'Order Now',
    this.imageIndex = 1,
    this.gradientColors = const [AppColors.accent, Color(0xFF3D0D06)],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(color: gradientColors.last.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Opacity(
                opacity: 0.55,
                child: AppImage(
                  path: AppAssets.banner(imageIndex),
                  fallbackIcon: Icons.fastfood_rounded,
                  fit: BoxFit.cover,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, height: 1.12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(ctaText,
                              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 12.5)),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.accent),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
