import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../models/trip_member.dart';
import '../models/expense.dart';

/// Mock trip repository for testing without Firebase
class MockTripRepository {
  static final MockTripRepository _instance = MockTripRepository._internal();
  factory MockTripRepository() => _instance;
  MockTripRepository._internal();

  // Mock trips database
  final List<Trip> _trips = [];
  final StreamController<List<Trip>> _tripsController = StreamController<List<Trip>>.broadcast();
  final StreamController<Trip?> _activeTripController = StreamController<Trip?>.broadcast();

  /// Initialize with sample data
  Future<void> initialize() async {
    if (_trips.isEmpty) {
      _trips.addAll(_generateSampleTrips());
      _notifyListeners();

      if (kDebugMode) {
        print('🎭 Mock Trip Repository: Initialized with ${_trips.length} sample trips');
      }
    }
  }

  /// Force reload test data (clears existing and loads fresh)
  Future<void> initializeMockData() async {
    _trips.clear();
    _trips.addAll(_generateSampleTrips());
    _notifyListeners();

    if (kDebugMode) {
      print('🧪 Mock Trip Repository: Force loaded ${_trips.length} test trips');
    }
  }

  /// Get active trip stream
  Stream<Trip?> getActiveTrip() {
    return _activeTripController.stream.map((trip) {
      return _trips.where((t) => t.status == TripStatus.active).isNotEmpty
          ? _trips.firstWhere((t) => t.status == TripStatus.active)
          : null;
    });
  }

  /// Get all trips stream
  Stream<List<Trip>> getAllTrips() {
    return _tripsController.stream;
  }

  /// Get trip by ID stream
  Stream<Trip?> getTripById(String tripId) {
    return _tripsController.stream.map((trips) {
      try {
        return trips.firstWhere((trip) => trip.id == tripId);
      } catch (e) {
        return null;
      }
    });
  }

  /// Create trip
  Future<Trip> createTrip(Trip trip) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

    final newTrip = Trip(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      name: trip.name,
      origin: trip.origin,
      destination: trip.destination,
      startDate: trip.startDate,
      endDate: trip.endDate,
      currency: trip.currency,
      status: trip.status,
      adminId: trip.adminId,
      members: trip.members,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      settings: trip.settings,
    );

    // If creating as active, deactivate other trips
    if (newTrip.status == TripStatus.active) {
      for (int i = 0; i < _trips.length; i++) {
        if (_trips[i].status == TripStatus.active) {
          _trips[i] = _trips[i].updateStatus(TripStatus.closed);
        }
      }
    }

    _trips.insert(0, newTrip);
    _notifyListeners();

    if (kDebugMode) {
      print('🎭 Mock Trip Repository: Created trip "${newTrip.name}"');
    }

    return newTrip;
  }

  /// Update trip
  Future<void> updateTrip(Trip trip) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _trips.indexWhere((t) => t.id == trip.id);
    if (index != -1) {
      _trips[index] = Trip(
        id: trip.id,
        name: trip.name,
        origin: trip.origin,
        destination: trip.destination,
        startDate: trip.startDate,
        endDate: trip.endDate,
        currency: trip.currency,
        status: trip.status,
        adminId: trip.adminId,
        members: trip.members,
        createdAt: trip.createdAt,
        updatedAt: DateTime.now(),
        settings: trip.settings,
      );
      _notifyListeners();

      if (kDebugMode) {
        print('🎭 Mock Trip Repository: Updated trip "${trip.name}"');
      }
    }
  }

  /// Delete trip
  Future<void> deleteTrip(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    _trips.removeWhere((trip) => trip.id == tripId);
    _notifyListeners();
    
    if (kDebugMode) {
      print('🎭 Mock Trip Repository: Deleted trip $tripId');
    }
  }



  /// Get trips by status
  Stream<List<Trip>> getTripsByStatus(TripStatus status) {
    return _tripsController.stream.map((trips) {
      return trips.where((trip) => trip.status == status).toList();
    });
  }

  /// Activate trip (set as active, deactivate others)
  Future<void> activateTrip(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // First, deactivate all other trips
    for (int i = 0; i < _trips.length; i++) {
      if (_trips[i].status == TripStatus.active && _trips[i].id != tripId) {
        _trips[i] = _trips[i].updateStatus(TripStatus.planning);
      }
    }

    // Then activate the selected trip
    final index = _trips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      _trips[index] = _trips[index].updateStatus(TripStatus.active);
      _notifyListeners();

      if (kDebugMode) {
        print('🎭 Mock Trip Repository: Activated trip "${_trips[index].name}"');
      }
    }
  }

  /// Toggle trip status between planning and active
  Future<void> toggleTripStatus(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _trips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      final currentTrip = _trips[index];

      if (currentTrip.status == TripStatus.planning) {
        // Activate this trip (and deactivate others)
        await activateTrip(tripId);
      } else if (currentTrip.status == TripStatus.active) {
        // Deactivate this trip
        _trips[index] = currentTrip.updateStatus(TripStatus.planning);
        _notifyListeners();

        if (kDebugMode) {
          print('🎭 Mock Trip Repository: Deactivated trip "${currentTrip.name}"');
        }
      }
    }
  }

  void _notifyListeners() {
    _tripsController.add(List.from(_trips));
    final activeTrip = _trips.where((t) => t.status == TripStatus.active).isNotEmpty
        ? _trips.firstWhere((t) => t.status == TripStatus.active)
        : null;
    _activeTripController.add(activeTrip);
  }

  List<Trip> _generateSampleTrips() {
    final now = DateTime.now();
    return [
      Trip(
        id: 'trip_active_demo',
        name: 'Goa Beach Trip',
        origin: 'Mumbai',
        destination: 'Goa',
        startDate: now.add(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 14)),
        currency: 'INR',
        status: TripStatus.active,
        adminId: 'demo_user_1',
        members: [
          TripMember.create(name: 'John Doe', phone: '1234567890'),
          TripMember.create(name: 'Jane Smith', phone: '2345678901'),
        ],
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 1)),
        settings: TripSettings(),
      ),
      Trip(
        id: 'trip_planning_demo',
        name: 'Europe Backpacking',
        origin: 'Delhi',
        destination: 'Paris',
        startDate: now.add(const Duration(days: 60)),
        endDate: now.add(const Duration(days: 75)),
        currency: 'EUR',
        status: TripStatus.planning,
        adminId: 'demo_user_1',
        members: [
          TripMember.create(name: 'Alice Johnson', phone: '3456789012'),
        ],
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 2)),
        settings: TripSettings(),
      ),
      Trip(
        id: 'trip_completed_demo',
        name: 'Manali Adventure',
        origin: 'Delhi',
        destination: 'Manali',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.subtract(const Duration(days: 25)),
        currency: 'INR',
        status: TripStatus.closed,
        adminId: 'demo_user_1',
        members: [
          TripMember.create(name: 'Bob Wilson', phone: '4567890123'),
          TripMember.create(name: 'Carol Davis', phone: '5678901234'),
        ],
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 20)),
        settings: TripSettings(),
      ),
    ];
  }

  /// Dispose resources
  void dispose() {
    _tripsController.close();
    _activeTripController.close();
  }
}
