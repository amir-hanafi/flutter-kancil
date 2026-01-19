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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'keranjang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_vert),
            label: 'lainnya',
          ),
        ],
      ),
    );
  }
}
