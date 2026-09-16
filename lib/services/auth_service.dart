import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _macClientId =
      '146283361860-tu0m36ndonmjp0k2ighm74gd1d6oe2de.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS)
        ? _macClientId
        : null,
  );

  // Auth State Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current Logged-in User
  User? get currentUser => _auth.currentUser;

  // Generates a secure random nonce string
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // SHA256 digest of string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Google Sign-In Method
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          // User canceled the sign-in flow
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  // Apple Sign-In Method (Required for App Store Review)
  Future<UserCredential?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
      final AuthCredential credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      // Apple only returns name on the FIRST sign-in
      if (user != null) {
        final String? givenName = appleCredential.givenName;
        final String? familyName = appleCredential.familyName;
        if (givenName != null || familyName != null) {
          final fullName = [familyName, givenName]
              .where((s) => s != null && s.trim().isNotEmpty)
              .join(' ')
              .trim();
          if (fullName.isNotEmpty) {
            await user.updateDisplayName(fullName);
            await user.reload();
          }
        }
      }

      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        // User canceled the Apple Sign-In dialog
        debugPrint('Apple Sign-In was canceled by user.');
        return null;
      }
      debugPrint('Apple Sign-In Authorization Error: $e');
      rethrow;
    } catch (e) {
      debugPrint('Apple Sign-In Error: $e');
      rethrow;
    }
  }

  // Account Deletion Method (Required for App Store Guideline 5.1.1(v))
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final uid = user.uid;

        // 1. Delete user cloud data from Firestore
        try {
          final firestore = FirebaseFirestore.instance;
          final userDoc = firestore.collection('users').doc(uid);
          final collections = [
            'todos',
            'categories',
            'routines',
            'workouts',
            'workout_logs',
            'workout_presets',
            'settings',
          ];

          for (final col in collections) {
            final snapshot = await userDoc.collection(col).get();
            for (final doc in snapshot.docs) {
              await doc.reference.delete();
            }
          }
          await userDoc.delete();
        } catch (e) {
          debugPrint('Firestore Data Deletion Error: $e');
        }

        // 2. Delete Auth user from Firebase
        await user.delete();

        // 3. Sign out of local SDKs
        if (!kIsWeb) {
          await _googleSignIn.signOut();
        }
      }
    } catch (e) {
      debugPrint('Account Deletion Error: $e');
      rethrow;
    }
  }

  // Sign Out Method
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign-Out Error: $e');
      rethrow;
    }
  }
}
