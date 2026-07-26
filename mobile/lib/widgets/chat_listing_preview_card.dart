import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../models/listing_public.dart';
import '../services/listing_repository.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../utils/listing_offer_meta.dart';

/// การ์ดทรัพย์ย่อในแชท — กดเข้าดูรายละเอียดได้ · ปุ่มสนใจทรัพย์ (แชทความต้องการ)
class ChatListingPreviewCard extends StatefulWidget {
  const ChatListingPreviewCard({
    super.key,
    required this.link,
    required this.onTap,
    this.textColor,
    this.interestLabel,
    this.onInterest,
    this.interestBusy = false,
  });

  final ChatMessageLink link;
  final VoidCallback onTap;
  final Color? textColor;
  final String? interestLabel;
  final VoidCallback? onInterest;
  final bool interestBusy;

  @override
  State<ChatListingPreviewCard> createState() => _ChatListingPreviewCardState();
}

class _ChatListingPreviewCardState extends State<ChatListingPreviewCard> {
  final _repo = ListingRepository();
  ListingPublic? _listing;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final found = await _repo.resolveForChatLink(
      listingId: widget.link.listingId,
      label: widget.link.label,
    );

    if (mounted) {
      setState(() {
        _listing = found;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final textColor = widget.textColor ?? p.textPrimary;
    final listing = _listing;
    final cover = listing != null ? ListingOfferMeta.coverUrl(listing) : null;
    final currency =
        NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);

    return Material(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.border.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.onTap,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 72,
                      height: 54,
                      child: _loading
                          ? ColoredBox(color: AppTheme.cardTint)
                          : cover != null
                              ? Image.network(
                                  cover,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _placeholder(),
                                )
                              : _placeholder(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (listing?.listingCode.isNotEmpty == true)
                          Text(
                            listing!.listingCode,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: p.primary,
                            ),
                          ),
                        Text(
                          listing != null
                              ? ListingOfferMeta.displayTitle(listing)
                              : widget.link.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (listing != null && listing.priceNet > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            currency.format(listing.priceNet),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: p.primary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.open_in_new, size: 12, color: p.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.link.label,
                                style: TextStyle(fontSize: 10, color: p.primary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.onInterest != null && widget.interestLabel != null) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: widget.interestBusy ? null : widget.onInterest,
                icon: widget.interestBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.favorite_border, size: 18),
                label: Text(widget.interestLabel!),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: AppTheme.cardTint,
      child: Center(
        child: Icon(
          Icons.home_work_outlined,
          color: AppTheme.textSecondary.withOpacity(0.45),
          size: 22,
        ),
      ),
    );
  }
}
