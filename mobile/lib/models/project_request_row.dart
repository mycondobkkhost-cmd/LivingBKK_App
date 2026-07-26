/// คำขอเพิ่มโครงการจากลูกค้า
class ProjectRequestRow {
  const ProjectRequestRow({
    required this.id,
    required this.projectName,
    required this.source,
    this.sourceQuery,
    required this.status,
    this.adminNote,
    this.linkedProjectId,
    required this.createdAt,
    this.userId,
  });

  factory ProjectRequestRow.fromJson(Map<String, dynamic> json) {
    return ProjectRequestRow(
      id: json['id'] as String,
      projectName: json['project_name'] as String? ?? '',
      source: json['source'] as String? ?? 'search_bar',
      sourceQuery: json['source_query'] as String?,
      status: json['status'] as String? ?? 'pending',
      adminNote: json['admin_note'] as String?,
      linkedProjectId: json['linked_project_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String?,
    );
  }

  final String id;
  final String projectName;
  final String source;
  final String? sourceQuery;
  final String status;
  final String? adminNote;
  final String? linkedProjectId;
  final DateTime createdAt;
  final String? userId;

  bool get isPending => status == 'pending' || status == 'reviewing';
}
