class PropertyCareRight {
  const PropertyCareRight({
    required this.id,
    required this.userId,
    required this.careRole,
    required this.status,
    required this.isPrimary,
    required this.version,
    this.listingId,
    this.inventoryId,
    this.inventoryCode,
    this.listingCode,
    this.grantedBy,
    this.grantedAt,
    this.inviteCode,
    this.notes,
    this.userDisplayName,
  });

  final String id;
  final String? listingId;
  final String? inventoryId;
  final String? inventoryCode;
  final String? listingCode;
  final String userId;
  final String careRole;
  final String status;
  final bool isPrimary;
  final String? grantedBy;
  final DateTime? grantedAt;
  final String? inviteCode;
  final String? notes;
  final String? userDisplayName;
  final int version;

  Map<String, dynamic> toJson() => {
        'id': id,
        if (listingId != null) 'listing_id': listingId,
        if (inventoryId != null) 'inventory_id': inventoryId,
        if (inventoryCode != null) 'inventory_code': inventoryCode,
        if (listingCode != null) 'listing_code': listingCode,
        'user_id': userId,
        'care_role': careRole,
        'status': status,
        'is_primary': isPrimary,
        if (grantedBy != null) 'granted_by': grantedBy,
        if (grantedAt != null) 'granted_at': grantedAt!.toIso8601String(),
        if (inviteCode != null) 'invite_code': inviteCode,
        if (notes != null) 'notes': notes,
        if (userDisplayName != null) 'user_display_name': userDisplayName,
        'version': version,
      };

  factory PropertyCareRight.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];
    String? name = json['user_display_name']?.toString();
    if (name == null && profile is Map) {
      name = profile['display_name']?.toString();
    }
    final inv = json['property_inventory'];
    String? invCode;
    if (inv is Map) {
      invCode = inv['inventory_code']?.toString();
    }
    return PropertyCareRight(
      id: json['id']?.toString() ?? '',
      listingId: json['listing_id']?.toString(),
      inventoryId: json['inventory_id']?.toString(),
      inventoryCode: json['inventory_code']?.toString() ?? invCode,
      listingCode: json['listing_code']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      careRole: json['care_role']?.toString() ?? 'primary_caretaker',
      status: json['status']?.toString() ?? 'active',
      isPrimary: json['is_primary'] == true,
      grantedBy: json['granted_by']?.toString(),
      grantedAt: json['granted_at'] != null
          ? DateTime.tryParse(json['granted_at'].toString())?.toLocal()
          : null,
      inviteCode: json['invite_code']?.toString(),
      notes: json['notes']?.toString(),
      userDisplayName: name,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}
