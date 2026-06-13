import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/offers/presentation/screens/offer_detail_screen.dart';
import '../../features/offers/presentation/screens/create_offer_screen.dart';
import '../../features/applications/presentation/screens/offer_applications_screen.dart';
import '../../features/admin/presentation/screens/admin_list_screen.dart';

/// Petit pont entre Riverpod et go_router :
/// go_router se rafraîchit (et ré-évalue `redirect`) chaque fois que
/// l'état d'authentification change, grâce à ce [Listenable].
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this._ref) {
    // On écoute les changements d'authentification (connexion / déconnexion).
    _sub = _ref.listen<AuthState>(
      authProvider,
      (prev, next) {
        if (prev?.isAuthenticated != next.isAuthenticated) {
          notifyListeners();
        }
      },
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

/// Fournit l'instance unique de [GoRouter] de l'application.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refresh,
    redirect: (context, state) {
      final isAuth = ref.read(authProvider).isAuthenticated;
      final loc = state.matchedLocation;
      final goingToAuth = loc == '/login' || loc == '/register';

      // Non connecté : on force le retour vers /login (sauf si on y va déjà).
      if (!isAuth && !goingToAuth) return '/login';

      // Déjà connecté : inutile de revoir login/register → on renvoie à l'accueil.
      if (isAuth && goingToAuth) return '/home';

      return null; // aucune redirection
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: '/offers/create',
        builder: (context, state) => const CreateOfferScreen(),
      ),
      // ⚠️ Cette route doit être déclarée AVANT '/offer/:id' n'est pas concernée
      // car les chemins diffèrent (/offers/... vs /offer/...). On garde l'ordre clair.
      GoRoute(
        path: '/offers/:id/applications',
        builder: (context, state) {
          final offerId = state.pathParameters['id']!;
          final title = (state.extra as String?) ?? 'Candidatures';
          return OfferApplicationsScreen(offerId: offerId, offerTitle: title);
        },
      ),
      GoRoute(
        path: '/offer/:id',
        builder: (context, state) {
          final offerId = state.pathParameters['id']!;
          return OfferDetailScreen(offerId: offerId);
        },
      ),
      GoRoute(
        path: '/admin/list/:type',
        builder: (context, state) {
          final typeStr = state.pathParameters['type']!;
          final type = AdminListType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => AdminListType.users,
          );
          return AdminListScreen(type: type);
        },
      ),
    ],
  );
});
