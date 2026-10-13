import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_scope.dart';
import '../data/order_models.dart';
import '../data/order_repository.dart';
import '../data/product_models.dart';
import '../theme/app_colors.dart';
import 'auth_screen.dart';
import 'my_bookings_screen.dart';
import 'order_track_screen.dart';

/// The Orders tab: grocery deliveries and service bookings.
///
/// They are separate lists because they are separate things on the backend -
/// an order has a delivery slot and a basket, a booking has a site visit.
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          title: const Text('My orders'),
          bottom: const TabBar(
            labelColor: AppColors.green,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.green,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: [
              Tab(text: 'Grocery'),
              Tab(text: 'Services'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GroceryOrders(),
            MyBookingsScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}

class _GroceryOrders extends StatefulWidget {
  const _GroceryOrders();

  @override
  State<_GroceryOrders> createState() => _GroceryOrdersState();
}

class _GroceryOrdersState extends State<_GroceryOrders> {
  final _repository = OrderRepository();

  List<CustomerOrder>? _orders;
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
      if (mounted) setState(() => _orders = rows);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _orders = const [];
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
          reason: 'Sign in to see every order placed with your number.',
        ),
      ),
    );
    if (signedIn == true && mounted) {
      _loadedForToken = true;
      await _load();
    }
  }

  void _openLookup() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OrderLookupScreen()),
      );

  @override
  Widget build(BuildContext context) {
    if (!AuthScope.of(context).isSignedIn) {
      // Not a wall: orders can be placed as a guest, so a reference lookup
      // sits beside the sign-in offer.
      return _GuestPrompt(onSignIn: _signIn, onLookup: _openLookup);
    }

    final orders = _orders;
    if (orders == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppColors.green,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 70),
          children: [
            const Icon(Icons.shopping_bag_outlined,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              _error ??
                  'No grocery orders yet. What you order from the shop shows '
                      'up here.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _openLookup,
                child: const Text('Track an order by reference'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.green,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => OrderCard(order: orders[i]),
      ),
    );
  }
}

class _GuestPrompt extends StatelessWidget {
  const _GuestPrompt({required this.onSignIn, required this.onLookup});

  final VoidCallback onSignIn;
  final VoidCallback onLookup;

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
                'See all your orders',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sign in and every order placed with your number appears here, '
                'with your saved addresses at checkout.',
                style: TextStyle(
                    color: Colors.white70, fontSize: 12.5, height: 1.3),
              ),
              const SizedBox(height: 12),
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
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or track one order',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onLookup,
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Track with a reference',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ),
      ],
    );
  }
}

/// One order in the list. Tapping it opens the tracking screen.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final quantity = order.items.fold<int>(0, (sum, i) => sum + i.quantity);

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderTrackScreen(order: order)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                  child: Text(order.reference,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          letterSpacing: 0.4)),
                ),
                _StatusChip(order: order),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$quantity ${quantity == 1 ? 'item' : 'items'}'
              '${order.items.isEmpty ? '' : ' · ${order.items.first.name}'
                  '${order.items.length > 1 ? ' and ${order.items.length - 1} more' : ''}'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(order.deliveryAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                ),
                Text(formatNpr(order.total),
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final colour = switch (order.status) {
      'delivered' => AppColors.green,
      'cancelled' => AppColors.emergencyRed,
      'out_for_delivery' => AppColors.orange,
      _ => AppColors.blue,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(order.statusDisplay,
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w700, color: colour)),
    );
  }
}
