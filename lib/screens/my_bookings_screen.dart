import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_scope.dart';
import '../data/booking_models.dart';
import '../data/booking_repository.dart';
import '../theme/app_colors.dart';
import 'auth_screen.dart';

/// The customer's bookings.
///
/// Signed out this is not a wall: bookings can be made as a guest, so there
/// is a reference + phone lookup alongside the sign-in offer. Otherwise
/// someone who booked without an account could never see it again.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final _repository = BookingRepository();

  List<CustomerBooking>? _bookings;
  String? _error;
  bool _loadedForToken = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = AuthScope.of(context).token;
    if (token != null && !_loadedForToken) {
      _loadedForToken = true;
      _load();
    } else if (token == null) {
      _loadedForToken = false;
    }
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = AuthScope.of(context).token;
    if (token == null) return;
    setState(() => _error = null);
    try {
      final rows = await _repository.mine(token);
      if (mounted) setState(() => _bookings = rows);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _bookings = const [];
          _error = e.message;
        });
      }
    }
  }

  Future<void> _signIn() async {
    final auth = AuthScope.of(context);
    final signedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          auth: auth,
          reason: 'Sign in to see every booking made with your number.',
        ),
      ),
    );
    if (signedIn == true && mounted) {
      _loadedForToken = true;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = AuthScope.of(context).isSignedIn;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('My bookings'),
      ),
      body: signedIn ? _signedInBody() : _GuestBody(onSignIn: _signIn, repository: _repository),
    );
  }

  Widget _signedInBody() {
    final bookings = _bookings;
    if (bookings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
          children: [
            const Icon(Icons.event_note_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              _error ?? 'No bookings yet. When you book a service it will show up here.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => BookingCard(booking: bookings[i]),
      ),
    );
  }
}

class _GuestBody extends StatefulWidget {
  const _GuestBody({required this.onSignIn, required this.repository});

  final VoidCallback onSignIn;
  final BookingRepository repository;

  @override
  State<_GuestBody> createState() => _GuestBodyState();
}

class _GuestBodyState extends State<_GuestBody> {
  final _reference = TextEditingController();
  final _phone = TextEditingController();

  CustomerBooking? _found;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _reference.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _found = null;
    });

    if (_reference.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      setState(() => _error = 'Enter both the reference and the phone number you booked with.');
      return;
    }

    setState(() => _busy = true);
    try {
      final booking = await widget.repository.lookup(
        reference: _reference.text,
        phone: _phone.text,
      );
      if (mounted) setState(() => _found = booking);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.statusCode == 404
            ? 'No booking found for that reference and number.'
            : e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'See all your bookings',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sign in and every booking made with your number appears here.',
                style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.3),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or track one booking',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        _TrackField(
          controller: _reference,
          label: 'Booking reference',
          hint: 'PH-XXXXXX',
          icon: Icons.confirmation_number_outlined,
          capitalise: true,
        ),
        _TrackField(
          controller: _phone,
          label: 'Phone number used',
          icon: Icons.call_outlined,
          keyboardType: TextInputType.phone,
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!,
              style: const TextStyle(fontSize: 12.5, color: AppColors.emergencyRed)),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: _busy ? null : _track,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Track booking', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        if (_found != null) ...[
          const SizedBox(height: 20),
          BookingCard(booking: _found!),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _TrackField extends StatelessWidget {
  const _TrackField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.capitalise = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final bool capitalise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization:
            capitalise ? TextCapitalization.characters : TextCapitalization.none,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
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

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking});

  final CustomerBooking booking;

  static const _statusColours = {
    'pending': Color(0xFFB26A00),
    'confirmed': Color(0xFF2E7BC4),
    'in_progress': Color(0xFF7A5FC7),
    'completed': Color(0xFF3E9142),
    'cancelled': Color(0xFF8A8A8A),
  };

  @override
  Widget build(BuildContext context) {
    final colour = _statusColours[booking.status] ?? AppColors.textSecondary;
    final amount = booking.finalAmount ?? booking.quotedAmount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.subcategoryName ?? 'Service booking',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: colour.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.statusDisplay,
                  style: TextStyle(fontSize: 11, color: colour, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            booking.reference,
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _Line(
            icon: Icons.person_outline,
            text: booking.providerName ?? 'Assigning a professional',
            muted: booking.providerName == null,
          ),
          _Line(
            icon: Icons.event_outlined,
            text: booking.scheduledDate == null
                ? 'Date to be confirmed${booking.slotDisplay.isEmpty ? '' : ' · ${booking.slotDisplay}'}'
                : '${_date(booking.scheduledDate!)}'
                    '${booking.slotDisplay.isEmpty ? '' : ' · ${booking.slotDisplay}'}',
          ),
          _Line(icon: Icons.location_on_outlined, text: booking.address),
          if (amount != null)
            _Line(
              icon: Icons.sell_outlined,
              text: '${booking.finalAmount != null ? 'Total' : 'Quoted'}: '
                  'NPR ${amount.toStringAsFixed(0)}',
            ),
        ],
      ),
    );
  }

  static String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, this.muted = false});

  final IconData icon;
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                fontStyle: muted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
