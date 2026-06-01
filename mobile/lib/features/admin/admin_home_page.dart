import 'package:flutter/material.dart';

import '../../services/admin_repository.dart';
import '../../theme/app_theme.dart';
import 'admin_create_demand_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> with SingleTickerProviderStateMixin {
  final _admin = AdminRepository();
  late final TabController _tabs;
  bool _allowed = false;
  bool _loading = true;
  List<Map<String, dynamic>> _offers = [];
  List<Map<String, dynamic>> _leads = [];
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final ok = await _admin.isAdmin();
    if (!ok) {
      setState(() {
        _allowed = false;
        _loading = false;
      });
      return;
    }
    await _refresh();
    setState(() {
      _allowed = true;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    final offers = await _admin.allDemandOffers();
    final leads = await _admin.recentLeads();
    final stats = await _admin.leadStats();
    setState(() {
      _offers = offers;
      _leads = leads;
      _stats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_allowed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'ต้องมี role = admin ใน Supabase profiles\n(ตั้งใน Table Editor หรือ SQL)',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('LivingBKK Admin'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'ข้อเสนอ'),
            Tab(text: 'Leads'),
            Tab(text: 'สร้างบอร์ด'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _offersTab(),
          _leadsTab(),
          AdminCreateDemandPage(onCreated: _refresh),
        ],
      ),
    );
  }

  Widget _offersTab() {
    if (_offers.isEmpty) {
      return const Center(child: Text('ยังไม่มีข้อเสนอ'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _offers.length,
      itemBuilder: (context, i) {
        final o = _offers[i];
        final post = o['demand_posts'] as Map<String, dynamic>?;
        return Card(
          child: ExpansionTile(
            title: Text(post?['title']?.toString() ?? 'Demand'),
            subtitle: Text(
              '${o['offerer_capacity']} · ${o['status']} · verify: ${o['capacity_verified']}',
            ),
            children: [
              if (o['external_url'] != null)
                ListTile(
                  title: const Text('ลิงก์'),
                  subtitle: Text(o['external_url'].toString()),
                ),
              if (o['description'] != null)
                ListTile(
                  title: const Text('รายละเอียด'),
                  subtitle: Text(o['description'].toString()),
                ),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      await _admin.verifyOfferCapacity(o['id'] as String, approved: true);
                      _refresh();
                    },
                    child: const Text('ยืนยันสิทธิ์'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _admin.verifyOfferCapacity(o['id'] as String, approved: false);
                      _refresh();
                    },
                    child: const Text('ปฏิเสธ', style: TextStyle(color: AppTheme.error)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _leadsTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (_stats != null)
          Card(
            child: ListTile(
              title: const Text('สถิติวันล่าสุด (สำหรับ Make.com)'),
              subtitle: Text(
                'Leads: ${_stats!['lead_count']} · รับแล้ว: ${_stats!['accepted_count']}',
              ),
            ),
          ),
        ..._leads.map(
          (l) => Card(
            child: ListTile(
              title: Text(l['listing_code']?.toString() ?? '—'),
              subtitle: Text('${l['seeker_nickname']} · ${l['status']}'),
            ),
          ),
        ),
      ],
    );
  }
}
