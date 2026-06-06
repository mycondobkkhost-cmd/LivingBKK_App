import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_strings.dart';
import '../../models/platform_watermark_settings.dart';
import '../../services/admin_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../theme/brand_assets.dart';

/// แอดมิน — อัปโหลดรูปลายน้ำประกาศ
class AdminWatermarkTab extends StatefulWidget {
  const AdminWatermarkTab({super.key});

  @override
  State<AdminWatermarkTab> createState() => _AdminWatermarkTabState();
}

class _AdminWatermarkTabState extends State<AdminWatermarkTab> {
  final _admin = AdminRepository();
  final _picker = ImagePicker();

  bool _loading = true;
  bool _uploading = false;
  bool _saving = false;
  PlatformWatermarkSettings _settings = PlatformWatermarkSettings.defaults;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await _admin.fetchWatermarkSettings();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _loading = false;
    });
  }

  Future<void> _pickAndUpload() async {
    final files = await _picker.pickMultiImage(imageQuality: 92);
    if (files.isEmpty) return;
    setState(() => _uploading = true);
    try {
      final next = await _admin.uploadListingWatermark(files.first);
      if (!mounted) return;
      setState(() => _settings = next);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.adminWatermarkUploaded)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _saveTuning() async {
    setState(() => _saving = true);
    try {
      final next = await _admin.saveWatermarkSettings(_settings);
      if (!mounted) return;
      setState(() => _settings = next);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.adminWatermarkSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearCustom() async {
    final s = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.adminWatermarkClearTitle),
        content: Text(s.adminWatermarkClearBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.adminWatermarkClearConfirm)),
        ],
      ),
    );
    if (ok != true) return;
    await _admin.clearListingWatermark();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminWatermarkCleared)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final previewUrl = _settings.publicUrl;
    final fallbackAsset = BrandAssets.logoMark;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.adminWatermarkTitle, style: AdminTheme.title.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text(s.adminWatermarkHint, style: AdminTheme.hint),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.adminWatermarkPreview, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE8EAEF), Color(0xFFD8DCE5)],
                            ),
                          ),
                          child: const Icon(Icons.photo_outlined, size: 48, color: Color(0xFF9CA3AF)),
                        ),
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Opacity(
                            opacity: (_settings.opacity / 255).clamp(0.1, 1.0),
                            child: SizedBox(
                              width: 120 * _settings.sizeRatio / 0.08,
                              height: 120 * _settings.sizeRatio / 0.08,
                              child: previewUrl != null
                                  ? Image.network(previewUrl, fit: BoxFit.contain)
                                  : Image.asset(fallbackAsset, fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _settings.hasCustomImage
                        ? s.adminWatermarkUsingCustom
                        : s.adminWatermarkUsingDefault,
                    style: AdminTheme.hint,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _uploading ? null : _pickAndUpload,
                    icon: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_outlined),
                    label: Text(s.adminWatermarkUpload),
                  ),
                  if (_settings.hasCustomImage) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _clearCustom,
                      icon: const Icon(Icons.restore_outlined),
                      label: Text(s.adminWatermarkUseDefault),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.adminWatermarkTuning, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.adminWatermarkEnabled),
                    subtitle: Text(s.adminWatermarkEnabledHint, style: AdminTheme.hint),
                    value: _settings.enabled,
                    onChanged: (v) => setState(
                      () => _settings = PlatformWatermarkSettings(
                        enabled: v,
                        storagePath: _settings.storagePath,
                        publicUrl: _settings.publicUrl,
                        opacity: _settings.opacity,
                        sizeRatio: _settings.sizeRatio,
                      ),
                    ),
                  ),
                  Text(s.adminWatermarkOpacityLabel(_settings.opacity)),
                  Slider(
                    min: 40,
                    max: 120,
                    divisions: 16,
                    value: _settings.opacity.toDouble(),
                    label: '${_settings.opacity}',
                    onChanged: (v) => setState(
                      () => _settings = PlatformWatermarkSettings(
                        enabled: _settings.enabled,
                        storagePath: _settings.storagePath,
                        publicUrl: _settings.publicUrl,
                        opacity: v.round(),
                        sizeRatio: _settings.sizeRatio,
                      ),
                    ),
                  ),
                  Text(s.adminWatermarkSizeLabel((_settings.sizeRatio * 100).round())),
                  Slider(
                    min: 0.05,
                    max: 0.14,
                    divisions: 9,
                    value: _settings.sizeRatio.clamp(0.05, 0.14),
                    label: '${(_settings.sizeRatio * 100).round()}%',
                    onChanged: (v) => setState(
                      () => _settings = PlatformWatermarkSettings(
                        enabled: _settings.enabled,
                        storagePath: _settings.storagePath,
                        publicUrl: _settings.publicUrl,
                        opacity: _settings.opacity,
                        sizeRatio: v,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saving ? null : _saveTuning,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(s.adminWatermarkSaveTuning),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(s.adminWatermarkNote, style: AdminTheme.hint),
        ],
      ),
    );
  }
}
