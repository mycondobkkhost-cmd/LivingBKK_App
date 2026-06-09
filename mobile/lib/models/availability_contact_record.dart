/// บันทึกการติดต่อเจ้าของ — แชทในระบบ / โทรนอกระบบ
enum AvailabilityContactChannel {
  inAppChat,
  externalPhone,
  other,
}

class AvailabilityContactRecord {
  const AvailabilityContactRecord({
    required this.at,
    required this.channel,
    this.note,
    this.actor,
  });

  final DateTime at;
  final AvailabilityContactChannel channel;
  final String? note;
  final String? actor;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'channel': channel.name,
        if (note != null && note!.isNotEmpty) 'note': note,
        if (actor != null && actor!.isNotEmpty) 'actor': actor,
      };

  factory AvailabilityContactRecord.fromJson(Map<String, dynamic> j) {
    final ch = j['channel']?.toString() ?? 'other';
    return AvailabilityContactRecord(
      at: DateTime.tryParse(j['at']?.toString() ?? '') ?? DateTime.now(),
      channel: AvailabilityContactChannel.values.firstWhere(
        (e) => e.name == ch,
        orElse: () => AvailabilityContactChannel.other,
      ),
      note: j['note']?.toString(),
      actor: j['actor']?.toString(),
    );
  }
}
