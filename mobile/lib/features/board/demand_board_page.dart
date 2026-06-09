import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../navigation/demand_board_navigation.dart';
import '../../l10n/app_strings.dart';
import '../../models/demand_board_filter_state.dart';
import '../../models/demand_post.dart';
import '../../models/listing_public.dart';
import '../../services/demand_board_favorites_service.dart';
import '../../services/demand_mystock_match_service.dart';
import '../../services/demand_repository.dart';
import '../../services/my_stock_listing_pool.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../utils/demand_board_filter_apply.dart';
import '../../utils/demand_search_match.dart';
import '../../widgets/demand/demand_board_filter_sheet.dart';
import '../../widgets/demand/demand_create_post_cta.dart';
import '../../widgets/demand_inquiry_card.dart';
import '../../widgets/proppiter_search_capsule_field.dart';
import '../../theme/li_layout.dart';
import '../../utils/page_safe_insets.dart';
import '../../shell/main_shell_scope.dart';
import '../../widgets/consumer/consumer_page_shell.dart';

class DemandBoardPage extends StatefulWidget {
  const DemandBoardPage({
    super.key,
    this.isShellTab = false,
    this.fromHomeEntry = false,
  });

  /// แท็บล่าง「บอร์ด」— ปุ่มย้อนกลับกลับหน้าแรก
  final bool isShellTab;
  /// กดเข้ามาจากหน้าแรก (เมนูบริการ) — ใช้หัวข้อยาว
  final bool fromHomeEntry;

  @override
  State<DemandBoardPage> createState() => _DemandBoardPageState();
}

class _DemandBoardPageState extends State<DemandBoardPage> {
  final _repo = DemandRepository();
  final _locationController = TextEditingController();
  final _locationFocus = FocusNode();
  List<DemandPost> _posts = [];
  bool _loading = true;
  bool _openOnly = true;

  DemandBoardFilterState _filters = DemandBoardFilterState.initial;
  bool _favoritesOnly = false;
  List<ListingPublic> _myStock = [];
  Map<String, int> _myStockScores = {};

  @override
  void initState() {
    super.initState();
    _locationController.addListener(_onLocationQueryChanged);
    DemandBoardFavoritesService.instance.addListener(_onFavoritesChanged);
    _load();
  }

