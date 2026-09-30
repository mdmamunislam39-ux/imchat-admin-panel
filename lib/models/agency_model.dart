import 'package:cloud_firestore/cloud_firestore.dart';

class AgencyModel {
  final String id;
  final String agencyName;
  final String? logoUrl;
  final String agencyIdNumber;
  final AgencyOwner owner;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final double totalCommissionEarned;
  final int totalHosts;
  final List<String> hostIds;
  /// Commission rate as a decimal (e.g. 0.10 = 10%). Default 10%.
  final double commissionRate;
  /// When true, admin has paused commission payouts for this agency.
  final bool isCommissionHeld;

  AgencyModel({
    required this.id,
    required this.agencyName,
    this.logoUrl,
    required this.agencyIdNumber,
    required this.owner,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.totalCommissionEarned = 0.0,
    this.totalHosts = 0,
    this.hostIds = const [],
    this.commissionRate = 0.10,
    this.isCommissionHeld = false,
  });

  String get ownerUserId => owner.userId ?? '';

  factory AgencyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ownerMap = Map<String, dynamic>.from(data['owner'] ?? {});
    if ((ownerMap['userId'] == null || ownerMap['userId'].toString().isEmpty) && data['ownerUserId'] != null) {
      ownerMap['userId'] = data['ownerUserId'];
    }
    return AgencyModel(
      id: doc.id,
      agencyName: data['agencyName'] ?? data['name'] ?? data['title'] ?? '',
      logoUrl: data['logoUrl'] ?? data['photoUrl'] ?? data['imageUrl'],
      agencyIdNumber: data['agencyIdNumber'] ?? data['agencyId'] ?? data['searchId'] ?? doc.id,
      owner: AgencyOwner.fromMap(ownerMap),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      totalCommissionEarned: (data['totalCommissionEarned'] ?? 0.0).toDouble(),
      totalHosts: data['totalHosts'] ?? 0,
      hostIds: List<String>.from(data['hostIds'] ?? []),
      commissionRate: (data['commissionRate'] ?? 0.10).toDouble(),
      isCommissionHeld: data['isCommissionHeld'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'agencyName': agencyName,
      'logoUrl': logoUrl,
      'agencyIdNumber': agencyIdNumber,
      'owner': owner.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'totalCommissionEarned': totalCommissionEarned,
      'totalHosts': totalHosts,
      'hostIds': hostIds,
      'commissionRate': commissionRate,
      'isCommissionHeld': isCommissionHeld,
    };
  }

  AgencyModel copyWith({
    String? id,
    String? agencyName,
    String? logoUrl,
    String? agencyIdNumber,
    AgencyOwner? owner,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    double? totalCommissionEarned,
    int? totalHosts,
    List<String>? hostIds,
    double? commissionRate,
    bool? isCommissionHeld,
  }) {
    return AgencyModel(
      id: id ?? this.id,
      agencyName: agencyName ?? this.agencyName,
      logoUrl: logoUrl ?? this.logoUrl,
      agencyIdNumber: agencyIdNumber ?? this.agencyIdNumber,
      owner: owner ?? this.owner,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      totalCommissionEarned: totalCommissionEarned ?? this.totalCommissionEarned,
      totalHosts: totalHosts ?? this.totalHosts,
      hostIds: hostIds ?? this.hostIds,
      commissionRate: commissionRate ?? this.commissionRate,
      isCommissionHeld: isCommissionHeld ?? this.isCommissionHeld,
    );
  }
}

class AgencyOwner {
  final String name;
  final String phone;
  final String email;
  final String? profileImageUrl;
  final DateTime? dateOfBirth;
  final String? address;
  final String? userId;

  AgencyOwner({
    required this.name,
    required this.phone,
    required this.email,
    this.profileImageUrl,
    this.dateOfBirth,
    this.address,
    this.userId,
  });

  factory AgencyOwner.fromMap(Map<String, dynamic> data) {
    return AgencyOwner(
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      dateOfBirth: data['dateOfBirth'] != null 
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      address: data['address'],
      userId: data['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'dateOfBirth': dateOfBirth != null 
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'address': address,
      'userId': userId,
    };
  }

  AgencyOwner copyWith({
    String? name,
    String? phone,
    String? email,
    String? profileImageUrl,
    DateTime? dateOfBirth,
    String? address,
    String? userId,
  }) {
    return AgencyOwner(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      userId: userId ?? this.userId,
    );
  }
}
