import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/demand_post.dart';
import '../../navigation/demand_board_navigation.dart';
import '../../services/demand_board_favorites_service.dart';
import '../../services/demand_repository.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../widgets/demand_inquiry_card.dart';
import '../../utils/page_safe_insets.dart';
import '../../theme/li_layout.dart';
import '../../widgets/consumer/consumer_page_shell.dart';

class SavedDemandBoardPage extends StatefulWidget {
  const SavedDemandBoardPage({super.key});

  @override
  State<SavedDemandBoardPage> createState() => _SavedDemandBoardPageState();
}

class _SavedDemandBoardPageState extends State<SavedDemandBoardPage> {
  final _repo = DemandRepository();
  List<DemandPost> _feed = [];
  bool _loading = true;
  bool _manageMode = false;
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    DemandBoardFavoritesService.instance.addListener(_refresh);
    DemandBoardFavoritesService.instance.load();
    _load();
  }

  @override
  void dispose() {
    DemandBoardFavoritesService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final posts = await _repo.fetchPosts();
      if (!mounted) return;
      setState(() {
        _feed = posts;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _exitManageMode() {
    setState(() {
      _manageMode = false;
      _selected.clear();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _toggleSelectAll(List<DemandPost> saved) {
    setState(() {
      if (_selected.length == saved.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(saved.map((p) => p.id));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final s = AppStrings.of(context);
    final count = _selected.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.savedDemandBoardDeleteSelected(count)),
        content: Text(s.savedDemandBoardDeleteConfirm(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await DemandBoardFavoritesService.instance.removeMany(_selected);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.savedDemandBoardRemoved)),
    );
    _exitManageMode();
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
    final saved = DemandBoardFavoritesService.instance.resolvePosts(_feed);

    return ConsumerPageShell(
      title: _manageMode && _selected.isNotEmpty
          ? '${s.savedDemandBoardTitle} (${_selected.length})'
          : s.savedDemandBoardTitle,
      onBack: () => Navigator.of(context).maybePop(),
      safeBottomBody: false,
      actions: saved.isEmpty
          ? const []
          : _manageMode
              ? [
                  ConsumerHeaderTextButton(
                    label: _selected.length == saved.length
                        ? s.savedListingsDeselectAll
                        : s.savedListingsSelectAll,
                    onTap: () => _toggleSelectAll(saved),
                  ),
                  ConsumerHeaderTextButton(
                    label: s.cancel,
                    onTap: _exitManageMode,
                  ),
                ]
              : [
                  ConsumerHeaderTextButton(
                    label: s.savedListingsManage,
                    onTap: () => setState(() => _manageMode = true),
                  ),
                ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : saved.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: AppTheme.primary.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s.savedDemandBoardEmpty,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.savedDemandBoardHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: PageSafeInsets.padLTRB(
                          context,
                          left: LiLayout.pagePadding,
                          top: LiLayout.pagePadding,
                          right: LiLayout.pagePadding,
                          bottom: _manageMode && _selected.isNotEmpty ? 88 : 16,
                          addHomeIndicator: false,
                        ),
                        itemCount: saved.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final p = saved[i];
                          final checked = _selected.contains(p.id);
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: DemandInquiryCard(
                                  post: p,
                                  timeLabel: _timeLabel(p, s),
                                  selectionMode: _manageMode,
                                  onTap: _manageMode
                                      ? () => _toggleSelect(p.id)
                                      : () => DemandBoardNavigation.openPostDetail(
                                            context,
                                            post: p,
                                          ),
                                  onOffer: () => DemandBoardNavigation.openSubmitOffer(
                                    context,
                                    post: p,
                                  ),
                                ),
                              ),
                              if (_manageMode) ...[
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Checkbox(
                                    value: checked,
                                    onChanged: (_) => _toggleSelect(p.id),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    if (_manageMode && _selected.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Material(
                          elevation: 8,
                          color: Colors.white,
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: LivingBkkBrand.accentOrange,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _deleteSelected,
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(
                                    s.savedDemandBoardDeleteSelected(
                                      _selected.length,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
