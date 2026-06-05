import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/bangkok_project_meta.dart';
import '../../models/listing_public.dart';
import '../../services/chat_service.dart';
import '../../services/co_agent_repository.dart';
import '../../services/favorites_service.dart';
import '../../services/listing_activity_service.dart';
import '../../services/listing_repository.dart';
import '../../services/preferred_stock_service.dart';
import '../../utils/listing_navigation.dart';
import '../../l10n/app_strings.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/localized_content.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../utils/listing_share_actions.dart';
import '../../widgets/design_system/app_button.dart';
import '../../widgets/listing_image_gallery.dart';
import '../../widgets/listings_map.dart';
import '../../widgets/reference_code_chip.dart';
import '../../shell/main_shell_scope.dart';
import '../contact/property_chat_page.dart';

class ListingDetailPage extends StatefulWidget {
  const ListingDetailPage({
    super.key,
    required this.listing,
    this.isAgent = false,
  });

  final ListingPublic listing;
  final bool isAgent;

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  final _coAgentRepo = CoAgentRepository();
  final _listingRepo = ListingRepository();
  bool _requesting = false;
  bool _bookingBusy = false;
  bool _showViewingBanner = true;
  int _siblingCount = 0;

  @override
  void initState() {
    super.initState();
    ListingActivityService.instance.recordView(widget.listing);
    PreferredStockService.instance.load();
    FavoritesService.instance.load();
    _loadSiblingCount();
  }

  Future<void> _loadSiblingCount() async {
    try {
      final all = await _listingRepo.fetchPublished();
      final listing = widget.listing;
      final count = all.where((l) {
        if (l.id == listing.id) return false;
        if (listing.projectSlug != null &&
            listing.projectSlug!.isNotEmpty &&
            l.projectSlug == listing.projectSlug) {
          return true;
        }
        if (listing.projectName != null && l.projectName == listing.projectName) {
          return true;
        }
        return false;
      }).length;
      if (mounted) setState(() => _siblingCount = count);
    } catch (_) {}
  }

  void _openProjectUnits() {
    final name = widget.listing.projectName;
    if (name == null || name.isEmpty) return;
    ListingNavigation.openProjectUnits(
      context,
      projectName: name,
      projectSlug: widget.listing.projectSlug,
      isAgent: widget.isAgent,
    );
  }

  void _openLocationTag(String label, {List<String>? geoSlugs, String? projectSlug}) {
    if (projectSlug != null && projectSlug.isNotEmpty) {
      ListingNavigation.openProject(
        context,
        projectName: widget.listing.projectName ?? label,
        projectSlug: projectSlug,
        isAgent: widget.isAgent,
      );
      return;
    }
    ListingNavigation.openTag(
      context,
      tagLabel: label,
      geoZoneSlugs: geoSlugs?.isNotEmpty == true
          ? geoSlugs!
          : [label.toLowerCase().replaceAll(' ', '-')],
      isAgent: widget.isAgent,
    );
  }

