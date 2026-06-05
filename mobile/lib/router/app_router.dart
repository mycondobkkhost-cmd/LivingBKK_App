import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/demand_board_menu_config.dart';
import '../config/post_listing_menu_config.dart';
import '../features/admin/admin_import_tab.dart';
import '../features/admin/admin_console_page.dart';
import '../features/admin/admin_faq_page.dart';
import '../features/admin/admin_chat_detail_page.dart';
import '../features/admin/admin_home_page.dart';
import '../features/admin/admin_lead_detail_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/signup_page.dart';
import '../features/legal/legal_document_page.dart';
import '../config/legal_config.dart';
import '../features/board/demand_post_detail_page.dart';
import '../features/board/saved_demand_board_page.dart';
import '../features/board/submit_offer_page.dart';
import '../features/listing/create_listing_page.dart';
import '../features/listing/listing_detail_route_page.dart';
import '../features/listing/listing_detail_page.dart';
import '../features/listing/my_listings_page.dart';
import '../features/requirements/create_requirement_page.dart';
import '../features/requirements/my_requirements_page.dart';
import '../features/work/lead_inbox_detail_page.dart';
import '../models/demand_post.dart';
import '../models/listing_public.dart';
import '../models/listing_route_extra.dart';
import '../features/search/browse_list_page.dart';
import '../features/search/project_detail_page.dart';
import '../features/search/saved_listings_page.dart';
import '../features/search/saved_searches_page.dart';
import '../features/work/agent_tools_page.dart';
import '../models/browse_list_route_extra.dart';
import '../models/home_section_route_extra.dart';
import '../shell/main_shell.dart';
import '../widgets/not_found_scaffold.dart';
import '../state/locale_controller.dart';
import '../state/search_session_controller.dart';
import '../state/session_gate.dart';
import '../state/theme_controller.dart';
import '../state/user_role_controller.dart';
import '../services/auth_service.dart';
import '../utils/admin_routing.dart';

class AppRouter {
  static final _rootKey = GlobalKey<NavigatorState>();

