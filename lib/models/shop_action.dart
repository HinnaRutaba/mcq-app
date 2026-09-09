import 'enforcement_definitions.dart';

/// What an officer can do about a shop, in the order the app offers it.
///
/// The app's own list rather than the register's: `enforcement/definitions`
/// publishes everything a case timeline can carry — including the entries the
/// server writes itself — in the server's wording. These are the steps an
/// officer standing at a shopfront chooses between, worded as the choice being
/// made. Each carries the register [code] that goes with it, so what is
/// eventually posted is still the register's row and not this list.
enum ShopAction {
  visit(
    'Record a visit',
    'You called at the shop today.',
    code: 'site_visit',
  ),
  warn(
    'Give a warning',
    'Told them in person, on the record.',
    code: 'verbal_warning',
  ),
  promise(
    'Take promise to pay',
    'They name a day they will pay by.',
    code: 'payment_promised',
  ),
  remind(
    'Set reminder to visit',
    'You pick a day to come back.',
    code: 'reminder_visit_set',
  ),

  /// Raised through the fines endpoint, which bills it as well — which is why
  /// `EnforcementActionRequest` will not post one.
  fine(
    'Impose a fine',
    'A penalty bill, apart from the rent.',
    code: 'fine_imposed',
  ),

  /// `POST enforcement/cases`. Its own endpoint, so no action type stands
  /// behind it.
  openCase('Create new case', 'Opens a file to work the shop through.'),

  /// Sealing and releasing both hang off a case, and the server writes the
  /// timeline entry for them itself.
  seal(
    'Seal the shop',
    'Shuts it until the arrears are cleared.',
    code: 'seal',
    needsCase: true,
  ),
  unseal(
    'Unseal the shop',
    'Lets them trade again.',
    code: 'unseal',
    needsCase: true,
  );

  const ShopAction(
    this.label,
    this.description, {
    this.code,
    this.needsCase = false,
  });

  /// What the row says.
  final String label;

  /// One line under it, saying what the step actually does — these are the
  /// choices an officer makes in front of a shopkeeper, and "Take promise to
  /// pay" on its own is a phrase, not an instruction.
  final String description;

  /// The `ActionTypeDefinition.code` this step is recorded under, where it is
  /// recorded as an action at all.
  final String? code;

  /// Whether a case has to exist first — a shop with none gets one opened as
  /// part of the step.
  final bool needsCase;

  /// The steps to offer for one shop. [seal] and [unseal] are the same row in
  /// two states, so only ever one of them is on the sheet.
  static List<ShopAction> forShop({required bool sealed}) {
    final ShopAction hidden = sealed ? seal : unseal;
    return values.where((ShopAction action) => action != hidden).toList();
  }
}

/// One row off the Take Action sheet: the step the officer picked, and the
/// register row that goes with it.
class ShopActionChoice {
  const ShopActionChoice(this.action, {this.definition});

  final ShopAction action;

  /// The register's row for [ShopAction.code] — its wording, the id to post
  /// and the fields a form has to ask for. Null on [ShopAction.openCase],
  /// which is not an action type at all.
  final ActionTypeDefinition? definition;
}
