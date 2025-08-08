import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../business_logic/providers/expense_providers.dart';
import '../../../business_logic/providers/trip_providers.dart';
import '../../../data/models/expense.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTrip = ref.watch(activeTripProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: DesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/add-expense');
            },
          ),
        ],
      ),
      body: activeTrip.when(
        data: (trip) {
          if (trip == null) {
            return const _NoActiveTripState();
          }
          
          return _ExpensesContent(tripId: trip.id);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(activeTripProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpensesContent extends ConsumerWidget {
  final String tripId;

  const _ExpensesContent({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(tripExpensesProvider(tripId));
    final expenseStats = ref.watch(expenseStatsProvider(tripId));

    return Column(
      children: [
        // Stats Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DesignTokens.primaryBlue,
            borderRadius: BorderRadius.circular(DesignTokens.borderRadius),
          ),
          child: Column(
            children: [
              Text(
                'Total Expenses',
                style: DesignTokens.subtitle.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(expenseStats.totalAmount, 'INR'),
                style: DesignTokens.header.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(
                    label: 'Total',
                    value: '${expenseStats.totalCount}',
                    color: Colors.white,
                  ),
                  _StatColumn(
                    label: 'Pending',
                    value: '${expenseStats.pendingCount}',
                    color: Colors.orange.shade200,
                  ),
                  _StatColumn(
                    label: 'Approved',
                    value: '${expenseStats.approvedCount}',
                    color: Colors.green.shade200,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Expenses List
        Expanded(
          child: expenses.when(
            data: (expenseList) {
              if (expenseList.isEmpty) {
                return const _EmptyExpensesState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: expenseList.length,
                itemBuilder: (context, index) {
                  final expense = expenseList[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ExpenseListItem(expense: expense),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading expenses: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(tripExpensesProvider(tripId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ExpenseListItem extends StatelessWidget {
  final Expense expense;

  const ExpenseListItem({
    super.key,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    
    switch (expense.status) {
      case ExpenseStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case ExpenseStatus.committed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case ExpenseStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.borderRadius),
      ),
      child: InkWell(
        onTap: () {
          context.push('/expense/${expense.id}');
        },
        borderRadius: BorderRadius.circular(DesignTokens.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      expense.description,
                      style: DesignTokens.subtitle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(statusIcon, color: statusColor, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    CurrencyFormatter.format(expense.amount, expense.currency),
                    style: DesignTokens.stats.copyWith(
                      color: DesignTokens.primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormatter.formatRelative(expense.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Paid by ${expense.paidBy}', // TODO: Get actual user name
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _NoActiveTripState extends StatelessWidget {
  const _NoActiveTripState();

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
            'No Active Trip',
            style: DesignTokens.header.copyWith(
              color: DesignTokens.inactiveGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create or activate a trip to view expenses',
            style: DesignTokens.subtitle.copyWith(
              color: DesignTokens.inactiveGray,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.go('/trips');
            },
            icon: const Icon(Icons.card_travel),
            label: const Text('View All Trips'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExpensesState extends StatelessWidget {
  const _EmptyExpensesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long,
            size: 80,
            color: DesignTokens.inactiveGray,
          ),
          const SizedBox(height: 24),
          Text(
            'No Expenses Yet',
            style: DesignTokens.header.copyWith(
              color: DesignTokens.inactiveGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first expense to get started',
            style: DesignTokens.subtitle.copyWith(
              color: DesignTokens.inactiveGray,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/add-expense');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add First Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
