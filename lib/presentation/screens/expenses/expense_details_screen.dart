import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../business_logic/providers/expense_providers.dart';
import '../../../data/models/expense.dart';

class ExpenseDetailsScreen extends ConsumerWidget {
  final String expenseId;

  const ExpenseDetailsScreen({
    super.key,
    required this.expenseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expense = ref.watch(expenseProvider(expenseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        backgroundColor: DesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit expense
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit expense coming soon')),
              );
            },
          ),
        ],
      ),
      body: expense.when(
        data: (expenseData) {
          if (expenseData == null) {
            return const Center(
              child: Text('Expense not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Expense Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                expenseData.description,
                                style: DesignTokens.header,
                              ),
                            ),
                            _StatusBadge(status: expenseData.status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          CurrencyFormatter.format(expenseData.amount, expenseData.currency),
                          style: DesignTokens.header.copyWith(
                            fontSize: 32,
                            color: DesignTokens.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Expense Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Details',
                          style: DesignTokens.subtitle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          icon: Icons.person,
                          label: 'Paid by',
                          value: expenseData.payerId, // Fixed: was paidBy. TODO: Get actual user name
                        ),
                        _DetailRow(
                          icon: Icons.calendar_today,
                          label: 'Date',
                          value: DateFormatter.formatDateTime(expenseData.date), // Fixed: use date field
                        ),
                        _DetailRow(
                          icon: Icons.category,
                          label: 'Category',
                          value: expenseData.category, // Fixed: was categoryId
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Note: Participants and custom split features are not supported in current Expense model
                // These fields (participants, customSplit) don't exist in the simplified Expense model
                
                // Receipt
                if (expenseData.receiptPath != null && expenseData.receiptPath!.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Receipt',
                            style: DesignTokens.subtitle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Receipt path: ${expenseData.receiptPath}',
                            style: DesignTokens.subtitle,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Receipt viewing is not yet implemented',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Admin Actions (if pending)
                if (expenseData.status == ExpenseStatus.pending) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Actions',
                            style: DesignTokens.subtitle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Implement approve expense
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Approve expense coming soon')),
                                    );
                                  },
                                  icon: const Icon(Icons.check),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // TODO: Implement reject expense
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Reject expense coming soon')),
                                    );
                                  },
                                  icon: const Icon(Icons.close),
                                  label: const Text('Reject'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Note: Admin comment feature not supported in current Expense model
                // The adminComment field doesn't exist in the simplified Expense model
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading expense: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(expenseProvider(expenseId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ExpenseStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case ExpenseStatus.pending:
        color = Colors.orange;
        icon = Icons.schedule;
        text = 'PENDING';
        break;
      case ExpenseStatus.approved: // Fixed: was ExpenseStatus.committed
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'APPROVED';
        break;
      case ExpenseStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
        text = 'REJECTED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: DesignTokens.inactiveGray),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: DesignTokens.subtitle.copyWith(
              color: DesignTokens.inactiveGray,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: DesignTokens.subtitle.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
