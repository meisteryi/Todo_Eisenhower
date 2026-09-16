import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../models/category_model.dart';
import '../models/routine_model.dart';
import '../models/todo_model.dart';
import '../models/workout_model.dart';
import 'database_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  FirebaseFirestore? get _firestore {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance;
  }

  final List<StreamSubscription> _subscriptions = [];

  // Initialize real-time sync listening to Auth changes
  void initializeSync(
    Function() onDataChanged, {
    Function(Map<String, dynamic>)? onSettingsChanged,
  }) {
    if (Firebase.apps.isEmpty) return;

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        startSync(user.uid, onDataChanged, onSettingsChanged: onSettingsChanged);
      } else {
        _cancelSubscriptions();
      }
    });
  }

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  // Start real-time sync with Cloud Firestore
  Future<void> startSync(
    String userId,
    Function() onDataChanged, {
    Function(Map<String, dynamic>)? onSettingsChanged,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;

    _cancelSubscriptions();
    final db = DatabaseHelper.instance;

    // 1. Initial Bi-directional Sync
    try {
      final userDoc = firestore.collection('users').doc(userId);

      // --- A. TODOS ---
      final localTodos = await db.fetchAllTodosAll();
      final todosCol = userDoc.collection('todos');
      for (final todo in localTodos) {
        if (todo.id != null) {
          await todosCol.doc('${todo.id}').set(todo.toMap(), SetOptions(merge: true));
        }
      }
      final remoteTodos = await todosCol.get();
      for (final doc in remoteTodos.docs) {
        await db.upsertTodoRaw(doc.data());
      }

      // --- B. CATEGORIES ---
      final localCategories = await db.fetchCategories();
      final categoriesCol = userDoc.collection('categories');
      for (final cat in localCategories) {
        if (cat.id != null) {
          await categoriesCol.doc('${cat.id}').set(cat.toMap(), SetOptions(merge: true));
        }
      }
      final remoteCategories = await categoriesCol.get();
      for (final doc in remoteCategories.docs) {
        await db.upsertCategoryRaw(doc.data());
      }

      // --- C. ROUTINES ---
      final localRoutines = await db.fetchRoutines();
      final routinesCol = userDoc.collection('routines');
      for (final r in localRoutines) {
        if (r.id != null) {
          await routinesCol.doc('${r.id}').set(r.toMap(), SetOptions(merge: true));
        }
      }
      final remoteRoutines = await routinesCol.get();
      for (final doc in remoteRoutines.docs) {
        await db.upsertRoutineRaw(doc.data());
      }

      // --- D. WORKOUTS ---
      final localWorkouts = await db.fetchWorkouts();
      final workoutsCol = userDoc.collection('workouts');
      for (final w in localWorkouts) {
        if (w.id != null) {
          await workoutsCol.doc('${w.id}').set(w.toMap(), SetOptions(merge: true));
        }
      }
      final remoteWorkouts = await workoutsCol.get();
      for (final doc in remoteWorkouts.docs) {
        await db.upsertWorkoutRaw(doc.data());
      }

      // --- E. WORKOUT LOGS ---
      final localLogs = await db.fetchAllWorkoutLogs();
      final logsCol = userDoc.collection('workout_logs');
      for (final l in localLogs) {
        if (l.id != null) {
          await logsCol.doc('${l.id}').set(l.toMap(), SetOptions(merge: true));
        }
      }
      final remoteLogs = await logsCol.get();
      for (final doc in remoteLogs.docs) {
        await db.upsertWorkoutLogRaw(doc.data());
      }

      // --- F. WORKOUT PRESETS ---
      final localPresets = await db.fetchWorkoutPresets();
      final presetsCol = userDoc.collection('workout_presets');
      for (final p in localPresets) {
        if (p.id != null) {
          await presetsCol.doc('${p.id}').set(p.toMap(), SetOptions(merge: true));
        }
      }
      final remotePresets = await presetsCol.get();
      for (final doc in remotePresets.docs) {
        await db.upsertWorkoutPresetRaw(doc.data());
      }

      // --- G. SETTINGS ---
      final settingsDoc = await userDoc.collection('settings').doc('preferences').get();
      if (settingsDoc.exists && settingsDoc.data() != null) {
        onSettingsChanged?.call(settingsDoc.data()!);
      }

      onDataChanged();
    } catch (e) {
      debugPrint('Cloud Initial Sync Warning: $e');
    }

    // 2. Real-time Listeners for all entities
    try {
      final userDoc = firestore.collection('users').doc(userId);

      // Listen Todos
      _subscriptions.add(
        userDoc.collection('todos').snapshots().listen((snapshot) async {
          for (final change in snapshot.docChanges) {
            final data = change.doc.data();
            if (data == null) continue;
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              await db.upsertTodoRaw(data);
            } else if (change.type == DocumentChangeType.removed) {
              final id = data['id'] as int?;
              if (id != null) await db.deletePermanently(id);
            }
          }
          onDataChanged();
        }),
      );

      // Listen Categories
      _subscriptions.add(
        userDoc.collection('categories').snapshots().listen((snapshot) async {
          for (final change in snapshot.docChanges) {
            final data = change.doc.data();
            if (data == null) continue;
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              await db.upsertCategoryRaw(data);
            } else if (change.type == DocumentChangeType.removed) {
              final id = data['id'] as int?;
              if (id != null) await db.deleteCategory(id);
            }
          }
          onDataChanged();
        }),
      );

      // Listen Routines
      _subscriptions.add(
        userDoc.collection('routines').snapshots().listen((snapshot) async {
          for (final change in snapshot.docChanges) {
            final data = change.doc.data();
            if (data == null) continue;
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              await db.upsertRoutineRaw(data);
            } else if (change.type == DocumentChangeType.removed) {
              final id = data['id'] as int?;
              if (id != null) await db.deleteRoutine(id);
            }
          }
          onDataChanged();
        }),
      );

      // Listen Workouts
      _subscriptions.add(
        userDoc.collection('workouts').snapshots().listen((snapshot) async {
          for (final change in snapshot.docChanges) {
            final data = change.doc.data();
            if (data == null) continue;
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              await db.upsertWorkoutRaw(data);
            } else if (change.type == DocumentChangeType.removed) {
              final id = data['id'] as int?;
              if (id != null) await db.deleteWorkout(id);
            }
          }
          onDataChanged();
        }),
      );

      // Listen Workout Logs
      _subscriptions.add(
        userDoc.collection('workout_logs').snapshots().listen((snapshot) async {
          for (final change in snapshot.docChanges) {
            final data = change.doc.data();
            if (data == null) continue;
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              await db.upsertWorkoutLogRaw(data);
            }
          }
          onDataChanged();
        }),
      );

      // Listen Workout Presets
      _subscriptions.add(
        userDoc.collection('workout_presets').snapshots().listen((snapshot) async {
          for (final change in snapshot.docChanges) {
            final data = change.doc.data();
            if (data == null) continue;
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              await db.upsertWorkoutPresetRaw(data);
            } else if (change.type == DocumentChangeType.removed) {
              final id = data['id'] as int?;
              if (id != null) await db.deleteWorkoutPreset(id);
            }
          }
          onDataChanged();
        }),
      );

      // Listen Settings
      _subscriptions.add(
        userDoc.collection('settings').doc('preferences').snapshots().listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            onSettingsChanged?.call(snapshot.data()!);
          }
        }),
      );
    } catch (e) {
      debugPrint('Cloud Real-time Subscriptions Warning: $e');
    }
  }

  // --- Push and Remove Helpers ---

  Future<void> pushTodo(Todo todo) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || todo.id == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('todos')
          .doc('${todo.id}')
          .set(todo.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Cloud Push Todo Error: $e');
    }
  }

  Future<void> removeTodo(int todoId) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('todos')
          .doc('$todoId')
          .delete();
    } catch (e) {
      debugPrint('Cloud Remove Todo Error: $e');
    }
  }

  Future<void> pushCategory(Category cat) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || cat.id == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc('${cat.id}')
          .set(cat.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Cloud Push Category Error: $e');
    }
  }

  Future<void> removeCategory(int catId) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc('$catId')
          .delete();
    } catch (e) {
      debugPrint('Cloud Remove Category Error: $e');
    }
  }

  Future<void> pushRoutine(Routine r) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || r.id == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('routines')
          .doc('${r.id}')
          .set(r.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Cloud Push Routine Error: $e');
    }
  }

  Future<void> removeRoutine(int rId) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('routines')
          .doc('$rId')
          .delete();
    } catch (e) {
      debugPrint('Cloud Remove Routine Error: $e');
    }
  }

  Future<void> pushWorkout(Workout w) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || w.id == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .doc('${w.id}')
          .set(w.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Cloud Push Workout Error: $e');
    }
  }

  Future<void> removeWorkout(int wId) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .doc('$wId')
          .delete();
    } catch (e) {
      debugPrint('Cloud Remove Workout Error: $e');
    }
  }

  Future<void> pushWorkoutLog(WorkoutLog log) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || log.id == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_logs')
          .doc('${log.id}')
          .set(log.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Cloud Push Workout Log Error: $e');
    }
  }

  Future<void> pushWorkoutPreset(WorkoutPreset p) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || p.id == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_presets')
          .doc('${p.id}')
          .set(p.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Cloud Push Preset Error: $e');
    }
  }

  Future<void> removeWorkoutPreset(int pId) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_presets')
          .doc('$pId')
          .delete();
    } catch (e) {
      debugPrint('Cloud Remove Preset Error: $e');
    }
  }

  Future<void> pushSettings(Map<String, dynamic> settings) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('preferences')
          .set(settings, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Cloud Push Settings Error: $e');
    }
  }
}

