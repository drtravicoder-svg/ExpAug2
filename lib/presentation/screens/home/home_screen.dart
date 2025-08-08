import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../business_logic/providers/auth_providers.dart';
import '../../../business_logic/providers/trip_providers.dart';
import '../../../business_logic/providers/expense_providers.dart';
import '../../../business_logic/services/real_time_service.dart';
import '../../../data/repositories/mock_trip_repository.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/active_trip_card.dart';
import '../../widgets/recent_expenses_section.dart';
import '../../widgets/common/animated_card.dart';
import '../../widgets/common/loading_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _refreshController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning!';
    } else if (hour < 17) {
      return 'Good afternoon!';
    } else {
      return 'Good evening!';
    }
  }

  Future<void> _handleRefresh() async {
    _refreshController.forward();
    try {
      ref.invalidate(activeTripProvider);
      ref.invalidate(currentUserProvider);
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      _refreshController.reset();
    }
  }

  Future<void> _loadTestData() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧪 Loading test data...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Get the mock repository and load test data
      final mockRepo = MockTripRepository();
      await mockRepo.initializeMockData();

      // Refresh the providers to show new data
      ref.invalidate(allTripsProvider);
      ref.invalidate(activeTripProvider);
      ref.invalidate(currentUserProvider);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Test data loaded! Check All Trips screen.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error loading test data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final activeTrip = ref.watch(activeTripProvider);

    return Scaffold(
      backgroundColor: DesignTokens.backgroundLight,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(DesignTokens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              AnimatedCard(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(DesignTokens.spacing20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignTokens.borderRadius12),
                    gradient: LinearGradient(
                      colors: [
                        DesignTokens.primaryColor,
                        DesignTokens.primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: DesignTokens.headingMedium.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: DesignTokens.spacing8),
                              Text(
                                currentUser != null ? 'Hello, ${currentUser!.displayName ?? 'Admin'}' : 'Hello, Guest',
                                style: DesignTokens.bodyLarge.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Test Data Button
                              GestureDetector(
                                onTap: _loadTestData,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.science,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Refresh Button
                              AnimatedBuilder(
                                animation: _refreshAnimation,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _refreshAnimation.value * 2 * 3.14159,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.sync,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.spacing16),
                      // Real-time status indicator
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spacing8),
                          Text(
                            'Real-time sync active',
                            style: DesignTokens.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: DesignTokens.spacing24),

              // Active Trip Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Active Trip',
                        style: DesignTokens.headingSmall,
                      ),
                      const SizedBox(width: DesignTokens.spacing8),
                      activeTrip.when(
                        data: (trip) => trip != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'LIVE',
                                      style: DesignTokens.bodySmall.copyWith(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _handleRefresh,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                      ),
                      IconButton(
                        onPressed: () {
                          context.push('/trips/create');
                        },
                        icon: const Icon(Icons.add),
                        tooltip: 'Create Trip',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: DesignTokens.spacing16),

              // Active Trip Card
              activeTrip.when(
                data: (trip) => ActiveTripCard(trip: trip),
                loading: () => const ShimmerLoading(
                  child: _TripCardSkeleton(),
                ),
                error: (error, stack) => AnimatedCard(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DesignTokens.spacing20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(DesignTokens.borderRadius12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade600,
                          size: 32,
                        ),
                        const SizedBox(height: DesignTokens.spacing8),
                        Text(
                          'Error loading active trip',
                          style: DesignTokens.bodyMedium.copyWith(
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacing8),
                        ElevatedButton(
                          onPressed: _handleRefresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: DesignTokens.spacing32),

              // Recent Expenses Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Recent Expenses',
                        style: DesignTokens.headingSmall,
                      ),
                      const SizedBox(width: DesignTokens.spacing8),
                      activeTrip.when(
                        data: (trip) {
                          if (trip == null) return const SizedBox.shrink();
                          return Consumer(
                            builder: (context, ref, child) {
                              final recentExpenses = ref.watch(recentExpensesProvider(trip.id));
                              return recentExpenses.when(
                                data: (expenses) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: DesignTokens.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${expenses.length}',
                                    style: DesignTokens.bodySmall.copyWith(
                                      color: DesignTokens.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      context.push('/expenses');
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View All'),
                  ),
                ],
              ),

              const SizedBox(height: DesignTokens.spacing16),

              // Recent Expenses List
              const RecentExpensesSection(),

              const SizedBox(height: DesignTokens.spacing32),

              // Quick Actions
              AnimatedCard(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(DesignTokens.spacing20),
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceColor,
                    borderRadius: BorderRadius.circular(DesignTokens.borderRadius12),
                    border: Border.all(color: DesignTokens.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: DesignTokens.headingSmall,
                      ),
                      const SizedBox(height: DesignTokens.spacing16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.push('/trips');
                              },
                              icon: const Icon(Icons.luggage),
                              label: const Text('All Trips'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spacing12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.push('/add-expense');
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Add Expense'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.spacing12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.push('/analytics');
                              },
                              icon: const Icon(Icons.analytics_outlined),
                              label: const Text('Analytics'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spacing12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.push('/settings');
                              },
                              icon: const Icon(Icons.settings_outlined),
                              label: const Text('Settings'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom padding for better scrolling
              const SizedBox(height: DesignTokens.spacing32),
            ],
          ),
        ),
      ),
    );
  }
}

// Skeleton widgets for loading states
class _TripCardSkeleton extends StatelessWidget {
  const _TripCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(DesignTokens.spacing20),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(DesignTokens.borderRadius12),
      ),
    );
  }
}

class _ExpensesSkeleton extends StatelessWidget {
  const _ExpensesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (index) =>
        Container(
          width: double.infinity,
          height: 80,
          margin: const EdgeInsets.only(bottom: DesignTokens.spacing12),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(DesignTokens.borderRadius8),
          ),
        ),
      ),
    );
  }
}
