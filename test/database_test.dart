import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import '../lib/data/datasources/database_service.dart';
import '../lib/data/models/trip.dart';
import '../lib/data/models/trip_member.dart';

void main() {
  late DatabaseService databaseService;

  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseService = DatabaseService();
    // Reset database for each test
    await databaseService.resetDatabase();
  });

  tearDown(() async {
    await databaseService.close();
  });

  group('Enhanced SQLite Database Tests', () {
    test('should create database with all tables and indexes', () async {
      final db = await databaseService.database;
      
      // Check if all tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      
      final tableNames = tables.map((t) => t['name']).toList();
      
      expect(tableNames, contains('trips'));
      expect(tableNames, contains('trip_members'));
      expect(tableNames, contains('expenses'));
      expect(tableNames, contains('expense_splits'));
      expect(tableNames, contains('receipts'));
    });

    test('should enforce foreign key constraints', () async {
      final db = await databaseService.database;
      
      // Check if foreign keys are enabled
      final result = await db.rawQuery('PRAGMA foreign_keys');
      expect(result.first['foreign_keys'], equals(1));
    });

    test('should create trip with members in transaction', () async {
      final trip = Trip(
        id: const Uuid().v4(),
        name: 'Test Trip',
        description: 'A test trip for SQLite',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        currency: 'USD',
        status: TripStatus.planning,
        adminId: 'admin123',
        members: [
          TripMember.create(
            name: 'John Doe',
            phone: '1234567890',
            email: 'john@example.com',
          ),
          TripMember.create(
            name: 'Jane Smith',
            phone: '2345678901',
            email: 'jane@example.com',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        settings: const TripSettings(
          allowMemberCategories: true,
          requireReceiptApproval: false,
        ),
        budgetAmount: 1000.0,
      );

      final tripId = await databaseService.createTrip(trip);
      expect(tripId, equals(trip.id));

      // Verify trip was created
      final retrievedTrip = await databaseService.getTripById(tripId);
      expect(retrievedTrip, isNotNull);
      expect(retrievedTrip!.name, equals('Test Trip'));
      expect(retrievedTrip.members.length, equals(2));
      expect(retrievedTrip.budgetAmount, equals(1000.0));
    });

    test('should enforce single active trip constraint', () async {
      // Create first trip
      final trip1 = Trip(
        id: const Uuid().v4(),
        name: 'Trip 1',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        currency: 'USD',
        status: TripStatus.active,
        adminId: 'admin123',
        members: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        settings: const TripSettings(),
      );

      await databaseService.createTrip(trip1);

      // Create second trip and set it to active
      final trip2 = Trip(
        id: const Uuid().v4(),
        name: 'Trip 2',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        currency: 'USD',
        status: TripStatus.planning,
        adminId: 'admin123',
        members: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        settings: const TripSettings(),
      );

      await databaseService.createTrip(trip2);
      await databaseService.updateTripStatus(trip2.id, TripStatus.active);

      // Verify only trip2 is active
      final trips = await databaseService.getAllTrips();
      final activeTrips = trips.where((t) => t.isActive).toList();
      
      expect(activeTrips.length, equals(1));
      expect(activeTrips.first.id, equals(trip2.id));
    });

    test('should handle database migrations', () async {
      // This test verifies that the migration system works
      final db = await databaseService.database;
      
      // Check if new columns exist (added in version 2)
      final tripColumns = await db.rawQuery('PRAGMA table_info(trips)');
      final columnNames = tripColumns.map((c) => c['name']).toList();
      
      expect(columnNames, contains('budget_amount'));
      expect(columnNames, contains('is_deleted'));
      expect(columnNames, contains('description'));
    });

    test('should perform database backup and restore', () async {
      // Create a trip
      final trip = Trip(
        id: const Uuid().v4(),
        name: 'Backup Test Trip',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        currency: 'USD',
        status: TripStatus.planning,
        adminId: 'admin123',
        members: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        settings: const TripSettings(),
      );

      await databaseService.createTrip(trip);

      // Create backup
      final backupPath = await databaseService.backupDatabase();
      expect(backupPath, isNotEmpty);

      // Clear database
      await databaseService.resetDatabase();
      
      // Verify trip is gone
      final tripsAfterReset = await databaseService.getAllTrips();
      expect(tripsAfterReset.length, equals(0));

      // Restore from backup
      await databaseService.restoreDatabase(backupPath);

      // Verify trip is back
      final tripsAfterRestore = await databaseService.getAllTrips();
      expect(tripsAfterRestore.length, equals(1));
      expect(tripsAfterRestore.first.name, equals('Backup Test Trip'));
    });

    test('should check database integrity', () async {
      final isIntegrityOk = await databaseService.checkIntegrity();
      expect(isIntegrityOk, isTrue);
    });

    test('should get performance statistics', () async {
      // Perform some operations to generate stats
      await databaseService.getAllTrips();
      
      final stats = databaseService.getPerformanceStats();
      expect(stats['queryCount'], greaterThan(0));
      expect(stats['databaseVersion'], equals(2));
    });

    test('should handle soft delete for trips', () async {
      final trip = Trip(
        id: const Uuid().v4(),
        name: 'Delete Test Trip',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        currency: 'USD',
        status: TripStatus.planning,
        adminId: 'admin123',
        members: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        settings: const TripSettings(),
      );

      await databaseService.createTrip(trip);

      // Mark as deleted
      final deletedTrip = trip.markAsDeleted();
      await databaseService.updateTrip(deletedTrip);

      // Should not appear in normal queries
      final activeTrips = await databaseService.getAllTrips();
      expect(activeTrips.length, equals(0));

      // Should appear when including deleted
      final allTrips = await databaseService.getAllTrips(includeDeleted: true);
      expect(allTrips.length, equals(1));
      expect(allTrips.first.isDeleted, isTrue);
    });

    test('should validate data constraints', () async {
      final db = await databaseService.database;

      // Test invalid trip data (empty name should fail)
      expect(
        () async => await db.insert('trips', {
          'id': 'test',
          'name': '', // Empty name should fail CHECK constraint
          'start_date': DateTime.now().toIso8601String(),
          'end_date': DateTime.now().toIso8601String(),
          'currency': 'USD',
          'admin_id': 'admin',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }),
        throwsA(isA<Exception>()),
      );
    });
  });
}
