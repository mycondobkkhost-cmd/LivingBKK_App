import 'dart:async';

import 'package:flutter/material.dart';

import '../services/search_service.dart';
import '../theme/app_theme.dart';

class SmartSearchBar extends StatefulWidget {
  const SmartSearchBar({
    super.key,
    required this.onApplyFilters,
  });

  final void Function(Map<String, dynamic> filters) onApplyFilters;

  @override
  State<SmartSearchBar> createState() => _SmartSearchBarState();
}

class _SmartSearchBarState extends State<SmartSearchBar> {
  final _controller = TextEditingController();
  final _search = SearchService();
  Timer? _debounce;
  List<SearchPreviewItem> _preview = [];
  Map<String, dynamic> _filters = {};
  bool _showPreview = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _showPreview = false;
        _preview = [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final result = await _search.parseQuery(value);
      if (!mounted) return;
      setState(() {
        _preview = result.preview;
        _filters = result.filters;
        _showPreview = result.preview.isNotEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'คอนโดแนวสุขุมวิท เลี้ยงสัตว์ได้ งบไม่เกิน 15k',
            prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
          ),
        ),
        if (_showPreview)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ตัวกรองที่ตรวจจับได้',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ..._preview.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${p.label}: ${p.value}',
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        widget.onApplyFilters(_filters);
                        setState(() => _showPreview = false);
                      },
                      child: const Text('ใช้ตัวกรอง'),
                    ),
                    TextButton(
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _showPreview = false;
                          _preview = [];
                          _filters = {};
                        });
                      },
                      child: const Text('ล้าง'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
