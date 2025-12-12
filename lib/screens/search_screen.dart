import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../models/item_model.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _firestoreService = FirestoreService();
  CategoryModel? _selectedCategory;
  List<ItemModel> _searchResults = [];
  List<TransactionModel> _transactions = [];
  bool _isSearching = false;

  void _performSearch() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الصنف'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSearching = true);
  }

  int _getTotalStock() {
    return _searchResults.fold(0, (sum, item) => sum + item.currentStock);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              color: AppTheme.secondaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'استعلام',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'البحث عن الأصناف',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Search section
            StreamBuilder<List<CategoryModel>>(
              stream: _firestoreService.getCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<CategoryModel>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'اختر الصنف',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<CategoryModel>(
                          value: category,
                          child: Text('${category.name} (${category.unit})'),
                        );
                      }).toList(),
                      onChanged: (category) {
                        setState(() {
                          _selectedCategory = category;
                          _isSearching = false;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _performSearch,
                      icon: const Icon(Icons.search),
                      label: const Text('بحث'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Results
            if (_isSearching && _selectedCategory != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              StreamBuilder<List<ItemModel>>(
                stream: _firestoreService.searchItemsByName(_selectedCategory!.name),
                builder: (context, itemSnapshot) {
                  if (itemSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  _searchResults = itemSnapshot.data ?? [];

                  if (_searchResults.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'لا توجد نتائج',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Summary Card
                      Card(
                        color: AppTheme.successColor.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'إجمالي الرصيد:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_getTotalStock()} ${_selectedCategory!.unit}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.successColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('عدد السجلات:'),
                                  Text(
                                    '${_searchResults.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Items list
                      const Text(
                        'تفاصيل الأصناف:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ..._searchResults.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: item.isExpired
                                ? AppTheme.errorColor
                                : item.isExpiringSoon
                                    ? Colors.orange
                                    : AppTheme.successColor,
                            child: Text(
                              item.currentStock.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            'Lot: ${item.lotNumber}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'انتهاء: ${DateFormat('dd/MM/yyyy').format(item.expireDate)}',
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildDetailRow('الكمية الأصلية', '${item.quantity} ${item.unit}'),
                                  _buildDetailRow('الرصيد الحالي', '${item.currentStock} ${item.unit}'),
                                  _buildDetailRow('تاريخ الانتهاء', DateFormat('dd/MM/yyyy').format(item.expireDate)),
                                  if (item.dispensedDate != null)
                                    _buildDetailRow('تاريخ الصرف', DateFormat('dd/MM/yyyy').format(item.dispensedDate!)),
                                  if (item.notes.isNotEmpty)
                                    _buildDetailRow('ملاحظات', item.notes),
                                  _buildDetailRow('تاريخ الإضافة', DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt)),

                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),

                                  // Transactions for this item
                                  StreamBuilder<List<TransactionModel>>(
                                    stream: _firestoreService.getTransactionsByItem(item.id),
                                    builder: (context, transSnapshot) {
                                      final transactions = transSnapshot.data ?? [];

                                      if (transactions.isEmpty) {
                                        return const Text(
                                          'لا توجد عمليات',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        );
                                      }

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'سجل العمليات:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...transactions.map((trans) => Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  trans.type == TransactionType.add
                                                      ? Icons.add_circle
                                                      : Icons.remove_circle,
                                                  color: trans.type == TransactionType.add
                                                      ? AppTheme.successColor
                                                      : AppTheme.errorColor,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '${trans.typeDisplayText}: ${trans.quantity} ${trans.unit} - ${DateFormat('dd/MM/yyyy').format(trans.createdAt)}',
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
