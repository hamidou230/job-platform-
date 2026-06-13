import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/offers_providers.dart';
import '../widgets/offer_card.dart';
import '../widgets/filter_sheet.dart';
import '../../data/offers_repository.dart';

/// Liste des offres : barre de recherche, filtres, pagination (scroll infini),
/// pull-to-refresh et gestion d'erreur.
class OffersListScreen extends ConsumerStatefulWidget {
  const OffersListScreen({super.key});
  @override
  ConsumerState<OffersListScreen> createState() => _OffersListScreenState();
}

class _OffersListScreenState extends ConsumerState<OffersListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Chargement initial après le 1er frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(offersProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(offersProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(offersProvider.notifier).search(value.trim());
    });
  }

  Future<void> _openFilters() async {
    final current = ref.read(offersProvider).filters;
    final result = await showModalBottomSheet<OfferFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FilterSheet(initial: current),
    );
    if (result != null) {
      ref.read(offersProvider.notifier).applyFilters(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(offersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offres'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un poste, une compétence...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(offersProvider.notifier).search('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: state.filters.hasActiveFilters,
                  child: IconButton.filledTonal(
                    icon: const Icon(Icons.tune),
                    onPressed: _openFilters,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(offersProvider.notifier).refresh(),
        child: _buildBody(state, theme),
      ),
    );
  }

  Widget _buildBody(OffersListState state, ThemeData theme) {
    if (state.isLoading && state.offers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.offers.isEmpty) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => ref.read(offersProvider.notifier).refresh(),
      );
    }
    if (state.offers.isEmpty) {
      return _EmptyView(
        icon: Icons.search_off,
        title: 'Aucune offre trouvée',
        subtitle: 'Essayez de modifier votre recherche ou vos filtres.',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: state.offers.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.offers.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OfferCard(offer: state.offers[index]),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyView({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 72, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.cloud_off, size: 72, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(message,
              textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ),
      ],
    );
  }
}
