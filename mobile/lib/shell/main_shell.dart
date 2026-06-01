import 'dart:async';

import 'package:flutter/material.dart';

import '../features/board/demand_board_page.dart';
import '../features/contact/contact_tab_page.dart';
import '../features/profile/profile_page.dart';
import '../features/search/map_home_page.dart';
import '../features/work/work_page.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';
import '../state/user_role_controller.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.roleController});

  final UserRoleController roleController;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _realtime = RealtimeService();
  StreamSubscription<String>? _notifSub;

  @override
  void initState() {
    super.initState();
    _setupRealtime();
    _syncRoleFromServer();
  }

  Future<void> _syncRoleFromServer() async {
    final role = await AuthService().fetchProfileRole();
    if (role != null && mounted) {
      widget.roleController.setRole(role);
    }
  }

  void _setupRealtime() {
    _realtime.subscribeToMyLeads();
    _notifSub = _realtime.messages.listen((msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
      );
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _realtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.roleController,
      builder: (context, _) {
        final isAgent = widget.roleController.isAgent;
        final pages = [
          MapHomePage(isAgent: isAgent),
          const DemandBoardPage(),
          WorkPage(isAgent: isAgent),
          const ContactTabPage(),
          ProfilePage(roleController: widget.roleController),
        ];

        return Scaffold(
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'ค้นหา',
              ),
              NavigationDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign),
                label: 'บอร์ด',
              ),
              NavigationDestination(
                icon: Icon(Icons.inbox_outlined),
                selectedIcon: Icon(Icons.inbox),
                label: 'งาน',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'ติดต่อ',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'ฉัน',
              ),
            ],
          ),
        );
      },
    );
  }
}
