// services/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

import '../models/exercise_item.dart';
import '../models/meal_model.dart';
import '../models/session_model.dart';
import '../models/workout.dart';
import '../models/strava_activity.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('muscu_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE exercises(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      reps INTEGER,
      sets INTEGER,
      weight REAL,
      muscleGroup TEXT,
      category TEXT,
      image TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE workouts(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      exerciseId INTEGER,
      sets INTEGER,
      reps INTEGER,
      weight REAL,
      date TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE sessions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      date TEXT,
      exercises TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE meals(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      date TEXT,
      items TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE strava_activities(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      strava_id TEXT UNIQUE,
      name TEXT,
      distance REAL,
      duration INTEGER,
      elevation REAL,
      type TEXT,
      date TEXT
    )
    ''');

    await _insertDefaultExercises(db);
    await _insertTrainingCategoryExercises(db);
  }

  Future<void> _insertDefaultExercises(Database db) async {
    final defaultExercises = [];
    for (var exercise in defaultExercises) {
      final rawName = (exercise['name'] as String).toLowerCase().replaceAll(' ', '_');
      final imageName = '$rawName.png';
      exercise['image'] = [
        'squat.png',
        'tractions.png',
        'devcouche.png',
        'pompes.png',
        'crunchs.png'
      ].contains(imageName) ? imageName : 'default.png';
      await db.insert('exercises', exercise);
    }
  }

  Future<void> _insertTrainingCategoryExercises(Database db) async {
    final categoryExercises = [
      {'name': 'Course continue', 'sets': 1, 'reps': 1, 'weight': 0.0, 'category': 'Course', 'muscleGroup': 'Cardio', 'image': 'endurance_run.png'},
      {'name': 'Montée genoux', 'sets': 3, 'reps': 30, 'weight': 0.0, 'category': 'Course', 'muscleGroup': 'Jambes', 'image': 'high_knees.png'},
    ];

    for (var exercise in categoryExercises) {
      final exists = await db.query(
        'exercises',
        where: 'name = ? AND category = ?',
        whereArgs: [exercise['name'], exercise['category']],
      );
      if (exists.isEmpty) {
        await db.insert('exercises', exercise);
      }
    }
  }

  Future<int> insertStravaActivity(StravaActivity activity) async {
    final db = await instance.database;
    return await db.insert('strava_activities', activity.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<StravaActivity>> getStravaActivities() async {
    final db = await instance.database;
    final result = await db.query('strava_activities');
    return result.map((e) => StravaActivity.fromMap(e)).toList();
  }

  Future<int> insertWorkout(Workout workout) async {
    final db = await instance.database;
    return await db.insert('workouts', workout.toMap());
  }

  Future<int> insertExercise(ExerciseItem exercise) async {
    final db = await instance.database;
    return await db.insert('exercises', exercise.toMap());
  }

  Future<int> insertSession(Session session) async {
    final db = await instance.database;
    return await db.insert('sessions', session.toMap());
  }

  Future<int> insertMeal(Meal meal) async {
    final db = await instance.database;
    return await db.insert('meals', meal.toMap());
  }

  Future<int> updateMeal(Meal meal) async {
    final db = await instance.database;
    return await db.update('meals', meal.toMap(), where: 'id = ?', whereArgs: [meal.id]);
  }

  Future<void> deleteMeal(int id) async {
    final db = await instance.database;
    await db.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSession(Session session) async {
    final db = await instance.database;
    await db.update('sessions', session.toMap(), where: 'id = ?', whereArgs: [session.id]);
  }

  Future<void> deleteSession(int id) async {
    final db = await instance.database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ExerciseItem>> getExercises() async {
    final db = await instance.database;
    final result = await db.query('exercises');
    return result.map((e) => ExerciseItem(
      id: e['id'] as int,
      name: e['name'] as String,
      reps: e['reps'] as int,
      sets: e['sets'] as int,
      weight: (e['weight'] as num).toDouble(),
      muscleGroup: e['muscleGroup'] as String,
      category: e['category'] as String,
      image: e['image'] as String,
    )).toList();
  }

  Future<List<Workout>> getWorkouts() async {
    final db = await instance.database;
    final result = await db.query('workouts');
    return result.map((e) => Workout(
      id: e['id'] as int,
      exerciseId: e['exerciseId'] as int,
      sets: e['sets'] as int,
      reps: e['reps'] as int,
      weight: (e['weight'] as num).toDouble(),
      date: DateTime.parse(e['date'] as String),
    )).toList();
  }

  Future<List<Session>> getSessions() async {
    final db = await instance.database;
    final result = await db.query('sessions');
    return result.map((e) => Session(
      id: e['id'] as int,
      name: e['name'] as String,
      date: DateTime.parse(e['date'] as String),
      exercises: (jsonDecode(e['exercises'] as String) as List)
          .map((ex) => ExerciseItem.fromMap(ex as Map<String, dynamic>)).toList(),
    )).toList();
  }

  Future<List<Meal>> getMeals() async {
    final db = await instance.database;
    final result = await db.query('meals');
    return result.map((e) => Meal.fromMap(e)).toList();
  }

  Future<List<ExerciseItem>> getExercisesByCategoryAndGroup({
    required String category,
    required String muscleGroup,
  }) async {
    final db = await instance.database;
    final result = await db.query(
      'exercises',
      where: 'category = ? AND muscleGroup = ?',
      whereArgs: [category, muscleGroup],
    );

    return result.map((e) => ExerciseItem.fromMap(e)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
