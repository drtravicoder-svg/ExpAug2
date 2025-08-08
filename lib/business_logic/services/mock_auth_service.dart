import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/user.dart';

/// Mock authentication service for testing without Firebase
class MockAuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  // Mock current user
  User? _currentUser;
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();

  // Mock users database
  static final List<User> _mockUsers = [
    User(
      id: 'demo_user_1',
      email: 'demo@example.com',
      displayName: 'Demo User',
      phoneNumber: '+1234567890',
      role: UserRole.admin,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      preferences: const UserPreferences(),
    ),
    User(
      id: 'demo_user_2',
      email: 'member@example.com',
      displayName: 'Demo Member',
      phoneNumber: '+1234567891',
      role: UserRole.member,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      preferences: const UserPreferences(),
    ),
  ];

  /// Get current user
  User? get currentUser => _currentUser;

  /// Get current user ID
  String? get currentUserId => _currentUser?.id;

  /// Auth state stream
  Stream<User?> get authStateChanges => _authStateController.stream;

  /// Initialize mock auth with demo user
  Future<void> initialize() async {
    // Auto-login with demo user for testing
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = _mockUsers.first;
    _authStateController.add(_currentUser);
    
    if (kDebugMode) {
      print('🎭 Mock Auth: Logged in as ${_currentUser?.displayName}');
    }
  }

  /// Sign in with email and password (mock)
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000)); // Simulate network delay
    
    // Find user by email
    final user = _mockUsers.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception('User not found'),
    );
    
    _currentUser = user;
    _authStateController.add(_currentUser);
    
    if (kDebugMode) {
      print('🎭 Mock Auth: Signed in as ${user.displayName}');
    }
    
    return user;
  }

  /// Sign out
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _authStateController.add(null);
    
    if (kDebugMode) {
      print('🎭 Mock Auth: Signed out');
    }
  }

  /// Create user account (mock)
  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final newUser = User(
      id: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName,
      phoneNumber: phoneNumber,
      role: UserRole.member,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      preferences: const UserPreferences(),
    );
    
    _mockUsers.add(newUser);
    _currentUser = newUser;
    _authStateController.add(_currentUser);
    
    if (kDebugMode) {
      print('🎭 Mock Auth: Created account for ${newUser.displayName}');
    }
    
    return newUser;
  }

  /// Get all mock users
  List<User> getAllUsers() => List.from(_mockUsers);

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
