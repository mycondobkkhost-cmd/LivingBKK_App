import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/saved_search_service.dart';
import '../../state/search_session_controller.dart';
import '../../theme/app_theme.dart';

class SavedSearchesPage extends StatefulWidget {
  const SavedSearchesPage({
    super.key,
    required this.searchSession,
  });

  final SearchSessionController searchSession;

  @override
  State<SavedSearchesPage> createState() => _SavedSearchesPageState();
}

class _SavedSearchesPageState extends State<SavedSearchesPage> {
  @override
  void initState() {
    super.initState();
    SavedSearchService.instance.load();
  }

  Future<void> _saveCurrent() async {
    final filters = widget.searchSession.filters;
    final s = AppStrings.of(context);
    final name = s.filtersSummary(filters);
    await SavedSearchService.instance.save(
      name: name,
      filters: filters,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).savedSearchCreated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ListenableBuilder(
      listenable: SavedSearchService.instance,
      builder: (context, _) {
        final items = SavedSearchService.instance.items;
        return Scaffold(
          appBar: AppBar(
            title: Text(s.savedSearchTitle),
            actions: [
              TextButton.icon(
                onPressed: _saveCurrent,
                icon: const Icon(Icons.add_alert_outlined, size: 18),
                label: Text(s.savedSearchSaveCurrent),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: AppTheme.accentDeepLight,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    s.savedSearchIntro,
                    style: TextStyle(fontSize: 13, height: 1.45),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Text(
                    s.savedSearchEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              else
                ...items.map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(s.filtersSummary(item.filters)),
                      trailing: Switch(
                        value: item.notifyEnabled,
                        onChanged: (v) =>
                            SavedSearchService.instance.toggleNotify(item.id, v),
                      ),
                      onTap: () {
                        widget.searchSession.setFilters(item.filters);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
