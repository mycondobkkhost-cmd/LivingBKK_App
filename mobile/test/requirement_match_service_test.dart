import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/models/customer_requirement.dart';
import 'package:livingbkk/models/listing_public.dart';
import 'package:livingbkk/services/requirement_match_service.dart';

ListingPublic _listing({
  required String id,
  required String listingType,
  double priceNet = 20000,
  double? priceSaleNet,
  String propertyType = 'condo',
}) {
  return ListingPublic(
    id: id,
    listingCode: 'X-$id',
    listingType: listingType,
    title: 'Unit $id',
    priceNet: priceNet,
    priceSaleNet: priceSaleNet,
    propertyType: propertyType,
    district: 'วัฒนา',
    projectName: 'Life Asoke',
  );
}

CustomerRequirement _req({
  required String transactionType,
  double? maxPriceNet,
}) {
  return CustomerRequirement(
    id: 'req-$transactionType',
    transactionType: transactionType,
    propertyType: 'condo',
    zone: '',
    maxPriceNet: maxPriceNet,
  );
}

void main() {
  final svc = RequirementMatchService.instance;

  test('ความต้องการเช่าจับคู่ประกาศเช่า+ขายด้วยราคาเช่า', () {
    final dual = _listing(
      id: 'dual',
      listingType: 'rent_and_sale',
      priceNet: 18000,
      priceSaleNet: 5_500_000,
    );
    final hits = svc.match(
      req: _req(transactionType: 'rent', maxPriceNet: 25000),
      pool: [dual],
    );
    expect(hits.map((e) => e.id), ['dual']);
  });

  test('ความต้องการซื้อจับคู่ประกาศเช่า+ขายด้วยราคาขาย ไม่ใช่ราคาเช่า', () {
    final dual = _listing(
      id: 'dual',
      listingType: 'rent_and_sale',
      priceNet: 18000,
      priceSaleNet: 5_500_000,
    );
    final inBudget = svc.match(
      req: _req(transactionType: 'sale', maxPriceNet: 6_000_000),
      pool: [dual],
    );
    expect(inBudget.map((e) => e.id), ['dual']);

    // ถ้าเอา price_net (ค่าเช่า 18k) ไปเทียบงบซื้อ ทั้งสองงบจะได้คะแนนราคาเท่ากัน
    final high = svc.scoreFor(
      _req(transactionType: 'sale', maxPriceNet: 6_000_000),
      dual,
    );
    final low = svc.scoreFor(
      _req(transactionType: 'sale', maxPriceNet: 3_000_000),
      dual,
    );
    expect(high, greaterThan(low));
  });

  test('ความต้องการซื้อจับคู่ประกาศขายฝาก', () {
    final installment = _listing(
      id: 'inst',
      listingType: 'sale_installment',
      priceNet: 4_200_000,
    );
    final hits = svc.match(
      req: _req(transactionType: 'sale', maxPriceNet: 5_000_000),
      pool: [installment],
    );
    expect(hits.map((e) => e.id), ['inst']);
  });

  test('ความต้องการเช่าไม่จับคู่ประกาศขายอย่างเดียว', () {
    final sale = _listing(
      id: 'sale',
      listingType: 'sale',
      priceNet: 4_000_000,
    );
    final hits = svc.match(
      req: _req(transactionType: 'rent', maxPriceNet: 25000),
      pool: [sale],
    );
    expect(hits, isEmpty);
  });
}
