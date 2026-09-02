import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/todo_model.dart';
import 'database_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  FirebaseFirestore? get _firestore {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance;
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _todosSubscription;

  // Initialize real-time sync listening to Auth changes
  void initializeSync(Function() onDataChanged) {
    if (Firebase.apps.isEmpty) return;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        startSync(user.uid, onDataChanged);
      } else {
        _todosSubscription?.cancel();
        _todosSubscription = null;
      }
    });
  }

  // Start real-time sync with Cloud Firestore
  Future<void> startSync(String userId, Function() onDataChanged) async {
    final firestore = _firestore;
    if (firestore == null) return;

    await _todosSubscription?.cancel();

    // 1. Initial Sync: Merge Local SQLite with Remote Cloud Firestore
    try {
      final db = DatabaseHelper.instance;
      final localTodos = await db.fetchAllActive();

      final remoteSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('todos')
          .get();

      // Push all local todos to Cloud Firestore
      for (final todo in localTodos) {
        if (todo.id != null) {
          await firestore
              .collection('users')
              .doc(userId)
              .collection('todos')
              .doc('${todo.id}')
              .set(todo.toMap(), SetOptions(merge: true));
        }
      }

      // Save any remote-only todos into local SQLite
      for (final doc in remoteSnapshot.docs) {
        final data = doc.data();
        final remoteTodo = Todo.fromMap(data);
        if (remoteTodo.id != null) {
          final existsLocally = localTodos.any((t) => t.id == remoteTodo.id);
          if (!existsLocally) {
            await db.insert(remoteTodo);
          } else {
            await db.update(remoteTodo);
          }
        }
      }

      onDataChanged();
    } catch (e) {
      debugPrint('Cloud Sync Initial Fetch Warning: $e');
    }

    // 2. Listen to real-time Firestore updates from other devices (iOS / Android / macOS / Web)
    _todosSubscription = firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .snapshots()
        .listen((snapshot) async {
      final db = DatabaseHelper.instance;
      bool changeOccurred = false;

      for (final change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;

        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {
          final todo = Todo.fromMap(data);
          if (todo.id != null) {
            final localList = await db.fetchAllActive();
            final exists = localList.any((t) => t.id == todo.id);
            if (!exists) {
              await db.insert(todo);
            } else {
              await db.update(todo);
            }
            changeOccurred = true;
          }
        } else if (change.type == DocumentChangeType.removed) {
          final id = data['id'] as int?;
          if (id != null) {
            await db.deletePermanently(id);
            changeOccurred = true;
          }
        }
      }

      if (changeOccurred) {
        onDataChanged();
      }
    });
  }

  // Push single todo to Cloud Firestore
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

  // Remove single todo from Cloud Firestore
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
}
