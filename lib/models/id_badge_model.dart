import 'package:cloud_firestore/cloud_firestore.dart';

class IdBadgeModel {
  final String id;
  final int digitLength; // 1, 2, 3, 4, 5, 6, 7, 8, 0 (0 = default)
  final String name;
  final String badgeUrl;
  final String fileType; // 'png', 'webp', 'gif', 'svga', 'auto'
  final bool isActive;
  final double width;
  final double height;
  final DateTime updatedAt;
  final String? updatedBy;

  IdBadgeModel({
    required this.id,
    required this.digitLength,
    required this.name,
    required this.badgeUrl,
    this.fileType = 'auto',
    this.isActive = true,
    this.width = 116.0,
    this.height = 30.0,
    required this.updatedAt,
    this.updatedBy,
  });

  factory IdBadgeModel.fromMap(String id, Map<String, dynamic> data) {
    return IdBadgeModel(
      id: id,
      digitLength: data['digitLength'] is int
          ? data['digitLength']
          : int.tryParse(data['digitLength']?.toString() ?? '0') ?? 0,
      name: data['name'] ?? '',
      badgeUrl: data['badgeUrl'] ?? data['imageUrl'] ?? data['url'] ?? '',
      fileType: data['fileType'] ?? _detectFileType(data['badgeUrl'] ?? ''),
      isActive: data['isActive'] ?? true,
      width: (data['width'] is num) ? (data['width'] as num).toDouble() : 116.0,
      height: (data['height'] is num) ? (data['height'] as num).toDouble() : 30.0,
      updatedAt: data['updatedAt'] != null && data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedBy: data['updatedBy']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'digitLength': digitLength,
      'name': name,
      'badgeUrl': badgeUrl,
      'fileType': fileType,
      'isActive': isActive,
      'width': width,
      'height': height,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }

  static String _detectFileType(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.svga')) return 'svga';
    if (lower.contains('.gif')) return 'gif';
    if (lower.contains('.webp')) return 'webp';
    if (lower.contains('.png')) return 'png';
    return 'png';
  }

  String get digitLabel {
    if (digitLength == 0) return 'Default ID Badge';
    return '$digitLength-Digit ID Badge';
  }
}