  Future<void> _togglePreferred() async {
    await PreferredStockService.instance.toggle(widget.listing.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).preferredStockSaved)),
    );
    setState(() {});
  }

  Future<void> _requestCoAgent() async {
    final s = AppStrings.of(context);
    setState(() => _requesting = true);
    try {
      await _coAgentRepo.requestCoAgent(listingId: widget.listing.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.coAgentRequestSent)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  void _openChat() {
    ListingActivityService.instance.recordChatStart(widget.listing.id);
    openPropertyChat(
      context,
      widget.listing,
      allowViewingRequest: true,
    );
  }

  Future<void> _openBookProperty() async {
    ListingActivityService.instance.recordChatStart(widget.listing.id);
    final s = AppStrings.of(context);
    setState(() => _bookingBusy = true);
    try {
      final room = await ChatService.instance.recordBookingInterest(
        listing: widget.listing,
        isEnglish: s.isEnglish,
      );
      if (!mounted) return;
      MainShellScope.maybeOf(context)?.selectTab(3);
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => PropertyChatPage(room: room),
        ),
      );
    } finally {
      if (mounted) setState(() => _bookingBusy = false);
    }
  }

  void _openScheduleViewing() {
    ListingActivityService.instance.recordChatStart(widget.listing.id);
    openPropertyChat(
      context,
      widget.listing,
      allowViewingRequest: true,
      openViewingForm: true,
    );
  }

  int _simulatedLiveViewers(ListingPublic listing) {
    final views = ListingActivityService.instance.viewCount(listing.id);
    return (views % 4) + 2;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final listing = widget.listing;
    final en = s.isEnglish;
    final currency = NumberFormat.currency(
      locale: en ? 'en_US' : 'th_TH',
      symbol: '฿',
      decimalDigits: 0,
    );
    final price = currency.format(listing.priceNet);
    final priceSuffix = listing.listingType == 'rent' ? s.perMonth : '';
    final sqmPrice = listing.areaSqm != null && listing.areaSqm! > 0
        ? s.pricePerSqm(
            NumberFormat('#,###', en ? 'en_US' : 'th_TH')
                .format((listing.priceNet / listing.areaSqm!).round()),
          )
        : null;
    final projectMeta = BangkokProjectMeta.forProject(listing.projectName);
    final project = BangkokProjectMeta.findProject(listing.projectName);
    final localizedDesc = listing.localizedDescription(en);
    final description = localizedDesc.isNotEmpty
        ? localizedDesc
        : (en
            ? 'Great location near ${project?.bts ?? listing.localizedDistrict(en) ?? 'Bangkok'}. '
                'Ideal for ${listing.listingType == 'rent' ? 'renting' : 'living or investment'}.'
            : 'ทำเลดี ใกล้${project?.bts ?? listing.district ?? 'กรุงเทพ'} '
                'เหมาะ${listing.listingType == 'rent' ? 'เช่าอยู่อาศัย' : 'ลงทุนหรืออยู่อาศัย'}');
    final liveViewers = _simulatedLiveViewers(listing);

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: ListingImageGallery(imageUrls: listing.imageUrls)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.localizedTitle(en),
                        style: AppTypography.textTheme(p).headlineMedium!.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 8),
                      ReferenceCodeChip(
                        code: listing.listingCode,
                        label: s.propertyCodeLabel,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 16, color: p.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [
                                listing.localizedDistrict(en),
                                listing.localizedProjectName(en) ?? listing.projectName,
                              ].whereType<String>().where((e) => e.isNotEmpty).join(' · '),
                              style: TextStyle(fontSize: 14, color: p.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PropertyFactsRow(listing: listing),
                      const SizedBox(height: 8),
                      Text(
                        '${s.listingLastUpdated} · ${s.listingUpdatedAgo(listing.effectiveUpdatedAt)}',
                        style: TextStyle(fontSize: 12, color: p.textSecondary),
                      ),
                      if (listing.localizedProjectName(en) != null) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _openProjectUnits,
                          child: Text(
                            listing.localizedProjectName(en)!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: p.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: p.primary,
                            ),
                          ),
                        ),
                      ],
                      if (_siblingCount > 0) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _openProjectUnits,
                          icon: const Icon(Icons.apartment_outlined, size: 18),
                          label: Text(
                            s.moreRoomsInProject(
                              _siblingCount,
                              listing.localizedProjectName(en) ??
                                  listing.projectName ??
                                  s.t('โครงการนี้', 'this project'),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: p.primary,
                            side: BorderSide(color: p.primary),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _sectionTitle(s.listingDetailsSection, p),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(height: 1.55, fontSize: 15, color: p.textPrimary),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TagChip(
                            label: s.propertyTypeChip(listing.propertyType),
                            color: AppTheme.primary,
                            onTap: () => ListingNavigation.openCategory(
                              context,
                              slug: listing.propertyType,
                              isAgent: widget.isAgent,
                            ),
                          ),
                          _TagChip(
                            label: s.listingTransactionLabel(listing.listingType),
                            color: AppTheme.accentSoft,
                          ),
                          if (project?.bts != null)
                            _TagChip(
                              label: project!.bts!,
                              color: AppTheme.accentDeep,
                              onTap: () => _openLocationTag(
                                project.bts!,
                                geoSlugs: project.geoZoneId != null
                                    ? [project.geoZoneId!]
                                    : null,
                              ),
                            ),
                          if (listing.localizedDistrict(en) != null)
                            _TagChip(
                              label: listing.localizedDistrict(en)!,
                              color: AppTheme.accentMid,
                              onTap: () => _openLocationTag(
                                listing.localizedDistrict(en)!,
                                geoSlugs: listing.geoZoneSlug != null
                                    ? [listing.geoZoneSlug!]
                                    : null,
                              ),
                            ),
                          if (listing.projectSlug != null || listing.projectName != null)
                            _TagChip(
                              label: listing.localizedProjectName(en) ??
                                  listing.projectName ??
                                  s.t('โครงการ', 'Project'),
                              color: AppTheme.primary,
                              onTap: _openProjectUnits,
                            ),
                          if (listing.coAgentListingType == 'owner_direct')
                            _TagChip(label: s.listingStockOwnerDirect, color: AppTheme.accentMid),
                          if (listing.coAgentListingType == 'co_agent_50_50')
                            _TagChip(label: s.listingStockCoAgent, color: AppTheme.accentDeep),
                          if (listing.coAgentEligible)
                            _TagChip(label: s.coAgentEligible, color: AppTheme.accentMuted),
                        ],
                      ),
                      if (widget.isAgent && listing.coAgentEligible) ...[
                        const SizedBox(height: 16),
                        AppButton(
                          label: s.detailOfferCta,
                          variant: AppButtonVariant.outlined,
                          icon: Icons.handshake_outlined,
                          loading: _requesting,
                          onPressed: _requesting ? null : _requestCoAgent,
                        ),
                      ],
                      const SizedBox(height: 22),
                      _sectionTitle(s.projectDetailsSection, p),
                      const SizedBox(height: 10),
                      _infoRow(
                        s.yearBuiltLabel,
                        en
                            ? '${projectMeta.yearBuilt} CE'
                            : '${projectMeta.yearBuilt + 543} (พ.ศ.) / ${projectMeta.yearBuilt}',
                      ),
                      if (project?.bts != null) _infoRow(s.locationLabel, project!.bts!),
                      if (listing.localizedDistrict(en) != null)
                        _infoRow(s.districtField, listing.localizedDistrict(en)!),
                      if (listing.localizedFloorRange(en) != null)
                        _infoRow(s.floorLabel, listing.localizedFloorRange(en)!),
                      const SizedBox(height: 10),
                      Text(
                        s.commonFacilities,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: s
                            .localizedFacilities(projectMeta.facilities)
                            .map(
                              (f) => Chip(
                                label: Text(f, style: TextStyle(fontSize: 12)),
                                backgroundColor: AppTheme.primaryLight,
                                side: BorderSide.none,
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 200,
                          child: listing.lat != null && listing.lng != null
                              ? ListingsMap(listings: [listing])
                              : Container(
                                  color: AppTheme.primaryLight.withOpacity(0.4),
                                  child: Center(
                                    child: Text(
                                      s.mapApproxHint,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
                child: Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    _FloatingToolBar(
                      listingId: listing.id,
                      isAgent: widget.isAgent,
                      onShare: () {
                        ListingActivityService.instance.recordShare(listing.id);
                        ListingShareActions.shareLink(listing, isEnglish: s.isEnglish);
                      },
                      onDownload: () =>
                          ListingShareActions.downloadAllPhotos(context, listing),
                      onPreferred: widget.isAgent ? _togglePreferred : null,
                      onChat: _openChat,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _StickyDetailBar(
        price: '$price$priceSuffix',
        sqmPrice: sqmPrice,
        contactLabel: s.detailContactCta,
        bookLabel: s.detailBookPropertyCta,
        scheduleLabel: s.detailScheduleCta,
        onContact: _openChat,
        onBook: _openBookProperty,
        onSchedule: _openScheduleViewing,
        bookLoading: _bookingBusy,
        showViewersBanner: _showViewingBanner,
        viewersText: s.peopleViewingNow(liveViewers),
        onDismissViewers: () => setState(() => _showViewingBanner = false),
      ),
    );
  }

  Widget _sectionTitle(String t, AppPalette p) => Text(
        t,
        style: AppTypography.textTheme(p).titleLarge!.copyWith(fontSize: 17),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Text(
                label,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
}

class _FloatingToolBar extends StatelessWidget {
  const _FloatingToolBar({
    required this.listingId,
    required this.isAgent,
    required this.onShare,
    required this.onDownload,
    required this.onChat,
    this.onPreferred,
  });

  final String listingId;
  final bool isAgent;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback onChat;
  final VoidCallback? onPreferred;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Material(
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(999),
      color: AppTheme.cardTint,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListenableBuilder(
              listenable: FavoritesService.instance,
              builder: (context, _) {
                final fav = FavoritesService.instance.isFavorite(listingId);
                return _ToolIcon(
                  icon: fav ? Icons.favorite : Icons.favorite_border,
                  color: fav ? AppTheme.error : AppTheme.textSecondary,
                  onTap: () => FavoritesService.instance.toggle(listingId),
                );
              },
            ),
            _ToolIcon(icon: Icons.ios_share, onTap: onShare),
            _ToolIcon(icon: Icons.download_outlined, onTap: onDownload),
            if (isAgent && onPreferred != null)
              ListenableBuilder(
                listenable: PreferredStockService.instance,
                builder: (context, _) {
                  final on = PreferredStockService.instance.contains(listingId);
                  return _ToolIcon(
                    icon: on ? Icons.bookmark : Icons.bookmark_outline,
                    onTap: onPreferred!,
                  );
                },
              ),
            const SizedBox(width: 4),
            Material(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: onChat,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        s.detailAskInfoCta,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 22, color: color ?? AppTheme.textSecondary),
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color, this.onTap});

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: chip,
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _LiveViewersBanner extends StatefulWidget {
  const _LiveViewersBanner({required this.text, required this.onDismiss});

  final String text;
  final VoidCallback onDismiss;

  @override
  State<_LiveViewersBanner> createState() => _LiveViewersBannerState();
}

class _LiveViewersBannerState extends State<_LiveViewersBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: const Color(0xFFFFF7ED),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final t = _pulse.value;
                return ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Color.lerp(const Color(0xFFFF4500), const Color(0xFFFFD700), t)!,
                      Color.lerp(const Color(0xFFFF8C00), const Color(0xFFFF4500), t)!,
                    ],
                  ).createShader(bounds),
                  child: child,
                );
              },
              child: const Text('🔥', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9A3412),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Color(0xFF9A3412)),
              visualDensity: VisualDensity.compact,
              onPressed: widget.onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyFactsRow extends StatelessWidget {
  const _PropertyFactsRow({required this.listing});

  final ListingPublic listing;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = context.palette;
    final facts = <_FactItem>[
      if (listing.bedrooms != null)
        _FactItem(
          icon: Icons.bed_outlined,
          label: listing.bedrooms == 0
              ? s.filterStudio
              : s.bedCount(listing.bedrooms!),
        ),
      if (listing.areaSqm != null)
        _FactItem(icon: Icons.square_foot_outlined, label: s.sqmShort(listing.areaSqm!.toInt())),
      if (listing.localizedFloorRange(s.isEnglish) != null)
        _FactItem(
          icon: Icons.layers_outlined,
          label: listing.localizedFloorRange(s.isEnglish)!,
        ),
      if (listing.petAllowed)
        _FactItem(icon: Icons.pets_outlined, label: s.filterPetAllowed),
      _FactItem(
        icon: Icons.apartment_outlined,
        label: s.propertyTypeChip(listing.propertyType),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: p.divider),
          bottom: BorderSide(color: p.divider),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: facts
            .map(
              (f) => Expanded(
                child: Column(
                  children: [
                    Icon(f.icon, size: 22, color: p.textSecondary),
                    const SizedBox(height: 6),
                    Text(
                      f.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FactItem {
  const _FactItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _StickyDetailBar extends StatelessWidget {
  const _StickyDetailBar({
    required this.price,
    required this.contactLabel,
    required this.bookLabel,
    required this.scheduleLabel,
    required this.onContact,
    required this.onBook,
    required this.onSchedule,
    this.sqmPrice,
    this.bookLoading = false,
    this.showViewersBanner = false,
    this.viewersText = '',
    this.onDismissViewers,
  });

  final String price;
  final String? sqmPrice;
  final String contactLabel;
  final String bookLabel;
  final String scheduleLabel;
  final VoidCallback onContact;
  final VoidCallback onBook;
  final VoidCallback onSchedule;
  final bool bookLoading;
  final bool showViewersBanner;
  final String viewersText;
  final VoidCallback? onDismissViewers;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      elevation: 12,
      shadowColor: p.navShadow,
      color: p.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showViewersBanner && onDismissViewers != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LiveViewersBanner(
                    text: viewersText,
                    onDismiss: onDismissViewers!,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      price,
                      style: AppTypography.price(p).copyWith(fontSize: 20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (sqmPrice != null)
                    Text(
                      sqmPrice!,
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: AppButton(
                        label: contactLabel,
                        variant: AppButtonVariant.outlined,
                        expand: false,
                        height: 44,
                        onPressed: onContact,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: bookLoading ? null : onBook,
                      style: FilledButton.styleFrom(
                        backgroundColor: LivingBkkBrand.loginAccentBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        ),
                      ),
                      child: bookLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              bookLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: AppButton(
                        label: scheduleLabel,
                        variant: AppButtonVariant.accent,
                        expand: false,
                        height: 44,
                        onPressed: onSchedule,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
