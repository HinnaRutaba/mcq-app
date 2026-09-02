import 'package:flutter/material.dart';

import '../../../widgets/widgets.dart';
import '../shared/widgets/back_to_home_button.dart';

class DefaultersScreen extends StatelessWidget {
  const DefaultersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          AppHeroHeader(title: 'Defaulters', leading: BackToHomeButton()),
          Expanded(
            child: AppEmptyState(
              icon: Icons.storefront_outlined,
              title: 'Not wired up yet',
              message:
                  'Everyone behind on rent comes from the field defaulters '
                  'endpoint, worst first.',
            ),
          ),
        ],
      ),
    );
  }
}
