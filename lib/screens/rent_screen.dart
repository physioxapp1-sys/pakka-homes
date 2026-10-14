import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_scope.dart';
import '../data/product_models.dart' show formatNpr;
import '../data/rent_models.dart';
import '../data/rent_repository.dart';
import '../theme/app_colors.dart';
import 'auth_screen.dart';
import 'rent_forms.dart';

/// Rent: Dashboard, Properties, Rent & Payments, Contract.
///
/// The same four tabs serve the person who owns the flat and the person who
/// lives in it, because they are the same four questions asked from opposite
/// ends - how am I doing, which place, what money, what did we agree. Which
/// side someone is on is not a setting: owning a property makes you an owner,
/// being named on a live lease makes you a tenant, and a person can be both,
/// in which case they get a switch.
class RentScreen extends StatefulWidget {
  const RentScreen({super.key});

  @override
  State<RentScreen> createState() => _RentScreenState();
}

class _RentScreenState extends State<RentScreen> {
  final _repository = RentRepository();

  RentHome? _home;
  String? _error;
  bool _loadedForToken = false;

  /// Only ever shown to someone who is both. Otherwise it follows the facts.
  bool _asTenant = false;

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
      final home = await _repository.home(token);
      if (!mounted) return;
      setState(() {
        _home = home;
        // Someone who only rents starts on the tenant side; someone who only
        // lets starts on the owner side. Nobody has to find the switch.
        _asTenant = home.isTenant && !home.isOwner;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// The way out of the empty state.
  ///
  /// The tabs are not drawn until someone owns a property or is named on a
  /// lease, so the button that creates the first one has to live here - it is
  /// on the Properties tab too, but nobody in this state can reach that.
  Future<void> _addFirstProperty() async {
    final added = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
    );
    if (added != null && mounted) await _load();
  }

  Future<void> _signIn() async {
    final auth = AuthScope.of(context);
    final signedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          auth: auth,
          reason: 'Sign in to see your properties, rent and contracts.',
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
    final token = AuthScope.of(context).token;

    if (token == null) {
      return _Shell(child: _SignedOut(onSignIn: _signIn));
    }
    final home = _home;
    if (home == null) {
      return _Shell(
        child: _error == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.green))
            : _Message(
                icon: Icons.wifi_off_rounded,
                text: _error!,
                actionLabel: 'Try again',
                onAction: _load,
              ),
      );
    }
    final tenantSide = _asTenant && home.isTenant;
    // Someone who owns nothing has nothing of their own to list, so the
    // Properties tab shows what is going spare instead. That is also the one
    // thing in this section worth opening when you are neither - looking for
    // a flat needs no account at all, and hiding it behind a lease was wrong.
    final browsing = tenantSide || !home.isOwner;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          title: const Text('Rent'),
          actions: [
            if (home.isOwner && home.isTenant)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: () => setState(() => _asTenant = !_asTenant),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text(tenantSide ? 'Renting' : 'Letting',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.green),
                ),
              ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.green,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.green,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: [
              Tab(text: 'Dashboard'),
              Tab(text: 'Properties'),
              Tab(text: 'Rent & Payments'),
              Tab(text: 'Contract'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DashboardTab(
              home: home,
              asTenant: tenantSide,
              onRefresh: _load,
              onAddProperty: _addFirstProperty,
            ),
            _PropertiesTab(
              repository: _repository,
              browsing: browsing,
              canAdd: !tenantSide,
              onChanged: _load,
            ),
            _PaymentsTab(
              repository: _repository,
              asTenant: tenantSide,
              onChanged: _load,
              settled: !home.isNeither,
            ),
            _ContractTab(
              repository: _repository,
              asTenant: tenantSide,
              onChanged: _load,
              settled: !home.isNeither,
            ),
          ],
        ),
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Rent'),
      ),
      body: child,
    );
  }
}

