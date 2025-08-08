import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../../core/utils/error_handler.dart';
import '../../core/config/firebase_config.dart';

/// Repository for managing expense categories
class CategoryRepository {
  final FirebaseFirestore _firestore;

  CategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get all default categories
  Future<List<Category>> getDefaultCategories() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.categoriesCollection)
          .where('isDefault', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get categories for a specific trip
  Stream<List<Category>> getTripCategories(String tripId) {
    try {
      return _firestore
          .collection(FirebaseConstants.categoriesCollection)
          .where('tripId', whereIn: [tripId, null]) // Include trip-specific and default categories
          .orderBy('order')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
      });
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Create a new category
  Future<Category> createCategory(Category category) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConstants.categoriesCollection)
          .add(category.toFirestore());
      
      final doc = await docRef.get();
      return Category.fromFirestore(doc);
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Update category
  Future<void> updateCategory(Category category) async {
    try {
      await _firestore
          .collection(FirebaseConstants.categoriesCollection)
          .doc(category.id)
          .update(category.toFirestore());
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.categoriesCollection)
          .doc(categoryId)
          .delete();
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.categoriesCollection)
          .doc(categoryId)
          .get();

      if (doc.exists) {
        return Category.fromFirestore(doc);
      }
      return null;
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get most used categories for a trip
  Future<List<Category>> getMostUsedCategories(String tripId, {int limit = 5}) async {
    try {
      // This would require aggregating expense data
      // For now, return default categories
      return await getDefaultCategories();
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Initialize default categories
  Future<void> initializeDefaultCategories() async {
    try {
      final defaultCategories = [
        Category(
          id: 'food',
          name: 'Food & Dining',
          icon: 'restaurant',
          color: 0xFFFF6B6B,
          isDefault: true,
          order: 1,
        ),
        Category(
          id: 'transport',
          name: 'Transportation',
          icon: 'directions_car',
          color: 0xFF4ECDC4,
          isDefault: true,
          order: 2,
        ),
        Category(
          id: 'accommodation',
          name: 'Accommodation',
          icon: 'hotel',
          color: 0xFF45B7D1,
          isDefault: true,
          order: 3,
        ),
        Category(
          id: 'entertainment',
          name: 'Entertainment',
          icon: 'movie',
          color: 0xFF96CEB4,
          isDefault: true,
          order: 4,
        ),
        Category(
          id: 'shopping',
          name: 'Shopping',
          icon: 'shopping_bag',
          color: 0xFFFECA57,
          isDefault: true,
          order: 5,
        ),
        Category(
          id: 'health',
          name: 'Health & Medical',
          icon: 'local_hospital',
          color: 0xFFFF9FF3,
          isDefault: true,
          order: 6,
        ),
        Category(
          id: 'utilities',
          name: 'Utilities',
          icon: 'electrical_services',
          color: 0xFF54A0FF,
          isDefault: true,
          order: 7,
        ),
        Category(
          id: 'miscellaneous',
          name: 'Miscellaneous',
          icon: 'category',
          color: 0xFF5F27CD,
          isDefault: true,
          order: 8,
        ),
      ];

      final batch = _firestore.batch();

      for (final category in defaultCategories) {
        final docRef = _firestore
            .collection(FirebaseConstants.categoriesCollection)
            .doc(category.id);
        batch.set(docRef, category.toFirestore(), SetOptions(merge: true));
      }

      await batch.commit();
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Search categories by name
  Future<List<Category>> searchCategories(String query, {String? tripId}) async {
    try {
      Query<Map<String, dynamic>> baseQuery = _firestore
          .collection(FirebaseConstants.categoriesCollection);

      if (tripId != null) {
        baseQuery = baseQuery.where('tripId', whereIn: [tripId, null]);
      }

      final snapshot = await baseQuery
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + '\uf8ff')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get category usage statistics for a trip
  Future<Map<String, CategoryUsage>> getCategoryUsageStats(String tripId) async {
    try {
      // This would require aggregating expense data by category
      // For now, return empty map
      return {};
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Reorder categories
  Future<void> reorderCategories(List<String> categoryIds) async {
    try {
      final batch = _firestore.batch();

      for (int i = 0; i < categoryIds.length; i++) {
        final docRef = _firestore
            .collection(FirebaseConstants.categoriesCollection)
            .doc(categoryIds[i]);
        batch.update(docRef, {'order': i + 1});
      }

      await batch.commit();
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Check if category is being used in any expenses
  Future<bool> isCategoryInUse(String categoryId) async {
    try {
      final expenseQuery = await _firestore
          .collection('expenses')
          .where('categoryId', isEqualTo: categoryId)
          .limit(1)
          .get();

      return expenseQuery.docs.isNotEmpty;
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get categories with usage count
  Future<List<CategoryWithUsage>> getCategoriesWithUsage(String tripId) async {
    try {
      final categories = await getTripCategories(tripId).first;
      final categoriesWithUsage = <CategoryWithUsage>[];

      for (final category in categories) {
        final usageCount = await _getCategoryUsageCount(category.id, tripId);
        categoriesWithUsage.add(CategoryWithUsage(
          category: category,
          usageCount: usageCount,
        ));
      }

      // Sort by usage count (most used first)
      categoriesWithUsage.sort((a, b) => b.usageCount.compareTo(a.usageCount));

      return categoriesWithUsage;
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get usage count for a specific category in a trip
  Future<int> _getCategoryUsageCount(String categoryId, String tripId) async {
    try {
      final expenseQuery = await _firestore
          .collection('expenses')
          .where('tripId', isEqualTo: tripId)
          .where('categoryId', isEqualTo: categoryId)
          .count()
          .get();

      return expenseQuery.count;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Category Usage Count');
      return 0;
    }
  }
}

/// Category usage statistics model
class CategoryUsage {
  final String categoryId;
  final int expenseCount;
  final double totalAmount;
  final double averageAmount;
  final DateTime lastUsed;

  const CategoryUsage({
    required this.categoryId,
    required this.expenseCount,
    required this.totalAmount,
    required this.averageAmount,
    required this.lastUsed,
  });
}

/// Category with usage count model
class CategoryWithUsage {
  final Category category;
  final int usageCount;

  const CategoryWithUsage({
    required this.category,
    required this.usageCount,
  });
}
