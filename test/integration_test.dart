import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import '../lib/data/datasources/database_service.dart';
import '../lib/data/repositories/trip_repository.dart';
import '../lib/data/models/trip.dart';
import '../lib/data/models/trip_member.dart';

/// Comprehensive integration test demonstrating SQLite functionality
/// This test simulates real user interactions with the Trip Creation app
void main() {
  late DatabaseService databaseService;
  late TripRepository tripRepository;

  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseService = DatabaseService();
    tripRepository = TripRepository(databaseService: databaseService);
    // Reset database for each test
    await databaseService.resetDatabase();
  });

  tearDown(() async {
    await databaseService.close();
  });

  group('🚀 Trip Creation App - Complete Integration Tests', () {
    test('📱 Complete User Journey: Create → View → Edit → Delete Trip', () async {
      print('\n🎯 Starting Complete User Journey Test...\n');

      // 1. Create a trip with members (simulating Create Trip screen)
      print('1️⃣ Creating trip with members...');
      final trip = await tripRepository.createTrip(
        name: 'Summer Vacation 2024',
        description: 'Family trip to the mountains',
        origin: 'San Francisco',
        destination: 'Lake Tahoe',
        startDate: DateTime.now().add(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 37)),
        currency: 'USD',
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
        budgetAmount: 2500.0,
      );

      expect(trip.name, equals('Summer Vacation 2024'));
      expect(trip.members.length, equals(2));
      expect(trip.budgetAmount, equals(2500.0));
      print('✅ Trip created successfully: ${trip.name}');

      // 2. Retrieve all trips (simulating All Trips screen)
      print('\n2️⃣ Retrieving all trips...');
      final allTrips = await tripRepository.getAllTrips();
      expect(allTrips.length, equals(1));
      expect(allTrips.first.name, equals('Summer Vacation 2024'));
      print('✅ Retrieved ${allTrips.length} trip(s)');

      // 3. Set trip as active (simulating toggle in All Trips screen)
      print('\n3️⃣ Setting trip as active...');
      await tripRepository.setTripActive(trip.id);
      final activeTrip = await tripRepository.getActiveTrip();
      expect(activeTrip, isNotNull);
      expect(activeTrip!.isActive, isTrue);
      print('✅ Trip is now active');

      // 4. Add another member (simulating Add Member dialog)
      print('\n4️⃣ Adding another member...');
      final newMember = TripMember.create(
        name: 'Bob Wilson',
        phone: '3456789012',
        email: 'bob@example.com',
      );
      final updatedTrip = await tripRepository.addMemberToTrip(trip.id, newMember);
      expect(updatedTrip.members.length, equals(3));
      print('✅ Added member: ${newMember.name}');

      // 5. Search trips (simulating search functionality)
      print('\n5️⃣ Testing search functionality...');
      final searchResults = await tripRepository.searchTrips('Summer');
      expect(searchResults.length, equals(1));
      expect(searchResults.first.name, contains('Summer'));
      print('✅ Search found ${searchResults.length} result(s)');

      // 6. Get trip statistics (simulating stats dashboard)
      print('\n6️⃣ Getting trip statistics...');
      final stats = await tripRepository.getTripStats();
      expect(stats['total'], equals(1));
      expect(stats['active'], equals(1));
      expect(stats['totalMembers'], equals(3));
      print('✅ Statistics: ${stats['total']} total, ${stats['active']} active, ${stats['totalMembers']} members');

      // 7. Create second trip to test single active constraint
      print('\n7️⃣ Testing single active trip constraint...');
      final secondTrip = await tripRepository.createTrip(
        name: 'Winter Ski Trip',
        startDate: DateTime.now().add(const Duration(days: 60)),
        endDate: DateTime.now().add(const Duration(days: 67)),
        members: [
          TripMember.create(name: 'Alice Brown', phone: '4567890123'),
        ],
      );
      
      // Set second trip as active
      await tripRepository.setTripActive(secondTrip.id);
      
      // Verify only second trip is active
      final allTripsAfterToggle = await tripRepository.getAllTrips();
      final activeTrips = allTripsAfterToggle.where((t) => t.isActive).toList();
      expect(activeTrips.length, equals(1));
      expect(activeTrips.first.id, equals(secondTrip.id));
      print('✅ Single active trip constraint working correctly');

      // 8. Test soft delete and restore
      print('\n8️⃣ Testing soft delete and restore...');
      await tripRepository.deleteTrip(trip.id);
      
      final tripsAfterDelete = await tripRepository.getAllTrips();
      expect(tripsAfterDelete.length, equals(1)); // Only second trip visible
      
      final restoredTrip = await tripRepository.restoreTrip(trip.id);
      expect(restoredTrip, isNotNull);
      
      final tripsAfterRestore = await tripRepository.getAllTrips();
      expect(tripsAfterRestore.length, equals(2));
      print('✅ Soft delete and restore working correctly');

      // 9. Test database backup and performance
      print('\n9️⃣ Testing database backup and performance...');
      final backupPath = await tripRepository.backupDatabase();
      expect(backupPath, isNotEmpty);
      
      final dbStats = tripRepository.getDatabaseStats();
      expect(dbStats['queryCount'], greaterThan(0));
      print('✅ Database backup created: ${backupPath.split('/').last}');
      print('✅ Performance stats: ${dbStats['queryCount']} queries executed');

      print('\n🎉 Complete User Journey Test PASSED! All functionality working correctly.\n');
    });

    test('🔄 Real-time Data Synchronization Test', () async {
      print('\n🎯 Testing Real-time Data Synchronization...\n');

      // Create initial trip
      final trip = await tripRepository.createTrip(
        name: 'Sync Test Trip',
        startDate: DateTime.now().add(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 37)),
        members: [
          TripMember.create(name: 'Test User', phone: '1111111111'),
        ],
      );

      // Test stream updates (simulating real-time UI updates)
      final streamUpdates = <List<Trip>>[];
      final subscription = tripRepository.tripsStream.listen((trips) {
        streamUpdates.add(trips);
      });

      // Trigger updates
      await tripRepository.setTripActive(trip.id);
      await Future.delayed(const Duration(milliseconds: 100));
      
      await tripRepository.addMemberToTrip(
        trip.id, 
        TripMember.create(name: 'New Member', phone: '2222222222'),
      );
      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      expect(streamUpdates.length, greaterThan(0));
      print('✅ Real-time stream updates working: ${streamUpdates.length} updates received');
    });

    test('📊 Performance and Scalability Test', () async {
      print('\n🎯 Testing Performance and Scalability...\n');

      final stopwatch = Stopwatch()..start();

      // Create multiple trips with members
      for (int i = 1; i <= 10; i++) {
        await tripRepository.createTrip(
          name: 'Performance Test Trip $i',
          startDate: DateTime.now().add(Duration(days: i * 7)),
          endDate: DateTime.now().add(Duration(days: i * 7 + 5)),
          members: List.generate(3, (j) => TripMember.create(
            name: 'Member ${i}_$j',
            phone: '${i}${j}${i}${j}${i}${j}${i}${j}${i}${j}',
          )),
        );
      }

      stopwatch.stop();
      final creationTime = stopwatch.elapsedMilliseconds;

      // Test retrieval performance
      stopwatch.reset();
      stopwatch.start();
      
      final allTrips = await tripRepository.getAllTrips();
      
      stopwatch.stop();
      final retrievalTime = stopwatch.elapsedMilliseconds;

      expect(allTrips.length, equals(10));
      expect(creationTime, lessThan(5000)); // Should complete in under 5 seconds
      expect(retrievalTime, lessThan(1000)); // Should retrieve in under 1 second

      print('✅ Created 10 trips with 30 members in ${creationTime}ms');
      print('✅ Retrieved all trips in ${retrievalTime}ms');
      print('✅ Performance test PASSED!');
    });
  });
}
