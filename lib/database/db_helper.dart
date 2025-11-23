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
      version: 2, // UPGRADE DATABASE
      onCreate: (db, version) async {
        await db.execute("""
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            price INTEGER NOT NULL,
            barcode TEXT,
            image TEXT,

            is_parent INTEGER DEFAULT 0,
            parent_id INTEGER,
            pack_size INTEGER,
            stock_qty INTEGER DEFAULT 0
          );
        """);
      },

      // RUN WHEN DATABASE NEEDS UPGRADE
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE products ADD COLUMN is_parent INTEGER DEFAULT 0;");
          await db.execute("ALTER TABLE products ADD COLUMN parent_id INTEGER;");
          await db.execute("ALTER TABLE products ADD COLUMN pack_size INTEGER;");
          await db.execute("ALTER TABLE products ADD COLUMN stock_qty INTEGER DEFAULT 0;");
        }
      },
    );

    return _db!;
  }

  // INSERT PRODUCT
  static Future<int> insertProduct(Map<String, dynamic> data) async {
    final db = await database();
    return await db.insert("products", data);
  }

  // GET PRODUCTS
  static Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database();
    return await db.query("products", orderBy: "id DESC");
  }

  // Get single product by id
  static Future<Map<String, dynamic>?> getProductById(int id) async {
    final db = await database();
    final res = await db.query(
      "products",
      where: "id = ?",
      whereArgs: [id],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  // Get child products for a parent id
  static Future<List<Map<String, dynamic>>> getChildProducts(int parentId) async {
    final db = await database();
    return await db.query(
      "products",
      where: "parent_id = ?",
      whereArgs: [parentId],
      orderBy: "id DESC",
    );
  }

  // DELETE PRODUCT
  static Future<int> deleteProduct(int id) async {
    final db = await database();
    return await db.delete("products", where: "id = ?", whereArgs: [id]);
  }

  // GET BY BARCODE
  static Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final db = await database();
    final res = await db.query(
      "products",
      where: "barcode = ?",
      whereArgs: [barcode],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  // UPDATE STOCK
  static Future<int> updateStock(int id, int newQty) async {
    final db = await database();
    return await db.update(
      "products",
      {"stock_qty": newQty},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // GET ONLY PARENT PRODUCTS
  static Future<List<Map<String, dynamic>>> getOnlyParents() async {
    final db = await database();
    return await db.query(
      "products",
      where: "is_parent = ?",
      whereArgs: [1],
      orderBy: "name ASC",
    );
  }

  // UPDATE PRODUCT
  static Future<int> updateProduct(int id, Map<String, dynamic> data) async {
    final db = await database();
    return await db.update(
      "products",
      data,
      where: "id = ?",
      whereArgs: [id],
    );
  }


}
