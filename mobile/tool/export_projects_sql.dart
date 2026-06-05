// ignore_for_file: avoid_print
import '../lib/data/bangkok_project_meta.dart';
import '../lib/data/bangkok_projects.dart';

String geoZoneSlug(BangkokProject p) {
  final bts = (p.bts ?? '').toLowerCase();
  final d = p.district;
  if (bts.contains('อโศก') || bts.contains('asok')) return 'asok';
  if (bts.contains('ทองหล่อ') || bts.contains('เอกมัย')) return 'thonglor';
  if (d == 'บางนา' || d == 'สวนหลวง' || bts.contains('บางนา') || bts.contains('อ่อนนุช')) {
    return 'samut-prakan';
  }
  if (bts.contains('สุขุมวิท') || bts.contains('บางจาก') || bts.contains('พร้อมพงษ์') || bts.contains('นานา')) {
    return 'sukhumvit';
  }
  return 'bangkok-all';
}

String sqlEscape(String s) => s.replaceAll("'", "''");

void main() {
  for (final p in BangkokProjects.bootstrap) {
    final meta = BangkokProjectMeta.forProject(p.nameTh);
    final year = p.yearBuilt ?? meta.yearBuilt;
    final facilities = p.facilities.isNotEmpty ? p.facilities : meta.facilities;
    final aliases = p.aliases.map((a) => "'${sqlEscape(a)}'").join(', ');
    final fac = facilities.map((f) => "'${sqlEscape(f)}'").join(', ');
    final bts = p.bts == null ? 'NULL' : "'${sqlEscape(p.bts!)}'";
    final gz = geoZoneSlug(p);
    print("""
INSERT INTO public.property_projects (
  slug, name_th, name_en, district, bts_station, property_type,
  lat, lng, location, aliases, year_built, facilities, geo_zone_id
)
SELECT
  '${sqlEscape(p.slug)}',
  '${sqlEscape(p.nameTh)}',
  '${sqlEscape(p.nameEn)}',
  '${sqlEscape(p.district)}',
  $bts,
  '${sqlEscape(p.propertyType)}',
  ${p.lat},
  ${p.lng},
  ST_SetSRID(ST_MakePoint(${p.lng}, ${p.lat}), 4326)::geography,
  ARRAY[$aliases],
  $year,
  ARRAY[$fac],
  gz.id
FROM public.geo_zones gz
WHERE gz.slug = '$gz'
ON CONFLICT (slug) DO UPDATE SET
  name_th = EXCLUDED.name_th,
  name_en = EXCLUDED.name_en,
  district = EXCLUDED.district,
  bts_station = EXCLUDED.bts_station,
  property_type = EXCLUDED.property_type,
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  location = EXCLUDED.location,
  aliases = EXCLUDED.aliases,
  year_built = EXCLUDED.year_built,
  facilities = EXCLUDED.facilities,
  geo_zone_id = EXCLUDED.geo_zone_id,
  updated_at = now();
""");
  }
}
