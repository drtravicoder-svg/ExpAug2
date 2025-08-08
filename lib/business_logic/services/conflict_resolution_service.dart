import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/error_handler.dart';
import '../../data/models/expense.dart';
import '../../data/models/trip.dart';
import 'offline_service.dart';

/// Service for handling data conflicts during synchronization
class ConflictResolutionService {
  final FirebaseFirestore _firestore;
  final OfflineService _offlineService;

  ConflictResolutionService({
    FirebaseFirestore? firestore,
    OfflineService? offlineService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
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
    final localModified = local.updatedAt ?? local.createdAt;
    final remoteModified = remote.updatedAt ?? remote.createdAt;
    
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
      title: _selectMostRecent(local.title, remote.title, local.updatedAt, remote.updatedAt),
      description: _selectMostRecent(local.description, remote.description, local.updatedAt, remote.updatedAt),
      amount: _selectMostRecent(local.amount, remote.amount, local.updatedAt, remote.updatedAt),
      categoryId: _selectMostRecent(local.categoryId, remote.categoryId, local.updatedAt, remote.updatedAt),
      paidBy: local.paidBy, // Keep original payer
      splitBetween: _mergeSplitBetween(local.splitBetween, remote.splitBetween),
      receiptUrl: local.receiptUrl ?? remote.receiptUrl, // Keep any receipt
      status: _mergeStatus(local.status, remote.status),
      createdAt: local.createdAt, // Keep original creation time
      updatedAt: DateTime.now(), // Set new update time
      approvedBy: _mergeApprovedBy(local.approvedBy, remote.approvedBy),
      rejectedBy: _mergeRejectedBy(local.rejectedBy, remote.rejectedBy),
      tags: _mergeTags(local.tags, remote.tags),
      location: local.location ?? remote.location,
      notes: local.notes ?? remote.notes,
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
  T _selectMostRecent<T>(T localValue, T remoteValue, DateTime? localTime, DateTime? remoteTime) {
    if (localTime == null && remoteTime == null) return localValue;
    if (localTime == null) return remoteValue;
    if (remoteTime == null) return localValue;
    
    return localTime.isAfter(remoteTime) ? localValue : remoteValue;
  }

  /// Merge split between maps
  Map<String, double> _mergeSplitBetween(Map<String, double> local, Map<String, double> remote) {
    final merged = <String, double>{};
    
    // Add all local entries
    merged.addAll(local);
    
    // Add remote entries that don't exist locally or have higher values
    for (final entry in remote.entries) {
      if (!merged.containsKey(entry.key) || merged[entry.key]! < entry.value) {
        merged[entry.key] = entry.value;
      }
    }
    
    return merged;
  }

  /// Merge expense status
  ExpenseStatus _mergeStatus(ExpenseStatus local, ExpenseStatus remote) {
    // Priority: committed > approved > pending > draft > rejected
    const statusPriority = {
      ExpenseStatus.committed: 5,
      ExpenseStatus.approved: 4,
      ExpenseStatus.pending: 3,
      ExpenseStatus.draft: 2,
      ExpenseStatus.rejected: 1,
    };
    
    final localPriority = statusPriority[local] ?? 0;
    final remotePriority = statusPriority[remote] ?? 0;
    
    return localPriority >= remotePriority ? local : remote;
  }

  /// Merge approved by lists
  List<String> _mergeApprovedBy(List<String> local, List<String> remote) {
    final merged = <String>{};
    merged.addAll(local);
    merged.addAll(remote);
    return merged.toList();
  }

  /// Merge rejected by lists
  List<String> _mergeRejectedBy(List<String> local, List<String> remote) {
    final merged = <String>{};
    merged.addAll(local);
    merged.addAll(remote);
    return merged.toList();
  }

  /// Merge tags
  List<String> _mergeTags(List<String> local, List<String> remote) {
    final merged = <String>{};
    merged.addAll(local);
    merged.addAll(remote);
    return merged.toList();
  }

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

  /// Check if expenses have conflicts
  bool _hasConflict(Expense local, Expense remote) {
    return local.title != remote.title ||
           local.amount != remote.amount ||
           local.categoryId != remote.categoryId ||
           local.description != remote.description ||
           local.status != remote.status ||
           !_mapsEqual(local.splitBetween, remote.splitBetween);
  }

  /// Get conflicting fields
  List<String> _getConflictFields(Expense local, Expense remote) {
    final conflicts = <String>[];
    
    if (local.title != remote.title) conflicts.add('title');
    if (local.amount != remote.amount) conflicts.add('amount');
    if (local.categoryId != remote.categoryId) conflicts.add('category');
    if (local.description != remote.description) conflicts.add('description');
    if (local.status != remote.status) conflicts.add('status');
    if (!_mapsEqual(local.splitBetween, remote.splitBetween)) conflicts.add('splitBetween');
    
    return conflicts;
  }

  /// Check if maps are equal
  bool _mapsEqual<K, V>(Map<K, V> map1, Map<K, V> map2) {
    if (map1.length != map2.length) return false;
    
    for (final entry in map1.entries) {
      if (!map2.containsKey(entry.key) || map2[entry.key] != entry.value) {
        return false;
      }
    }
    
    return true;
  }

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
        !conflict.conflictFields.contains('paidBy')) {
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
