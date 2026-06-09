import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/living_bkk_brand.dart';

/// ปุ่มลอยส้ม「ลงประกาศหาทรัพย์」— ตัวหนังสือเข้มค้าง 1.5 วิ แล้วจาง→เข้มใน 1 วิ วนซ้ำ
class DemandCreatePostCta extends StatefulWidget {
  const DemandCreatePostCta({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<DemandCreatePostCta> createState() => _DemandCreatePostCtaState();
}

class _DemandCreatePostCtaState extends State<DemandCreatePostCta>
    with SingleTickerProviderStateMixin {
  static const double _height = 44;
  static const Duration _hold = Duration(milliseconds: 1500);
  static const Duration _cycle = Duration(milliseconds: 2500); // hold 1.5s + fade 1s

  static const double _fadeMinOpacity = 0.38;

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: _cycle)..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  double _labelOpacity(double t) {
    final holdEnd = _hold.inMilliseconds / _cycle.inMilliseconds;
    if (t < holdEnd) return 1.0;
    final fadeT = (t - holdEnd) / (1 - holdEnd);
    return _fadeMinOpacity + fadeT * (1 - _fadeMinOpacity);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final label = s.postDemandWantedButton;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        elevation: 6,
        shadowColor: LivingBkkBrand.piterOrange.withOpacity(0.45),
        color: LivingBkkBrand.piterOrange,
        borderRadius: BorderRadius.circular(_height / 2),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(_height / 2),
          child: Ink(
            height: _height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_height / 2),
              boxShadow: [
                BoxShadow(
                  color: LivingBkkBrand.piterOrange.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white,
                  size: 21,
                ),
                const SizedBox(width: 7),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _labelOpacity(_pulse.value),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                          letterSpacing: -0.2,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
