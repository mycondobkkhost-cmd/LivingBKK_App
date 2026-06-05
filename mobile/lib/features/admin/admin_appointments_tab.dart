import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/appointment.dart';
import '../../services/appointment_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/appointments_map.dart';

class AdminAppointmentsTab extends StatefulWidget {
  const AdminAppointmentsTab({super.key});

  @override
  State<AdminAppointmentsTab> createState() => _AdminAppointmentsTabState();
}

class _AdminAppointmentsTabState extends State<AdminAppointmentsTab> {
  final _repo = AppointmentRepository();
  bool _loading = true;
  List<Appointment> _items = [];
  String? _selectedId;
  bool _showMap = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.fetchUpcoming();
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  String _dateLabel(DateTime d, AppStrings s) =>
      '${d.day}/${d.month}/${d.year + (s.isEnglish ? 0 : 543)}';

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppTheme.primary;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Text(
                s.adminManageAppointments,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              IconButton(
                tooltip: _showMap ? s.adminHideMap : s.adminShowMap,
                onPressed: () => setState(() => _showMap = !_showMap),
                icon: Icon(_showMap ? Icons.map : Icons.map_outlined),
              ),
            ],
          ),
          if (_showMap) ...[
            AppointmentsMap(
              appointments: _items,
              selectedId: _selectedId,
              onAppointmentTap: (a) => setState(() => _selectedId = a.id),
              height: 240,
            ),
            const SizedBox(height: 12),
          ],
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                s.adminAppointmentsEmpty,
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._items.map((a) {
              final selected = a.id == _selectedId;
              return Card(
                color: selected ? AppTheme.primaryLight.withOpacity(0.5) : null,
                child: ListTile(
                  leading: Icon(Icons.event, color: _statusColor(a.status)),
                  title: Text('${a.seekerNickname} · ${a.listingCode ?? ''}'),
                  subtitle: Text(
                    '${_dateLabel(a.scheduledDate, s)} · ${a.timeSlot}\n'
                    '${a.locationLabel ?? ''} · ${a.status}',
                  ),
                  isThreeLine: true,
                  onTap: () => setState(() => _selectedId = a.id),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      await _repo.updateStatus(a.id, v);
                      _load();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'confirmed', child: Text(s.adminConfirmAppointment)),
                      PopupMenuItem(value: 'completed', child: Text(s.adminCompleteAppointment)),
                      PopupMenuItem(value: 'cancelled', child: Text(s.cancel)),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
