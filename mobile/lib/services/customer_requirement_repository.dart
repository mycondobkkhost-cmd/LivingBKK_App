import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../models/customer_requirement.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class RequirementSubmitOutcome {
  const RequirementSubmitOutcome({
    required this.requirement,
    required this.savedToDatabase,
  });

  final CustomerRequirement requirement;
  final bool savedToDatabase;
}

/// เก็บความต้องการลูกค้า (ในเครื่อง + ส่ง Supabase ถ้ามีตาราง)
class CustomerRequirementRepository extends ChangeNotifier {
  CustomerRequirementRepository._();
  static final instance = CustomerRequirementRepository._();

  final _items = <CustomerRequirement>[];
  bool _loadedRemote = false;

  List<CustomerRequirement> get items => List.unmodifiable(_items);

  List<CustomerRequirement> listForDisplay() {
    if (_items.isEmpty) return [CustomerRequirement.demo()];
    return List.unmodifiable(_items);
  }

  bool get isShowingDemo => _items.isEmpty;

  Future<void> refreshFromServer() async {
    if (!Env.isConfigured ||
        !SupabaseService.isReady ||
        !AuthService.instance.isRealSupabaseSession) {
      return;
    }
    try {
      final uid = SupabaseService.client!.auth.currentUser?.id;
      if (uid == null) return;
      final data = await SupabaseService.client!
          .from('customer_requirements')
          .select('*, demand_posts(post_code)')
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      final rows = (data as List).cast<Map<String, dynamic>>();
      _items
        ..clear()
        ..addAll(rows.map(CustomerRequirement.fromRow));
      _loadedRemote = true;
      notifyListeners();
    } catch (e) {
      debugPrint('CustomerRequirementRepository.refreshFromServer: $e');
    }
  }

  Future<RequirementSubmitOutcome> submit(CustomerRequirement draft) async {
    var saved = false;
    CustomerRequirement item = draft;

    if (Env.isConfigured &&
        SupabaseService.isReady &&
        AuthService.instance.isRealSupabaseSession) {
      try {
        final uid = SupabaseService.client!.auth.currentUser?.id;
        final row = await SupabaseService.client!
            .from('customer_requirements')
            .insert(draft.toInsertJson(uid))
            .select('*, demand_posts(post_code)')
            .single();
        saved = true;
        item = CustomerRequirement.fromRow(Map<String, dynamic>.from(row));
      } catch (e) {
        debugPrint('CustomerRequirementRepository.submit: $e');
        saved = false;
      }
    }

    if (!saved) {
      item = draft.copyWith(savedToDatabase: false);
    }

    _items.insert(0, item);
    notifyListeners();
    return RequirementSubmitOutcome(requirement: item, savedToDatabase: saved);
  }
}
