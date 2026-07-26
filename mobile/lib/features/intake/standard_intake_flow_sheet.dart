import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/chat_room.dart';
import '../../models/participant_profile_data.dart';
import '../../models/profile_tag.dart';
import '../../models/viewing_request.dart';
import '../../services/chat_service.dart';
import '../../services/lead_repository.dart';
import '../../services/owner_inquiry_repository.dart';
import '../../services/participant_profile_prefill_service.dart';
import '../../services/profile_tag_repository.dart';
import '../../services/viewing_request_repository.dart';
import '../../services/viewing_appointment_record_service.dart';
import '../../theme/app_theme.dart';
import '../../models/viewing_submit_result.dart';
import 'intake_flow_config.dart';
import 'intake_who_section.dart';
import 'participant_profile_section.dart';

/// ฟอร์มมาตรฐาน 2 ชั้น — โปรไฟล์ + ส่วนเฉพาะงาน
class StandardIntakeFlowSheet extends StatefulWidget {
  const StandardIntakeFlowSheet({
    super.key,
    this.room,
    required this.config,
    this.inquiryType = 'general',
    this.prefilledQuestion,
    this.subtitle,
    this.adminListing,
    this.participantUserId,
  }) : assert(room != null || adminListing != null);

  final ChatRoom? room;
  final IntakeFlowConfig config;
  final String inquiryType;
  final String? prefilledQuestion;
  final String? subtitle;
  /// โหมดแอดมินบันทึกจากโทรศัพท์ — ไม่ต้องมีห้องแชท
  final AdminIntakeListing? adminListing;
  /// ลิงก์ recap ไปแชทกลางผู้ใช้ (ถ้ารู้ user id)
  final String? participantUserId;

  @override
  State<StandardIntakeFlowSheet> createState() =>
      _StandardIntakeFlowSheetState();
}

class _StandardIntakeFlowSheetState extends State<StandardIntakeFlowSheet> {
  final _repo = LeadRepository();
  final _profile = ParticipantProfileData();
  bool _loading = true;
  bool _submitting = false;
  String? _formError;

  ProfileTag? _clientTag;
  ProfileTag? _presenterTag;

  bool get _adminPhoneMode => widget.adminListing != null;

  ChatRoom get _effectiveRoom {
    if (widget.room != null) return widget.room!;
    final l = widget.adminListing!;
    return ChatRoom(
      id: 'admin-phone-${l.listingId}',
      listingId: l.listingId,
      listingCode: l.listingCode,
      listingTitle: l.listingTitle,
      projectName: l.projectName,
    );
  }

  DateTime? _viewingDate;
  TimeOfDay? _viewingTime;

  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _last4Ctrl;
  late final TextEditingController _occupationCtrl;
  late final TextEditingController _workplaceCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _inquiryCtrl;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _last4Ctrl = TextEditingController();
    _occupationCtrl = TextEditingController();
    _workplaceCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _inquiryCtrl = TextEditingController();

