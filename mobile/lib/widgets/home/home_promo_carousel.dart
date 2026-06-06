import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../config/home_promo_config.dart';
import '../../services/home_promo_service.dart';
import '../../state/locale_controller.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/li_layout.dart';
import 'home_promo_detail_sheet.dart';
import 'home_promo_image.dart';

/// แบนเนอร์โฆษณา ultra-wide (21:9) — สูงไม่เกิน ~124px
class HomePromoCarousel extends StatefulWidget {
  const HomePromoCarousel({
    super.key,
    required this.localeController,
  });

  final LocaleController localeController;

  static const double maxBannerHeight = 124;
  static const double aspectRatio = 21 / 9;
  /// การ์ดชิดซ้าย + โผล่การ์ดถัดไป
  static const double viewportFraction = 0.92;
  /// ระยะขอบซ้ายจอ → การ์ดแรก (= ช่องว่างระหว่างการ์ด)
  static const double slideInset = LiLayout.pagePadding;
  static const double slideRadius = 18;
  /// ห่างช่องค้นหา → แบนเนอร์
  static const double sectionTopPad = 6;
  /// แบนเนอร์ → จุด carousel
  static const double dotsGap = 6;
  /// จุด carousel → ปุ่มลงประกาศ
  static const double sectionBottomPad = 4;

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
  final _page = PageController(
    viewportFraction: HomePromoCarousel.viewportFraction,
  );
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
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
        return LayoutBuilder(
          builder: (context, constraints) {
            final slideWidth =
                constraints.maxWidth * HomePromoCarousel.viewportFraction;
            final naturalH = slideWidth / HomePromoCarousel.aspectRatio;
            final bannerHeight = naturalH.clamp(0.0, HomePromoCarousel.maxBannerHeight);
            // viewportFraction < 1 centers pages by default — shift left to align first card.
            final gutter = constraints.maxWidth *
                (1 - HomePromoCarousel.viewportFraction) /
                2;

            return Column(
              children: [
                const SizedBox(height: HomePromoCarousel.sectionTopPad),
                SizedBox(
                  height: bannerHeight,
                  child: Transform.translate(
                    offset: Offset(-gutter, 0),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: ScrollConfiguration(
                        behavior: _CarouselScrollBehavior(),
                        child: PageView.builder(
                          controller: _page,
                          clipBehavior: Clip.none,
                          physics: const PageScrollPhysics(),
                          itemCount: promos.length,
                          onPageChanged: (i) => setState(() => _index = i),
                          itemBuilder: (context, i) {
                            final promo = promos[i];
                            const inset = HomePromoCarousel.slideInset;
                            final half = inset / 2;
                            return Padding(
                              padding: EdgeInsets.only(
                                left: i == 0 ? inset : half,
                                right: half,
                              ),
                              child: _PromoSlide(
                                promo: promo,
                                onTap: () => HomePromoDetailSheet.show(
                                  context,
                                  promo: promo,
                                  isEnglish: en,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: HomePromoCarousel.dotsGap),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < promos.length; i++)
                      AnimatedContainer(
                        duration: AppTheme.animFast,
                        margin: const EdgeInsets.symmetric(horizontal: 3.5),
                        width: _index == i ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _index == i
                              ? context.palette.primary
                              : context.palette.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: HomePromoCarousel.sectionBottomPad),
              ],
            );
          },
        );
      },
    );
  }
}

class _PromoSlide extends StatelessWidget {
  const _PromoSlide({
    required this.promo,
    required this.onTap,
  });

  final HomePromoItem promo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(HomePromoCarousel.slideRadius),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(HomePromoCarousel.slideRadius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: p.cardShadow.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: HomePromoImage(
              promo: promo,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}
