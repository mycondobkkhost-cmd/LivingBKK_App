/// ทำเล / โครงการที่เลือกในฟอร์มความต้องการ
class RequirementLocationEntry {
  const RequirementLocationEntry({
    required this.label,
    this.projectSlug,
    this.geoZoneSlug,
    this.isCustom = false,
  });

  final String label;
  final String? projectSlug;
  final String? geoZoneSlug;
  final bool isCustom;

  @override
  bool operator ==(Object other) =>
      other is RequirementLocationEntry &&
      other.label.toLowerCase() == label.toLowerCase();

  @override
  int get hashCode => label.toLowerCase().hashCode;
}
