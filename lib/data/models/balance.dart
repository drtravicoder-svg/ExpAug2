import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'balance.freezed.dart';
part 'balance.g.dart';

@freezed
class Balance with _$Balance {
  const factory Balance({
    required String id,
    required String tripId,
    required String memberId,
    @Default(0.0) double totalPaid,
    @Default(0.0) double totalShare,
    @Default(0.0) double netBalance,
    required DateTime lastUpdated,
    @Default({}) Map<String, CategoryBalance> expenseBreakdown,
  }) = _Balance;

  factory Balance.fromJson(Map<String, dynamic> json) => _$BalanceFromJson(json);

  factory Balance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Balance(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      memberId: data['memberId'] ?? '',
      totalPaid: (data['totalPaid'] ?? 0.0).toDouble(),
      totalShare: (data['totalShare'] ?? 0.0).toDouble(),
      netBalance: (data['netBalance'] ?? 0.0).toDouble(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      expenseBreakdown: (data['expenseBreakdown'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(
                  key, CategoryBalance.fromJson(value as Map<String, dynamic>))) ??
          {},
    );
  }
}

@freezed
class CategoryBalance with _$CategoryBalance {
  const factory CategoryBalance({
    @Default(0.0) double paid,
    @Default(0.0) double share,
  }) = _CategoryBalance;

  factory CategoryBalance.fromJson(Map<String, dynamic> json) =>
      _$CategoryBalanceFromJson(json);
}

@freezed
class Settlement with _$Settlement {
  const factory Settlement({
    required String fromMemberId,
    required String toMemberId,
    required double amount,
    required String currency,
  }) = _Settlement;

  factory Settlement.fromJson(Map<String, dynamic> json) =>
      _$SettlementFromJson(json);
}

extension BalanceExtensions on Balance {
  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'memberId': memberId,
      'totalPaid': totalPaid,
      'totalShare': totalShare,
      'netBalance': netBalance,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'expenseBreakdown': expenseBreakdown
          .map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  /// Returns true if this member owes money (negative balance)
  bool get owesMoneyToGroup => netBalance < 0;

  /// Returns true if this member is owed money (positive balance)
  bool get isOwedMoneyByGroup => netBalance > 0;

  /// Returns true if this member is settled (zero balance)
  bool get isSettled => netBalance.abs() < 0.01; // Account for floating point precision

  /// Returns the absolute amount owed or to be received
  double get absoluteBalance => netBalance.abs();
}

class BalanceCalculator {
  /// Calculate settlements needed to balance all members
  static List<Settlement> calculateSettlements(
    List<Balance> balances,
    String currency,
  ) {
    final settlements = <Settlement>[];
    final creditors = <Balance>[];
    final debtors = <Balance>[];

    // Separate creditors (positive balance) and debtors (negative balance)
    for (final balance in balances) {
      if (balance.netBalance > 0.01) {
        creditors.add(balance);
      } else if (balance.netBalance < -0.01) {
        debtors.add(balance);
      }
    }

    // Sort creditors by amount owed (descending)
    creditors.sort((a, b) => b.netBalance.compareTo(a.netBalance));
    // Sort debtors by amount owed (ascending, most negative first)
    debtors.sort((a, b) => a.netBalance.compareTo(b.netBalance));

    int creditorIndex = 0;
    int debtorIndex = 0;

    while (creditorIndex < creditors.length && debtorIndex < debtors.length) {
      final creditor = creditors[creditorIndex];
      final debtor = debtors[debtorIndex];

      final amountToSettle = [creditor.netBalance, -debtor.netBalance].reduce((a, b) => a < b ? a : b);

      if (amountToSettle > 0.01) {
        settlements.add(Settlement(
          fromMemberId: debtor.memberId,
          toMemberId: creditor.memberId,
          amount: amountToSettle,
          currency: currency,
        ));

        // Update balances
        creditors[creditorIndex] = creditor.copyWith(
          netBalance: creditor.netBalance - amountToSettle,
        );
        debtors[debtorIndex] = debtor.copyWith(
          netBalance: debtor.netBalance + amountToSettle,
        );
      }

      // Move to next creditor or debtor if current one is settled
      if (creditors[creditorIndex].netBalance <= 0.01) {
        creditorIndex++;
      }
      if (debtors[debtorIndex].netBalance >= -0.01) {
        debtorIndex++;
      }
    }

    return settlements;
  }
}
