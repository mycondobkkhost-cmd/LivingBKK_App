import 'package:flutter/material.dart';

import '../../utils/admin_desktop.dart';

/// Master-detail แบบเดียวกันทุกโมดูล ERP
/// - กว้าง: แสดง list + detail คู่กัน
/// - แคบ: แสดง detail แทน list เมื่อเลือกแล้ว
class AdminAdaptiveDetail extends StatelessWidget {
  const AdminAdaptiveDetail({
    super.key,
    required this.list,
    required this.detail,
    required this.showDetail,
    this.listWidth = 320,
    this.listFlex = 2,
    this.detailFlex = 3,
  });

  final Widget list;
  final Widget? detail;
  final bool showDetail;
  final double listWidth;
  final int listFlex;
  final int detailFlex;

  @override
  Widget build(BuildContext context) {
    final wide = useAdminSplitPane(context);
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: listWidth, child: list),
          const VerticalDivider(width: 1),
          Expanded(child: detail ?? const SizedBox.shrink()),
        ],
      );
    }
    if (showDetail && detail != null) {
      return detail!;
    }
    return list;
  }
}

/// แท็บย่อยภายในโมดูล (เช่น Calendar / List / Map)
class AdminSectionTabBar extends StatelessWidget {
  const AdminSectionTabBar({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        isScrollable: tabs.length > 3,
        tabAlignment: tabs.length > 3 ? TabAlignment.start : TabAlignment.fill,
        onTap: onChanged,
        tabs: [for (final t in tabs) Tab(text: t)],
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );
  }
}
