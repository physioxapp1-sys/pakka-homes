import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_scope.dart';
import '../data/rent_models.dart';
import '../data/rent_repository.dart';
import '../theme/app_colors.dart';

/// Adding a house, laying out its rooms, and putting a tenant into them.
///
/// These exist so an owner never has to be sent to the office to see their own
/// Rent tab do anything. Each pops with the thing it created, so the list
/// behind it can refresh without guessing.

/// Adding a house, a plot, or whatever else is let.
///
/// Only a name is really needed - "House 1" will do, and it can be renamed
/// the week after. Floors and rooms come next, on the house's own screen.
class AddBuildingScreen extends StatefulWidget {
  const AddBuildingScreen({super.key});

  @override
  State<AddBuildingScreen> createState() => _AddBuildingScreenState();
}

class _AddBuildingScreenState extends State<AddBuildingScreen> {
  final _repository = RentRepository();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();

  String _kind = 'house';
  bool _saving = false;
  Map<String, List<String>> _serverErrors = const {};

  @override
  void dispose() {
    for (final c in [_name, _address, _city]) {
      c.dispose();
    }
    _repository.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _serverErrors = const {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final building = await _repository.addBuilding(
        token: AuthScope.of(context).token!,
        name: _name.text.trim(),
        kind: _kind,
        address: _address.text.trim(),
        city: _city.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(building);
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
        title: const Text('Add a house'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            RentField(
              controller: _name,
              label: 'What do you call it?',
              hint: 'House 1',
              icon: Icons.apartment_outlined,
              textCapitalization: TextCapitalization.words,
              helper: 'You can rename it any time.',
              validator: (v) =>
                  (_serverErrors['name']?.first) ??
                  ((v == null || v.trim().length < 2)
                      ? "Give it a name, even just 'House 1'."
                      : null),
            ),
            const _Label('What is it?'),
            Wrap(
              spacing: 8,
              children: [
                for (final (value, label) in kBuildingKinds)
                  ChoiceChip(
                    label: Text(label, style: const TextStyle(fontSize: 12)),
                    selected: _kind == value,
                    onSelected: (_) => setState(() => _kind = value),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                _kind == 'house'
                    ? 'You will lay out its floors and rooms next.'
                    : 'Let whole, so it has no floors or rooms.',
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ),
            RentField(
              controller: _address,
              label: 'Address',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            RentField(
              controller: _city,
              label: 'City (optional)',
              icon: Icons.location_city_outlined,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            _SaveButton(
              label: _kind == 'house' ? 'Add house' : 'Add it',
              busy: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// Laying out floors of rooms in one go.
///
/// A landlord says "six floors, four rooms each" once, rather than adding
/// twenty-four rooms one at a time.
class AddRoomsScreen extends StatefulWidget {
  const AddRoomsScreen({
    super.key,
    required this.building,
    required this.repository,
  });

  final Building building;
  final RentRepository repository;

  @override
  State<AddRoomsScreen> createState() => _AddRoomsScreenState();
}

class _AddRoomsScreenState extends State<AddRoomsScreen> {
  int _floors = 1;
  int _roomsPerFloor = 4;
  bool _saving = false;

  /// The floors this would create, carrying on above whatever is there.
  List<int> get _newFloors {
    final existing = widget.building.floors.map((f) => f.floor).toList();
    final from = existing.isEmpty ? 1 : (existing.reduce((a, b) => a > b ? a : b) + 1);
    return [for (var i = 0; i < _floors; i++) from + i];
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repository.addRooms(
        token: AuthScope.of(context).token!,
        buildingId: widget.building.id,
        floors: _newFloors,
        roomsPerFloor: _roomsPerFloor,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final floors = _newFloors;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Add rooms'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Label('How many floors are you adding?'),
          _Stepper(
            value: _floors,
            min: 1,
            max: 20,
            onChanged: (v) => setState(() => _floors = v),
          ),
          const SizedBox(height: 16),
          const _Label('How many rooms on each?'),
          _Stepper(
            value: _roomsPerFloor,
            min: 1,
            max: 40,
            onChanged: (v) => setState(() => _roomsPerFloor = v),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.tileGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This adds ${floors.length * _roomsPerFloor} rooms',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green),
                ),
                const SizedBox(height: 4),
                Text(
                  floors.length == 1
                      ? 'Floor ${floors.first}, rooms 1 to $_roomsPerFloor.'
                      : 'Floors ${floors.first} to ${floors.last}, '
                          '$_roomsPerFloor rooms each.',
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Rent is set per room when you add a tenant, so nothing to '
                  'type now.',
                  style: TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SaveButton(
            label: 'Add ${floors.length * _roomsPerFloor} rooms',
            busy: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.primary,
          ),
          Text('$value',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

const kBuildingKinds = <(String, String)>[
  ('house', 'House'),
  ('land', 'Land'),
  ('other', 'Other'),
];

/// Putting a tenant into a place.
///
/// A lease covers one room or several: a family taking two rooms is one
/// tenancy over both, paying once. The room it was opened from is ticked, the
/// other empty ones at the same address can be ticked too, and the rent is one
/// figure for the lot rather than a sum to split.
class AddTenantScreen extends StatefulWidget {
  const AddTenantScreen({
    super.key,
    required this.property,
    this.alsoVacant = const [],
  });

  /// The room tapped. Always part of the lease.
  final RentProperty property;

  /// Other empty rooms the owner has, offered alongside it.
  final List<RentProperty> alsoVacant;

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

  /// Room ids on the lease, the tapped one first - the server makes the first
  /// its headline room.
  late final _rooms = <int>{widget.property.id};

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
        roomIds: [
          widget.property.id,
          for (final room in widget.alsoVacant)
            if (_rooms.contains(room.id)) room.id,
        ],
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
      // "Someone is already in Room 2" lands on the rooms, which have no
      // field on this form - so it is said out loud instead of being dropped.
      final onProperty = errors['rooms']?.first ?? errors['property']?.first;
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
            if (widget.alsoVacant.isNotEmpty) ...[
              const _Label('Taking more than one room?'),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Tick any others they are taking. One lease, one rent, one '
                  'row a month.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ),
              for (final room in widget.alsoVacant)
                CheckboxListTile(
                  value: _rooms.contains(room.id),
                  onChanged: (on) => setState(() => on == true
                      ? _rooms.add(room.id)
                      : _rooms.remove(room.id)),
                  activeColor: AppColors.green,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  title: Text(room.title, style: const TextStyle(fontSize: 13.5)),
                ),
            ],
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
              helper: _rooms.length > 1
                  ? 'The whole lease, for all ${_rooms.length} rooms together.'
                  : null,
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
