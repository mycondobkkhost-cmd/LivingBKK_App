import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/appointment.dart';
import '../../models/calendar_event.dart';
import '../../services/appointment_repository.dart';
import '../../services/calendar_event_repository.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/demo_cast_bootstrap.dart';
import '../../config/env.dart';
import '../../services/viewing_calendar_alert_service.dart';
import '../../services/viewing_appointment_record_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_theme.dart';
import '../../theme/living_bkk_brand.dart';
import '../../utils/admin_desktop.dart';
import '../../utils/admin_listing_nav.dart';
import 'admin_comp_card_widgets.dart';
import 'admin_nav_model.dart';
import '../../services/admin_comp_card_service.dart';
import '../../utils/appointment_staff_labels.dart';
import '../../utils/appointment_time_format.dart';
import 'admin_calendar_appointment_actions.dart';
import 'admin_calendar_day_appointment_card.dart';
import 'admin_calendar_day_timeline.dart';
import 'admin_calendar_event_card.dart';
import 'admin_calendar_event_sheet.dart';
import 'admin_viewing_follow_up_actions.dart';

Future<void> _openLeadFromSheet(BuildContext context, String leadId) async {
  dismissAdminRootOverlays(context);
  await Future<void>.delayed(const Duration(milliseconds: 40));
  if (!context.mounted) return;
  context.push('/admin/lead/$leadId');
}

String _appointmentPlace(Appointment a) {
  final loc = a.locationLabel?.trim();
  if (loc != null && loc.isNotEmpty) return loc;
  return a.listingCode ?? '—';
}

Color _appointmentAccent(Appointment a, Color Function(String) statusColor) {
  if (appointmentIsNoShow(a)) return Colors.red.shade700;
  return statusColor(a.status);
}

Future<void> _openDayListSheet(
  BuildContext context, {
  required String dayLabel,
  required List<Appointment> initialItems,
  required List<CalendarEvent> initialCalendarEvents,
  required Future<List<Appointment>> Function() loadItems,
  required Future<List<CalendarEvent>> Function() loadCalendarEvents,
  required AppStrings s,
  required Future<void> Function() onCalendarRefresh,
  required Color Function(String) statusColor,
  required bool canAssignStaff,
}) {
  final dayListKey = GlobalKey<_DayListPanelState>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: initialItems.isEmpty ? 0.38 : 0.58,
      minChildSize: 0.32,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => _DayListPanel(
        key: dayListKey,
        dayLabel: dayLabel,
        initialItems: initialItems,
        calendarEvents: initialCalendarEvents,
        loadItems: loadItems,
        loadCalendarEvents: loadCalendarEvents,
        s: s,
        scrollController: scrollController,
        onCalendarRefresh: onCalendarRefresh,
        onDayListReload: () async {
          await dayListKey.currentState?.reload();
        },
        statusColor: statusColor,
        canAssignStaff: canAssignStaff,
      ),
    ),
  );
}

Future<void> _openAppointmentDetail(
  BuildContext context, {
  required Appointment appointment,
  required Future<void> Function() onParentRefresh,
  required bool canAssignStaff,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (ctx) => _AppointmentDetailSheet(
      initial: appointment,
      onParentRefresh: onParentRefresh,
      canAssignStaff: canAssignStaff,
    ),
  );
}

/// Sheet รายละเอียด — โหลดใหม่หลังระบุคนพา / ยืนยัน
class _AppointmentDetailSheet extends StatefulWidget {
  const _AppointmentDetailSheet({
    required this.initial,
    required this.onParentRefresh,
    required this.canAssignStaff,
  });

  final Appointment initial;
  final Future<void> Function() onParentRefresh;
  final bool canAssignStaff;

  @override
  State<_AppointmentDetailSheet> createState() => _AppointmentDetailSheetState();
}

class _AppointmentDetailSheetState extends State<_AppointmentDetailSheet> {
  final _repo = AppointmentRepository();
  late Appointment _appointment;
  bool _busy = false;
  bool _pickingStaff = false;

  @override
  void initState() {
    super.initState();
    _appointment = widget.initial;
    unawaited(ViewingAppointmentRecordService.instance.init());
  }

