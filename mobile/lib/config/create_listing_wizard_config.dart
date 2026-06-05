/// ขั้นตอนฟอร์ม「สร้างประกาศ」— ปรับลำดับ/จำนวนขั้นที่นี่
abstract final class CreateListingWizardConfig {
  static const stepCount = 5;

  static const stepTitlesTh = [
    'ผู้ประกาศและประเภท',
    'ทำเลและโครงการ',
    'หัวข้อและรายละเอียด',
    'รูปและลิงก์',
    'ราคาและส่งตรวจ',
  ];

  static const stepTitlesEn = [
    'Poster & type',
    'Location & project',
    'Title & details',
    'Photos & links',
    'Price & submit',
  ];

  static String stepTitle(int index, bool isEnglish) {
    final titles = isEnglish ? stepTitlesEn : stepTitlesTh;
    return titles[index.clamp(0, titles.length - 1)];
  }
}
