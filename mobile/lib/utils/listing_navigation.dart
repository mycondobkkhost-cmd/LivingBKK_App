import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/bangkok_projects.dart';
import '../data/bangkok_project_meta.dart';
import '../data/property_catalog.dart';
import '../utils/localized_content.dart';
import '../l10n/app_strings.dart';
import '../models/browse_list_route_extra.dart';
import '../models/home_section_route_extra.dart';
import '../models/listing_public.dart';
import '../models/listing_route_extra.dart';
import '../services/home_sections_builder.dart';

/// นำทางไปหน้ารายการทรัพย์ / โครงการ จากทุกจุดในแอp
class ListingNavigation {
  static void openBrowse(BuildContext context, BrowseListRouteExtra extra) {
    context.push('/browse', extra: extra);
  }

  static void openCategory(
    BuildContext context, {
    required String slug,
    required bool isAgent,
  }) {
    final s = AppStrings.of(context);
    final cat = PropertyCatalog.bySlug(slug);
    openBrowse(
      context,
      BrowseListRouteExtra(
        title: cat?.label(s.isEnglish) ?? slug,
        mode: BrowseListMode.category,
        categorySlug: slug,
        isAgent: isAgent,
      ),
    );
  }

  static void openProject(
    BuildContext context, {
    required String projectName,
    String? projectSlug,
    required bool isAgent,
  }) {
    final slug = projectSlug ?? BangkokProjectMeta.findProject(projectName)?.slug;
    if (slug != null && slug.isNotEmpty) {
      context.push('/project/$slug', extra: isAgent);
      return;
    }
    openProjectUnits(
      context,
      projectName: projectName,
      projectSlug: projectSlug,
      isAgent: isAgent,
    );
  }

  /// หน้ารายการห้องทั้งหมดในโครงการ (ไม่ผ่านหน้าโครงการ)
  static void openProjectUnits(
    BuildContext context, {
    required String projectName,
    String? projectSlug,
    required bool isAgent,
  }) {
    final catalog = projectSlug != null ? BangkokProjects.bySlug(projectSlug) : null;
    final meta = catalog ?? BangkokProjectMeta.findProject(projectName);
    final title = meta?.displayBilingual ?? projectName;
    openBrowse(
      context,
      BrowseListRouteExtra(
        title: title,
        mode: BrowseListMode.project,
        projectName: meta?.nameTh ?? projectName,
        projectSlug: projectSlug ?? meta?.slug,
        isAgent: isAgent,
      ),
    );
  }

  static void openArea(
    BuildContext context, {
    required String areaSlug,
    required String title,
    required bool isAgent,
  }) {
    openBrowse(
      context,
      BrowseListRouteExtra(
        title: title,
        mode: BrowseListMode.area,
        geoZoneSlugs: [areaSlug],
        isAgent: isAgent,
      ),
    );
  }

  static void openTransit(
    BuildContext context, {
    required String title,
    required List<String> geoZoneSlugs,
    required bool isAgent,
  }) {
    openBrowse(
      context,
      BrowseListRouteExtra(
        title: title,
        mode: BrowseListMode.transit,
        geoZoneSlugs: geoZoneSlugs,
        isAgent: isAgent,
      ),
    );
  }

  static void openTag(
    BuildContext context, {
    required String tagLabel,
    required List<String> geoZoneSlugs,
    required bool isAgent,
  }) {
    openBrowse(
      context,
      BrowseListRouteExtra(
        title: tagLabel,
        mode: BrowseListMode.tag,
        tagLabel: tagLabel,
        geoZoneSlugs: geoZoneSlugs,
        isAgent: isAgent,
      ),
    );
  }

  static void openSection(
    BuildContext context, {
    required HomeFeedSection section,
    required bool isAgent,
  }) {
    final s = AppStrings.of(context);
    openBrowse(
      context,
      BrowseListRouteExtra(
        title: s.isEnglish ? section.titleEn : section.titleTh,
        mode: BrowseListMode.section,
        presetItems: section.items,
        isAgent: isAgent,
      ),
    );
  }

  /// รองรับ route เก่า `/home/section`
  static void openLegacySection(
    BuildContext context, {
    required HomeSectionRouteExtra extra,
  }) {
    openBrowse(
      context,
      BrowseListRouteExtra(
        title: extra.title,
        mode: BrowseListMode.section,
        presetItems: extra.items,
        isAgent: extra.isAgent,
      ),
    );
  }

  static void openListing(
    BuildContext context, {
    required ListingPublic listing,
    required bool isAgent,
  }) {
    context.push(
      '/listing/${listing.id}',
      extra: ListingRouteExtra(listing: listing, isAgent: isAgent),
    );
  }
}
