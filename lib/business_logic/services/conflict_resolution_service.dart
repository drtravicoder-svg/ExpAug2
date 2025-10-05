import 'dart:async';
// Firebase Firestore integration disabled (not installed)
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/error_handler.dart';
import '../../data/models/expense.dart';
import '../../data/models/trip.dart';
import 'offline_service.dart';

/// Service for handling data conflicts during synchronization
/// NOTE: Firebase integration is disabled - this service requires Firebase to function
class ConflictResolutionService {
  // final FirebaseFirestore _firestore;
  final OfflineService _offlineService;

  ConflictResolutionService({
    // FirebaseFirestore? firestore,
    OfflineService? offlineService,
  }) : // _firestore = firestore ?? FirebaseFirestore.instance,
        _offlineService = offlineService ?? OfflineService();

  /// Resolve expense conflicts
  Future<ConflictResolution> resolveExpenseConflict({
    required Expense localExpense,
    required Expense remoteExpense,
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.lastWriteWins,
  }) async {
    try {
      switch (strategy) {
        case ConflictResolutionStrategy.lastWriteWins:
          return _resolveLastWriteWins(localExpense, remoteExpense);
        
        case ConflictResolutionStrategy.mergeChanges:
          return _resolveMergeChanges(localExpense, remoteExpense);
        
        case ConflictResolutionStrategy.userChoice:
          return ConflictResolution(
            type: ConflictType.userChoice,
            localData: localExpense,
            remoteData: remoteExpense,
            resolvedData: null,
            requiresUserInput: true,
          );
        
        case ConflictResolutionStrategy.keepBoth:
          return _resolveKeepBoth(localExpense, remoteExpense);
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Resolve using last write wins strategy
  ConflictResolution _resolveLastWriteWins(Expense local, Expense remote) {
    final localModified = local.updatedAt;
    final remoteModified = remote.updatedAt;
    
    if (localModified.isAfter(remoteModified)) {
      return ConflictResolution(
        type: ConflictType.localWins,
        localData: local,
        remoteData: remote,
        resolvedData: local,
        requiresUserInput: false,
      );
    } else {
      return ConflictResolution(
        type: ConflictType.remoteWins,
        localData: local,
        remoteData: remote,
        resolvedData: remote,
        requiresUserInput: false,
      );
    }
  }

  /// Resolve using merge changes strategy
  ConflictResolution _resolveMergeChanges(Expense local, Expense remote) {
    // Create merged expense with intelligent field selection
    final merged = Expense(
      id: local.id,
      tripId: local.tripId,
      payerId: local.payerId, // Fixed: was paidBy
      title: _selectMostRecent(local.title, remote.title, local.updatedAt, remote.updatedAt),
      description: _selectMostRecent(local.description, remote.description, local.updatedAt, remote.updatedAt),
      amount: _selectMostRecent(local.amount, remote.amount, local.updatedAt, remote.updatedAt),
      currency: _selectMostRecent(local.currency, remote.currency, local.updatedAt, remote.updatedAt),
      category: _selectMostRecent(local.category, remote.category, local.updatedAt, remote.updatedAt), // Fixed: was categoryId
      date: _selectMostRecent(local.date, remote.date, local.updatedAt, remote.updatedAt),
      receiptPath: local.receiptPath ?? remote.receiptPath, // Fixed: was receiptUrl
      status: _mergeStatus(local.status, remote.status),
      createdAt: local.createdAt, // Keep original creation time
      updatedAt: DateTime.now(), // Set new update time
    );

    return ConflictResolution(
      type: ConflictType.merged,
      localData: local,
      remoteData: remote,
      resolvedData: merged,
      requiresUserInput: false,
    );
  }

  /// Resolve using keep both strategy
  ConflictResolution _resolveKeepBoth(Expense local, Expense remote) {
    // Create a duplicate of the local expense with a new ID
    final duplicateLocal = local.copyWith(
      id: 'duplicate_${local.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: '${local.title} (Local Copy)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return ConflictResolution(
      type: ConflictType.keepBoth,
      localData: local,
      remoteData: remote,
      resolvedData: duplicateLocal,
      requiresUserInput: false,
      additionalData: remote, // Keep remote as well
    );
  }

  /// Select most recent value
  T _selectMostRecent<T>(T localValue, T remoteValue, DateTime localTime, DateTime remoteTime) {
    return localTime.isAfter(remoteTime) ? localValue : remoteValue;
  }

  /// Merge expense status
  ExpenseStatus _mergeStatus(ExpenseStatus local, ExpenseStatus remote) {
    // Priority: approved > pending > rejected
    const statusPriority = {
      ExpenseStatus.approved: 3, // Fixed: was ExpenseStatus.committed
      ExpenseStatus.pending: 2,
      ExpenseStatus.rejected: 1,
    };
    
    final localPriority = statusPriority[local] ?? 0;
    final remotePriority = statusPriority[remote] ?? 0;
    
    return localPriority >= remotePriority ? local : remote;
  }

  // Note: The following methods are disabled because they rely on Firebase Firestore
  /*
  /// Detect conflicts in expense
  Future<List<ConflictDetection>> detectExpenseConflicts(String tripId) async {
    try {
      final conflicts = <ConflictDetection>[];
      
      // Get local expenses
      final localExpenses = await _offlineService.getOfflineExpenses(tripId);
      
      // Get remote expenses
      final remoteQuery = await _firestore
          .collection('expenses')
          .where('tripId', isEqualTo: tripId)
          .get();
      
      final remoteExpenses = remoteQuery.docs
          .map((doc) => Expense.fromFirestore(doc))
          .toList();
      
      // Create maps for efficient lookup
      final localMap = {for (final expense in localExpenses) expense.id: expense};
      final remoteMap = {for (final expense in remoteExpenses) expense.id: expense};
      
      // Check for conflicts
      for (final localExpense in localExpenses) {
        final remoteExpense = remoteMap[localExpense.id];
        
        if (remoteExpense != null) {
          if (_hasConflict(localExpense, remoteExpense)) {
            conflicts.add(ConflictDetection(
              id: localExpense.id,
              type: ConflictType.dataConflict,
              localData: localExpense,
              remoteData: remoteExpense,
              conflictFields: _getConflictFields(localExpense, remoteExpense),
            ));
          }
        }
      }
      
      return conflicts;
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }
  */

  /// Check if expenses have conflicts
  bool _hasConflict(Expense local, Expense remote) {
    return local.title != remote.title ||
           local.amount != remote.amount ||
           local.category != remote.category || // Fixed: was categoryId
           local.description != remote.description ||
           local.status != remote.status;
  }

  /// Get conflicting fields
  List<String> _getConflictFields(Expense local, Expense remote) {
    final conflicts = <String>[];
    
    if (local.title != remote.title) conflicts.add('title');
    if (local.amount != remote.amount) conflicts.add('amount');
    if (local.category != remote.category) conflicts.add('category'); // Fixed: was categoryId
    if (local.description != remote.description) conflicts.add('description');
    if (local.status != remote.status) conflicts.add('status');
    
    return conflicts;
  }

  // Note: Firebase-dependent methods are commented out
  /*
  /// Apply conflict resolution
  Future<void> applyConflictResolution(ConflictResolution resolution) async {
    try {
      if (resolution.resolvedData == null) return;
      
      switch (resolution.type) {
        case ConflictType.localWins:
          // Update remote with local data
          await _firestore
              .collection('expenses')
              .doc(resolution.resolvedData!.id)
              .set((resolution.resolvedData! as Expense).toFirestore());
          break;
          
        case ConflictType.remoteWins:
          // Update local cache with remote data
          await _offlineService.cacheData(
            'expense_${resolution.resolvedData!.id}',
            (resolution.resolvedData! as Expense).toFirestore(),
          );
          break;
          
        case ConflictType.merged:
          // Update both local and remote with merged data
          await _firestore
              .collection('expenses')
              .doc(resolution.resolvedData!.id)
              .set((resolution.resolvedData! as Expense).toFirestore());
          
          await _offlineService.cacheData(
            'expense_${resolution.resolvedData!.id}',
            (resolution.resolvedData! as Expense).toFirestore(),
          );
          break;
          
        case ConflictType.keepBoth:
          // Create new document for duplicate
          await _firestore
              .collection('expenses')
              .doc(resolution.resolvedData!.id)
              .set((resolution.resolvedData! as Expense).toFirestore());
          
          // Keep remote data as well
          if (resolution.additionalData != null) {
            await _offlineService.cacheData(
              'expense_${(resolution.additionalData! as Expense).id}',
              (resolution.additionalData! as Expense).toFirestore(),
            );
          }
          break;
          
        case ConflictType.userChoice:
          // User choice should be handled by UI
          break;
          
        case ConflictType.dataConflict:
          // This is for detection only
          break;
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }
  */

  /// Get conflict resolution suggestions
  List<ConflictResolutionSuggestion> getResolutionSuggestions(ConflictDetection conflict) {
    final suggestions = <ConflictResolutionSuggestion>[];
    
    // Always suggest last write wins
    suggestions.add(ConflictResolutionSuggestion(
      strategy: ConflictResolutionStrategy.lastWriteWins,
      title: 'Use Most Recent Changes',
      description: 'Keep the version that was modified most recently',
      confidence: 0.8,
    ));
    
    // Suggest merge if fields don't overlap critically
    if (!conflict.conflictFields.contains('amount') || 
        !conflict.conflictFields.contains('payerId')) { // Fixed: was paidBy
      suggestions.add(ConflictResolutionSuggestion(
        strategy: ConflictResolutionStrategy.mergeChanges,
        title: 'Merge Changes',
        description: 'Combine changes from both versions intelligently',
        confidence: 0.7,
      ));
    }
    
    // Always suggest keep both
    suggestions.add(ConflictResolutionSuggestion(
      strategy: ConflictResolutionStrategy.keepBoth,
      title: 'Keep Both Versions',
      description: 'Create separate expenses for both versions',
      confidence: 0.6,
    ));
    
    // Suggest user choice for complex conflicts
    if (conflict.conflictFields.length > 2) {
      suggestions.add(ConflictResolutionSuggestion(
        strategy: ConflictResolutionStrategy.userChoice,
        title: 'Manual Resolution',
        description: 'Let user choose which changes to keep',
        confidence: 0.9,
      ));
    }
    
    return suggestions..sort((a, b) => b.confidence.compareTo(a.confidence));
  }
}

/// Conflict resolution model
class ConflictResolution {
  final ConflictType type;
  final dynamic localData;
  final dynamic remoteData;
  final dynamic resolvedData;
  final bool requiresUserInput;
  final dynamic additionalData;

  const ConflictResolution({
    required this.type,
    required this.localData,
    required this.remoteData,
    required this.resolvedData,
    required this.requiresUserInput,
    this.additionalData,
  });
}

/// Conflict detection model
class ConflictDetection {
  final String id;
  final ConflictType type;
  final dynamic localData;
  final dynamic remoteData;
  final List<String> conflictFields;

  const ConflictDetection({
    required this.id,
    required this.type,
    required this.localData,
    required this.remoteData,
    required this.conflictFields,
  });
}

/// Conflict resolution suggestion
class ConflictResolutionSuggestion {
  final ConflictResolutionStrategy strategy;
  final String title;
  final String description;
  final double confidence;

  const ConflictResolutionSuggestion({
    required this.strategy,
    required this.title,
    required this.description,
    required this.confidence,
  });
}

/// Enums
enum ConflictType {
  localWins,
  remoteWins,
  merged,
  keepBoth,
  userChoice,
  dataConflict,
}

enum ConflictResolutionStrategy {
  lastWriteWins,
  mergeChanges,
  userChoice,
  keepBoth,
}
