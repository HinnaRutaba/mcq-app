import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../models/mobile_access.dart';
import '../../widgets/widgets.dart';
import 'widgets/auth_scaffold.dart';

/// Which workspace to open, for an officer the server gave more than one —
/// and the dead end, said plainly, for one it gave none.
class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController auth = Get.find<AuthController>();

    return Obx(() {
      final List<MobileWorkspace> workspaces =
          auth.access.value?.workspaces ?? const <MobileWorkspace>[];

      if (workspaces.isEmpty) {
        return AuthScaffold(
          title: 'Nothing here for you',
          message: 'Nothing on this app for your account.',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const AppAlert(
                tone: AppTone.info,
                icon: Icons.info_outline_rounded,
                message:
                    'Your account has no work on the phone. If that is wrong, '
                    'ask MCQ IT to check your role.',
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Log out',
                variant: AppButtonVariant.outline,
                onPressed: () => AppSignOutDialog.confirmAndSignOut(context),
              ),
            ],
          ),
        );
      }

      return AuthScaffold(
        title: 'Choose a workspace',
        message:
            'Your account works in more than one. You can switch later '
            'from More.',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final MobileWorkspace workspace in workspaces) ...<Widget>[
              MoreMenuTile(
                icon: _icon(workspace),
                title: workspace.label,
                subtitle: _line(workspace),
                onTap: () => context.go(AppRoutes.homeOf(workspace)),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      );
    });
  }

  static IconData _icon(MobileWorkspace workspace) => switch (workspace) {
    MobileWorkspace.field => Icons.storefront_outlined,
    MobileWorkspace.agreements => Icons.assignment_turned_in_outlined,
  };

  static String _line(MobileWorkspace workspace) => switch (workspace) {
    MobileWorkspace.field => 'Defaulters, fines, seals and the round.',
    MobileWorkspace.agreements => 'Counter agreement cases waiting for review.',
  };
}
