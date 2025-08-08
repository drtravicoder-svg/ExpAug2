import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../business_logic/providers/trip_providers.dart';
import '../widgets/active_trip_card.dart';
import '../widgets/recent_expenses_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Trip'),
        backgroundColor: DesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh the active trip data
              ref.invalidate(activeTripProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to add expense screen
              context.push('/add-expense');
            },
          ),
        ],
      ),
      body: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh data when user pulls down
        // This will be handled by the providers
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          ActiveTripCard(),
          SizedBox(height: DesignTokens.sectionSpacing),
          RecentExpensesSection(),
        ],
      ),
    );
  }
}
