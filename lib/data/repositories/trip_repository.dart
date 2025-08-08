import 'package:uuid/uuid.dart';
import 'dart:async';
import '../models/trip.dart';
import '../models/trip_member.dart';
import '../datasources/database_service.dart';

/// Enhanced Trip Repository with SQLite integration, caching, and error handling
class TripRepository {
  final DatabaseService _databaseService;
  static const String _defaultAdminId = 'default_user'; // In a real app, this would come from auth

  // In-memory cache for better performance
  List<Trip>? _cachedTrips;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Stream controllers for real-time updates
  final StreamController<List<Trip>> _tripsStreamController = StreamController<List<Trip>>.broadcast();
  final StreamController<Trip> _tripUpdateStreamController = StreamController<Trip>.broadcast();

  TripRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  /// Stream of all trips for real-time updates
  Stream<List<Trip>> get tripsStream => _tripsStreamController.stream;

  /// Stream of individual trip updates
  Stream<Trip> get tripUpdateStream => _tripUpdateStreamController.stream;

  /// Dispose resources
  void dispose() {
    _tripsStreamController.close();
    _tripUpdateStreamController.close();
  }

  /// Create a new trip with enhanced error handling and caching
  Future<Trip> createTrip({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    List<TripMember> members = const [],
    String? origin,
    String? destination,
    String? description,
    String currency = 'INR',
    TripSettings? settings,
    double budgetAmount = 0.0,
  }) async {
    try {
      // Validate input data
      _validateTripData(name, startDate, endDate, members);

      final now = DateTime.now();
      final trip = Trip(
        id: const Uuid().v4(),
        name: name.trim(),
        description: description?.trim(),
        origin: origin?.trim(),
        destination: destination?.trim(),
        startDate: startDate,
        endDate: endDate,
        currency: currency,
        status: TripStatus.planning, // Always start as planning
        adminId: _defaultAdminId,
        members: members,
        createdAt: now,
        updatedAt: now,
        settings: settings ?? const TripSettings(),
        budgetAmount: budgetAmount,
        isDeleted: false,
      );

      // Save to database
      await _databaseService.createTrip(trip);

      // Update cache and notify listeners
      await _refreshCache();
      _tripUpdateStreamController.add(trip);

      return trip;
    } catch (e) {
      throw TripRepositoryException('Failed to create trip: ${e.toString()}');
    }
  }

  /// Validate trip data before creation/update
  void _validateTripData(String name, DateTime startDate, DateTime endDate, List<TripMember> members) {
    if (name.trim().isEmpty) {
      throw TripRepositoryException('Trip name cannot be empty');
    }

    if (startDate.isAfter(endDate)) {
      throw TripRepositoryException('Start date cannot be after end date');
    }

    if (endDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      throw TripRepositoryException('End date cannot be in the past');
    }

    // Validate members
    final phoneNumbers = <String>{};
    for (final member in members) {
      if (member.name.trim().isEmpty) {
        throw TripRepositoryException('Member name cannot be empty');
      }

      if (member.phone.length < 10) {
        throw TripRepositoryException('Invalid phone number: ${member.phone}');
      }

      if (phoneNumbers.contains(member.phone)) {
        throw TripRepositoryException('Duplicate phone number: ${member.phone}');
      }
      phoneNumbers.add(member.phone);
    }
  }

  /// Get all trips with caching and real-time updates
  Future<List<Trip>> getAllTrips({bool forceRefresh = false}) async {
    try {
      // Return cached data if valid and not forcing refresh
      if (!forceRefresh && _isCacheValid()) {
        return _cachedTrips!;
      }

      // Fetch from database
      final trips = await _databaseService.getAllTrips(includeDeleted: false);

      // Update cache
      _cachedTrips = trips;
      _lastCacheUpdate = DateTime.now();

      // Notify stream listeners
      _tripsStreamController.add(trips);

      return trips;
    } catch (e) {
      throw TripRepositoryException('Failed to get trips: ${e.toString()}');
    }
  }

