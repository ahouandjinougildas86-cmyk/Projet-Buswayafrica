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
          final extra =
              state.extra as Map<String, dynamic>;
          return BookingScreen(
            trajetId: extra['trajetId'],
            data: extra['data'],
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