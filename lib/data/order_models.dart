/// Mirrors orders/serializers.py on the backend.

class DeliverySlot {
  const DeliverySlot({required this.value, required this.label});

  final String value;
  final String label;

  factory DeliverySlot.fromJson(Map<String, dynamic> json) => DeliverySlot(
        value: json['value'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );
}

class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.labelDisplay,
    required this.recipientName,
    required this.phone,
    required this.address,
    this.landmark = '',
    this.city = '',
    this.isDefault = false,
    this.oneLine = '',
  });

  final int id;
  final String label;
  final String labelDisplay;
  final String recipientName;
  final String phone;
  final String address;
  final String landmark;
  final String city;
  final bool isDefault;
  final String oneLine;

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
        id: json['id'] as int? ?? 0,
        label: json['label'] as String? ?? 'home',
        labelDisplay: json['label_display'] as String? ?? 'Home',
        recipientName: json['recipient_name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
        landmark: json['landmark'] as String? ?? '',
        city: json['city'] as String? ?? '',
        isDefault: json['is_default'] as bool? ?? false,
        oneLine: json['one_line'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'recipient_name': recipientName,
        'phone': phone,
        'address': address,
        if (landmark.isNotEmpty) 'landmark': landmark,
        if (city.isNotEmpty) 'city': city,
        'is_default': isDefault,
      };
}

class OrderItemLine {
  const OrderItemLine({
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.unit = '',
    this.imageUrl,
  });

  final String name;
  final String unit;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final String? imageUrl;

  factory OrderItemLine.fromJson(Map<String, dynamic> json) => OrderItemLine(
        name: json['name'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        unitPrice: _toDouble(json['unit_price']) ?? 0,
        quantity: json['quantity'] as int? ?? 1,
        lineTotal: _toDouble(json['line_total']) ?? 0,
        imageUrl: json['image'] as String?,
      );
}

class TimelineStep {
  const TimelineStep({required this.status, required this.label, required this.done});

  final String status;
  final String label;
  final bool done;

  factory TimelineStep.fromJson(Map<String, dynamic> json) => TimelineStep(
        status: json['status'] as String? ?? '',
        label: json['label'] as String? ?? '',
        done: json['done'] as bool? ?? false,
      );
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.reference,
    required this.status,
    required this.statusDisplay,
    required this.contactName,
    required this.deliveryAddress,
    required this.total,
    this.contactPhone = '',
    this.landmark = '',
    this.scheduledDate,
    this.slotDisplay = '',
    this.itemTotal = 0,
    this.deliveryFee = 0,
    this.discount = 0,
    this.partnerName,
    this.partnerPhone,
    this.items = const [],
    this.timeline = const [],
    this.createdAt,
  });

  final int id;
  final String reference;
  final String status;
  final String statusDisplay;
  final String contactName;
  final String contactPhone;
  final String deliveryAddress;
  final String landmark;
  final DateTime? scheduledDate;
  final String slotDisplay;
  final double itemTotal;
  final double deliveryFee;
  final double discount;
  final double total;

  /// Null until someone is assigned to deliver it.
  final String? partnerName;
  final String? partnerPhone;
  final List<OrderItemLine> items;
  final List<TimelineStep> timeline;
  final DateTime? createdAt;

  bool get isOpen => status != 'delivered' && status != 'cancelled';

  factory CustomerOrder.fromJson(Map<String, dynamic> json) => CustomerOrder(
        id: json['id'] as int? ?? 0,
        reference: json['reference'] as String? ?? '',
        status: json['status'] as String? ?? 'placed',
        statusDisplay: json['status_display'] as String? ?? 'Order Placed',
        contactName: json['contact_name'] as String? ?? '',
        contactPhone: json['contact_phone'] as String? ?? '',
        deliveryAddress: json['delivery_address'] as String? ?? '',
        landmark: json['landmark'] as String? ?? '',
        scheduledDate: _toDate(json['scheduled_date']),
        slotDisplay: json['slot_display'] as String? ?? '',
        itemTotal: _toDouble(json['item_total']) ?? 0,
        deliveryFee: _toDouble(json['delivery_fee']) ?? 0,
        discount: _toDouble(json['discount']) ?? 0,
        total: _toDouble(json['total']) ?? 0,
        partnerName: json['partner_name'] as String?,
        partnerPhone: json['partner_phone'] as String?,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => OrderItemLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        timeline: (json['timeline'] as List<dynamic>? ?? [])
            .map((e) => TimelineStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: _toDate(json['created_at']),
      );
}

DateTime? _toDate(dynamic value) => value is String ? DateTime.tryParse(value) : null;

// DRF renders DecimalField as a string.
double? _toDouble(dynamic value) => switch (value) {
      null => null,
      num n => n.toDouble(),
      String s => double.tryParse(s),
      _ => null,
    };