  /// Get all trips including deleted ones (for admin purposes)
  Future<List<Trip>> getAllTripsIncludingDeleted() async {
    try {
      return await _databaseService.getAllTrips(includeDeleted: true);
    } catch (e) {
      throw TripRepositoryException('Failed to get all trips: ${e.toString()}');
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid() {
    return _cachedTrips != null &&
           _lastCacheUpdate != null &&
           DateTime.now().difference(_lastCacheUpdate!) < _cacheValidDuration;
  }

  /// Refresh cache from database
  Future<void> _refreshCache() async {
    _cachedTrips = null;
    _lastCacheUpdate = null;
    await getAllTrips();
  }

  /// Get a specific trip by ID with caching
  Future<Trip?> getTripById(String id) async {
    try {
      // Check cache first
      if (_cachedTrips != null) {
        final cachedTrip = _cachedTrips!.where((trip) => trip.id == id).firstOrNull;
        if (cachedTrip != null) {
          return cachedTrip;
        }
      }

      // Fetch from database
      return await _databaseService.getTripById(id);
    } catch (e) {
      throw TripRepositoryException('Failed to get trip: ${e.toString()}');
    }
  }

  /// Update an existing trip with validation and caching
  Future<Trip> updateTrip(Trip trip) async {
    try {
      // Validate trip data
      _validateTripData(trip.name, trip.startDate, trip.endDate, trip.members);

      final updatedTrip = trip.copyWith(
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateTrip(updatedTrip);

      // Update cache and notify listeners
      await _refreshCache();
      _tripUpdateStreamController.add(updatedTrip);

      return updatedTrip;
    } catch (e) {
      throw TripRepositoryException('Failed to update trip: ${e.toString()}');
    }
  }

  /// Soft delete a trip (mark as deleted)
  Future<void> deleteTrip(String id) async {
    try {
      final trip = await getTripById(id);
      if (trip == null) {
        throw TripRepositoryException('Trip not found');
      }

      final deletedTrip = trip.markAsDeleted();
      await _databaseService.updateTrip(deletedTrip);

      // Update cache and notify listeners
      await _refreshCache();
      _tripUpdateStreamController.add(deletedTrip);
    } catch (e) {
      throw TripRepositoryException('Failed to delete trip: ${e.toString()}');
    }
  }

  /// Permanently delete a trip (hard delete)
  Future<void> permanentlyDeleteTrip(String id) async {
    try {
      await _databaseService.deleteTrip(id);
      await _refreshCache();
    } catch (e) {
      throw TripRepositoryException('Failed to permanently delete trip: ${e.toString()}');
    }
  }

  /// Restore a deleted trip
  Future<Trip> restoreTrip(String id) async {
    try {
      final trip = await _databaseService.getTripById(id);
      if (trip == null) {
        throw TripRepositoryException('Trip not found');
      }

      final restoredTrip = trip.restore();
      await _databaseService.updateTrip(restoredTrip);

      // Update cache and notify listeners
      await _refreshCache();
      _tripUpdateStreamController.add(restoredTrip);

      return restoredTrip;
    } catch (e) {
      throw TripRepositoryException('Failed to restore trip: ${e.toString()}');
    }
  }

  /// Add a member to a trip with validation
  Future<Trip> addMemberToTrip(String tripId, TripMember member) async {
    try {
      final trip = await getTripById(tripId);
      if (trip == null) {
        throw TripRepositoryException('Trip not found');
      }

      // Validate member doesn't already exist
      final existingMember = trip.members.where((m) => m.phone == member.phone).firstOrNull;
      if (existingMember != null) {
        throw TripRepositoryException('Member with phone ${member.phone} already exists');
      }

      final updatedTrip = trip.addMember(member);
      return await updateTrip(updatedTrip);
    } catch (e) {
      throw TripRepositoryException('Failed to add member: ${e.toString()}');
    }
  }

  /// Remove a member from a trip
  Future<Trip> removeMemberFromTrip(String tripId, String memberId) async {
    try {
      final trip = await getTripById(tripId);
      if (trip == null) {
        throw TripRepositoryException('Trip not found');
      }

      // Check if member exists
      final memberExists = trip.members.any((m) => m.id == memberId);
      if (!memberExists) {
        throw TripRepositoryException('Member not found in trip');
      }

      final updatedTrip = trip.removeMember(memberId);
      return await updateTrip(updatedTrip);
    } catch (e) {
      throw TripRepositoryException('Failed to remove member: ${e.toString()}');
    }
  }

  /// Update a member in a trip
  Future<Trip> updateMemberInTrip(String tripId, TripMember updatedMember) async {
    try {
      final trip = await getTripById(tripId);
      if (trip == null) {
        throw TripRepositoryException('Trip not found');
      }

      final memberIndex = trip.members.indexWhere((m) => m.id == updatedMember.id);
      if (memberIndex == -1) {
        throw TripRepositoryException('Member not found in trip');
      }

      final updatedMembers = List<TripMember>.from(trip.members);
      updatedMembers[memberIndex] = updatedMember;

      final updatedTrip = trip.copyWith(members: updatedMembers);
      return await updateTrip(updatedTrip);
    } catch (e) {
      throw TripRepositoryException('Failed to update member: ${e.toString()}');
    }
  }

  /// Toggle trip status between planning and active with enhanced logic
  Future<Trip> toggleTripStatus(String tripId) async {
    try {
      final trip = await getTripById(tripId);
      if (trip == null) {
        throw TripRepositoryException('Trip not found');
      }

      TripStatus newStatus;
      switch (trip.status) {
        case TripStatus.planning:
          newStatus = TripStatus.active;
          break;
        case TripStatus.active:
          newStatus = TripStatus.planning;
          break;
        case TripStatus.closed:
        case TripStatus.archived:
          throw TripRepositoryException('Cannot toggle status of ${trip.status.name} trip');
      }

      await _databaseService.updateTripStatus(tripId, newStatus);

      // Get updated trip and refresh cache
      await _refreshCache();
      final updatedTrip = await getTripById(tripId);
      if (updatedTrip != null) {
        _tripUpdateStreamController.add(updatedTrip);
      }

      return updatedTrip!;
    } catch (e) {
      throw TripRepositoryException('Failed to toggle trip status: ${e.toString()}');
    }
  }

  /// Set a trip as active (and set all others as planning)
  Future<Trip> setTripActive(String tripId) async {
    try {
      await _databaseService.updateTripStatus(tripId, TripStatus.active);

      // Refresh cache and get updated trip
      await _refreshCache();
      final updatedTrip = await getTripById(tripId);
      if (updatedTrip != null) {
        _tripUpdateStreamController.add(updatedTrip);
      }

      return updatedTrip!;
    } catch (e) {
      throw TripRepositoryException('Failed to set trip active: ${e.toString()}');
    }
  }

  /// Get the currently active trip (if any)
  Future<Trip?> getActiveTrip() async {
    try {
      final trips = await getAllTrips();
      return trips.where((trip) => trip.status == TripStatus.active).firstOrNull;
    } catch (e) {
      throw TripRepositoryException('Failed to get active trip: ${e.toString()}');
    }
  }

  /// Search trips by name or destination
  Future<List<Trip>> searchTrips(String query) async {
    try {
      final trips = await getAllTrips();
      final lowercaseQuery = query.toLowerCase();

      return trips.where((trip) {
        return trip.name.toLowerCase().contains(lowercaseQuery) ||
               (trip.destination?.toLowerCase().contains(lowercaseQuery) ?? false) ||
               (trip.origin?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    } catch (e) {
      throw TripRepositoryException('Failed to search trips: ${e.toString()}');
    }
  }

  /// Get trips by status
  Future<List<Trip>> getTripsByStatus(TripStatus status) async {
    try {
      final trips = await getAllTrips();
      return trips.where((trip) => trip.status == status).toList();
    } catch (e) {
      throw TripRepositoryException('Failed to get trips by status: ${e.toString()}');
    }
  }

  /// Create a member from manual input
  TripMember createMember({
    required String name,
    required String phone,
    String? email,
  }) {
    return TripMember.create(
      name: name,
      phone: phone,
      email: email,
      isFromContacts: false,
    );
  }

  /// Create a member from contacts
  TripMember createMemberFromContact({
    required String name,
    required String phone,
    String? email,
    required String contactId,
  }) {
    return TripMember.create(
      name: name,
      phone: phone,
      email: email,
      contactId: contactId,
      isFromContacts: true,
    );
  }

  /// Get trip statistics with enhanced metrics
  Future<Map<String, dynamic>> getTripStats() async {
    try {
      final trips = await getAllTrips();
      final now = DateTime.now();

      return {
        'total': trips.length,
        'planning': trips.where((t) => t.status == TripStatus.planning).length,
        'active': trips.where((t) => t.status == TripStatus.active).length,
        'closed': trips.where((t) => t.status == TripStatus.closed).length,
        'archived': trips.where((t) => t.status == TripStatus.archived).length,
        'upcoming': trips.where((t) => t.startDate.isAfter(now)).length,
        'ongoing': trips.where((t) => t.isOngoing).length,
        'past': trips.where((t) => t.endDate.isBefore(now)).length,
        'totalMembers': trips.fold<int>(0, (sum, trip) => sum + trip.members.length),
        'averageMembersPerTrip': trips.isEmpty ? 0.0 : trips.fold<int>(0, (sum, trip) => sum + trip.members.length) / trips.length,
      };
    } catch (e) {
      throw TripRepositoryException('Failed to get trip statistics: ${e.toString()}');
    }
  }

  /// Get database performance statistics
  Map<String, dynamic> getDatabaseStats() {
    return _databaseService.getPerformanceStats();
  }

  /// Backup database
  Future<String> backupDatabase() async {
    try {
      return await _databaseService.backupDatabase();
    } catch (e) {
      throw TripRepositoryException('Failed to backup database: ${e.toString()}');
    }
  }

  /// Clear cache and force refresh
  Future<void> clearCache() async {
    _cachedTrips = null;
    _lastCacheUpdate = null;
    await getAllTrips(forceRefresh: true);
  }

  /// Check if repository has cached data
  bool get hasCachedData => _cachedTrips != null;

  /// Get cache age in minutes
  int get cacheAgeInMinutes {
    if (_lastCacheUpdate == null) return -1;
    return DateTime.now().difference(_lastCacheUpdate!).inMinutes;
  }
}

/// Custom exception for trip repository operations
class TripRepositoryException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const TripRepositoryException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() {
    return 'TripRepositoryException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}
