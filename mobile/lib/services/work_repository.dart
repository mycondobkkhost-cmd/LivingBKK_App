import 'lead_repository.dart';
import 'supabase_service.dart';

class WorkRepository {
  WorkRepository({LeadRepository? leads}) : _leads = leads ?? LeadRepository();

  final LeadRepository _leads;

  Future<List<Map<String, dynamic>>> mySubmittedLeads() => _leads.myLeads();

  Future<List<Map<String, dynamic>>> inboxLeads() => _leads.assignedLeads();

  Future<List<Map<String, dynamic>>> myDemandOffers() async {
    if (!SupabaseService.isReady) return [];
    final uid = SupabaseService.client!.auth.currentUser?.id;
    if (uid == null) return [];

    final data = await SupabaseService.client!
        .from('demand_offers')
        .select('id, status, offerer_capacity, created_at, demand_post_id')
        .eq('offerer_id', uid)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data as List);
  }
}
