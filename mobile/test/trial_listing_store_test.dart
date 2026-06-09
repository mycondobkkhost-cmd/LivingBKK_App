import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/models/listing_create_rules.dart';
import 'package:livingbkk/models/listing_pet_policy.dart';
import 'package:livingbkk/models/offer_commission_scheme.dart';
import 'package:livingbkk/services/listing_create_repository.dart';
import 'package:livingbkk/services/trial_listing_store.dart';

ListingCreateInput _sampleInput({String title = 'ทดสอบออฟไลน์'}) {
  return ListingCreateInput(
    title: title,
    listingType: 'rent',
    propertyType: 'house',
    priceNet: 25000,
    district: 'บางนา',
    posterRole: ListingPosterRole.owner,
    contactName: 'เจ้าของทดสอบ',
    contactPhone: '0812345678',
    description: 'รายละเอียดทดสอบ',
    promoPriceNet: 22000,
    petPolicy: const ListingPetPolicyInput(
      allowed: true,
      dogsAllowed: true,
    ),
    commissionScheme: OfferCommissionScheme.ownerRent1MoPer1Yr,
  );
}

void main() {
  setUp(() => TrialListingStore.instance.reset());

  test('seed มี pending, published และ draft', () {
    final mine = TrialListingStore.instance.myListings();
    expect(mine.any((r) => r['status'] == 'pending_review'), isTrue);
    expect(mine.any((r) => r['status'] == 'published'), isTrue);
    expect(mine.any((r) => r['status'] == 'draft'), isTrue);

    final pending = TrialListingStore.instance.pendingReview();
    expect(pending, isNotEmpty);
    expect(pending.first['id'], 'trial-listing-pending');
  });

  test('ลงประกาศ → ส่งตรวจ → อนุมัติ → published', () {
    final id = TrialListingStore.instance.registerDraft(_sampleInput());
    expect(TrialListingStore.instance.submitForReview(id), isTrue);

    expect(
      TrialListingStore.instance.pendingReview().any((r) => r['id'] == id),
      isTrue,
    );

    expect(TrialListingStore.instance.approveForPublish(id), isTrue);

    final row = TrialListingStore.instance
        .myListings()
        .firstWhere((r) => r['id'] == id);
    expect(row['status'], 'published');
    expect(row['owner_contact_phone'], '0812345678');
    expect(row['description_public']?.toString().contains('0812345678'), isNot(true));
    expect(row['published_at'], isNotNull);
    expect(row['last_bump_at'], isNotNull);

    expect(
      TrialListingStore.instance.pendingReview().any((r) => r['id'] == id),
      isFalse,
    );
  });

  test('ปฏิเสธส่งกลับเป็น draft', () {
    final id = TrialListingStore.instance.registerDraft(_sampleInput(title: 'รอปฏิเสธ'));
    TrialListingStore.instance.submitForReview(id);

    expect(TrialListingStore.instance.rejectToDraft(id), isTrue);

    final row = TrialListingStore.instance
        .myListings()
        .firstWhere((r) => r['id'] == id);
    expect(row['status'], 'draft');
  });

  test('bump ได้เฉพาะ published', () {
    final id = 'trial-listing-published';
    expect(TrialListingStore.instance.bump(id), isTrue);

    final draftId = 'trial-listing-installment';
    expect(TrialListingStore.instance.bump(draftId), isFalse);
  });

  test('id ไม่มีใน store → false', () {
    expect(TrialListingStore.instance.submitForReview('missing'), isFalse);
    expect(TrialListingStore.instance.approveForPublish('missing'), isFalse);
    expect(TrialListingStore.instance.rejectToDraft('missing'), isFalse);
  });
}
