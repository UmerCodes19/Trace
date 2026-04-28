// lib/data/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simple_user_model.dart';
import 'api_service.dart';
import 'notification_service.dart';


final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(apiService: ref.read(apiServiceProvider));
});

class AuthService {
  AuthService({required this.apiService});

  final ApiService apiService;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  SimpleUserModel? _currentUser;
  bool _signedOutExplicitly = false;

  SimpleUserModel? get currentUser => _currentUser;
  User? get firebaseUser => _firebaseAuth.currentUser;

  Future<void> setMockUser(String uid) async {
    final userMap = await apiService.getUser(uid);
    if (userMap != null) {
      _currentUser = SimpleUserModel.fromMap(userMap);
    }
  }

  /// Sign in with Google using Firebase
  Future<SimpleUserModel?> signInWithGoogle({
    bool forceTestUser = false,
  }) async {
    try {
      if (forceTestUser) {
        return null;
      }
      _signedOutExplicitly = false;

      // Clear stale cached account to avoid silent token issues.
      await _googleSignIn.signOut();

      User? firebaseUser;
      GoogleSignInAccount? selectedGoogleUser;
      try {
        final googleUser = await _googleSignIn.signIn();
        selectedGoogleUser = googleUser;
        if (googleUser != null) {
          final googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          final userCredential = await _firebaseAuth.signInWithCredential(
            credential,
          );
          firebaseUser = userCredential.user;
        }
      } catch (e) {
        debugPrint('Primary GoogleSignIn path failed: $e');
        selectedGoogleUser =
            _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      }

      // Fallback path (web-based OAuth flow) for devices where GoogleSignIn plugin fails.
      if (firebaseUser == null) {
        try {
          final provider = GoogleAuthProvider();
          final userCredential = await _firebaseAuth.signInWithProvider(
            provider,
          );
          firebaseUser = userCredential.user;
        } catch (e) {
          debugPrint('Fallback signInWithProvider path failed: $e');
        }
      }

      if (firebaseUser == null) {
        debugPrint('Google sign in was cancelled or failed');
        if (selectedGoogleUser != null) {
          return await _signInLocallyWithGoogleAccount(selectedGoogleUser);
        }
        return null;
      }

      // Create or update user in SQLite
      final user = SimpleUserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        photoURL: firebaseUser.photoURL ?? '',
        isCMSVerified: false,
        department: null,
        contactNumber: null,
        itemsLost: 0,
        itemsFound: 0,
        karmaPoints: 0,
      );

      final syncedUser = await apiService.syncUser(user.toMap());
      _currentUser = SimpleUserModel.fromMap(syncedUser);
      _signedOutExplicitly = false;

      debugPrint('Firebase sign-in successful: ${user.email}');
      
      // Register device for notifications
      await NotificationService().registerDevice(user.uid);
      
      return user;

    } catch (e) {
      debugPrint('Firebase sign-in error: $e');
      return null;
    }
  }

  Future<SimpleUserModel?> _signInLocallyWithGoogleAccount(
    GoogleSignInAccount googleUser,
  ) async {
    final localUser = SimpleUserModel(
      uid: googleUser.email,
      name: googleUser.displayName ?? 'Google User',
      email: googleUser.email,
      photoURL: googleUser.photoUrl ?? '',
      isCMSVerified: false,
    );
    final syncedUser = await apiService.syncUser(localUser.toMap());
    _currentUser = SimpleUserModel.fromMap(syncedUser);
    _signedOutExplicitly = false;
    return _currentUser;
  }

  /// Sign in with email and password (Backup method)
  Future<SimpleUserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('Firebase user is null');

      final syncedUser = await apiService.syncUser(SimpleUserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? email.split('@')[0],
        email: email,
        photoURL: firebaseUser.photoURL ?? '',
      ).toMap());
      _currentUser = SimpleUserModel.fromMap(syncedUser);
      _signedOutExplicitly = false;
      debugPrint('Email sign-in successful: $email');
      
      // Register device for notifications
      await NotificationService().registerDevice(_currentUser!.uid);

      return _currentUser;

    } catch (e) {
      debugPrint('Email sign-in error: $e');
      return null;
    }
  }

  /// Get current user from Firebase or SQLite
  Future<SimpleUserModel?> getCurrentUser() async {
    if (_signedOutExplicitly) {
      return null;
    }

    if (_currentUser != null) {
      return _currentUser;
    }

    // Try to get from Firebase
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      final userMap = await apiService.getUser(firebaseUser.uid);
      if (userMap != null) {
        _currentUser = SimpleUserModel.fromMap(userMap);
        return _currentUser;
      }
      
      final created = SimpleUserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        photoURL: firebaseUser.photoURL ?? '',
      );
      final synced = await apiService.syncUser(created.toMap());
      _currentUser = SimpleUserModel.fromMap(synced);

      // Ensure device is registered for notifications on app start
      await NotificationService().registerDevice(_currentUser!.uid);

      return _currentUser;
    }


    return null;
  }

  Future<SimpleUserModel?> setCurrentUserFromUid(String uid) async {
    final userMap = await apiService.getUser(uid);
    if (userMap == null) return null;
    _currentUser = SimpleUserModel.fromMap(userMap);
    _signedOutExplicitly = false;
    return _currentUser;
  }

  /// Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      final updated = await apiService.syncUser(data);
      if (_currentUser?.uid == uid) {
        _currentUser = SimpleUserModel.fromMap(updated);
      }
      debugPrint('User profile updated');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Sign out from both Firebase and local storage
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      await CookieManager.instance().deleteAllCookies();
      // CMS data is now also in the cloud or cleared session-wise
      _signedOutExplicitly = true;
      _currentUser = null;
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Sign-out error: $e');
      _signedOutExplicitly = true;
      _currentUser = null;
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _currentUser != null;
  }

  /// Get list of all users (for debugging)
  Future<List<SimpleUserModel>> getAllUsers() async {
    final users = await apiService.getAllUsers();
    return users.map((u) => SimpleUserModel.fromMap(u as Map<String, dynamic>)).toList();
  }
}
