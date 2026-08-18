import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart'
    hide _WavePainter;
import '../../features/auth/screens/register_screen.dart'
    hide _WavePainter;
import '../../features/client/screens/home_screen.dart';
import '../../features/client/screens/booking_screen.dart';
import '../../features/driver/screens/driver_home_screen.dart';
import '../../features/admin/screens/admin_home_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/client',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) {
          final extra = state.extra;

          // Si l'utilisateur arrive ici sans données (rechargement de page,
          // lien direct, hot restart en cours sur cette URL...), on le
          // renvoie vers l'accueil au lieu de planter avec un TypeError.
          if (extra == null || extra is! Map<String, dynamic>) {
            return const _BookingRedirect();
          }

          final trajetId = extra['trajetId'];
          final data = extra['data'];

          if (trajetId == null || data == null) {
            return const _BookingRedirect();
          }

          return BookingScreen(
            trajetId: trajetId,
            data: data,
          );
        },
      ),
      GoRoute(
        path: '/driver',
        builder: (_, __) => const DriverHomeScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminHomeScreen(),
      ),
    ],
  );
}

// Écran affiché quand /booking est atteint sans les données nécessaires
// (rechargement de page, lien direct...). Pas de redirection automatique :
// ça évite un conflit avec le Navigator pendant une transition en cours.
class _BookingRedirect extends StatelessWidget {
  const _BookingRedirect();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Informations de trajet introuvables.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Retourne à l\'accueil et sélectionne à nouveau un trajet.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/client'),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}