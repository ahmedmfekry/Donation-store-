import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'add_stock_screen.dart';
import 'deduct_stock_screen.dart';
import 'search_screen.dart';
import 'manage_items_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AddStockScreen(),
    DeductStockScreen(),
    SearchScreen(),
    ManageItemsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة مخزون التبرعات'),
        actions: [
          // User info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                authService.currentUserDisplayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          // Sign out button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تسجيل الخروج'),
                  content: const Text('هل تريد تسجيل الخروج؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                      ),
                      child: const Text('تسجيل الخروج'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await authService.signOut();
              }
            },
          ),
        ],
      ),
      
      body: _screens[_currentIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_rounded),
            label: 'إضافة طلبية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.remove_circle_outline_rounded),
            label: 'خصم رصيد',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'استعلام',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_rounded),
            label: 'إدارة الأصناف',
          ),
        ],
      ),
    );
  }
}
