import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_scope.dart';
import '../data/rent_models.dart';
import '../data/rent_repository.dart';
import '../theme/app_colors.dart';

/// Adding a property, and putting a tenant into one.
///
/// Both exist so an owner never has to be sent to the office to see their own
/// Rent tab do anything. Both pop with the thing they created, so the list
/// behind them can refresh without guessing.

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _repository = RentRepository();
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _rent = TextEditingController();
  final _deposit = TextEditingController();
  final _area = TextEditingController();

  String _kind = 'flat';
  int _bedrooms = 1;
  int _bathrooms = 1;
  bool _listed = false;
  bool _saving = false;
  Map<String, List<String>> _serverErrors = const {};

  @override
  void dispose() {
    for (final c in [_title, _address, _city, _rent, _deposit, _area]) {
      c.dispose();
    }
    _repository.dispose();
    super.dispose();
  }

  String? _serverError(String field) {
    final errors = _serverErrors[field];
    return (errors == null || errors.isEmpty) ? null : errors.first;
  }

  Future<void> _save() async {
    setState(() => _serverErrors = const {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final property = await _repository.addProperty(
        token: AuthScope.of(context).token!,
        title: _title.text.trim(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        monthlyRent: double.tryParse(_rent.text.trim()) ?? 0,
        deposit: double.tryParse(_deposit.text.trim()) ?? 0,
        areaSqft: int.tryParse(_area.text.trim()),
        kind: _kind,
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        isListed: _listed,
      );
      if (mounted) Navigator.of(context).pop(property);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _serverErrors = e.fieldErrors ?? const {});
      _formKey.currentState!.validate();
      if (e.fieldErrors == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Add a property'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            RentField(
              controller: _title,
              label: 'What do you call it?',
              hint: 'Dhapasi 2BHK, first floor',
              icon: Icons.home_outlined,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  _serverError('title') ??
                  ((v == null || v.trim().length < 3)
                      ? 'Give it a name you will recognise.'
                      : null),
            ),
            const _Label('Type'),
            Wrap(
              spacing: 8,
              children: [
                for (final (value, label) in kPropertyKinds)
                  ChoiceChip(
                    label: Text(label, style: const TextStyle(fontSize: 12)),
                    selected: _kind == value,
                    onSelected: (_) => setState(() => _kind = value),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            RentField(
              controller: _address,
              label: 'Address',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  _serverError('address') ??
                  ((v == null || v.trim().length < 5)
                      ? 'Enter enough address for someone to find it.'
                      : null),
            ),
            RentField(
              controller: _city,
              label: 'City (optional)',
              icon: Icons.location_city_outlined,
              textCapitalization: TextCapitalization.words,
            ),
            const _Label('Size'),
            Row(
              children: [
                Expanded(
                  child: _Counter(
                    label: 'Bedrooms',
                    value: _bedrooms,
                    onChanged: (v) => setState(() => _bedrooms = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Counter(
                    label: 'Bathrooms',
                    value: _bathrooms,
                    onChanged: (v) => setState(() => _bathrooms = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RentField(
              controller: _area,
              label: 'Area in sq ft (optional)',
              icon: Icons.straighten_rounded,
              keyboardType: TextInputType.number,
            ),
            const _Label('Money'),
            RentField(
              controller: _rent,
              label: 'Monthly rent (NPR)',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  _serverError('monthly_rent') ??
                  (((double.tryParse((v ?? '').trim()) ?? 0) <= 0)
                      ? 'Enter the monthly rent.'
                      : null),
            ),
            RentField(
              controller: _deposit,
              label: 'Deposit (optional)',
              icon: Icons.savings_outlined,
              keyboardType: TextInputType.number,
            ),
            CheckboxListTile(
              value: _listed,
              onChanged: (v) => setState(() => _listed = v ?? false),
              activeColor: AppColors.green,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Show it to people looking to rent',
                  style: TextStyle(fontSize: 13.5)),
              subtitle: const Text(
                'It comes off the list by itself once someone moves in.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            _SaveButton(
              label: 'Add property',
              busy: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// Putting a tenant into one property. The rent and deposit start at what the
/// property asks, because that is usually what was agreed.
class AddTenantScreen extends StatefulWidget {
  const AddTenantScreen({super.key, required this.property});

  final RentProperty property;

  @override
  State<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> {
  final _repository = RentRepository();
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController();
  late final _phone = TextEditingController();
  late final _rent =
      TextEditingController(text: widget.property.monthlyRent.round().toString());
  late final _deposit =
      TextEditingController(text: widget.property.deposit.round().toString());
  final _notes = TextEditingController();

  DateTime _start = DateTime.now();
  int _dueDay = 1;
  bool _saving = false;
  Map<String, List<String>> _serverErrors = const {};

  @override
  void dispose() {
    for (final c in [_name, _phone, _rent, _deposit, _notes]) {
      c.dispose();
    }
    _repository.dispose();
    super.dispose();
  }

  String? _serverError(String field) {
    final errors = _serverErrors[field];
    return (errors == null || errors.isEmpty) ? null : errors.first;
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _save() async {
    setState(() => _serverErrors = const {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final contract = await _repository.addTenant(
        token: AuthScope.of(context).token!,
        propertyId: widget.property.id,
        tenantName: _name.text.trim(),
        tenantPhone: _phone.text.trim(),
        startDate: _start,
        monthlyRent: double.tryParse(_rent.text.trim()) ?? 0,
        deposit: double.tryParse(_deposit.text.trim()) ?? 0,
        rentDueDay: _dueDay,
        notes: _notes.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(contract);
    } on ApiException catch (e) {
      if (!mounted) return;
      final errors = e.fieldErrors ?? const <String, List<String>>{};
      setState(() => _serverErrors = errors);
      _formKey.currentState!.validate();
      // "Someone is already in it" lands on the property, which has no field
      // on this form - so it is said out loud instead of silently dropped.
      final onProperty = errors['property']?.first;
      if (onProperty != null || e.fieldErrors == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(onProperty ?? e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Add a tenant'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tileBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home_rounded, size: 18, color: AppColors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.property.title,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            RentField(
              controller: _name,
              label: "Tenant's name",
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  _serverError('tenant_name') ??
                  ((v == null || v.trim().length < 2)
                      ? "Enter the tenant's name."
                      : null),
            ),
            RentField(
              controller: _phone,
              label: 'Phone number',
              icon: Icons.call_outlined,
              keyboardType: TextInputType.phone,
              helper: 'They see their own rent and contract when they sign in '
                  'with this number.',
              validator: (v) =>
                  _serverError('tenant_phone') ??
                  (((v ?? '').replaceAll(RegExp(r'\D'), '').length < 7)
                      ? 'Enter a valid phone number.'
                      : null),
            ),
            const _Label('When it starts'),
            InkWell(
              onTap: _pickStart,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined,
                        size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text(_formatDate(_start),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Text('Change',
                        style: TextStyle(fontSize: 13, color: AppColors.primary)),
                  ],
                ),
              ),
            ),
            const _Label('Money'),
            RentField(
              controller: _rent,
              label: 'Monthly rent (NPR)',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  _serverError('monthly_rent') ??
                  (((double.tryParse((v ?? '').trim()) ?? 0) <= 0)
                      ? 'Enter the agreed rent.'
                      : null),
            ),
            RentField(
              controller: _deposit,
              label: 'Deposit (optional)',
              icon: Icons.savings_outlined,
              keyboardType: TextInputType.number,
            ),
            const _Label('Rent is due on'),
            _DueDayPicker(
              value: _dueDay,
              onChanged: (v) => setState(() => _dueDay = v),
            ),
            const SizedBox(height: 16),
            RentField(
              controller: _notes,
              label: 'Notes (optional)',
              icon: Icons.notes_outlined,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            _SaveButton(
              label: 'Add tenant',
              busy: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: 10),
            const Text(
              'This month’s rent is raised straight away, so it shows up '
              'under Rent & Payments.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

const kPropertyKinds = <(String, String)>[
  ('flat', 'Flat / Apartment'),
  ('house', 'House'),
  ('room', 'Room'),
  ('shop', 'Shop / Commercial'),
];

class RentField extends StatelessWidget {
  const RentField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.helper,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final String? helper;
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
          hintText: hint,
          helperText: helper,
          helperMaxLines: 2,
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

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          IconButton(
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            visualDensity: VisualDensity.compact,
            color: AppColors.primary,
          ),
          Text('$value',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          IconButton(
            onPressed: value < 20 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline, size: 20),
            visualDensity: VisualDensity.compact,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

/// 1 to 28, plus "last day". Nothing above 28 is safe on every month, and the
/// server already folds a 31 back to the last day - this just stops someone
/// picking a day that only exists seven months a year by accident.
class _DueDayPicker extends StatelessWidget {
  const _DueDayPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final day in const [1, 5, 10, 15, 20, 25, 28, 31])
          ChoiceChip(
            label: Text(day == 31 ? 'Last day' : '$day',
                style: const TextStyle(fontSize: 12)),
            selected: value == day,
            onSelected: (_) => onChanged(day),
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
          ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
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
