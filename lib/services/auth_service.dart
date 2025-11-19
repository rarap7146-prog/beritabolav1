import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'onesignal_service.dart';
import 'analytics_service.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OneSignalService _oneSignal = OneSignalService();
  final AnalyticsService _analytics = AnalyticsService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register with Email & Password
  Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      // Create Firestore user document
      await _createUserDocument(credential.user!);

      // Set OneSignal external user ID
      await _oneSignal.setExternalUserId(credential.user!.uid);

      // Track registration event
      await _analytics.trackRegistration(
        method: 'email',
        userId: credential.user!.uid,
      );

      return {
        'success': true,
        'user': credential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getErrorMessage(e),
      };
    } catch (e) {
      print('Error in AuthService.registerWithEmail: $e');
      return {
        'success': false,
        'error': 'Registration failed: $e',
      };
    }
  }

  /// Login with Email & Password
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update Firestore user document
      await _updateUserDocument(credential.user!);

      // Set OneSignal external user ID (for authenticated users only)
      if (!credential.user!.isAnonymous) {
        await _oneSignal.setExternalUserId(credential.user!.uid);
      }

      // Track login event
      await _analytics.trackLogin(
        method: 'email',
        userId: credential.user!.uid,
      );

      return {
        'success': true,
        'user': credential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getErrorMessage(e),
      };
    } catch (e) {
      print('Error in AuthService.loginWithEmail: $e');
      return {
        'success': false,
        'error': 'Login failed: $e',
      };
    }
  }

  /// Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {
          'success': false,
          'error': 'Google Sign-In cancelled',
        };
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Create/update Firestore user document
      await _createUserDocument(userCredential.user!);

      // Set OneSignal external user ID
      await _oneSignal.setExternalUserId(userCredential.user!.uid);

      // Track login/registration event
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        await _analytics.trackRegistration(
          method: 'google',
          userId: userCredential.user!.uid,
        );
      } else {
        await _analytics.trackLogin(
          method: 'google',
          userId: userCredential.user!.uid,
        );
      }

      return {
        'success': true,
        'user': userCredential.user,
      };
    } catch (e) {
      print('Error in AuthService.signInWithGoogle: $e');
      return {
        'success': false,
        'error': 'Google Sign-In failed: $e',
      };
    }
  }

  /// Sign in Anonymously
  Future<Map<String, dynamic>> signInAnonymously() async {
    try {
      final UserCredential credential = await _auth.signInAnonymously();

      // Create Firestore user document
      await _createUserDocument(credential.user!);

      // Track anonymous login
      await _analytics.trackLogin(
        method: 'anonymous',
        userId: credential.user!.uid,
      );

      return {
        'success': true,
        'user': credential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getErrorMessage(e),
      };
    } catch (e) {
      print('Error in AuthService.signInAnonymously: $e');
      return {
        'success': false,
        'error': 'Anonymous sign-in failed: $e',
      };
    }
  }

  /// Link Anonymous Account to Email/Password
  Future<Map<String, dynamic>> linkWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'No user logged in',
        };
      }

      // Create email credential
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // Link the credential
      final UserCredential userCredential = await user.linkWithCredential(credential);

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Update Firestore user document
      await _updateUserDocument(userCredential.user!);

      return {
        'success': true,
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getErrorMessage(e),
      };
    } catch (e) {
      print('Error in AuthService.linkWithEmailPassword: $e');
      return {
        'success': false,
        'error': 'Account linking failed: $e',
      };
    }
  }

  /// Link Account to Google
  Future<Map<String, dynamic>> linkWithGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'No user logged in',
        };
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {
          'success': false,
          'error': 'Google Sign-In cancelled',
        };
      }

      // Obtain the auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the credential
      final UserCredential userCredential = await user.linkWithCredential(credential);

      // Update Firestore user document
      await _updateUserDocument(userCredential.user!);

      return {
        'success': true,
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getErrorMessage(e),
      };
    } catch (e) {
      print('Error in AuthService.linkWithGoogle: $e');
      return {
        'success': false,
        'error': 'Google linking failed: $e',
      };
    }
  }

  /// Set Password for Google-authenticated user
  Future<Map<String, dynamic>> setPassword({
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'No user logged in',
        };
      }

      if (user.email == null || user.email!.isEmpty) {
        return {
          'success': false,
          'error': 'User must have an email address',
        };
      }

      // Create email credential with the user's existing email
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      // Link the credential
      final UserCredential userCredential = await user.linkWithCredential(credential);

      // Update Firestore user document
      await _updateUserDocument(userCredential.user!);

      return {
        'success': true,
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getErrorMessage(e),
      };
    } catch (e) {
      print('Error in AuthService.setPassword: $e');
      return {
        'success': false,
        'error': 'Set password failed: $e',
      };
    }
  }

  /// Check if user has password provider
  bool hasPasswordProvider() {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'password');
  }

  /// Check if user has Google provider
  bool hasGoogleProvider() {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'google.com');
  }

  /// Logout
  Future<void> logout() async {
    try {
      final userId = _auth.currentUser?.uid;
      
      // Track logout event before signing out
      if (userId != null) {
        await _analytics.trackLogout(userId: userId);
      }
      
      // Remove OneSignal external user ID
      await _oneSignal.removeExternalUserId();
      
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error in AuthService.logout: $e');
      rethrow;
    }
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'userId': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName ?? 'User',
          'phoneNumber': user.phoneNumber,
          'photoURL': user.photoURL,
          'isAnonymous': user.isAnonymous,
          'linkedProviders': user.providerData.map((e) => e.providerId).toList(),
          'theme': 'system',
          'notificationSubscribed': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _updateUserDocument(user);
      }
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  /// Update user document in Firestore
  Future<void> _updateUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'email': user.email ?? '',
        'displayName': user.displayName ?? 'User',
        'photoURL': user.photoURL,
        'linkedProviders': user.providerData.map((e) => e.providerId).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user document: $e');
    }
  }

  /// Get user-friendly error messages
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Try again later';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
