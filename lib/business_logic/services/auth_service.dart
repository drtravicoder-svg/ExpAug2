import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/config/firebase_config.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/storage_service.dart';
import '../../data/models/user.dart';
import '../../data/repositories/user_repository.dart';

/// Enhanced authentication service with multiple auth methods
class EnhancedAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final UserRepository _userRepository;
  final LocalAuthentication _localAuth;
  final StorageService _storage;

  EnhancedAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    UserRepository? userRepository,
    LocalAuthentication? localAuth,
    StorageService? storage,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _userRepository = userRepository ?? UserRepository(),
        _localAuth = localAuth ?? LocalAuthentication(),
        _storage = storage ?? StorageService();

  /// Current Firebase user
  firebase_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  /// Current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  /// Auth state stream
  Stream<User?> get authStateStream {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      
      try {
        return await _userRepository.getUserById(firebaseUser.uid);
      } catch (error, stackTrace) {
        await ErrorHandler.logError(
          error,
          stackTrace,
          context: 'Auth State Stream',
          additionalData: {'userId': firebaseUser.uid},
        );
        return null;
      }
    });
  }

  /// Sign in with email and password
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw const AuthException('Sign in failed: No user returned');
      }

      // Update last login time
      await _userRepository.updateLastLogin(credential.user!.uid);
      
      // Get user from Firestore
      final user = await _userRepository.getUserById(credential.user!.uid);
      
      // Store user info locally
      await _storage.setUserId(user.id);
      await _storage.setUserEmail(user.email);
      await _storage.setUserName(user.displayName);
      
      // Log analytics event
      await FirebaseConfig.logEvent(
        FirebaseConstants.eventTripCreated,
        {'method': 'email_password'},
      );
      
      return user;
    } on firebase_auth.FirebaseAuthException catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Sign up with email and password (Admin only)
  Future<User> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    String? phone,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw const AuthException('Sign up failed: No user returned');
      }

      // Update Firebase Auth display name
      await credential.user!.updateDisplayName(displayName);
      
      // Create user profile in Firestore
      final user = User(
        id: credential.user!.uid,
        email: email,
        phone: phone,
        displayName: displayName,
        role: UserRole.admin, // Default to admin for sign-up
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      await _userRepository.createUser(user);
      
      // Store user info locally
      await _storage.setUserId(user.id);
      await _storage.setUserEmail(user.email);
      await _storage.setUserName(user.displayName);
      
      // Log analytics event
      await FirebaseConfig.logEvent(
        'user_signup',
        {'method': 'email_password'},
      );
      
      return user;
    } on firebase_auth.FirebaseAuthException catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Sign in with phone number (OTP)
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
          try {
            final userCredential = await _firebaseAuth.signInWithCredential(credential);
            if (userCredential.user != null) {
              await _handlePhoneSignIn(userCredential.user!);
            }
          } catch (error) {
            onError('Auto-verification failed: ${error.toString()}');
          }
        },
        verificationFailed: (firebase_auth.FirebaseAuthException error) {
          onError(ErrorHandler.getUserMessage(error));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle timeout
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Phone Sign In');
      onError(ErrorHandler.getUserMessage(error));
    }
  }

  /// Verify OTP code
  Future<User> verifyOTPCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        throw const AuthException('OTP verification failed: No user returned');
      }
      
      return await _handlePhoneSignIn(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Handle phone sign in
  Future<User> _handlePhoneSignIn(firebase_auth.User firebaseUser) async {
    try {
      // Check if user exists in Firestore
      User user;
      try {
        user = await _userRepository.getUserById(firebaseUser.uid);
        // Update last login
        await _userRepository.updateLastLogin(firebaseUser.uid);
      } catch (e) {
        // Create new user if doesn't exist
        user = User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          phone: firebaseUser.phoneNumber,
          displayName: firebaseUser.displayName ?? 'User',
          role: UserRole.member, // Default to member for phone sign-in
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        await _userRepository.createUser(user);
      }
      
      // Store user info locally
      await _storage.setUserId(user.id);
      await _storage.setUserEmail(user.email);
      await _storage.setUserName(user.displayName);
      
      // Log analytics event
      await FirebaseConfig.logEvent(
        'user_signin',
        {'method': 'phone'},
      );
      
      return user;
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Biometric Check');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Get Biometrics');
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({
    String reason = 'Please authenticate to access your account',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        // Log analytics event
        await FirebaseConfig.logEvent(
          'biometric_auth_success',
          {'timestamp': DateTime.now().toIso8601String()},
        );
      }

      return isAuthenticated;
    } on PlatformException catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Biometric Auth');
      return false;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Biometric Auth');
      return false;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      
      // Log analytics event
      await FirebaseConfig.logEvent(
        'password_reset_sent',
        {'email_domain': email.split('@').last},
      );
    } on firebase_auth.FirebaseAuthException catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Clear local storage
      await _storage.remove(AppConstants.keyUserId);
      await _storage.remove(AppConstants.keyUserEmail);
      await _storage.remove(AppConstants.keyUserName);
      
      // Sign out from Firebase
      await _firebaseAuth.signOut();
      
      // Log analytics event
      await FirebaseConfig.logEvent(
        'user_signout',
        {'timestamp': DateTime.now().toIso8601String()},
      );
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No user signed in');
      }

      // Delete user data from Firestore
      await _userRepository.deleteUser(user.uid);
      
      // Delete Firebase Auth account
      await user.delete();
      
      // Clear local storage
      await _storage.clear();
      
      // Log analytics event
      await FirebaseConfig.logEvent(
        'account_deleted',
        {'timestamp': DateTime.now().toIso8601String()},
      );
    } on firebase_auth.FirebaseAuthException catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Update user profile
  Future<User> updateProfile({
    String? displayName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const AuthException('No user signed in');
      }

      // Update Firebase Auth profile
      if (displayName != null) {
        await firebaseUser.updateDisplayName(displayName);
      }

      // Update Firestore profile
      final updatedUser = await _userRepository.updateUserProfile(
        firebaseUser.uid,
        displayName: displayName,
        phone: phone,
        avatarUrl: avatarUrl,
      );

      // Update local storage
      if (displayName != null) {
        await _storage.setUserName(displayName);
      }

      return updatedUser;
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Check if user is admin
  Future<bool> isAdmin() async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;
      
      final user = await _userRepository.getUserById(userId);
      return user.isAdmin;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Admin Check');
      return false;
    }
  }

  /// Check if user is member
  Future<bool> isMember() async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;
      
      final user = await _userRepository.getUserById(userId);
      return user.isMember;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Member Check');
      return false;
    }
  }
}