// ---------------------------------------------------------------- dashboard

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.home,
    required this.asTenant,
    required this.onRefresh,
    required this.onAddProperty,
  });

  final RentHome home;
  final bool asTenant;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddProperty;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.green,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: home.isNeither
            ? _gettingStarted(context)
            : (asTenant
                ? _tenant(context, home.tenant!)
                : _owner(context, home.owner!)),
      ),
    );
  }

  /// Nothing to report yet, so the dashboard explains the two ways in rather
  /// than drawing zeroes.
  List<Widget> _gettingStarted(BuildContext context) => [
        const _StartCard(
          icon: Icons.vpn_key_outlined,
          tone: AppColors.green,
          tint: AppColors.tileGreen,
          title: 'You let a place out',
          body: 'Add your first property and the rest of this section comes to '
              'life - who is in it, what they owe, and the contract.',
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: _AddPropertyButton(onPressed: onAddProperty),
        ),
        const SizedBox(height: 16),
        const _StartCard(
          icon: Icons.person_outline,
          tone: AppColors.blue,
          tint: AppColors.tileBlue,
          title: 'You rent a place',
          body: 'Your landlord adds you to the tenancy, and your rent and '
              'contract turn up here by themselves. Make sure they have the '
              'number you signed in with.',
        ),
        const SizedBox(height: 16),
        const _StartCard(
          icon: Icons.search_rounded,
          tone: AppColors.orange,
          tint: AppColors.tileOrange,
          title: 'Still looking',
          body: 'Places going spare are on the Properties tab. No account '
              'needed to look.',
        ),
      ];

  List<Widget> _owner(BuildContext context, OwnerSummary s) {
    final outstanding = s.expectedThisMonth - s.collectedThisMonth;
    return [
      _BigCard(
        label: 'Collected this month',
        value: formatNpr(s.collectedThisMonth),
        sub: outstanding > 0
            ? '${formatNpr(outstanding)} still to come'
            : 'All in, nothing outstanding',
        tone: outstanding > 0 ? AppColors.orange : AppColors.green,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Occupied',
              value: '${s.occupied}',
              sub: 'of ${s.properties}',
              colour: AppColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Vacant',
              value: '${s.vacant}',
              sub: s.vacant == 0 ? 'all let' : 'to fill',
              colour: AppColors.blue,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _StatCard(
        label: 'Overdue',
        value: '${s.overdueCount}',
        sub: s.overdueCount == 0
            ? 'nobody is behind'
            : '${formatNpr(s.overdueAmount)} owed',
        colour: s.overdueCount == 0 ? AppColors.green : AppColors.emergencyRed,
        wide: true,
      ),
    ];
  }

  List<Widget> _tenant(BuildContext context, TenantSummary s) {
    final due = s.nextDue;
    return [
      _BigCard(
        label: due == null ? 'Rent' : 'Rent due ${_date(due.dueDate)}',
        value: formatNpr(due?.amount ?? s.contract.monthlyRent),
        sub: due == null
            ? 'Nothing outstanding - you are up to date'
            : (due.isOverdue ? 'Overdue' : 'Due soon'),
        tone: due == null
            ? AppColors.green
            : (due.isOverdue ? AppColors.emergencyRed : AppColors.orange),
      ),
      const SizedBox(height: 12),
      _Card(
        title: 'Where you live',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.contract.propertyTitle,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(s.contract.propertyAddress,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            _Detail(label: 'Rent', value: formatNpr(s.contract.monthlyRent)),
            _Detail(label: 'Due on', value: 'day ${s.contract.rentDueDay} of the month'),
            if (s.contract.ownerName != null)
              _Detail(label: 'Landlord', value: s.contract.ownerName!),
          ],
        ),
      ),
      if (s.unpaidCount > 1) ...[
        const SizedBox(height: 12),
        _Note(
          text: '${s.unpaidCount} months are outstanding. '
              'Check the Rent & Payments tab.',
          tone: AppColors.emergencyRed,
        ),
      ],
    ];
  }
}

// --------------------------------------------------------------- properties

class _PropertiesTab extends StatefulWidget {
  const _PropertiesTab({
    required this.repository,
    required this.browsing,
    required this.canAdd,
    required this.onChanged,
  });

  final RentRepository repository;

  /// Showing what is going spare, rather than the caller's own.
  final bool browsing;

  /// A renter has nothing to add; everyone else might.
  final bool canAdd;

  /// Adding a property or a tenant changes the dashboard too.
  final Future<void> Function() onChanged;

