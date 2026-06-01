import 'package:flutter/material.dart';

import '../../config/env.dart';
import '../../services/co_agent_repository.dart';
import '../../services/work_repository.dart';
import '../../theme/app_theme.dart';

class WorkPage extends StatefulWidget {
  const WorkPage({super.key, this.isAgent = false});

  final bool isAgent;

  @override
  State<WorkPage> createState() => _WorkPageState();
}

class _WorkPageState extends State<WorkPage> {
  final _work = WorkRepository();
  final _coAgent = CoAgentRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _myLeads = [];
  List<Map<String, dynamic>> _inbox = [];
  List<Map<String, dynamic>> _offers = [];
  List<Map<String, dynamic>> _coAgentReqs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final leads = await _work.mySubmittedLeads();
      final inbox = widget.isAgent ? await _work.inboxLeads() : <Map<String, dynamic>>[];
      final offers = await _work.myDemandOffers();
      final coReqs = widget.isAgent ? await _coAgent.myRequests() : <Map<String, dynamic>>[];
      setState(() {
        _myLeads = leads;
        _inbox = inbox;
        _offers = offers;
        _coAgentReqs = coReqs;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('งานของฉัน'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!Env.isConfigured)
                    const Card(
                      child: ListTile(
                        title: Text('โหมด Demo'),
                        subtitle: Text('ล็อกอิน + ตั้งค่า Supabase เพื่อเห็นรายการจริง'),
                      ),
                    ),
                  _sectionTitle('คำขอที่ส่ง (Lead)'),
                  if (_myLeads.isEmpty)
                    _empty('ยังไม่มีคำขอที่ส่ง')
                  else
                    ..._myLeads.map(_leadTile),
                  if (widget.isAgent) ...[
                    const SizedBox(height: 16),
                    _sectionTitle('กล่อง Lead (มอบหมาย)'),
                    if (_inbox.isEmpty)
                      _empty('ยังไม่มี Lead มอบหมาย')
                    else
                      ..._inbox.map(_inboxTile),
                    const SizedBox(height: 16),
                    _sectionTitle('คำขอ Co-Agent'),
                    if (_coAgentReqs.isEmpty)
                      _empty('ยังไม่มีคำขอโคเอเจ้นท์')
                    else
                      ..._coAgentReqs.map(_coAgentTile),
                  ],
                  const SizedBox(height: 16),
                  _sectionTitle('ข้อเสนอบอร์ด'),
                  if (_offers.isEmpty)
                    _empty('ยังไม่มีข้อเสนอบนบอร์ด')
                  else
                    ..._offers.map(_offerTile),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );

  Widget _empty(String msg) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(msg, style: const TextStyle(color: AppTheme.textSecondary)),
      );

  Widget _leadTile(Map<String, dynamic> row) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.mail_outline, color: AppTheme.primary),
        title: Text(row['listing_code']?.toString() ?? '—'),
        subtitle: Text('สถานะ: ${row['status']}'),
      ),
    );
  }

  Widget _inboxTile(Map<String, dynamic> row) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person_search, color: AppTheme.primary),
        title: Text(row['seeker_nickname']?.toString() ?? 'ลูกค้า'),
        subtitle: Text(
          '${row['listing_code']} · ${row['seeker_phone_censored'] ?? 'เบอร์ปิด'}',
        ),
      ),
    );
  }

  Widget _coAgentTile(Map<String, dynamic> row) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.handshake_outlined, color: AppTheme.primary),
        title: Text('Listing ${row['listing_id']?.toString().substring(0, 8) ?? ''}…'),
        subtitle: Text('สถานะ: ${row['status']}'),
      ),
    );
  }

  Widget _offerTile(Map<String, dynamic> row) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description_outlined, color: AppTheme.primary),
        title: Text('${row['offerer_capacity']}'),
        subtitle: Text('สถานะ: ${row['status']}'),
      ),
    );
  }
}
