import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/firebase_config.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/storage_service.dart';
import '../../core/utils/connectivity_service.dart';
import '../../data/models/expense.dart';
import '../../data/models/trip.dart';
import '../../data/models/user.dart';

/// Service for managing offline capabilities and data synchronization
class OfflineService {
  final FirebaseFirestore _firestore;
  final StorageService _storage;
  final ConnectivityService _connectivity;
  
  final Map<String, PendingOperation> _pendingOperations = {};
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  OfflineService({
    FirebaseFirestore? firestore,
    StorageService? storage,
    ConnectivityService? connectivity,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? StorageService(),
        _connectivity = connectivity ?? ConnectivityService();

  /// Initialize offline service
  Future<void> initialize() async {
    try {
      // Enable Firestore offline persistence
      if (!kIsWeb) {
        await _firestore.enablePersistence();
      }

      // Load pending operations from storage
      await _loadPendingOperations();

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.isConnected.listen(_onConnectivityChanged);

      // Perform initial sync if connected
      if (await _connectivity.hasConnection()) {
        _syncPendingOperations();
      }

      debugPrint('Offline service initialized');
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Offline Service Init');
    }
  }

  /// Cache data locally
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    try {
      final cacheKey = 'cache_$key';
      await _storage.setString(cacheKey, jsonEncode(data));
      
      // Store cache metadata
      final metadata = {
        'key': key,
        'timestamp': DateTime.now().toIso8601String(),
        'size': jsonEncode(data).length,
      };
      await _storage.setString('${cacheKey}_meta', jsonEncode(metadata));
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Cache Data');
    }
  }

  /// Get cached data
  Future<Map<String, dynamic>?> getCachedData(String key) async {
    try {
      final cacheKey = 'cache_$key';
      final cachedData = await _storage.getString(cacheKey);
      
      if (cachedData != null) {
        return Map<String, dynamic>.from(jsonDecode(cachedData));
      }
      return null;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Get Cached Data');
      return null;
    }
  }

  /// Add operation to pending queue
  Future<void> addPendingOperation(PendingOperation operation) async {
    try {
      _pendingOperations[operation.id] = operation;
      await _savePendingOperations();
      
      // Try to sync immediately if connected
      if (await _connectivity.hasConnection()) {
        _syncPendingOperations();
      }
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Add Pending Operation');
    }
  }

  /// Create expense offline
  Future<String> createExpenseOffline(Expense expense) async {
    try {
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final expenseWithTempId = expense.copyWith(id: tempId);
      
      // Cache locally
      await cacheData('expense_$tempId', expenseWithTempId.toFirestore());
      
      // Add to pending operations
      final operation = PendingOperation(
        id: tempId,
        type: OperationType.create,
        collection: 'expenses',
        data: expenseWithTempId.toFirestore(),
        timestamp: DateTime.now(),
      );
      
      await addPendingOperation(operation);
      
      return tempId;
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Update expense offline
  Future<void> updateExpenseOffline(String expenseId, Map<String, dynamic> updates) async {
    try {
      // Update cached data
      final cachedExpense = await getCachedData('expense_$expenseId');
      if (cachedExpense != null) {
        cachedExpense.addAll(updates);
        await cacheData('expense_$expenseId', cachedExpense);
      }
      
      // Add to pending operations
      final operation = PendingOperation(
        id: '${expenseId}_update_${DateTime.now().millisecondsSinceEpoch}',
        type: OperationType.update,
        collection: 'expenses',
        documentId: expenseId,
        data: updates,
        timestamp: DateTime.now(),
      );
      
      await addPendingOperation(operation);
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Delete expense offline
  Future<void> deleteExpenseOffline(String expenseId) async {
    try {
      // Mark as deleted in cache
      await cacheData('expense_${expenseId}_deleted', {'deleted': true});
      
      // Add to pending operations
      final operation = PendingOperation(
        id: '${expenseId}_delete_${DateTime.now().millisecondsSinceEpoch}',
        type: OperationType.delete,
        collection: 'expenses',
        documentId: expenseId,
        timestamp: DateTime.now(),
      );
      
      await addPendingOperation(operation);
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get offline expenses
  Future<List<Expense>> getOfflineExpenses(String tripId) async {
    try {
      final expenses = <Expense>[];
      final keys = await _storage.getKeys();
      
      for (final key in keys) {
        if (key.startsWith('cache_expense_') && !key.endsWith('_meta') && !key.endsWith('_deleted')) {
          final cachedData = await getCachedData(key.replaceFirst('cache_', ''));
          if (cachedData != null && cachedData['tripId'] == tripId) {
            // Check if not deleted
            final deletedData = await getCachedData('${key.replaceFirst('cache_', '')}_deleted');
            if (deletedData == null) {
              expenses.add(Expense.fromJson(cachedData));
            }
          }
        }
      }
      
      return expenses;
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Sync pending operations
  Future<void> _syncPendingOperations() async {
    if (_isSyncing || _pendingOperations.isEmpty) return;
    
    try {
      _isSyncing = true;
      final operations = List<PendingOperation>.from(_pendingOperations.values);
      operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      for (final operation in operations) {
        try {
          await _executePendingOperation(operation);
          _pendingOperations.remove(operation.id);
        } catch (error) {
          // Log error but continue with other operations
          await ErrorHandler.logError(error, StackTrace.current, 
              context: 'Sync Operation: ${operation.id}');
        }
      }
      
      await _savePendingOperations();
      
      // Log analytics event
      await FirebaseConfig.logEvent('offline_sync_completed', {
        'operations_synced': operations.length,
        'remaining_operations': _pendingOperations.length,
      });
      
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Sync Pending Operations');
    } finally {
      _isSyncing = false;
    }
  }

  /// Execute pending operation
  Future<void> _executePendingOperation(PendingOperation operation) async {
    switch (operation.type) {
      case OperationType.create:
        await _executeCreateOperation(operation);
        break;
      case OperationType.update:
        await _executeUpdateOperation(operation);
        break;
      case OperationType.delete:
        await _executeDeleteOperation(operation);
        break;
    }
  }

  /// Execute create operation
  Future<void> _executeCreateOperation(PendingOperation operation) async {
    final docRef = await _firestore.collection(operation.collection).add(operation.data);
    
    // Update local cache with real ID
    if (operation.collection == 'expenses') {
      final realId = docRef.id;
      final tempId = operation.id;
      
      // Remove temp cache
      await _storage.remove('cache_expense_$tempId');
      await _storage.remove('cache_expense_${tempId}_meta');
      
      // Cache with real ID
      final updatedData = Map<String, dynamic>.from(operation.data);
      updatedData['id'] = realId;
      await cacheData('expense_$realId', updatedData);
    }
  }

  /// Execute update operation
  Future<void> _executeUpdateOperation(PendingOperation operation) async {
    if (operation.documentId == null) return;
    
    await _firestore
        .collection(operation.collection)
        .doc(operation.documentId)
        .update(operation.data);
  }

  /// Execute delete operation
  Future<void> _executeDeleteOperation(PendingOperation operation) async {
    if (operation.documentId == null) return;
    
    await _firestore
        .collection(operation.collection)
        .doc(operation.documentId)
        .delete();
    
    // Remove from local cache
    await _storage.remove('cache_${operation.collection}_${operation.documentId}');
    await _storage.remove('cache_${operation.collection}_${operation.documentId}_meta');
    await _storage.remove('cache_${operation.collection}_${operation.documentId}_deleted');
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(bool isConnected) {
    if (isConnected && _pendingOperations.isNotEmpty) {
      _syncPendingOperations();
    }
  }

  /// Load pending operations from storage
  Future<void> _loadPendingOperations() async {
    try {
      final operationsJson = await _storage.getString('pending_operations');
      if (operationsJson != null) {
        final operationsList = List<Map<String, dynamic>>.from(jsonDecode(operationsJson));
        for (final operationData in operationsList) {
          final operation = PendingOperation.fromJson(operationData);
          _pendingOperations[operation.id] = operation;
        }
      }
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Load Pending Operations');
    }
  }

  /// Save pending operations to storage
  Future<void> _savePendingOperations() async {
    try {
      final operationsList = _pendingOperations.values.map((op) => op.toJson()).toList();
      await _storage.setString('pending_operations', jsonEncode(operationsList));
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Save Pending Operations');
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    try {
      final keys = await _storage.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_')) {
          await _storage.remove(key);
        }
      }
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Clear Cache');
    }
  }

  /// Get cache size
  Future<int> getCacheSize() async {
    try {
      int totalSize = 0;
      final keys = await _storage.getKeys();
      
      for (final key in keys) {
        if (key.startsWith('cache_') && key.endsWith('_meta')) {
          final metaData = await _storage.getString(key);
          if (metaData != null) {
            final meta = Map<String, dynamic>.from(jsonDecode(metaData));
            totalSize += (meta['size'] as int? ?? 0);
          }
        }
      }
      
      return totalSize;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Get Cache Size');
      return 0;
    }
  }

  /// Get sync status
  SyncStatus getSyncStatus() {
    if (_isSyncing) return SyncStatus.syncing;
    if (_pendingOperations.isNotEmpty) return SyncStatus.pending;
    return SyncStatus.synced;
  }

  /// Get pending operations count
  int getPendingOperationsCount() => _pendingOperations.length;

  /// Force sync
  Future<void> forceSync() async {
    if (await _connectivity.hasConnection()) {
      await _syncPendingOperations();
    }
  }

  /// Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

/// Pending operation model
class PendingOperation {
  final String id;
  final OperationType type;
  final String collection;
  final String? documentId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const PendingOperation({
    required this.id,
    required this.type,
    required this.collection,
    this.documentId,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'collection': collection,
    'documentId': documentId,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };

  factory PendingOperation.fromJson(Map<String, dynamic> json) => PendingOperation(
    id: json['id'],
    type: OperationType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => OperationType.create,
    ),
    collection: json['collection'],
    documentId: json['documentId'],
    data: Map<String, dynamic>.from(json['data']),
    timestamp: DateTime.parse(json['timestamp']),
  );
}

/// Operation types
enum OperationType { create, update, delete }

/// Sync status
enum SyncStatus { synced, pending, syncing }
