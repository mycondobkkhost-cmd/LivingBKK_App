import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/rental_contract_attachment.dart';
import '../../models/rental_lease.dart';
import '../../services/rental_lease_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chat_copyable_text.dart';
import '../../widgets/consumer/consumer_page_shell.dart';
import 'rental_lease_dates_display.dart';
import 'rental_condition_album_panel.dart';
import 'rental_payments_panel.dart';

/// แชทกลุ่มสัญญาเช่า — scaffold Phase 27 (ข้อความ/เอกสาร/อัลบั้ม/ชำระ/ซ่อม)
class RentalGroupChatPage extends StatefulWidget {
  const RentalGroupChatPage({
    super.key,
    required this.lease,
    this.isAdminView = false,
  });

  final RentalLease lease;
  final bool isAdminView;

  @override
  State<RentalGroupChatPage> createState() => _RentalGroupChatPageState();
}

class _RentalGroupChatPageState extends State<RentalGroupChatPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _input = TextEditingController();

  final _service = RentalLeaseService.instance;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _service.addListener(_onLeaseChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onLeaseChanged);
    _tabs.dispose();
    _input.dispose();
    super.dispose();
  }

  void _onLeaseChanged() {
    if (mounted) setState(() {});
  }

  RentalLease get _lease =>
      _service.leaseById(widget.lease.id) ?? widget.lease;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lease = _lease;
    final fmt = DateFormat(s.isEnglish ? 'd MMM yyyy' : 'd MMM yyyy');
    final caption = Theme.of(context).textTheme.bodySmall;

    return ConsumerPageShell(
      title: s.rentalGroupChatTitle,
      headerBottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(lease.listingCode, style: caption),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(lease.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(s.rentalGroupBlindHint, style: caption),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: RentalLeaseDatesDisplay(lease: lease, dateFmt: fmt),
          ),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabs: [
              Tab(text: s.rentalTabChat),
              Tab(text: s.rentalTabDocuments),
              Tab(text: s.rentalTabAlbum),
              Tab(text: s.rentalTabPayments),
              Tab(text: s.rentalTabMaintenance),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ChatTab(lease: lease, input: _input),
                _DocumentsTab(lease: lease, dateFmt: fmt),
                RentalConditionAlbumPanel(
                  lease: lease,
                  isAdmin: widget.isAdminView,
                ),
                RentalPaymentsPanel(lease: lease, isAdmin: widget.isAdminView),
                _ComingSoonPanel(
                  icon: Icons.build_outlined,
                  title: s.rentalTabMaintenance,
                  hint: s.rentalMaintenanceHint,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTab extends StatelessWidget {
  const _ChatTab({required this.lease, required this.input});

  final RentalLease lease;
  final TextEditingController input;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SystemBubble(text: s.rentalGroupWelcome(lease.listingCode)),
              for (final m in lease.members)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: const Icon(Icons.person_outline, size: 16),
                      label: Text(m.displayLabel, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              _SystemBubble(text: s.rentalGroupPhaseNote),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.rentalFeatureComingSoon)),
                  );
                },
                icon: const Icon(Icons.attach_file),
                tooltip: s.rentalAttachDocument,
              ),
              Expanded(
                child: TextField(
                  controller: input,
                  decoration: InputDecoration(
                    hintText: s.rentalChatInputHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.rentalFeatureComingSoon)),
                  );
                },
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SystemBubble extends StatelessWidget {
  const _SystemBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ChatCopyableText(
        text: text,
        style: Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
      ),
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({required this.lease, required this.dateFmt});

  final RentalLease lease;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final files = lease.contractAttachments;

    if (files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined,
                  size: 48, color: AppTheme.primary.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text(s.rentalDocumentsEmpty, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(s.rentalDocumentsAdminOnly, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final f = files[files.length - 1 - i];
        return _ContractFileTile(file: f, dateFmt: dateFmt);
      },
    );
  }
}

class _ContractFileTile extends StatelessWidget {
  const _ContractFileTile({required this.file, required this.dateFmt});

  final RentalContractAttachment file;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.picture_as_pdf_outlined, color: AppTheme.primary),
        title: Text(file.fileName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            dateFmt.format(file.uploadedAt),
            file.uploadedBy,
            if (file.note != null) file.note!,
          ].join('\n'),
        ),
        trailing: const Icon(Icons.visibility_outlined),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.s.rentalContractViewSoon)),
          );
        },
      ),
    );
  }
}

class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel({
    required this.icon,
    required this.title,
    required this.hint,
  });

  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.primary.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              s.rentalFeatureComingSoon,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
