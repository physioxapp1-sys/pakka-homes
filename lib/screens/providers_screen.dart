import 'package:flutter/material.dart';

import '../data/provider_models.dart';
import '../data/provider_repository.dart';
import '../theme/app_colors.dart';
import 'booking_screen.dart';

/// Who can do the job the customer just picked.
///
/// NOT in the customer flow. Booking goes straight from a subcategory to the
/// booking form, and dispatch assigns someone afterwards - we sell the job,
/// not an introduction to a tradesperson.
///
/// Kept because that decision is worth being able to reverse: re-linking this
/// from SubcategoryScreen restores "choose your pro". Doing so also needs
/// /api/v1/providers/ opened up again, which is staff-only now.
class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({
    super.key,
    required this.categoryName,
    required this.categorySlug,
    required this.vertical,
    this.subcategoryName,
    this.subcategorySlug,
  });

  final String categoryName;
  final String categorySlug;
  final String vertical;

  /// Only known once the catalog is imported; the list is by category either way.
  final String? subcategoryName;
  final String? subcategorySlug;

  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  final _repository = ProviderRepository();

  List<ServiceProvider>? _providers;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _providers = null;
      _error = null;
    });
    try {
      final rows = await _repository.forCategory(
        categorySlug: widget.categorySlug,
        vertical: widget.vertical,
      );
      if (mounted) setState(() => _providers = rows);
    } catch (e) {
      if (mounted) {
        setState(() {
          _providers = const [];
          _error = 'Could not load providers. Check your connection.';
        });
      }
    }
  }

  void _book(ServiceProvider provider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          title: widget.subcategoryName ?? widget.categoryName,
          categorySlug: widget.categorySlug,
          subcategorySlug: widget.subcategorySlug,
          providerSlug: provider.slug,
          providerName: provider.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(widget.subcategoryName ?? widget.categoryName),
      ),
      body: RefreshIndicator(onRefresh: _load, child: _body()),
    );
  }

  Widget _body() {
    final providers = _providers;
    if (providers == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (providers.isEmpty) {
      return _EmptyState(message: _error ?? 'No providers listed here yet.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: providers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ProviderCard(
        provider: providers[i],
        onBook: () => _book(providers[i]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    // Must scroll for RefreshIndicator to let the user pull to retry.
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      children: [
        const Icon(Icons.engineering_outlined, size: 48, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.onBook});

  final ServiceProvider provider;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFE9EEF3),
                backgroundImage:
                    provider.photoUrl != null ? NetworkImage(provider.photoUrl!) : null,
                child: provider.photoUrl == null
                    ? const Icon(Icons.person, color: AppColors.textSecondary, size: 28)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (provider.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 15, color: AppColors.primary),
                        ],
                      ],
                    ),
                    Text(
                      provider.tradeDisplay,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (provider.serviceArea.isNotEmpty)
                          _MetaLine(
                            icon: Icons.location_on_outlined,
                            text: provider.serviceArea,
                          ),
                        _MetaLine(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFF5A623),
                          text: '${provider.rating} (${provider.reviewCount})',
                        ),
                        if (provider.experienceYears > 0)
                          _MetaLine(
                            icon: Icons.work_outline_rounded,
                            text: '${provider.experienceYears} yrs',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (provider.isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Available today',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF3E9142),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                provider.displayRate,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: provider.isQuoteOnly
                      ? AppColors.textSecondary
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text(
                  provider.isQuoteOnly ? 'Get quote' : 'Book Now',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text, this.iconColor});

  final IconData icon;
  final String text;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor ?? AppColors.textSecondary),
        const SizedBox(width: 2),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
