// lib/services/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fittracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path,
        version: 6, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try { await db.execute('ALTER TABLE weight_entries ADD COLUMN image_path TEXT'); } catch (_) {}
    }
    if (oldVersion < 3) {
      try { await db.execute('ALTER TABLE exercises ADD COLUMN last_weight REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE exercises ADD COLUMN last_logged TEXT'); } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS workout_sets (
            id TEXT PRIMARY KEY,
            workout_log_id TEXT NOT NULL,
            exercise_id TEXT NOT NULL,
            exercise_name TEXT NOT NULL,
            set_number INTEGER NOT NULL,
            reps INTEGER NOT NULL,
            weight REAL NOT NULL,
            completed INTEGER NOT NULL DEFAULT 0,
            date TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS body_measurements (
            id TEXT PRIMARY KEY,
            date TEXT NOT NULL,
            waist REAL, chest REAL, hips REAL,
            bicep REAL, thigh REAL, neck REAL,
            notes TEXT
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try { await db.execute('ALTER TABLE exercises ADD COLUMN last_reps INTEGER'); } catch (_) {}
    }
    if (oldVersion < 6) {
      try { await db.execute('ALTER TABLE profile ADD COLUMN custom_calorie_goal INTEGER'); } catch (_) {}
      try { await db.execute('ALTER TABLE profile ADD COLUMN custom_protein_goal INTEGER'); } catch (_) {}
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE routines (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        day_of_week INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        routine_id TEXT NOT NULL,
        name TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL NOT NULL,
        image_path TEXT,
        notes TEXT,
        order_index INTEGER NOT NULL,
        last_weight REAL,
        last_reps INTEGER,
        last_logged TEXT,
        FOREIGN KEY (routine_id) REFERENCES routines(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_logs (
        id TEXT PRIMARY KEY,
        routine_id TEXT NOT NULL,
        date TEXT NOT NULL,
        duration_minutes INTEGER,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_sets (
        id TEXT PRIMARY KEY,
        workout_log_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE weight_entries (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        weight REAL NOT NULL,
        fat_percentage REAL,
        muscle_percentage REAL,
        bone_percentage REAL,
        water_percentage REAL,
        notes TEXT,
        image_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE meals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        day_of_week INTEGER,
        is_template INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_items (
        id TEXT PRIMARY KEY,
        meal_id TEXT NOT NULL,
        food_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein REAL,
        carbs REAL,
        fat REAL,
        FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE shopping_list (
        id TEXT PRIMARY KEY,
        item_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        is_checked INTEGER NOT NULL DEFAULT 0,
        week_start TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE water_log (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        amount_ml INTEGER NOT NULL,
        time TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE medical_reminders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        frequency TEXT NOT NULL,
        time TEXT NOT NULL,
        days TEXT,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        notification_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE medical_logs (
        id TEXT PRIMARY KEY,
        reminder_id TEXT NOT NULL,
        date TEXT NOT NULL,
        taken INTEGER NOT NULL DEFAULT 1,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE progress_photos (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        image_path TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE body_measurements (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        waist REAL, chest REAL, hips REAL,
        bicep REAL, thigh REAL, neck REAL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY,
        name TEXT,
        age INTEGER,
        height REAL,
        gender TEXT,
        goal TEXT,
        activity_level TEXT,
        custom_calorie_goal INTEGER,
        custom_protein_goal INTEGER
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}