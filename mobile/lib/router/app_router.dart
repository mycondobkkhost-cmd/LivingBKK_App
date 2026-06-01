import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/board/demand_post_detail_page.dart';
import '../features/board/submit_offer_page.dart';
import '../features/listing/create_listing_page.dart';
import '../features/listing/listing_detail_page.dart';
import '../models/demand_post.dart';
import '../models/listing_route_extra.dart';
import '../shell/main_shell.dart';
import '../state/user_role_controller.dart';

class AppRouter {
  static final _rootKey = GlobalKey<NavigatorState>();

  static GoRouter create({required UserRoleController roleController}) {
    return GoRouter(
      navigatorKey: _rootKey,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MainShell(roleController: roleController),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/listing/create',
          builder: (context, state) => const CreateListingPage(),
        ),
        GoRoute(
          path: '/listing/:id',
          builder: (context, state) {
            final extra = state.extra;
            ListingRouteExtra? bundle;
            if (extra is ListingRouteExtra) bundle = extra;
            if (bundle == null) {
              return const Scaffold(body: Center(child: Text('ไม่พบทรัพย์')));
            }
            return ListingDetailPage(
              listing: bundle.listing,
              isAgent: bundle.isAgent,
            );
          },
        ),
        GoRoute(
          path: '/board/:id',
          builder: (context, state) {
            final post = state.extra as DemandPost?;
            if (post == null) {
              return const Scaffold(body: Center(child: Text('ไม่พบประกาศ')));
            }
            return DemandPostDetailPage(post: post);
          },
        ),
        GoRoute(
          path: '/board/:id/offer',
          builder: (context, state) {
            final post = state.extra as DemandPost?;
            if (post == null) {
              return const Scaffold(body: Center(child: Text('ไม่พบประกาศ')));
            }
            return SubmitOfferPage(post: post);
          },
        ),
      ],
    );
  }
}
