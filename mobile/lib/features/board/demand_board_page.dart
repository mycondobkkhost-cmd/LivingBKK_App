import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/demand_board_feed_tab.dart';
import '../../models/demand_board_filter_state.dart';
import '../../models/demand_post.dart';
import '../../models/listing_public.dart';
import '../../navigation/demand_board_navigation.dart';
import '../../services/auth_service.dart';
import '../../services/demand_board_favorites_service.dart';
import '../../services/demand_mystock_match_service.dart';
import '../../services/demand_repository.dart';
import '../../services/my_stock_listing_pool.dart';
import '../../shell/main_shell_scope.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/demand_board_filter_apply.dart';
import '../../utils/demand_search_match.dart';
import '../../utils/page_safe_insets.dart';
import '../../widgets/app_mobile_scaffold.dart';
import '../../widgets/demand/demand_board_feed_tabs.dart';
import '../../widgets/demand/demand_board_filter_sheet.dart';
import '../../widgets/demand/demand_board_my_search_panel.dart';
import '../../widgets/demand/demand_create_post_sheet.dart';
import '../../widgets/demand_inquiry_card.dart';
import '../../widgets/proppiter_search_capsule_field.dart';

/// บอร์ดหาทรัพย์ — สไตล์ Looking Feed · ฟังก์ชัน RealXtate
class DemandBoardPage extends StatefulWidget {
  const DemandBoardPage({
    super.key,
    this.isShellTab = false,
    this.fromHomeEntry = false,
    this.onBackToHub,
  });

  final bool isShellTab;
  final bool fromHomeEntry;
  /// ถ้าอยู่ใน hub — กลับ hub ก่อน; ไม่มี hub แล้วค่อยกลับแท็บแรก
  final VoidCallback? onBackToHub;

  @override
  State<DemandBoardPage> createState() => _DemandBoardPageState();
}

class _DemandBoardPageState extends State<DemandBoardPage> {
  final _repo = DemandRepository();
  final _locationController = TextEditingController();
  final _locationFocus = FocusNode();
  List<DemandPost> _posts = [];
  bool _loading = true;
  bool _searchExpanded = false;

  DemandBoardFeedTab _feedTab = DemandBoardFeedTab.feed;
  DemandBoardFilterState _filters = DemandBoardFilterState.initial;
  List<ListingPublic> _myStock = [];
  Map<String, int> _myStockScores = {};

  @override
  void initState() {
    super.initState();
    _locationController.addListener(_onLocationQueryChanged);
    DemandBoardFavoritesService.instance.addListener(_onFavoritesChanged);
    AuthService.instance.addListener(_onAuthChanged);
    _load();
  }

