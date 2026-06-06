/// พิกัดสถานี BTS / MRT / ARL กทม.+ปริมณฑล — ใช้หาสถานีใกล้โครงการ
class TransitStationCoord {
  const TransitStationCoord({
    required this.system,
    required this.nameTh,
    required this.nameEn,
    required this.lat,
    required this.lng,
    this.geoZoneSlugs = const [],
  });

  final String system;
  final String nameTh;
  final String nameEn;
  final double lat;
  final double lng;
  final List<String> geoZoneSlugs;

  String get labelTh => '$system $nameTh';
  String get labelEn => '$system $nameEn';
}

abstract final class BangkokTransitStationCoords {
  static const all = <TransitStationCoord>[
    // BTS สุขุมวิต
    TransitStationCoord(system: 'BTS', nameTh: 'หมอชิต', nameEn: 'Mo Chit', lat: 13.8027, lng: 100.5540, geoZoneSlugs: ['ari']),
    TransitStationCoord(system: 'BTS', nameTh: 'อารีย์', nameEn: 'Ari', lat: 13.7797, lng: 100.5448, geoZoneSlugs: ['ari']),
    TransitStationCoord(system: 'BTS', nameTh: 'สนามเป้า', nameEn: 'Sanam Pao', lat: 13.7728, lng: 100.5448),
    TransitStationCoord(system: 'BTS', nameTh: 'อนุสาวรีย์ชัยฯ', nameEn: 'Victory Monument', lat: 13.7651, lng: 100.5370),
    TransitStationCoord(system: 'BTS', nameTh: 'พญาไท', nameEn: 'Phaya Thai', lat: 13.7569, lng: 100.5347),
    TransitStationCoord(system: 'BTS', nameTh: 'ราชเทวี', nameEn: 'Ratchathewi', lat: 13.7519, lng: 100.5316),
    TransitStationCoord(system: 'BTS', nameTh: 'สยาม', nameEn: 'Siam', lat: 13.7456, lng: 100.5341, geoZoneSlugs: ['asok']),
    TransitStationCoord(system: 'BTS', nameTh: 'ชิดลม', nameEn: 'Chit Lom', lat: 13.7445, lng: 100.5430),
    TransitStationCoord(system: 'BTS', nameTh: 'เพลินจิต', nameEn: 'Phloen Chit', lat: 13.7431, lng: 100.5488),
    TransitStationCoord(system: 'BTS', nameTh: 'นานา', nameEn: 'Nana', lat: 13.7405, lng: 100.5553, geoZoneSlugs: ['asok', 'sukhumvit']),
    TransitStationCoord(system: 'BTS', nameTh: 'อโศก', nameEn: 'Asok', lat: 13.7373, lng: 100.5606, geoZoneSlugs: ['asok', 'sukhumvit']),
    TransitStationCoord(system: 'BTS', nameTh: 'พร้อมพงษ์', nameEn: 'Phrom Phong', lat: 13.7305, lng: 100.5693, geoZoneSlugs: ['sukhumvit']),
    TransitStationCoord(system: 'BTS', nameTh: 'ทองหล่อ', nameEn: 'Thong Lo', lat: 13.7242, lng: 100.5784, geoZoneSlugs: ['thonglor']),
    TransitStationCoord(system: 'BTS', nameTh: 'เอกมัย', nameEn: 'Ekkamai', lat: 13.7195, lng: 100.5851, geoZoneSlugs: ['thonglor']),
    TransitStationCoord(system: 'BTS', nameTh: 'อ่อนนุช', nameEn: 'On Nut', lat: 13.7056, lng: 100.6011),
    TransitStationCoord(system: 'BTS', nameTh: 'บางจาก', nameEn: 'Bang Chak', lat: 13.6967, lng: 100.6055),
    TransitStationCoord(system: 'BTS', nameTh: 'แบริ่ง', nameEn: 'Bearing', lat: 13.6687, lng: 100.6018, geoZoneSlugs: ['bangna']),
    TransitStationCoord(system: 'BTS', nameTh: 'สำโรง', nameEn: 'Samrong', lat: 13.6462, lng: 100.5956, geoZoneSlugs: ['bangna']),
    // BTS สีลม
    TransitStationCoord(system: 'BTS', nameTh: 'สนามกีฬาแห่งชาติ', nameEn: 'National Stadium', lat: 13.7468, lng: 100.5292),
    TransitStationCoord(system: 'BTS', nameTh: 'ราชดำริ', nameEn: 'Ratchadamri', lat: 13.7396, lng: 100.5345),
    TransitStationCoord(system: 'BTS', nameTh: 'ศาลาแดง', nameEn: 'Sala Daeng', lat: 13.7284, lng: 100.5342, geoZoneSlugs: ['silom']),
    TransitStationCoord(system: 'BTS', nameTh: 'ช่องนนทรี', nameEn: 'Chong Nonsi', lat: 13.7236, lng: 100.5294, geoZoneSlugs: ['silom']),
    TransitStationCoord(system: 'BTS', nameTh: 'สุรศักดิ์', nameEn: 'Surasak', lat: 13.7199, lng: 100.5234, geoZoneSlugs: ['silom']),
    TransitStationCoord(system: 'BTS', nameTh: 'สะพานตากสิน', nameEn: 'Saphan Taksin', lat: 13.7188, lng: 100.5141),
    TransitStationCoord(system: 'BTS', nameTh: 'กรุงธนบุรี', nameEn: 'Krung Thon Buri', lat: 13.7210, lng: 100.5057),
    TransitStationCoord(system: 'BTS', nameTh: 'วงเวียนใหญ่', nameEn: 'Wongwian Yai', lat: 13.7209, lng: 100.4953),
    // MRT สีน้ำเงิน
    TransitStationCoord(system: 'MRT', nameTh: 'สุขุมวิท', nameEn: 'Sukhumvit', lat: 13.7386, lng: 100.5613, geoZoneSlugs: ['asok', 'sukhumvit']),
    TransitStationCoord(system: 'MRT', nameTh: 'สีลม', nameEn: 'Silom', lat: 13.7297, lng: 100.5368, geoZoneSlugs: ['silom']),
    TransitStationCoord(system: 'MRT', nameTh: 'ลุมพินี', nameEn: 'Lumphini', lat: 13.7278, lng: 100.5458),
    TransitStationCoord(system: 'MRT', nameTh: 'คลองเตย', nameEn: 'Khlong Toei', lat: 13.7224, lng: 100.5539),
    TransitStationCoord(system: 'MRT', nameTh: 'ศูนย์สิริกิติ์', nameEn: 'Queen Sirikit', lat: 13.7220, lng: 100.5600),
    TransitStationCoord(system: 'MRT', nameTh: 'พระราม 9', nameEn: 'Phra Ram 9', lat: 13.7587, lng: 100.5650, geoZoneSlugs: ['rama-9']),
    TransitStationCoord(system: 'MRT', nameTh: 'ศูนย์วัฒนธรรม', nameEn: 'Thailand Cultural Centre', lat: 13.7655, lng: 100.5704),
    TransitStationCoord(system: 'MRT', nameTh: 'ห้วยขวาง', nameEn: 'Huai Khwang', lat: 13.7785, lng: 100.5736, geoZoneSlugs: ['huai-khwang']),
    TransitStationCoord(system: 'MRT', nameTh: 'สุทธิสาร', nameEn: 'Sutthisan', lat: 13.7895, lng: 100.5741),
    TransitStationCoord(system: 'MRT', nameTh: 'ลาดพร้าว', nameEn: 'Lat Phrao', lat: 13.8060, lng: 100.5734, geoZoneSlugs: ['ladprao']),
    TransitStationCoord(system: 'MRT', nameTh: 'พหลโยธิน', nameEn: 'Phahon Yothin', lat: 13.8140, lng: 100.5700),
    TransitStationCoord(system: 'MRT', nameTh: 'สวนจตุจักร', nameEn: 'Chatuchak Park', lat: 13.8029, lng: 100.5532),
    TransitStationCoord(system: 'MRT', nameTh: 'กำแพงเพชร', nameEn: 'Kamphaeng Phet', lat: 13.7982, lng: 100.5489),
    TransitStationCoord(system: 'MRT', nameTh: 'บางซื่อ', nameEn: 'Bang Sue', lat: 13.8038, lng: 100.5392),
    TransitStationCoord(system: 'MRT', nameTh: 'หัวลำโพง', nameEn: 'Hua Lamphong', lat: 13.7378, lng: 100.5174),
    // MRT สายอื่น
    TransitStationCoord(system: 'MRT', nameTh: 'เตาปูน', nameEn: 'Tao Poon', lat: 13.8061, lng: 100.5304),
    TransitStationCoord(system: 'MRT', nameTh: 'บางหว้า', nameEn: 'Bang Wa', lat: 13.7202, lng: 100.4572),
    // สายทอง / ARL
    TransitStationCoord(system: 'Gold', nameTh: 'กรุงธนบุรี', nameEn: 'Krung Thon Buri', lat: 13.7210, lng: 100.5057),
    TransitStationCoord(system: 'ARL', nameTh: 'มักกะสัน', nameEn: 'Makkasan', lat: 13.7510, lng: 100.5608, geoZoneSlugs: ['asok']),
    TransitStationCoord(system: 'ARL', nameTh: 'รามคำแหง', nameEn: 'Ramkhamhaeng', lat: 13.7488, lng: 100.5997),
  ];
}
