import 'package:flutter/material.dart';
import 'package:kancil/database/db_helper.dart';
import 'package:kancil/pages/cart_page.dart';
import 'package:kancil/pages/home_page.dart';
import 'package:kancil/pages/other.dart';
import 'package:kancil/pages/register_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  Widget _buildNavItem({
  required IconData icon,
  required String label,
  required int index,
}) {
  final bool isActive = _selectedIndex == index;

  return Expanded(
    child: InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? Colors.green : Colors.grey,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.green : Colors.grey,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
  );
}


  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(),
      CartPage(),
      OtherPage(),
    ];

    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    await Future.delayed(const Duration(seconds: 1)); // jeda setelah splash

    final store = await DBHelper.getStoreProfile();

    if (!mounted) return;

    if (store == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RegisterPage(),
          fullscreenDialog: true,
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  body: _pages[_selectedIndex],

  floatingActionButton: FloatingActionButton(
    backgroundColor: Colors.green,
    elevation: 4,
    onPressed: () {
      _onItemTapped(1); // Cart
    },
    child: const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
  ),
  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

  bottomNavigationBar: BottomAppBar(
    shape: const CircularNotchedRectangle(),
    notchMargin: 6,
    child: SizedBox(
      height: 55, // lebih pendek dari default
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(
            icon: Icons.home,
            label: "Beranda",
            index: 0,
          ),

          const SizedBox(width: 50), // ruang untuk FAB

          _buildNavItem(
            icon: Icons.more_vert,
            label: "Lainnya",
            index: 2,
          ),
        ],
      ),
    ),
  ),
);


  }
}
