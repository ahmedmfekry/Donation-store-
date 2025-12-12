import 'package:flutter/material.dart';
import '../models/category_model.dart';

class ItemDropdown extends StatelessWidget {
  final String label;
  final List<CategoryModel> categories;
  final CategoryModel? selectedCategory;
  final void Function(CategoryModel?) onChanged;
  final String? Function(CategoryModel?)? validator;
  final VoidCallback? onAddNew;

  const ItemDropdown({
    super.key,
    required this.label,
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
    this.validator,
    this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onAddNew != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).inputDecorationTheme.labelStyle,
              ),
              TextButton.icon(
                onPressed: onAddNew,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة صنف'),
              ),
            ],
          ),
        DropdownButtonFormField<CategoryModel>(
          value: selectedCategory,
          decoration: InputDecoration(
            labelText: onAddNew == null ? label : null,
          ),
          items: categories.map((category) {
            return DropdownMenuItem<CategoryModel>(
              value: category,
              child: Text('${category.name} (${category.unit})'),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
