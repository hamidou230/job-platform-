import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';

void main() {
  runApp(const ProviderScope(child: JobPlatformApp()));
}

/// Au démarrage, on restaure la session (token stocké de façon sécurisée)
/// AVANT de laisser le routeur décider de la première page à afficher.
/// Tant que ce Future n'est pas terminé, on montre un écran de démarrage.
final appStartupProvider = FutureProvider<void>((ref) async {
  await ref.read(authProvider.notifier).restoreSession();
});

class JobPlatformApp extends ConsumerWidget {
  const JobPlatformApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(appStartupProvider);

    return startup.when(
      // Restauration de session en cours → splash.
      loading: () => const _SplashApp(),
      // En cas d'erreur improbable, on démarre quand même l'app (l'utilisateur
      // sera simplement renvoyé vers l'écran de connexion par le routeur).
      error: (_, __) => const _RouterApp(),
      data: (_) => const _RouterApp(),
    );
  }
}

/// L'application principale, une fois la session restaurée.
class _RouterApp extends ConsumerWidget {
  const _RouterApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'JobStage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      // Application en français.
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

/// Écran de démarrage minimaliste affiché pendant la restauration de session.
class _SplashApp extends StatelessWidget {
  const _SplashApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.work_outline_rounded, size: 72),
              SizedBox(height: 16),
              Text(
                'JobStage',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
