import '../models/rental_lease.dart';
import '../models/rental_payment_installment.dart';
import '../models/rental_payment_policy.dart';

abstract final class RentalPaymentLogic {
  /// สร้างรอบชำระทั้งปีตามวันที่กำหนด (เช่น วันที่ 5 ทุกเดือน × 12 ครั้ง)
  static List<RentalPaymentInstallment> generateInstallments({
    required RentalLease lease,
    int? year,
  }) {
    final y = year ?? lease.paymentPolicy.policyYear ?? DateTime.now().year;
    final count = lease.paymentPolicy.installmentsPerYear.clamp(1, 24);
    final day = lease.paymentDayOfMonth.clamp(1, 28);
    final leaseStartDay = DateTime(
      lease.leaseStart.year,
      lease.leaseStart.month,
      lease.leaseStart.day,
    );

    final out = <RentalPaymentInstallment>[];
    for (var m = 1; m <= count && m <= 12; m++) {
      final due = DateTime(y, m, day);
      if (due.isBefore(leaseStartDay)) continue;
      if (lease.leaseEnd != null) {
        final end = DateTime(
          lease.leaseEnd!.year,
          lease.leaseEnd!.month,
          lease.leaseEnd!.day,
        );
        if (due.isAfter(end)) break;
      }
      out.add(
        RentalPaymentInstallment(
          id: '${lease.id}-pay-$y-${m.toString().padLeft(2, '0')}',
          sequence: out.length + 1,
          dueDate: due,
        ),
      );
    }
    return out;
  }

  /// รอบที่ควรแจ้งเตือนวันนี้ (ยังไม่มีสลิป)
  static List<({RentalPaymentInstallment inst, int daysBefore})> pendingReminders({
    required RentalLease lease,
    DateTime? onDate,
  }) {
    final today = onDate ?? DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final policy = lease.paymentPolicy;
    final out = <({RentalPaymentInstallment inst, int daysBefore})>[];

    for (final inst in lease.paymentInstallments) {
      if (inst.isSettled) continue;
      final due = DateTime(
        inst.dueDate.year,
        inst.dueDate.month,
        inst.dueDate.day,
      );
      final daysUntil = due.difference(day).inDays;
      for (final before in policy.reminderDaysBefore) {
        if (daysUntil == before &&
            !inst.remindersSentDaysBefore.contains(before)) {
          out.add((inst: inst, daysBefore: before));
        }
      }
    }
    return out;
  }

  static int latePenaltyBaht({
    required RentalPaymentInstallment inst,
    required RentalPaymentPolicy policy,
    DateTime? onDate,
  }) {
    if (inst.isSettled) return 0;
    final late = inst.daysLate(onDate ?? DateTime.now());
    final over = late - policy.graceDaysLate;
    if (over <= 0) return 0;
    return over * policy.penaltyPerDayAfterGrace;
  }

  /// รอบที่แสดงสถานะบนการ์ดหน้าบ้าน — เดือนปัจจุบันก่อน ไม่มีก็รอบถัดไป
  static RentalPaymentInstallment? displayInstallment({
    required RentalLease lease,
    DateTime? onDate,
  }) {
    final now = onDate ?? DateTime.now();
    for (final inst in lease.paymentInstallments) {
      if (inst.dueDate.year == now.year && inst.dueDate.month == now.month) {
        return inst;
      }
    }
    return lease.nextPendingInstallment;
  }
}
