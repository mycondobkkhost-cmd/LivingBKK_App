import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import 'admin_asset_registry_page.dart';

/// คลังข้อมูลลับ — CEO / SUPER · ตาราง + รายละเอียดเต็ม
class AdminVaultTab extends StatelessWidget {
  const AdminVaultTab({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminAssetRegistryPage(
      confidential: true,
      showStorageInfo: true,
      showSync: true,
      title: context.s.adminNavVault,
    );
  }
}
