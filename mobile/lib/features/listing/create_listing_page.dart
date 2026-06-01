import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/listing_create_repository.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _createRepo = ListingCreateRepository();
  final _storage = StorageService();

  final _title = TextEditingController();
  final _district = TextEditingController();
  final _price = TextEditingController();
  final _area = TextEditingController();
  final _desc = TextEditingController();

  String _listingType = 'rent';
  String _propertyType = 'condo';
  String? _coAgentType;
  List<XFile> _images = [];
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _district.dispose();
    _price.dispose();
    _area.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _storage.pickImages();
    setState(() => _images = files);
  }

  Future<void> _submit({required bool publish}) async {
    if (_title.text.trim().isEmpty || _price.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรอกชื่อและราคา Net (รวมคอมแล้ว)')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final id = await _createRepo.createDraft(
        ListingCreateInput(
          title: _title.text.trim(),
          listingType: _listingType,
          propertyType: _propertyType,
          priceNet: double.parse(_price.text.replaceAll(',', '')),
          district: _district.text.trim().isEmpty ? 'กรุงเทพฯ' : _district.text.trim(),
          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          areaSqm: double.tryParse(_area.text),
          coAgentListingType: _coAgentType,
        ),
      );

      if (_images.isNotEmpty) {
        await _storage.uploadListingImages(listingId: id, files: _images);
      }

      if (publish) {
        await _createRepo.publish(id);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(publish ? 'เผยแพร่ประกาศแล้ว' : 'บันทึกแบบร่างแล้ว'),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลงประกาศทรัพย์')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'ราคา Net = ราคารวมค่าคอมมิชชันแล้ว (ผู้ชมเห็นเฉพาะราคานี้)',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'หัวข้อ *')),
          TextField(controller: _district, decoration: const InputDecoration(labelText: 'เขต/ย่าน')),
          TextField(
            controller: _price,
            decoration: const InputDecoration(labelText: 'ราคา Net *'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _area,
            decoration: const InputDecoration(labelText: 'ตร.ม.'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _desc,
            decoration: const InputDecoration(labelText: 'คำอธิบาย'),
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _listingType,
            decoration: const InputDecoration(labelText: 'ประเภท'),
            items: const [
              DropdownMenuItem(value: 'rent', child: Text('เช่า')),
              DropdownMenuItem(value: 'sale', child: Text('ขาย')),
            ],
            onChanged: (v) => setState(() => _listingType = v!),
          ),
          DropdownButtonFormField<String>(
            value: _coAgentType ?? '',
            decoration: const InputDecoration(labelText: 'Co-Agent (ถ้ามี)'),
            items: const [
              DropdownMenuItem(value: '', child: Text('—')),
              DropdownMenuItem(value: 'owner_direct', child: Text('Owner Direct')),
              DropdownMenuItem(value: 'co_agent_50_50', child: Text('Co-Agent 50/50')),
            ],
            onChanged: (v) => setState(() => _coAgentType = v == '' ? null : v),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text('เลือกรูป (${_images.length})'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : () => _submit(publish: true),
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('เผยแพร่'),
          ),
          TextButton(
            onPressed: _busy ? null : () => _submit(publish: false),
            child: const Text('บันทึกแบบร่าง'),
          ),
        ],
      ),
    );
  }
}
