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

/// Time windows the backend accepts, paired with what to show the customer.
const kBookingSlots = <(String, String)>[
  ('anytime', 'Anytime'),
  ('morning', 'Morning (8am - 12pm)'),
  ('afternoon', 'Afternoon (12pm - 4pm)'),
  ('evening', 'Evening (4pm - 8pm)'),
];
