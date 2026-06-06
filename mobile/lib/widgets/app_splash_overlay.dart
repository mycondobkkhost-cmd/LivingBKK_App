import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/living_bkk_brand.dart';
import 'proppiter_brand_hero.dart';

/// Splash โหลดแอป — ธีมเดียวกับ header หน้าแรก
class AppSplashOverlay extends StatefulWidget {
  const AppSplashOverlay({
    super.key,
    required this.child,
    this.minDuration = const Duration(milliseconds: 1800),
  });

  final Widget child;
  final Duration minDuration;

  @override
  State<AppSplashOverlay> createState() => _AppSplashOverlayState();
}

class _AppSplashOverlayState extends State<AppSplashOverlay>
    with SingleTickerProviderStateMixin {
  bool _visible = true;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.15, 1)),
    );
    _ctrl.forward();
    Future<void>.delayed(widget.minDuration, () {
      if (!mounted) return;
      setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_visible)
          AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 360),
            child: IgnorePointer(
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LivingBkkBrand.homeHeaderBlockGradient,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        top: -80,
                        right: -60,
                        child: _glowOrb(200, 0.22),
                      ),
                      Positioned(
                        bottom: -40,
                        left: -30,
                        child: _glowOrb(160, 0.14),
                      ),
                      Center(
                        child: AnimatedBuilder(
                          animation: _ctrl,
                          builder: (context, _) => Opacity(
                            opacity: _fade.value,
                            child: Transform.scale(
                              scale: _scale.value,
                              child: const ProppiterBrandHero(
                                size: ProppiterBrandHeroSize.splash,
                                centered: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 48,
                        child: AnimatedBuilder(
                          animation: _ctrl,
                          builder: (context, _) => Opacity(
                            opacity: _fade.value * 0.7,
                            child: const LinearProgressIndicator(
                              minHeight: 2,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _glowOrb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
