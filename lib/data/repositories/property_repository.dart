import '../../models/property.dart';
import '../mock/mock_seed.dart';

/// Read access to properties/shops. See [ChalaanRepository] for the swap
/// pattern used across this app's data layer.
abstract class PropertyRepository {
  List<Property> getAll();
  Property getById(String id);
  List<Property> search(String query);
}

class MockPropertyRepository implements PropertyRepository {
  @override
  List<Property> getAll() => List.unmodifiable(MockSeed.properties);

  @override
  Property getById(String id) => MockSeed.propertyById(id);

  @override
  List<Property> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return MockSeed.properties.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.tenantName.toLowerCase().contains(q) ||
          p.address.toLowerCase().contains(q) ||
          p.area.toLowerCase().contains(q);
    }).toList();
  }
}
