import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/field/beat.dart';

/// How each beat queue is drawn and where it goes.
///
/// Two decisions live here:
///
/// * **The raw `key` is never rendered.** `follow_ups_due` is a database
///   word. "Promises to chase, due today or overdue" is what an officer
///   reads, and MCQ wrote those labels themselves.
/// * **A zero queue is good news and must look like it.** A tile that
///   stays red at zero teaches the officer that the colours mean nothing,
///   and once he has learnt that, the red one that matters is just another
///   red tile.
class BeatQueueMeta {
  const BeatQueueMeta({
    required this.icon,
    required this.labelKey,
    required this.subLabelKey,
    required this.clearKey,
  });

  final IconData icon;
  final String labelKey;
  final String subLabelKey;

  /// What this tile says when its count is zero.
  final String clearKey;

  String get label => t(labelKey);
  String get subLabel => t(subLabelKey);
  String get clearLabel => t(clearKey);

  // The six MCQ named, in the order they appear on the beat.
  static const String keyDefaulters = 'defaulters';
  static const String keyFollowUpsDue = 'follow_ups_due';
  static const String keyAwaitingUnseal = 'awaiting_unseal';
  static const String keySealedShops = 'sealed_shops';
  static const String keyOpenCases = 'open_cases';
  static const String keyAssignedToMe = 'assigned_to_me';

  static const Map<String, BeatQueueMeta> _known = {
    keyDefaulters: BeatQueueMeta(
      icon: Icons.storefront_rounded,
      labelKey: 'queue.defaulters',
      subLabelKey: 'queue.defaultersSub',
      clearKey: 'queue.defaultersClear',
    ),
    keyFollowUpsDue: BeatQueueMeta(
      icon: Icons.handshake_rounded,
      labelKey: 'queue.followUps',
      subLabelKey: 'queue.followUpsSub',
      clearKey: 'queue.followUpsClear',
    ),
    keyAwaitingUnseal: BeatQueueMeta(
      icon: Icons.lock_open_rounded,
      labelKey: 'queue.awaitingUnseal',
      subLabelKey: 'queue.awaitingUnsealSub',
      clearKey: 'queue.awaitingUnsealClear',
    ),
    keySealedShops: BeatQueueMeta(
      icon: Icons.lock_rounded,
      labelKey: 'queue.sealedShops',
      subLabelKey: 'queue.sealedShopsSub',
      clearKey: 'queue.sealedShopsClear',
    ),
    keyOpenCases: BeatQueueMeta(
      icon: Icons.folder_open_rounded,
      labelKey: 'queue.openCases',
      subLabelKey: 'queue.openCasesSub',
      clearKey: 'queue.openCasesClear',
    ),
    keyAssignedToMe: BeatQueueMeta(
      icon: Icons.assignment_ind_rounded,
      labelKey: 'queue.assignedToMe',
      subLabelKey: 'queue.assignedToMeSub',
      clearKey: 'queue.assignedToMeClear',
    ),
  };

  /// A queue MCQ adds later still draws — with a neutral icon and the
  /// server's own key humanised — rather than crashing or rendering
  /// `follow_ups_due` at an officer.
  static BeatQueueMeta of(String key) =>
      _known[key] ??
      const BeatQueueMeta(
        icon: Icons.list_alt_rounded,
        labelKey: 'queue.unknown',
        subLabelKey: 'queue.unknownSub',
        clearKey: 'queue.unknownClear',
      );

  static bool isKnown(String key) => _known.containsKey(key);

  /// A zero tile is drawn in the success tone whatever the server said —
  /// the tone describes a queue with work in it.
  static AppTone toneFor(BeatQueue queue) =>
      queue.isClear ? AppTone.success : AppToneColors.fromApi(queue.tone);
}
