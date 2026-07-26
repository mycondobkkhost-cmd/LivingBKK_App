import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/owner_inquiry.dart';
import '../../services/owner_inquiry_repository.dart';
import '../../theme/app_palette.dart';

Future<bool?> showOwnerInquiryReplySheet(
  BuildContext context, {
  required OwnerInquiryRow inquiry,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => OwnerInquiryReplySheet(inquiry: inquiry),
  );
}

class OwnerInquiryReplySheet extends StatefulWidget {
  const OwnerInquiryReplySheet({super.key, required this.inquiry});

  final OwnerInquiryRow inquiry;

  @override
  State<OwnerInquiryReplySheet> createState() => _OwnerInquiryReplySheetState();
}

class _OwnerInquiryReplySheetState extends State<OwnerInquiryReplySheet> {
  final _reply = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    try {
      await OwnerInquiryRepository.instance.replyAsOwner(
        inquiryId: widget.inquiry.id,
        replyText: text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _infoBox(BuildContext context, {required String title, required String body}) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body),
        ],
      ),
    );
  }

  String _profileSummary(OwnerInquiryRow inq) {
    if (inq.seekerContext.isEmpty) return '';
    return inq.seekerContext.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final inq = widget.inquiry;
    final profile = _profileSummary(inq);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.ownerInquiryReplyTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '${inq.listingCode} · ${inq.code}',
              style: TextStyle(color: context.palette.textSecondary),
            ),
            const SizedBox(height: 12),
            if (profile.isNotEmpty) ...[
              _infoBox(
                context,
                title: s.ownerInquirySeekerProfileTitle,
                body: profile,
              ),
              const SizedBox(height: 12),
            ],
            _infoBox(
              context,
              title: s.ownerInquiryAskSection,
              body: inq.seekerQuestion,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reply,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: s.ownerInquiryReplyLabel,
                hintText: s.ownerInquiryReplyHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.ownerInquiryReplyBtn),
            ),
          ],
        ),
      ),
    );
  }
}
