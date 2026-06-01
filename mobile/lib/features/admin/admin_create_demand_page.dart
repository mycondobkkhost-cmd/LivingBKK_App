import 'package:flutter/material.dart';

import '../../services/admin_repository.dart';

class AdminCreateDemandPage extends StatefulWidget {
  const AdminCreateDemandPage({super.key, required this.onCreated});

  final VoidCallback onCreated;

  @override
  State<AdminCreateDemandPage> createState() => _AdminCreateDemandPageState();
}

class _AdminCreateDemandPageState extends State<AdminCreateDemandPage> {
  final _admin = AdminRepository();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _maxPrice = TextEditingController();
  final _minArea = TextEditingController();
  final _btsKm = TextEditingController(text: '1.5');
  String _type = 'rent';
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _maxPrice.dispose();
    _minArea.dispose();
    _btsKm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await _admin.createDemandPost(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        transactionType: _type,
        maxPriceNet: double.tryParse(_maxPrice.text),
        minAreaSqm: double.tryParse(_minArea.text),
        maxDistanceBtsKm: double.tryParse(_btsKm.text),
      );
      widget.onCreated();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สร้างประกาศบอร์ดแล้ว')),
      );
      _title.clear();
      _desc.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'บอร์ดประกาศจาก LivingBKK\n(ผู้ใช้จะไม่เห็นข้อเสนอของกัน)',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(controller: _title, decoration: const InputDecoration(labelText: 'หัวข้อ *')),
        TextField(
          controller: _desc,
          decoration: const InputDecoration(
            labelText: 'รายละเอียด',
            hintText: 'หาคอนโดย่านทองหล่อ BTS ≤1.5km ...',
          ),
          maxLines: 4,
        ),
        TextField(
          controller: _maxPrice,
          decoration: const InputDecoration(labelText: 'งบสูงสุด (บาท)'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _minArea,
          decoration: const InputDecoration(labelText: 'ตร.ม. ขั้นต่ำ'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _btsKm,
          decoration: const InputDecoration(labelText: 'ห่าง BTS (กม.)'),
          keyboardType: TextInputType.number,
        ),
        DropdownButtonFormField<String>(
          value: _type,
          items: const [
            DropdownMenuItem(value: 'rent', child: Text('เช่า')),
            DropdownMenuItem(value: 'sale', child: Text('ขาย')),
          ],
          onChanged: (v) => setState(() => _type = v!),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('เผยแพร่บอร์ด'),
        ),
      ],
    );
  }
}
