import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/home_promo_config.dart';
import '../../l10n/app_strings.dart';
import '../../models/home_promo_banner_row.dart';
import '../../services/home_promo_repository.dart';
import '../../services/home_promo_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../utils/promo_image_util.dart';
import '../../utils/promo_slug_util.dart';
import '../../widgets/home/home_promo_carousel.dart';
import '../../widgets/admin_mobile_layout.dart';
import '../../widgets/home/home_promo_image.dart';

/// แอดมิน — จัดการโฆษณา carousel หน้าแรก (สูงสุด 10 รายการ)
class AdminPromosTab extends StatefulWidget {
  const AdminPromosTab({super.key});

  @override
  State<AdminPromosTab> createState() => _AdminPromosTabState();
}

class _AdminPromosTabState extends State<AdminPromosTab> {
  final _repo = HomePromoRepository();

  List<HomePromoBannerRow> _rows = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      _rows = await _repo.listAll();
    } catch (_) {
      _rows = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  int get _activeCount => _rows.where((r) => r.isActive).length;

  Future<void> _toggleActive(HomePromoBannerRow row) async {
    if (!row.isActive && _activeCount >= HomePromoBannerRow.maxActive) {
      _snack(context.s.adminPromosMaxActive);
      return;
    }
    setState(() => _busy = true);
    try {
      await _repo.upsert(row.copyWith(isActive: !row.isActive));
      await _refresh();
      await HomePromoService.instance.refresh();
    } catch (e) {
      _snack(HomePromoRepository.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _move(HomePromoBannerRow row, {required bool up}) async {
    final sorted = [..._rows]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final i = sorted.indexWhere((r) => r.id == row.id);
    final j = up ? i - 1 : i + 1;
    if (i < 0 || j < 0 || j >= sorted.length) return;
    setState(() => _busy = true);
    try {
      await _repo.swapSortOrder(sorted[i], sorted[j]);
      await _refresh();
      await HomePromoService.instance.refresh();
    } catch (e) {
      _snack(HomePromoRepository.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(HomePromoBannerRow row) async {
    final s = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.adminPromosDeleteTitle),
        content: Text(s.adminPromosDeleteBody(row.titleTh)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      if (!row.id.startsWith('local-')) {
        await _repo.delete(row.id);
      }
      await _refresh();
      await HomePromoService.instance.refresh();
    } catch (e) {
      _snack(HomePromoRepository.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openEditor({HomePromoBannerRow? existing}) async {
    final s = context.s;
    final bool? saved;
    if (kIsWeb) {
      // Web: bottom sheet บัง file picker — ใช้หน้าเต็มแทน
      saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (ctx) => Scaffold(
            appBar: AppBar(
              title: Text(existing == null ? s.adminPromosAdd : s.adminPromosEdit),
            ),
            body: _PromoEditorSheet(
              initial: existing,
              activeCount: _activeCount,
              embedded: true,
            ),
          ),
        ),
      );
    } else {
      saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => _PromoEditorSheet(
          initial: existing,
          activeCount: _activeCount,
        ),
      );
    }
    if (saved == true) {
      await _refresh();
      await HomePromoService.instance.refresh();
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sorted = [..._rows]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Stack(
      children: [
        ListView(
          padding: AdminMobileLayout.scrollPadding(context, horizontal: 12, fabClearance: 64),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.adminPromosSpecTitle,
                        style: AdminTheme.title.copyWith(fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(
                      s.adminPromosSpecBody(
                        HomePromoConfig.imageWidthPx,
                        HomePromoConfig.imageHeightPx,
                      ),
                      style: AdminTheme.hint,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                s.adminPromosActiveCount(_activeCount, HomePromoBannerRow.maxActive),
                style: AdminTheme.hint,
              ),
            ),
            if (sorted.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(s.adminPromosEmpty, textAlign: TextAlign.center),
              )
            else
              ...sorted.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                final promo = row.toPromoItem();
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 72,
                            height: 31,
                            child: HomePromoImage(promo: promo, fit: BoxFit.cover),
                          ),
                        ),
                        title: Text(row.titleTh,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${row.slug} · #${row.sortOrder}'
                          '${row.isActive ? '' : ' · ${s.adminPromosInactive}'}',
                        ),
                        trailing: Switch(
                          value: row.isActive,
                          onChanged: _busy ? null : (_) => _toggleActive(row),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: _PromoCardActions(
                          busy: _busy,
                          isFirst: i == 0,
                          isLast: i == sorted.length - 1,
                          onMoveUp: () => _move(row, up: true),
                          onMoveDown: () => _move(row, up: false),
                          onEdit: () => _openEditor(existing: row),
                          onDelete: () => _delete(row),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
        AdminMobileLayout.stickyFooter(
          context,
          child: FilledButton.icon(
            onPressed: _busy || _activeCount >= HomePromoBannerRow.maxActive
                ? null
                : () => _openEditor(),
            icon: const Icon(Icons.add_rounded),
            label: Text(s.adminPromosAdd),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppTheme.primary,
            ),
          ),
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x22000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _PromoCardActions extends StatelessWidget {
  const _PromoCardActions({
    required this.busy,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
    required this.onDelete,
  });

  final bool busy;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final compact = AdminMobileLayout.isCompact(context);
    final children = [
      IconButton(
        tooltip: s.adminPromosMoveUp,
        onPressed: busy || isFirst ? null : onMoveUp,
        icon: const Icon(Icons.arrow_upward_rounded),
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      ),
      IconButton(
        tooltip: s.adminPromosMoveDown,
        onPressed: busy || isLast ? null : onMoveDown,
        icon: const Icon(Icons.arrow_downward_rounded),
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      ),
      TextButton.icon(
        onPressed: busy ? null : onEdit,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text(s.edit),
      ),
      if (!compact) const Spacer(),
      IconButton(
        tooltip: s.delete,
        onPressed: busy ? null : onDelete,
        icon: Icon(Icons.delete_outline, color: AppTheme.error),
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      ),
    ];

    if (compact) {
      return Wrap(
        spacing: 4,
        runSpacing: 0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      );
    }
    return Row(children: children);
  }
}

class _PromoEditorSheet extends StatefulWidget {
  const _PromoEditorSheet({
    this.initial,
    required this.activeCount,
    this.embedded = false,
  });

  final HomePromoBannerRow? initial;
  final int activeCount;
  final bool embedded;

  @override
  State<_PromoEditorSheet> createState() => _PromoEditorSheetState();
}

class _PromoEditorSheetState extends State<_PromoEditorSheet> {
  final _repo = HomePromoRepository();
  final _picker = ImagePicker();
  final _slug = TextEditingController();
  final _sort = TextEditingController();
  final _titleTh = TextEditingController();
  final _titleEn = TextEditingController();
  final _subtitleTh = TextEditingController();
  final _subtitleEn = TextEditingController();
  final _detailTh = TextEditingController();
  final _detailEn = TextEditingController();
  final _bulletTh = TextEditingController();
  final _bulletEn = TextEditingController();
  final _gradientStart = TextEditingController(text: '#12122B');
  final _gradientEnd = TextEditingController(text: '#FF5B8A');
  final _accent = TextEditingController(text: '#FFD54F');

  bool _active = true;
  bool _saving = false;
  bool _slugTouched = false;
  bool _slugEditing = false;
  bool _programmaticSlug = false;
  bool _uploading = false;
  String? _imageUrl;
  String? _imagePath;
  Uint8List? _pickedBytes;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    if (r != null) {
      _slug.text = r.slug;
      _slugTouched = true;
      _sort.text = '${r.sortOrder}';
      _titleTh.text = r.titleTh;
      _titleEn.text = r.titleEn;
      _subtitleTh.text = r.subtitleTh;
      _subtitleEn.text = r.subtitleEn;
      _detailTh.text = r.detailTh;
      _detailEn.text = r.detailEn;
      _bulletTh.text = r.bulletTh.join('\n');
      _bulletEn.text = r.bulletEn.join('\n');
      _gradientStart.text = r.gradientStart;
      _gradientEnd.text = r.gradientEnd;
      _accent.text = r.accentColor;
      _active = r.isActive;
      _imageUrl = r.imageUrl;
      _imagePath = r.imageStoragePath;
    } else {
      _sort.text = '${widget.activeCount + 1}';
    }
    _titleTh.addListener(_onFormChanged);
    _titleEn.addListener(_onFormChanged);
    _subtitleTh.addListener(_onFormChanged);
    _detailTh.addListener(_onFormChanged);
    _bulletTh.addListener(_onFormChanged);
    _slug.addListener(() {
      if (!_programmaticSlug && _slug.text.trim().isNotEmpty) {
        _slugTouched = true;
      }
    });
    if (widget.initial == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoSlug());
    }
  }

  void _maybeAutoSlug() {
    if (_slugTouched || widget.initial != null) return;
    _programmaticSlug = true;
    _slug.text = PromoSlugUtil.autofill(
      titleTh: _titleTh.text,
      titleEn: _titleEn.text,
    );
    _programmaticSlug = false;
  }

  void _onFormChanged() {
    _maybeAutoSlug();
    setState(() {});
  }

  @override
  void dispose() {
    _titleTh.removeListener(_onFormChanged);
    _titleEn.removeListener(_onFormChanged);
    _subtitleTh.removeListener(_onFormChanged);
    _detailTh.removeListener(_onFormChanged);
    _bulletTh.removeListener(_onFormChanged);
    _slug.dispose();
    _sort.dispose();
    _titleTh.dispose();
    _titleEn.dispose();
    _subtitleTh.dispose();
    _subtitleEn.dispose();
    _detailTh.dispose();
    _detailEn.dispose();
    _bulletTh.dispose();
    _bulletEn.dispose();
    _gradientStart.dispose();
    _gradientEnd.dispose();
    _accent.dispose();
    super.dispose();
  }

  List<String> _lines(TextEditingController c) =>
      c.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  String _resolvedSlug() {
    final manual = _slug.text.trim();
    if (manual.isNotEmpty) return manual;
    return PromoSlugUtil.autofill(titleTh: _titleTh.text, titleEn: _titleEn.text);
  }

  int _resolvedSort() {
    return (int.tryParse(_sort.text.trim()) ?? widget.activeCount + 1).clamp(1, 10);
  }

  HomePromoItem _buildPreviewItem(AppStrings s) {
    final base = widget.initial?.toPromoItem();
    final titleTh = _titleTh.text.trim().isEmpty
        ? (base?.titleTh ?? s.adminPromosDefaultTitle)
        : _titleTh.text.trim();
    final titleEn = _titleEn.text.trim().isEmpty ? titleTh : _titleEn.text.trim();
    return HomePromoItem(
      id: _resolvedSlug(),
      titleTh: titleTh,
      titleEn: titleEn,
      subtitleTh: _subtitleTh.text.trim(),
      subtitleEn: _subtitleEn.text.trim().isEmpty
          ? _subtitleTh.text.trim()
          : _subtitleEn.text.trim(),
      detailTh: _detailTh.text.trim(),
      detailEn: _detailEn.text.trim(),
      bulletTh: _lines(_bulletTh),
      bulletEn: _lines(_bulletEn),
      imageAsset: _imageUrl == null ? base?.imageAsset : null,
      imageUrl: _imageUrl ?? base?.imageUrl,
      gradient: _gradientFromFields(base),
      accentColor: _accentColorFromField(base),
      badgeTh: base?.badgeTh,
      badgeEn: base?.badgeEn,
    );
  }

  Gradient _gradientFromFields(HomePromoItem? base) {
    Color parse(String hex, Color fallback) {
      var h = hex.trim();
      if (h.startsWith('#')) h = h.substring(1);
      if (h.length == 6) h = 'FF$h';
      final v = int.tryParse(h, radix: 16);
      return v != null ? Color(v) : fallback;
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        parse(_gradientStart.text, const Color(0xFF12122B)),
        parse(_gradientEnd.text, const Color(0xFFFF5B8A)),
      ],
    );
  }

  Color _accentColorFromField(HomePromoItem? base) {
    var h = _accent.text.trim();
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    return v != null ? Color(v) : (base?.accentColor ?? const Color(0xFFFFD54F));
  }

  Future<void> _pickImage() async {
    final s = context.s;
    try {
      final file = await PromoImageUtil.pickPromoImage(_picker);
      if (file == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.adminPromosPickCancelled)),
          );
        }
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _pickedBytes = bytes);

      setState(() => _uploading = true);
      try {
        final result = await _repo.uploadImage(slug: _resolvedSlug(), file: file);
        if (!mounted) return;
        setState(() {
          _imageUrl = result.url;
          _imagePath = result.path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.adminPromosUploadDone)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${HomePromoRepository.friendlyError(e)}\n${s.adminPromosUploadFailed}',
            ),
          ),
        );
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(HomePromoRepository.friendlyError(e))),
      );
    }
  }

  Future<void> _save() async {
    final s = context.s;
    final hasImage = _imageUrl != null || widget.initial?.imageUrl != null;
    if (_titleTh.text.trim().isEmpty && !hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminPromosNeedTitleOrImage)),
      );
      return;
    }
    if (_active &&
        widget.initial?.isActive != true &&
        widget.activeCount >= HomePromoBannerRow.maxActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminPromosMaxActive)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final titleTh = _titleTh.text.trim().isEmpty
          ? s.adminPromosDefaultTitle
          : _titleTh.text.trim();
      final row = HomePromoBannerRow(
        id: widget.initial?.id ?? '',
        slug: _resolvedSlug(),
        sortOrder: _resolvedSort(),
        isActive: _active,
        titleTh: titleTh,
        titleEn: _titleEn.text.trim().isEmpty ? titleTh : _titleEn.text.trim(),
        subtitleTh: _subtitleTh.text.trim(),
        subtitleEn: _subtitleEn.text.trim(),
        detailTh: _detailTh.text.trim().isEmpty
            ? (_subtitleTh.text.trim().isEmpty ? titleTh : _subtitleTh.text.trim())
            : _detailTh.text.trim(),
        detailEn: _detailEn.text.trim(),
        bulletTh: _lines(_bulletTh),
        bulletEn: _lines(_bulletEn),
        imageUrl: _imageUrl ?? widget.initial?.imageUrl,
        imageStoragePath: _imagePath ?? widget.initial?.imageStoragePath,
        gradientStart: _gradientStart.text.trim(),
        gradientEnd: _gradientEnd.text.trim(),
        accentColor: _accent.text.trim(),
      );
      await _repo.upsert(row);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(HomePromoRepository.friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final preview = _buildPreviewItem(s);
    final slug = _resolvedSlug();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AdminTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (!widget.embedded) ...[
              const SizedBox(height: 12),
              Text(
                widget.initial == null ? s.adminPromosAdd : s.adminPromosEdit,
                style: AdminTheme.title.copyWith(fontSize: 18),
              ),
            ],
            const SizedBox(height: 14),
            _PromoAdminPreview(
              promo: preview,
              strings: s,
              memoryBytes: _pickedBytes,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: (_saving || _uploading) ? null : _pickImage,
              icon: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_rounded),
              label: Text(s.adminPromosUploadImage),
            ),
            Text(s.adminPromosUploadHint, style: AdminTheme.hint),
            const SizedBox(height: 14),
            _field(s.adminPromosTitleThRequired, _titleTh),
            _field(s.adminPromosSubtitleThOptional, _subtitleTh),
            _field(s.adminPromosDetailTh, _detailTh, maxLines: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${s.adminPromosSlugAuto}: $slug',
                    style: AdminTheme.hint.copyWith(fontFamily: 'monospace'),
                  ),
                ),
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() => _slugEditing = !_slugEditing),
                  child: Text(s.adminPromosSlugEdit),
                ),
              ],
            ),
            if (_slugEditing)
              _field(s.adminPromosSlug, _slug, enabled: widget.initial == null),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(s.adminPromosSectionOptional,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              children: [
                _field(s.adminPromosTitleEn, _titleEn),
                _field(s.adminPromosSubtitleEn, _subtitleEn),
                _field(s.adminPromosDetailEn, _detailEn, maxLines: 3),
                _field(s.adminPromosBulletsTh, _bulletTh,
                    maxLines: 5, hint: s.adminPromosBulletsHint),
                _field(s.adminPromosBulletsEn, _bulletEn,
                    maxLines: 5, hint: s.adminPromosBulletsHint),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(s.adminPromosSectionAdvanced,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              children: [
                _field(s.adminPromosSort, _sort, keyboard: TextInputType.number),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.adminPromosActive),
                  value: _active,
                  onChanged: _saving ? null : (v) => setState(() => _active = v),
                ),
                Row(
                  children: [
                    Expanded(
                        child: _field(s.adminPromosGradientStart, _gradientStart)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(s.adminPromosGradientEnd, _gradientEnd)),
                  ],
                ),
                _field(s.adminPromosAccent, _accent),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(s.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    int maxLines = 1,
    String? hint,
    bool enabled = true,
    TextInputType? keyboard,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        enabled: enabled && !_saving,
        maxLines: maxLines,
        keyboardType: keyboard,
        onChanged: onChanged,
        inputFormatters:
            keyboard == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

/// พรีวิวสองจุด: carousel (รูปอย่างเดียว) + sheet รายละเอียดเมื่อแตะ
class _PromoAdminPreview extends StatelessWidget {
  const _PromoAdminPreview({
    required this.promo,
    required this.strings,
    this.memoryBytes,
  });

  final HomePromoItem promo;
  final AppStrings strings;
  final Uint8List? memoryBytes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(strings.adminPromosPreviewHome,
            style: AdminTheme.title.copyWith(fontSize: 13)),
        const SizedBox(height: 4),
        Text(strings.adminPromosPreviewHomeHint, style: AdminTheme.hint),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF6B4FC4),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(HomePromoCarousel.slideRadius),
                  child: SizedBox(
                    height: HomePromoCarousel.maxBannerHeight,
                    child: HomePromoImage(
                      promo: promo,
                      fit: BoxFit.cover,
                      memoryBytes: memoryBytes,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Opacity(
                opacity: 0.55,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(HomePromoCarousel.slideRadius),
                  child: SizedBox(
                    width: 36,
                    height: HomePromoCarousel.maxBannerHeight,
                    child: HomePromoImage(
                      promo: promo,
                      fit: BoxFit.cover,
                      memoryBytes: memoryBytes,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(strings.adminPromosPreviewDetail,
            style: AdminTheme.title.copyWith(fontSize: 13)),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: HomePromoConfig.imageAspectRatio,
                    child: HomePromoImage(
                      promo: promo,
                      fit: BoxFit.cover,
                      memoryBytes: memoryBytes,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  promo.titleTh,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                if (promo.subtitleTh.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(promo.subtitleTh, style: AdminTheme.hint),
                ],
                const SizedBox(height: 8),
                Text(
                  promo.detailTh.isNotEmpty
                      ? promo.detailTh
                      : strings.adminPromosDetailPreviewHint,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: promo.detailTh.isEmpty ? AdminTheme.hint.color : null,
                    fontStyle:
                        promo.detailTh.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                if (promo.bulletTh.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final b in promo.bulletTh.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 16, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Expanded(child: Text(b, style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
