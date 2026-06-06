import 'package:flutter_test/flutter_test.dart';
import 'package:livingbkk/l10n/app_strings.dart';
import 'package:livingbkk/models/chat_message.dart';

void main() {
  test('ChatMessageLink serializes form action kinds', () {
    final s = AppStrings(false);
    final req = ChatMessageLink.requirementForm(s);
    final view = ChatMessageLink.viewingForm(s);

    expect(req.toJson()['kind'], 'requirement_form');
    expect(view.toJson()['kind'], 'viewing_form');
    expect(req.isFormAction, isTrue);
    expect(req.isListingAction, isFalse);
  });

  test('ChatMessageLink.fromJson parses form action kinds', () {
    final req = ChatMessageLink.fromJson({
      'label': 'Fill form',
      'kind': 'requirement_form',
    });
    final view = ChatMessageLink.fromJson({
      'label': 'Book viewing',
      'kind': 'viewing_form',
    });

    expect(req.kind, ChatMessageLinkKind.requirementForm);
    expect(view.kind, ChatMessageLinkKind.viewingForm);
  });
}
