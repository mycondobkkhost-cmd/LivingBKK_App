import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/rental_lease.dart';

/// แสดงวันที่สัญญา — ทำสัญญา · เริ่ม · สิ้นสุด
class RentalLeaseDatesDisplay extends StatelessWidget {
  const RentalLeaseDatesDisplay({
    super.key,
    required this.lease,
    required this.dateFmt,
    this.dense = false,
    this.textStyle,
  });

  final RentalLease lease;
  final DateFormat dateFmt;
  final bool dense;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final style = textStyle ??
        Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12);

    Widget row(IconData icon, String label, DateTime? date) {
      if (date == null) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.only(bottom: dense ? 2 : 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: style?.color?.withOpacity(0.7)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$label ${dateFmt.format(date)}',
                style: style,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row(
          Icons.edit_calendar_outlined,
          s.rentalContractSignedLabel,
          lease.contractSignedAt,
        ),
        row(Icons.play_circle_outline, s.rentalLeaseStartLabel, lease.leaseStart),
        row(Icons.event_busy_outlined, s.rentalLeaseEndLabel, lease.leaseEnd),
      ],
    );
  }
}
