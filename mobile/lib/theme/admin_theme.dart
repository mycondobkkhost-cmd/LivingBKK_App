import 'package:flutter/material.dart';

import 'living_bkk_brand.dart';

/// สีและสไตล์หลังบ้าน — โทนสว่าง อ่านง่าย ไม่กลืน
abstract final class AdminTheme {
  static const Color bg = LivingBkkBrand.offWhite;
  static const Color surface = LivingBkkBrand.surfaceWhite;
  static const Color surfaceMuted = Color(0xFFF3F4F6);
  static const Color text = LivingBkkBrand.navy;
  static const Color textMuted = Color(0xFF4B5563);
  static const Color textFaint = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderStrong = Color(0xFFD1D5DB);

  static TextStyle get title => const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: text,
        height: 1.25,
      );

  static TextStyle get section => const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: text,
      );

  static TextStyle get body => const TextStyle(
        fontSize: 14,
        color: text,
        height: 1.4,
      );

  static TextStyle get hint => const TextStyle(
        fontSize: 12,
        color: textMuted,
        height: 1.35,
      );

  static TextStyle get caption => const TextStyle(
        fontSize: 11,
        color: textFaint,
        height: 1.35,
      );

  static TextStyle get status => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: LivingBkkBrand.purplePrimary,
      );

  static BoxDecoration card({Color? color, bool alert = false}) => BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alert ? const Color(0xFFFECACA) : border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration infoBox() => BoxDecoration(
        color: surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderStrong),
      );

  static ThemeData shellTheme(ThemeData base) => base.copyWith(
        scaffoldBackgroundColor: bg,
        appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: surface,
          foregroundColor: text,
          surfaceTintColor: Colors.transparent,
        ),
        tabBarTheme: base.tabBarTheme.copyWith(
          labelColor: LivingBkkBrand.purplePrimary,
          unselectedLabelColor: textMuted,
          indicatorColor: LivingBkkBrand.purplePrimary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          labelPadding: const EdgeInsets.symmetric(horizontal: 10),
          tabAlignment: TabAlignment.start,
        ),
        cardTheme: base.cardTheme.copyWith(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: border),
          ),
        ),
        dividerTheme: const DividerThemeData(color: border, thickness: 1),
      );
}

/// ข้อความรอง / คำอธิบายสั้น
class AdminHint extends StatelessWidget {
  const AdminHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: AdminTheme.hint);
}

/// กล่องแจ้งสถานะ (ไม่ใช้พื้นม่วงกลืนข้อความ)
class AdminNote extends StatelessWidget {
  const AdminNote(this.text, {super.key, this.icon = Icons.info_outline});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AdminTheme.infoBox(),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AdminTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AdminTheme.hint)),
        ],
      ),
    );
  }
}
