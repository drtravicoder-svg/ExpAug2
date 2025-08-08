import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../business_logic/providers/trip_providers.dart';
import '../../business_logic/providers/expense_providers.dart';
import '../../data/models/trip.dart';

class ActiveTripCard extends ConsumerWidget {
  final Trip? trip;

  const ActiveTripCard({super.key, this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTrip = trip != null ? AsyncValue.data(trip) : ref.watch(activeTripProvider);

    return activeTrip.when(
      data: (trip) {
        if (trip == null) {
          return const _NoActiveTrip();
        }
        return Card(
          color: DesignTokens.primaryBlue,
          child: Padding(
            padding: EdgeInsets.all(DesignTokens.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.yellow),
                    const SizedBox(width: 8),
                    Text(
                      'ACTIVE TRIP',
                      style: DesignTokens.buttonText.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.liveGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'LIVE',
                        style: DesignTokens.buttonText.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  trip.name,
                  style: DesignTokens.header.copyWith(
                    color: DesignTokens.white,
                  ),
                ),
                Text(
                  '${trip.origin} → ${trip.destination}',
                  style: DesignTokens.subtitle.copyWith(
                    color: DesignTokens.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormatter.formatDateRange(trip.startDate, trip.endDate),
                  style: DesignTokens.subtitle.copyWith(
                    color: DesignTokens.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final tripStats = ref.watch(tripStatsProvider(trip.id));
                        return _StatItem(
                          icon: Icons.currency_rupee,
                          value: CurrencyFormatter.formatCompact(tripStats.totalExpenses, trip.currency),
                          label: 'Total Expenses',
                        );
                      },
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final tripStats = ref.watch(tripStatsProvider(trip.id));
                        return _StatItem(
                          icon: Icons.people,
                          value: '${tripStats.memberCount}',
                          label: 'Members',
                        );
                      },
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final tripStats = ref.watch(tripStatsProvider(trip.id));
                        return _StatItem(
                          icon: Icons.receipt_long,
                          value: '${tripStats.expenseCount}',
                          label: 'Expenses',
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Expense'),
                        onPressed: () {
                          context.push('/add-expense?tripId=${trip.id}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Details'),
                        onPressed: () {
                          context.push('/trip/${trip.id}');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}

class _NoActiveTrip extends StatelessWidget {
  const _NoActiveTrip();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hiking, size: 48, color: DesignTokens.inactiveGray),
            const SizedBox(height: 16),
            Text(
              'No Active Trip',
              style: DesignTokens.header,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new trip or activate an existing one',
              style: DesignTokens.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Trip'),
              onPressed: () {
                context.push('/create-trip');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 8),
        Text(
          value,
          style: DesignTokens.stats.copyWith(
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: DesignTokens.buttonText.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
