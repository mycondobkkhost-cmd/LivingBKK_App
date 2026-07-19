import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/demand_post.dart';
import '../../services/demand_repository.dart';
import '../../widgets/app_mobile_scaffold.dart';
import '../../widgets/not_found_scaffold.dart';

/// โหลดประกาศบอร์ดเมื่อเปิดจากลิงก์ตรง, notification หรือหลัง login
class DemandPostRoutePage extends StatefulWidget {
  const DemandPostRoutePage({
    super.key,
    required this.postId,
    required this.builder,
  });

  final String postId;
  final Widget Function(DemandPost post) builder;

  @override
  State<DemandPostRoutePage> createState() => _DemandPostRoutePageState();
}

class _DemandPostRoutePageState extends State<DemandPostRoutePage> {
  final _repo = DemandRepository();
  late Future<DemandPost?> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchById(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DemandPost?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return AppMobileScaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final post = snapshot.data;
        if (post == null) {
          return NotFoundScaffold(message: (s) => s.notFoundPost);
        }
        return widget.builder(post);
      },
    );
  }
}
