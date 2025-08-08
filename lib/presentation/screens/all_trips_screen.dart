import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../business_logic/providers/trip_providers.dart';
import '../../data/models/trip.dart';
import 'create_trip_screen.dart';

class AllTripsScreen extends ConsumerStatefulWidget {
  const AllTripsScreen({super.key});

  @override
  ConsumerState<AllTripsScreen> createState() => _AllTripsScreenState();
}

class _AllTripsScreenState extends ConsumerState<AllTripsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TripStatus? _selectedStatus;
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(allTripsProvider);
    final tripActions = ref.watch(tripActionsProvider);
    final tripStats = ref.watch(tripStatsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _showSearch ? _buildSearchField() : const Text(
          'All Trips',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: Colors.black87,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black87),
            onPressed: () => _navigateToCreateTrip(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Bar
          tripStats.when(
            data: (stats) => _buildStatsBar(stats),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Trips List
          Expanded(
            child: tripsAsync.when(
              data: (trips) {
                final filteredTrips = _filterTrips(trips);
                return filteredTrips.isEmpty
                    ? _buildEmptyState(context, trips.isNotEmpty)
                    : _buildTripsList(filteredTrips, tripActions, ref);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error.toString(), ref),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateTrip(context),
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search trips...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
      style: const TextStyle(color: Colors.black87, fontSize: 18),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildStatsBar(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', stats['total']?.toString() ?? '0', Colors.blue),
          _buildStatItem('Active', stats['active']?.toString() ?? '0', Colors.green),
          _buildStatItem('Planning', stats['planning']?.toString() ?? '0', Colors.orange),
          _buildStatItem('Ongoing', stats['ongoing']?.toString() ?? '0', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasTrips) {
    if (hasTrips) {
      // Filtered results are empty
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No trips found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedStatus = null;
                  _showSearch = false;
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      );
    }

    // No trips at all
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.luggage_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No trips yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first trip to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateTrip(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  List<Trip> _filterTrips(List<Trip> trips) {
    var filteredTrips = trips;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredTrips = filteredTrips.where((trip) {
        final query = _searchQuery.toLowerCase();
        return trip.name.toLowerCase().contains(query) ||
               (trip.destination?.toLowerCase().contains(query) ?? false) ||
               (trip.origin?.toLowerCase().contains(query) ?? false) ||
               (trip.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply status filter
    if (_selectedStatus != null) {
      filteredTrips = filteredTrips.where((trip) => trip.status == _selectedStatus).toList();
    }

    return filteredTrips;
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Trips'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filter by status:'),
            const SizedBox(height: 16),
            ...TripStatus.values.map((status) => RadioListTile<TripStatus?>(
              title: Text(_getStatusDisplayName(status)),
              value: status,
              groupValue: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
                Navigator.of(context).pop();
              },
            )),
            RadioListTile<TripStatus?>(
              title: const Text('All'),
              value: null,
              groupValue: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = null;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusDisplayName(TripStatus status) {
    switch (status) {
      case TripStatus.planning:
        return 'Planning';
      case TripStatus.active:
        return 'Active';
      case TripStatus.closed:
        return 'Closed';
      case TripStatus.archived:
        return 'Archived';
    }
  }

  Widget _buildTripsList(List<Trip> trips, TripActions tripActions, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allTripsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return _buildTripCard(trip, tripActions, ref);
        },
      ),
    );
  }

  Widget _buildTripCard(Trip trip, TripActions tripActions, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToEditTrip(context, trip.id),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (trip.description != null && trip.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            trip.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusToggle(trip, tripActions, ref),
                ],
              ),
              const SizedBox(height: 16),

              // Trip Details Row
              Row(
                children: [
                  // Dates
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${DateFormat('MMM dd').format(trip.startDate)} - ${DateFormat('MMM dd, yyyy').format(trip.endDate)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Duration
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${trip.durationInDays} day${trip.durationInDays != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              // Origin/Destination if available
              if (trip.origin != null || trip.destination != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _buildLocationText(trip),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Bottom Row: Members and Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Members Count
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${trip.members.length} member${trip.members.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  // Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _navigateToEditTrip(context, trip.id),
                        color: Colors.grey[600],
                        tooltip: 'Edit trip',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _showDeleteConfirmation(context, trip, tripActions),
                        color: Colors.grey[600],
                        tooltip: 'Delete trip',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildLocationText(Trip trip) {
    if (trip.origin != null && trip.destination != null) {
      return '${trip.origin} → ${trip.destination}';
    } else if (trip.origin != null) {
      return 'From ${trip.origin}';
    } else if (trip.destination != null) {
      return 'To ${trip.destination}';
    }
    return '';
  }

  Widget _buildStatusToggle(Trip trip, TripActions tripActions, WidgetRef ref) {
    final canToggle = trip.status == TripStatus.planning || trip.status == TripStatus.active;

    return Column(
      children: [
        Switch(
          value: trip.status == TripStatus.active,
          onChanged: canToggle
              ? (value) async {
                  try {
                    final result = await tripActions.toggleTripStatus(trip.id);
                    if (result != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result.isActive
                                ? 'Trip "${result.name}" is now active'
                                : 'Trip "${result.name}" is now in planning',
                          ),
                          backgroundColor: result.isActive ? Colors.green[600] : Colors.orange[600],
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating trip status: $e'),
                          backgroundColor: Colors.red[600],
                        ),
                      );
                    }
                  }
                }
              : null,
          activeColor: Colors.white,
          activeTrackColor: Colors.green,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey[300],
        ),
        Text(
          trip.isActive ? 'Active' : 'Planning',
          style: TextStyle(
            fontSize: 12,
            color: trip.isActive ? Colors.green[700] : Colors.orange[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(TripStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case TripStatus.planning:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        text = 'Planning';
        break;
      case TripStatus.active:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        text = 'Active';
        break;
      case TripStatus.closed:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        text = 'Closed';
        break;
      case TripStatus.archived:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[600]!;
        text = 'Archived';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => ref.invalidate(allTripsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateTrip(BuildContext context) async {
    final result = await Navigator.of(context).push<Trip>(
      MaterialPageRoute(
        builder: (context) => const CreateTripScreen(),
      ),
    );

    if (result != null && mounted) {
      // Trip was created successfully, refresh the list
      ref.invalidate(allTripsProvider);
      ref.invalidate(tripStatsProvider);
    }
  }

  void _navigateToEditTrip(BuildContext context, String tripId) async {
    final result = await Navigator.of(context).push<Trip>(
      MaterialPageRoute(
        builder: (context) => CreateTripScreen(tripId: tripId),
      ),
    );

    if (result != null && mounted) {
      // Trip was updated successfully, refresh the list
      ref.invalidate(allTripsProvider);
      ref.invalidate(tripStatsProvider);
    }
  }

  void _showDeleteConfirmation(BuildContext context, Trip trip, TripActions tripActions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${trip.name}"?'),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                final success = await tripActions.deleteTrip(trip.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Trip "${trip.name}" deleted successfully'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green[600],
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'Undo',
                        textColor: Colors.white,
                        onPressed: () async {
                          final restored = await tripActions.restoreTrip(trip.id);
                          if (restored != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Trip "${restored.name}" restored'),
                                backgroundColor: Colors.blue[600],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete trip "${trip.name}"'),
                      backgroundColor: Colors.red[600],
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting trip: $e'),
                      backgroundColor: Colors.red[600],
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
