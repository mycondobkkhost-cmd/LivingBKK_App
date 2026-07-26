import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class RentalPickedDocument {
  const RentalPickedDocument({
    required this.fileName,
    required this.bytes,
  });

  final String fileName;
  final Uint8List bytes;
}

/// เลือกไฟล์เอกสาร (PDF / รูป) สำหรับกลุ่มเช่า
Future<RentalPickedDocument?> pickRentalDocument() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) return null;
  final name = (file.name.trim().isNotEmpty ? file.name : 'document.pdf');
  return RentalPickedDocument(fileName: name, bytes: bytes);
}
