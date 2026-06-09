import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/appointment.dart';
import '../../models/calendar_event.dart';
import '../../theme/admin_theme.dart';
import '../../theme/living_bkk_brand.dart';

class AdminCalendarTimelineEntry {
  const AdminCalendarTimelineEntry({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.color,
    required this.isAiDraft,
    this.subtitle,
    this.onTap,
  });

  final String id;
  final String title;
  final String? subtitle;
  final DateTime start;
  final DateTime end;
  final Color color;
  final bool isAiDraft;
  final VoidCallback? onTap;

  static List<AdminCalendarTimelineEntry> fromDay({
    required List<Appointment> appointments,
    required List<CalendarEvent> events,
    required Color Function(String status) appointmentStatusColor,
    required void Function(CalendarEvent event)? onEventTap,
    required void Function(Appointment appt)? onAppointmentTap,
  }) {
    final out = <AdminCalendarTimelineEntry>[];
    for (final e in events) {
      if (e.status == 'cancelled') continue;
      out.add(
        AdminCalendarTimelineEntry(
          id: 'ev-${e.id}',
          title: e.title,
          subtitle: e.locationLabel ?? e.listingCode,
          start: e.startAt,
          end: e.endAt,
          color: _eventColor(e),
          isAiDraft: e.isAiDraft,
          onTap: onEventTap == null ? null : () => onEventTap(e),
        ),
      );
    }
    for (final a in appointments) {
      if (a.status == 'cancelled') continue;
      final times = _appointmentTimes(a);
      out.add(
        AdminCalendarTimelineEntry(
          id: 'ap-${a.id}',
          title: a.seekerNickname,
          subtitle: a.locationLabel ?? a.listingCode,
          start: times.$1,
          end: times.$2,
          color: appointmentStatusColor(a.status),
          isAiDraft: false,
          onTap: onAppointmentTap == null ? null : () => onAppointmentTap(a),
        ),
      );
    }
    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
  }

  static Color _eventColor(CalendarEvent e) {
    switch (e.colorHint) {
      case 'blue':
        return Colors.lightBlue.shade700;
      case 'green':
        return Colors.green.shade700;
      case 'grey':
        return Colors.blueGrey;
      default:
        return Colors.red.shade700;
    }
  }

  static (DateTime, DateTime) _appointmentTimes(Appointment a) {
    final d = a.scheduledDate;
    final slot = a.timeSlot.replaceAll('–', '-');
    final parts = slot.split('-').map((s) => s.trim()).toList();
    DateTime clock(String raw, DateTime day) {
      final m = RegExp(r'(\d{1,2})[:\.]?(\d{2})?').firstMatch(raw);
      final h = m != null ? int.parse(m.group(1)!) : 10;
      final min = m != null ? int.parse(m.group(2) ?? '0') : 0;
      return DateTime(day.year, day.month, day.day, h, min);
    }

    final start = clock(parts.isNotEmpty ? parts.first : '10:00', d);
    final end = clock(parts.length > 1 ? parts[1] : '11:00', d);
    return (start, end.isAfter(start) ? end : start.add(const Duration(hours: 1)));
  }
}

/// มุมมองวันแบบแกนเวลา (คล้าย Google Calendar)
class AdminCalendarDayTimeline extends StatelessWidget {
  const AdminCalendarDayTimeline({
    super.key,
    required this.entries,
    required this.s,
    this.hourStart = 8,
    this.hourEnd = 20,
  });

  final List<AdminCalendarTimelineEntry> entries;
  final AppStrings s;
  final int hourStart;
  final int hourEnd;

  @override
  Widget build(BuildContext context) {
    final totalHours = hourEnd - hourStart;
    const hourHeight = 52.0;
    final gridHeight = totalHours * hourHeight;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.adminCalendarDayTimelineTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(s.adminCalendarDayEmpty, style: AdminTheme.caption),
              )
            else
              SizedBox(
                height: gridHeight.clamp(200, 520),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 44,
                      height: gridHeight,
                      child: Column(
                        children: [
                          for (var h = hourStart; h < hourEnd; h++)
                            SizedBox(
                              height: hourHeight,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6, top: 2),
                                  child: Text(
                                    '${h.toString().padLeft(2, '0')}:00',
                                    style: AdminTheme.caption.copyWith(fontSize: 10),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Column(
                                children: [
                                  for (var h = hourStart; h < hourEnd; h++)
                                    Container(
                                      height: hourHeight,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: AdminTheme.border
                                                .withOpacity(0.45),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              ..._layoutEntries(
                                gridHeight,
                                constraints.maxWidth,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _layoutEntries(double gridHeight, double laneWidth) {
    if (entries.isEmpty) return const [];

    final totalMinutes = (hourEnd - hourStart) * 60;
    final lanes = <List<AdminCalendarTimelineEntry>>[];

    for (final e in entries) {
      var placed = false;
      for (final lane in lanes) {
        if (!lane.any((x) => _overlaps(x, e))) {
          lane.add(e);
          placed = true;
          break;
        }
      }
      if (!placed) lanes.add([e]);
    }

    final laneCount = lanes.length;
    final widgets = <Widget>[];
    for (var laneIdx = 0; laneIdx < lanes.length; laneIdx++) {
      final lane = lanes[laneIdx];
      final colW = laneWidth / laneCount;
      for (final e in lane) {
        final top = _offsetMinutes(e.start) / totalMinutes * gridHeight;
        final height = (_offsetMinutes(e.end) - _offsetMinutes(e.start))
                .clamp(28, totalMinutes) /
            totalMinutes *
            gridHeight;

        widgets.add(
          Positioned(
            top: top,
            left: laneIdx * colW + 2,
            width: colW - 4,
            height: height.clamp(28, gridHeight - top),
            child: _TimelineBlock(entry: e, s: s),
          ),
        );
      }
    }
    return widgets;
  }

  int _offsetMinutes(DateTime t) {
    final m = (t.hour - hourStart) * 60 + t.minute;
    return m.clamp(0, (hourEnd - hourStart) * 60);
  }

  bool _overlaps(AdminCalendarTimelineEntry a, AdminCalendarTimelineEntry b) =>
      a.start.isBefore(b.end) && b.start.isBefore(a.end);
}

class _TimelineBlock extends StatelessWidget {
  const _TimelineBlock({required this.entry, required this.s});

  final AdminCalendarTimelineEntry entry;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: entry.color.withOpacity(entry.isAiDraft ? 0.22 : 0.35),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: entry.onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: entry.isAiDraft
                  ? LivingBkkBrand.purplePrimary
                  : entry.color.withOpacity(0.65),
              width: entry.isAiDraft ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.isAiDraft)
                Text(
                  s.adminCalendarAiDraftBadge,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: LivingBkkBrand.purplePrimary,
                  ),
                ),
              Text(
                entry.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
              if (entry.subtitle != null)
                Text(
                  entry.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTheme.caption.copyWith(fontSize: 9),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
