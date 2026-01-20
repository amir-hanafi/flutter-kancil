

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
      version: 6, // ⬅️ NAIKKAN VERSION
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
            date TEXT NOT NULL,
            is_refund INTEGER DEFAULT 0,
            refund_from INTEGER
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

        // TABLE REFUNDS
        await db.execute("""
          CREATE TABLE refunds (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transaction_id INTEGER,
            amount INTEGER,
            reason TEXT,
            created_at TEXT
          );
        """);

        // TABLE STORE PROFILE
        await db.execute("""
          CREATE TABLE store_profile (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            address TEXT,
            phone TEXT,
            logo TEXT
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

        if (oldVersion < 4) {
          await db.execute("""
          CREATE TABLE store_profile (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            address TEXT,
            phone TEXT,
            logo TEXT
          );
          """);
        }

        // ✅ REFUND SYSTEM
        if (oldVersion < 5) {
          if (oldVersion < 5) {
            await db.execute("ALTER TABLE transactions ADD COLUMN is_refund INTEGER DEFAULT 0;");
            await db.execute("ALTER TABLE transactions ADD COLUMN refund_from INTEGER;");
          }


          await db.execute("""
            CREATE TABLE refunds (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              transaction_id INTEGER,
              amount INTEGER,
              reason TEXT,
              created_at TEXT
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
  static Future<int> insertTransaction(
    int total,
    List<Map<String, dynamic>> items,
  ) async {
    final db = await database();

    final txnId = await db.insert("transactions", {
      "total": total,
      "date": DateTime.now().toIso8601String(),
      "is_refund": 0,
      "refund_from": null,
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

  // ================== REFUND ==================
  static Future<void> markTransactionRefund(int transactionId) async {
    final db = await database();
    await db.update(
      "transactions",
      {
        "is_refund": 1,
      },
      where: "id = ?",
      whereArgs: [transactionId],
    );
  }

  static Future<void> insertRefund(Map<String, dynamic> data) async {
    final db = await database();
    await db.insert("refunds", data);
  }

  static Future<List<Map<String, dynamic>>> getRefunds() async {
    final db = await database();
    return await db.query("refunds", orderBy: "id DESC");
  }

  // ================== STORE PROFILE ==================
  static Future<Map<String, dynamic>?> getStoreProfile() async {
    final db = await database();
    final res = await db.query("store_profile", limit: 1);
    return res.isNotEmpty ? res.first : null;
  }

  static Future<void> saveStoreProfile(Map<String, dynamic> data) async {
    final db = await database();
    final res = await db.query("store_profile", limit: 1);

    if (res.isEmpty) {
      await db.insert("store_profile", data);
    } else {
      await db.update(
        "store_profile",
        data,
        where: "id = ?",
        whereArgs: [res.first['id']],
      );
    }
  }

  static Future<int> insertRefundTransaction(
  int fromTransactionId,
  int total,
  List<Map<String, dynamic>> items,
) async {
  final db = await database();

  final newId = await db.insert("transactions", {
    "total": total, // ✅ TOTAL BARU (SISA)
    "date": DateTime.now().toIso8601String(),
    "is_refund": 1,
    "refund_from": fromTransactionId,
  });

  for (var item in items) {
    await db.insert("transaction_items", {
      "transaction_id": newId,
      "product_id": item['productId'],
      "name": item['name'],
      "type": item['type'],
      "qty": item['qty'],
      "price": item['price'],
    });
  }

  return newId;
}


}
