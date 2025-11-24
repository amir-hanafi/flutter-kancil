import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  // ================== DATABASE INIT ==================
  static Future<Database> database() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "kancil.db");

    _db = await openDatabase(
      path,
      version: 3, // update ke versi 3 untuk transaksi
      onCreate: (db, version) async {
        // TABLE PRODUCTS
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

        // TABLE TRANSACTIONS
        await db.execute("""
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            total INTEGER NOT NULL,
            date TEXT NOT NULL
          );
        """);

        // TABLE TRANSACTION ITEMS
        await db.execute("""
          CREATE TABLE transaction_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transaction_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            qty INTEGER NOT NULL,
            price INTEGER NOT NULL
          );
        """);
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE products ADD COLUMN is_parent INTEGER DEFAULT 0;");
          await db.execute("ALTER TABLE products ADD COLUMN parent_id INTEGER;");
          await db.execute("ALTER TABLE products ADD COLUMN pack_size INTEGER;");
          await db.execute("ALTER TABLE products ADD COLUMN stock_qty INTEGER DEFAULT 0;");
        }

        if (oldVersion < 3) {
          await db.execute("""
            CREATE TABLE transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              total INTEGER NOT NULL,
              date TEXT NOT NULL
            );
          """);

          await db.execute("""
            CREATE TABLE transaction_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              transaction_id INTEGER NOT NULL,
              product_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              qty INTEGER NOT NULL,
              price INTEGER NOT NULL
            );
          """);
        }
      },
    );

    return _db!;
  }

  // ================== PRODUCTS ==================
  static Future<int> insertProduct(Map<String, dynamic> data) async {
    final db = await database();
    return await db.insert("products", data);
  }

  static Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database();
    return await db.query("products", orderBy: "id DESC");
  }

  static Future<Map<String, dynamic>?> getProductById(int id) async {
    final db = await database();
    final res = await db.query("products", where: "id = ?", whereArgs: [id], limit: 1);
    return res.isNotEmpty ? res.first : null;
  }

  static Future<List<Map<String, dynamic>>> getChildProducts(int parentId) async {
    final db = await database();
    return await db.query("products", where: "parent_id = ?", whereArgs: [parentId], orderBy: "id DESC");
  }

  static Future<int> deleteProduct(int id) async {
    final db = await database();
    return await db.delete("products", where: "id = ?", whereArgs: [id]);
  }

  static Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final db = await database();
    final res = await db.query("products", where: "barcode = ?", whereArgs: [barcode], limit: 1);
    return res.isNotEmpty ? res.first : null;
  }

  static Future<int> updateStock(int id, int newQty) async {
    final db = await database();
    return await db.update("products", {"stock_qty": newQty}, where: "id = ?", whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getOnlyParents() async {
    final db = await database();
    return await db.query("products", where: "is_parent = ?", whereArgs: [1], orderBy: "name ASC");
  }

  static Future<int> updateProduct(int id, Map<String, dynamic> data) async {
    final db = await database();
    return await db.update("products", data, where: "id = ?", whereArgs: [id]);
  }

  // ================== TRANSACTIONS ==================
  static Future<int> insertTransaction(int total, List<Map<String, dynamic>> items) async {
    final db = await database();
    final txnId = await db.insert("transactions", {
      "total": total,
      "date": DateTime.now().toIso8601String(),
    });

    for (var item in items) {
      await db.insert("transaction_items", {
        "transaction_id": txnId,
        "product_id": item['productId'],
        "name": item['name'],
        "type": item['type'],
        "qty": item['qty'],
        "price": item['price'],
      });
    }

    return txnId;
  }

  static Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await database();
    return await db.query("transactions", orderBy: "date DESC");
  }

  static Future<List<Map<String, dynamic>>> getTransactionItems(int transactionId) async {
    final db = await database();
    return await db.query("transaction_items", where: "transaction_id = ?", whereArgs: [transactionId]);
  }
}
