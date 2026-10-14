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
    this.subcategorySlugs = const [],
    this.preferredSlots = const [],
    this.engagement,
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

  /// Several services on one booking - maid work is hired as a bundle. The
  /// first is the headline one on the server.
  final List<String> subcategorySlugs;

  /// Times that suit, most-wanted first. A household will take morning or
  /// evening and not mind which, which [slot] alone cannot say.
  final List<String> preferredSlots;

  /// 'full_time', 'part_time' or 'one_time'. Null for a one-off job, where
  /// the question does not arise.
  final String? engagement;
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
        if (subcategorySlugs.isNotEmpty) 'subcategory_slugs': subcategorySlugs,
        if (preferredSlots.isNotEmpty) 'preferred_slots': preferredSlots,
        if (engagement != null) 'engagement': engagement,
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
    this.serviceNames = const [],
    this.engagementDisplay = '',
    this.preferredSlotsDisplay = '',
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

  /// Everything asked for. A maid booking names several; everything else
  /// names one.
  final List<String> serviceNames;

  /// "Full time" / "Part time", empty for a one-off job.
  final String engagementDisplay;

  /// The times that suit, in words. Falls back to the single slot.
  final String preferredSlotsDisplay;

  /// Null until dispatch assigns someone.
  final String? providerName;
  final double? quotedAmount;
  final double? finalAmount;
  final DateTime? createdAt;

  bool get isOpen => const {'pending', 'confirmed', 'in_progress'}.contains(status);

  /// What to call this booking in a list.
  String get title => serviceNames.isNotEmpty
      ? serviceNames.join(', ')
      : (subcategoryName ?? 'Service booking');

  /// The times that suit. Falls back to the single slot for bookings taken
  /// before more than one could be given.
  String get timesDisplay =>
      preferredSlotsDisplay.isNotEmpty ? preferredSlotsDisplay : slotDisplay;

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
        serviceNames: (json['service_names'] as List<dynamic>? ?? const [])
            .map((e) => '$e')
            .toList(),
        engagementDisplay: json['engagement_display'] as String? ?? '',
        preferredSlotsDisplay: json['preferred_slots_display'] as String? ?? '',
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

/// How often the help is wanted. Only asked where it changes the job - maid
/// work - and the labels match the backend's Booking.Engagement.
const kEngagements = <(String, String)>[
  ('full_time', 'Full time'),
  ('part_time', 'Part time'),
  ('one_time', 'One time'),
];