  Appointment _withStaff(String? staffId) => Appointment(
        id: _appointment.id,
        leadId: _appointment.leadId,
        listingId: _appointment.listingId,
        listingCode: _appointment.listingCode,
        seekerNickname: _appointment.seekerNickname,
        seekerPhone: _appointment.seekerPhone,
        scheduledDate: _appointment.scheduledDate,
        timeSlot: _appointment.timeSlot,
        status: _appointment.status,
        locationLabel: _appointment.locationLabel,
        lat: _appointment.lat,
        lng: _appointment.lng,
        adminNotes: _appointment.adminNotes,
        assignedTo: staffId,
        transactionRef: _appointment.transactionRef,
        viewingReport: _appointment.viewingReport,
      );

  Future<void> _reload({bool refreshParent = false}) async {
    final fresh = await _repo.fetchById(_appointment.id);
    if (fresh != null && mounted) {
      setState(() => _appointment = fresh);
    }
    if (refreshParent) await widget.onParentRefresh();
  }

  void _toggleStaffPicker() {
    if (_busy) return;
    setState(() => _pickingStaff = !_pickingStaff);
  }

  Future<void> _applyStaff(String? staffId) async {
    if (_busy || staffId == null || staffId.isEmpty) return;
    final s = context.s;
    final name = AppointmentStaffLabels.label(staffId, isEn: s.isEnglish);
    setState(() {
      _pickingStaff = false;
      _appointment = _withStaff(staffId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${s.adminCalendarStaffAssigned(name)}\n${s.adminCalendarStaffAssignNeedConfirm}',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
    try {
      await _repo.updateAssignment(_appointment.id, staffId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _confirmStatus() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await confirmGuideForAppointment(
        context,
        appointment: _appointment,
        onRefresh: () async {
          await _reload(refreshParent: true);
        },
      );
      if (!mounted) return;
      final fresh = await _repo.fetchById(_appointment.id);
      if (fresh != null) setState(() => _appointment = fresh);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final needsGuideConfirm = appointmentNeedsGuideConfirm(_appointment);
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.adminCalendarDetailTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(),
              ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AppointmentCard(
                      appointment: _appointment,
                      s: s,
                      canAssignStaff: widget.canAssignStaff,
                      onAssign: _toggleStaffPicker,
                      onStatus: (_, __) => _confirmStatus(),
                      onFollowUpRecorded: () {
                        _reload(refreshParent: true);
                      },
                      onOpenLead: (leadId) => _openLeadFromSheet(context, leadId),
                      onOpenChat: (appt) =>
                          openCustomerChatForAppointment(context, appt),
                      pinGuideConfirmInSheet: false,
                    ),
                    if (widget.canAssignStaff && _pickingStaff) ...[
                      const SizedBox(height: 8),
                      _InlineStaffPicker(
                        s: s,
                        selectedId: _appointment.assignedTo,
                        onPick: _applyStaff,
                        onCancel: () => setState(() => _pickingStaff = false),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (needsGuideConfirm) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _confirmStatus,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(guideConfirmLabel(s, _appointment)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// เลือกคนพาในหน้าเดียว — ไม่เปิด modal ซ้อน (แก้กดไม่ได้บนเว็บ)
class _InlineStaffPicker extends StatelessWidget {
  const _InlineStaffPicker({
    required this.s,
    required this.selectedId,
    required this.onPick,
    required this.onCancel,
  });

  final AppStrings s;
  final String? selectedId;
  final ValueChanged<String?> onPick;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminTheme.surfaceMuted.withOpacity(0.55),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.adminCalendarAssignStaff,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            for (final o in AppointmentStaffLabels.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: OutlinedButton(
                  onPressed: () => onPick(o.id),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    backgroundColor: selectedId == o.id
                        ? AppTheme.primary.withOpacity(0.08)
                        : null,
                    side: BorderSide(
                      color: selectedId == o.id
                          ? AppTheme.primary
                          : AdminTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.isEnglish ? o.en : o.th,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        o.phone,
                        style: AdminTheme.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            TextButton(
              onPressed: () => onPick(null),
              child: Text(s.adminCalendarClearStaff),
            ),
          ],
        ),
      ),
    );
  }
}

/// ปฏิทินนัดชมขนาดใหญ่ — ภาพรวม · คำขอนัด · เจ้าหน้าที่พาดู
class AdminViewingCalendarTab extends StatefulWidget {
  const AdminViewingCalendarTab({
    super.key,
    this.viewingStaffOnly = false,
    this.onAttentionCountChanged,
  });

  final bool viewingStaffOnly;
  final void Function(int attentionCount)? onAttentionCountChanged;

  @override
  State<AdminViewingCalendarTab> createState() => _AdminViewingCalendarTabState();
}

class _AdminViewingCalendarTabState extends State<AdminViewingCalendarTab> {
  final _repo = AppointmentRepository();
  final _calendarRepo = CalendarEventRepository();
  bool _loading = true;
  List<Appointment> _items = [];
  List<CalendarEvent> _calendarEvents = [];
  ViewingCalendarAlertSummary _alerts = const ViewingCalendarAlertSummary();
  late DateTime _focusedMonth;
  DateTime _selectedDay = DateTime.now();
  String? _staffUserId;
  String? _staffSlug;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (widget.viewingStaffOnly) {
      final access = await AuthService.instance.fetchProfileAccess();
      _staffUserId = AuthService.instance.effectiveUserId;
      _staffSlug = access.staffSlug;
    } else if (Env.adminDemoCases) {
      await AppointmentRepository.ensureDemoSeedCurrent();
    }
    await AdminCompCardService.instance.ensureSeeded();
    await _load();
  }

  void _selectDay(DateTime d, {required bool wide}) {
    final day = DateTime(d.year, d.month, d.day);
    setState(() => _selectedDay = day);
    if (!wide) {
      final s = context.s;
      _openDayListSheet(
        context,
        dayLabel: _dayLabel(day, s),
        initialItems: _forDay(day),
        initialCalendarEvents: _calendarForDay(day),
        loadItems: () async => _forDay(day),
        loadCalendarEvents: () async => _calendarForDay(day),
        s: s,
        onCalendarRefresh: _reloadCalendarItems,
        statusColor: _statusColor,
        canAssignStaff: _canAssignStaff,
      );
    }
  }

  String _dayLabel(DateTime day, AppStrings s) {
    final y = s.isEnglish ? day.year : day.year + 543;
    return '${day.day}/${day.month}/$y';
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final list = await _repo.fetchUpcoming(
      limit: 200,
      staffUserId: widget.viewingStaffOnly ? _staffUserId : null,
      staffSlug: widget.viewingStaffOnly ? _staffSlug : null,
    );
    final events = await _calendarRepo.fetchUpcoming();
    if (!mounted) return;
    final items = list.where((a) => a.status != 'cancelled').toList();
    final alerts = await ViewingCalendarAlertService.analyze(items);
    if (!mounted) return;
    setState(() {
      _items = items;
      _calendarEvents = events.where((e) => e.status != 'cancelled').toList();
      _alerts = alerts;
      _loading = false;
    });
    widget.onAttentionCountChanged?.call(alerts.navBadgeCount);
    await ViewingCalendarAlertService.markSnapshot(items);
    widget.onAttentionCountChanged?.call(0);
    if (!widget.viewingStaffOnly) {
      final s = context.s;
      await ViewingCalendarAlertService.publishOverviewBanner(
        summary: alerts,
        message: s.adminCalendarAlertOverview(
          unassigned: alerts.unassigned,
          awaitingConfirm: alerts.awaitingConfirm,
          newCases: alerts.newCases,
          postViewing: alerts.postViewing,
        ),
        force: !silent,
      );
    }
  }

  Future<void> _reloadCalendarItems() => _load(silent: true);

  Future<void> _resetTrialCases() async {
    if (!Env.adminDemoCases) return;
    final s = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.adminResetTrialCases),
        content: Text(s.adminResetTrialCasesConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.adminResetTrialCases),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _loading = true);
    await AppointmentRepository.ensureDemoSeedCurrent(force: true);
    await DemoCastBootstrap.resetViewingTrialCases();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.adminResetTrialCasesDone)),
    );
  }

  bool get _canAssignStaff => !widget.viewingStaffOnly;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Appointment> _forDay(DateTime day) {
    return _items.where((a) => _sameDay(a.scheduledDate, day)).toList()
      ..sort((a, b) => a.timeSlot.compareTo(b.timeSlot));
  }

  List<CalendarEvent> _calendarForDay(DateTime day) {
    return _calendarEvents.where((e) => _sameDay(e.startAt, day)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  int get _aiDraftCount =>
      _calendarEvents.where((e) => e.isAiDraft).length;

  int _countWhere(bool Function(Appointment a) test) =>
      _items.where(test).length;

  String _monthTitle(DateTime m, AppStrings s) {
    const thMonths = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    if (s.isEnglish) {
      return '${[
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][m.month - 1]} ${m.year}';
    }
    return '${thMonths[m.month - 1]} ${m.year + 543}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppTheme.primary;
      case 'completed':
        return Colors.green.shade700;
      default:
        return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayItems = _forDay(today);
    final selectedItems = _forDay(_selectedDay);
    final weekEnd = today.add(const Duration(days: 7));
    final weekCount = _items
        .where(
          (a) =>
              !a.scheduledDate.isBefore(today) &&
              a.scheduledDate.isBefore(weekEnd),
        )
        .length;

    // โหมดคอม (sidebar) — ใช้เลย์เอาต์แยกปฏิทิน|รายการวัน แม้พื้นที่แคบกว่า 900px
    final wide =
        useAdminWideShell(context) ||
        MediaQuery.sizeOf(context).width >= kAdminDesktopMinWidth;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.adminCalendarTitle,
                    style: AdminTheme.title.copyWith(fontSize: 16),
                  ),
                  Text(
                    s.adminCalendarSubtitle,
                    style: AdminTheme.caption.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!widget.viewingStaffOnly && Env.adminDemoCases) ...[
              TextButton(
                onPressed: _resetTrialCases,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.restart_alt, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      s.adminResetTrialCases,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.go('/admin?nav=appointments'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      s.adminCalendarListMapLink,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (_alerts.hasAny && !widget.viewingStaffOnly)
          _CalendarAlertBanner(summary: _alerts, s: s),
        if (_alerts.hasAny && !widget.viewingStaffOnly) const SizedBox(height: 8),
        _SummaryRow(
          tiles: [
            _SummaryTile(
              label: s.adminCalendarTodayCount(todayItems.length),
              icon: Icons.today_outlined,
              color: LivingBkkBrand.purplePrimary,
              highlight: todayItems.isNotEmpty,
            ),
            _SummaryTile(
              label: s.adminCalendarPendingCount(
                _countWhere((a) => a.status == 'pending'),
              ),
              icon: Icons.pending_actions_outlined,
              color: Colors.orange.shade800,
              highlight: _countWhere((a) => a.status == 'pending') > 0,
            ),
            _SummaryTile(
              label: s.adminCalendarWeekCount(weekCount),
              icon: Icons.date_range_outlined,
              color: AppTheme.primary,
            ),
            if (!widget.viewingStaffOnly)
              _SummaryTile(
                label: s.adminCalendarUnassignedCount(
                  _countWhere((a) => a.assignedTo == null || a.assignedTo!.isEmpty),
                ),
                icon: Icons.person_off_outlined,
                color: AppTheme.textSecondary,
              ),
            if (!widget.viewingStaffOnly && _aiDraftCount > 0)
              _SummaryTile(
                label: s.adminCalendarAiDraftCount(_aiDraftCount),
                icon: Icons.auto_awesome,
                color: LivingBkkBrand.purplePrimary,
                highlight: true,
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );

    final monthCalendar = _MonthCalendar(
      focusedMonth: _focusedMonth,
      selectedDay: _selectedDay,
      items: _items,
      calendarEvents: _calendarEvents,
      s: s,
      monthTitle: _monthTitle(_focusedMonth, s),
      onPrev: () => setState(() {
        _focusedMonth = DateTime(
          _focusedMonth.year,
          _focusedMonth.month - 1,
        );
      }),
      onNext: () => setState(() {
        _focusedMonth = DateTime(
          _focusedMonth.year,
          _focusedMonth.month + 1,
        );
      }),
      onSelectDay: (d) => _selectDay(d, wide: wide),
      statusColor: _statusColor,
    );

    final dayEvents = _calendarForDay(_selectedDay);
    final timeline = AdminCalendarDayTimeline(
      entries: AdminCalendarTimelineEntry.fromDay(
        appointments: selectedItems,
        events: dayEvents,
        appointmentStatusColor: _statusColor,
        onEventTap: (e) => showAdminCalendarEventSheet(
          context,
          initial: e,
          onSaved: _reloadCalendarItems,
        ),
        onAppointmentTap: (a) => _openAppointmentDetail(
          context,
          appointment: a,
          onParentRefresh: _reloadCalendarItems,
          canAssignStaff: _canAssignStaff,
        ),
      ),
      s: s,
    );

    final dayPanel = _DayListPanel(
      dayLabel: _dayLabel(_selectedDay, s),
      initialItems: selectedItems,
      calendarEvents: dayEvents,
      loadItems: () async {
        await _load();
        return _forDay(_selectedDay);
      },
      loadCalendarEvents: () async {
        await _load();
        return _calendarForDay(_selectedDay);
      },
      s: s,
      onCalendarRefresh: _reloadCalendarItems,
      statusColor: _statusColor,
      canAssignStaff: _canAssignStaff,
      fillHeight: wide,
    );

    if (wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: header,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [monthCalendar, const SizedBox(height: 12), timeline],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: dayPanel),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          header,
          monthCalendar,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.tiles});

  final List<_SummaryTile> tiles;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tiles,
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? color.withOpacity(0.1)
            : AdminTheme.surfaceMuted.withOpacity(0.45),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlight
              ? color.withOpacity(0.35)
              : AdminTheme.border.withOpacity(0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: highlight ? color : AdminTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.focusedMonth,
    required this.selectedDay,
    required this.items,
    required this.calendarEvents,
    required this.s,
    required this.monthTitle,
    required this.onPrev,
    required this.onNext,
    required this.onSelectDay,
    required this.statusColor,
  });

  final DateTime focusedMonth;
  final DateTime selectedDay;
  final List<Appointment> items;
  final List<CalendarEvent> calendarEvents;
  final AppStrings s;
  final String monthTitle;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelectDay;
  final Color Function(String) statusColor;

  @override
  Widget build(BuildContext context) {
    final weekdays = s.isEnglish
        ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        : const ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

    final first = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startWeekday = first.weekday; // Mon=1

    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    List<Appointment> forDay(int day) {
      final d = DateTime(focusedMonth.year, focusedMonth.month, day);
      return items.where((a) => sameDay(a.scheduledDate, d)).toList();
    }

    List<CalendarEvent> eventsForDay(int day) {
      final d = DateTime(focusedMonth.year, focusedMonth.month, day);
      return calendarEvents.where((e) => sameDay(e.startAt, d)).toList();
    }

    final cells = <Widget>[
      for (final w in weekdays)
        Center(
          child: Text(
            w,
            style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
    ];

    for (var i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(focusedMonth.year, focusedMonth.month, day);
      final dayAppts = forDay(day);
      final dayEvents = eventsForDay(day);
      final isSelected = sameDay(date, selectedDay);
      final isToday = sameDay(date, DateTime.now());
      cells.add(_CalendarCell(
        day: day,
        appointments: dayAppts,
        calendarEvents: dayEvents,
        isSelected: isSelected,
        isToday: isToday,
        s: s,
        statusColor: statusColor,
        onTap: () => onSelectDay(date),
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text(
                    monthTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.85,
              children: cells,
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    required this.appointments,
    required this.calendarEvents,
    required this.isSelected,
    required this.isToday,
    required this.s,
    required this.statusColor,
    required this.onTap,
  });

  final int day;
  final List<Appointment> appointments;
  final List<CalendarEvent> calendarEvents;
  final bool isSelected;
  final bool isToday;
  final AppStrings s;
  final Color Function(String) statusColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? LivingBkkBrand.purplePrimary.withOpacity(0.14)
        : isToday
            ? Colors.amber.shade50
            : null;
    final border = isSelected
        ? Border.all(color: LivingBkkBrand.purplePrimary, width: 1.5)
        : isToday
            ? Border.all(color: Colors.amber.shade700, width: 1)
            : Border.all(color: AdminTheme.border.withOpacity(0.5));

    return Material(
      color: bg ?? AdminTheme.surfaceMuted.withOpacity(0.35),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(border: border, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? LivingBkkBrand.purplePrimary : AdminTheme.text,
                ),
              ),
              if (appointments.isNotEmpty || calendarEvents.isNotEmpty) ...[
                const SizedBox(height: 2),
                Builder(builder: (context) {
                  final noShows =
                      appointments.where(appointmentIsNoShow).length;
                  final aiDrafts =
                      calendarEvents.where((e) => e.isAiDraft).length;
                  final total = appointments.length + calendarEvents.length;
                  final accent = noShows > 0
                      ? Colors.red.shade700
                      : aiDrafts > 0
                          ? LivingBkkBrand.purplePrimary
                          : LivingBkkBrand.purplePrimary;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4),
                      border: noShows > 0
                          ? Border.all(color: accent.withOpacity(0.45))
                          : null,
                    ),
                    child: Text(
                      s.adminCalendarCellApptCount(total),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  );
                }),
                if (calendarEvents.any((e) => e.isAiDraft))
                  Text(
                    s.adminCalendarAiDraftBadge,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 6,
                      fontWeight: FontWeight.w800,
                      color: LivingBkkBrand.purplePrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (appointments.any(appointmentIsNoShow))
                  Text(
                    s.adminCalendarNoShowBadge,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 6,
                      fontWeight: FontWeight.w800,
                      color: Colors.red.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (appointments.length == 1)
                  Text(
                    appointments.first.timeSlot.split(' ').first,
                    style: AdminTheme.caption.copyWith(fontSize: 7),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// รายการย่อของวัน — แยกจากรายละเอียดเต็ม (เปิด sheet อีกชั้น)
class _DayListPanel extends StatefulWidget {
  const _DayListPanel({
    super.key,
    required this.dayLabel,
    required this.initialItems,
    required this.calendarEvents,
    required this.loadItems,
    required this.loadCalendarEvents,
    required this.s,
    required this.onCalendarRefresh,
    required this.statusColor,
    this.scrollController,
    this.onDayListReload,
    this.canAssignStaff = true,
    this.fillHeight = false,
  });

  final String dayLabel;
  final List<Appointment> initialItems;
  final List<CalendarEvent> calendarEvents;
  final Future<List<Appointment>> Function() loadItems;
  final Future<List<CalendarEvent>> Function() loadCalendarEvents;
  final AppStrings s;
  final Future<void> Function() onCalendarRefresh;
  final Future<void> Function()? onDayListReload;
  final Color Function(String) statusColor;
  final ScrollController? scrollController;
  final bool canAssignStaff;
  final bool fillHeight;

  @override
  State<_DayListPanel> createState() => _DayListPanelState();
}

class _DayListPanelState extends State<_DayListPanel> {
  final _calendarRepo = CalendarEventRepository();
  late List<Appointment> _items;
  late List<CalendarEvent> _events;
  String? _confirmingAppointmentId;
  String? _confirmingEventId;

  @override
  void initState() {
    super.initState();
    _items = widget.initialItems;
    _events = widget.calendarEvents;
  }

  @override
  void didUpdateWidget(_DayListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialItems != widget.initialItems) {
      _items = widget.initialItems;
    }
    if (oldWidget.calendarEvents != widget.calendarEvents) {
      _events = widget.calendarEvents;
    }
  }

  Future<void> reload() async {
    final next = await widget.loadItems();
    final ev = await widget.loadCalendarEvents();
    if (!mounted) return;
    setState(() {
      _items = next;
      _events = ev;
    });
  }

  Future<void> _afterDetailChange() async {
    await widget.onCalendarRefresh();
    await reload();
  }

  Widget _dayAppointmentCard(BuildContext context, Appointment a) {
    final s = widget.s;
    return AdminCalendarDayAppointmentCard(
      appointment: a,
      s: s,
      statusColor: _appointmentAccent(a, widget.statusColor),
      confirmGuideBusy: _confirmingAppointmentId == a.id,
      onTapDetail: () => _openAppointmentDetail(
        context,
        appointment: a,
        onParentRefresh: _afterDetailChange,
        canAssignStaff: widget.canAssignStaff,
      ),
      onOpenCustomerChat: () => openCustomerChatForAppointment(context, a),
      onOpenAdminOwnerChat: () => openAdminOwnerChatForAppointment(context, a),
      onConfirmGuide: appointmentNeedsGuideConfirm(a)
          ? () async {
              setState(() => _confirmingAppointmentId = a.id);
              try {
                await confirmGuideForAppointment(
                  context,
                  appointment: a,
                  onRefresh: _afterDetailChange,
                );
              } finally {
                if (mounted) {
                  setState(() => _confirmingAppointmentId = null);
                }
              }
            }
          : null,
    );
  }

  Future<void> _confirmEventDraft(CalendarEvent e) async {
    setState(() => _confirmingEventId = e.id);
    try {
      await _calendarRepo.confirmDraft(e);
      await _afterDetailChange();
    } finally {
      if (mounted) setState(() => _confirmingEventId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final events = _events;
    final s = widget.s;
    final confirmed = items.where((a) => a.status == 'confirmed').length;
    final pending = items.where((a) => a.status == 'pending').length;
    final unassigned =
        items.where((a) => a.assignedTo == null || a.assignedTo!.isEmpty).length;
    final inSheet = widget.scrollController != null;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.adminCalendarDayOverview(widget.dayLabel),
                    style: AdminTheme.section,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.adminCalendarDayDetail(widget.dayLabel, items.length),
                    style: AdminTheme.caption,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: items.isEmpty
                    ? AdminTheme.surfaceMuted
                    : LivingBkkBrand.purplePrimary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: items.isEmpty
                      ? AdminTheme.border
                      : LivingBkkBrand.purplePrimary.withOpacity(0.35),
                ),
              ),
              child: Text(
                s.adminCalendarDayCaseCount(items.length),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: items.isEmpty
                      ? AdminTheme.textMuted
                      : LivingBkkBrand.purplePrimary,
                ),
              ),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (confirmed > 0)
                _DayStatChip(
                  label: s.adminCalendarDayConfirmedCount(confirmed),
                  color: AppTheme.primary,
                ),
              if (pending > 0)
                _DayStatChip(
                  label: s.adminCalendarDayPendingCount(pending),
                  color: Colors.orange.shade800,
                ),
              if (unassigned > 0)
                _DayStatChip(
                  label: s.adminCalendarDayUnassignedCount(unassigned),
                  color: AppTheme.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(s.adminCalendarDayListTitle, style: AdminTheme.section),
          const SizedBox(height: 4),
          Text(s.adminCalendarTapForDetail, style: AdminTheme.caption),
        ],
      ],
    );

    if (items.isEmpty && events.isEmpty) {
      final emptyBody = Column(
        children: [
          if (!inSheet && !widget.fillHeight) header else ...[
            header,
            const SizedBox(height: 16),
          ],
          if (widget.fillHeight) const Spacer(),
          Icon(Icons.event_busy, size: 40, color: AdminTheme.textMuted),
          const SizedBox(height: 8),
          Text(
            s.adminCalendarDayEmpty,
            textAlign: TextAlign.center,
            style: AdminTheme.caption,
          ),
          if (widget.fillHeight) const Spacer(),
        ],
      );
      if (inSheet) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 28),
          child: emptyBody,
        );
      }
      if (widget.fillHeight) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                Expanded(child: emptyBody),
              ],
            ),
          ),
        );
      }
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: emptyBody,
        ),
      );
    }

    Widget eventCards() {
      return Column(
        children: [
          for (var i = 0; i < events.length; i++)
            AdminCalendarEventCard(
              event: events[i],
              s: s,
              busy: _confirmingEventId == events[i].id,
              onTap: () => showAdminCalendarEventSheet(
                context,
                initial: events[i],
                onSaved: _afterDetailChange,
              ),
              onConfirm: events[i].isAiDraft
                  ? () => _confirmEventDraft(events[i])
                  : null,
            ),
        ],
      );
    }

    if (inSheet) {
      return ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          header,
          const SizedBox(height: 10),
          if (events.isNotEmpty) ...[
            eventCards(),
            const SizedBox(height: 8),
          ],
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _dayAppointmentCard(context, items[i]),
          ],
        ],
      );
    }

    if (widget.fillHeight) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    if (events.isNotEmpty) ...[
                      eventCards(),
                      const SizedBox(height: 8),
                    ],
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _dayAppointmentCard(context, items[i]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final rowCount = items.length + events.length;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 8),
            if (events.isNotEmpty) ...[
              eventCards(),
              const SizedBox(height: 8),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: rowCount > 3 ? 640 : rowCount * 280.0,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: rowCount > 4
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final a = items[i];
                  return _dayAppointmentCard(context, a);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayStatChip extends StatelessWidget {
  const _DayStatChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _CalendarAlertBanner extends StatelessWidget {
  const _CalendarAlertBanner({required this.summary, required this.s});

  final ViewingCalendarAlertSummary summary;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notifications_active_outlined,
                size: 20, color: Colors.orange.shade900),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.adminCalendarAlertBannerTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.adminCalendarAlertOverview(
                      unassigned: summary.unassigned,
                      awaitingConfirm: summary.awaitingConfirm,
                      newCases: summary.newCases,
                      postViewing: summary.postViewing,
                    ),
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.s,
    this.onSelectDay,
    this.selected = false,
    this.canAssignStaff = true,
    required this.onAssign,
    required this.onStatus,
    this.onFollowUpRecorded,
    this.onOpenLead,
    this.onOpenChat,
    this.compact = false,
    this.pinGuideConfirmInSheet = true,
  });

  final Appointment appointment;
  final AppStrings s;
  final VoidCallback? onSelectDay;
  final bool selected;
  final bool canAssignStaff;
  final VoidCallback onAssign;
  final Future<void> Function(Appointment, String) onStatus;
  final VoidCallback? onFollowUpRecorded;
  final Future<void> Function(String leadId)? onOpenLead;
  final Future<void> Function(Appointment appointment)? onOpenChat;
  final bool compact;
  /// false = ปุ่มยืนยันเอเจ้นอยู่นอกการ์ด (sheet รายละเอียด)
  final bool pinGuideConfirmInSheet;

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppTheme.primary;
      case 'completed':
        return Colors.green.shade700;
      default:
        return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final noShow = appointmentIsNoShow(a);
    final staff = AppointmentStaffLabels.label(
      a.assignedTo,
      isEn: s.isEnglish,
    );
    final accent = noShow ? Colors.red.shade700 : _statusColor(a.status);

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 8 : 10),
      color: noShow
          ? Colors.red.shade50
          : selected
              ? AppTheme.primaryLight.withOpacity(0.35)
              : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  a.timeSlot,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: noShow
                        ? Border.all(color: Colors.red.shade300)
                        : null,
                  ),
                  child: Text(
                    noShow
                        ? s.adminCalendarNoShowBadge
                        : s.adminCalendarStatusLabel(a.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${a.seekerNickname} · ${a.listingCode ?? '—'}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            if (a.locationLabel != null && a.locationLabel!.isNotEmpty)
              Text(a.locationLabel!, style: AdminTheme.caption),
            const SizedBox(height: 8),
            AdminAppointmentChatAdminRow(
              appointment: a,
              compact: compact,
              onSendTag: (card, room) => sendCompCardTagToRoom(
                context,
                card: card,
                room: room,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: AdminTheme.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.adminCalendarStaffGuide(staff),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Builder(builder: (context) {
                        final guideCard =
                            AdminCompCardService.instance.byProfileId(a.assignedTo);
                        if (guideCard == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: AdminCompTagChip(
                            tagCode: guideCard.tagCode,
                            compact: true,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                if (canAssignStaff)
                  TextButton(
                    onPressed: onAssign,
                    child: Text(s.adminCalendarAssignStaff),
                  ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (a.listingCode != null && a.listingCode!.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => openAdminListing(
                      context,
                      listingId: a.listingId,
                      listingCode: a.listingCode,
                    ),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(s.adminOpenListing),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (a.leadId != null && a.leadId!.isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      if (onOpenChat != null) {
                        onOpenChat!(a);
                        return;
                      }
                      openCustomerChatForAppointment(context, a);
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: Text(s.adminOpenCustomerChat),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      final leadId = a.leadId!;
                      if (onOpenLead != null) {
                        onOpenLead!(leadId);
                        return;
                      }
                      context.push('/admin/lead/$leadId');
                    },
                    icon: const Icon(Icons.support_agent, size: 16),
                    label: Text(s.adminTabLeads),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
                if (pinGuideConfirmInSheet && appointmentNeedsGuideConfirm(a))
                  FilledButton.tonal(
                    onPressed: () => onStatus(a, 'confirmed'),
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: Text(guideConfirmLabel(s, a)),
                  ),
                if (appointmentEligibleForFollowUp(a))
                  FilledButton.icon(
                    onPressed: () => runAdminViewingFollowUp(
                      context,
                      appointment: a,
                      seekerNickname: a.seekerNickname,
                      seekerPhone: a.seekerPhone,
                      onRecorded: onFollowUpRecorded,
                      popParentSheetOnDone: true,
                    ),
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.fact_check_outlined, size: 16),
                    label: Text(s.adminViewingFollowUpBtn),
                  ),
                if (appointmentHasViewingReport(a))
                  OutlinedButton.icon(
                    onPressed: () => runAdminViewingFollowUp(
                      context,
                      appointment: a,
                      seekerNickname: a.seekerNickname,
                      seekerPhone: a.seekerPhone,
                    ),
                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.article_outlined, size: 16),
                    label: Text(s.adminViewingReportViewDetail),
                  ),
              ],
            ),
            if (appointmentHasViewingReport(a)) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => runAdminViewingFollowUp(
                  context,
                  appointment: a,
                  seekerNickname: a.seekerNickname,
                  seekerPhone: a.seekerPhone,
                ),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${s.adminViewingFollowUpBadge(a.viewingReport!.decision)} · ${a.viewingReport!.outcome}',
                    style: AdminTheme.caption.copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: AdminTheme.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
