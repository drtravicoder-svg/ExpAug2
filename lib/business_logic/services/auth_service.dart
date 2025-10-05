// Firebase Auth is not installed - all Firebase code is commented out
// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import 'package:local_auth/local_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
// import '../../core/config/firebase_config.dart';
// import '../../core/config/app_config.dart';
// import '../../core/utils/error_handler.dart';
// import '../../core/utils/storage_service.dart';
// import '../../data/models/user.dart';
// import '../../data/repositories/user_repository.dart';

/// Enhanced authentication service with multiple auth methods - DISABLED (Firebase not installed)
/// Use MockAuthService instead for demo/testing
class EnhancedAuthService {
  // All Firebase Auth code is commented out
  // Use MockAuthService for authentication in this app
  
  EnhancedAuthService() {
    print('⚠️ EnhancedAuthService is disabled - use MockAuthService instead');
  }
  
  // final firebase_auth.FirebaseAuth _firebaseAuth;
  // final UserRepository _userRepository;
  // final LocalAuthentication _localAuth;
  // final StorageService _storage;

  // EnhancedAuthService({
  //   firebase_auth.FirebaseAuth? firebaseAuth,
  //   UserRepository? userRepository,
  //   LocalAuthentication? localAuth,
  //   StorageService? storage,
  // })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
  //       _userRepository = userRepository ?? UserRepository(),
  //       _localAuth = localAuth ?? LocalAuthentication(),
  //       _storage = storage ?? StorageService();

  // /// Current Firebase user
  // firebase_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // /// Current user ID
  // String? get currentUserId => _firebaseAuth.currentUser?.uid;

  // /// Auth state stream
  // Stream<User?> get authStateStream {
  //   return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
  //     if (firebaseUser == null) return null;
  //     
  //     try {
  //       return await _userRepository.getUserById(firebaseUser.uid);
  //     } catch (error, stackTrace) {
  //       await ErrorHandler.logError(
  //         error,
  //         stackTrace,
  //         context: 'Auth State Stream',
  //         additionalData: {'userId': firebaseUser.uid},
  //       );
  //       return null;
  //     }
  //   });
  // }

  // All other methods are commented out...
  // Use MockAuthService for authentication functionality
}
