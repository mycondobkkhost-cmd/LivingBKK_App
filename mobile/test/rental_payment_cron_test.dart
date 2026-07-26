import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/models/rental_lease.dart';
import 'package:livingbkk/models/rental_payment_installment.dart';
import 'package:livingbkk/models/rental_payment_policy.dart';
import 'package:livingbkk/services/rental_payment_logic.dart';

RentalLease _leaseWithDueInDays(int daysUntilDue) {
  final today = DateTime(2026, 6, 16);
  final due = today.add(Duration(days: daysUntilDue));
  return RentalLease(
    id: 'test-lease',
    listingId: 'l1',
    listingCode: 'RXT-TEST',
    title: 'Test',
    rentAmount: 10000,
    paymentDayOfMonth: due.day,
    billingCycle: RentalBillingCycle.monthly,
    leaseStart: today.subtract(const Duration(days: 30)),
    paymentPolicy: const RentalPaymentPolicy(reminderDaysBefore: [2, 1]),
    paymentInstallments: [
      RentalPaymentInstallment(
        id: 'pay-1',
        sequence: 1,
        dueDate: due,
      ),
    ],
  );
}

void main() {
  test('pendingReminders matches daysBefore policy', () {
    final onDate = DateTime(2026, 6, 16);
    final lease = _leaseWithDueInDays(2);
    final pending = RentalPaymentLogic.pendingReminders(
      lease: lease,
      onDate: onDate,
    );
    expect(pending.length, 1);
    expect(pending.first.daysBefore, 2);
  });

  test('pendingReminders skips already sent', () {
    final onDate = DateTime(2026, 6, 16);
    final due = onDate.add(const Duration(days: 2));
    final lease = RentalLease(
      id: 'test-lease',
      listingId: 'l1',
      listingCode: 'RXT-TEST',
      title: 'Test',
      rentAmount: 10000,
      paymentDayOfMonth: due.day,
      billingCycle: RentalBillingCycle.monthly,
      leaseStart: onDate.subtract(const Duration(days: 30)),
      paymentPolicy: const RentalPaymentPolicy(reminderDaysBefore: [2, 1]),
      paymentInstallments: [
        RentalPaymentInstallment(
          id: 'pay-1',
          sequence: 1,
          dueDate: due,
          remindersSentDaysBefore: const [2],
        ),
      ],
    );
    final pending = RentalPaymentLogic.pendingReminders(
      lease: lease,
      onDate: onDate,
    );
    expect(pending, isEmpty);
  });
}
