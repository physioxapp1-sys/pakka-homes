import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_scope.dart';
import '../data/order_models.dart';
import '../data/order_repository.dart';
import '../data/product_models.dart';
import '../theme/app_colors.dart';

/// Where an order is now: the status timeline, what is in it and who is
/// bringing it.
///
/// There is no live map. That needs a maps SDK key and a delivery partner
/// reporting their position, neither of which exists yet; the timeline below
/// is real data, so it is shown instead of a decorative map.
class OrderTrackScreen extends StatefulWidget {
  const OrderTrackScreen({
    super.key,
    required this.order,
    this.justPlaced = false,
  });

  final CustomerOrder order;

  /// Shows the confirmation banner, and makes back go to the shop rather than
  /// to the checkout form the order came from.
  final bool justPlaced;

  @override
  State<OrderTrackScreen> createState() => _OrderTrackScreenState();
}

class _OrderTrackScreenState extends State<OrderTrackScreen> {
  final _repository = OrderRepository();

  late CustomerOrder _order = widget.order;
  bool _refreshing = false;

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final fresh = await _repository.lookup(
        reference: _order.reference,
        phone: _order.contactPhone,
      );
      if (mounted) setState(() => _order = fresh);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.navy,
        title: const Text('Track Order',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
        actions: [
          IconButton(
            onPressed: _refreshing ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.green,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            if (widget.justPlaced) ...[
              const _PlacedBanner(),
              const SizedBox(height: 14),
            ],
            _ReferenceCard(order: order),
            const SizedBox(height: 14),
            _Card(
              title: 'Order status',
              child: _Timeline(steps: order.timeline),
            ),
            const SizedBox(height: 14),
            if (order.partnerName != null && order.partnerName!.isNotEmpty) ...[
              _PartnerCard(order: order),
              const SizedBox(height: 14),
            ],
            _Card(
              title: 'Delivery details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                      icon: Icons.person_outline,
                      label: 'Name',
                      value: order.contactName),
                  _DetailRow(
                      icon: Icons.call_outlined,
                      label: 'Phone',
                      value: order.contactPhone),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: [order.deliveryAddress, order.landmark]
                        .where((s) => s.isNotEmpty)
                        .join(', '),
                  ),
                  if (order.scheduledDate != null || order.slotDisplay.isNotEmpty)
                    _DetailRow(
                      icon: Icons.schedule,
                      label: 'When',
                      value: [
                        if (order.scheduledDate != null)
                          _formatDate(order.scheduledDate!),
                        if (order.slotDisplay.isNotEmpty) order.slotDisplay,
                      ].join(' · '),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              title: '${order.items.length} '
                  '${order.items.length == 1 ? 'item' : 'items'}',
              child: Column(
                children: [
                  for (final item in order.items) _ItemRow(item: item),
                  const Divider(height: 24, color: AppColors.cardBorder),
                  _TotalRow(label: 'Item total', value: order.itemTotal),
                  if (order.discount > 0)
                    _TotalRow(
                        label: 'Discount',
                        value: -order.discount,
                        valueColor: AppColors.green),
                  _TotalRow(
                    label: 'Delivery',
                    value: order.deliveryFee,
                    freeWhenZero: true,
                  ),
                  const SizedBox(height: 6),
                  _TotalRow(label: 'Total paid', value: order.total, bold: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Orders tab entry for guests, and for anyone who has the reference from the
/// confirmation but is not signed in.
class OrderLookupScreen extends StatefulWidget {
  const OrderLookupScreen({super.key});

  @override
  State<OrderLookupScreen> createState() => _OrderLookupScreenState();
}

class _OrderLookupScreenState extends State<OrderLookupScreen> {
  final _repository = OrderRepository();
  final _formKey = GlobalKey<FormState>();
  final _reference = TextEditingController();
  final _phone = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefilled) {
      _prefilled = true;
      final user = AuthScope.of(context).user;
      if (user != null && _phone.text.isEmpty) _phone.text = user.phone;
    }
  }

  @override
  void dispose() {
    _reference.dispose();
    _phone.dispose();
    _repository.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await _repository.lookup(
        reference: _reference.text,
        phone: _phone.text,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderTrackScreen(order: order)),
      );
    } on ApiException catch (e) {
      // 404 covers both a wrong reference and a phone that does not match -
      // the endpoint deliberately does not say which.
      if (mounted) {
        setState(() => _error = e.statusCode == 404
            ? 'No order found with that reference and phone number.'
            : e.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.navy,
        title: const Text('Find an order',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Enter the reference from your order confirmation along with the '
              'phone number you ordered with.',
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reference,
              textCapitalization: TextCapitalization.characters,
              decoration: _decoration('Order reference', Icons.receipt_long_outlined),
              validator: (v) => (v == null || v.trim().length < 4)
                  ? 'Enter the order reference, e.g. PO-XQ3DUH.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: _decoration('Phone number', Icons.call_outlined),
              validator: (v) =>
                  (v ?? '').replaceAll(RegExp(r'\D'), '').length < 7
                      ? 'Enter a valid phone number.'
                      : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.emergencyRed)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _find,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Track order',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
      );
}

class _PlacedBanner extends StatelessWidget {
  const _PlacedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tileGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.green, size: 26),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order placed',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.green)),
                SizedBox(height: 2),
                Text('We will call you to confirm before delivery.',
                    style:
                        TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order reference',
                    style: TextStyle(fontSize: 12, color: Color(0xFFBBD4EA))),
                const SizedBox(height: 4),
                Text(order.reference,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(order.statusDisplay,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const Text('No status yet.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary));
    }

    // The last done step is "now" - everything before it is history, and the
    // ones after it are still to come.
    var current = -1;
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].done) current = i;
    }

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    height: 22,
                    width: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: steps[i].done ? AppColors.green : Colors.white,
                      border: Border.all(
                        color: steps[i].done
                            ? AppColors.green
                            : AppColors.cardBorder,
                        width: 2,
                      ),
                    ),
                    child: steps[i].done
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : null,
                  ),
                  if (i != steps.length - 1)
                    Container(
                      height: 30,
                      width: 2,
                      color: steps[i + 1].done
                          ? AppColors.green
                          : AppColors.cardBorder,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    steps[i].label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: i == current ? FontWeight.w800 : FontWeight.w500,
                      color: steps[i].done
                          ? AppColors.navy
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final phone = order.partnerPhone ?? '';
    return _Card(
      title: 'Delivery partner',
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.tileGreen,
            ),
            child: const Icon(Icons.delivery_dining,
                color: AppColors.green, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.partnerName!,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                if (phone.isNotEmpty)
                  Text(phone,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            // Shows the number rather than dialling it: placing a call needs
            // url_launcher and a tel: intent, which the app does not have yet.
            OutlinedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Call delivery partner'),
                  content: Text('${order.partnerName}\n$phone'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              icon: const Icon(Icons.call, size: 16),
              label: const Text('Call'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 62,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy)),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderItemLine item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            height: 24,
            width: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.tileGreen,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text('${item.quantity}',
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.unit.isEmpty ? item.name : '${item.name} (${item.unit})',
              style: const TextStyle(fontSize: 13.5),
            ),
          ),
          Text(formatNpr(item.lineTotal),
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.freeWhenZero = false,
    this.valueColor,
  });

  final String label;
  final double value;
  final bool bold;
  final bool freeWhenZero;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final text = freeWhenZero && value == 0 ? 'Free' : formatNpr(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: bold ? 15 : 13.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: bold ? AppColors.navy : AppColors.textSecondary,
              )),
          Text(text,
              style: TextStyle(
                fontSize: bold ? 15 : 13.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ??
                    (freeWhenZero && value == 0
                        ? AppColors.green
                        : AppColors.navy),
              )),
        ],
      ),
    );
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';
