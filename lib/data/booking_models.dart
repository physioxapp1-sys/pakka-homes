/// Mirrors bookings/serializers.py on the backend.

class BookingRequest {
  const BookingRequest({
    required this.contactName,
    required this.contactPhone,
    required this.address,
    this.landmark = '',
    this.scheduledDate,
    this.slot = 'anytime',
    this.notes = '',
    this.categorySlug,
    this.subcategorySlug,
    this.providerSlug,
  });

  final String contactName;
  final String contactPhone;
  final String address;
  final String landmark;
  final DateTime? scheduledDate;
  final String slot;
  final String notes;

  /// Subcategory slugs are unique per category, not globally, so the category
  /// has to travel with them.
  final String? categorySlug;
  final String? subcategorySlug;
  final String? providerSlug;

  Map<String, dynamic> toJson() => {
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'address': address,
        if (landmark.isNotEmpty) 'landmark': landmark,
        if (scheduledDate != null)
          'scheduled_date':
              '${scheduledDate!.year.toString().padLeft(4, '0')}-'
              '${scheduledDate!.month.toString().padLeft(2, '0')}-'
              '${scheduledDate!.day.toString().padLeft(2, '0')}',
        'slot': slot,
        if (notes.isNotEmpty) 'notes': notes,
        if (categorySlug != null) 'category_slug': categorySlug,
        if (subcategorySlug != null) 'subcategory_slug': subcategorySlug,
        if (providerSlug != null) 'provider_slug': providerSlug,
      };
}

class BookingConfirmation {
  const BookingConfirmation({
    required this.reference,
    required this.status,
    required this.detail,
  });

  final String reference;
  final String status;
  final String detail;

  factory BookingConfirmation.fromJson(Map<String, dynamic> json) => BookingConfirmation(
        reference: json['reference'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        detail: json['detail'] as String? ?? 'Booking received.',
      );
}

/// A booking as the customer sees it back. Mirrors BookingSerializer.
class CustomerBooking {
  const CustomerBooking({
    required this.id,
    required this.reference,
    required this.status,
    required this.statusDisplay,
    required this.contactName,
    required this.address,
    this.slotDisplay = '',
    this.scheduledDate,
    this.subcategoryName,
    this.providerName,
    this.quotedAmount,
    this.finalAmount,
    this.createdAt,
  });

  final int id;
  final String reference;
  final String status;
  final String statusDisplay;
  final String contactName;
  final String address;
  final String slotDisplay;
  final DateTime? scheduledDate;

  /// Null until the catalog link resolves; the job title falls back to this.
  final String? subcategoryName;

  /// Null until dispatch assigns someone.
  final String? providerName;
  final double? quotedAmount;
  final double? finalAmount;
  final DateTime? createdAt;

  bool get isOpen => const {'pending', 'confirmed', 'in_progress'}.contains(status);

  factory CustomerBooking.fromJson(Map<String, dynamic> json) => CustomerBooking(
        id: json['id'] as int? ?? 0,
        reference: json['reference'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        statusDisplay: json['status_display'] as String? ?? 'Pending',
        contactName: json['contact_name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        slotDisplay: json['slot_display'] as String? ?? '',
        scheduledDate: _toDate(json['scheduled_date']),
        subcategoryName: json['subcategory_name'] as String?,
        providerName: json['provider_name'] as String?,
        quotedAmount: _toDouble(json['quoted_amount']),
        finalAmount: _toDouble(json['final_amount']),
        createdAt: _toDate(json['created_at']),
      );

  static DateTime? _toDate(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;

  // DRF renders DecimalField as a string.
  static double? _toDouble(dynamic value) => switch (value) {
        null => null,
        num n => n.toDouble(),
        String s => double.tryParse(s),
        _ => null,
      };
}

/// Time windows the backend accepts, paired with what to show the customer.
const kBookingSlots = <(String, String)>[
  ('anytime', 'Anytime'),
  ('morning', 'Morning (8am - 12pm)'),
  ('afternoon', 'Afternoon (12pm - 4pm)'),
  ('evening', 'Evening (4pm - 8pm)'),
];
