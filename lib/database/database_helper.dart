import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/restaurant_model.dart';
import '../models/food_item_model.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/favorite_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  // Cache the *Future* (not the finished Database) so that several screens
  // asking for the DB at the same time all share one init. On web the
  // WASM/worker start-up is slow enough that the old null-check pattern let
  // two callers open (and seed) the database at once.
  static Future<Database>? _dbFuture;

  // Bump this whenever seed data changes so existing installs pick up the
  // new restaurants/menu instead of keeping stale local data.
  static const int _dbVersion = 2;

  Future<Database> get database => _dbFuture ??= _openOnce();

  Future<Database> _openOnce() async {
    try {
      return await _initDatabase();
    } catch (_) {
      _dbFuture = null; // allow a retry if init failed
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
  if (kIsWeb) {
    // No shared worker: needs only web/sqlite3.wasm (no sqflite_sw.js build).
    // Data still persists in IndexedDB; the only trade-off is that two open
    // browser tabs of the app don't coordinate with each other.
    databaseFactory = databaseFactoryFfiWebNoWebWorker;

    return await databaseFactory.openDatabase(
      'food_delivery_web.db',
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'food_delivery.db');

  return await openDatabase(
    path,
    version: _dbVersion,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
}

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Menu content changed completely (new restaurants/items), so old
    // restaurant/food/cart/favorite rows are no longer valid - wipe and
    // reseed. Users and Orders history are left untouched.
    await db.execute('DROP TABLE IF EXISTS Cart');
    await db.execute('DROP TABLE IF EXISTS Favorites');
    await db.execute('DROP TABLE IF EXISTS FoodItems');
    await db.execute('DROP TABLE IF EXISTS Restaurants');
    await _createTables(db);
    await _seedData(db);
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _seedData(db);
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Restaurants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        rating REAL NOT NULL,
        deliveryMinLow INTEGER NOT NULL,
        deliveryMinHigh INTEGER NOT NULL,
        freeDelivery INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS FoodItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        restaurantId INTEGER NOT NULL,
        name TEXT NOT NULL,
        section TEXT NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (restaurantId) REFERENCES Restaurants (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        foodItemId INTEGER NOT NULL,
        foodName TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        restaurantId INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES Users (id),
        FOREIGN KEY (foodItemId) REFERENCES FoodItems (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        itemsSummary TEXT NOT NULL,
        itemCount INTEGER NOT NULL,
        totalAmount REAL NOT NULL,
        status TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES Users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        foodItemId INTEGER NOT NULL,
        foodName TEXT NOT NULL,
        restaurantName TEXT NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (userId) REFERENCES Users (id),
        FOREIGN KEY (foodItemId) REFERENCES FoodItems (id)
      )
    ''');
  }

  Future<void> _seedData(Database db) async {
    final restaurants = [
      RestaurantModel(name: 'Urban Bites', category: 'Fast Food', rating: 4.4, deliveryMinLow: 20, deliveryMinHigh: 30, freeDelivery: true),
      RestaurantModel(name: 'Pizza Street', category: 'Pizza', rating: 4.6, deliveryMinLow: 30, deliveryMinHigh: 45, freeDelivery: true),
      RestaurantModel(name: 'Spice Garden', category: 'Pakistani', rating: 4.5, deliveryMinLow: 35, deliveryMinHigh: 50, freeDelivery: false),
      RestaurantModel(name: 'Wok & Bowl', category: 'Chinese', rating: 4.3, deliveryMinLow: 30, deliveryMinHigh: 40, freeDelivery: true),
      RestaurantModel(name: 'Brew House', category: 'Cafe', rating: 4.7, deliveryMinLow: 15, deliveryMinHigh: 25, freeDelivery: true),
      RestaurantModel(name: 'Wrap & Roll', category: 'Shawarma & Wraps', rating: 4.2, deliveryMinLow: 20, deliveryMinHigh: 30, freeDelivery: false),
      RestaurantModel(name: 'Sweet Cravings', category: 'Desserts', rating: 4.8, deliveryMinLow: 25, deliveryMinHigh: 35, freeDelivery: true),
      RestaurantModel(name: 'Desi Dastarkhwan', category: 'Desi Food', rating: 4.5, deliveryMinLow: 30, deliveryMinHigh: 45, freeDelivery: false),
    ];

    final restaurantIds = <String, int>{};
    for (final r in restaurants) {
      final id = await db.insert('Restaurants', r.toMap());
      restaurantIds[r.name] = id;
    }

    final foodData = <String, List<Map<String, dynamic>>>{
      'Urban Bites': [
        {'name': 'Zinger Burger', 'section': 'Burgers', 'price': 520.0},
        {'name': 'Chicken Burger', 'section': 'Burgers', 'price': 450.0},
        {'name': 'Beef Smash Burger', 'section': 'Burgers', 'price': 650.0},
        {'name': 'Chicken Cheese Burger', 'section': 'Burgers', 'price': 580.0},
        {'name': 'Loaded Fries', 'section': 'Sides', 'price': 420.0},
        {'name': 'Chicken Nuggets (6 pcs)', 'section': 'Sides', 'price': 350.0},
        {'name': 'BBQ Wings (8 pcs)', 'section': 'Sides', 'price': 480.0},
        {'name': 'Chicken Shawarma', 'section': 'Wraps', 'price': 300.0},
        {'name': 'Soft Drink', 'section': 'Drinks', 'price': 100.0},
      ],
      'Pizza Street': [
        {'name': 'Chicken Fajita Pizza', 'section': 'Pizza', 'price': 1150.0},
        {'name': 'Chicken Tikka Pizza', 'section': 'Pizza', 'price': 1150.0},
        {'name': 'Creamy Garlic Pizza', 'section': 'Pizza', 'price': 1250.0},
        {'name': 'Pepperoni Pizza', 'section': 'Pizza', 'price': 1450.0},
        {'name': 'BBQ Chicken Pizza', 'section': 'Pizza', 'price': 1300.0},
        {'name': 'Cheese Lovers Pizza', 'section': 'Pizza', 'price': 1200.0},
        {'name': 'Garlic Bread', 'section': 'Sides', 'price': 350.0},
        {'name': 'Cheese Sticks', 'section': 'Sides', 'price': 400.0},
      ],
      'Spice Garden': [
        {'name': 'Chicken Karahi', 'section': 'Karahi', 'price': 1200.0},
        {'name': 'Mutton Karahi', 'section': 'Karahi', 'price': 2000.0},
        {'name': 'Chicken Biryani', 'section': 'Rice', 'price': 350.0},
        {'name': 'Beef Pulao', 'section': 'Rice', 'price': 450.0},
        {'name': 'Chicken Handi', 'section': 'Karahi', 'price': 1250.0},
        {'name': 'Daal Makhni', 'section': 'Curries', 'price': 400.0},
        {'name': 'Chicken Seekh Kebab', 'section': 'BBQ', 'price': 500.0},
        {'name': 'Tandoori Roti', 'section': 'Bread', 'price': 40.0},
        {'name': 'Garlic Naan', 'section': 'Bread', 'price': 100.0},
        {'name': 'Raita', 'section': 'Sides', 'price': 100.0},
      ],
      'Wok & Bowl': [
        {'name': 'Chicken Chow Mein', 'section': 'Noodles', 'price': 550.0},
        {'name': 'Chicken Fried Rice', 'section': 'Rice', 'price': 500.0},
        {'name': 'Chicken Manchurian', 'section': 'Mains', 'price': 650.0},
        {'name': 'Hot & Sour Soup', 'section': 'Soups', 'price': 350.0},
        {'name': 'Chicken Chilli', 'section': 'Mains', 'price': 700.0},
        {'name': 'Beef Chilli Dry', 'section': 'Mains', 'price': 850.0},
        {'name': 'Chicken Shashlik', 'section': 'Mains', 'price': 750.0},
        {'name': 'Vegetable Fried Rice', 'section': 'Rice', 'price': 400.0},
      ],
      'Brew House': [
        {'name': 'Cappuccino', 'section': 'Hot Drinks', 'price': 350.0},
        {'name': 'Latte', 'section': 'Hot Drinks', 'price': 380.0},
        {'name': 'Americano', 'section': 'Hot Drinks', 'price': 300.0},
        {'name': 'Spanish Latte', 'section': 'Hot Drinks', 'price': 450.0},
        {'name': 'Cold Coffee', 'section': 'Cold Drinks', 'price': 450.0},
        {'name': 'Chocolate Shake', 'section': 'Cold Drinks', 'price': 500.0},
        {'name': 'Chicken Club Sandwich', 'section': 'Food', 'price': 650.0},
        {'name': 'Chicken Panini', 'section': 'Food', 'price': 600.0},
        {'name': 'French Fries', 'section': 'Sides', 'price': 350.0},
        {'name': 'Chocolate Cake', 'section': 'Desserts', 'price': 400.0},
      ],
      'Wrap & Roll': [
        {'name': 'Chicken Shawarma', 'section': 'Shawarma', 'price': 300.0},
        {'name': 'Cheese Shawarma', 'section': 'Shawarma', 'price': 380.0},
        {'name': 'Chicken Mayo Roll', 'section': 'Rolls', 'price': 350.0},
        {'name': 'BBQ Chicken Wrap', 'section': 'Wraps', 'price': 450.0},
        {'name': 'Zinger Wrap', 'section': 'Wraps', 'price': 500.0},
        {'name': 'Beef Wrap', 'section': 'Wraps', 'price': 550.0},
        {'name': 'Loaded Fries', 'section': 'Sides', 'price': 450.0},
        {'name': 'Chicken Nuggets', 'section': 'Sides', 'price': 350.0},
      ],
      'Sweet Cravings': [
        {'name': 'Chocolate Cake Slice', 'section': 'Cakes', 'price': 350.0},
        {'name': 'Lotus Cheesecake', 'section': 'Cheesecakes', 'price': 500.0},
        {'name': 'Brownie', 'section': 'Bakes', 'price': 300.0},
        {'name': 'Chocolate Lava Cake', 'section': 'Cakes', 'price': 450.0},
        {'name': 'Waffles', 'section': 'Waffles & Pancakes', 'price': 500.0},
        {'name': 'Pancakes', 'section': 'Waffles & Pancakes', 'price': 450.0},
        {'name': 'Nutella Crepe', 'section': 'Crepes', 'price': 550.0},
        {'name': 'Ice Cream Sundae', 'section': 'Ice Cream', 'price': 400.0},
      ],
      'Desi Dastarkhwan': [
        {'name': 'Chicken Biryani', 'section': 'Rice', 'price': 350.0},
        {'name': 'Beef Biryani', 'section': 'Rice', 'price': 400.0},
        {'name': 'Chicken Pulao', 'section': 'Rice', 'price': 350.0},
        {'name': 'Chicken Karahi', 'section': 'Karahi', 'price': 1100.0},
        {'name': 'Beef Nihari', 'section': 'Curries', 'price': 550.0},
        {'name': 'Chicken Haleem', 'section': 'Curries', 'price': 350.0},
        {'name': 'Daal Chawal', 'section': 'Curries', 'price': 300.0},
        {'name': 'Chicken Tikka', 'section': 'BBQ', 'price': 450.0},
        {'name': 'Naan', 'section': 'Bread', 'price': 50.0},
      ],
    };

    for (final entry in foodData.entries) {
      final restaurantId = restaurantIds[entry.key]!;
      for (final item in entry.value) {
        final food = FoodItemModel(
          restaurantId: restaurantId,
          name: item['name'] as String,
          section: item['section'] as String,
          price: item['price'] as double,
        );
        await db.insert('FoodItems', food.toMap());
      }
    }
  }

  // ---------------- USERS ----------------

  Future<int> registerUser(UserModel user) async {
    final db = await database;
    return await db.insert('Users', user.toMap());
  }

  Future<UserModel?> loginUser(String email, String password) async {
    final db = await database;
    final result = await db.query('Users', where: 'email = ? AND password = ?', whereArgs: [email, password]);
    if (result.isNotEmpty) return UserModel.fromMap(result.first);
    return null;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query('Users', where: 'email = ?', whereArgs: [email]);
    if (result.isNotEmpty) return UserModel.fromMap(result.first);
    return null;
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final result = await db.query('Users', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return UserModel.fromMap(result.first);
    return null;
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update('Users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  // ---------------- RESTAURANTS ----------------

  Future<List<RestaurantModel>> getRestaurants() async {
    final db = await database;
    final result = await db.query('Restaurants');
    return result.map((e) => RestaurantModel.fromMap(e)).toList();
  }

  Future<List<RestaurantModel>> getRestaurantsByCategory(String category) async {
    final db = await database;
    final result = await db.query('Restaurants', where: 'category = ?', whereArgs: [category]);
    return result.map((e) => RestaurantModel.fromMap(e)).toList();
  }

  // ---------------- FOOD ITEMS ----------------

  Future<List<FoodItemModel>> getFoodItemsForRestaurant(int restaurantId) async {
    final db = await database;
    final result = await db.query('FoodItems', where: 'restaurantId = ?', whereArgs: [restaurantId]);
    return result.map((e) => FoodItemModel.fromMap(e)).toList();
  }

  Future<FoodItemModel?> getFoodItemById(int id) async {
    final db = await database;
    final result = await db.query('FoodItems', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return FoodItemModel.fromMap(result.first);
  }

  Future<List<FoodItemModel>> searchFoodItems(String query) async {
    final db = await database;
    final result = await db.query(
      'FoodItems',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    return result.map((e) => FoodItemModel.fromMap(e)).toList();
  }

  /// Same as [searchFoodItems] but also brings back the restaurant name for
  /// each hit, so the Search screen can show the right food image and
  /// actually add the correct item (with its real restaurantId) to cart.
  Future<List<Map<String, dynamic>>> searchFoodItemsWithRestaurant(String query) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT f.*, r.name as restaurantName
      FROM FoodItems f
      JOIN Restaurants r ON f.restaurantId = r.id
      WHERE f.name LIKE ?
      ORDER BY f.name
    ''', ['%$query%']);
  }

  /// Returns one flagship item per restaurant (the first item added for each
  /// restaurant), joined with its restaurant name - used to power the
  /// "Popular Picks" section on Home without needing a separate table.
  Future<List<Map<String, dynamic>>> getPopularItems() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT f.*, r.name as restaurantName
      FROM FoodItems f
      JOIN Restaurants r ON f.restaurantId = r.id
      WHERE f.id IN (SELECT MIN(id) FROM FoodItems GROUP BY restaurantId)
      ORDER BY f.restaurantId
    ''');
  }

  // ---------------- CART ----------------

  Future<List<CartItemModel>> getCartItems(int userId) async {
    final db = await database;
    final result = await db.query('Cart', where: 'userId = ?', whereArgs: [userId]);
    return result.map((e) => CartItemModel.fromMap(e)).toList();
  }

  Future<void> addToCart(CartItemModel item) async {
    final db = await database;
    final existing = await db.query(
      'Cart',
      where: 'userId = ? AND foodItemId = ?',
      whereArgs: [item.userId, item.foodItemId],
    );

    if (existing.isNotEmpty) {
      final existingItem = CartItemModel.fromMap(existing.first);
      await db.update(
        'Cart',
        {'quantity': existingItem.quantity + item.quantity},
        where: 'id = ?',
        whereArgs: [existingItem.id],
      );
    } else {
      await db.insert('Cart', item.toMap());
    }
  }

  Future<void> updateCartQuantity(int cartId, int quantity) async {
    final db = await database;
    if (quantity <= 0) {
      await db.delete('Cart', where: 'id = ?', whereArgs: [cartId]);
    } else {
      await db.update('Cart', {'quantity': quantity}, where: 'id = ?', whereArgs: [cartId]);
    }
  }

  Future<void> removeFromCart(int cartId) async {
    final db = await database;
    await db.delete('Cart', where: 'id = ?', whereArgs: [cartId]);
  }

  Future<void> clearCart(int userId) async {
    final db = await database;
    await db.delete('Cart', where: 'userId = ?', whereArgs: [userId]);
  }

  // ---------------- ORDERS ----------------

  Future<int> createOrder(OrderModel order) async {
    final db = await database;
    return await db.insert('Orders', order.toMap());
  }

  Future<List<OrderModel>> getOrdersForUser(int userId) async {
    final db = await database;
    final result = await db.query('Orders', where: 'userId = ?', whereArgs: [userId], orderBy: 'id DESC');
    return result.map((e) => OrderModel.fromMap(e)).toList();
  }

  // ---------------- FAVORITES ----------------

  Future<List<FavoriteModel>> getFavorites(int userId) async {
    final db = await database;
    final result = await db.query('Favorites', where: 'userId = ?', whereArgs: [userId]);
    return result.map((e) => FavoriteModel.fromMap(e)).toList();
  }

  Future<bool> isFavorite(int userId, int foodItemId) async {
    final db = await database;
    final result = await db.query(
      'Favorites',
      where: 'userId = ? AND foodItemId = ?',
      whereArgs: [userId, foodItemId],
    );
    return result.isNotEmpty;
  }

  Future<void> addFavorite(FavoriteModel favorite) async {
    final db = await database;
    await db.insert('Favorites', favorite.toMap());
  }

  Future<void> removeFavorite(int userId, int foodItemId) async {
    final db = await database;
    await db.delete(
      'Favorites',
      where: 'userId = ? AND foodItemId = ?',
      whereArgs: [userId, foodItemId],
    );
  }
}
