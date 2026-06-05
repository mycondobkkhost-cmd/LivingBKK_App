/// สเกลราคาในตัวกรอง — ช่วงที่ใช้บ่อยกินพื้นที่เลื่อนมากกว่าช่วงสูง
abstract final class PriceSliderScale {
  static const rentCap = 100000.0;
  static const saleCap = 300000000.0;
  static const saleCommonCap = 20000000.0; // 20 ล้าน — 80% ของแถบเลื่อน

  static const defaultRentMax = 50000.0;
  static const defaultSaleMax = saleCommonCap;

  /// เช่า: เลื่อนเชิงเส้น 0–100k
  static double rentPositionToBaht(double t) => t.clamp(0, 1) * rentCap;

  static double rentBahtToPosition(double baht) =>
      (baht / rentCap).clamp(0, 1);

  /// ซื้อ: 0–80% ของแถบ = 0–20M, 80–100% = 20M–300M
  static double salePositionToBaht(double t) {
    final p = t.clamp(0, 1);
    if (p <= 0.8) return (p / 0.8) * saleCommonCap;
    return saleCommonCap + ((p - 0.8) / 0.2) * (saleCap - saleCommonCap);
  }

  static double saleBahtToPosition(double baht) {
    final v = baht.clamp(0, saleCap);
    if (v <= saleCommonCap) return (v / saleCommonCap) * 0.8;
    return 0.8 + ((v - saleCommonCap) / (saleCap - saleCommonCap)) * 0.2;
  }

  static bool isAtCap(bool isSale, double baht) =>
      isSale ? baht >= saleCap - 1 : baht >= rentCap - 1;

  static String formatBaht(double v, {required bool isSale}) {
    if (isAtCap(isSale, v)) return 'ไม่จำกัด';
    if (v >= 1000000) {
      final m = v / 1000000;
      return m >= 10 ? '${m.toStringAsFixed(0)} ล้าน' : '${m.toStringAsFixed(1)} ล้าน';
    }
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)},000';
    return v.toInt().toString();
  }
}
