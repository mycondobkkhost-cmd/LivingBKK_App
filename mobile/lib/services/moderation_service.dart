import 'supabase_service.dart';

class ModerationResult {
  const ModerationResult({required this.allowed, this.flags = const [], this.message});

  final bool allowed;
  final List<Map<String, dynamic>> flags;
  final String? message;
}

class ModerationService {
  Future<ModerationResult> checkText(String text) async {
    if (!SupabaseService.isReady || text.trim().isEmpty) {
      return const ModerationResult(allowed: true);
    }

    final res = await SupabaseService.client!.functions.invoke(
      'moderate-listing-text',
      body: {'text': text},
    );

    final data = res.data as Map<String, dynamic>? ?? {};
    return ModerationResult(
      allowed: data['allowed'] as bool? ?? true,
      message: data['message'] as String?,
      flags: List<Map<String, dynamic>>.from(
        (data['flags'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      ),
    );
  }
}
