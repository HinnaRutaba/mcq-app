import 'package:flutter/material.dart';

import '../../../../core/utils/dialer.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../../../models/api_refs.dart';
import '../../../../widgets/widgets.dart';

class HolderActions extends StatelessWidget {
  const HolderActions({
    super.key,
    this.mobileNo,
    this.point,
    this.address,
    this.dialer = const Dialer(),
    this.maps = const MapLauncher(),
    this.compact = false,
  });

  final bool compact;

  static double heightFor({required bool compact}) => compact ? 30 : 36;

  final String? mobileNo;

  /// Where the shop stands, and what to search a map for without a fix.
  final GeoPoint? point;
  final String? address;

  /// Injected so a test can press these: the platform has no dialler and no
  /// map app.
  final Dialer dialer;
  final MapLauncher maps;

  bool get isEmpty => mobileNo == null && point == null && address == null;

  @override
  Widget build(BuildContext context) {
    final String? number = mobileNo;

    return SizedBox(
      height: heightFor(compact: compact),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          if (number != null) ...<Widget>[
            AppHeroAction(
              icon: Icons.call_rounded,
              label: 'Call',
              compact: compact,
              onTap: () => dialer.call(number),
            ),
            const SizedBox(width: 12),
            AppHeroAction(
              icon: Icons.sms_outlined,
              label: 'Message',
              compact: compact,
              onTap: () => dialer.message(number),
            ),
            const SizedBox(width: 12),
          ],
          if (point != null || address != null)
            AppHeroAction(
              icon: Icons.directions_outlined,
              label: 'Directions',
              compact: compact,
              onTap: () => maps.open(point: point, address: address),
            ),
        ],
      ),
    );
  }
}
