import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new user
  Future<void> createUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toFirestore());
    } catch (e) {
      throw UserRepositoryException('Failed to create user: ${e.toString()}');
    }
  }

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw UserRepositoryException('Failed to get user: ${e.toString()}');
    }
  }

  // Get user by email
  Future<User?> getUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return User.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw UserRepositoryException('Failed to get user by email: ${e.toString()}');
    }
  }

  // Update user
  Future<void> updateUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toFirestore());
    } catch (e) {
      throw UserRepositoryException('Failed to update user: ${e.toString()}');
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(String userId, UserPreferences preferences) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'preferences': preferences.toJson(),
      });
    } catch (e) {
      throw UserRepositoryException('Failed to update user preferences: ${e.toString()}');
    }
  }

  // Update last login time
  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw UserRepositoryException('Failed to update last login: ${e.toString()}');
    }
  }

  // Update user avatar
  Future<void> updateUserAvatar(String userId, String avatarUrl) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'avatarUrl': avatarUrl,
      });
    } catch (e) {
      throw UserRepositoryException('Failed to update user avatar: ${e.toString()}');
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw UserRepositoryException('Failed to delete user: ${e.toString()}');
    }
  }

  // Get all admin users
  Future<List<User>> getAdminUsers() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      
      return query.docs.map((doc) => User.fromFirestore(doc)).toList();
    } catch (e) {
      throw UserRepositoryException('Failed to get admin users: ${e.toString()}');
    }
  }

  // Get all member users
  Future<List<User>> getMemberUsers() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'member')
          .get();
      
      return query.docs.map((doc) => User.fromFirestore(doc)).toList();
    } catch (e) {
      throw UserRepositoryException('Failed to get member users: ${e.toString()}');
    }
  }

  // Search users by display name or email
  Future<List<User>> searchUsers(String searchTerm) async {
    try {
      // Note: Firestore doesn't support full-text search, so we'll do a simple prefix search
      final nameQuery = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: searchTerm)
          .where('displayName', isLessThan: searchTerm + '\uf8ff')
          .get();

      final emailQuery = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: searchTerm)
          .where('email', isLessThan: searchTerm + '\uf8ff')
          .get();

      final users = <User>[];
      final userIds = <String>{};

      // Add users from name search
      for (final doc in nameQuery.docs) {
        if (!userIds.contains(doc.id)) {
          users.add(User.fromFirestore(doc));
          userIds.add(doc.id);
        }
      }

      // Add users from email search (avoid duplicates)
      for (final doc in emailQuery.docs) {
        if (!userIds.contains(doc.id)) {
          users.add(User.fromFirestore(doc));
          userIds.add(doc.id);
        }
      }

      return users;
    } catch (e) {
      throw UserRepositoryException('Failed to search users: ${e.toString()}');
    }
  }

  // Stream user changes
  Stream<User?> streamUser(String userId) {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          return User.fromFirestore(doc);
        }
        return null;
      });
    } catch (e) {
      throw UserRepositoryException('Failed to stream user: ${e.toString()}');
    }
  }

  // Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      throw UserRepositoryException('Failed to check if user exists: ${e.toString()}');
    }
  }

  // Get user count by role
  Future<int> getUserCountByRole(UserRole role) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: role.toString().split('.').last)
          .count()
          .get();

      return query.count;
    } catch (e) {
      throw UserRepositoryException('Failed to get user count: ${e.toString()}');
    }
  }

  // Update user profile (used by auth service)
  Future<User> updateUserProfile(
    String userId, {
    String? displayName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (displayName != null) updates['displayName'] = displayName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);
      }

      // Return updated user
      final updatedUser = await getUserById(userId);
      if (updatedUser == null) {
        throw UserRepositoryException('User not found after update');
      }

      return updatedUser;
    } catch (e) {
      throw UserRepositoryException('Failed to update user profile: ${e.toString()}');
    }
  }

  // Batch operations for better performance
  Future<void> batchCreateUsers(List<User> users) async {
    try {
      final batch = _firestore.batch();

      for (final user in users) {
        final docRef = _firestore.collection('users').doc(user.id);
        batch.set(docRef, user.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      throw UserRepositoryException('Failed to batch create users: ${e.toString()}');
    }
  }

  // Get users by IDs
  Future<List<User>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      // Firestore 'in' queries are limited to 10 items
      final chunks = <List<String>>[];
      for (int i = 0; i < userIds.length; i += 10) {
        chunks.add(userIds.sublist(i, i + 10 > userIds.length ? userIds.length : i + 10));
      }

      final users = <User>[];

      for (final chunk in chunks) {
        final query = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        users.addAll(query.docs.map((doc) => User.fromFirestore(doc)));
      }

      return users;
    } catch (e) {
      throw UserRepositoryException('Failed to get users by IDs: ${e.toString()}');
    }
  }
}

class UserRepositoryException implements Exception {
  final String message;
  UserRepositoryException(this.message);
  
  @override
  String toString() => message;
}
