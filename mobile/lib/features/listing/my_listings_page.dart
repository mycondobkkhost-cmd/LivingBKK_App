import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/listing_owner_repository.dart';
import '../../theme/app_theme.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  final _repo = ListingOwnerRepository();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await _repo.myListings();
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _bump(String id) async {
    await _repo.bumpListing(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ยืนยันว่างแล้ว — ดันประกาศ (Bump)')),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประกาศของฉัน'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const Center(child: Text('ยังไม่มีประกาศ'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _rows.length,
                  itemBuilder: (context, i) {
                    final r = _rows[i];
                    final status = r['status']?.toString() ?? '';
                    return Card(
                      child: ListTile(
                        title: Text(r['title']?.toString() ?? ''),
                        subtitle: Text(
                          '${r['listing_code']} · $status · ฿${r['price_net']}',
                        ),
                        trailing: status == 'published'
                            ? TextButton(
                                onPressed: () => _bump(r['id'] as String),
                                child: const Text('ยืนยันว่าง'),
                              )
                            : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/listing/create'),
        icon: const Icon(Icons.add),
        label: const Text('ลงประกาศ'),
      ),
    );
  }
}