  @override
  State<_PropertiesTab> createState() => _PropertiesTabState();
}

class _PropertiesTabState extends State<_PropertiesTab> {
  List<RentProperty>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_PropertiesTab old) {
    super.didUpdateWidget(old);
    if (old.browsing != widget.browsing) _load();
  }

  Future<void> _load() async {
    setState(() {
      _rows = null;
      _error = null;
    });
    try {
      final rows = widget.browsing
          ? await widget.repository.listed()
          : await widget.repository.myProperties(AuthScope.of(context).token!);
      if (mounted) setState(() => _rows = rows);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _rows = const [];
          _error = e.message;
        });
      }
    }
  }

  Future<void> _addProperty() async {
    final added = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
    );
    if (added != null && mounted) {
      await _load();
      await widget.onChanged();
    }
  }

  Future<void> _addTenant(RentProperty property) async {
    final added = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddTenantScreen(property: property)),
    );
    if (added != null && mounted) {
      await _load();
      await widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tenant added, and this month\u2019s '
              'rent is on the Rent & Payments tab.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    if (rows == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }

    final body = rows.isEmpty
        ? _Message(
            icon: Icons.home_work_outlined,
            text: _error ??
                (widget.browsing
                    ? 'Nothing listed to rent just now. Pull down to check '
                        'again.'
                    : 'No properties yet. Add your first one and the rest of '
                        'this section comes to life.'),
            actionLabel: widget.browsing ? 'Refresh' : 'Add a property',
            onAction: widget.browsing ? _load : _addProperty,
          )
        : RefreshIndicator(
            onRefresh: _load,
            color: AppColors.green,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 16, 16, widget.canAdd ? 86 : 16),
              itemCount: rows.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                if (i == rows.length) return _ListNote(browsing: widget.browsing);
                return _PropertyCard(
                  property: rows[i],
                  browsing: widget.browsing,
                  onAddTenant: () => _addTenant(rows[i]),
                );
              },
            ),
          );

    if (!widget.canAdd) return body;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProperty,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add property'),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
    required this.browsing,
    this.onAddTenant,
  });

  final RentProperty property;

  /// Browsing for a place, rather than looking at one's own.
  final bool browsing;
  final VoidCallback? onAddTenant;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (property.imageUrl != null && property.imageUrl!.isNotEmpty)
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Image.network(
                property.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.tileBlue,
                  child: const Icon(Icons.home_rounded,
                      size: 40, color: AppColors.blue),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(property.title,
                          style: const TextStyle(
                              fontSize: 15.5, fontWeight: FontWeight.w800)),
                    ),
                    if (!browsing) _StateChip(property: property),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [property.address, property.city]
                      .where((s) => s.isNotEmpty)
                      .join(', '),
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    if (property.bedrooms > 0)
                      _Spec(icon: Icons.bed_outlined, text: '${property.bedrooms} bed'),
                    if (property.bathrooms > 0)
                      _Spec(
                          icon: Icons.bathtub_outlined,
                          text: '${property.bathrooms} bath'),
                    if (property.areaSqft != null)
                      _Spec(
                          icon: Icons.straighten_rounded,
                          text: '${property.areaSqft} sq ft'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('${formatNpr(property.monthlyRent)} / month',
                        style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy)),
                    const Spacer(),
                    if (!browsing && property.tenantName != null)
                      Text(property.tenantName!,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textSecondary)),
                  ],
                ),
                // An empty flat earns nothing, so the way out of that is on
                // the card rather than somewhere else.
                if (!browsing && !property.isOccupied && onAddTenant != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onAddTenant,
                      icon: const Icon(Icons.person_add_alt_1_outlined, size: 17),
                      label: const Text('Add a tenant'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.green,
                        side: const BorderSide(color: AppColors.green),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.property});

  final RentProperty property;

  @override
  Widget build(BuildContext context) {
    final (label, colour) = switch (property.rentState) {
      'paid' => ('Rent paid', AppColors.green),
      'overdue' => ('Overdue', AppColors.emergencyRed),
      'due' => ('Rent due', AppColors.orange),
      _ => property.isOccupied
          ? ('Occupied', AppColors.green)
          : ('Vacant', AppColors.blue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w700, color: colour)),
    );
  }
}

