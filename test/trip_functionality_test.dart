import 'package:flutter_test/flutter_test.dart';
import 'package:group_trip_expense_splitter/data/datasources/database_service.dart';
import 'package:group_trip_expense_splitter/data/repositories/trip_repository.dart';
import 'package:group_trip_expense_splitter/data/models/trip.dart';
import 'package:group_trip_expense_splitter/data/models/trip_member.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('Trip Functionality Tests', () {
    late TripRepository repository;
    late DatabaseService databaseService;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Create in-memory database for testing
      databaseService = DatabaseService();
      repository = TripRepository(databaseService: databaseService);
    });

    group('Trip Creation', () {
      test('should create a trip with members successfully', () async {
        // Arrange
        final members = [
          TripMember.create(name: 'John Doe', phone: '1234567890'),
          TripMember.create(name: 'Jane Smith', phone: '2345678901'),
        ];

        // Act
        final trip = await repository.createTrip(
          name: 'Test Trip',
          startDate: DateTime(2024, 8, 15),
          endDate: DateTime(2024, 8, 20),
          members: members,
        );

        // Assert
        expect(trip.name, equals('Test Trip'));
        expect(trip.status, equals(TripStatus.planning));
        expect(trip.members.length, equals(2));
        expect(trip.members[0].name, equals('John Doe'));
        expect(trip.members[1].name, equals('Jane Smith'));
      });

      test('should validate trip data correctly', () async {
        // Test empty name
        String? error = repository.validateTrip(
          name: '',
          startDate: DateTime(2024, 8, 15),
          endDate: DateTime(2024, 8, 20),
          members: [TripMember.create(name: 'John', phone: '1234567890')],
        );
        expect(error, equals('Trip name is required'));

        // Test invalid dates
        error = repository.validateTrip(
          name: 'Test Trip',
          startDate: DateTime(2024, 8, 20),
          endDate: DateTime(2024, 8, 15),
          members: [TripMember.create(name: 'John', phone: '1234567890')],
        );
        expect(error, equals('Start date must be before end date'));

        // Test no members
        error = repository.validateTrip(
          name: 'Test Trip',
          startDate: DateTime(2024, 8, 15),
          endDate: DateTime(2024, 8, 20),
          members: [],
        );
        expect(error, equals('At least one member is required'));

        // Test duplicate phone numbers
        error = repository.validateTrip(
          name: 'Test Trip',
          startDate: DateTime(2024, 8, 15),
          endDate: DateTime(2024, 8, 20),
          members: [
            TripMember.create(name: 'John', phone: '1234567890'),
            TripMember.create(name: 'Jane', phone: '1234567890'),
          ],
        );
        expect(error, equals('Duplicate phone numbers are not allowed'));

        // Test valid data
        error = repository.validateTrip(
          name: 'Test Trip',
          startDate: DateTime(2024, 8, 15),
          endDate: DateTime(2024, 8, 20),
          members: [
            TripMember.create(name: 'John', phone: '1234567890'),
            TripMember.create(name: 'Jane', phone: '2345678901'),
          ],
        );
        expect(error, isNull);
      });
    });

    group('Trip Retrieval', () {
      test('should retrieve all trips', () async {
        // Arrange - Create multiple trips
        await repository.createTrip(
          name: 'Trip 1',
          startDate: DateTime(2024, 8, 15),
          endDate: DateTime(2024, 8, 20),
          members: [TripMember.create(name: 'John', phone: '1234567890')],
        );

        await repository.createTrip(
          name: 'Trip 2',
          startDate: DateTime(2024, 9, 15),
          endDate: DateTime(2024, 9, 20),
          members: [TripMember.create(name: 'Jane', phone: '2345678901')],
        );

        // Act
        final trips = await repository.getAllTrips();

        // Assert
        expect(trips.length, equals(2));
        expect(trips[0].name, equals('Trip 2')); // Newest first
        expect(trips[1].name, equals('Trip 1'));
      });

      test('should retrieve trip by ID', () async {
        // Arrange
        final createdTrip = await repository.createTrip(
          name: 'Test Trip',
          startDate: DateTime(2024, 8, 15),
          endDate: DateTime(2024, 8, 20),
          members: [TripMember.create(name: 'John', phone: '1234567890')],
        );

        // Act
        final retrievedTrip = await repository.getTripById(createdTrip.id);

        // Assert
        expect(retrievedTrip, isNotNull);
        expect(retrievedTrip!.id, equals(createdTrip.id));
        expect(retrievedTrip.name, equals('Test Trip'));
        expect(retrievedTrip.members.length, equals(1));
      });
    });

    group('Trip Status Management', () {
      test('should toggle trip status correctly', () async {
        // Arrange
        final trip = await repository.createTrip(
          name: 'Test Trip',
          startDate: DateTime(2024, 8, 15),
          endDate: DateTime(2024, 8, 20),
          members: [TripMember.create(name: 'John', phone: '1234567890')],
        );

        // Act - Toggle from planning to active
        await repository.toggleTripStatus(trip.id);
        final activeTrip = await repository.getTripById(trip.id);

        // Assert
        expect(activeTrip!.status, equals(TripStatus.active));

        // Act - Toggle back to planning
        await repository.toggleTripStatus(trip.id);
        final planningTrip = await repository.getTripById(trip.id);

        // Assert
        expect(planningTrip!.status, equals(TripStatus.planning));
      });

      test('should ensure only one trip is active at a time', () async {
        // Arrange - Create two trips
        final trip1 = await repository.createTrip(
          name: 'Trip 1',
          startDate: DateTime(2024, 8, 15),
          endDate: DateTime(2024, 8, 20),
          members: [TripMember.create(name: 'John', phone: '1234567890')],
        );

        final trip2 = await repository.createTrip(
          name: 'Trip 2',
          startDate: DateTime(2024, 9, 15),
          endDate: DateTime(2024, 9, 20),
          members: [TripMember.create(name: 'Jane', phone: '2345678901')],
        );

        // Act - Set trip1 as active
        await repository.setTripActive(trip1.id);
        
        // Act - Set trip2 as active
        await repository.setTripActive(trip2.id);

        // Assert - Only trip2 should be active
        final retrievedTrip1 = await repository.getTripById(trip1.id);
        final retrievedTrip2 = await repository.getTripById(trip2.id);
        final activeTrip = await repository.getActiveTrip();

        expect(retrievedTrip1!.status, equals(TripStatus.planning));
        expect(retrievedTrip2!.status, equals(TripStatus.active));
        expect(activeTrip!.id, equals(trip2.id));
      });
    });

    group('Member Management', () {
      test('should add member to trip', () async {
        // Arrange
        final trip = await repository.createTrip(
          name: 'Test Trip',
          startDate: DateTime(2024, 8, 15),
          endDate: DateTime(2024, 8, 20),
          members: [TripMember.create(name: 'John', phone: '1234567890')],
        );

        final newMember = TripMember.create(name: 'Jane', phone: '2345678901');

        // Act
        final updatedTrip = await repository.addMemberToTrip(trip.id, newMember);

        // Assert
        expect(updatedTrip.members.length, equals(2));
        expect(updatedTrip.members.any((m) => m.name == 'Jane'), isTrue);
      });

      test('should remove member from trip', () async {
        // Arrange
        final member1 = TripMember.create(name: 'John', phone: '1234567890');
        final member2 = TripMember.create(name: 'Jane', phone: '2345678901');
        
        final trip = await repository.createTrip(
          name: 'Test Trip',
          startDate: DateTime(2024, 8, 15),
          endDate: DateTime(2024, 8, 20),
          members: [member1, member2],
        );

        // Act
        final updatedTrip = await repository.removeMemberFromTrip(trip.id, member1.id);

        // Assert
        expect(updatedTrip.members.length, equals(1));
        expect(updatedTrip.members.first.name, equals('Jane'));
      });
    });

    group('Trip Statistics', () {
      test('should calculate trip statistics correctly', () async {
        // Arrange - Create trips with different statuses
        await repository.createTrip(
          name: 'Planning Trip',
          startDate: DateTime(2024, 8, 15),
          endDate: DateTime(2024, 8, 20),
          members: [TripMember.create(name: 'John', phone: '1234567890')],
        );

        final activeTrip = await repository.createTrip(
          name: 'Active Trip',
          startDate: DateTime(2024, 9, 15),
          endDate: DateTime(2024, 9, 20),
          members: [TripMember.create(name: 'Jane', phone: '2345678901')],
        );

        await repository.setTripActive(activeTrip.id);

        // Act
        final stats = await repository.getTripStats();

        // Assert
        expect(stats['total'], equals(2));
        expect(stats['planning'], equals(1));
        expect(stats['active'], equals(1));
        expect(stats['closed'], equals(0));
        expect(stats['archived'], equals(0));
      });
    });

    group('Trip Deletion', () {
      test('should delete trip and its members', () async {
        // Arrange
        final trip = await repository.createTrip(
          name: 'Test Trip',
          startDate: DateTime(2024, 8, 15),
          endDate: DateTime(2024, 8, 20),
          members: [
            TripMember.create(name: 'John', phone: '1234567890'),
            TripMember.create(name: 'Jane', phone: '2345678901'),
          ],
        );

        // Act
        await repository.deleteTrip(trip.id);

        // Assert
        final deletedTrip = await repository.getTripById(trip.id);
        final allTrips = await repository.getAllTrips();
        
        expect(deletedTrip, isNull);
        expect(allTrips.isEmpty, isTrue);
      });
    });
  });
}
