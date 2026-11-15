import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/image_provider.dart';
import '../../domain/media_entry.dart';

class MediaCover extends StatelessWidget {
  const MediaCover({
    super.key,
    required this.type,
    this.imagePath,
    this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 14,
  });

  final MediaType type;
  final String? imagePath;
  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (type) {
      MediaType.book => Icons.menu_book_rounded,
      MediaType.movie => Icons.local_movies_rounded,
      MediaType.series => Icons.live_tv_rounded,
    };
    final accent = switch (type) {
      MediaType.book => ShelfColors.book,
      MediaType.movie => ShelfColors.movie,
      MediaType.series => ShelfColors.series,
    };
    Widget fallback() => Container(
      width: width,
      height: height,
      color: accent.withValues(
        alpha: theme.brightness == Brightness.dark ? .12 : .2,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 30, color: accent),
    );

    Widget image;
    final localProvider = imagePath == null
        ? null
        : localImageProvider(imagePath!);
    if (localProvider != null) {
      image = Image(
        image: localProvider,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback(),
      );
    } else if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => fallback(),
        errorWidget: (context, url, error) => fallback(),
      );
    } else {
      image = fallback();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: width, height: height, child: image),
    );
  }
}
