import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'web_image.dart';

class MediaPreviewWidget extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadiusGeometry? borderRadius;

  const MediaPreviewWidget({
    super.key,
    required this.url,
    this.width = 60,
    this.height = 60,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _buildPlaceholder(Icons.image);
    }

    final lowerUrl = url.toLowerCase();
    
    // Handle SVGA
    if (lowerUrl.contains('.svga')) {
      return _buildPlaceholder(Icons.animation, label: 'SVGA');
    }
    
    // Handle MP4/Video
    if (lowerUrl.contains('.mp4') || lowerUrl.contains('.vap') || lowerUrl.contains('.mov')) {
      return _buildPlaceholder(Icons.videocam, label: 'Video');
    }

    final isWebp = lowerUrl.contains('.webp');
    final effectiveFit = isWebp ? BoxFit.contain : fit;

    // Default to Image/GIF/WEBP via CachedNetworkImage
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: Container(
          color: Colors.black12,
          padding: EdgeInsets.zero,
          child: kIsWeb
              ? buildWebImage(url, width, height, effectiveFit)
              : CachedNetworkImage(
                  imageUrl: url,
                  width: width,
                  height: height,
                  fit: effectiveFit,
                  placeholder: (context, url) => Container(
                    width: width,
                    height: height,
                    color: Colors.grey[800],
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildPlaceholder(Icons.broken_image),
                ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon, {String? label}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[400], size: width * 0.4),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
