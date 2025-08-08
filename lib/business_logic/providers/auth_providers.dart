import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../data/models/user.dart';
import '../../data/repositories/user_repository.dart';
import '../services/mock_auth_service.dart';

// Firebase Auth instance provider
final firebaseAuthProvider = Provider<firebase_auth.FirebaseAuth>((ref) {
  return firebase_auth.FirebaseAuth.instance;
});

// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// Mock auth service provider
final mockAuthServiceProvider = Provider<MockAuthService>((ref) {
  return MockAuthService();
});

// Auth state stream provider (using mock service for demo)
final authStateProvider = StreamProvider<User?>((ref) {
  final mockAuth = ref.watch(mockAuthServiceProvider);
  return mockAuth.authStateChanges;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final mockAuth = ref.watch(mockAuthServiceProvider);
  return mockAuth.currentUser;
});

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return AuthService(firebaseAuth, userRepository);
});

// Auth loading state provider
final authLoadingProvider = StateProvider<bool>((ref) => false);

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final UserRepository _userRepository;

  AuthService(this._firebaseAuth, this._userRepository);

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Update last login time
        await _userRepository.updateLastLogin(credential.user!.uid);
        return await _userRepository.getUserById(credential.user!.uid);
      }
      
      return null;
    } catch (e) {
      throw AuthException('Failed to sign in: ${e.toString()}');
    }
  }

  // Sign up with email and password (Admin only)
  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Create user profile in Firestore
        final user = User(
          id: credential.user!.uid,
          email: email,
          displayName: displayName,
          role: UserRole.admin, // Default to admin for sign-up
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        
        await _userRepository.createUser(user);
        
        // Update Firebase Auth display name
        await credential.user!.updateDisplayName(displayName);
        
        return user;
      }
      
      return null;
    } catch (e) {
      throw AuthException('Failed to sign up: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw AuthException('Failed to send password reset email: ${e.toString()}');
    }
  }

  // Check if user is admin
  bool isAdmin(User? user) {
    return user?.role == UserRole.admin;
  }

  // Check if user is member
  bool isMember(User? user) {
    return user?.role == UserRole.member;
  }

  // Get current Firebase user
  firebase_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // Get current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => message;
}

// Auth state notifier for complex auth operations
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState.initial());

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.error('Failed to sign in');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AuthState.loading();
    
    try {
      final user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.error('Failed to sign up');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signOut() async {
    state = const AuthState.loading();
    
    try {
      await _authService.signOut();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  void clearError() {
    if (state is AuthStateError) {
      state = const AuthState.unauthenticated();
    }
  }
}

// Auth state classes
abstract class AuthState {
  const AuthState();
  
  const factory AuthState.initial() = AuthStateInitial;
  const factory AuthState.loading() = AuthStateLoading;
  const factory AuthState.authenticated(User user) = AuthStateAuthenticated;
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;
  const factory AuthState.error(String message) = AuthStateError;
}

class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateAuthenticated extends AuthState {
  final User user;
  const AuthStateAuthenticated(this.user);
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

class AuthStateError extends AuthState {
  final String message;
  const AuthStateError(this.message);
}
