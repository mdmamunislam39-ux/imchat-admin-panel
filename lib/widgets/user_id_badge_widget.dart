import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'media_preview_widget.dart';

/// Admin Panel User ID Badge Widget that renders custom graphic PNG/SVGA/GIF banners
/// and overlays the numeric ID over the empty space in real-time.
class UserIdBadgeWidget extends StatelessWidget {
  final String searchId;
  final TextStyle? textStyle;
  final double? badgeWidth;
  final double? badgeHeight;
  final bool showCopyIcon;
  final Color? copyIconColor;
  final VoidCallback? onCopy;

  const UserIdBadgeWidget({
    super.key,
    required this.searchId,
    this.textStyle,
    this.badgeWidth,
    this.badgeHeight,
    this.showCopyIcon = false,
    this.copyIconColor,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    if (searchId.isEmpty) {
      return const SizedBox.shrink();
    }

    final cleanId = searchId.trim();
    final digitLength = cleanId.length;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('global_settings')
          .doc('id_badges')
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic>? data = snapshot.data?.data();

        // 1. Check digit-specific badge (e.g. digit_1, digit_2, digit_3...)
        Map<String, dynamic>? badgeData = data?['digit_$digitLength'];

        // 2. Fallback to default badge (digit_0) if not found or inactive
        if (badgeData == null ||
            badgeData['isActive'] != true ||
            (badgeData['badgeUrl'] ?? '').toString().isEmpty) {
          badgeData = data?['digit_0'];
        }

        final bool hasActiveBadge = badgeData != null &&
            badgeData['isActive'] == true &&
            (badgeData['badgeUrl'] ?? '').toString().isNotEmpty;

        final String badgeUrl = (badgeData?['badgeUrl'] ?? '').toString();

        final double baseHeight = (badgeData?['height'] is num ? (badgeData!['height'] as num).toDouble() : 30.0);

        final double baseWidth = (badgeData?['width'] is num ? (badgeData!['width'] as num).toDouble() : 116.0);

        final double effectiveBadgeHeight = badgeHeight ?? baseHeight;

        final double effectiveBadgeWidth = badgeWidth ??
            (badgeHeight != null
                ? (badgeHeight! * (baseWidth / baseHeight))
                : baseWidth);

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasActiveBadge)
              // Complete Graphic PNG/SVGA Banner with ID Number in empty space
              SizedBox(
                width: effectiveBadgeWidth,
                height: effectiveBadgeHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Full Graphic Banner (Shield + Capsule Bar)
                    Positioned.fill(
                      child: MediaPreviewWidget(
                        url: badgeUrl,
                        width: effectiveBadgeWidth,
                        height: effectiveBadgeHeight,
                        fit: BoxFit.fill,
                      ),
                    ),
                    // 2. ID Number in empty portion
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: effectiveBadgeHeight * 1.25,
                          right: effectiveBadgeHeight * 0.25,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              cleanId,
                              style: (textStyle ?? const TextStyle()).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: textStyle?.fontSize ?? (effectiveBadgeHeight * 0.46),
                                letterSpacing: 0.3,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Fallback Default Sleek Pill when no badge is configured
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ID: ',
                      style: (textStyle ?? const TextStyle()).copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: (textStyle?.fontSize ?? 12) * 0.9,
                      ),
                    ),
                    Text(
                      cleanId,
                      style: (textStyle ?? const TextStyle()).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: textStyle?.fontSize ?? 12,
                      ),
                    ),
                  ],
                ),
              ),

            // Copy Icon next to banner
            if (showCopyIcon) ...[
              const SizedBox(width: 5),
              InkWell(
                onTap: onCopy,
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: copyIconColor ?? Colors.white70,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
