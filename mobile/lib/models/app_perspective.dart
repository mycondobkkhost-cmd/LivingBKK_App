/// มุมมองใช้งานบนหน้าหลัก — บัญชีเดียวสลับได้ (ไม่รวมแอดมินระบบ)
enum AppPerspective {
  customer,
  agent,
  owner,
}

extension AppPerspectiveLabels on AppPerspective {
  String get labelTh {
    switch (this) {
      case AppPerspective.customer:
        return 'กำลังหาซื้อ / หาเช่าอยู่ด้วยตัวเอง';
      case AppPerspective.agent:
        return 'นายหน้า กำลังหาทรัพย์ให้ลูกค้า';
      case AppPerspective.owner:
        return 'เจ้าของทรัพย์ · ลงประกาศ';
    }
  }

  String get labelEn {
    switch (this) {
      case AppPerspective.customer:
        return 'Looking to buy or rent';
      case AppPerspective.agent:
        return 'Broker seeking for clients';
      case AppPerspective.owner:
        return 'Owner · post listings';
    }
  }

  String get shortLabelTh {
    switch (this) {
      case AppPerspective.customer:
        return 'หาซื้อ / หาเช่าเอง';
      case AppPerspective.agent:
        return 'นายหน้า หาทรัพย์';
      case AppPerspective.owner:
        return 'เจ้าของทรัพย์';
    }
  }

  String get shortLabelEn {
    switch (this) {
      case AppPerspective.customer:
        return 'Rent / Buy';
      case AppPerspective.agent:
        return 'Broker';
      case AppPerspective.owner:
        return 'Owner';
    }
  }

  String label(bool isEnglish) => isEnglish ? labelEn : labelTh;

  String shortLabel(bool isEnglish) => isEnglish ? shortLabelEn : shortLabelTh;
}
