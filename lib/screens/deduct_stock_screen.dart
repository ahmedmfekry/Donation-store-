import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/item_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/date_picker_field.dart';
import '../theme/app_theme.dart';

class DeductStockScreen extends StatefulWidget {
  const DeductStockScreen({super.key});

  @override
  State<DeductStockScreen> createState() => _DeductStockScreenState();
}

class _DeductStockScreenState extends State<DeductStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  
  ItemModel? _selectedItem;
  final _quantityController = TextEditingController();
  final _lotNumberController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _expireDate;
  DateTime? _dispensedDate;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _lotNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectItem(ItemModel item) {
    setState(() {
      _selectedItem = item;
      _lotNumberController.text = item.lotNumber;
      _expireDate = item.expireDate;
      _dispensedDate = item.dispensedDate;
      _notesController.text = '';
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الصنف'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final quantity = int.parse(_quantityController.text);
    if (quantity > _selectedItem!.currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الكمية المطلوبة ($quantity) أكبر من الرصيد المتاح (${_selectedItem!.currentStock})'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      await _firestoreService.deductStock(
        itemId: _selectedItem!.id,
        categoryName: _selectedItem!.categoryName,
        quantity: quantity,
        unit: _selectedItem!.unit,
        lotNumber: _lotNumberController.text,
        expireDate: _expireDate ?? _selectedItem!.expireDate,
        dispensedDate: _dispensedDate,
        notes: _notesController.text,
        userId: authService.currentUserId,
        userEmail: authService.currentUserEmail,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ تم خصم الرصيد بنجاح'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Clear form
        _formKey.currentState!.reset();
        setState(() {
          _selectedItem = null;
          _quantityController.clear();
          _lotNumberController.clear();
          _notesController.clear();
          _expireDate = null;
          _dispensedDate = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<ItemModel>>(
        stream: _firestoreService.getAllItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('خطأ: ${snapshot.error}'),
            );
          }

          final allItems = snapshot.data ?? [];
          final availableItems = allItems.where((item) => item.currentStock > 0).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Card(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'خصم رصيد',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'خصم للحملات الخارجية',
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

                // Available items list
                if (availableItems.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد أصناف متاحة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'يرجى إضافة طلبيات أولاً',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  const Text(
                    'اختر الصنف المراد خصمه:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Items list
                  ...availableItems.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: _selectedItem?.id == item.id ? 8 : 2,
                    color: _selectedItem?.id == item.id 
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.isExpiringSoon
                            ? AppTheme.errorColor
                            : AppTheme.primaryColor,
                        child: Text(
                          item.currentStock.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        item.categoryName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Lot: ${item.lotNumber} | انتهاء: ${DateFormat('dd/MM/yyyy').format(item.expireDate)}',
                      ),
                      trailing: Icon(
                        _selectedItem?.id == item.id 
                            ? Icons.check_circle 
                            : Icons.radio_button_unchecked,
                        color: _selectedItem?.id == item.id 
                            ? AppTheme.primaryColor 
                            : AppTheme.textSecondary,
                      ),
                      onTap: () => _selectItem(item),
                    ),
                  )),

                  if (_selectedItem != null) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Current stock info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.successColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'الرصيد الحالي:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_selectedItem!.currentStock} ${_selectedItem!.unit}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          CustomTextField(
                            label: 'الكمية المراد خصمها *',
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال الكمية';
                              }
                              if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                return 'يرجى إدخال عدد صحيح';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          CustomTextField(
                            label: 'Lot Number',
                            controller: _lotNumberController,
                            readOnly: true,
                          ),

                          const SizedBox(height: 16),

                          DatePickerField(
                            label: 'تاريخ الصرف (اختياري)',
                            selectedDate: _dispensedDate,
                            onDateSelected: (date) {
                              setState(() {
                                _dispensedDate = date;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          CustomTextField(
                            label: 'ملاحظات *',
                            controller: _notesController,
                            maxLines: 3,
                            hintText: 'سبب الخصم (حملة خارجية، إلخ)...',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال سبب الخصم';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          CustomButton(
                            text: 'خصم من الرصيد',
                            icon: Icons.remove,
                            onPressed: _submitForm,
                            isLoading: _isLoading,
                            backgroundColor: AppTheme.accentColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
