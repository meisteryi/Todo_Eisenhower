import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  // Google Sign-In Method
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        // On macOS, try GoogleSignIn with clientId, or fallback to OAuth provider
        try {
          final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
          if (googleUser == null) {
            return null;
          }
          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;
          final OAuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          return await _auth.signInWithCredential(credential);
        } catch (e) {
          debugPrint('GoogleSignIn failed on macOS, trying signInWithProvider: $e');
          final GoogleAuthProvider provider = GoogleAuthProvider();
          return await _auth.signInWithProvider(provider);
        }
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
