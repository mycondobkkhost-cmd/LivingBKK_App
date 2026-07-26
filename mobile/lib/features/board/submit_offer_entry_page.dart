import 'package:flutter/material.dart';

import '../../models/demand_post.dart';
import '../../models/listing_public.dart';
import '../../models/submit_offer_route_args.dart';
import '../../services/demand_mystock_match_service.dart';
import '../../services/demand_repository.dart';
import '../../services/my_stock_listing_pool.dart';
import '../../theme/app_theme.dart';
import '../../widgets/not_found_scaffold.dart';
import 'submit_offer_page.dart';

/// เปิดหน้าเสนอทรัพย์จาก URL — โหลดประกาศจาก id เมื่อ refresh ทำให้ `extra` หาย
class SubmitOfferEntryPage extends StatefulWidget {
  const SubmitOfferEntryPage({
    super.key,
    required this.postId,
    this.initialArgs,
  });

  final String postId;
  final SubmitOfferRouteArgs? initialArgs;

  @override
  State<SubmitOfferEntryPage> createState() => _SubmitOfferEntryPageState();
}

class _SubmitOfferEntryPageState extends State<SubmitOfferEntryPage> {
  final _repo = DemandRepository();
  DemandPost? _post;
  SubmitOfferMode _mode = SubmitOfferMode.manualOnly;
  List<ListingPublic> _matched = const [];
  List<ListingPublic> _stock = const [];
  bool _loading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final args = widget.initialArgs;
    if (args != null) {
      if (!mounted) return;
      setState(() {
        _post = args.post;
        _mode = args.mode;
        _matched = args.matchedListings;
        _stock = args.stockListings;
        _loading = false;
      });
      return;
    }

    final post = await _repo.findPostById(widget.postId);
    if (!mounted) return;
    if (post == null) {
      setState(() {
        _notFound = true;
        _loading = false;
      });
      return;
    }

    final stock = await MyStockListingPool.instance.load();
    final matches = DemandMyStockMatchService.instance.matchingListings(post, stock);
    final mode = matches.isNotEmpty
        ? SubmitOfferMode.stockPick
        : (stock.isNotEmpty
            ? SubmitOfferMode.boardFlexible
            : SubmitOfferMode.manualOnly);

    setState(() {
      _post = post;
      _mode = mode;
      _matched = matches;
      _stock = stock;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }
    if (_notFound || _post == null) {
      return NotFoundScaffold(message: (s) => s.notFoundPost);
    }
    return SubmitOfferPage(
      post: _post!,
      mode: _mode,
      matchedListings: _matched,
      stockListings: _stock,
    );
  }
}
