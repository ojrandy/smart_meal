import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// Standard network image treatment for the app: a shimmering skeleton
/// while loading, and a graceful icon fallback if the URL is missing or
/// fails to load. Use this instead of a bare [CachedNetworkImage] anywhere
/// a recipe photo, avatar, or other remote image is rendered.
class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return _fallback();
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, _) => _shimmer(),
      errorWidget: (context, _, __) => _fallback(),
    );
  }

  Widget _shimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.surface,
      child: Container(
        width: width,
        height: height,
        color: AppColors.surfaceVariant,
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child: const Icon(Iconsax.image, color: Colors.grey, size: 32),
    );
  }
}
