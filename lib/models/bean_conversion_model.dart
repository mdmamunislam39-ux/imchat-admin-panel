import 'package:cloud_firestore/cloud_firestore.dart';

class BeanConversionModel {
  final String id;
  final String userId;
  final String username;
  final double beansSpent;
  final double diamondsReceived;
  final DateTime createdAt;

  BeanConversionModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.beansSpent,
    required this.diamondsReceived,
    required this.createdAt,
  });

  factory BeanConversionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BeanConversionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      beansSpent: (data['beansSpent'] ?? 0.0).toDouble(),
      diamondsReceived: (data['diamondsReceived'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'beansSpent': beansSpent,
      'diamondsReceived': diamondsReceived,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
