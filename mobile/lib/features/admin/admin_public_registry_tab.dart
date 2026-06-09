import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import 'admin_asset_registry_page.dart';

/// คลังทรัพย์ปฏิบัติการ — แอดมินทุกระดับ · ตารางเดียวกันแต่ไม่เห็นข้อมูลลับ
class AdminPublicRegistryTab extends StatelessWidget {
  const AdminPublicRegistryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminAssetRegistryPage(
      confidential: false,
      title: context.s.adminNavAssetRegistry,
    );
  }
}
