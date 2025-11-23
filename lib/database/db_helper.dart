import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;
  

  static Future<Database> database() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "kancil.db");

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute("""
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            price REAL NOT NULL,
            barcode TEXT,
            image TEXT
          );
        """);
      },
    );

    return _db!;
  }

  static Future<int> insertProduct(Map<String, dynamic> data) async {
    final db = await database();
    return await db.insert("products", data);
  }

  static Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database();
    return await db.query("products", orderBy: "id DESC");
  }

  static Future<int> deleteProduct(int id) async {
    final db = await database();
    return await db.delete("products", where: "id = ?", whereArgs: [id]);
  }

  static Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
  final db = await database();
  final res = await db.query(
    "products",
    where: "barcode = ?",
    whereArgs: [barcode],
    limit: 1,
  );

  if (res.isNotEmpty) {
    return res.first;
  }
  return null; // tidak ditemukan
}

  
}