  @override
  void dispose() {
    _locationController.removeListener(_onLocationQueryChanged);
    DemandBoardFavoritesService.instance.removeListener(_onFavoritesChanged);
    AuthService.instance.removeListener(_onAuthChanged);
    _locationController.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  void _onFavoritesChanged() => setState(() {});
  void _onAuthChanged() => setState(() {});
  void _onLocationQueryChanged() => setState(() {});

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final posts = await _repo.fetchPosts();
      final stock = await MyStockListingPool.instance.load();
      final scores = DemandMyStockMatchService.instance.scoreMap(posts, stock);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _myStock = stock;
        _myStockScores = scores;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openFilterSheet() async {
    final picked = await DemandBoardFilterSheet.show(
      context,
      initial: _filters,
      myStockCount: _myStock.length,
    );
    if (!mounted || picked == null) return;
    setState(() => _filters = picked);
  }

  void _openCompose() => DemandCreatePostSheet.show(context);

  List<DemandPost> get _feedPosts {
    var list = _posts.where((p) => p.status == 'open').toList();

    final locationQuery = _locationController.text;
    if (locationQuery.trim().isNotEmpty) {
      list = list
          .where((p) => demandPostMatchesSearchQuery(p, locationQuery))
          .toList();
    }

    list = applyDemandBoardFilters(
      posts: list,
      filters: _filters,
      myStockScores: _myStockScores,
    );

    list.sort((a, b) {
      if (a.isUrgentRush != b.isUrgentRush) return a.isUrgentRush ? -1 : 1;
      if (a.isCashCase != b.isCashCase) return a.isCashCase ? -1 : 1;
      if (_filters.matchMyStock || _feedTab == DemandBoardFeedTab.matches) {
        final sa = _myStockScores[a.id] ?? 0;
        final sb = _myStockScores[b.id] ?? 0;
        if (sa != sb) return sb.compareTo(sa);
      }
      return compareDemandPostsByPriceSort(a, b, _filters.priceSort);
    });
    return list;
  }

  List<DemandPost> get _matchPosts {
    final base = _feedPosts;
    return base
        .where((p) => (_myStockScores[p.id] ?? 0) >= 42)
        .toList();
  }

  String _greetingName(AppStrings s) {
    final auth = AuthService.instance;
    final trial = auth.trialDisplayName?.trim();
    if (trial != null && trial.isNotEmpty) return trial;
    final email = (auth.displayEmail ?? '').trim();
    if (email.contains('@')) return email.split('@').first;
    if (email.isNotEmpty && !email.contains('Demo')) return email;
    return LivingBkkBrand.name;
  }

  String _relativeTime(DateTime time, AppStrings s) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes.clamp(1, 59);
      return s.t('$m นาทีที่แล้ว', '$m min ago');
    }
    if (diff.inHours < 24) {
      return s.t('${diff.inHours} ชม.ที่แล้ว', '${diff.inHours}h ago');
    }
    if (diff.inDays < 7) {
      return s.t('${diff.inDays} วันที่แล้ว', '${diff.inDays}d ago');
    }
    return DateFormat('d MMM yyyy', 'th').format(time);
  }

  String _timeLabel(DemandPost p, AppStrings s) {
    final created = p.createdAt;
    final updated = p.updatedAt;
    if (updated != null &&
        created != null &&
        updated.difference(created).inMinutes > 2) {
      return s.updatedAgo(_relativeTime(updated, s));
    }
    return _relativeTime(p.displayTime, s);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final favCount = DemandBoardFavoritesService.instance.count;
    final filterActive = _filters.hasActive;
    final matchCount = _matchPosts.length;
    final top = PageSafeInsets.top(context);
    final headerTop = top >= 50 ? top + 6.0 : (top > 0 ? top + 4.0 : 10.0);

    return AppMobileScaffold(
      backgroundColor: LivingBkkBrand.pageBackgroundOf(context),
      safeBottomBody: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton(
          onPressed: _openCompose,
          backgroundColor: LivingBkkBrand.accentOrange,
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add_rounded, size: 30),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  LiLayout.pagePadding,
                  headerTop,
                  LiLayout.pagePadding,
                  10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (widget.isShellTab || widget.fromHomeEntry)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            onPressed: () {
                              if (widget.onBackToHub != null) {
                                widget.onBackToHub!();
                              } else if (widget.isShellTab) {
                                MainShellScope.maybeOf(context)?.selectTab(0);
                              } else {
                                Navigator.of(context).maybePop();
                              }
                            },
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            s.demandBoardGreeting(_greetingName(s)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.prompt(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              height: 1.2,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              DemandBoardNavigation.openSavedBoard(context),
                          icon: Badge(
                            isLabelVisible: favCount > 0,
                            smallSize: 8,
                            backgroundColor: LivingBkkBrand.brandRed,
                            child: Icon(
                              Icons.favorite_border_rounded,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(
                            () => _searchExpanded = !_searchExpanded,
                          ),
                          icon: Icon(
                            _searchExpanded
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: _openFilterSheet,
                          icon: Badge(
                            isLabelVisible: filterActive,
                            label: filterActive
                                ? Text('${_filters.activeCount}')
                                : null,
                            backgroundColor: LivingBkkBrand.brandRed,
                            child: Icon(
                              Icons.tune_rounded,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DemandBoardFeedTabs(
                      selected: _feedTab,
                      matchCount: matchCount > 0 ? matchCount : null,
                      onChanged: (tab) {
                        setState(() {
                          _feedTab = tab;
                          if (tab == DemandBoardFeedTab.matches) {
                            _filters = _filters.copyWith(matchMyStock: true);
                          } else if (_filters.matchMyStock &&
                              tab == DemandBoardFeedTab.feed) {
                            _filters = _filters.copyWith(matchMyStock: false);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    if (_searchExpanded)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ProppiterSearchCapsuleField(
                          controller: _locationController,
                          focusNode: _locationFocus,
                          typewriterHint: s.demandSearchLocationHint,
                          cacheKey: 'demand_board_search',
                        ),
                      ),
                    _ComposeBar(
                      hint: s.demandBoardComposeHint,
                      onTap: _openCompose,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.demandBoardHero,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(s)),
        ],
      ),
    );
  }

  Widget _buildBody(AppStrings s) {
    if (_feedTab == DemandBoardFeedTab.mine) {
      return const DemandBoardMySearchPanel();
    }

    final posts = _feedTab == DemandBoardFeedTab.matches
        ? _matchPosts
        : _feedPosts;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _feedTab == DemandBoardFeedTab.matches
                ? (_myStock.isEmpty
                    ? s.demandFilterMatchMyStockEmpty
                    : s.t(
                        'ยังไม่มีประกาศที่จับคู่กับ MyStock',
                        'No posts match your MyStock yet',
                      ))
                : s.t(
                    'ยังไม่มีประกาศในฟีดนี้',
                    'No posts in this feed',
                  ),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: LivingBkkBrand.brandRed,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: PageSafeInsets.padLTRB(
          context,
          left: 0,
          top: 0,
          right: 0,
          bottom: 96,
          addHomeIndicator: false,
        ),
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox.shrink(),
        itemBuilder: (context, i) {
          final p = posts[i];
          return DemandInquiryCard(
            post: p,
            timeLabel: _timeLabel(p, s),
            myStockMatchScore: _myStockScores[p.id],
            onTap: () => DemandBoardNavigation.openPostDetail(
              context,
              post: p,
            ),
            onOffer: () => DemandBoardNavigation.openSubmitOffer(
              context,
              post: p,
            ),
          );
        },
      ),
    );
  }
}

class _ComposeBar extends StatelessWidget {
  const _ComposeBar({
    required this.hint,
    required this.onTap,
  });

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LivingBkkBrand.pageBackground,
      shape: StadiumBorder(
        side: BorderSide(color: AppTheme.border.withOpacity(0.95)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: LivingBkkBrand.brandRedTint,
                child: Text(
                  'R',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: LivingBkkBrand.brandRed,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hint,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
