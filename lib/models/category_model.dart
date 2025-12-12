import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String unit; // الوحدة (كرتونة، علبة، قطعة، إلخ)
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.unit,
    required this.createdAt,
  });

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Firestore
  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      unit: data['unit'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Create from Map
  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      unit: map['unit'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
