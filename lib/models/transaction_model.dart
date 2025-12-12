import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  add, // إضافة للمخزن
  deduct, // خصم من المخزن
}

class TransactionModel {
  final String id;
  final String itemId; // Reference to item
  final String categoryName; // اسم الصნف
  final TransactionType type; // نوع العملية
  final int quantity; // العدد
  final String unit; // الوحدة
  final String lotNumber; // Lot Number
  final DateTime expireDate; // تاريخ الانتهاء
  final DateTime? dispensedDate; // تاريخ الصرف
  final String notes; // ملاحظات
  final DateTime createdAt;
  final String createdBy; // User who performed this transaction
  final String userEmail; // Email of the user

  TransactionModel({
    required this.id,
    required this.itemId,
    required this.categoryName,
    required this.type,
    required this.quantity,
    required this.unit,
    required this.lotNumber,
    required this.expireDate,
    this.dispensedDate,
    required this.notes,
    required this.createdAt,
    required this.createdBy,
    required this.userEmail,
  });

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'categoryName': categoryName,
      'type': type.name,
      'quantity': quantity,
      'unit': unit,
      'lotNumber': lotNumber,
      'expireDate': Timestamp.fromDate(expireDate),
      'dispensedDate': dispensedDate != null ? Timestamp.fromDate(dispensedDate!) : null,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'userEmail': userEmail,
    };
  }

  // Create from Firestore
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      type: data['type'] == 'deduct' ? TransactionType.deduct : TransactionType.add,
      quantity: data['quantity'] ?? 0,
      unit: data['unit'] ?? '',
      lotNumber: data['lotNumber'] ?? '',
      expireDate: (data['expireDate'] as Timestamp).toDate(),
      dispensedDate: data['dispensedDate'] != null 
          ? (data['dispensedDate'] as Timestamp).toDate() 
          : null,
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      userEmail: data['userEmail'] ?? '',
    );
  }

  // Get display text for transaction type
  String get typeDisplayText {
    return type == TransactionType.add ? 'إضافة' : 'خصم';
  }
}
