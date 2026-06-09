import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/vault_asset.dart';
import '../../services/admin_repository.dart';
import '../../services/availability_hidden_registry_service.dart';
import '../../services/registry_asset_ops_service.dart';
import '../../services/vault_repository.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../widgets/admin_mobile_layout.dart';
import 'admin_asset_registry_widgets.dart';

/// คลังทรัพย์แบบตาราง — ใช้ร่วมกันระหว่างคลังลับ (CEO/SUPER) และคลังปฏิบัติการ (แอดมินทั่วไป)
class AdminAssetRegistryPage extends StatefulWidget {
  const AdminAssetRegistryPage({
    super.key,
    required this.confidential,
    this.showStorageInfo = false,
    this.showSync = false,
    this.title,
  });

  /// true = คลังลับเห็น PII · false = แอดมินทั่วไป (เซ็นเซอร์)
  final bool confidential;
  final bool showStorageInfo;
  final bool showSync;
  final String? title;

  @override
  State<AdminAssetRegistryPage> createState() => _AdminAssetRegistryPageState();
}

class _AdminAssetRegistryPageState extends State<AdminAssetRegistryPage> {
  final _repo = VaultRepository.instance;
  final _admin = AdminRepository();
  final _search = TextEditingController();
  String _adminTier = 'admin';
  String? _filter;
  VaultListResult? _list;
  bool _loading = true;
  bool _syncing = false;
  bool _isDemoPreview = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final hidden = AvailabilityHiddenRegistryService.instance;
    hidden.ensureLoaded();
    hidden.addListener(_onHiddenChanged);
    _load();
    _loadTier();
  }

  void _onHiddenChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTier() async {
    try {
      final tier = await _admin.fetchAdminTier();
      if (mounted) setState(() => _adminTier = tier);
    } catch (_) {}
  }

  @override
  void dispose() {
    AvailabilityHiddenRegistryService.instance.removeListener(_onHiddenChanged);
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.list(entityType: _filter);
      if (!mounted) return;
      setState(() {
        _list = result;
        _isDemoPreview = result.isDemoPreview;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _sync() async {
    if (!widget.showSync) return;
    setState(() => _syncing = true);
    try {
      final n = await _repo.syncAll();
      await _load();
      if (!mounted) return;
      final msg = _repo.isDemoPreview
          ? context.s.adminVaultDemoSynced
          : context.s.adminVaultSynced;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_repo.isDemoPreview ? msg : '$msg ($n)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  List<VaultAssetSummary> get _filtered {
    final items = _list?.items ?? [];
    final hiddenPool = AvailabilityHiddenRegistryService.instance.hiddenSummaries();
    return filterAssetRegistry(items, _query, hiddenPool: hiddenPool);
  }

  Future<void> _openDetail(VaultAssetSummary item) async {
    try {
      final detail = await _repo.detail(
        entityType: item.entityType,
        entityId: item.entityId,
      );
      if (!mounted) return;
      await openAssetRegistryDetailSheet(
        context: context,
        detail: detail,
        confidential: widget.confidential,
        adminTier: _adminTier,
        isDemoPreview: _isDemoPreview,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final title = widget.title ??
        (widget.confidential ? s.adminNavVault : s.adminNavAssetRegistry);
    final filtered = _filtered;
    final total = _list?.items.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: AdminMobileLayout.scrollPadding(
                context,
                top: 12,
                horizontal: 12,
                fabClearance: 8,
              ),
              children: [
                if (widget.showStorageInfo) const _StorageInfoCard(),
                if (widget.showStorageInfo && _isDemoPreview) ...[
                  const SizedBox(height: 10),
                  _InfoBanner(message: s.adminVaultDemoBanner),
                ],
                if (!widget.confidential) ...[
                  _InfoBanner(
                    message: s.adminRegistryPublicBanner,
                    icon: Icons.folder_shared_outlined,
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(child: Text(title, style: AdminTheme.section)),
                    if (widget.showSync)
                      _syncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              onPressed: _sync,
                              icon: const Icon(Icons.sync),
                              tooltip: s.adminVaultSync,
                            ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _FilterChip(
                      label: s.adminVaultFilterAll,
                      selected: _filter == null,
                      onTap: () {
                        setState(() => _filter = null);
                        _load();
                      },
                    ),
                    _FilterChip(
                      label: s.adminVaultFilterImport,
                      selected: _filter == 'listing_import',
                      onTap: () {
                        setState(() => _filter = 'listing_import');
                        _load();
                      },
                    ),
                    _FilterChip(
                      label: s.adminVaultFilterListing,
                      selected: _filter == 'listing',
                      onTap: () {
                        setState(() => _filter = 'listing');
                        _load();
                      },
                    ),
                    _FilterChip(
                      label: s.adminVaultFilterProfile,
                      selected: _filter == 'profile',
                      onTap: () {
                        setState(() => _filter = 'profile');
                        _load();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AdminAssetRegistrySearchBar(
                  controller: _search,
                  total: total,
                  shown: filtered.length,
                  query: _query,
                  onChanged: () => setState(() => _query = _search.text),
                  onClear: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(_error!, style: TextStyle(color: AppTheme.error)),
                        if (widget.showSync) ...[
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _sync,
                            icon: const Icon(Icons.cloud_sync_outlined),
                            label: Text(s.adminVaultSync),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.52,
                    child: ListenableBuilder(
                      listenable: RegistryAssetOpsService.instance,
                      builder: (context, _) => AdminAssetRegistryTable(
                        items: filtered,
                        onRowTap: _openDetail,
                        emptyMessage: _query.isNotEmpty
                            ? s.adminRegistryNoSearchResults
                            : s.adminVaultEmpty,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message, this.icon = Icons.science_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LivingBkkBrand.purplePrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LivingBkkBrand.purplePrimary.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: LivingBkkBrand.purplePrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AdminTheme.caption.copyWith(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _StorageInfoCard extends StatelessWidget {
  const _StorageInfoCard();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AdminTheme.card(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage_outlined, color: LivingBkkBrand.purplePrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                s.adminVaultStorageTitle,
                style: AdminTheme.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(s.adminVaultStorageBody, style: AdminTheme.caption),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
