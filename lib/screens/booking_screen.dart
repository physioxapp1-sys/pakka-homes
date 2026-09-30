import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/booking_models.dart';
import '../data/booking_repository.dart';
import '../theme/app_colors.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.title,
    this.categorySlug,
    this.subcategorySlug,
    this.providerSlug,
    this.providerName,
  });

  final String title;
  final String? categorySlug;
  final String? subcategorySlug;
  final String? providerSlug;
  final String? providerName;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = BookingRepository();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _landmark = TextEditingController();
  final _notes = TextEditingController();

  DateTime? _date;
  String _slot = 'anytime';
  bool _submitting = false;

  /// Field errors returned by the server, so DRF's validation surfaces on the
  /// field it belongs to rather than as one opaque message.
  Map<String, List<String>> _serverErrors = const {};

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _landmark, _notes]) {
      c.dispose();
    }
    _repository.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 120)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = const {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final confirmation = await _repository.create(BookingRequest(
        contactName: _name.text,
        contactPhone: _phone.text,
        address: _address.text,
        landmark: _landmark.text,
        scheduledDate: _date,
        slot: _slot,
        notes: _notes.text,
        categorySlug: widget.categorySlug,
        subcategorySlug: widget.subcategorySlug,
        providerSlug: widget.providerSlug,
      ));
      if (mounted) _showConfirmation(confirmation);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _serverErrors = e.fieldErrors ?? const {});
      // Re-run validators so any field-level server errors are shown.
      _formKey.currentState!.validate();
      if (e.fieldErrors == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showConfirmation(BookingConfirmation confirmation) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Color(0xFF3E9142), size: 44),
        title: const Text('Booking received'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(confirmation.detail, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                confirmation.reference,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep this reference to track your booking.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(confirmation);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String? _serverError(String field) {
    final errors = _serverErrors[field];
    return (errors == null || errors.isEmpty) ? null : errors.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Book a service'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Summary(title: widget.title, providerName: widget.providerName),
            const SizedBox(height: 18),
            _Field(
              controller: _name,
              label: 'Your name',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              validator: (v) => _serverError('contact_name') ??
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
              validator: (v) => _serverError('address') ??
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
            const SizedBox(height: 4),
            _DateRow(date: _date, onPick: _pickDate, onClear: () => setState(() => _date = null)),
            const SizedBox(height: 14),
            const Text('Preferred time',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (value, label) in kBookingSlots)
                  ChoiceChip(
                    label: Text(label, style: const TextStyle(fontSize: 12)),
                    selected: _slot == value,
                    onSelected: (_) => setState(() => _slot = value),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _Field(
              controller: _notes,
              label: 'Anything we should know? (optional)',
              icon: Icons.notes_outlined,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Confirm booking',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.title, this.providerName});

  final String title;
  final String? providerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_turned_in_outlined, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  providerName == null ? 'We will assign a professional' : 'with $providerName',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.onPick, required this.onClear});

  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final label = date == null
        ? 'Pick a date (optional)'
        : '${date!.day}/${date!.month}/${date!.year}';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: date == null ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ),
            if (date != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
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
