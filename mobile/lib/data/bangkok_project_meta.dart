import 'bangkok_projects.dart';
import '../utils/localized_content.dart';

class ProjectMeta {
  const ProjectMeta({
    required this.yearBuilt,
    required this.facilities,
  });

  final int yearBuilt;
  final List<String> facilities;

  static const fallbackFacilities = [
    'สระว่ายน้ำ',
    'ฟิตเนส',
    'ที่จอดรถ',
    'รปภ. 24 ชม.',
    'Lobby',
  ];
}

/// ข้อมูลโครงการเสริม (ปีสร้าง / ส่วนกลาง)
class BangkokProjectMeta {
  static const _bySlug = <String, ProjectMeta>{
    'rhythm-sukhumvit-36': ProjectMeta(
      yearBuilt: 2016,
      facilities: ['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ', 'Sky Lounge', 'รปภ. 24 ชม.'],
    ),
    'true-thonglor': ProjectMeta(
      yearBuilt: 2014,
      facilities: ['สระว่ายน้ำ', 'ฟิตเนส', 'Co-working', 'ที่จอดรถ'],
    ),
    'ashton-asoke': ProjectMeta(
      yearBuilt: 2018,
      facilities: ['สระว่ายน้ำ', 'ฟิตเนส', 'Sky garden', 'ที่จอดรถ', 'Lobby'],
    ),
    'the-line-sukhumvit-101': ProjectMeta(
      yearBuilt: 2017,
      facilities: ['สระว่ายน้ำ', 'ฟิตเนส', 'Co-working', 'รปภ. 24 ชม.'],
    ),
    'noble-remix-thonglor': ProjectMeta(
      yearBuilt: 2013,
      facilities: ['สระว่ายน้ำ', 'ฟิตเนส', 'ที่จอดรถ'],
    ),
  };

  static BangkokProject? findProject(String? name) {
    if (name == null || name.isEmpty) return null;
    final q = name.toLowerCase();
    for (final p in BangkokProjects.all) {
      if (p.nameTh == name ||
          p.displayBilingual == name ||
          name.contains(p.nameTh) ||
          p.nameEn.toLowerCase() == q ||
          p.aliases.any((a) => q.contains(a.toLowerCase()))) {
        return p;
      }
    }
    return null;
  }

  static ProjectMeta forProject(String? projectName) {
    final project = findProject(projectName);
    if (project == null) {
      return const ProjectMeta(
        yearBuilt: 2015,
        facilities: ProjectMeta.fallbackFacilities,
      );
    }
    if (project.yearBuilt != null && project.facilities.isNotEmpty) {
      return ProjectMeta(
        yearBuilt: project.yearBuilt!,
        facilities: project.facilities,
      );
    }
    return _bySlug[project.slug] ??
        ProjectMeta(
          yearBuilt: project.yearBuilt ??
              2012 + project.slug.hashCode.abs() % 10,
          facilities: project.facilities.isNotEmpty
              ? project.facilities
              : ProjectMeta.fallbackFacilities,
        );
  }
}