  @override
  void dispose() {
    _locationController.removeListener(_onLocationQueryChanged);
    DemandBoardFavoritesService.instance.removeListener(_onFavoritesChanged);
    _locationController.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  void _onFavoritesChanged() => setState(() {});

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
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openFilterSheet() async {
    final s = AppStrings.of(context);
    final picked = await DemandBoardFilterSheet.show(
      context,
      initial: _filters,
      myStockCount: _myStock.length,
    );
    if (!mounted || picked == null) return;
    setState(() => _filters = picked);
  }

  List<DemandPost> get _visible {
    var list = _openOnly
        ? _posts.where((p) => p.status == 'open').toList()
        : _posts.where((p) => p.status != 'open').toList();

    if (_favoritesOnly) {
      final fav = DemandBoardFavoritesService.instance;
      list = list.where((p) => fav.isFavorite(p.id)).toList();
    }

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

    final open = list.where((p) => p.status == 'open').toList();
    final closed = list.where((p) => p.status != 'open').toList();
    open.sort((a, b) {
      if (a.isUrgentRush != b.isUrgentRush) return a.isUrgentRush ? -1 : 1;
      if (a.isCashCase != b.isCashCase) return a.isCashCase ? -1 : 1;
      if (_filters.matchMyStock) {
        final sa = _myStockScores[a.id] ?? 0;
        final sb = _myStockScores[b.id] ?? 0;
        if (sa != sb) return sb.compareTo(sa);
      }
      return compareDemandPostsByPriceSort(a, b, _filters.priceSort);
    });
    closed.sort((a, b) => b.displayTime.compareTo(a.displayTime));
    return [...open, ...closed];
  }

  void _clearFilters() {
    setState(() {
      _filters = DemandBoardFilterState.initial;
      _favoritesOnly = false;
      _locationController.clear();
    });
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
    return s.postedAgo(_relativeTime(p.displayTime, s));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final visible = _visible;
    final hasLocationQuery = _locationController.text.trim().isNotEmpty;
    final favCount = DemandBoardFavoritesService.instance.count;
    final filterActive = _filters.hasActive;
    final hasActiveFilters =
        filterActive || _favoritesOnly || hasLocationQuery;

    return ConsumerPageShell(
      title: widget.fromHomeEntry
          ? s.demandBoardCollectionTitle
          : s.demandBoardTitle,
      titleFontSize: widget.fromHomeEntry ? 15 : null,
      onBack: widget.isShellTab
          ? () => MainShellScope.maybeOf(context)?.selectTab(0)
          : () => Navigator.of(context).maybePop(),
      safeBottomBody: false,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 4, right: 2),
        child: DemandCreatePostCta(
          onTap: () => DemandBoardNavigation.openCreateRequirement(context),
        ),
      ),
      actions: [
        ConsumerHeaderIconButton(
          icon: Icons.tune_rounded,
          onTap: _openFilterSheet,
          showBadge: filterActive,
          badgeLabel: filterActive ? Text('${_filters.activeCount}') : null,
        ),
        ConsumerHeaderIconButton(
          icon: Icons.favorite_border_rounded,
          onTap: () => DemandBoardNavigation.openSavedBoard(context),
          showBadge: favCount > 0,
          badgeLabel: favCount > 0 ? Text('$favCount') : null,
        ),
        if (hasActiveFilters)
          ConsumerHeaderTextButton(
            label: s.t('ล้าง', 'Clear'),
            onTap: _clearFilters,
          ),
      ],
      headerBottom: Padding(
        padding: const EdgeInsets.fromLTRB(
          LiLayout.pagePadding,
          0,
          LiLayout.pagePadding,
          4,
        ),
        child: ProppiterSearchCapsuleField(
          controller: _locationController,
          focusNode: _locationFocus,
          typewriterHint: s.demandSearchLocationHint,
          cacheKey: 'demand_board_search',
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_filters.matchMyStock && _myStockScores.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LiLayout.pagePadding,
                8,
                LiLayout.pagePadding,
                0,
              ),
              child: _FilterChip(
                label: s.demandMyStockMatchBadge,
                active: true,
                onTap: _openFilterSheet,
                showDropdownIcon: false,
                leadingIcon: Icons.home_work_outlined,
              ),
            ),
          Container(
            margin: EdgeInsets.fromLTRB(
              LiLayout.pagePadding,
              _filters.matchMyStock && _myStockScores.isNotEmpty ? 8 : 10,
              LiLayout.pagePadding,
              0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryLight, AppTheme.accentRoseLight],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.demandBoardHero,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.inventory_2_outlined, color: AppTheme.primary, size: 28),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(LiLayout.pagePadding, 8, LiLayout.pagePadding, 0),
            child: SegmentedButton<bool>(
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 12),
              ),
              segments: [
                ButtonSegment(value: true, label: Text(s.demandOfferOpen)),
                ButtonSegment(value: false, label: Text(s.demandOfferClosed)),
              ],
              selected: {_openOnly},
              onSelectionChanged: (v) => setState(() => _openOnly = v.first),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _filters.matchMyStock && _myStock.isEmpty
                                ? s.demandFilterMatchMyStockEmpty
                                : _favoritesOnly
                                    ? s.savedDemandBoardEmpty
                                    : _filters.matchMyStock &&
                                            visible.isEmpty
                                        ? s.t(
                                            'ไม่มีประกาศบอร์ดที่ตรงกับ MyStock ของคุณ',
                                            'No board posts match your MyStock',
                                          )
                                        : hasLocationQuery
                                    ? s.t(
                                        'ไม่พบประกาศที่ตรงกับทำเลหรือโครงการนี้',
                                        'No posts match this area or project',
                                      )
                                    : s.t(
                                        'ยังไม่มีประกาศในหมวดนี้',
                                        'No posts in this tab',
                                      ),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: PageSafeInsets.padLTRB(
                            context,
                            left: 12,
                            top: 8,
                            right: 12,
                            bottom: 72,
                            addHomeIndicator: false,
                          ),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final p = visible[i];
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
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.showDropdownIcon = true,
    this.leadingIcon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool showDropdownIcon;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppTheme.primaryLight : AppTheme.cardTint,
      shape: StadiumBorder(
        side: BorderSide(color: active ? AppTheme.primary : AppTheme.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: 14,
                  color: active ? AppTheme.primary : AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                ),
              ),
              if (showDropdownIcon) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: active ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
