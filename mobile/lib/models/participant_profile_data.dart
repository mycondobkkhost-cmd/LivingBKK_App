import '../l10n/app_strings.dart';
import '../services/lead_repository.dart';
import '../utils/price_slider_scale.dart';
import 'profile_tag.dart';

/// ข้อมูลโปรไฟล์มาตรฐาน — ใช้ร่วมทุกฟังก์ชัน (นัดดู / หาทรัพย์ / ต่อรอง)
class ParticipantProfileData {
  ParticipantProfileData({
    this.applicantType = 'seeker_self',
    this.nickname = '',
    this.phone = '',
    this.customerPhoneLast4 = '',
    this.occupants,
    this.gender,
    this.occupation = '',
    this.workplace = '',
    this.contract,
    this.budgetMinPos = 0,
    this.budgetMaxPos = 0.3,
    this.contractStartDate,
    this.contractNotLaterThan = false,
    this.hasCar,
    this.smoking,
    this.pets,
    this.notes = '',
    this.presenterDisplayName = '',
    this.presenterAgency = '',
    this.presenterLicense = '',
    this.presenterPhone = '',
  });

  String applicantType;
  String nickname;
  String phone;
  String customerPhoneLast4;
  String? occupants;
  String? gender;
  String occupation;
  String workplace;
  String? contract;
  double budgetMinPos;
  double budgetMaxPos;
  DateTime? contractStartDate;
  bool contractNotLaterThan;
  String? hasCar;
  String? smoking;
  String? pets;
  String notes;

  /// โคเอ — ผู้พานัด (PR)
  String presenterDisplayName;
  String presenterAgency;
  String presenterLicense;
  String presenterPhone;

  bool get isCoAgent => applicantType == 'co_agent_request';

  ProfileTagRole get clientTagRole =>
      isCoAgent ? ProfileTagRole.clientSubject : ProfileTagRole.seekerSelf;

  double get budgetMin => PriceSliderScale.rentPositionToBaht(budgetMinPos);
  double get budgetMax => PriceSliderScale.rentPositionToBaht(budgetMaxPos);

  String budgetRangeLabel({bool isSale = false}) =>
      '${PriceSliderScale.formatBaht(budgetMin, isSale: isSale)} – '
      '${PriceSliderScale.formatBaht(budgetMax, isSale: isSale)}';

  void applyFromTag(ProfileTag tag) {
    final snap = tag.snapshot;
    nickname = snap['nickname'] ?? snap['displayName'] ?? nickname;
    phone = snap['phone'] ?? phone;
    occupants = snap['occupants'] ?? occupants;
    occupation = snap['occupation'] ?? occupation;
    workplace = snap['workplace'] ?? workplace;
    contract = snap['contract'] ?? contract;
    notes = snap['notes'] ?? notes;
    if (tag.role == ProfileTagRole.coAgentPresenter) {
      presenterDisplayName = snap['displayName'] ?? presenterDisplayName;
      presenterAgency = snap['agencyName'] ?? presenterAgency;
      presenterLicense = snap['licenseNo'] ?? presenterLicense;
      presenterPhone = snap['phone'] ?? presenterPhone;
    }
  }

  Map<String, String> toClientSnapshot(AppStrings s) => {
        'nickname': nickname.trim(),
        'phone': phone.trim(),
        if (occupants != null) 'occupants': occupants!,
        'occupation': occupation.trim(),
        if (workplace.trim().isNotEmpty) 'workplace': workplace.trim(),
        if (contract != null) 'contract': contract!,
        'budget': budgetRangeLabel(),
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      };

  Map<String, String> toPresenterSnapshot() => {
        if (presenterDisplayName.trim().isNotEmpty)
          'displayName': presenterDisplayName.trim(),
        if (presenterAgency.trim().isNotEmpty) 'agencyName': presenterAgency.trim(),
        if (presenterLicense.trim().isNotEmpty) 'licenseNo': presenterLicense.trim(),
        if (presenterPhone.trim().isNotEmpty) 'phone': presenterPhone.trim(),
      };

