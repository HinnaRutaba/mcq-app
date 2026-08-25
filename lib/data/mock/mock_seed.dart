import '../../models/chalaan.dart';
import '../../models/payment_method.dart';
import '../../models/property.dart';
import '../../models/seal_record.dart';

/// Demo identities used until real auth/user data lands.
///
/// The login screen doesn't collect a real account yet, so whichever role
/// is picked signs in as this fixed demo user — enough to drive "my
/// chalaans" / "my jurisdiction" filtering in the mock repositories.
class DemoIdentity {
  DemoIdentity._();

  static const tenantId = 'T-001';
  static const tenantName = 'Ali Traders';
  static const magistrateId = 'M-001';
  static const magistrateName = 'Ahmed Raza';
  static const magistrateBadge = 'MG-204';
  static const magistrateJurisdiction = 'Saddar Town';
}

/// In-memory seed data for the mock repositories.
///
/// Everything here is placeholder content standing in for the real data
/// model — shapes will change, but only this file and the repositories in
/// `lib/data/repositories` need to know about it.
class MockSeed {
  MockSeed._();

  static final List<Property> properties = [
    const Property(
      id: 'P-001',
      name: 'Shop 4, Al-Karam Plaza',
      category: 'Retail Shop',
      address: 'Shop 4, Al-Karam Plaza, Main Bazaar',
      area: 'Saddar Town',
      tenantId: 'T-001',
      tenantName: 'Ali Traders',
      tenantPhone: '+92 300 1234567',
    ),
    const Property(
      id: 'P-002',
      name: 'Shop 12, Liberty Market',
      category: 'Retail Shop',
      address: 'Shop 12, Liberty Market',
      area: 'Gulberg Town',
      tenantId: 'T-002',
      tenantName: 'Bilal General Store',
      tenantPhone: '+92 301 2345678',
    ),
    const Property(
      id: 'P-003',
      name: 'Booth 3, Anarkali Bazaar',
      category: 'Stall',
      address: 'Booth 3, Anarkali Bazaar',
      area: 'Old City',
      tenantId: 'T-003',
      tenantName: 'Sana Fabrics',
      tenantPhone: '+92 302 3456789',
    ),
    const Property(
      id: 'P-004',
      name: 'Shop 7, Hall Road',
      category: 'Retail Shop',
      address: 'Shop 7, Hall Road',
      area: 'Saddar Town',
      tenantId: 'T-004',
      tenantName: 'Umar Electronics',
      tenantPhone: '+92 303 4567890',
    ),
    const Property(
      id: 'P-005',
      name: 'Shop 21, Ichhra Market',
      category: 'Retail Shop',
      address: 'Shop 21, Ichhra Market',
      area: 'Ichhra Town',
      tenantId: 'T-005',
      tenantName: 'Fatima Bakers',
      tenantPhone: '+92 304 5678901',
    ),
  ];

  static Property propertyById(String id) =>
      properties.firstWhere((p) => p.id == id);

