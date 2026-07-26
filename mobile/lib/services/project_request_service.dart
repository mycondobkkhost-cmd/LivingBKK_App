import '../config/env.dart';
import '../services/in_app_notification_hub.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class ProjectRequestResult {
  const ProjectRequestResult({
    required this.success,
    this.duplicate = false,
    this.projectName = '',
    this.error,
  });

  final bool success;
  final bool duplicate;
  final String projectName;
  final String? error;
}

/// ส่งคำขอเพิ่มโครงการที่ยังไม่มีในทะเบียน — ลูกค้าเห็นแค่แจ้งเตือนเงียบๆ
class ProjectRequestService {
  ProjectRequestService._();
  static final ProjectRequestService instance = ProjectRequestService._();

  Future<ProjectRequestResult> submit({
    required String projectName,
    String? sourceQuery,
    String source = 'search_bar',
    void Function(String message)? onNotify,
  }) async {
    final name = projectName.trim();
    if (name.length < 2) {
      return const ProjectRequestResult(
        success: false,
        error: 'project_name too short',
      );
    }

    if (!Env.isConfigured || !SupabaseService.isReady) {
      onNotify?.call('บันทึกคำขอชั่วคราว — เชื่อมระบบแล้วลองใหม่');
      return ProjectRequestResult(success: false, projectName: name, error: 'offline');
    }

    if (!AuthService.instance.isSignedIn) {
      return const ProjectRequestResult(
        success: false,
        error: 'sign_in_required',
      );
    }

    try {
      final res = await SupabaseService.client!.functions.invoke(
        'submit-project-request',
        body: {
          'project_name': name,
          if (sourceQuery != null && sourceQuery.trim().isNotEmpty)
            'source_query': sourceQuery.trim(),
          'source': source,
        },
      );

      final data = res.data as Map<String, dynamic>?;
      if (res.status != 200 || data == null || data['error'] != null) {
        return ProjectRequestResult(
          success: false,
          projectName: name,
          error: data?['error']?.toString() ?? 'submit failed',
        );
      }

      final duplicate = data['duplicate'] == true;
      return ProjectRequestResult(
        success: true,
        duplicate: duplicate,
        projectName: data['project_name']?.toString() ?? name,
      );
    } catch (e) {
      return ProjectRequestResult(
        success: false,
        projectName: name,
        error: e.toString(),
      );
    }
  }

  /// ส่งคำขอ + แจ้งเตือน in-app (ไม่เปิดแชท)
  Future<bool> submitAndNotify({
    required String projectName,
    required String submittedMessage,
    required String duplicateMessage,
    String? sourceQuery,
    String source = 'search_bar',
  }) async {
    final result = await submit(
      projectName: projectName,
      sourceQuery: sourceQuery,
      source: source,
    );
    if (!result.success) return false;

    final msg = result.duplicate ? duplicateMessage : submittedMessage;
    InAppNotificationHub.instance.showMessage(msg);
    return true;
  }
}
