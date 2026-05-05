// lib/providers/app_provider.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_helper.dart';

const _uuid = Uuid();

class AppProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  UserProfile _profile = UserProfile();
  UserProfile get profile => _profile;

  List<Routine> _routines = [];
  List<Routine> get routines => _routines;

  List<WeightEntry> _weightEntries = [];
  List<WeightEntry> get weightEntries => _weightEntries;
  WeightEntry? get latestWeight =>
      _weightEntries.isEmpty ? null : _weightEntries.last;
  // Alias para home_screen
  WeightEntry? get lastWeightEntry => latestWeight;

  int get workoutsThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return _workoutLogs.where((l) => !l.date.isBefore(weekStart)).length;
  }

  List<Meal> _meals = [];
  List<Meal> get meals => _meals;
  List<ShoppingItem> _shoppingList = [];
  List<ShoppingItem> get shoppingList => _shoppingList;

  List<WaterLog> _waterLogs = [];
  int get todayWaterMl {
    final today = DateTime.now();
    return _waterLogs
        .where((w) =>
            w.date.year == today.year &&
            w.date.month == today.month &&
            w.date.day == today.day)
        .fold(0, (s, w) => s + w.amountMl);
  }

  int _waterGoalMl = 2000;
  int get waterGoalMl => _waterGoalMl;

  List<MedicalReminder> _medicalReminders = [];
  List<MedicalReminder> get medicalReminders => _medicalReminders;

  List<ProgressPhoto> _progressPhotos = [];
  List<ProgressPhoto> get progressPhotos => _progressPhotos;

  List<WorkoutLog> _workoutLogs = [];
  List<WorkoutLog> get workoutLogs => _workoutLogs;

  List<BodyMeasurement> _measurements = [];
  List<BodyMeasurement> get measurements => _measurements;

  bool _onboardingDone = false;
  bool get onboardingDone => _onboardingDone;

  int? get dailyCalorieGoal {
    if (_profile.customCalorieGoal != null) return _profile.customCalorieGoal;
    final w = latestWeight?.weight;
    if (w == null) return null;
    return _profile.dailyCalorieGoal(w);
  }

  int? get dailyProteinGoal {
    if (_profile.customProteinGoal != null) return _profile.customProteinGoal;
    final w = latestWeight?.weight;
    if (w == null) return null;
    return _profile.dailyProteinGoal(w);
  }

  int get todayProtein {
    final today = DateTime.now();
    return _meals
        .where((m) => m.dayOfWeek == today.weekday)
        .fold(0, (s, m) => s + m.totalProtein.round());
  }

  // Streak
  int get workoutStreak {
    if (_workoutLogs.isEmpty) return 0;
    final dates = _workoutLogs
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime current = DateTime.now();
    for (final date in dates) {
      final diff = DateTime(current.year, current.month, current.day)
          .difference(date)
          .inDays;
      if (diff <= 1) {
        streak++;
        current = date;
      } else {
        break;
      }
    }
    return streak;
  }

  int get todayCalories {
    final today = DateTime.now();
    return _meals
        .where((m) => m.dayOfWeek == today.weekday)
        .fold(0, (s, m) => s + m.totalCalories);
  }

  List<Routine> get todayRoutines {
    final today = DateTime.now().weekday;
    return _routines.where((r) => r.dayOfWeek == today).toList();
  }

  bool get hasTrainedToday {
    final today = DateTime.now();
    return _workoutLogs.any((l) =>
        l.date.year == today.year &&
        l.date.month == today.month &&
        l.date.day == today.day);
  }

  List<MedicalReminder> get todayReminders {
    final today = DateTime.now();
    return _medicalReminders.where((r) {
      if (!r.isActive) return false;
      if (r.frequency == 'daily') return true;
      if (r.frequency == 'weekdays') return today.weekday <= 5;
      if (r.frequency == 'weekends') return today.weekday >= 6;
      if (r.frequency == 'weekly' || r.frequency == 'custom') {
        if (r.days == null || r.days!.isEmpty) return false;
        final days = r.days!.split(',').map((d) => int.tryParse(d.trim()) ?? 0).toList();
        return days.contains(today.weekday);
      }
      return false;
    }).toList();
  }

  List<Meal> get todayMeals {
    final today = DateTime.now().weekday;
    return _meals.where((m) => m.dayOfWeek == today).toList();
  }

  // ── INIT ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _loadOnboarding();
    await _loadPreferences();
    await _loadProfile();
    await _loadRoutines();
    await _loadWeightEntries();
    await _loadMeals();
    await _loadShoppingList();
    await _loadWaterLogs();
    await _loadMedicalReminders();
    await _loadProgressPhotos();
    await _loadWorkoutLogs();
    await _loadMeasurements();
    notifyListeners();
    _autoBackupIfNeeded();
  }

  // ── PREFERENCES ────────────────────────────────────────────────────────────

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme_mode') ?? 'system';
    _themeMode = theme == 'light'
        ? ThemeMode.light
        : theme == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;
    _waterGoalMl = prefs.getInt('water_goal_ml') ?? 2000;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'theme_mode',
        mode == ThemeMode.light
            ? 'light'
            : mode == ThemeMode.dark
                ? 'dark'
                : 'system');
    notifyListeners();
  }

  Future<void> setWaterGoal(int ml) async {
    _waterGoalMl = ml;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_goal_ml', ml);
    notifyListeners();
  }

  // ── PROFILE ────────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('profile', limit: 1);
      if (maps.isNotEmpty) {
        _profile = UserProfile.fromMap(maps.first);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    try {
      final db = await DatabaseHelper.instance.database;
      final existing = await db.query('profile', limit: 1);
      if (existing.isEmpty) {
        await db.insert('profile', profile.toMap());
      } else {
        await db.update('profile', profile.toMap(), where: 'id = 1');
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
    }
    notifyListeners();
  }

  // ── ROUTINES ───────────────────────────────────────────────────────────────

  Future<void> _loadRoutines() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final routineMaps = await db.query('routines', orderBy: 'day_of_week');
      _routines = [];
      for (final map in routineMaps) {
        final routine = Routine.fromMap(map);
        final exerciseMaps = await db.query(
          'exercises',
          where: 'routine_id = ?',
          whereArgs: [routine.id],
          orderBy: 'order_index',
        );
        routine.exercises = exerciseMaps.map(Exercise.fromMap).toList();
        _routines.add(routine);
      }
    } catch (e) {
      debugPrint('Error loading routines: $e');
    }
  }

  Future<void> addRoutine(Routine routine) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('routines', routine.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      for (int i = 0; i < routine.exercises.length; i++) {
        final ex = routine.exercises[i];
        // Make sure exercise has correct routineId
        final fixedEx = Exercise(
          id: ex.id,
          routineId: routine.id,
          name: ex.name,
          sets: ex.sets,
          reps: ex.reps,
          weight: ex.weight,
          imagePath: ex.imagePath,
          notes: ex.notes,
          orderIndex: i,
        );
        routine.exercises[i] = fixedEx;
        await db.insert('exercises', fixedEx.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      _routines.add(routine);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding routine: $e');
    }
  }

  Future<void> updateRoutine(Routine routine) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update('routines', routine.toMap(),
          where: 'id = ?', whereArgs: [routine.id]);
      await db.delete('exercises',
          where: 'routine_id = ?', whereArgs: [routine.id]);
      for (int i = 0; i < routine.exercises.length; i++) {
        final ex = routine.exercises[i];
        final fixedEx = Exercise(
          id: ex.id,
          routineId: routine.id,
          name: ex.name,
          sets: ex.sets,
          reps: ex.reps,
          weight: ex.weight,
          imagePath: ex.imagePath,
          notes: ex.notes,
          orderIndex: i,
        );
        routine.exercises[i] = fixedEx;
        await db.insert('exercises', fixedEx.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final idx = _routines.indexWhere((r) => r.id == routine.id);
      if (idx != -1) _routines[idx] = routine;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating routine: $e');
    }
  }

  Future<void> deleteRoutine(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('routines', where: 'id = ?', whereArgs: [id]);
      _routines.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting routine: $e');
    }
  }

  Future<void> logWorkout(WorkoutLog log) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('workout_logs', log.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      _workoutLogs.insert(0, log);
      notifyListeners();
    } catch (e) {
      debugPrint('Error logging workout: $e');
    }
  }

  Future<void> _loadWorkoutLogs() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps =
          await db.query('workout_logs', orderBy: 'date DESC', limit: 100);
      _workoutLogs = maps.map(WorkoutLog.fromMap).toList();
    } catch (e) {
      debugPrint('Error loading workout logs: $e');
    }
  }

  // Save per-set performance for active workout

  // Recarga los ejercicios de una rutina desde DB (para obtener lastWeight actualizado)
  Future<void> reloadRoutineExercises(String routineId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final exMaps = await db.query('exercises',
          where: 'routine_id = ?', whereArgs: [routineId], orderBy: 'order_index');
      final exercises = exMaps.map(Exercise.fromMap).toList();
      final idx = _routines.indexWhere((r) => r.id == routineId);
      if (idx >= 0) {
        _routines[idx].exercises
          ..clear()
          ..addAll(exercises);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error reloading exercises: $e');
    }
  }

  Future<void> saveWorkoutSets(String workoutLogId, String exerciseId,
      String exerciseName, List<Map<String, dynamic>> sets) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final today = DateTime.now().toIso8601String().split('T')[0];
      // Delete existing sets for this exercise in this workout
      await db.delete('workout_sets',
          where: 'workout_log_id = ? AND exercise_id = ?',
          whereArgs: [workoutLogId, exerciseId]);
      for (int i = 0; i < sets.length; i++) {
        await db.insert('workout_sets', {
          'id': _uuid.v4(),
          'workout_log_id': workoutLogId,
          'exercise_id': exerciseId,
          'exercise_name': exerciseName,
          'set_number': i + 1,
          'reps': sets[i]['reps'] ?? 0,
          'weight': sets[i]['weight'] ?? 0.0,
          'completed': sets[i]['completed'] == true ? 1 : 0,
          'date': today,
        });
      }
      // Update last_weight and last_reps on exercise
      if (sets.isNotEmpty) {
        final lastWeight = sets.last['weight'] ?? 0.0;
        final lastReps = sets.last['reps'] ?? 0;
        await db.update('exercises',
            {'last_weight': lastWeight, 'last_reps': lastReps, 'last_logged': today},
            where: 'id = ?', whereArgs: [exerciseId]);
        // Update in memory
        for (final r in _routines) {
          for (final ex in r.exercises) {
            if (ex.id == exerciseId) {
              ex.lastWeight = (lastWeight as num).toDouble();
              ex.lastReps = (lastReps as num).toInt();
              ex.lastLogged = today;
            }
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving workout sets: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getExerciseHistory(String exerciseId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.query(
        'workout_sets',
        where: 'exercise_id = ?',
        whereArgs: [exerciseId],
        orderBy: 'date DESC',
        limit: 50,
      );
    } catch (e) {
      debugPrint('Error getting exercise history: $e');
      return [];
    }
  }

  Future<void> _loadOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingDone = prefs.getBool('onboarding_done') ?? false;
  }

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    notifyListeners();
  }

  // ── WEIGHT ─────────────────────────────────────────────────────────────────

  Future<void> _loadWeightEntries() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('weight_entries', orderBy: 'date ASC');
      _weightEntries = maps.map(WeightEntry.fromMap).toList();
    } catch (e) {
      debugPrint('Error loading weight entries: $e');
    }
  }

  Future<void> addWeightEntry(WeightEntry entry) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('weight_entries', entry.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      _weightEntries.add(entry);
      _weightEntries.sort((a, b) => a.date.compareTo(b.date));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding weight entry: $e');
    }
  }

  Future<void> deleteWeightEntry(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('weight_entries', where: 'id = ?', whereArgs: [id]);
      _weightEntries.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting weight entry: $e');
    }
  }

  // ── DIET ───────────────────────────────────────────────────────────────────

  Future<void> _loadMeals() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final mealMaps = await db.query('meals');
      _meals = [];
      for (final map in mealMaps) {
        final meal = Meal.fromMap(map);
        final itemMaps = await db.query(
          'meal_items',
          where: 'meal_id = ?',
          whereArgs: [meal.id],
        );
        meal.items = itemMaps.map(MealItem.fromMap).toList();
        _meals.add(meal);
      }
    } catch (e) {
      debugPrint('Error loading meals: $e');
    }
  }

  Future<void> addMeal(Meal meal) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('meals', meal.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      // Fix meal_id on all items before inserting
      final fixedItems = meal.items.map((item) => MealItem(
            id: item.id,
            mealId: meal.id, // always use the meal's actual id
            foodName: item.foodName,
            quantity: item.quantity,
            unit: item.unit,
            calories: item.calories,
            protein: item.protein,
            carbs: item.carbs,
            fat: item.fat,
          )).toList();
      meal.items = fixedItems;
      for (final item in fixedItems) {
        await db.insert('meal_items', item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      _meals.add(meal);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding meal: $e');
    }
  }

  Future<void> updateMeal(Meal meal) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update('meals', meal.toMap(),
          where: 'id = ?', whereArgs: [meal.id]);
      await db.delete('meal_items',
          where: 'meal_id = ?', whereArgs: [meal.id]);
      final fixedItems = meal.items.map((item) => MealItem(
            id: item.id,
            mealId: meal.id,
            foodName: item.foodName,
            quantity: item.quantity,
            unit: item.unit,
            calories: item.calories,
            protein: item.protein,
            carbs: item.carbs,
            fat: item.fat,
          )).toList();
      meal.items = fixedItems;
      for (final item in fixedItems) {
        await db.insert('meal_items', item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final idx = _meals.indexWhere((m) => m.id == meal.id);
      if (idx != -1) _meals[idx] = meal;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating meal: $e');
    }
  }

  Future<void> deleteMeal(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('meals', where: 'id = ?', whereArgs: [id]);
      _meals.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting meal: $e');
    }
  }

  Future<void> _loadShoppingList() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();
      final weekStart = now
          .subtract(Duration(days: now.weekday - 1))
          .toIso8601String()
          .split('T')[0];
      final maps = await db.query('shopping_list',
          where: 'week_start = ?', whereArgs: [weekStart]);
      _shoppingList = maps.map(ShoppingItem.fromMap).toList();
    } catch (e) {
      debugPrint('Error loading shopping list: $e');
    }
  }

  Future<void> generateShoppingList() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();
      final weekStart = now
          .subtract(Duration(days: now.weekday - 1))
          .toIso8601String()
          .split('T')[0];
      final Map<String, ShoppingItem> itemMap = {};
      for (final meal in _meals.where((m) => m.dayOfWeek != null)) {
        for (final item in meal.items) {
          final key = '${item.foodName}_${item.unit}';
          if (itemMap.containsKey(key)) {
            itemMap[key] = ShoppingItem(
              id: itemMap[key]!.id,
              itemName: item.foodName,
              quantity: itemMap[key]!.quantity + item.quantity,
              unit: item.unit,
              weekStart: weekStart,
            );
          } else {
            itemMap[key] = ShoppingItem(
              itemName: item.foodName,
              quantity: item.quantity,
              unit: item.unit,
              weekStart: weekStart,
            );
          }
        }
      }
      await db.delete('shopping_list',
          where: 'week_start = ?', whereArgs: [weekStart]);
      for (final item in itemMap.values) {
        await db.insert('shopping_list', item.toMap());
      }
      _shoppingList = itemMap.values.toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error generating shopping list: $e');
    }
  }

  Future<void> toggleShoppingItem(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final idx = _shoppingList.indexWhere((i) => i.id == id);
      if (idx == -1) return;
      _shoppingList[idx].isChecked = !_shoppingList[idx].isChecked;
      await db.update('shopping_list',
          {'is_checked': _shoppingList[idx].isChecked ? 1 : 0},
          where: 'id = ?', whereArgs: [id]);
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling shopping item: $e');
    }
  }

  Future<void> addShoppingItem(ShoppingItem item) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('shopping_list', item.toMap());
      _shoppingList.add(item);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding shopping item: $e');
    }
  }

  // ── WATER ──────────────────────────────────────────────────────────────────

  Future<void> _loadWaterLogs() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final today = DateTime.now().toIso8601String().split('T')[0];
      final maps =
          await db.query('water_log', where: 'date = ?', whereArgs: [today]);
      _waterLogs = maps.map(WaterLog.fromMap).toList();
    } catch (e) {
      debugPrint('Error loading water logs: $e');
    }
  }

  Future<void> addWater(int ml) async {
    try {
      final now = DateTime.now();
      final log = WaterLog(
        date: now,
        amountMl: ml,
        time:
            '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      );
      final db = await DatabaseHelper.instance.database;
      await db.insert('water_log', log.toMap());
      _waterLogs.add(log);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding water: $e');
    }
  }

  // ── MEDICAL / REMINDERS ────────────────────────────────────────────────────

  Future<void> _loadMedicalReminders() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('medical_reminders');
      _medicalReminders = maps.map(MedicalReminder.fromMap).toList();
    } catch (e) {
      debugPrint('Error loading reminders: $e');
    }
  }

  Future<void> addMedicalReminder(MedicalReminder reminder) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('medical_reminders', reminder.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      _medicalReminders.add(reminder);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding reminder: $e');
    }
  }

  Future<void> updateMedicalReminder(MedicalReminder reminder) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update('medical_reminders', reminder.toMap(),
          where: 'id = ?', whereArgs: [reminder.id]);
      final idx = _medicalReminders.indexWhere((r) => r.id == reminder.id);
      if (idx != -1) _medicalReminders[idx] = reminder;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating reminder: $e');
    }
  }

  Future<void> deleteMedicalReminder(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('medical_reminders', where: 'id = ?', whereArgs: [id]);
      _medicalReminders.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting reminder: $e');
    }
  }

  // ── PROGRESS PHOTOS ────────────────────────────────────────────────────────

  Future<void> _loadProgressPhotos() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps =
          await db.query('progress_photos', orderBy: 'date DESC');
      _progressPhotos = maps.map(ProgressPhoto.fromMap).toList();
    } catch (e) {
      debugPrint('Error loading progress photos: $e');
    }
  }

  Future<void> addProgressPhoto(ProgressPhoto photo) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('progress_photos', photo.toMap());
      _progressPhotos.insert(0, photo);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding progress photo: $e');
    }
  }


  // ── BORRAR DATOS ───────────────────────────────────────────────────────────

  Future<void> clearMeals() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('meal_items');
      await db.delete('meals');
      await db.delete('shopping_list');
      _meals.clear();
      _shoppingList.clear();
      notifyListeners();
    } catch (e) { debugPrint('Error clearing meals: $e'); }
  }

  Future<void> clearWeightEntries() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('weight_entries');
      _weightEntries.clear();
      notifyListeners();
    } catch (e) { debugPrint('Error clearing weight: $e'); }
  }

  Future<void> clearRoutines() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('workout_sets');
      await db.delete('workout_logs');
      await db.delete('exercises');
      await db.delete('routines');
      _routines.clear();
      _workoutLogs.clear();
      notifyListeners();
    } catch (e) { debugPrint('Error clearing routines: $e'); }
  }

  Future<void> clearReminders() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('medical_reminders');
      await db.delete('medical_logs');
      _medicalReminders.clear();
      notifyListeners();
    } catch (e) { debugPrint('Error clearing reminders: $e'); }
  }

  Future<void> clearAllData() async {
    await clearMeals();
    await clearWeightEntries();
    await clearRoutines();
    await clearReminders();
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('water_log');
      await db.delete('progress_photos');
      await db.delete('body_measurements');
      _progressPhotos.clear();
      _measurements.clear();
      _waterLogs.clear();
      notifyListeners();
    } catch (e) { debugPrint('Error clearing all: $e'); }
  }

  // ── AUTO BACKUP ───────────────────────────────────────────────────────────

  Future<void> _autoBackupIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackup = prefs.getString('last_backup');
      final now = DateTime.now();
      if (lastBackup != null) {
        final last = DateTime.parse(lastBackup);
        if (now.difference(last).inDays < 7) return;
      }
      await exportBackup();
      await prefs.setString('last_backup', now.toIso8601String());
    } catch (e) {
      debugPrint('Auto-backup error: $e');
    }
  }

  Future<String> exportBackup() async {
    final meals = _meals.map((m) => {
      'name': m.name, 'mealType': m.mealType, 'dayOfWeek': m.dayOfWeek,
      'items': m.items.map((i) => {'foodName': i.foodName, 'quantity': i.quantity,
          'unit': i.unit, 'calories': i.calories,
          if (i.protein != null) 'protein': i.protein,
          if (i.carbs != null) 'carbs': i.carbs,
          if (i.fat != null) 'fat': i.fat}).toList(),
    }).toList();
    final routines = _routines.map((r) => {
      'name': r.name, 'dayOfWeek': r.dayOfWeek,
      'exercises': r.exercises.map((e) => {'name': e.name, 'sets': e.sets,
          'reps': e.reps, 'weight': e.weight}).toList(),
    }).toList();
    final weights = _weightEntries.map((w) => {
      'date': w.date.toIso8601String(), 'weight': w.weight,
      if (w.fatPercentage != null) 'fatPercentage': w.fatPercentage,
    }).toList();
    final backup = {'meals': meals, 'routines': routines, 'weights': weights,
        'exportedAt': DateTime.now().toIso8601String()};
    final json = const JsonEncoder.withIndent('  ').convert(backup);
    // Save to shared prefs as emergency backup (accessible even without file permissions)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_backup', json);
    return json;
  }

  Future<String?> getEmergencyBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('emergency_backup');
  }

  // ── BODY MEASUREMENTS ─────────────────────────────────────────────────────

  Future<void> _loadMeasurements() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('body_measurements', orderBy: 'date DESC');
      _measurements = maps.map(BodyMeasurement.fromMap).toList();
    } catch (e) {
      debugPrint('Error loading measurements: $e');
    }
  }

  Future<void> addMeasurement(BodyMeasurement m) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('body_measurements', m.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      _measurements.insert(0, m);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding measurement: $e');
    }
  }

  Future<void> deleteMeasurement(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('body_measurements', where: 'id = ?', whereArgs: [id]);
      _measurements.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting measurement: $e');
    }
  }

  Future<void> deleteProgressPhoto(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('progress_photos', where: 'id = ?', whereArgs: [id]);
      _progressPhotos.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting progress photo: $e');
    }
  }
}