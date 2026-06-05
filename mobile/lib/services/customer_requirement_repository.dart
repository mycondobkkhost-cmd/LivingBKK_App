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

  List<CustomerRequirement> get items => List.unmodifiable(_items);

  List<CustomerRequirement> listForDisplay() {
    if (_items.isEmpty) return [CustomerRequirement.demo()];
    return List.unmodifiable(_items);
  }

  bool get isShowingDemo => _items.isEmpty;

  Future<RequirementSubmitOutcome> submit(CustomerRequirement draft) async {
    var saved = false;
    if (Env.isConfigured &&
        SupabaseService.isReady &&
        AuthService.instance.isRealSupabaseSession) {
      try {
        final uid = SupabaseService.client!.auth.currentUser?.id;
        await SupabaseService.client!
            .from('customer_requirements')
            .insert(draft.toInsertJson(uid));
        saved = true;
      } catch (_) {
        saved = false;
      }
    }

    final item = draft.copyWith(savedToDatabase: saved);
    _items.insert(0, item);
    notifyListeners();
    return RequirementSubmitOutcome(requirement: item, savedToDatabase: saved);
  }
}