  static GoRouter create({
    required UserRoleController roleController,
    required SearchSessionController searchSession,
    required LocaleController localeController,
    required SessionGate sessionGate,
    required ThemeController themeController,
  }) {
    return GoRouter(
      navigatorKey: _rootKey,
      initialLocation: '/',
      refreshListenable: Listenable.merge([
        AuthService.instance,
        sessionGate,
        roleController,
      ]),
      redirect: (context, state) {
        if (!sessionGate.loaded) return '/login';

        final path = state.uri.path;
        final signedIn = AuthService.instance.isSignedIn;
        final isAdmin = roleController.isPlatformAdmin;

        if (signedIn) {
          if (path == '/login' || path == '/signup') {
            return isAdmin ? adminHomePath() : '/';
          }
          if (isAdmin &&
              path == '/' &&
              state.uri.queryParameters['preview'] != '1') {
            return adminHomePath();
          }
          if (isAdminRoute(path) && !isAdmin) {
            return '/';
          }
          return null;
        }

        if (isAdminRoute(path)) return '/login';
        if (path == '/login' || path == '/signup') return null;
        if (path.startsWith('/legal/')) return null;
        return '/login';
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginPage(
            roleController: roleController,
            localeController: localeController,
          ),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => SignUpPage(roleController: roleController),
        ),
        GoRoute(
          path: '/legal/:kind',
          builder: (context, state) {
            final type = LegalDocumentType.fromPath(state.pathParameters['kind']);
            if (type == null) {
              return NotFoundScaffold(message: (s) => s.notFoundSection);
            }
            return LegalDocumentPage(type: type);
          },
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => MainShell(
            roleController: roleController,
            searchSession: searchSession,
            localeController: localeController,
            themeController: themeController,
          ),
        ),
        GoRoute(
          path: '/browse',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is! BrowseListRouteExtra) {
              return NotFoundScaffold(message: (s) => s.notFoundSection);
            }
            return BrowseListPage(extra: extra);
          },
        ),
        GoRoute(
          path: '/project/:slug',
          builder: (context, state) {
            final slug = state.pathParameters['slug'];
            if (slug == null || slug.isEmpty) {
              return NotFoundScaffold(message: (s) => s.notFoundSection);
            }
            final isAgent = state.extra == true;
            return ProjectDetailPage(projectSlug: slug, isAgent: isAgent);
          },
        ),
        GoRoute(
          path: '/home/section',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is! HomeSectionRouteExtra) {
              return NotFoundScaffold(message: (s) => s.notFoundSection);
            }
            return BrowseListPage(
              extra: BrowseListRouteExtra(
                title: extra.title,
                mode: BrowseListMode.section,
                presetItems: extra.items,
                isAgent: extra.isAgent,
              ),
            );
          },
        ),
        GoRoute(
          path: PostListingMenuConfig.createRoute,
          builder: (context, state) =>
              CreateListingPage(roleController: roleController),
        ),
        GoRoute(
          path: PostListingMenuConfig.myListingsRoute,
          builder: (context, state) => const MyListingsPage(),
        ),
        GoRoute(
          path: DemandBoardMenuConfig.myRequirementsRoute,
          builder: (context, state) => const MyRequirementsPage(),
        ),
        GoRoute(
          path: DemandBoardMenuConfig.createRequirementRoute,
          builder: (context, state) => const CreateRequirementPage(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminHomePage(),
        ),
        GoRoute(
          path: '/admin/import',
          builder: (context, state) => const AdminImportPage(),
        ),
        GoRoute(
          path: '/admin/console',
          builder: (context, state) {
            final roomId = state.uri.queryParameters['room'];
            return AdminConsolePage(initialRoomId: roomId);
          },
        ),
        GoRoute(
          path: '/admin/lead/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            if (id == null || id.isEmpty) {
              return NotFoundScaffold(message: (s) => s.notFoundLead);
            }
            return AdminLeadDetailPage(leadId: id);
          },
        ),
        GoRoute(
          path: '/admin/faq',
          builder: (context, state) => const AdminFaqPage(),
        ),
        GoRoute(
          path: '/admin/chat/:roomId',
          builder: (context, state) {
            final roomId = state.pathParameters['roomId'];
            if (roomId == null || roomId.isEmpty) {
              return NotFoundScaffold(message: (s) => s.notFoundChat);
            }
            return AdminChatDetailPage(roomId: roomId);
          },
        ),
        GoRoute(
          path: '/saved-listings',
          builder: (context, state) => const SavedListingsPage(),
        ),
        GoRoute(
          path: '/saved-searches',
          builder: (context, state) {
            final session = state.extra as SearchSessionController? ??
                searchSession;
            return SavedSearchesPage(searchSession: session);
          },
        ),
        GoRoute(
          path: '/agent-tools',
          builder: (context, state) => const AgentToolsPage(),
        ),
        GoRoute(
          path: '/listing/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            if (id == null || id.isEmpty) {
              return NotFoundScaffold(message: (s) => s.notFoundListing);
            }
            final extra = state.extra;
            if (extra is ListingRouteExtra) {
              return ListingDetailPage(
                listing: extra.listing,
                isAgent: extra.isAgent,
              );
            }
            return ListingDetailRoutePage(listingId: id);
          },
        ),
        GoRoute(
          path: DemandBoardMenuConfig.savedBoardRoute,
          builder: (context, state) => const SavedDemandBoardPage(),
        ),
        GoRoute(
          path: '/board/:id',
          builder: (context, state) {
            final post = state.extra as DemandPost?;
            if (post == null) {
              return NotFoundScaffold(message: (s) => s.notFoundPost);
            }
            return DemandPostDetailPage(post: post);
          },
        ),
        GoRoute(
          path: '/work/lead/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            if (id == null || id.isEmpty) {
              return NotFoundScaffold(message: (s) => s.notFoundLead);
            }
            return LeadInboxDetailPage(leadId: id);
          },
        ),
        GoRoute(
          path: '/board/:id/offer',
          builder: (context, state) {
            final post = state.extra as DemandPost?;
            if (post == null) {
              return NotFoundScaffold(message: (s) => s.notFoundPost);
            }
            return SubmitOfferPage(post: post);
          },
        ),
      ],
    );
  }
}
