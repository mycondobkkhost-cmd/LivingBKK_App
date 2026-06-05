import 'package:flutter/material.dart';

/// สไลด์รูปบนการ์ดทรัพย์ — ที่ขอบรูปสุดท้าย/แรก ส่งต่อให้ rail เลื่อนประกาศถัดไป
class PropertyCardImagePager extends StatefulWidget {
  const PropertyCardImagePager({
    super.key,
    required this.imageUrls,
    required this.placeholder,
    this.overlay,
    this.railScrollController,
    this.railStep = 292,
    this.onImageDragStart,
    this.onImageDragEnd,
    this.onTap,
  });

  final List<String> imageUrls;
  final Widget placeholder;
  final Widget? overlay;
  final ScrollController? railScrollController;
  final double railStep;
  final VoidCallback? onImageDragStart;
  final VoidCallback? onImageDragEnd;
  final VoidCallback? onTap;

  @override
  State<PropertyCardImagePager> createState() => _PropertyCardImagePagerState();
}

class _PropertyCardImagePagerState extends State<PropertyCardImagePager> {
  late final PageController _controller;
  int _index = 0;
  double _dragTotal = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _animateRail(double delta) async {
    final rail = widget.railScrollController;
    if (rail == null || !rail.hasClients) return;
    final target = (rail.offset + delta).clamp(0.0, rail.position.maxScrollExtent);
    await rail.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onDragStart(DragStartDetails details) {
    widget.onImageDragStart?.call();
  }

  void _onDragEnd(DragEndDetails details) {
    widget.onImageDragEnd?.call();
    final urls = widget.imageUrls;
    if (urls.length <= 1) {
      _dragTotal = 0;
      return;
    }

    final velocity = details.primaryVelocity ?? 0;
    final goingNext = velocity < -220 || _dragTotal < -28;
    final goingPrev = velocity > 220 || _dragTotal > 28;
    _dragTotal = 0;

    if (goingNext) {
      if (_index < urls.length - 1) {
        _controller.nextPage(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      } else {
        _animateRail(widget.railStep);
      }
    } else if (goingPrev) {
      if (_index > 0) {
        _controller.previousPage(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      } else {
        _animateRail(-widget.railStep);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;
    if (urls.isEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          widget.placeholder,
          if (widget.overlay != null) widget.overlay!,
        ],
      );
    }

    if (urls.length == 1) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            urls.first,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => widget.placeholder,
          ),
          if (widget.overlay != null) widget.overlay!,
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: (d) => _dragTotal += d.delta.dx,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: () {
        widget.onImageDragEnd?.call();
        _dragTotal = 0;
      },
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => Image.network(
              urls[i],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => widget.placeholder,
            ),
          ),
          if (widget.overlay != null) widget.overlay!,
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < urls.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _index ? 7 : 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i == _index
                          ? Colors.white
                          : Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
