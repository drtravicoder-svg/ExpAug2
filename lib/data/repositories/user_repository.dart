// Firestore is not installed - all Firebase code is commented out
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

/// User Repository - DISABLED (Firestore not installed)
/// This app uses SQLite and mock data instead
class UserRepository {
  UserRepository() {
    print('ℹ️ UserRepository is disabled - using mock data');
  }
  
  // All Firestore code is commented out
  // final FirebaseFirestore _firestore;

  // UserRepository({FirebaseFirestore? firestore})
  //     : _firestore = firestore ?? FirebaseFirestore.instance;

  // Stub methods to avoid compilation errors
  Future<void> createUser(User user) async {
    throw UserRepositoryException('UserRepository is disabled - Firebase not installed');
  }

  Future<User?> getUserById(String userId) async {
    throw UserRepositoryException('UserRepository is disabled - Firebase not installed');
  }

  Future<void> updateLastLogin(String userId) async {
    // Disabled
  }

  Future<User> updateUserProfile(
    String userId, {
    String? displayName,
    String? phone,
    String? avatarUrl,
  }) async {
    throw UserRepositoryException('UserRepository is disabled - Firebase not installed');
  }

  Future<void> deleteUser(String userId) async {
    throw UserRepositoryException('UserRepository is disabled - Firebase not installed');
  }

  // All other methods are commented out...
}

class UserRepositoryException implements Exception {
  final String message;
  UserRepositoryException(this.message);
  
  @override
  String toString() => message;
}
