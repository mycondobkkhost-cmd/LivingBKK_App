import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_strings.dart';
import '../../models/property_project_admin.dart';
import '../../services/listing_import_repository.dart';
import '../../services/project_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../utils/google_maps_share_url.dart';

/// หน้าย่อยเพิ่มโครงการ — วางลิงก์แชร์ Google Maps เพื่อปักพิกัด (ไม่ดึง API)
class AdminImportAddProjectSheet extends StatefulWidget {
  const AdminImportAddProjectSheet({
    super.key,
    required this.importId,
    required this.listingId,
    required this.initialProjectName,
    this.initialDistrict,
    required this.propertyType,
    required this.onDone,
  });

  final String importId;
  final String listingId;
  final String initialProjectName;
  final String? initialDistrict;
  final String propertyType;
  final VoidCallback onDone;

  @override
  State<AdminImportAddProjectSheet> createState() =>
      _AdminImportAddProjectSheetState();
}

class _AdminImportAddProjectSheetState extends State<AdminImportAddProjectSheet> {
  final _importRepo = ListingImportRepository.instance;
  final _projectRepo = ProjectRepository.instance;

  final _mapsLink = TextEditingController();
  final _nameTh = TextEditingController();
  final _nameEn = TextEditingController();
  final _district = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  String? _resolvedMapsUrl;
  bool _loadingCoords = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _nameTh.text = widget.initialProjectName.trim();
    _district.text = widget.initialDistrict?.trim() ?? '';
  }

  @override
  void dispose() {
    _mapsLink.dispose();
    _nameTh.dispose();
    _nameEn.dispose();
    _district.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _applyCoordsFromLink() async {
    final s = context.s;
    final link = _mapsLink.text.trim();
    if (!GoogleMapsShareUrl.looksLikeMapsUrl(link)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminImportMapsLinkInvalid)),
      );
      return;
    }

    setState(() => _loadingCoords = true);
    try {
      final hit = await GoogleMapsShareUrl.resolveAndParseCoords(link);
      if (!mounted) return;
      if (hit == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.adminImportMapsLinkNoCoords)),
        );
        return;
      }
      setState(() {
        _lat.text = hit.lat.toStringAsFixed(6);
        _lng.text = hit.lng.toStringAsFixed(6);
        _resolvedMapsUrl = hit.resolvedUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminImportMapsCoordsApplied)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminImportMapsLinkResolveFailed)),
      );
    } finally {
      if (mounted) setState(() => _loadingCoords = false);
    }
  }

  Future<void> _openMaps() async {
    final url = _resolvedMapsUrl ?? _mapsLink.text.trim();
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmAdd() async {
    final s = context.s;
    final nameTh = _nameTh.text.trim();
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    if (nameTh.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminImportProjectNameRequired)),
      );
      return;
    }
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminImportCoordsRequired)),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final district = _district.text.trim().isEmpty ? 'กรุงเทพฯ' : _district.text.trim();
      final nameEn = _nameEn.text.trim().isEmpty ? nameTh : _nameEn.text.trim();
      final propType = widget.propertyType == 'other' ? 'condo' : widget.propertyType;
      final sourceUrl = _resolvedMapsUrl ?? _mapsLink.text.trim();

      final created = await _projectRepo.create(
        PropertyProjectRow(
          id: '',
          slug: '',
          nameTh: nameTh,
          nameEn: nameEn,
          district: district,
          propertyType: propType,
          lat: lat,
          lng: lng,
          isActive: true,
          sourcePlatform: 'maps_share_link',
          sourceUrl: sourceUrl.isEmpty ? null : sourceUrl,
          aliases: [nameTh, if (nameEn != nameTh) nameEn],
        ),
      );

      await _importRepo.linkListingToProject(
        importId: widget.importId,
        listingId: widget.listingId,
        projectId: created.id,
        projectName: created.nameTh,
        district: created.district,
        lat: created.lat,
        lng: created.lng,
      );

      if (!mounted) return;
      widget.onDone();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.adminImportProjectLinked)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final hasCoords = _lat.text.trim().isNotEmpty && _lng.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(s.adminImportAddProjectTitle, style: AdminTheme.title.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          AdminNote(s.adminImportAddProjectHint),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _mapsLink,
                    decoration: InputDecoration(
                      labelText: s.adminImportMapsShareLink,
                      hintText: s.adminImportMapsShareLinkHint,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: (_busy || _loadingCoords) ? null : _applyCoordsFromLink,
                    icon: _loadingCoords
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.pin_drop_outlined, size: 18),
                    label: Text(s.adminImportApplyMapsLink),
                  ),
                  const SizedBox(height: 6),
                  AdminHint(s.adminImportMapsShareSteps),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameTh,
                    decoration: InputDecoration(
                      labelText: '${s.adminImportProjectNameTh} *',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameEn,
                    decoration: InputDecoration(
                      labelText: s.adminImportProjectNameEn,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _district,
                    decoration: InputDecoration(
                      labelText: s.adminImportDistrict,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _lat,
                          decoration: InputDecoration(
                            labelText: 'Lat',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _lng,
                          decoration: InputDecoration(
                            labelText: 'Lng',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasCoords) ...[
                    const SizedBox(height: 10),
                    AdminHint(s.adminImportCoordsFromLinkOnly),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if ((_resolvedMapsUrl ?? _mapsLink.text.trim()).isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _busy ? null : _openMaps,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(s.adminImportOpenGoogleMaps),
                ),
              FilledButton.icon(
                onPressed: _busy ? null : _confirmAdd,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_location_alt_outlined, size: 18),
                label: Text(s.adminImportConfirmAddProject),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
