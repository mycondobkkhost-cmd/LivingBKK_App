import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

enum ListingGalleryVariant {
  /// การ์ด / รายการทั่วไป
  compact,

  /// หน้ารายละเอียดแบบ LI — รูปใหญ่ + thumbnail แถวล่าง
  detail,
}

class ListingImageGallery extends StatefulWidget {
  const ListingImageGallery({
    super.key,
    required this.imageUrls,
    this.variant = ListingGalleryVariant.detail,
  });

  final List<String> imageUrls;
  final ListingGalleryVariant variant;

  @override
  State<ListingImageGallery> createState() => _ListingImageGalleryState();
}

class _ListingImageGalleryState extends State<ListingImageGallery> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _go(int delta) {
    if (widget.imageUrls.isEmpty) return;
    final next = (_index + delta).clamp(0, widget.imageUrls.length - 1);
    if (next == _index) return;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _openFullscreen([int? startIndex]) {
    if (widget.imageUrls.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenGallery(
          urls: widget.imageUrls,
          initialIndex: startIndex ?? _index,
        ),
      ),
    );
  }

  void _selectThumb(int i) {
    setState(() => _index = i);
    _pageController.jumpToPage(i);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variant == ListingGalleryVariant.compact) {
      return _buildCompact(context);
    }
    return _buildDetail(context);
  }

  Widget _buildDetail(BuildContext context) {
    final s = AppStrings.of(context);
    final urls = widget.imageUrls;

    if (urls.isEmpty) {
      return Container(
        height: 260,
        color: AppTheme.primaryLight,
        child: Center(
          child: Icon(Icons.photo_library_outlined, size: 56, color: AppTheme.primary),
        ),
      );
    }

    final thumbCount = urls.length > 4 ? 3 : urls.length.clamp(0, 4);
    final showAllTile = urls.length > 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 280,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () => _openFullscreen(_index),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: urls.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => Image.network(
                    urls[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.primaryLight,
                      child: const Icon(Icons.broken_image_outlined, size: 48),
                    ),
                  ),
                ),
              ),
              if (urls.length > 1)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: GestureDetector(
                    onTap: urls.length > 4 ? () => _openFullscreen(_index) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        urls.length > 4
                            ? '${_index + 1}/${urls.length} · +${urls.length - 4}'
                            : '${_index + 1} / ${urls.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: _ArrowButton(
                  icon: Icons.fullscreen_outlined,
                  onTap: () => _openFullscreen(_index),
                ),
              ),
              if (_index > 0)
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ArrowButton(icon: Icons.chevron_left, onTap: () => _go(-1)),
                  ),
                ),
              if (_index < urls.length - 1)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ArrowButton(icon: Icons.chevron_right, onTap: () => _go(1)),
                  ),
                ),
            ],
          ),
        ),
        if (urls.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                for (var i = 0; i < thumbCount; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < thumbCount - 1 || showAllTile ? 8 : 0),
                      child: _ThumbTile(
                        url: urls[i],
                        selected: _index == i,
                        onTap: () => _selectThumb(i),
                      ),
                    ),
                  ),
                if (showAllTile)
                  Expanded(
                    child: _ThumbTile(
                      url: urls[3],
                      overlayLabel: s.showAllPhotos(urls.length),
                      onTap: () => _openFullscreen(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCompact(BuildContext context) {
    final urls = widget.imageUrls;
    if (urls.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Center(
            child: Icon(Icons.photo_library_outlined, size: 56, color: AppTheme.primary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: AppTheme.cardTint,
          child: InkWell(
            onTap: () => _openFullscreen(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: urls.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) => Image.network(
                      urls[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.primaryLight,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
                if (_index > 0)
                  Positioned(
                    left: 8,
                    child: _ArrowButton(icon: Icons.chevron_left, onTap: () => _go(-1)),
                  ),
                if (_index < urls.length - 1)
                  Positioned(
                    right: 8,
                    child: _ArrowButton(icon: Icons.chevron_right, onTap: () => _go(1)),
                  ),
                Positioned(
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_index + 1} / ${urls.length}',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThumbTile extends StatelessWidget {
  const _ThumbTile({
    required this.url,
    required this.onTap,
    this.selected = false,
    this.overlayLabel,
  });

  final String url;
  final VoidCallback onTap;
  final bool selected;
  final String? overlayLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.15,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppTheme.primaryLight),
              ),
              if (overlayLabel != null)
                Container(
                  color: Colors.black45,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_outlined, color: Colors.white, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        overlayLabel!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              if (selected && overlayLabel == null)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primary, width: 2.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery({
    required this.urls,
    required this.initialIndex,
  });

  final List<String> urls;
  final int initialIndex;

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller;
  late int _index;
  final _transforms = <int, TransformationController>{};
  final _panEnabled = <int, bool>{};

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  TransformationController _transformFor(int i) {
    return _transforms.putIfAbsent(i, () {
      final tc = TransformationController();
      tc.addListener(() => _syncPan(i));
      return tc;
    });
  }

  void _syncPan(int i) {
    final zoomed = _transformFor(i).value.getMaxScaleOnAxis() > 1.01;
    if (_panEnabled[i] == zoomed) return;
    setState(() => _panEnabled[i] = zoomed);
  }

  bool get _pageScrollLocked => _panEnabled[_index] == true;

  void _onPageChanged(int i) {
    setState(() => _index = i);
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final tc in _transforms.values) {
      tc.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.urls.length,
        physics: _pageScrollLocked
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        onPageChanged: _onPageChanged,
        itemBuilder: (_, i) => InteractiveViewer(
          transformationController: _transformFor(i),
          panEnabled: _panEnabled[i] ?? false,
          scaleEnabled: true,
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.network(
              widget.urls[i],
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
