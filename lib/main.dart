import 'package:flutter/material.dart';
import 'package:kancil/pages/cart_page.dart';
import 'package:kancil/pages/list_page.dart';
import 'package:kancil/pages/stock_in_out_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainPage(),
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

  void _goToListPage() {
  setState(() {
    _selectedIndex = 0;
  });
}


@override
void initState() {
  super.initState();
  _pages = [
    ListPage(),
    StockInOutPage(onSuccess: _goToListPage),
    CartPage(),
  ];
}


  // Saat item navbar ditekan
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
        type: BottomNavigationBarType.fixed, // agar 3+ item bisa tampil
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'List barang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_search),
            label: 'Masuk/Keluar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'keranjang',
          ),
        ],
      ),
    );
  }
}