import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_scope.dart';
import '../data/cart.dart';
import '../data/order_models.dart';
import '../data/order_repository.dart';
import '../data/product_models.dart';
import '../theme/app_colors.dart';
import 'order_track_screen.dart';

/// Delivery address and time, then place the order.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _repository = OrderRepository();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _landmark = TextEditingController();

  List<SavedAddress> _saved = const [];
  SavedAddress? _selected;
  List<DeliverySlot> _slots = const [];
  String? _slot;
  DateTime _date = DateTime.now();

  bool _placing = false;
  bool _loaded = false;
  bool _saveForNextTime = false;
  Map<String, List<String>> _serverErrors = const {};
  String? _formError;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _prefill();
      _loadAddresses();
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _landmark]) {
      c.dispose();
    }
    _repository.dispose();
    super.dispose();
  }

  void _prefill() {
    final user = AuthScope.of(context).user;
    if (user == null) return;
    if (_name.text.isEmpty && user.fullName.isNotEmpty) _name.text = user.fullName;
    if (_phone.text.isEmpty && user.phone.isNotEmpty) _phone.text = user.phone;
  }

  Future<void> _loadSlots() async {
    try {
      final rows = await _repository.slots();
      if (mounted) setState(() => _slots = rows);
    } on ApiException {
      // Slots are optional - an order without one still reaches the shop.
    }
  }

  Future<void> _loadAddresses() async {
    final token = AuthScope.of(context).token;
    if (token == null) return;
    try {
      final rows = await _repository.addresses(token);
      if (!mounted || rows.isEmpty) return;
      final chosen = rows.firstWhere((a) => a.isDefault, orElse: () => rows.first);
      setState(() {
        _saved = rows;
        _selected = chosen;
        _applyAddress(chosen);
      });
    } on ApiException {
      // Not signed in, or none saved - the form below still works.
    }
  }

  void _applyAddress(SavedAddress a) {
    _name.text = a.recipientName;
    _phone.text = a.phone;
    _address.text = a.address;
    _landmark.text = a.landmark;
  }

  Future<void> _place() async {
    setState(() {
      _serverErrors = const {};
      _formError = null;
    });
    if (!_formKey.currentState!.validate()) return;

    final cart = CartScope.of(context);
    final token = AuthScope.of(context).token;
    setState(() => _placing = true);
    try {
      final order = await _repository.place(
        cart: cart,
        contactName: _name.text,
        contactPhone: _phone.text,
        deliveryAddress: _address.text,
        landmark: _landmark.text,
        scheduledDate: _date,
        slot: _slot,
        token: token,
      );
      if (_saveForNextTime && token != null) await _saveAddress(token);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderTrackScreen(order: order, justPlaced: true),
        ),
      );
      // After navigating, so the bar does not blink to NPR 0 on the way out.
      cart.clear();
    } on ApiException catch (e) {
      if (!mounted) return;
      final errors = e.fieldErrors ?? const <String, List<String>>{};
      setState(() {
        _serverErrors = errors;
        _formError = errors['items']?.first ??
            errors['non_field_errors']?.first ??
            (errors.isEmpty ? e.message : null);
      });
      _formKey.currentState!.validate();
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  /// Best effort: the order is already placed, so a failure here is worth a
  /// note but not an error page.
  Future<void> _saveAddress(String token) async {
    try {
      await _repository.saveAddress(
        SavedAddress(
          id: 0,
          label: 'home',
          labelDisplay: 'Home',
          recipientName: _name.text.trim(),
          phone: _phone.text.trim(),
          address: _address.text.trim(),
          landmark: _landmark.text.trim(),
        ),
        token,
      );
    } on ApiException {
      // Ignored deliberately - see above.
    }
  }

  String? _serverError(String field) {
    final errors = _serverErrors[field];
    return (errors == null || errors.isEmpty) ? null : errors.first;
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.navy,
        title: const Text('Delivery Address',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          children: [
            if (_formError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEDED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 18, color: AppColors.emergencyRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_formError!,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.emergencyRed)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (_saved.isNotEmpty) ...[
              const _SectionLabel('Saved addresses'),
              for (final a in _saved)
                RadioListTile<int>(
                  value: a.id,
                  groupValue: _selected?.id,
                  onChanged: (_) => setState(() {
                    _selected = a;
                    _applyAddress(a);
                  }),
                  activeColor: AppColors.green,
                  contentPadding: EdgeInsets.zero,
                  title: Text(a.labelDisplay,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: Text(a.oneLine,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                ),
              const SizedBox(height: 10),
            ],
            const _SectionLabel('Deliver to'),
            _Field(
              controller: _name,
              label: 'Name',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  _serverError('contact_name') ??
                  ((v == null || v.trim().length < 2) ? 'Enter your name.' : null),
            ),
            _Field(
              controller: _phone,
              label: 'Phone number',
              icon: Icons.call_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                return _serverError('contact_phone') ??
                    (digits.length < 7 ? 'Enter a valid phone number.' : null);
              },
            ),
            _Field(
              controller: _address,
              label: 'Address',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  _serverError('delivery_address') ??
                  ((v == null || v.trim().length < 5)
                      ? 'Enter enough address for someone to find you.'
                      : null),
            ),
            _Field(
              controller: _landmark,
              label: 'Landmark (optional)',
              icon: Icons.signpost_outlined,
              textCapitalization: TextCapitalization.sentences,
            ),
            if (AuthScope.of(context).isSignedIn)
              CheckboxListTile(
                value: _saveForNextTime,
                onChanged: (v) => setState(() => _saveForNextTime = v ?? false),
                activeColor: AppColors.green,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Save this address for next time',
                    style: TextStyle(fontSize: 13.5)),
              ),
            const SizedBox(height: 8),
            const _SectionLabel('Select delivery time'),
            _DayPicker(selected: _date, onChanged: (d) => setState(() => _date = d)),
            const SizedBox(height: 10),
            if (_slots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Any time',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              )
            else
              for (final slot in _slots)
                RadioListTile<String>(
                  value: slot.value,
                  groupValue: _slot,
                  onChanged: (v) => setState(() => _slot = v),
                  activeColor: AppColors.green,
                  contentPadding: EdgeInsets.zero,
                  title: Text(slot.label, style: const TextStyle(fontSize: 14)),
                ),
            const SizedBox(height: 10),
            if (cart.delivery == 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tileGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined,
                        size: 18, color: AppColors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Free delivery on orders above '
                      '${formatNpr(Cart.freeDeliveryAbove)}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.green),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _placing ? null : _place,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _placing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Place order  ·  ${formatNpr(cart.total)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
    );
  }
}

/// Today and the next few days. Groceries are not booked weeks out, and a
/// full calendar for a four-day window is more work than it saves.
class _DayPicker extends StatelessWidget {
  const _DayPicker({required this.selected, required this.onChanged});

  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < 4; i++)
            Builder(builder: (context) {
              final day = DateTime(today.year, today.month, today.day + i);
              final isSelected = day.day == selected.day &&
                  day.month == selected.month &&
                  day.year == selected.year;
              final label = i == 0
                  ? 'Today'
                  : i == 1
                      ? 'Tomorrow'
                      : '${day.day}/${day.month}';
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => onChanged(day),
                  showCheckmark: false,
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.green,
                  side: const BorderSide(color: AppColors.cardBorder),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.navy,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
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
        ),
      ),
    );
  }
}
