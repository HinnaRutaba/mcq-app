/// A shop/unit a tenant occupies.
///
/// Current seal state lives on [SealRecord] (see `seal_record.dart`), not
/// here — a property has no seal fields of its own, so "is this sealed"
/// always comes from the seal repository's latest record for it.
class Property {
  const Property({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.area,
    required this.tenantId,
    required this.tenantName,
    required this.tenantPhone,
  });

  final String id;
  final String name;
  final String category;
  final String address;
  final String area;
  final String tenantId;
  final String tenantName;
  final String tenantPhone;
}
