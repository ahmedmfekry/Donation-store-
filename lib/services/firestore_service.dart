import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import '../models/item_model.dart';
import '../models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _categoriesCollection => _db.collection('categories');
  CollectionReference get _itemsCollection => _db.collection('items');
  CollectionReference get _transactionsCollection => _db.collection('transactions');

  // ========== Categories ==========

  // Add new category
  Future<String> addCategory(String name, String unit) async {
    try {
      final docRef = await _categoriesCollection.add({
        'name': name,
        'unit': unit,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('خطأ في إضافة الصنف: $e');
    }
  }

  // Get all categories
  Stream<List<CategoryModel>> getCategories() {
    return _categoriesCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList());
  }

  // Update category
  Future<void> updateCategory(String id, String name, String unit) async {
    try {
      await _categoriesCollection.doc(id).update({
        'name': name,
        'unit': unit,
      });
    } catch (e) {
      throw Exception('خطأ في تحديث الصنف: $e');
    }
  }

  // Delete category
  Future<void> deleteCategory(String id) async {
    try {
      await _categoriesCollection.doc(id).delete();
    } catch (e) {
      throw Exception('خطأ في حذف الصنف: $e');
    }
  }

  // ========== Items (Stock) ==========

  // Add stock (increases inventory)
  Future<void> addStock({
    required String categoryId,
    required String categoryName,
    required int quantity,
    required String unit,
    required String lotNumber,
    required DateTime expireDate,
    DateTime? dispensedDate,
    required String notes,
    required String userId,
    required String userEmail,
  }) async {
    try {
      // Create new item entry
      final itemRef = await _itemsCollection.add({
        'categoryId': categoryId,
        'categoryName': categoryName,
        'quantity': quantity,
        'unit': unit,
        'lotNumber': lotNumber,
        'expireDate': Timestamp.fromDate(expireDate),
        'dispensedDate': dispensedDate != null ? Timestamp.fromDate(dispensedDate) : null,
        'notes': notes,
        'currentStock': quantity, // Initial stock equals quantity
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': userId,
      });

      // Record transaction
      await _transactionsCollection.add({
        'itemId': itemRef.id,
        'categoryName': categoryName,
        'type': 'add',
        'quantity': quantity,
        'unit': unit,
        'lotNumber': lotNumber,
        'expireDate': Timestamp.fromDate(expireDate),
        'dispensedDate': dispensedDate != null ? Timestamp.fromDate(dispensedDate) : null,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': userId,
        'userEmail': userEmail,
      });
    } catch (e) {
      throw Exception('خطأ في إضافة الطلبية: $e');
    }
  }

  // Deduct stock (decreases inventory)
  Future<void> deductStock({
    required String itemId,
    required String categoryName,
    required int quantity,
    required String unit,
    required String lotNumber,
    required DateTime expireDate,
    DateTime? dispensedDate,
    required String notes,
    required String userId,
    required String userEmail,
  }) async {
    try {
      final itemDoc = await _itemsCollection.doc(itemId).get();
      
      if (!itemDoc.exists) {
        throw Exception('الصنف غير موجود');
      }

      final item = ItemModel.fromFirestore(itemDoc);
      final newStock = item.currentStock - quantity;

      if (newStock < 0) {
        throw Exception('الكمية المطلوب خصمها أكبر من الرصيد المتاح');
      }

      // Update item stock
      await _itemsCollection.doc(itemId).update({
        'currentStock': newStock,
      });

      // Record transaction
      await _transactionsCollection.add({
        'itemId': itemId,
        'categoryName': categoryName,
        'type': 'deduct',
        'quantity': quantity,
        'unit': unit,
        'lotNumber': lotNumber,
        'expireDate': Timestamp.fromDate(expireDate),
        'dispensedDate': dispensedDate != null ? Timestamp.fromDate(dispensedDate) : null,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': userId,
        'userEmail': userEmail,
      });
    } catch (e) {
      throw Exception('خطأ في خصم الرصيد: $e');
    }
  }

  // Get all items
  Stream<List<ItemModel>> getAllItems() {
    return _itemsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ItemModel.fromFirestore(doc))
            .toList());
  }

  // Get items by category
  Stream<List<ItemModel>> getItemsByCategory(String categoryId) {
    return _itemsCollection
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ItemModel.fromFirestore(doc))
            .toList());
  }

  // Search items by category name
  Stream<List<ItemModel>> searchItemsByName(String categoryName) {
    return _itemsCollection
        .where('categoryName', isEqualTo: categoryName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ItemModel.fromFirestore(doc))
            .toList());
  }

  // Get items expiring soon (within 30 days)
  Stream<List<ItemModel>> getExpiringSoonItems() {
    final now = DateTime.now();
    final thirtyDaysLater = now.add(const Duration(days: 30));

    return _itemsCollection
        .where('expireDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('expireDate', isLessThanOrEqualTo: Timestamp.fromDate(thirtyDaysLater))
        .where('currentStock', isGreaterThan: 0)
        .orderBy('expireDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ItemModel.fromFirestore(doc))
            .toList());
  }

  // ========== Transactions ==========

  // Get all transactions
  Stream<List<TransactionModel>> getAllTransactions() {
    return _transactionsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  // Get transactions by item
  Stream<List<TransactionModel>> getTransactionsByItem(String itemId) {
    return _transactionsCollection
        .where('itemId', isEqualTo: itemId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  // Get transactions by category name
  Stream<List<TransactionModel>> getTransactionsByCategory(String categoryName) {
    return _transactionsCollection
        .where('categoryName', isEqualTo: categoryName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }
}
