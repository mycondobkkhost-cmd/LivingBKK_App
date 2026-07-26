import '../models/chat_message.dart';
import '../l10n/app_strings.dart';

typedef ListingMapCoords = ({double? lat, double? lng});

const _locationKeys = [
  'โลเคชั่น',
  'location',
  'แผนที่',
  'แมพ',
  'map',
  'google map',
  'ใกล้ bts',
  'ใกล้ mrt',
  'ทำเล',
  'เดินทาง',
  'รถไฟฟ้า',
  'กี่เมตร',
  'ห่าง bts',
  'ห่าง mrt',
  'ขอพิกัด',
  'พิกัด',
  'ใกล้สถานี',
];

bool isLocationQuestion(String text) {
  final q = text.toLowerCase();
  return _locationKeys.any(q.contains);
}

const _internetKeys = [
  'อินเทอร์เน็ต',
  'เน็ต',
  'wifi',
  'wi-fi',
  'internet',
  'ติดเน็ต',
  'ติดตั้งเน็ต',
];

bool isInternetQuestion(String text) {
  final q = text.toLowerCase();
  return _internetKeys.any(q.contains);
}

const internetFaqBurst = [
  'ตามรายละเอียดค่าเช่าจะไม่ได้รวมอินเทอร์เน็ตค่ะ ทางเรามีบริการช่างอินเทอร์เน็ตให้นะคะ ทั้งสองค่าย',
  'ลูกค้าแค่ทำการเลือกแพ็กเกจ ไม่ต้องลำบากติดต่อพนักงานเองเลยค่ะ',
];

String? googleMapsUrlForCoords(double? lat, double? lng) {
  if (lat == null || lng == null) return null;
  return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
}

List<String> locationReplyTexts(ListingMapCoords? listing) {
  if (listing?.lat == null || listing?.lng == null) {
    return const [
      'แผนที่ที่แสดงจะบอกโซนโดยประมาณค่ะ หากต้องการทราบระยะทางจาก BTS/MRT แจ้งได้เลยนะคะ',
    ];
  }
  return const [
    'แอดมินส่งโลเคชั่นโครงการให้ทางนี้นะคะ ลูกค้าสามารถคลิกเพื่อตรวจสอบพิกัดได้เลยค่ะ',
  ];
}

List<ChatMessageLink> locationReplyLinks(ListingMapCoords? listing, AppStrings copy) {
  final url = listing == null
      ? null
      : googleMapsUrlForCoords(listing.lat, listing.lng);
  if (url == null) return const [];
  return [
    ChatMessageLink.viewingLocation(
      label: copy.chatLinkViewingLocation,
      mapsUrl: url,
    ),
  ];
}
