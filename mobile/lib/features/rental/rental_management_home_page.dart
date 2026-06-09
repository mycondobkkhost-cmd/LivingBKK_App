import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/rental_lease.dart';
import '../../models/rental_payment_installment.dart';
import '../../services/rental_lease_service.dart';
import '../../services/rental_payment_logic.dart';
import '../../services/system_push_notification.dart';
import '../../theme/app_theme.dart';
import '../../widgets/consumer/consumer_page_shell.dart';
import 'rental_group_chat_page.dart';
import 'rental_lease_dates_display.dart';

/// หน้าบ้าน — บริหารจัดการทรัพย์ให้เช่า (สัญญา active)
class RentalManagementHomePage extends StatefulWidget {
  const RentalManagementHomePage({super.key});

  @override
  State<RentalManagementHomePage> createState() =>
      _RentalManagementHomePageState();
}

class _RentalManagementHomePageState extends State<RentalManagementHomePage> {
  final _service = RentalLeaseService.instance;

  @override
  void initState() {
    super.initState();
    _service.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
    _service.addListener(_onChanged);
    requestSystemPushPermission();
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<RentalLease> get _leases {
    final active = _service.allLeases.where((l) => l.isActive).toList();
    return active.isEmpty ? _service.demoLeases : active;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final fmt = DateFormat(s.isEnglish ? 'd MMM yyyy' : 'd MMM yyyy');
    final leases = _leases;

    final caption = Theme.of(context).textTheme.bodySmall;

    return ConsumerPageShell(
      title: s.rentalManagementTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(s.rentalManagementIntro, style: caption),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _BlindBanner(text: s.rentalGroupBlindHint),
          ),
          Expanded(
            child: leases.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        s.rentalManagementEmpty,
                        textAlign: TextAlign.center,
                        style: caption,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: leases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final lease = leases[i];
                      return Card(
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  RentalGroupChatPage(lease: lease),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lease.listingCode,
                                  style: caption?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lease.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                if (lease.locationLine(s.isEnglish).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      lease.locationLine(s.isEnglish),
                                      style: caption,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.payments_outlined,
                                        size: 16, color: AppTheme.accentMid),
                                    const SizedBox(width: 6),
                                    Text(
                                      s.rentalRentAmount(lease.rentAmount),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.accentMid,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                ..._paymentStatusLines(
                                  context,
                                  lease: lease,
                                  fmt: fmt,
                                  caption: caption,
                                ),
                                const SizedBox(height: 6),
                                RentalLeaseDatesDisplay(
                                  lease: lease,
                                  dateFmt: fmt,
                                  dense: true,
                                  textStyle: caption,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  children: lease.members
                                      .map(
                                        (m) => Chip(
                                          label: Text(
                                            m.displayLabel,
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _paymentStatusLines(
  BuildContext context, {
  required RentalLease lease,
  required DateFormat fmt,
  required TextStyle? caption,
}) {
  final s = context.s;
  final inst = RentalPaymentLogic.displayInstallment(lease: lease);
  final out = <Widget>[];

  if (inst != null && inst.isAdminConfirmed) {
    out.add(const SizedBox(height: 6));
    out.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_outlined, size: 16, color: Colors.green.shade800),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                s.rentalPaymentHomeAdminConfirmed(inst.sequence),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  } else if (inst != null &&
      inst.status == RentalInstallmentStatus.slipSubmitted) {
    out.add(const SizedBox(height: 6));
    out.add(
      Row(
        children: [
          Icon(Icons.receipt_long_outlined, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 6),
          Text(
            s.rentalPaymentHomeSlipReceived(inst.sequence),
            style: caption?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  } else if (lease.nextPaymentDue != null) {
    out.add(const SizedBox(height: 4));
    out.add(
      Text(
        s.rentalNextPayment(fmt.format(lease.nextPaymentDue!)),
        style: caption,
      ),
    );
  }

  return out;
}

class _BlindBanner extends StatelessWidget {
  const _BlindBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
