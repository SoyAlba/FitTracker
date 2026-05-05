// lib/models/models.dart
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ── ROUTINE ──────────────────────────────────────────────────────────────────

class Routine {
  final String id;
  final String name;
  final int dayOfWeek; // 1=Mon...7=Sun
  final DateTime createdAt;
  List<Exercise> exercises;

  Routine({
    String? id,
    required this.name,
    required this.dayOfWeek,
    DateTime? createdAt,
    this.exercises = const [],
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'day_of_week': dayOfWeek,
        'created_at': createdAt.toIso8601String(),
      };

  factory Routine.fromMap(Map<String, dynamic> map) => Routine(
        id: map['id'],
        name: map['name'],
        dayOfWeek: map['day_of_week'],
        createdAt: DateTime.parse(map['created_at']),
      );

  Routine copyWith({String? name, int? dayOfWeek, List<Exercise>? exercises}) =>
      Routine(
          id: id,
          name: name ?? this.name,
          dayOfWeek: dayOfWeek ?? this.dayOfWeek,
          createdAt: createdAt,
          exercises: exercises ?? this.exercises);
}

class Exercise {
  final String id;
  final String routineId;
  String name;
  int sets;
  int reps;
  double weight;
  String? imagePath;
  String? notes;
  int orderIndex;
  double? lastWeight;
  int? lastReps;
  String? lastLogged;

  Exercise({
    String? id,
    required this.routineId,
    required this.name,
    this.sets = 3,
    this.reps = 10,
    this.weight = 0,
    this.imagePath,
    this.notes,
    this.orderIndex = 0,
    this.lastWeight,
    this.lastReps,
    this.lastLogged,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'routine_id': routineId,
        'name': name,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'image_path': imagePath,
        'notes': notes,
        'order_index': orderIndex,
        'last_weight': lastWeight,
        'last_reps': lastReps,
        'last_logged': lastLogged,
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'],
        routineId: map['routine_id'],
        name: map['name'],
        sets: map['sets'],
        reps: map['reps'],
        weight: (map['weight'] as num).toDouble(),
        imagePath: map['image_path'],
        notes: map['notes'],
        orderIndex: map['order_index'],
        lastWeight: map['last_weight'] != null ? (map['last_weight'] as num).toDouble() : null,
        lastReps: map['last_reps'] != null ? (map['last_reps'] as num).toInt() : null,
        lastLogged: map['last_logged'],
      );

  Exercise copyWith({
    String? name,
    int? sets,
    int? reps,
    double? weight,
    String? imagePath,
    String? notes,
  }) =>
      Exercise(
        id: id,
        routineId: routineId,
        name: name ?? this.name,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        imagePath: imagePath ?? this.imagePath,
        notes: notes ?? this.notes,
        orderIndex: orderIndex,
      );
}

class WorkoutLog {
  final String id;
  final String routineId;
  final DateTime date;
  int? durationMinutes;
  String? notes;

  WorkoutLog({
    String? id,
    required this.routineId,
    required this.date,
    this.durationMinutes,
    this.notes,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'routine_id': routineId,
        'date': date.toIso8601String(),
        'duration_minutes': durationMinutes,
        'notes': notes,
      };

  factory WorkoutLog.fromMap(Map<String, dynamic> map) => WorkoutLog(
        id: map['id'],
        routineId: map['routine_id'],
        date: DateTime.parse(map['date']),
        durationMinutes: map['duration_minutes'],
        notes: map['notes'],
      );
}

// ── WEIGHT ───────────────────────────────────────────────────────────────────

class WeightEntry {
  final String id;
  final DateTime date;
  final double weight;
  double? fatPercentage;
  double? musclePercentage;
  double? bonePercentage;
  double? waterPercentage;
  String? notes;
  String? imagePath;

  WeightEntry({
    String? id,
    required this.date,
    required this.weight,
    this.fatPercentage,
    this.musclePercentage,
    this.bonePercentage,
    this.waterPercentage,
    this.notes,
    this.imagePath,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'weight': weight,
        'fat_percentage': fatPercentage,
        'muscle_percentage': musclePercentage,
        'bone_percentage': bonePercentage,
        'water_percentage': waterPercentage,
        'notes': notes,
        'image_path': imagePath,
      };

  factory WeightEntry.fromMap(Map<String, dynamic> map) => WeightEntry(
        id: map['id'],
        date: DateTime.parse(map['date']),
        weight: (map['weight'] as num).toDouble(),
        fatPercentage: map['fat_percentage'] != null
            ? (map['fat_percentage'] as num).toDouble()
            : null,
        musclePercentage: map['muscle_percentage'] != null
            ? (map['muscle_percentage'] as num).toDouble()
            : null,
        bonePercentage: map['bone_percentage'] != null
            ? (map['bone_percentage'] as num).toDouble()
            : null,
        waterPercentage: map['water_percentage'] != null
            ? (map['water_percentage'] as num).toDouble()
            : null,
        notes: map['notes'],
        imagePath: map['image_path'],
      );
}

// ── DIET ─────────────────────────────────────────────────────────────────────

class Meal {
  final String id;
  final String name;
  final String mealType; // breakfast, lunch, dinner, snack
  final int? dayOfWeek;
  final bool isTemplate;
  List<MealItem> items;

