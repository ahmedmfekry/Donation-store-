import 'package:flutter/material.dart';
import '../models/category_model.dart';

class ItemDropdown extends StatelessWidget {
  final String label;
  final List<CategoryModel> categories;
  final CategoryModel? selectedCategory;
  final void Function(CategoryModel?) onChanged;
  final String? Function(CategoryModel?)? validator;

  const ItemDropdown({
    super.key,
    required this.label,
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<CategoryModel>(
      value: selectedCategory,
      decoration: InputDecoration(
        labelText: label,
      ),
      items: categories.map((category) {
        return DropdownMenuItem<CategoryModel>(
          value: category,
          child: Text('${category.name} (${category.unit})'),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
