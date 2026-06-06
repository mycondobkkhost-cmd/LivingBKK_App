import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/listing_public.dart';
import '../../services/listing_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/not_found_scaffold.dart';
import 'listing_detail_page.dart';
import '../../widgets/app_mobile_scaffold.dart';

/// เปิดจากลิงก์แชร์ `/listing/:id` — โหลดทรัพย์จาก Supabase หรือ demo
class ListingDetailRoutePage extends StatefulWidget {
  const ListingDetailRoutePage({
    super.key,
    required this.listingId,
    this.isAgent = false,
  });

  final String listingId;
  final bool isAgent;

  @override
  State<ListingDetailRoutePage> createState() => _ListingDetailRoutePageState();
}

class _ListingDetailRoutePageState extends State<ListingDetailRoutePage> {
  final _repo = ListingRepository();
  late Future<ListingPublic?> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchById(widget.listingId);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return FutureBuilder<ListingPublic?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return AppMobileScaffold(
      safeBottomBody: false,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    s.t('กำลังโหลดทรัพย์…', 'Loading listing…'),
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        final listing = snap.data;
        if (listing == null) {
          return NotFoundScaffold(message: (s) => s.notFoundListing);
        }

        return ListingDetailPage(
          listing: listing,
          isAgent: widget.isAgent,
        );
      },
    );
  }
}
