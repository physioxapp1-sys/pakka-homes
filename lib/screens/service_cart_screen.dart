import 'package:flutter/material.dart';

import '../data/service_cart.dart';
import '../theme/app_colors.dart';
import 'booking_screen.dart';

/// Everything picked, before the one booking that covers it.
///
/// There is no total. Services are quoted on what the household needs - hours,
/// rooms, how many people - and adding up four "On request" lines would be
/// arithmetic on nothing. The booking that follows is where the price gets
/// agreed, which is what the last line here says.
class ServiceCartScreen extends StatelessWidget {
  const ServiceCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = ServiceCartScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.navy,
        title: const Text('Your services',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, cart),
              child: const Text('Clear'),
            ),
        ],
      ),
      body: cart.isEmpty ? const _Empty() : _Body(cart: cart),
      bottomNavigationBar: cart.isEmpty ? null : _ContinueBar(cart: cart),
    );
  }

  Future<void> _confirmClear(BuildContext context, ServiceCart cart) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove everything?'),
        content: const Text('Your picked services will be cleared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.emergencyRed),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (yes == true) cart.clear();
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.cart});

  final ServiceCart cart;

  @override
  Widget build(BuildContext context) {
    final lines = cart.lines;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: lines.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == lines.length) return const _Reassurance();
        final line = lines[i];
        return _ServiceRow(
          line: line,
          onRemove: () => cart.remove(line.categorySlug, line.service.slug),
        );
      },
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.line, required this.onRemove});

  final ServiceLine line;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final service = line.service;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 56,
              child: _Thumb(url: service.imageUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(service.displayRate,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: service.isQuoteOnly
                            ? AppColors.textSecondary
                            : AppColors.green)),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 19),
            color: AppColors.textSecondary,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.tilePurple,
      child: const Icon(Icons.cleaning_services_rounded,
          size: 22, color: AppColors.purple),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return Image.network(url!,
        fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder);
  }
}

class _Reassurance extends StatelessWidget {
  const _Reassurance();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tileGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.green),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nothing is charged now. Tell us when you need help and we will '
              'call to agree the price before anyone starts.',
              style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.green),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                size: 50, color: AppColors.textSecondary),
            const SizedBox(height: 14),
            const Text('Nothing picked yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy)),
            const SizedBox(height: 8),
            const Text(
              'Add the help you need and it collects here, ready to book in '
              'one go.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Browse services'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({required this.cart});

  final ServiceCart cart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => _book(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${cart.count} service${cart.count == 1 ? '' : 's'}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Row(
                  children: [
                    Text('Book them',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _book(BuildContext context) async {
    final names = cart.names();
    final confirmation = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          title: names.length == 1 ? names.first : 'Home help',
          categorySlug: cart.commonCategory,
          subcategorySlugs: cart.slugs(),
          serviceNames: names,
          // These are people, not jobs: how often and when are the questions
          // that decide who gets sent.
          asksEngagement: true,
        ),
      ),
    );
    if (confirmation == null || !context.mounted) return;
    // Booked, so the cart has done its job.
    cart.clear();
    Navigator.of(context).pop();
  }
}