    if (widget.config.showInquiryQuestion) {
      final draft = widget.prefilledQuestion?.trim().isNotEmpty == true
          ? widget.prefilledQuestion!.trim()
          : (widget.room?.ownerInquiryDraft.trim() ?? '');
      if (draft.isNotEmpty) _inquiryCtrl.text = draft;
    }

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_adminPhoneMode) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final data = await ParticipantProfilePrefillService.instance.load(
      role: ProfileTagRole.seekerSelf,
    );
    _applyProfileToUi(data);
    if (mounted) setState(() => _loading = false);
  }

  void _applyProfileToUi(ParticipantProfileData data) {
    _profile.applicantType = data.applicantType;
    _profile.nickname = data.nickname;
    _profile.phone = data.phone;
    _profile.occupants = data.occupants;
    _profile.gender = data.gender;
    _profile.occupation = data.occupation;
    _profile.workplace = data.workplace;
    _profile.contract = data.contract;
    _profile.budgetMinPos = data.budgetMinPos;
    _profile.budgetMaxPos = data.budgetMaxPos;
    _profile.contractStartDate = data.contractStartDate;
    _profile.contractNotLaterThan = data.contractNotLaterThan;
    _profile.hasCar = data.hasCar;
    _profile.smoking = data.smoking;
    _profile.pets = data.pets;
    _profile.notes = data.notes;
    _profile.presenterDisplayName = data.presenterDisplayName;
    _profile.presenterAgency = data.presenterAgency;
    _profile.presenterLicense = data.presenterLicense;
    _profile.presenterPhone = data.presenterPhone;

    _nicknameCtrl.text = _profile.nickname;
    _phoneCtrl.text = _profile.phone;
    _occupationCtrl.text = _profile.occupation;
    _workplaceCtrl.text = _profile.workplace;
    _notesCtrl.text = _profile.notes;
  }

  Future<void> _onApplicantContextChanged() async {
    if (_profile.isCoAgent) {
      final data = await ParticipantProfilePrefillService.instance.loadCoAgentPair(
        clientTag: _clientTag,
        presenterTag: _presenterTag,
      );
      _applyProfileToUi(data);
    } else {
      final data = await ParticipantProfilePrefillService.instance.load(
        role: ProfileTagRole.seekerSelf,
        existingTag: _clientTag,
      );
      _applyProfileToUi(data);
    }
    setState(() {});
  }

  void _syncControllersToProfile() {
    _profile.nickname = _nicknameCtrl.text;
    _profile.phone = _phoneCtrl.text;
    _profile.customerPhoneLast4 = _last4Ctrl.text;
    _profile.occupation = _occupationCtrl.text;
    _profile.workplace = _workplaceCtrl.text;
    _profile.notes = _notesCtrl.text;
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _phoneCtrl.dispose();
    _last4Ctrl.dispose();
    _occupationCtrl.dispose();
    _workplaceCtrl.dispose();
    _notesCtrl.dispose();
    _inquiryCtrl.dispose();
    super.dispose();
  }

  String get _title {
    final s = AppStrings.of(context);
    if (_adminPhoneMode) {
      return s.adminPhoneViewingFormTitle;
    }
    return switch (widget.config.intent) {
      IntakeIntent.viewing => s.requestViewingTitle,
      IntakeIntent.ownerInquiry => s.ownerInquiryFormTitle,
      IntakeIntent.requirement => s.postDemandWantedButton,
      IntakeIntent.negotiation => s.t('ต่อรองราคา', 'Price negotiation'),
    };
  }

  Future<void> _pickContractStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _profile.contractStartDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _profile.contractStartDate = picked);
  }

  Future<void> _pickViewingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _viewingDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked == null) return;
    setState(() => _viewingDate = picked);
  }

  Future<void> _pickViewingTime() async {
    final picked = await pickViewingTimeSheet(context);
    if (picked == null) return;
    setState(() => _viewingTime = picked);
  }

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    setState(() => _formError = null);
    _syncControllersToProfile();

    final clientErr = _profile.validateClient(s);
    if (clientErr != null) {
      setState(() => _formError = clientErr);
      return;
    }

    if (widget.config.showViewingSchedule &&
        (_viewingDate == null || _viewingTime == null)) {
      setState(() => _formError = s.errRequiredFields);
      return;
    }

    if (widget.config.showInquiryQuestion &&
        _inquiryCtrl.text.trim().length < 2) {
      setState(() => _formError = s.ownerInquiryOpenAskRequired);
      return;
    }

    if (widget.config.intent == IntakeIntent.ownerInquiry) {
      await _submitOwnerInquiry(s);
      return;
    }

    if (widget.config.intent == IntakeIntent.viewing) {
      await _submitViewing(s);
    }
  }

  Future<void> _submitViewing(AppStrings s) async {
    String? customerLast4;
    var duplicateSuffix = false;
    if (_profile.isCoAgent) {
      customerLast4 =
          LeadRepository.normalizePhoneSuffix(_profile.customerPhoneLast4);
      duplicateSuffix =
          await _repo.isDuplicateCustomerPhoneSuffix(customerLast4);
    }

    setState(() => _submitting = true);
    final summary = Map<String, String>.from(_profile.buildSummary(s));
    final viewingSchedule = viewingScheduleSummary(s, _viewingDate, _viewingTime);
    if (viewingSchedule != null) {
      summary[s.summaryViewing] = viewingSchedule;
    }
    final movePlan = summary[s.summaryContractStart];

    try {
      final room = _effectiveRoom;
      final persisted = _adminPhoneMode
          ? room
          : await ChatService.instance.ensurePersistedRoom(room);

      ProfileTag? presenterTag = _presenterTag;
      if (_profile.isCoAgent && presenterTag == null &&
          _profile.presenterDisplayName.trim().isNotEmpty) {
        presenterTag = await ProfileTagRepository.instance.createTag(
          role: ProfileTagRole.coAgentPresenter,
          snapshot: _profile.toPresenterSnapshot(),
          subjectDisplayName: _profile.presenterDisplayName.trim(),
        );
      }

      final clientTag = await ProfileTagRepository.instance.createTag(
        role: _profile.clientTagRole,
        snapshot: _profile.toClientSnapshot(s),
        subjectDisplayName: _profile.nickname.trim(),
        basedOn: _clientTag,
      );

      final scheduledAt = DateTime(
        _viewingDate!.year,
        _viewingDate!.month,
        _viewingDate!.day,
        _viewingTime!.hour,
        _viewingTime!.minute,
      );

      final source = _adminPhoneMode
          ? (_profile.isCoAgent
              ? ViewingRequestSource.coAgent
              : ViewingRequestSource.adminPhone)
          : (_profile.isCoAgent
              ? ViewingRequestSource.coAgent
              : ViewingRequestSource.customer);

      final viewingReq = await ViewingRequestRepository.instance.create(
        listingId: persisted.listingId,
        listingCode: persisted.listingCode,
        listingTitle: persisted.listingTitle,
        projectName: persisted.projectName,
        scheduledAt: scheduledAt,
        clientTag: clientTag,
        presenterTag: presenterTag,
        source: source,
        threadId: _adminPhoneMode ? null : (persisted.isPersisted ? persisted.id : null),
      );

      if (_adminPhoneMode) {
        await ViewingAppointmentRecordService.instance.registerFromViewingForm(
          viewingRequest: viewingReq,
          clientTag: clientTag,
          presenterTag: presenterTag,
          scheduleLabel: viewingSchedule ?? '',
          room: persisted,
        );
        final uid = widget.participantUserId?.trim();
        if (uid != null && uid.isNotEmpty) {
          await ChatService.instance.postAdminPhoneViewingRecap(
            userId: uid,
            viewingRequest: viewingReq,
            clientTag: clientTag,
            presenterTag: presenterTag,
            scheduleLabel: viewingSchedule ?? '',
            propertyLabel: '${persisted.listingCode} · ${persisted.listingTitle}',
          );
        }
      } else {
        await ChatService.instance.submitViewingWithTags(
          persisted,
          viewingRequest: viewingReq,
          clientTag: clientTag,
          presenterTag: presenterTag,
          scheduleLabel: viewingSchedule ?? '',
          leadSummary: summary,
        );
      }

      final outcome = await _repo.submit(
        LeadSubmission(
          listingCode: persisted.listingCode,
          listingId: persisted.listingId,
          threadId: _adminPhoneMode
              ? null
              : (persisted.isPersisted ? persisted.id : null),
          seekerNickname: _profile.nickname.trim(),
          seekerPhone: _profile.phone.trim(),
          applicantType: _profile.applicantType,
          occupantsCount: _profile.parseOccupants(),
          gender: _profile.gender,
          occupation: _profile.occupation.trim(),
          workplace: _profile.workplace.trim().isEmpty
              ? null
              : _profile.workplace.trim(),
          movePlan: movePlan,
          contractDuration: _profile.contract!,
          budget: _profile.budgetMax,
          budgetMin: _profile.budgetMin,
          budgetMax: _profile.budgetMax,
          viewingSchedule: viewingSchedule,
          hasCar: _profile.hasCar == 'yes',
          pets: _profile.pets,
          smoking: _profile.smoking == 'yes'
              ? 'yes'
              : (_profile.smoking == 'no' ? 'no' : null),
          customerPhoneLast4: customerLast4,
          duplicatePhoneSuffix: duplicateSuffix,
          notes: _profile.notes.trim().isEmpty ? null : _profile.notes.trim(),
        ),
      );

      if (!mounted) return;
      Navigator.pop(
        context,
        ViewingSubmitResult(
          summary: summary,
          savedToDatabase: outcome.savedToDatabase,
          duplicatePhoneSuffix: duplicateSuffix,
          leadTransactionRef: outcome.transactionRef,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _formError = s.submitFailedWith('$e'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitOwnerInquiry(AppStrings s) async {
    setState(() => _submitting = true);
    try {
      final summary = Map<String, String>.from(_profile.buildSummary(s));
      summary[s.summaryInquiryQuestion] = _inquiryCtrl.text.trim();

      await OwnerInquiryRepository.instance.submit(
        threadId: widget.room!.id,
        listingCode: widget.room!.listingCode,
        listingId: widget.room!.listingId,
        inquiryType: widget.inquiryType,
        seekerQuestion: _inquiryCtrl.text.trim(),
        seekerContext: summary,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _formError = s.submitFailedWith('$e'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              widget.subtitle ??
                  (_adminPhoneMode
                      ? '${widget.adminListing!.listingCode} · ${widget.adminListing!.listingTitle}'
                      : _effectiveRoom.displayTitle),
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            if (widget.config.intent == IntakeIntent.ownerInquiry) ...[
              const SizedBox(height: 6),
              Text(
                s.ownerInquiryFormHint,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
            if (_formError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.error.withOpacity(0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formError!,
                        style: TextStyle(color: AppTheme.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            IntakeWhoSection(
              profile: _profile,
              allowCoAgent: widget.config.allowCoAgent,
              onChanged: () async {
                await _onApplicantContextChanged();
              },
              clientTag: _clientTag,
              presenterTag: _presenterTag,
              onClientTagChanged: (tag) async {
                _clientTag = tag;
                if (tag != null) {
                  _profile.applyFromTag(tag);
                  _applyProfileToUi(_profile);
                }
                setState(() {});
              },
              onPresenterTagChanged: (tag) {
                _presenterTag = tag;
                if (tag != null) _profile.applyFromTag(tag);
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            ParticipantProfileSection(
              profile: _profile,
              config: widget.config,
              onChanged: () => setState(() {}),
              nicknameCtrl: _nicknameCtrl,
              phoneCtrl: _phoneCtrl,
              customerLast4Ctrl: _last4Ctrl,
              occupationCtrl: _occupationCtrl,
              workplaceCtrl: _workplaceCtrl,
              notesCtrl: _notesCtrl,
              onPickContractStart: _pickContractStart,
            ),
            if (widget.config.showViewingSchedule)
              ViewingScheduleExtension(
                viewingDate: _viewingDate,
                viewingTime: _viewingTime,
                onPickDate: _pickViewingDate,
                onPickTime: _pickViewingTime,
              ),
            if (widget.config.showInquiryQuestion)
              InquiryQuestionExtension(
                controller: _inquiryCtrl,
                hint: s.ownerInquiryOpenAskHint,
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.config.intent == IntakeIntent.ownerInquiry
                          ? s.ownerInquirySubmitBtn
                          : s.submitViewingRequest,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<ViewingSubmitResult?> showAdminPhoneViewingIntake(
  BuildContext context, {
  required AdminIntakeListing listing,
  String? participantUserId,
}) {
  return showModalBottomSheet<ViewingSubmitResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => StandardIntakeFlowSheet(
      config: IntakeFlowConfig.adminPhone,
      adminListing: listing,
      participantUserId: participantUserId,
    ),
  );
}

Future<ViewingSubmitResult?> showStandardViewingIntake(
  BuildContext context, {
  required ChatRoom room,
}) {
  return showModalBottomSheet<ViewingSubmitResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => StandardIntakeFlowSheet(
      room: room,
      config: IntakeFlowConfig.viewing,
    ),
  );
}

Future<bool?> showStandardOwnerInquiryIntake(
  BuildContext context, {
  required ChatRoom room,
  String inquiryType = 'general',
  String? prefilledQuestion,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => StandardIntakeFlowSheet(
      room: room,
      config: IntakeFlowConfig.ownerInquiry,
      inquiryType: inquiryType,
      prefilledQuestion: prefilledQuestion,
    ),
  );
}
