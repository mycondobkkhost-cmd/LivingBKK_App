/// นโยบายชำระค่าเช่า — แอดมินตั้งค่าต่อสัญญา/ปี
class RentalPaymentPolicy {
  const RentalPaymentPolicy({
    this.reminderDaysBefore = const [2, 1],
    this.installmentsPerYear = 12,
    this.graceDaysLate = 3,
    this.penaltyPerDayAfterGrace = 100,
    this.policyYear,
  });

  /// แจ้งเตือนก่อนครบกำหนดกี่วัน (เช่น 2 วัน, 1 วัน)
  final List<int> reminderDaysBefore;
  /// เก็บสลิปกี่ครั้งต่อปี
  final int installmentsPerYear;
  /// ชำระล่าช้าได้ไม่เกินกี่วัน (หลังครบกำหนด)
  final int graceDaysLate;
  /// ค่าปรับต่อวันหลังเกิน grace
  final int penaltyPerDayAfterGrace;
  final int? policyYear;

  RentalPaymentPolicy copyWith({
    List<int>? reminderDaysBefore,
    int? installmentsPerYear,
    int? graceDaysLate,
    int? penaltyPerDayAfterGrace,
    int? policyYear,
  }) {
    return RentalPaymentPolicy(
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      installmentsPerYear: installmentsPerYear ?? this.installmentsPerYear,
      graceDaysLate: graceDaysLate ?? this.graceDaysLate,
      penaltyPerDayAfterGrace:
          penaltyPerDayAfterGrace ?? this.penaltyPerDayAfterGrace,
      policyYear: policyYear ?? this.policyYear,
    );
  }

  Map<String, dynamic> toJson() => {
        'reminder_days_before': reminderDaysBefore,
        'installments_per_year': installmentsPerYear,
        'grace_days_late': graceDaysLate,
        'penalty_per_day_after_grace': penaltyPerDayAfterGrace,
        if (policyYear != null) 'policy_year': policyYear,
      };

  factory RentalPaymentPolicy.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const RentalPaymentPolicy();
    final raw = j['reminder_days_before'];
    var days = <int>[2, 1];
    if (raw is List) {
      days = raw.map((e) => (e as num).toInt()).where((d) => d > 0).toList()
        ..sort((a, b) => b.compareTo(a));
      if (days.isEmpty) days = [2, 1];
    }
    return RentalPaymentPolicy(
      reminderDaysBefore: days,
      installmentsPerYear: (j['installments_per_year'] as num?)?.toInt() ?? 12,
      graceDaysLate: (j['grace_days_late'] as num?)?.toInt() ?? 3,
      penaltyPerDayAfterGrace:
          (j['penalty_per_day_after_grace'] as num?)?.toInt() ?? 100,
      policyYear: (j['policy_year'] as num?)?.toInt(),
    );
  }
}
