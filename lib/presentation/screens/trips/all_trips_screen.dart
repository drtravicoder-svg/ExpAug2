import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../business_logic/providers/trip_providers.dart';
import '../../../business_logic/providers/expense_providers.dart';
import '../../../data/models/trip.dart';
import '../../../data/models/expense.dart';
import '../../widgets/common/animated_card.dart';
import '../../widgets/common/loading_widgets.dart';

// Filter and sort options
enum TripFilter { all, active, completed, planning }
enum TripSort { newest, oldest, name, totalExpenses }

class AllTripsScreen extends ConsumerStatefulWidget {
  const AllTripsScreen({super.key});

  @override
  ConsumerState<AllTripsScreen> createState() => _AllTripsScreenState();
}

class _AllTripsScreenState extends ConsumerState<AllTripsScreen> with TickerProviderStateMixin {
  TripFilter _currentFilter = TripFilter.all;
  TripSort _currentSort = TripSort.newest;
  String _searchQuery = '';
  late AnimationController _filterAnimationController;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTrips = ref.watch(allTripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Trips'),
        backgroundColor: DesignTokens.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/debug'),
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug',
          ),
          IconButton(
            onPressed: () {
              _showSearchDialog(context);
            },
            icon: const Icon(Icons.search),
            tooltip: 'Search trips',
          ),
          IconButton(
            onPressed: () {
              _showFilterBottomSheet(context);
            },
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter and sort',
          ),
          IconButton(
            onPressed: () {
              ref.invalidate(allTripsProvider);
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          if (_searchQuery.isNotEmpty || _currentFilter != TripFilter.all)
            AnimatedCard(
              margin: const EdgeInsets.all(DesignTokens.spacing16),
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.spacing12),
                child: Row(
                  children: [
                    if (_searchQuery.isNotEmpty) ...[
                      Chip(
                        label: Text('Search: $_searchQuery'),
                        onDeleted: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        deleteIcon: const Icon(Icons.close, size: 16),
                      ),
                      const SizedBox(width: DesignTokens.spacing8),
                    ],
                    if (_currentFilter != TripFilter.all) ...[
                      Chip(
                        label: Text('Filter: ${_getFilterLabel(_currentFilter)}'),
                        onDeleted: () {
                          setState(() {
                            _currentFilter = TripFilter.all;
                          });
                        },
                        deleteIcon: const Icon(Icons.close, size: 16),
                      ),
                      const SizedBox(width: DesignTokens.spacing8),
                    ],
                    const Spacer(),
                    Text(
                      'Sort: ${_getSortLabel(_currentSort)}',
                      style: DesignTokens.bodySmall.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Info Banner
          AnimatedCard(
            margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.spacing16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(DesignTokens.borderRadius12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  const SizedBox(width: DesignTokens.spacing12),
                  Expanded(
                    child: Text(
                      'Only one trip can be active at a time',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: DesignTokens.spacing16),
          
          // Trips List
          Expanded(
            child: allTrips.when(
              data: (trips) {
                final filteredTrips = _filterAndSortTrips(trips);

                if (trips.isEmpty) {
                  return const _EmptyTripsState();
                }

                if (filteredTrips.isEmpty) {
                  return _buildNoResultsState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allTripsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing16),
                    itemCount: filteredTrips.length,
                    itemBuilder: (context, index) {
                      final trip = filteredTrips[index];
                      return AnimatedCard(
                        margin: const EdgeInsets.only(bottom: DesignTokens.spacing16),
                        child: EnhancedTripCard(trip: trip),
                      );
                    },
                  ),
                );
              },
              loading: () => const ShimmerLoading(
                child: _TripsListSkeleton(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: DesignTokens.spacing16),
                    Text(
                      'Error loading trips',
                      style: DesignTokens.headingSmall.copyWith(color: Colors.red),
                    ),
                    const SizedBox(height: DesignTokens.spacing8),
                    Text(
                      error.toString(),
                      style: DesignTokens.bodyMedium.copyWith(color: DesignTokens.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.spacing16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(allTripsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/create-trip');
        },
        backgroundColor: DesignTokens.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Trip'),
      ),
    );
  }

  List<Trip> _filterAndSortTrips(List<Trip> trips) {
    var filteredTrips = trips.where((trip) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!trip.name.toLowerCase().contains(query) &&
            !(trip.destination?.toLowerCase().contains(query) ?? false) &&
            !(trip.origin?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Apply status filter
      switch (_currentFilter) {
        case TripFilter.all:
          return true;
        case TripFilter.active:
          return trip.status == TripStatus.active;
        case TripFilter.completed:
          return trip.status == TripStatus.closed;
        case TripFilter.planning:
          return trip.status == TripStatus.planning;
      }
    }).toList();

    // Apply sorting
    switch (_currentSort) {
      case TripSort.newest:
        filteredTrips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case TripSort.oldest:
        filteredTrips.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case TripSort.name:
        filteredTrips.sort((a, b) => a.name.compareTo(b.name));
        break;
      case TripSort.totalExpenses:
        // TODO: Sort by actual total expenses when available
        filteredTrips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filteredTrips;
  }

  String _getFilterLabel(TripFilter filter) {
    switch (filter) {
      case TripFilter.all:
        return 'All';
      case TripFilter.active:
        return 'Active';
      case TripFilter.completed:
        return 'Completed';
      case TripFilter.planning:
        return 'Planning';
    }
  }

  String _getSortLabel(TripSort sort) {
    switch (sort) {
      case TripSort.newest:
        return 'Newest First';
      case TripSort.oldest:
        return 'Oldest First';
      case TripSort.name:
        return 'Name A-Z';
      case TripSort.totalExpenses:
        return 'Total Expenses';
    }
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 80,
            color: DesignTokens.textSecondary,
          ),
          const SizedBox(height: DesignTokens.spacing24),
          Text(
            'No trips found',
            style: DesignTokens.headingSmall.copyWith(
              color: DesignTokens.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing8),
          Text(
            'Try adjusting your search or filters',
            style: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _currentFilter = TripFilter.all;
              });
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Trips'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter trip name, origin, or destination',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value.trim();
            });
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignTokens.spacing20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter & Sort',
              style: DesignTokens.headingSmall,
            ),
            const SizedBox(height: DesignTokens.spacing20),

            // Filter options
            Text(
              'Filter by Status',
              style: DesignTokens.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing12),
            Wrap(
              spacing: DesignTokens.spacing8,
              children: TripFilter.values.map((filter) {
                return FilterChip(
                  label: Text(_getFilterLabel(filter)),
                  selected: _currentFilter == filter,
                  onSelected: (selected) {
                    setState(() {
                      _currentFilter = filter;
                    });
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: DesignTokens.spacing20),

            // Sort options
            Text(
              'Sort by',
              style: DesignTokens.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing12),
            Wrap(
              spacing: DesignTokens.spacing8,
              children: TripSort.values.map((sort) {
                return FilterChip(
                  label: Text(_getSortLabel(sort)),
                  selected: _currentSort == sort,
                  onSelected: (selected) {
                    setState(() {
                      _currentSort = sort;
                    });
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: DesignTokens.spacing20),
          ],
        ),
      ),
    );
  }
}

class EnhancedTripCard extends ConsumerWidget {
  final Trip trip;

  const EnhancedTripCard({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = trip.status == TripStatus.active;
    final cardColor = isActive ? DesignTokens.primaryColor : DesignTokens.surfaceColor;
    final textColor = isActive ? Colors.white : DesignTokens.textPrimary;
    final subtitleColor = isActive ? Colors.white70 : DesignTokens.textSecondary;

    return Card(
      color: cardColor,
      elevation: DesignTokens.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.name,
                        style: DesignTokens.header.copyWith(
                          color: textColor,
                          fontSize: 20,
                        ),
                      ),
                      if (trip.origin != null && trip.destination != null)
                        Text(
                          '${trip.origin} → ${trip.destination}',
                          style: DesignTokens.subtitle.copyWith(
                            color: subtitleColor,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white24 : DesignTokens.primaryBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    trip.status.name.toUpperCase(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Toggle (only show for planning/active trips)
            if (trip.status == TripStatus.planning || trip.status == TripStatus.active)
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
                        color: isActive ? Colors.white : DesignTokens.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: trip.status == TripStatus.active,
                      onChanged: (value) async {
                        final repository = ref.read(tripRepositoryProvider);
                        try {
                          await repository.toggleTripStatus(trip.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                    ? '✅ Trip activated: ${trip.name}'
                                    : '⏸️ Trip set to planning: ${trip.name}',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Failed to update trip status: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      activeColor: isActive ? Colors.white : Colors.green,
                      activeTrackColor: isActive ? Colors.white24 : Colors.green.shade200,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Trip dates
            Text(
              DateFormatter.formatDateRange(trip.startDate, trip.endDate),
              style: DesignTokens.subtitle.copyWith(
                color: subtitleColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Stats row with real data
            Consumer(
              builder: (context, ref, child) {
                final tripStats = ref.watch(tripStatsProvider(trip.id));
                return tripStats.when(
                  data: (stats) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatItem(
                        icon: Icons.attach_money,
                        value: CurrencyFormatter.formatCompact(stats.totalExpenses, trip.currency),
                        label: 'Total Expenses',
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      _StatItem(
                        icon: Icons.people,
                        value: '${stats.memberCount}',
                        label: 'Members',
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      _StatItem(
                        icon: Icons.receipt_long,
                        value: '${stats.expenseCount}',
                        label: 'Expenses',
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                    ],
                  ),
                  loading: () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatItem(
                        icon: Icons.attach_money,
                        value: '...',
                        label: 'Total Expenses',
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      _StatItem(
                        icon: Icons.people,
                        value: '...',
                        label: 'Members',
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      _StatItem(
                        icon: Icons.receipt_long,
                        value: '...',
                        label: 'Expenses',
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                    ],
                  ),
                  error: (_, __) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatItem(
                        icon: Icons.attach_money,
                        value: '0',
                        label: 'Total Expenses',
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      _StatItem(
                        icon: Icons.people,
                        value: '0',
                        label: 'Members',
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      _StatItem(
                        icon: Icons.receipt_long,
                        value: '0',
                        label: 'Expenses',
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Expense'),
                    onPressed: () {
                      context.push('/expenses/add?tripId=${trip.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.white24 : DesignTokens.primaryColor,
                      foregroundColor: isActive ? Colors.white : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.spacing12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    onPressed: () {
                      context.push('/trips/${trip.id}');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isActive ? Colors.white : DesignTokens.primaryColor,
                      side: BorderSide(
                        color: isActive ? Colors.white : DesignTokens.primaryColor,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.spacing8),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleTripAction(context, ref, trip, value),
                  itemBuilder: (context) => [
                    if (trip.status != TripStatus.active)
                      const PopupMenuItem(
                        value: 'activate',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow, size: 16),
                            SizedBox(width: 8),
                            Text('Activate'),
                          ],
                        ),
                      ),
                    if (trip.status == TripStatus.active)
                      const PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16),
                            SizedBox(width: 8),
                            Text('Complete'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 16),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(Icons.archive, size: 16),
                          SizedBox(width: 8),
                          Text('Archive'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white24 : DesignTokens.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      color: isActive ? Colors.white : DesignTokens.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleTripAction(BuildContext context, WidgetRef ref, Trip trip, String action) async {
    final repository = ref.read(tripRepositoryProvider);

    try {
      switch (action) {
        case 'activate':
          await repository.activateTrip(trip.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Activated trip: ${trip.name}'),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;
        case 'complete':
          final updatedTrip = trip.updateStatus(TripStatus.closed);
          await repository.updateTrip(updatedTrip);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Completed trip: ${trip.name}'),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;
        case 'edit':
          context.push('/trips/${trip.id}/edit');
          break;
        case 'duplicate':
          // TODO: Implement trip duplication
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Duplicated trip: ${trip.name}')),
          );
          break;
        case 'archive':
          final updatedTrip = trip.updateStatus(TripStatus.archived);
          await repository.updateTrip(updatedTrip);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📦 Archived trip: ${trip.name}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          break;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Skeleton components
class _TripsListSkeleton extends StatelessWidget {
  const _TripsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        width: double.infinity,
        height: 200,
        margin: const EdgeInsets.only(bottom: DesignTokens.spacing16),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(DesignTokens.borderRadius12),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color textColor;
  final Color subtitleColor;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: textColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: DesignTokens.stats.copyWith(
            color: textColor,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: subtitleColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _EmptyTripsState extends StatelessWidget {
  const _EmptyTripsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.card_travel,
            size: 80,
            color: DesignTokens.inactiveGray,
          ),
          const SizedBox(height: 24),
          Text(
            'No Trips Yet',
            style: DesignTokens.header.copyWith(
              color: DesignTokens.inactiveGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first trip to get started',
            style: DesignTokens.subtitle.copyWith(
              color: DesignTokens.inactiveGray,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/create-trip');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
