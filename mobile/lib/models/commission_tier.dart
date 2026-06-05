class CommissionTier {
  const CommissionTier({
    required this.id,
    required this.name,
    required this.minMonths,
    this.maxMonths,
    required this.platformPercent,
    required this.agentPercent,
    required this.ownerPercent,
  });

  final String id;
  final String name;
  final int minMonths;
  final int? maxMonths;
  final double platformPercent;
  final double agentPercent;
  final double ownerPercent;

  factory CommissionTier.fromJson(Map<String, dynamic> json) {
    return CommissionTier(
      id: json['id'] as String,
      name: json['name'] as String,
      minMonths: json['min_months'] as int,
      maxMonths: json['max_months'] as int?,
      platformPercent: (json['platform_percent'] as num).toDouble(),
      agentPercent: (json['agent_percent'] as num).toDouble(),
      ownerPercent: (json['owner_percent'] as num).toDouble(),
    );
  }

  String get splitSummary =>
      'แพลตฟอร์ม ${platformPercent.toStringAsFixed(0)}% · '
      'นายหน้า ${agentPercent.toStringAsFixed(0)}% · '
      'เจ้าของ ${ownerPercent.toStringAsFixed(0)}%';

  static List<CommissionTier> demo() => const [
        CommissionTier(
          id: 'demo-t1',
          name: 'สัญญา 6 เดือน',
          minMonths: 0,
          maxMonths: 6,
          platformPercent: 40,
          agentPercent: 30,
          ownerPercent: 30,
        ),
        CommissionTier(
          id: 'demo-t2',
          name: 'สัญญา 12 เดือน',
          minMonths: 7,
          maxMonths: 12,
          platformPercent: 35,
          agentPercent: 35,
          ownerPercent: 30,
        ),
        CommissionTier(
          id: 'demo-t3',
          name: 'สัญญา 24 เดือน',
          minMonths: 13,
          maxMonths: 24,
          platformPercent: 30,
          agentPercent: 35,
          ownerPercent: 35,
        ),
      ];
}