// ----------------------------------------------------------------- payments

class _PaymentsTab extends StatefulWidget {
  const _PaymentsTab({
    required this.repository,
    required this.asTenant,
    required this.onChanged,
    required this.settled,
  });

  final RentRepository repository;
  final bool asTenant;

  /// Whether the caller has a property or a lease at all. Empty means two
  /// different things, and they deserve two different sentences.
  final bool settled;

  /// Recording a payment changes the dashboard, so it reloads too.
  final Future<void> Function() onChanged;

  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  List<RentPayment>? _rows;
  String? _error;
  int? _recording;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_PaymentsTab old) {
    super.didUpdateWidget(old);
    if (old.asTenant != widget.asTenant) _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final rows = await widget.repository.payments(
        AuthScope.of(context).token!,
        asTenant: widget.asTenant,
      );
      if (mounted) setState(() => _rows = rows);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _rows = const [];
          _error = e.message;
        });
      }
    }
  }

  Future<void> _record(RentPayment payment) async {
    setState(() => _recording = payment.id);
    try {
      await widget.repository.recordPayment(
        payment.id,
        token: AuthScope.of(context).token!,
      );
      await _load();
      await widget.onChanged();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _recording = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    if (rows == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (rows.isEmpty) {
      return _Message(
        icon: Icons.receipt_long_outlined,
        text: _error ??
            (widget.settled
                ? 'No rent recorded yet. It appears here once a month is due.'
                : 'Rent shows up here once you have a property with someone in '
                    'it, or a landlord puts you on a tenancy.'),
        actionLabel: 'Refresh',
        onAction: _load,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.green,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _PaymentRow(
          payment: rows[i],
          // Only the person collecting the rent can say it arrived.
          canRecord: !widget.asTenant && !rows[i].isPaid,
          busy: _recording == rows[i].id,
          onRecord: () => _record(rows[i]),
          showTenant: !widget.asTenant,
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.canRecord,
    required this.busy,
    required this.onRecord,
    required this.showTenant,
  });

  final RentPayment payment;
  final bool canRecord;
  final bool busy;
  final VoidCallback onRecord;
  final bool showTenant;

  @override
  Widget build(BuildContext context) {
    final (label, colour) = switch (payment.state) {
      'paid' => ('Paid', AppColors.green),
      'overdue' => ('Overdue', AppColors.emergencyRed),
      _ => ('Due', AppColors.orange),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_month(payment.period),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: colour.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: colour)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (showTenant && payment.tenantName.isNotEmpty) payment.tenantName,
              if (payment.propertyTitle.isNotEmpty) payment.propertyTitle,
            ].join(' · '),
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(formatNpr(payment.amount),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  payment.isPaid
                      ? 'Paid ${_date(payment.paidOn)}'
                      : 'Due ${_date(payment.dueDate)}',
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ),
              if (canRecord)
                busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : OutlinedButton(
                        onPressed: onRecord,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(color: AppColors.green),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Mark received'),
                      ),
            ],
          ),
          if (payment.isPaid && payment.method.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              [payment.method, if (payment.reference.isNotEmpty) payment.reference]
                  .join(' · '),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- contract

class _ContractTab extends StatefulWidget {
  const _ContractTab({
    required this.repository,
    required this.asTenant,
    required this.onChanged,
    required this.settled,
  });

  final RentRepository repository;
  final bool asTenant;
  final Future<void> Function() onChanged;

  /// See the note on _PaymentsTab.settled.
  final bool settled;

  @override
  State<_ContractTab> createState() => _ContractTabState();
}

class _ContractTabState extends State<_ContractTab> {
  List<RentContract>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_ContractTab old) {
    super.didUpdateWidget(old);
    if (old.asTenant != widget.asTenant) _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final rows = await widget.repository.contracts(
        AuthScope.of(context).token!,
        asTenant: widget.asTenant,
      );
      if (mounted) setState(() => _rows = rows);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _rows = const [];
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    if (rows == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (rows.isEmpty) {
      return _Message(
        icon: Icons.description_outlined,
        text: _error ??
            (widget.settled
                ? 'No contracts yet. One appears when a tenancy starts.'
                : 'The agreement appears here once you let a place or rent '
                    'one.'),
        actionLabel: 'Refresh',
        onAction: _load,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.green,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _ContractCard(
          contract: rows[i],
          asTenant: widget.asTenant,
          onEnd: widget.asTenant ? null : () => _end(rows[i]),
        ),
      ),
    );
  }

  /// Ending a tenancy is asked about first: it is the kind of thing a thumb
  /// does by accident and a month of rent roll depends on.
  Future<void> _end(RentContract contract) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End this tenancy?'),
        content: Text(
          '${contract.tenantName} moves out of ${contract.propertyTitle}. '
          'The rent already recorded under this lease is kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.emergencyRed),
            child: const Text('End tenancy'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await widget.repository
          .endTenancy(contract.id, token: AuthScope.of(context).token!);
      await _load();
      await widget.onChanged();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({
    required this.contract,
    required this.asTenant,
    this.onEnd,
  });

  final RentContract contract;
  final bool asTenant;

  /// Null for a tenant, and for a lease that has already ended.
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: contract.propertyTitle,
      trailing: contract.statusDisplay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contract.propertyAddress.isNotEmpty) ...[
            Text(contract.propertyAddress,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
          ],
          _Detail(
            label: asTenant ? 'Landlord' : 'Tenant',
            value: asTenant
                ? (contract.ownerName ?? '-')
                : '${contract.tenantName}  ${contract.tenantPhone}',
          ),
          _Detail(
            label: 'Term',
            value: contract.endDate == null
                ? 'From ${_date(contract.startDate)}, rolling'
                : '${_date(contract.startDate)} to ${_date(contract.endDate)}',
          ),
          _Detail(label: 'Rent', value: '${formatNpr(contract.monthlyRent)} / month'),
          _Detail(label: 'Due on', value: 'day ${contract.rentDueDay}'),
          if (contract.deposit > 0)
            _Detail(label: 'Deposit', value: formatNpr(contract.deposit)),
          if (contract.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(contract.notes,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
          ],
          if (contract.documentUrl != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.attach_file_rounded,
                    size: 16, color: AppColors.green),
                const SizedBox(width: 6),
                // Shown rather than opened: opening a file needs url_launcher,
                // which the app does not carry yet.
                const Expanded(
                  child: Text('A signed copy is on file.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.green)),
                ),
              ],
            ),
          ],
          if (onEnd != null && contract.statusDisplay != 'Ended') ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onEnd,
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('Tenant moved out'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.emergencyRed,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- pieces

class _BigCard extends StatelessWidget {
  const _BigCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.tone,
  });

  final String label;
  final String value;
  final String sub;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFFBBD4EA))),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: tone),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(sub,
                    style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.colour,
    this.wide = false,
  });

  final String label;
  final String value;
  final String sub;
  final Color colour;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: colour)),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy)),
              ),
              if (trailing != null && trailing!.isNotEmpty)
                Text(trailing!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, required this.tone});

  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(fontSize: 13, color: tone)),
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.icon,
    required this.tone,
    required this.tint,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color tone;
  final Color tint;
  final String title;
  final String body;

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
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: tint),
                child: Icon(icon, size: 18, color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}

class _AddPropertyButton extends StatelessWidget {
  const _AddPropertyButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add a property',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// The line under a list that says what it is, so a renter does not wonder
/// why these three flats are the only ones in Kathmandu.
class _ListNote extends StatelessWidget {
  const _ListNote({required this.browsing});

  final bool browsing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        browsing
            ? 'These are the places Pakka Homes has free right now. Call us if '
                'none of them fit.'
            : 'Every property you let. Add a tenant to one and its rent starts '
                'showing under Rent & Payments.',
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 12, color: AppColors.textSecondary, height: 1.4),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary)),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
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
              const Text('Your properties and your rent',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 6),
              const Text(
                'Sign in to see what is let, what is due and what you agreed. '
                'Whether you own the place or live in it.',
                style: TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Sign in',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _date(DateTime? value) =>
    value == null ? '-' : '${value.day} ${_months[value.month - 1]} ${value.year}';

String _month(DateTime? value) =>
    value == null ? '-' : '${_months[value.month - 1]} ${value.year}';
