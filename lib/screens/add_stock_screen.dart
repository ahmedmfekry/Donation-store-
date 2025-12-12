import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/item_dropdown.dart';
import '../widgets/date_picker_field.dart';
import '../theme/app_theme.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  
  CategoryModel? _selectedCategory;
  final _quantityController = TextEditingController();
  final _lotNumberController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _expireDate;
  DateTime? _dispensedDate;
  
  bool _isLoading = false;

  void _showQuickAddCategoryDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('إضافة صنف جديد'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: 'اسم الصنف *',
                  controller: nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال اسم الصنف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'الوحدة *',
                  controller: unitController,
                  hintText: 'كرتونة، علبة، قطعة، إلخ',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال الوحدة';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => isSaving = true);
                      try {
                        final newId = await _firestoreService.addCategory(
                          nameController.text,
                          unitController.text,
                        );

                        if (!context.mounted) return;

                        final newCategory = CategoryModel(
                          id: newId,
                          name: nameController.text,
                          unit: unitController.text,
                          createdAt: DateTime.now(),
                        );

                        Navigator.pop(context);
                        setState(() {
                          _selectedCategory = newCategory;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ تمت إضافة الصنف'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ: ${e.toString()}'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() => isSaving = false);
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _lotNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الصنف'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_expireDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار تاريخ الانتهاء'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      await _firestoreService.addStock(
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        quantity: int.parse(_quantityController.text),
        unit: _selectedCategory!.unit,
        lotNumber: _lotNumberController.text,
        expireDate: _expireDate!,
        dispensedDate: _dispensedDate,
        notes: _notesController.text,
        userId: authService.currentUserId,
        userEmail: authService.currentUserEmail,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ تمت إضافة الطلبية بنجاح'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Clear form
        _formKey.currentState!.reset();
        setState(() {
          _selectedCategory = null;
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
      body: StreamBuilder<List<CategoryModel>>(
        stream: _firestoreService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('خطأ: ${snapshot.error}'),
            );
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 64,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد أصناف',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'يرجى إضافة أصناف أولاً من قسم "إدارة الأصناف"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Card(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_box,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إضافة طلبية جديدة',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'إضافة أصناف للمخزن',
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

                  // Form fields
                  ItemDropdown(
                    label: 'اسم الصنف *',
                    categories: categories,
                    selectedCategory: _selectedCategory,
                    onChanged: (category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    validator: (value) {
                      if (value == null) return 'يرجى اختيار الصنف';
                      return null;
                    },
                    onAddNew: _showQuickAddCategoryDialog,
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'العدد *',
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال العدد';
                      }
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'يرجى إدخال عدد صحيح';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Lot Number *',
                    controller: _lotNumberController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال Lot Number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  DatePickerField(
                    label: 'تاريخ الانتهاء *',
                    selectedDate: _expireDate,
                    onDateSelected: (date) {
                      setState(() {
                        _expireDate = date;
                      });
                    },
                    firstDate: DateTime.now(),
                    validator: (value) {
                      if (_expireDate == null) {
                        return 'يرجى اختيار تاريخ الانتهاء';
                      }
                      return null;
                    },
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
                    label: 'ملاحظات',
                    controller: _notesController,
                    maxLines: 3,
                    hintText: 'أدخل أي ملاحظات إضافية...',
                  ),

                  const SizedBox(height: 32),

                  CustomButton(
                    text: 'إضافة الطلبية',
                    icon: Icons.check,
                    onPressed: _submitForm,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
