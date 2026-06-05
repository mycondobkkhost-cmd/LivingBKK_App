import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/demand_post.dart';
import '../../services/demand_board_favorites_service.dart';
import '../../theme/app_theme.dart';

/// ปุ่มบันทึกประกาศบอร์ด — กดแล้วเก็บไว้ดูทีหลัง
class DemandPostFavoriteButton extends StatefulWidget {
  const DemandPostFavoriteButton({
    super.key,
    required this.post,
    this.iconSize = 20,
    this.showSnackBar = true,
  });

  final DemandPost post;
  final double iconSize;
  final bool showSnackBar;

  @override
  State<DemandPostFavoriteButton> createState() =>
      _DemandPostFavoriteButtonState();
}

class _DemandPostFavoriteButtonState extends State<DemandPostFavoriteButton> {
  @override
  void initState() {
    super.initState();
    DemandBoardFavoritesService.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    DemandBoardFavoritesService.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _toggle() async {
    final added = await DemandBoardFavoritesService.instance.toggle(widget.post);
    if (!mounted || !widget.showSnackBar) return;
    final s = AppStrings.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(added ? s.demandFavoriteSaved : s.demandFavoriteRemoved),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fav = DemandBoardFavoritesService.instance.isFavorite(widget.post.id);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _toggle,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            fav ? Icons.favorite : Icons.favorite_border,
            size: widget.iconSize,
            color: fav ? Colors.redAccent : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