  static List<Chalaan> buildChalaans() {
    final now = DateTime.now();
    DateTime daysAgo(int d) => now.subtract(Duration(days: d));
    DateTime daysFromNow(int d) => now.add(Duration(days: d));

    return [
      // --- Demo tenant (Ali Traders / P-001) -----------------------------
      Chalaan(
        id: 'CHL-101',
        type: ChalaanType.chalaan,
        status: ChalaanStatus.upcoming,
        tenantId: 'T-001',
        tenantName: 'Ali Traders',
        propertyId: 'P-001',
        propertyName: 'Shop 4, Al-Karam Plaza',
        propertyAddress: 'Shop 4, Al-Karam Plaza, Main Bazaar',
        amount: 12000,
        issueDate: daysAgo(10),
        dueDate: daysFromNow(5),
        description: 'Monthly rent — August',
      ),
      Chalaan(
        id: 'CHL-102',
        type: ChalaanType.chalaan,
        status: ChalaanStatus.overdue,
        tenantId: 'T-001',
        tenantName: 'Ali Traders',
        propertyId: 'P-001',
        propertyName: 'Shop 4, Al-Karam Plaza',
        propertyAddress: 'Shop 4, Al-Karam Plaza, Main Bazaar',
        amount: 8500,
        issueDate: daysAgo(40),
        dueDate: daysAgo(10),
        description: 'Utility surcharge — July',
      ),
      Chalaan(
        id: 'CHL-103',
        type: ChalaanType.chalaan,
        status: ChalaanStatus.paid,
        tenantId: 'T-001',
        tenantName: 'Ali Traders',
        propertyId: 'P-001',
        propertyName: 'Shop 4, Al-Karam Plaza',
        propertyAddress: 'Shop 4, Al-Karam Plaza, Main Bazaar',
        amount: 12000,
        issueDate: daysAgo(50),
        dueDate: daysAgo(20),
        paidDate: daysAgo(22),
        method: PaymentMethod.jazzcash,
        description: 'Monthly rent — July',
      ),
      Chalaan(
        id: 'CHL-104',
        type: ChalaanType.chalaan,
        status: ChalaanStatus.paid,
        tenantId: 'T-001',
        tenantName: 'Ali Traders',
        propertyId: 'P-001',
        propertyName: 'Shop 4, Al-Karam Plaza',
        propertyAddress: 'Shop 4, Al-Karam Plaza, Main Bazaar',
        amount: 12000,
        issueDate: daysAgo(80),
        dueDate: daysAgo(50),
        paidDate: daysAgo(53),
        method: PaymentMethod.bank,
        description: 'Monthly rent — June',
      ),
      Chalaan(
        id: 'CHL-105',
        type: ChalaanType.chalaan,
        status: ChalaanStatus.pendingVerification,
        tenantId: 'T-001',
        tenantName: 'Ali Traders',
        propertyId: 'P-001',
        propertyName: 'Shop 4, Al-Karam Plaza',
        propertyAddress: 'Shop 4, Al-Karam Plaza, Main Bazaar',
        amount: 4000,
        issueDate: daysAgo(15),
        dueDate: daysAgo(1),
        paidDate: daysAgo(1),
        method: PaymentMethod.manual,
        referenceNumber: 'TXN-88213374',
        description: 'Signage fee',
      ),

      // --- Other tenants (magistrate's collections) ----------------------
      Chalaan(
        id: 'CHL-111',
        type: ChalaanType.chalaan,
        status: ChalaanStatus.upcoming,
        tenantId: 'T-002',
        tenantName: 'Bilal General Store',
        propertyId: 'P-002',
        propertyName: 'Shop 12, Liberty Market',
        propertyAddress: 'Shop 12, Liberty Market',
        amount: 15000,
        issueDate: daysAgo(8),
        dueDate: daysFromNow(3),
        description: 'Monthly rent — August',
      ),
      Chalaan(
        id: 'CHL-112',
        type: ChalaanType.chalaan,
        status: ChalaanStatus.overdue,
        tenantId: 'T-003',
        tenantName: 'Sana Fabrics',
        propertyId: 'P-003',
        propertyName: 'Booth 3, Anarkali Bazaar',
        propertyAddress: 'Booth 3, Anarkali Bazaar',
        amount: 6000,
        issueDate: daysAgo(30),
        dueDate: daysAgo(6),
        description: 'Stall dues — July',
      ),
      Chalaan(
        id: 'CHL-113',
        type: ChalaanType.chalaan,
        status: ChalaanStatus.upcoming,
        tenantId: 'T-004',
        tenantName: 'Umar Electronics',
        propertyId: 'P-004',
        propertyName: 'Shop 7, Hall Road',
        propertyAddress: 'Shop 7, Hall Road',
        amount: 18000,
        issueDate: daysAgo(5),
        dueDate: daysFromNow(9),
        description: 'Monthly rent — August',
      ),
      Chalaan(
        id: 'CHL-114',
        type: ChalaanType.chalaan,
        status: ChalaanStatus.paid,
        tenantId: 'T-005',
        tenantName: 'Fatima Bakers',
        propertyId: 'P-005',
        propertyName: 'Shop 21, Ichhra Market',
        propertyAddress: 'Shop 21, Ichhra Market',
        amount: 9000,
        issueDate: daysAgo(35),
        dueDate: daysAgo(15),
        paidDate: daysAgo(16),
        method: PaymentMethod.easypaisa,
        description: 'Monthly rent — July',
      ),

      // --- Fines linked to seal records -----------------------------------
      Chalaan(
        id: 'FIN-201',
        type: ChalaanType.fine,
        status: ChalaanStatus.overdue,
        tenantId: 'T-002',
        tenantName: 'Bilal General Store',
        propertyId: 'P-002',
        propertyName: 'Shop 12, Liberty Market',
        propertyAddress: 'Shop 12, Liberty Market',
        amount: 25000,
        issueDate: daysAgo(10),
        dueDate: daysAgo(3),
        description: 'Unauthorized encroachment on walkway',
      ),
      Chalaan(
        id: 'FIN-202',
        type: ChalaanType.fine,
        status: ChalaanStatus.paid,
        tenantId: 'T-004',
        tenantName: 'Umar Electronics',
        propertyId: 'P-004',
        propertyName: 'Shop 7, Hall Road',
        propertyAddress: 'Shop 7, Hall Road',
        amount: 30000,
        issueDate: daysAgo(20),
        dueDate: daysAgo(13),
        paidDate: daysAgo(2),
        method: PaymentMethod.bank,
        description: 'Trading without a valid license',
      ),
      Chalaan(
        id: 'FIN-203',
        type: ChalaanType.fine,
        status: ChalaanStatus.paid,
        tenantId: 'T-005',
        tenantName: 'Fatima Bakers',
        propertyId: 'P-005',
        propertyName: 'Shop 21, Ichhra Market',
        propertyAddress: 'Shop 21, Ichhra Market',
        amount: 15000,
        issueDate: daysAgo(45),
        dueDate: daysAgo(38),
        paidDate: daysAgo(40),
        method: PaymentMethod.jazzcash,
        description: 'Blocking the fire exit',
      ),
    ];
  }

  static List<SealRecord> buildSealRecords() {
    final now = DateTime.now();
    DateTime daysAgo(int d) => now.subtract(Duration(days: d));

    return [
      SealRecord(
        id: 'SEAL-301',
        propertyId: 'P-002',
        propertyName: 'Shop 12, Liberty Market',
        tenantName: 'Bilal General Store',
        reason: 'Unauthorized encroachment on walkway',
        sealedDate: daysAgo(10),
        relatedChalaanId: 'FIN-201',
        status: SealStatus.sealed,
      ),
      SealRecord(
        id: 'SEAL-302',
        propertyId: 'P-004',
        propertyName: 'Shop 7, Hall Road',
        tenantName: 'Umar Electronics',
        reason: 'Trading without a valid license',
        sealedDate: daysAgo(20),
        relatedChalaanId: 'FIN-202',
        status: SealStatus.readyToUnseal,
      ),
      SealRecord(
        id: 'SEAL-303',
        propertyId: 'P-005',
        propertyName: 'Shop 21, Ichhra Market',
        tenantName: 'Fatima Bakers',
        reason: 'Blocking the fire exit',
        sealedDate: daysAgo(45),
        relatedChalaanId: 'FIN-203',
        status: SealStatus.removed,
        removedDate: daysAgo(5),
      ),
    ];
  }
}
