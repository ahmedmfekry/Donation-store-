import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String categoryId; // Reference to category
  final String categoryName; // اسم الصنف
  final int quantity; // العدد
  final String unit; // الوحدة
  final String lotNumber; // Lot Number
  final DateTime expireDate; // تاريخ الانتهاء
  final DateTime? dispensedDate; // تاريخ الصرف (optional)
  final String notes; // ملاحظات
  final int currentStock; // الرصيد الحالي
  final DateTime createdAt;
  final String createdBy; // User who created this entry

  ItemModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.quantity,
    required this.unit,
    required this.lotNumber,
    required this.expireDate,
    this.dispensedDate,
    required this.notes,
    required this.currentStock,
    required this.createdAt,
    required this.createdBy,
  });

  // Check if item is expiring soon (within 30 days)
  bool get isExpiringSoon {
    final now = DateTime.now();
    final difference = expireDate.difference(now).inDays;
    return difference <= 30 && difference >= 0;
  }

  // Check if item is expired
  bool get isExpired {
    return DateTime.now().isAfter(expireDate);
  }

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'quantity': quantity,
      'unit': unit,
      'lotNumber': lotNumber,
      'expireDate': Timestamp.fromDate(expireDate),
      'dispensedDate': dispensedDate != null ? Timestamp.fromDate(dispensedDate!) : null,
      'notes': notes,
      'currentStock': currentStock,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  // Create from Firestore
  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      quantity: data['quantity'] ?? 0,
      unit: data['unit'] ?? '',
      lotNumber: data['lotNumber'] ?? '',
      expireDate: (data['expireDate'] as Timestamp).toDate(),
      dispensedDate: data['dispensedDate'] != null 
          ? (data['dispensedDate'] as Timestamp).toDate() 
          : null,
      notes: data['notes'] ?? '',
      currentStock: data['currentStock'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  // Create a copy with modifications
  ItemModel copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    int? quantity,
    String? unit,
    String? lotNumber,
    DateTime? expireDate,
    DateTime? dispensedDate,
    String? notes,
    int? currentStock,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return ItemModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      lotNumber: lotNumber ?? this.lotNumber,
      expireDate: expireDate ?? this.expireDate,
      dispensedDate: dispensedDate ?? this.dispensedDate,
      notes: notes ?? this.notes,
      currentStock: currentStock ?? this.currentStock,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
