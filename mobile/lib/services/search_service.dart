import 'supabase_service.dart';

class SearchPreviewItem {
  const SearchPreviewItem({required this.label, required this.value});
  final String label;
  final String value;
}

class SearchService {
  Future<({Map<String, dynamic> filters, List<SearchPreviewItem> preview})>
      parseQuery(String query) async {
    if (!SupabaseService.isReady) {
      return _demoParse(query);
    }

    final res = await SupabaseService.client!.functions.invoke(
      'smart-search-parse',
      body: {'query': query},
    );

    final data = res.data as Map<String, dynamic>;
    final preview = (data['preview'] as List? ?? [])
        .map((e) => SearchPreviewItem(
              label: e['label'] as String,
              value: e['value'] as String,
            ))
        .toList();

    return (
      filters: data['filters'] as Map<String, dynamic>? ?? {},
      preview: preview,
    );
  }

  ({Map<String, dynamic> filters, List<SearchPreviewItem> preview})
      _demoParse(String query) {
    final preview = <SearchPreviewItem>[];
    final filters = <String, dynamic>{};

    if (query.contains('สุขุมวิท') || query.contains('อโศก')) {
      preview.add(const SearchPreviewItem(label: 'ทำเล', value: 'สุขุมวิท, อโศก'));
      filters['geo_zone_slugs'] = ['sukhumvit', 'asok'];
    }
    if (query.contains('15') || query.contains('15k')) {
      preview.add(
        const SearchPreviewItem(label: 'งบ', value: '≤ 15,000 บาท/เดือน'),
      );
      filters['max_price_net'] = 15000;
    }
    if (query.contains('สัตว์') || query.contains('เลี้ยง')) {
      preview.add(const SearchPreviewItem(label: 'สัตว์เลี้ยง', value: 'อนุญาต'));
      filters['pet_allowed'] = true;
    }

    return (filters: filters, preview: preview);
  }
}
