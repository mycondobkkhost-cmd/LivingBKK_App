import 'package:flutter/foundation.dart';

class UserRoleController extends ChangeNotifier {
  UserRoleController([this._role = 'seeker']);

  String _role;
  String get role => _role;
  bool get isAgent => _role == 'agent';

  void setRole(String value) {
    if (_role == value) return;
    _role = value;
    notifyListeners();
  }
}