  Meal({
    String? id,
    required this.name,
    required this.mealType,
    this.dayOfWeek,
    this.isTemplate = false,
    this.items = const [],
  }) : id = id ?? _uuid.v4();

  int get totalCalories => items.fold(0, (s, i) => s + i.calories);
  double get totalProtein => items.fold(0.0, (s, i) => s + (i.protein ?? 0));
  double get totalCarbs => items.fold(0.0, (s, i) => s + (i.carbs ?? 0));
  double get totalFat => items.fold(0.0, (s, i) => s + (i.fat ?? 0));

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'meal_type': mealType,
        'day_of_week': dayOfWeek,
        'is_template': isTemplate ? 1 : 0,
      };

  factory Meal.fromMap(Map<String, dynamic> map) => Meal(
        id: map['id'],
        name: map['name'],
        mealType: map['meal_type'],
        dayOfWeek: map['day_of_week'],
        isTemplate: map['is_template'] == 1,
      );
}

class MealItem {
  final String id;
  final String mealId;
  final String foodName;
  final double quantity;
  final String unit;
  final int calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  MealItem({
    String? id,
    required this.mealId,
    required this.foodName,
    required this.quantity,
    required this.unit,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'meal_id': mealId,
        'food_name': foodName,
        'quantity': quantity,
        'unit': unit,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  factory MealItem.fromMap(Map<String, dynamic> map) => MealItem(
        id: map['id'],
        mealId: map['meal_id'],
        foodName: map['food_name'],
        quantity: (map['quantity'] as num).toDouble(),
        unit: map['unit'],
        calories: map['calories'],
        protein:
            map['protein'] != null ? (map['protein'] as num).toDouble() : null,
        carbs: map['carbs'] != null ? (map['carbs'] as num).toDouble() : null,
        fat: map['fat'] != null ? (map['fat'] as num).toDouble() : null,
      );
}

class ShoppingItem {
  final String id;
  final String itemName;
  final double quantity;
  final String unit;
  bool isChecked;
  final String weekStart;

  ShoppingItem({
    String? id,
    required this.itemName,
    required this.quantity,
    required this.unit,
    this.isChecked = false,
    required this.weekStart,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'item_name': itemName,
        'quantity': quantity,
        'unit': unit,
        'is_checked': isChecked ? 1 : 0,
        'week_start': weekStart,
      };

  factory ShoppingItem.fromMap(Map<String, dynamic> map) => ShoppingItem(
        id: map['id'],
        itemName: map['item_name'],
        quantity: (map['quantity'] as num).toDouble(),
        unit: map['unit'],
        isChecked: map['is_checked'] == 1,
        weekStart: map['week_start'],
      );
}

// ── WATER ────────────────────────────────────────────────────────────────────

class WaterLog {
  final String id;
  final DateTime date;
  final int amountMl;
  final String time;

  WaterLog({
    String? id,
    required this.date,
    required this.amountMl,
    required this.time,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String().split('T')[0],
        'amount_ml': amountMl,
        'time': time,
      };

  factory WaterLog.fromMap(Map<String, dynamic> map) => WaterLog(
        id: map['id'],
        date: DateTime.parse(map['date']),
        amountMl: map['amount_ml'],
        time: map['time'],
      );
}

// ── MEDICAL ──────────────────────────────────────────────────────────────────

class MedicalReminder {
  final String id;
  final String name;
  final String type; // injection, supplement, medication
  final String frequency; // daily, weekly, custom
  final String time;
  final String? days; // JSON list of day numbers
  final String? notes;
  bool isActive;
  int? notificationId;

  MedicalReminder({
    String? id,
    required this.name,
    required this.type,
    required this.frequency,
    required this.time,
    this.days,
    this.notes,
    this.isActive = true,
    this.notificationId,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'frequency': frequency,
        'time': time,
        'days': days,
        'notes': notes,
        'is_active': isActive ? 1 : 0,
        'notification_id': notificationId,
      };

  factory MedicalReminder.fromMap(Map<String, dynamic> map) => MedicalReminder(
        id: map['id'],
        name: map['name'],
        type: map['type'],
        frequency: map['frequency'],
        time: map['time'],
        days: map['days'],
        notes: map['notes'],
        isActive: map['is_active'] == 1,
        notificationId: map['notification_id'],
      );
}

// ── PROGRESS PHOTO ────────────────────────────────────────────────────────────

class ProgressPhoto {
  final String id;
  final DateTime date;
  final String imagePath;
  final String? notes;

  ProgressPhoto({
    String? id,
    required this.date,
    required this.imagePath,
    this.notes,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'image_path': imagePath,
        'notes': notes,
      };

  factory ProgressPhoto.fromMap(Map<String, dynamic> map) => ProgressPhoto(
        id: map['id'],
        date: DateTime.parse(map['date']),
        imagePath: map['image_path'],
        notes: map['notes'],
      );
}

// ── PROFILE ──────────────────────────────────────────────────────────────────

class UserProfile {
  String? name;
  int? age;
  double? height; // cm
  String? gender;
  String? goal;
  String? activityLevel;
  int? customCalorieGoal;   // manual override
  int? customProteinGoal;   // manual override

  UserProfile({
    this.name,
    this.age,
    this.height,
    this.gender,
    this.goal,
    this.activityLevel,
    this.customCalorieGoal,
    this.customProteinGoal,
  });

  double? bmi(double weight) {
    if (height == null || height == 0) return null;
    final h = height! / 100;
    return weight / (h * h);
  }

  String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Bajo peso';
    if (bmi < 25) return 'Peso normal';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  /// Harris-Benedict + activity factor + goal adjustment
  int? dailyCalorieGoal(double weight) {
    if (height == null || age == null) return null;
    double bmr;
    if ((gender ?? 'female') == 'male') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height!) - (5.677 * age!);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height!) - (4.330 * age!);
    }
    final factor = switch (activityLevel ?? 'moderate') {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'active' => 1.725,
      'very_active' => 1.9,
      _ => 1.55,
    };
    final maintenance = bmr * factor;
    return switch (goal ?? 'maintain') {
      'lose' => (maintenance - 400).round(),
      'gain' => (maintenance + 300).round(),
      _ => maintenance.round(),
    };
  }

  int? dailyProteinGoal(double weight) {
    return switch (goal ?? 'maintain') {
      'gain' => (weight * 2.0).round(),
      'lose' => (weight * 1.8).round(),
      _ => (weight * 1.6).round(),
    };
  }

  Map<String, dynamic> toMap() => {
        'id': 1,
        'name': name,
        'age': age,
        'height': height,
        'gender': gender,
        'goal': goal,
        'activity_level': activityLevel,
        'custom_calorie_goal': customCalorieGoal,
        'custom_protein_goal': customProteinGoal,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        name: map['name'],
        age: map['age'],
        height: map['height'] != null ? (map['height'] as num).toDouble() : null,
        gender: map['gender'],
        goal: map['goal'],
        activityLevel: map['activity_level'],
        customCalorieGoal: map['custom_calorie_goal'],
        customProteinGoal: map['custom_protein_goal'],
      );
}

// ── BODY MEASUREMENT ─────────────────────────────────────────────────────────

class BodyMeasurement {
  final String id;
  final DateTime date;
  final double? waist;   // cm
  final double? chest;
  final double? hips;
  final double? bicep;
  final double? thigh;
  final double? neck;
  final String? notes;

  BodyMeasurement({
    String? id,
    required this.date,
    this.waist, this.chest, this.hips,
    this.bicep, this.thigh, this.neck,
    this.notes,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'waist': waist, 'chest': chest, 'hips': hips,
    'bicep': bicep, 'thigh': thigh, 'neck': neck,
    'notes': notes,
  };

  factory BodyMeasurement.fromMap(Map<String, dynamic> map) => BodyMeasurement(
    id: map['id'],
    date: DateTime.parse(map['date']),
    waist: map['waist'] != null ? (map['waist'] as num).toDouble() : null,
    chest: map['chest'] != null ? (map['chest'] as num).toDouble() : null,
    hips: map['hips'] != null ? (map['hips'] as num).toDouble() : null,
    bicep: map['bicep'] != null ? (map['bicep'] as num).toDouble() : null,
    thigh: map['thigh'] != null ? (map['thigh'] as num).toDouble() : null,
    neck: map['neck'] != null ? (map['neck'] as num).toDouble() : null,
    notes: map['notes'],
  );
}