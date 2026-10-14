/// Mirrors tenancy/serializers.py on the backend.

double? _toDouble(dynamic value) => switch (value) {
      null => null,
      num n => n.toDouble(),
      String s => double.tryParse(s),
      _ => null,
    };

DateTime? _toDate(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;

class RentProperty {
  const RentProperty({
    required this.id,
    required this.title,
    required this.address,
    required this.monthlyRent,
    this.kindDisplay = '',
    this.city = '',
    this.landmark = '',
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.areaSqft,
    this.deposit = 0,
    this.isListed = false,
    this.description = '',
    this.imageUrl,
    this.isOccupied = false,
    this.tenantName,
    this.rentState,
  });

  final int id;
  final String title;
  final String kindDisplay;
  final String address;
  final String city;
  final String landmark;
  final int bedrooms;
  final int bathrooms;
  final int? areaSqft;
  final double monthlyRent;
  final double deposit;
  final bool isListed;
  final String description;
  final String? imageUrl;
  final bool isOccupied;

  /// Only ever set for the owner of the property. Someone browsing for a
  /// place to rent never learns who is already in one.
  final String? tenantName;

  /// 'paid', 'due' or 'overdue' for the latest month. Owner only.
  final String? rentState;

  factory RentProperty.fromJson(Map<String, dynamic> json) => RentProperty(
        id: json['id'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        kindDisplay: json['kind_display'] as String? ?? '',
        address: json['address'] as String? ?? '',
        city: json['city'] as String? ?? '',
        landmark: json['landmark'] as String? ?? '',
        bedrooms: json['bedrooms'] as int? ?? 0,
        bathrooms: json['bathrooms'] as int? ?? 0,
        areaSqft: json['area_sqft'] as int?,
        monthlyRent: _toDouble(json['monthly_rent']) ?? 0,
        deposit: _toDouble(json['deposit']) ?? 0,
        isListed: json['is_listed'] as bool? ?? false,
        description: json['description'] as String? ?? '',
        imageUrl: json['image'] as String?,
        isOccupied: json['is_occupied'] as bool? ?? false,
        tenantName: json['tenant_name'] as String?,
        rentState: json['rent_state'] as String?,
      );
}

class RentPayment {
  const RentPayment({
    required this.id,
    required this.amount,
    required this.state,
    this.period,
    this.dueDate,
    this.paidOn,
    this.amountPaid,
    this.method = '',
    this.reference = '',
    this.propertyTitle = '',
    this.tenantName = '',
  });

  final int id;

  /// The month this rent covers, as its first day.
  final DateTime? period;
  final DateTime? dueDate;
  final double amount;
  final DateTime? paidOn;
  final double? amountPaid;
  final String method;
  final String reference;

  /// 'paid', 'due' or 'overdue'.
  final String state;
  final String propertyTitle;
  final String tenantName;

  bool get isPaid => state == 'paid';
  bool get isOverdue => state == 'overdue';

  factory RentPayment.fromJson(Map<String, dynamic> json) => RentPayment(
        id: json['id'] as int? ?? 0,
        period: _toDate(json['period']),
        dueDate: _toDate(json['due_date']),
        amount: _toDouble(json['amount']) ?? 0,
        paidOn: _toDate(json['paid_on']),
        amountPaid: _toDouble(json['amount_paid']),
        method: json['method'] as String? ?? '',
        reference: json['reference'] as String? ?? '',
        state: json['state'] as String? ?? 'due',
        propertyTitle: json['property_title'] as String? ?? '',
        tenantName: json['tenant_name'] as String? ?? '',
      );
}

class RentContract {
  const RentContract({
    required this.id,
    required this.tenantName,
    required this.propertyTitle,
    required this.monthlyRent,
    this.propertyAddress = '',
    this.roomNames = const [],
    this.tenantPhone = '',
    this.ownerName,
    this.startDate,
    this.endDate,
    this.deposit = 0,
    this.rentDueDay = 1,
    this.statusDisplay = '',
    this.documentUrl,
    this.notes = '',
  });

  final int id;
  final String tenantName;
  final String tenantPhone;
  final String propertyTitle;
  final String propertyAddress;

  /// Every room the lease covers. One name for a one-room let; several where
  /// a family took more than one.
  final List<String> roomNames;
  final String? ownerName;
  final DateTime? startDate;

  /// Null for a rolling tenancy with no agreed end.
  final DateTime? endDate;
  final double monthlyRent;
  final double deposit;
  final int rentDueDay;
  final String statusDisplay;

  /// What to call the place in a list: the rooms it covers, or the property.
  String get placeName =>
      roomNames.isNotEmpty ? roomNames.join(', ') : propertyTitle;

  /// The signed agreement, when a copy was uploaded.
  final String? documentUrl;
  final String notes;

  factory RentContract.fromJson(Map<String, dynamic> json) => RentContract(
        id: json['id'] as int? ?? 0,
        tenantName: json['tenant_name'] as String? ?? '',
        tenantPhone: json['tenant_phone'] as String? ?? '',
        propertyTitle: json['property_title'] as String? ?? '',
        propertyAddress: json['property_address'] as String? ?? '',
        roomNames: (json['room_names'] as List<dynamic>? ?? const [])
            .map((e) => '$e')
            .toList(),
        ownerName: json['owner_name'] as String?,
        startDate: _toDate(json['start_date']),
        endDate: _toDate(json['end_date']),
        monthlyRent: _toDouble(json['monthly_rent']) ?? 0,
        deposit: _toDouble(json['deposit']) ?? 0,
        rentDueDay: json['rent_due_day'] as int? ?? 1,
        statusDisplay: json['status_display'] as String? ?? '',
        documentUrl: json['document'] as String?,
        notes: json['notes'] as String? ?? '',
      );
}

/// The owner's dashboard numbers.
class OwnerSummary {
  const OwnerSummary({
    required this.properties,
    required this.occupied,
    required this.vacant,
    required this.expectedThisMonth,
    required this.collectedThisMonth,
    required this.overdueCount,
    required this.overdueAmount,
  });

  final int properties;
  final int occupied;
  final int vacant;
  final double expectedThisMonth;
  final double collectedThisMonth;
  final int overdueCount;
  final double overdueAmount;

  factory OwnerSummary.fromJson(Map<String, dynamic> json) => OwnerSummary(
        properties: json['properties'] as int? ?? 0,
        occupied: json['occupied'] as int? ?? 0,
        vacant: json['vacant'] as int? ?? 0,
        expectedThisMonth: _toDouble(json['expected_this_month']) ?? 0,
        collectedThisMonth: _toDouble(json['collected_this_month']) ?? 0,
        overdueCount: json['overdue_count'] as int? ?? 0,
        overdueAmount: _toDouble(json['overdue_amount']) ?? 0,
      );
}

/// What the tenant's dashboard needs: where they live and what is owed.
class TenantSummary {
  const TenantSummary({
    required this.contract,
    this.nextDue,
    this.unpaidCount = 0,
  });

  final RentContract contract;
  final RentPayment? nextDue;
  final int unpaidCount;

  factory TenantSummary.fromJson(Map<String, dynamic> json) => TenantSummary(
        contract: RentContract.fromJson(
            json['tenancy'] as Map<String, dynamic>? ?? const {}),
        nextDue: json['next_due'] == null
            ? null
            : RentPayment.fromJson(json['next_due'] as Map<String, dynamic>),
        unpaidCount: json['unpaid_count'] as int? ?? 0,
      );
}

/// Which side of the section someone is on, and their figures.
///
/// Both can be true: a person can let one flat and rent another.
class RentHome {
  const RentHome({
    required this.isOwner,
    required this.isTenant,
    this.owner,
    this.tenant,
  });

  final bool isOwner;
  final bool isTenant;
  final OwnerSummary? owner;
  final TenantSummary? tenant;

  bool get isNeither => !isOwner && !isTenant;

  factory RentHome.fromJson(Map<String, dynamic> json) => RentHome(
        isOwner: json['is_owner'] as bool? ?? false,
        isTenant: json['is_tenant'] as bool? ?? false,
        owner: json['owner'] == null
            ? null
            : OwnerSummary.fromJson(json['owner'] as Map<String, dynamic>),
        tenant: json['tenant'] == null
            ? null
            : TenantSummary.fromJson(json['tenant'] as Map<String, dynamic>),
      );
}
