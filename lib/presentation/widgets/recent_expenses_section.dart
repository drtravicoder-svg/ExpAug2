import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../business_logic/providers/trip_providers.dart';
import '../../business_logic/providers/expense_providers.dart';
import '../../data/models/expense.dart';

class RecentExpensesSection extends ConsumerWidget {
  const RecentExpensesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTrip = ref.watch(activeTripProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Expenses',
                  style: DesignTokens.header,
                ),
                Text(
                  'Latest expenses from your active trip',
                  style: DesignTokens.subtitle.copyWith(
                    color: DesignTokens.inactiveGray,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                context.go('/expenses');
              },
              child: const Row(
                children: [
                  Text('View All'),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        activeTrip.when(
          data: (trip) {
            if (trip == null) {
              return _buildNoActiveTripState();
            }

            return _RecentExpensesList(tripId: trip.id);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(),
        ),
      ],
    );
  }

  Widget _buildNoActiveTripState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(DesignTokens.borderRadius),
      ),
      child: Column(
        children: [
          Icon(
            Icons.card_travel,
            size: 48,
            color: DesignTokens.inactiveGray,
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Trip',
            style: DesignTokens.subtitle.copyWith(
              fontWeight: FontWeight.w600,
              color: DesignTokens.inactiveGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create or activate a trip to see recent expenses',
            style: TextStyle(
              color: DesignTokens.inactiveGray,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(DesignTokens.borderRadius),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Expenses',
            style: DesignTokens.subtitle.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentExpensesList extends ConsumerWidget {
  final String tripId;

  const _RecentExpensesList({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentExpenses = ref.watch(recentExpensesProvider(tripId));

    return recentExpenses.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: expenses.take(3).map((expense) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ExpenseListItem(expense: expense),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading expenses: $error'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(DesignTokens.borderRadius),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: DesignTokens.primaryBlue,
          ),
          const SizedBox(height: 16),
          Text(
            'No Expenses Yet',
            style: DesignTokens.subtitle.copyWith(
              fontWeight: FontWeight.w600,
              color: DesignTokens.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first expense to get started',
            style: TextStyle(
              color: DesignTokens.primaryBlue,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/add-expense?tripId=$tripId');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
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

class ExpenseListItem extends StatelessWidget {
  final Expense expense;

  const ExpenseListItem({
    super.key,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(DesignTokens.cardPadding),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DesignTokens.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.borderRadius),
                ),
                child: Icon(
                  _getCategoryIcon(expense.categoryId),
                  color: DesignTokens.primaryBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: DesignTokens.subtitle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 16,
                          color: DesignTokens.inactiveGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          expense.categoryId, // TODO: Get actual category name
                          style: TextStyle(
                            color: DesignTokens.inactiveGray,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: DesignTokens.inactiveGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormatter.formatRelative(expense.createdAt),
                          style: TextStyle(
                            color: DesignTokens.inactiveGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: DesignTokens.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Paid by ${expense.paidBy}', // TODO: Get actual user name
                          style: TextStyle(
                            color: DesignTokens.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(expense.amount, expense.currency),
                    style: DesignTokens.stats,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(expense.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(expense.status),
                      style: TextStyle(
                        color: _getStatusColor(expense.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'accommodation':
        return Icons.hotel;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'fuel':
        return Icons.local_gas_station;
      case 'medical':
        return Icons.medical_services;
      default:
        return Icons.category;
    }
  }

  Color _getStatusColor(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.pending:
        return Colors.orange;
      case ExpenseStatus.committed:
        return DesignTokens.liveGreen;
      case ExpenseStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusText(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.pending:
        return 'Pending';
      case ExpenseStatus.committed:
        return 'Split';
      case ExpenseStatus.rejected:
        return 'Rejected';
    }
  }
}
