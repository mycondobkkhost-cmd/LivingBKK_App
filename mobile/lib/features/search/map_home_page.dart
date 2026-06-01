import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/listing_public.dart';
import '../../services/listing_repository.dart';
import '../../theme/app_theme.dart';
import '../../models/listing_route_extra.dart';
import '../contact/lead_bot_sheet.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/listings_map.dart';
import '../../widgets/smart_search_bar.dart';

enum AgentMapMode { all, coAgentEligible, myWork }

class MapHomePage extends StatefulWidget {
  const MapHomePage({super.key, this.isAgent = false});

  final bool isAgent;

  @override
  State<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends State<MapHomePage> {
  final _repo = ListingRepository();
  List<ListingPublic> _listings = [];
  bool _loading = true;
  String? _listingType; // rent | sale
  AgentMapMode _agentMode = AgentMapMode.all;
  String? _selectedListingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.fetchPublished(
        listingType: _listingType,
        coAgentEligibleOnly:
            widget.isAgent && _agentMode == AgentMapMode.coAgentEligible,
      );
      setState(() {
        _listings = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LivingBKK', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SmartSearchBar(onApplyFilters: (_) => _load()),
          ),
          if (widget.isAgent)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<AgentMapMode>(
                segments: const [
                  ButtonSegment(value: AgentMapMode.all, label: Text('ทั้งหมด', style: TextStyle(fontSize: 12))),
                  ButtonSegment(
                    value: AgentMapMode.coAgentEligible,
                    label: Text('ขอโคเอเจ้นท์ได้', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(value: AgentMapMode.myWork, label: Text('งานของฉัน', style: TextStyle(fontSize: 12))),
                ],
                selected: {_agentMode},
                onSelectionChanged: (s) {
                  setState(() => _agentMode = s.first);
                  _load();
                },
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _chip('เช่า', _listingType == 'rent', () {
                  setState(() => _listingType = _listingType == 'rent' ? null : 'rent');
                  _load();
                }),
                _chip('ซื้อ', _listingType == 'sale', () {
                  setState(() => _listingType = _listingType == 'sale' ? null : 'sale');
                  _load();
                }),
                _chip('Co-Agent', false, () {}),
                _chip('BMV', false, () {}),
                _chip('ตัวกรอง', false, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Advanced filters — Phase 4.2')),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListingsMap(
                    listings: _listings,
                    selectedId: _selectedListingId,
                    onListingTap: (l) => setState(() => _selectedListingId = l.id),
                  ),
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.28,
                  minChildSize: 0.18,
                  maxChildSize: 0.75,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 24,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_listings.length} ทรัพย์',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                if (_loading)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _loading
                                ? const Center(child: CircularProgressIndicator())
                                : ListView.separated(
                                    controller: scrollController,
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                    itemCount: _listings.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                                    itemBuilder: (context, i) {
                                      final item = _listings[i];
                                      return ListingCard(
                                        listing: item,
                                        showCoAgentStrip: widget.isAgent,
                                        onTap: () => context.push(
                                          '/listing/${item.id}',
                                          extra: ListingRouteExtra(
                                            listing: item,
                                            isAgent: widget.isAgent,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLeadBotSheet(context),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('ติดต่อ'),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryLight,
        checkmarkColor: AppTheme.primary,
      ),
    );
  }
}
