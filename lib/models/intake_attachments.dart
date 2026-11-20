import 'agreement_case.dart';

/// Whose papers a group of attachments are.
enum IntakeAttachmentOwner { applicant, witness, supporting, agreement }

/// One person's (or the agreement's own) files on a case.
class IntakeAttachmentGroup {
  const IntakeAttachmentGroup({
    required this.owner,
    required this.title,
    this.subtitle,
    this.note,
    this.docs = const <IntakeDocument>[],
  });

  final IntakeAttachmentOwner owner;
  final String title;

  /// The person's name, when the case has one.
  final String? subtitle;
  final String? note;
  final List<IntakeDocument> docs;
}
