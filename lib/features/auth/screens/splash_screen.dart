import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _btnCtrl;

  late Animation<double> _scale;
  late Animation<double> _rotate;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;
  late Animation<double> _btnFade;
  late Animation<double> _btnSlide;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _rotate = Tween<double>(begin: -0.3, end: 0.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn),
    );
    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );
    _btnFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn),
    );
    _btnSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut),
    );

    // Cascade d'animations
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _logoCtrl.forward().then((_) {
        if (!mounted) return;
        _textCtrl.forward().then((_) {
          if (!mounted) return;
          _btnCtrl.forward();
        });
      });
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1565C0),
              AppTheme.primary,
              Color(0xFF42A5F5),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Vagues
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: CustomPaint(
                size: Size(size.width, size.height * 0.45),
                painter: _SplashWavePainter(),
              ),
            ),

            // Cercles décoratifs
            Positioned(
              top: -60, right: -60,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              top: 40, right: -30,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: size.height * 0.25, left: -40,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            // Contenu
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo animé
                  AnimatedBuilder(
                    animation: _logoCtrl,
                    builder: (_, __) => FadeTransition(
                      opacity: _logoFade,
                      child: Transform.rotate(
                        angle: _rotate.value,
                        child: ScaleTransition(
                          scale: _scale,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 115, height: 115,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white
                                      .withValues(alpha: 0.08),
                                  border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              Container(
                                width: 90, height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white
                                      .withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              Container(
                                width: 70, height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white
                                      .withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Text('B',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Texte animé
                  AnimatedBuilder(
                    animation: _textCtrl,
                    builder: (_, child) => FadeTransition(
                      opacity: _textFade,
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: child,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text('BusWay',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('A  F  R  I  C  A',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white
                                .withValues(alpha: 0.75),
                            letterSpacing: 6,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Transport & Expédition',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white
                                  .withValues(alpha: 0.9),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Boutons animés
                  AnimatedBuilder(
                    animation: _btnCtrl,
                    builder: (_, child) => FadeTransition(
                      opacity: _btnFade,
                      child: Transform.translate(
                        offset: Offset(0, _btnSlide.value),
                        child: child,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () =>
                                  context.go('/login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor:
                                    AppTheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(26),
                                ),
                                elevation: 6,
                                shadowColor: Colors.black
                                    .withValues(alpha: 0.25),
                              ),
                              child: const Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () =>
                                  context.go('/register'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                    color: Colors.white,
                                    width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(26),
                                ),
                              ),
                              child: const Text(
                                'Créer un compte',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.1);
    final path1 = Path();
    path1.moveTo(0, size.height * 0.35);
    path1.quadraticBezierTo(
        size.width * 0.25, size.height * 0.15,
        size.width * 0.5, size.height * 0.28);
    path1.quadraticBezierTo(
        size.width * 0.75, size.height * 0.42,
        size.width, size.height * 0.22);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, p1);

    final p2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.07);
    final path2 = Path();
    path2.moveTo(0, size.height * 0.5);
    path2.quadraticBezierTo(
        size.width * 0.3, size.height * 0.3,
        size.width * 0.55, size.height * 0.44);
    path2.quadraticBezierTo(
        size.width * 0.8, size.height * 0.55,
        size.width, size.height * 0.38);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, p2);

    final p3 = Paint()
      ..color = Colors.white.withValues(alpha: 0.04);
    final path3 = Path();
    path3.moveTo(0, size.height * 0.65);
    path3.quadraticBezierTo(
        size.width * 0.4, size.height * 0.48,
        size.width * 0.7, size.height * 0.6);
    path3.quadraticBezierTo(
        size.width * 0.88, size.height * 0.68,
        size.width, size.height * 0.55);
    path3.lineTo(size.width, size.height);
    path3.lineTo(0, size.height);
    path3.close();
    canvas.drawPath(path3, p3);
  }

  @override
  bool shouldRepaint(_) => false;
}