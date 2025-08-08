import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../business_logic/providers/auth_providers.dart';
import '../../business_logic/providers/trip_providers.dart';
import '../../business_logic/providers/expense_providers.dart';
import '../../core/theme/design_tokens.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final activeTrip = ref.watch(activeTripProvider);
    final allTrips = ref.watch(allTripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Screen'),
        backgroundColor: DesignTokens.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current User Debug
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current User',
                      style: DesignTokens.headingMedium,
                    ),
                    const SizedBox(height: 8),
                    if (currentUser != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('✅ User loaded: ${currentUser!.displayName}'),
                          Text('ID: ${currentUser!.id}'),
                          Text('Email: ${currentUser!.email}'),
                          Text('Role: ${currentUser!.role}'),
                        ],
                      )
                    else
                      const Text('❌ No user loaded'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Active Trip Debug
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Trip',
                      style: DesignTokens.headingMedium,
                    ),
                    const SizedBox(height: 8),
                    activeTrip.when(
                      data: (trip) => trip != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('✅ Active trip loaded: ${trip.name}'),
                                Text('ID: ${trip.id}'),
                                Text('Status: ${trip.status}'),
                                Text('Members: ${trip.members.length}'),
                                Text('Budget: ${trip.budget}'),
                              ],
                            )
                          : const Text('❌ No active trip'),
                      loading: () => const Text('🔄 Loading active trip...'),
                      error: (error, stack) => Text('❌ Error: $error'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // All Trips Debug
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Trips',
                      style: DesignTokens.headingMedium,
                    ),
                    const SizedBox(height: 8),
                    allTrips.when(
                      data: (trips) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('✅ ${trips.length} trips loaded'),
                          ...trips.map((trip) => Padding(
                                padding: const EdgeInsets.only(left: 16, top: 4),
                                child: Text('• ${trip.name} (${trip.status})'),
                              )),
                        ],
                      ),
                      loading: () => const Text('🔄 Loading trips...'),
                      error: (error, stack) => Text('❌ Error: $error'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Actions',
                      style: DesignTokens.headingMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/create-trip');
                            },
                            child: const Text('Test Create Trip'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/add-expense');
                            },
                            child: const Text('Test Add Expense'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Refresh all providers
                          ref.invalidate(currentUserProvider);
                          ref.invalidate(activeTripProvider);
                          ref.invalidate(allTripsProvider);
                        },
                        child: const Text('Refresh All Data'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
