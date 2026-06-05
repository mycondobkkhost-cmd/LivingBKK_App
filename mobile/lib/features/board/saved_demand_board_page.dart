import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/demand_post.dart';
import '../../navigation/demand_board_navigation.dart';
import '../../services/demand_board_favorites_service.dart';
import '../../services/demand_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/demand_inquiry_card.dart';

class SavedDemandBoardPage extends StatefulWidget {
  const SavedDemandBoardPage({super.key});

  @override
  State<SavedDemandBoardPage> createState() => _SavedDemandBoardPageState();
}

class _SavedDemandBoardPageState extends State<SavedDemandBoardPage> {
  final _repo = DemandRepository();
  List<DemandPost> _feed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DemandBoardFavoritesService.instance.addListener(_refresh);
    _load();
  }

  @override
  void dispose() {
    DemandBoardFavoritesService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => _load();

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

    return Scaffold(
      backgroundColor: AppTheme.surfaceWarm,
      appBar: AppBar(title: Text(s.savedDemandBoardTitle)),
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    itemCount: saved.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = saved[i];
                      return DemandInquiryCard(
                        post: p,
                        timeLabel: _timeLabel(p, s),
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
    );
  }
}