  Map<String, String> buildSummary(AppStrings s) {
    String applicantLabel() {
      switch (applicantType) {
        case 'seeker_self':
          return s.customerRole;
        case 'co_agent_request':
          return s.coAgentRole;
        default:
          return '-';
      }
    }

    String contractLabel() {
      switch (contract) {
        case '6m':
          return s.contract6Months;
        case '12m':
          return s.contract1Year;
        case '24m':
          return s.contract2Years;
        default:
          return '-';
      }
    }

    String petsLabel() {
      switch (pets) {
        case 'none':
          return s.petNone;
        case 'cat':
          return s.petCat;
        case 'dog':
          return s.petDog;
        case 'other':
          return s.petOther;
        default:
          return '-';
      }
    }

    String? contractStartSummary() {
      if (contractStartDate == null) return null;
      final d = contractStartDate!;
      final label = '${d.day}/${d.month}/${d.year + (s.isEnglish ? 0 : 543)}';
      if (contractNotLaterThan) {
        return s.contractStartNotLaterThan(label);
      }
      return s.contractStartOn(label);
    }

    return {
      s.summaryWhoAreYou: applicantLabel(),
      s.summaryNickname: nickname.trim(),
      s.summaryPhone: phone.trim(),
      if (isCoAgent && customerPhoneLast4.trim().isNotEmpty)
        s.summaryCustomerLast4: customerPhoneLast4.trim(),
      s.summaryOccupants: occupants ?? '-',
      if (gender != null) s.summaryGender: leadGenderLabel(gender),
      s.summaryOccupation: occupation.trim(),
      if (workplace.trim().isNotEmpty) s.summaryWorkplace: workplace.trim(),
      s.summaryContract: contractLabel(),
      s.summaryBudget: budgetRangeLabel(),
      if (contractStartSummary() != null)
        s.summaryContractStart: contractStartSummary()!,
      if (hasCar != null)
        s.summaryHasCar: hasCar == 'yes' ? s.hasCarYes : s.hasCarNo,
      if (smoking != null)
        s.summarySmoking: smoking == 'yes' ? s.smokeYes : s.smokeNo,
      if (pets != null) s.summaryPets: petsLabel(),
      if (notes.trim().isNotEmpty) s.summaryNotes: notes.trim(),
    };
  }

  String? validateClient(AppStrings s) {
    if (nickname.trim().isEmpty || phone.trim().length < 9) {
      return s.errNicknamePhone;
    }
    if (occupants == null || occupation.trim().isEmpty || contract == null) {
      return s.errRequiredFields;
    }
    if (isCoAgent && customerPhoneLast4.trim().length != 4) {
      return s.errCoAgentLast4;
    }
    return null;
  }

  int? parseOccupants() {
    if (occupants == null) return null;
    if (occupants!.contains('+')) {
      return int.tryParse(occupants!.replaceAll('+', ''));
    }
    return int.tryParse(occupants!);
  }

  ParticipantProfileData copyWith({
    String? applicantType,
    String? nickname,
    String? phone,
  }) {
    return ParticipantProfileData(
      applicantType: applicantType ?? this.applicantType,
      nickname: nickname ?? this.nickname,
      phone: phone ?? this.phone,
      customerPhoneLast4: customerPhoneLast4,
      occupants: occupants,
      gender: gender,
      occupation: occupation,
      workplace: workplace,
      contract: contract,
      budgetMinPos: budgetMinPos,
      budgetMaxPos: budgetMaxPos,
      contractStartDate: contractStartDate,
      contractNotLaterThan: contractNotLaterThan,
      hasCar: hasCar,
      smoking: smoking,
      pets: pets,
      notes: notes,
      presenterDisplayName: presenterDisplayName,
      presenterAgency: presenterAgency,
      presenterLicense: presenterLicense,
      presenterPhone: presenterPhone,
    );
  }
}
