import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/admin_stats.dart';
import '../../data/admin_repository.dart';
import '../../../../core/network/paginated.dart';
import '../../../../core/network/api_client.dart';

enum AdminListType { users, students, companies, offers, openOffers, applications }

extension AdminListTypeExt on AdminListType {
  String get title {
    switch (this) {
      case AdminListType.users: return 'Utilisateurs';
      case AdminListType.students: return 'Étudiants';
      case AdminListType.companies: return 'Entreprises';
      case AdminListType.offers: return 'Toutes les offres';
      case AdminListType.openOffers: return 'Offres ouvertes';
      case AdminListType.applications: return 'Candidatures';
    }
  }
}

class AdminListScreen extends ConsumerStatefulWidget {
  final AdminListType type;
  const AdminListScreen({super.key, required this.type});

  @override
  ConsumerState<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends ConsumerState<AdminListScreen> {
  final List<dynamic> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetch();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        _fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool reset = false}) async {
    if (_loading) return;
    if (reset) {
      setState(() { _items.clear(); _page = 1; _hasMore = true; _error = null; });
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final dio = ref.read(apiClientProvider).dio;
      List<dynamic> newItems = [];

      switch (widget.type) {
        case AdminListType.users:
          final r = await repo.users(page: _page);
          newItems = r.data; _hasMore = r.hasNextPage;
        case AdminListType.students:
          final r = await repo.users(page: _page, role: 'STUDENT');
          newItems = r.data; _hasMore = r.hasNextPage;
        case AdminListType.companies:
          final r = await repo.users(page: _page, role: 'COMPANY');
          newItems = r.data; _hasMore = r.hasNextPage;
        case AdminListType.offers:
        case AdminListType.openOffers:
          final params = {
            'page': _page, 'limit': 20,
            if (widget.type == AdminListType.openOffers) 'status': 'OPEN',
          };
          final res = await dio.get('/offers', queryParameters: params);
          final p = Paginated.fromJson(res.data, (j) => _OfferItem.fromJson(j));
          newItems = p.data; _hasMore = p.hasNextPage;
        case AdminListType.applications:
          final r = await repo.applications(page: _page);
          newItems = r.data; _hasMore = r.hasNextPage;
      }

      setState(() { _items.addAll(newItems); _page++; });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _fetchMore() {
    if (!_loading && _hasMore) _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.type.title)),
      body: RefreshIndicator(
        onRefresh: () => _fetch(reset: true),
        child: _error != null && _items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => _fetch(reset: true),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
            : _items.isEmpty && !_loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, size: 72, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text('Aucun élément', style: theme.textTheme.titleMedium),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _items.length + (_hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final item = _items[i];
                      if (item is AdminUser) return _UserTile(user: item);
                      if (item is AdminApplication) return _ApplicationTile(app: item);
                      if (item is _OfferItem) return _OfferTile(offer: item);
                      return const SizedBox.shrink();
                    },
                  ),
      ),
    );
  }
}

// ── Tuile utilisateur ──────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final AdminUser user;
  const _UserTile({required this.user});

  String _roleLabel(String r) {
    switch (r) {
      case 'STUDENT': return 'Étudiant';
      case 'COMPANY': return 'Entreprise';
      case 'ADMIN': return 'Admin';
      default: return r;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? cs.primaryContainer : cs.errorContainer,
          child: Icon(
            user.isActive ? Icons.person : Icons.person_off,
            color: user.isActive ? cs.onPrimaryContainer : cs.onErrorContainer,
          ),
        ),
        title: Text(user.name ?? user.email, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${_roleLabel(user.role)} • ${user.email}'),
        trailing: Chip(
          label: Text(user.isActive ? 'Actif' : 'Inactif', style: const TextStyle(fontSize: 11)),
          backgroundColor: user.isActive
              ? Colors.green.withValues(alpha: 0.15)
              : cs.errorContainer,
          side: BorderSide.none,
        ),
      ),
    );
  }
}

// ── Tuile offre ───────────────────────────────────────────────────
class _OfferItem {
  final String id;
  final String title;
  final String companyName;
  final String status;
  final String type;

  const _OfferItem({
    required this.id,
    required this.title,
    required this.companyName,
    required this.status,
    required this.type,
  });

  factory _OfferItem.fromJson(Map<String, dynamic> j) {
    final company = j['company'] as Map<String, dynamic>? ?? {};
    return _OfferItem(
      id: j['id'],
      title: j['title'] ?? '',
      companyName: company['name'] ?? '',
      status: j['status'] ?? '',
      type: j['type'] ?? '',
    );
  }
}

class _OfferTile extends StatelessWidget {
  final _OfferItem offer;
  const _OfferTile({required this.offer});

  Color _statusColor(BuildContext context, String s) {
    switch (s) {
      case 'OPEN': return Colors.green;
      case 'CLOSED': return Theme.of(context).colorScheme.error;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'OPEN': return 'Ouverte';
      case 'CLOSED': return 'Fermée';
      case 'DRAFT': return 'Brouillon';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, offer.status);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.work_outline, color: color),
        ),
        title: Text(offer.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(offer.companyName),
        trailing: Chip(
          label: Text(_statusLabel(offer.status), style: const TextStyle(fontSize: 11)),
          backgroundColor: color.withValues(alpha: 0.15),
          side: BorderSide.none,
        ),
      ),
    );
  }
}

// ── Tuile candidature ─────────────────────────────────────────────
class _ApplicationTile extends StatelessWidget {
  final AdminApplication app;
  const _ApplicationTile({required this.app});

  Color _statusColor(BuildContext context, String s) {
    switch (s) {
      case 'ACCEPTED': return Colors.green;
      case 'REJECTED': return Theme.of(context).colorScheme.error;
      case 'REVIEWED': return Colors.orange;
      default: return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, app.status);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            app.studentName.isNotEmpty ? app.studentName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(app.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${app.offerTitle} • ${app.companyName}'),
        trailing: Chip(
          label: Text(app.statusLabel, style: const TextStyle(fontSize: 11)),
          backgroundColor: color.withValues(alpha: 0.15),
          side: BorderSide.none,
        ),
      ),
    );
  }
}
