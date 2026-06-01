import 'package:flutter/material.dart';

import '../../models/demand_post.dart';
import '../../services/demand_repository.dart';
import '../../theme/app_theme.dart';

class SubmitOfferPage extends StatefulWidget {
  const SubmitOfferPage({super.key, required this.post});

  final DemandPost post;

  @override
  State<SubmitOfferPage> createState() => _SubmitOfferPageState();
}

class _SubmitOfferPageState extends State<SubmitOfferPage> {
  final _repo = DemandRepository();
  String _capacity = 'owner_direct_100';
  bool _useLink = false;
  bool _submitting = false;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await _repo.submitOffer(
        demandPostId: widget.post.id,
        offererCapacity: _capacity,
        offerType: _useLink ? 'external_link' : 'in_app',
        title: _titleCtrl.text.isEmpty ? null : _titleCtrl.text,
        description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
        priceNet: double.tryParse(_priceCtrl.text),
        externalUrl: _useLink ? _urlCtrl.text : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งข้อเสนอแล้ว ทีม LivingBKK จะตรวจสอบ')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เสนอทรัพย์')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'คุณเสนอในฐานะ *',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _capacity,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(
                value: 'owner_direct_100',
                child: Text('เจ้าของทรัพย์ (Owner 100%)'),
              ),
              DropdownMenuItem(
                value: 'co_agent_50_50',
                child: Text('โคเอเจ้นท์ (แบ่ง 50/50)'),
              ),
              DropdownMenuItem(
                value: 'listing_agent',
                child: Text('เอเจ้นท์ฝั่งประกาศ (รอตรวจ)'),
              ),
            ],
            onChanged: (v) => setState(() => _capacity = v!),
          ),
          const SizedBox(height: 8),
          const Text(
            'ข้อมูลนี้ไม่แสดงต่อผู้ใช้รายอื่น',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('ลงในแอป')),
              ButtonSegment(value: true, label: Text('แปะลิงก์')),
            ],
            selected: {_useLink},
            onSelectionChanged: (v) => setState(() => _useLink = v.first),
          ),
          const SizedBox(height: 16),
          if (_useLink) ...[
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'ลิงก์ (Facebook, ฯลฯ) *',
                hintText: 'https://...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'หมายเหตุ'),
              maxLines: 3,
            ),
          ] else ...[
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'หัวข้อ')),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'รายละเอียด'),
              maxLines: 4,
            ),
            TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: 'ราคา Net (รวมคอมแล้ว)'),
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('ส่งข้อเสนอ'),
          ),
        ],
      ),
    );
  }
}
