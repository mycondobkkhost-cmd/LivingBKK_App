import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../config/home_promo_config.dart';
import '../../l10n/app_strings.dart';
import '../../services/home_promo_service.dart';
import '../../state/locale_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/fb_feed_chrome.dart';
import '../../theme/living_bkk_brand.dart';
import 'home_promo_detail_sheet.dart';
import 'home_promo_image.dart';

/// โฆษณาหน้าแรก — 2 แถบขนาดเท่ากัน
/// ซ้าย: สไลด์รูป · ขวา: วิดีโอสั้น
class HomePromoCarousel extends StatefulWidget {
  const HomePromoCarousel({
    super.key,
    required this.localeController,
  });

  final LocaleController localeController;

  /// อัตราส่วนแต่ละแถบ (กว้าง:สูง) ≈ 3:4
  static const double aspectRatio = 3 / 4;

  static const double maxBannerHeight = 280;
  static const double viewportFraction = 1;
  static const double slideInset = 12;
  static const double slideRadius = 10;
  static const double columnGap = 8;
  static const double sectionTopPad = 8;
  static const double sectionBottomPad = 8;
  static const double dotsGap = 0;
  static const double secondaryAspectRatio = 2;

  @override
  State<HomePromoCarousel> createState() => _HomePromoCarouselState();
}

class _CarouselScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class _HomePromoCarouselState extends State<HomePromoCarousel> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _open(BuildContext context, HomePromoItem promo, bool en) {
    HomePromoDetailSheet.show(context, promo: promo, isEnglish: en);
  }

  /// ซ้าย = รูปสไลด์ / ขวา = รายการวิดีโอสั้น (มี videoUrl หรือใบสุดท้าย)
  ({List<HomePromoItem> slides, HomePromoItem video}) _split(
    List<HomePromoItem> promos,
  ) {
    HomePromoItem? video;
    for (final p in promos) {
      if (p.hasVideo) {
        video = p;
        break;
      }
    }
    video ??= promos.length > 1 ? promos.last : promos.first;
    final slides = promos.where((p) => p.id != video!.id).toList();
    if (slides.isEmpty) {
      return (slides: [video], video: video);
    }
    return (slides: slides, video: video);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.localeController,
        HomePromoService.instance,
      ]),
      builder: (context, _) {
        final promos = HomePromoService.instance.items;
        if (promos.isEmpty) return const SizedBox.shrink();
        final en = widget.localeController.isEnglish;
        final parts = _split(promos);

        return FbFeedCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              HomePromoCarousel.slideInset,
              HomePromoCarousel.sectionTopPad,
              HomePromoCarousel.slideInset,
              HomePromoCarousel.sectionBottomPad,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gap = HomePromoCarousel.columnGap;
                final colW = (constraints.maxWidth - gap) / 2;
                final h = (colW / HomePromoCarousel.aspectRatio)
                    .clamp(0.0, HomePromoCarousel.maxBannerHeight)
                    .toDouble();

                return SizedBox(
                  height: h,
                  width: constraints.maxWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: colW,
                        child: _ImageSliderPane(
                          promos: parts.slides,
                          pageController: _page,
                          index: _index,
                          onPageChanged: (i) => setState(() => _index = i),
                          onTap: (p) => _open(context, p, en),
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: colW,
                        child: _ShortVideoPane(
                          promo: parts.video,
                          isEnglish: en,
                          onTap: () => _open(context, parts.video, en),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ImageSliderPane extends StatelessWidget {
  const _ImageSliderPane({
    required this.promos,
    required this.pageController,
    required this.index,
    required this.onPageChanged,
    required this.onTap,
  });

  final List<HomePromoItem> promos;
  final PageController pageController;
  final int index;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<HomePromoItem> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(HomePromoCarousel.slideRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ScrollConfiguration(
            behavior: _CarouselScrollBehavior(),
            child: PageView.builder(
              controller: pageController,
              itemCount: promos.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, i) {
                final promo = promos[i];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(promo),
                    child: HomePromoImage(
                      promo: promo,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                );
              },
            ),
          ),
          if (promos.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < promos.length; i++)
                    AnimatedContainer(
                      duration: AppTheme.animFast,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == i
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
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

class _ShortVideoPane extends StatefulWidget {
  const _ShortVideoPane({
    required this.promo,
    required this.isEnglish,
    required this.onTap,
  });

  final HomePromoItem promo;
  final bool isEnglish;
  final VoidCallback onTap;

  @override
  State<_ShortVideoPane> createState() => _ShortVideoPaneState();
}

class _ShortVideoPaneState extends State<_ShortVideoPane> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant _ShortVideoPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.promo.videoUrl != widget.promo.videoUrl) {
      _disposeVideo();
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final url = widget.promo.videoUrl;
    if (url == null || url.isEmpty) return;
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = c;
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (!mounted) return;
      setState(() {
        _ready = true;
        _failed = false;
      });
    } catch (_) {
      _disposeVideo();
      if (mounted) {
        setState(() {
          _ready = false;
          _failed = true;
        });
      }
    }
  }

  void _disposeVideo() {
    _controller?.dispose();
    _controller = null;
    _ready = false;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  String get _viewLabel {
    // ตัวเลขชม. จำลองให้อ่านง่ายแบบตัวอย่าง
    final n = widget.promo.id.hashCode.abs() % 900 + 100;
    final k = (n / 10).toStringAsFixed(1);
    return '${k}k';
  }

  @override
  Widget build(BuildContext context) {
    final promo = widget.promo;
    final en = widget.isEnglish;
    final s = AppStrings.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(HomePromoCarousel.slideRadius),
      child: Material(
        color: Colors.black,
        child: InkWell(
          onTap: widget.onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_ready && _controller != null)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                HomePromoImage(
                  promo: promo,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              // มุมบนซ้าย: เล่น + จำนวนชม.
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _ready ? Icons.play_arrow_rounded : Icons.videocam_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _viewLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // การ์ดสินค้าด้านล่าง
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: HomePromoImage(
                            promo: promo,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              promo.title(en),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF222222),
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              promo.subtitle(en),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: LivingBkkBrand.brandRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (promo.badge(en) != null)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: LivingBkkBrand.brandRed,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            promo.badge(en)!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_failed)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Tooltip(
                    message: s.isEnglish ? 'Poster mode' : 'โหมดโปสเตอร์',
                    child: Icon(
                      Icons.image_outlined,
                      size: 14,
                      color: Colors.white.withOpacity(0.7),
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
