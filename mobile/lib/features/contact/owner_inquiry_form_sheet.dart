import 'package:flutter/material.dart';

import '../../models/chat_room.dart';
import '../intake/standard_intake_flow_sheet.dart';

Future<bool?> showOwnerInquiryFormSheet(
  BuildContext context, {
  required ChatRoom room,
  String inquiryType = 'general',
  String? prefilledQuestion,
}) =>
    showStandardOwnerInquiryIntake(
      context,
      room: room,
      inquiryType: inquiryType,
      prefilledQuestion: prefilledQuestion,
    );
