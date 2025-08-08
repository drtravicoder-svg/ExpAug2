import 'package:flutter/material.dart';
import 'data/models/trip.dart';
import 'data/models/trip_member.dart';

void main() {
  runApp(const TripManagementDemo());
}

class TripManagementDemo extends StatelessWidget {
  const TripManagementDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Management Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AllTripsScreen(),
    );
  }
}

class AllTripsScreen extends StatefulWidget {
  const AllTripsScreen({super.key});

  @override
  State<AllTripsScreen> createState() => _AllTripsScreenState();
}

class _AllTripsScreenState extends State<AllTripsScreen> {
  List<Trip> trips = [];

  @override
  void initState() {
    super.initState();
    _loadSampleTrips();
  }

  void _loadSampleTrips() {
    final now = DateTime.now();
    trips = [
      Trip(
        id: 'trip1',
        name: 'Goa Beach Trip',
        startDate: now.add(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 14)),
        currency: 'INR',
        status: TripStatus.active,
        adminId: 'user1',
        members: [
          TripMember(id: '1', name: 'John Doe', phone: '1234567890'),
          TripMember(id: '2', name: 'Jane Smith', phone: '2345678901'),
        ],
        createdAt: now,
        updatedAt: now,
        settings: TripSettings(),
      ),
      Trip(
        id: 'trip2',
        name: 'Europe Backpacking',
        startDate: now.add(const Duration(days: 60)),
        endDate: now.add(const Duration(days: 75)),
        currency: 'EUR',
        status: TripStatus.planning,
        adminId: 'user1',
        members: [
          TripMember(id: '3', name: 'Alice Johnson', phone: '3456789012'),
        ],
        createdAt: now,
        updatedAt: now,
        settings: TripSettings(),
      ),
      Trip(
        id: 'trip3',
        name: 'Tokyo Adventure',
        startDate: now.add(const Duration(days: 120)),
        endDate: now.add(const Duration(days: 130)),
        currency: 'JPY',
        status: TripStatus.planning,
        adminId: 'user1',
        members: [
          TripMember(id: '4', name: 'Bob Wilson', phone: '4567890123'),
          TripMember(id: '5', name: 'Carol Davis', phone: '5678901234'),
          TripMember(id: '6', name: 'David Brown', phone: '6789012345'),
        ],
        createdAt: now,
        updatedAt: now,
        settings: TripSettings(),
      ),
    ];
  }

  void _toggleTripStatus(int index) {
    setState(() {
      final trip = trips[index];
      if (trip.status == TripStatus.planning) {
        // Activate this trip and deactivate others
        for (int i = 0; i < trips.length; i++) {
          if (i == index) {
            trips[i] = trips[i].updateStatus(TripStatus.active);
          } else if (trips[i].status == TripStatus.active) {
            trips[i] = trips[i].updateStatus(TripStatus.planning);
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Activated trip: ${trip.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (trip.status == TripStatus.active) {
        trips[index] = trip.updateStatus(TripStatus.planning);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏸️ Trip set to planning: ${trip.name}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  void _showCreateTripDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Trip'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Create Trip functionality has been implemented in the main app with:',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              '• Trip name input\n• Date selection\n• Member management\n• Active status toggle',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Trips'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Only one trip can be active at a time. Toggle status using the switch.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          
          // Trips List
          Expanded(
            child: trips.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.luggage, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No trips yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap the + button to create your first trip',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      final isActive = trip.status == TripStatus.active;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: isActive ? Colors.blue : Colors.white,
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      trip.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isActive ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.white24 : Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      trip.status.toString().split('.').last.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isActive ? Colors.white : Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Status Toggle
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.white10 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      trip.status == TripStatus.active ? 'Active Trip' : 'Planning',
                                      style: TextStyle(
                                        color: isActive ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Switch(
                                      value: trip.status == TripStatus.active,
                                      onChanged: (value) => _toggleTripStatus(index),
                                      activeColor: isActive ? Colors.white : Colors.green,
                                      activeTrackColor: isActive ? Colors.white24 : Colors.green.shade200,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Members
                              Text(
                                'Members (${trip.members.length})',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isActive ? Colors.white70 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...trip.members.map((member) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: isActive ? Colors.white24 : Colors.grey.shade300,
                                      child: Icon(
                                        Icons.person,
                                        size: 16,
                                        color: isActive ? Colors.white : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${member.name} - ${member.formattedPhone}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isActive ? Colors.white70 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTripDialog,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Trip'),
      ),
    );
  }
}
