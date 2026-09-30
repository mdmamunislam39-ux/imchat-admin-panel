import 'package:cloud_firestore/cloud_firestore.dart';

class HostModel {
  final String id;
  final String userId;
  final String agencyId;
  final String hostName;
  final String? profileImageUrl;
  final String phone;
  final String email;
  final DateTime joinedDate;
  final DateTime? lastActiveDate;
  final bool isActive;
  final HostStatus status;
  final HostPerformance performance;
  final List<HostEarning> earnings;
  final String? notes;

  HostModel({
    required this.id,
    required this.userId,
    required this.agencyId,
    required this.hostName,
    this.profileImageUrl,
    required this.phone,
    required this.email,
    required this.joinedDate,
    this.lastActiveDate,
    this.isActive = true,
    this.status = HostStatus.pending,
    required this.performance,
    this.earnings = const [],
    this.notes,
  });

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  factory HostModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return HostModel(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      agencyId: data['agencyId']?.toString() ?? '',
      hostName: data['hostName']?.toString() ?? '',
      profileImageUrl: data['profileImageUrl']?.toString(),
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      joinedDate: _parseDate(data['joinedDate']),
      lastActiveDate: _parseNullableDate(data['lastActiveDate']),
      isActive: data['isActive'] == true || data['isActive'] == null,
      status: HostStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == data['status']?.toString().toLowerCase(),
        orElse: () => HostStatus.pending,
      ),
      performance: HostPerformance.fromMap(data['performance'] is Map ? Map<String, dynamic>.from(data['performance']) : {}),
      earnings: (data['earnings'] as List<dynamic>?)
          ?.map((e) => HostEarning.fromMap(e is Map ? Map<String, dynamic>.from(e) : {}))
          .toList() ?? [],
      notes: data['notes']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'agencyId': agencyId,
      'hostName': hostName,
      'profileImageUrl': profileImageUrl,
      'phone': phone,
      'email': email,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'lastActiveDate': lastActiveDate != null 
          ? Timestamp.fromDate(lastActiveDate!)
          : null,
      'isActive': isActive,
      'status': status.name,
      'performance': performance.toMap(),
      'earnings': earnings.map((e) => e.toMap()).toList(),
      'notes': notes,
    };
  }

  HostModel copyWith({
    String? id,
    String? userId,
    String? agencyId,
    String? hostName,
    String? profileImageUrl,
    String? phone,
    String? email,
    DateTime? joinedDate,
    DateTime? lastActiveDate,
    bool? isActive,
    HostStatus? status,
    HostPerformance? performance,
    List<HostEarning>? earnings,
    String? notes,
  }) {
    return HostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      agencyId: agencyId ?? this.agencyId,
      hostName: hostName ?? this.hostName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      joinedDate: joinedDate ?? this.joinedDate,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      performance: performance ?? this.performance,
      earnings: earnings ?? this.earnings,
      notes: notes ?? this.notes,
    );
  }
}

enum HostStatus {
  pending,
  active,
  suspended,
  terminated,
}

class HostPerformance {
  final double totalEarnings;
  final double totalDiamonds;
  final int totalLiveHours;
  final int totalGiftsReceived;
  final double averageRating;
  final DateTime lastUpdated;

  HostPerformance({
    this.totalEarnings = 0.0,
    this.totalDiamonds = 0.0,
    this.totalLiveHours = 0,
    this.totalGiftsReceived = 0,
    this.averageRating = 0.0,
    required this.lastUpdated,
  });

  factory HostPerformance.fromMap(Map<String, dynamic> data) {
    return HostPerformance(
      totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      totalDiamonds: (data['totalDiamonds'] as num?)?.toDouble() ?? 0.0,
      totalLiveHours: (data['totalLiveHours'] as num?)?.toInt() ?? 0,
      totalGiftsReceived: (data['totalGiftsReceived'] as num?)?.toInt() ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: HostModel._parseDate(data['lastUpdated']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalEarnings': totalEarnings,
      'totalDiamonds': totalDiamonds,
      'totalLiveHours': totalLiveHours,
      'totalGiftsReceived': totalGiftsReceived,
      'averageRating': averageRating,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  HostPerformance copyWith({
    double? totalEarnings,
    double? totalDiamonds,
    int? totalLiveHours,
    int? totalGiftsReceived,
    double? averageRating,
    DateTime? lastUpdated,
  }) {
    return HostPerformance(
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalDiamonds: totalDiamonds ?? this.totalDiamonds,
      totalLiveHours: totalLiveHours ?? this.totalLiveHours,
      totalGiftsReceived: totalGiftsReceived ?? this.totalGiftsReceived,
      averageRating: averageRating ?? this.averageRating,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class HostEarning {
  final String id;
  final String hostId;
  final String agencyId;
  final double diamondsEarned;
  final double commissionAmount;
  final DateTime earningDate;
  final EarningPeriod period;
  final String? description;

  HostEarning({
    required this.id,
    required this.hostId,
    required this.agencyId,
    required this.diamondsEarned,
    required this.commissionAmount,
    required this.earningDate,
    required this.period,
    this.description,
  });

  factory HostEarning.fromMap(Map<String, dynamic> data) {
    return HostEarning(
      id: data['id']?.toString() ?? '',
      hostId: data['hostId']?.toString() ?? '',
      agencyId: data['agencyId']?.toString() ?? '',
      diamondsEarned: (data['diamondsEarned'] as num?)?.toDouble() ?? 0.0,
      commissionAmount: (data['commissionAmount'] as num?)?.toDouble() ?? 0.0,
      earningDate: HostModel._parseDate(data['earningDate']),
      period: EarningPeriod.values.firstWhere(
        (e) => e.name.toLowerCase() == data['period']?.toString().toLowerCase(),
        orElse: () => EarningPeriod.weekly,
      ),
      description: data['description']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hostId': hostId,
      'agencyId': agencyId,
      'diamondsEarned': diamondsEarned,
      'commissionAmount': commissionAmount,
      'earningDate': Timestamp.fromDate(earningDate),
      'period': period.name,
      'description': description,
    };
  }
}

enum EarningPeriod {
  daily,
  weekly,
  monthly,
}
