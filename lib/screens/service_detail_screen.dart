import 'package:flutter/material.dart';

import '../data/catalog_models.dart';
import '../data/service_cart.dart';
import '../theme/app_colors.dart';
import 'service_cart_screen.dart';

/// What one service is, what it costs, and a button to add it.
///
/// The price shown is whatever the catalog holds. Where a service is quoted
/// after a visit the catalog says so rather than inventing a number, and this
/// screen repeats that plainly - a made-up figure on a cleaner's time is worse
/// than no figure.
class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({
    super.key,
    required this.service,
    required this.categorySlug,
    required this.categoryName,
  });

  final RemoteSubcategory service;
  final String categorySlug;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final cart = ServiceCartScope.of(context);
    final inCart = cart.contains(categorySlug, service.slug);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            // Square, like the product hero: the artwork is drawn roughly
            // that shape and a letterboxed photo looks like a mistake.
            expandedHeight: _heroHeight(context),
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.navy,
            actions: [_CartButton(cart: cart)],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.tilePurple,
                child: _Photo(url: service.imageUrl),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(categoryName.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.purple)),
                  const SizedBox(height: 6),
                  Text(service.name,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy)),
                  const SizedBox(height: 12),
                  _Price(service: service),
                  const SizedBox(height: 18),
                  if (service.description.isNotEmpty) ...[
                    const _Heading('About this service'),
                    Text(service.description,
                        style: const TextStyle(fontSize: 14, height: 1.5)),
                    const SizedBox(height: 18),
                  ],
                  const _Heading('How it works'),
                  const _Step(
                    number: '1',
                    text: 'Add the services you need. One person can usually '
                        'cover several.',
                  ),
                  const _Step(
                    number: '2',
                    text: 'Tell us how often you need them and which times '
                        'suit you.',
                  ),
                  const _Step(
                    number: '3',
                    text: 'We call to confirm, agree the price, and send '
                        'someone we know.',
                  ),
                  const SizedBox(height: 18),
                  const _Heading('Good to know'),
                  const _Bullet('Everyone we send is known to us and works '
                      'under Pakka Homes.'),
                  const _Bullet('Nothing is charged through the app - you '
                      'settle after the work.'),
                  const _Bullet('Change or cancel by calling us, any time '
                      'before the visit.'),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: inCart
                      ? OutlinedButton.icon(
                          onPressed: () =>
                              cart.remove(categorySlug, service.slug),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Added - tap to remove'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.green,
                            side: const BorderSide(color: AppColors.green),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () =>
                              cart.add(service, categorySlug: categorySlug),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Add to cart',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                ),
              ),
              if (!cart.isEmpty) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ServiceCartScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Cart · ${cart.count}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _heroHeight(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > 420 ? 300 : width * 0.72;
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.service});

  final RemoteSubcategory service;

  @override
  Widget build(BuildContext context) {
    final quoted = service.isQuoteOnly;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: quoted ? AppColors.background : AppColors.tileGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(quoted ? Icons.request_quote_outlined : Icons.sell_outlined,
              size: 20, color: quoted ? AppColors.navy : AppColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.displayRate,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: quoted ? AppColors.navy : AppColors.green)),
                const SizedBox(height: 2),
                Text(
                  quoted
                      ? 'Priced once we know the hours and the household.'
                      : 'Agreed before anyone starts.',
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.tilePurple,
      child: const Center(
        child: Icon(Icons.cleaning_services_rounded,
            size: 54, color: AppColors.purple),
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : Container(color: const Color(0xFFF1F6FA)),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.cart});

  final ServiceCart cart;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServiceCartScreen()),
          ),
        ),
        if (!cart.isEmpty)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${cart.count}',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy)),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 22,
            width: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.tileGreen,
            ),
            child: Text(number,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13.5, height: 1.45)),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 5, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13.5, height: 1.45, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
