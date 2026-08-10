import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _role = 'client';
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .get();
      final role = doc.data()?['role'] ?? 'client';
      if (!mounted) return;
      if (role == 'driver') context.go('/driver');
      else if (role == 'admin') context.go('/admin');
      else context.go('/client');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_errMsg(e.code)),
        backgroundColor: AppTheme.error,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _errMsg(String code) {
    switch (code) {
      case 'user-not-found': return 'Aucun compte avec cet email.';
      case 'wrong-password': return 'Mot de passe incorrect.';
      case 'invalid-email': return 'Email invalide.';
      case 'user-disabled': return 'Compte suspendu.';
      default: return 'Erreur de connexion.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1565C0), AppTheme.primary, Color(0xFF42A5F5)],
          ),
        ),
        child: Stack(
          children: [
            // Vague du bas
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width, h * 0.55),
                painter: _WavePainter(),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: h * 0.05),

                    // Logo
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text('B',
                          style: TextStyle(
                            fontSize: 38, fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('BusWay Africa',
                      style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700,
                        color: Colors.white, letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Transport & Expédition',
                      style: TextStyle(
                        fontSize: 12, color: Colors.white.withOpacity(0.7),
                        letterSpacing: 2,
                      ),
                    ),

                    SizedBox(height: h * 0.05),

                    // Card formulaire
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Onglets
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  _tab('Client', 'client'),
                                  _tab('Chauffeur', 'driver'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Champ email
                            _field(
                              controller: _emailCtrl,
                              hint: 'Email ou téléphone',
                              icon: Icons.person_outline,
                              keyboard: TextInputType.emailAddress,
                              validator: (v) => v!.isEmpty ? 'Requis' : null,
                            ),
                            const SizedBox(height: 14),

                            // Champ mot de passe
                            _field(
                              controller: _passCtrl,
                              hint: 'Mot de passe',
                              icon: Icons.lock_outline,
                              obscure: _obscure,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.primary, size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              validator: (v) =>
                                  v!.length < 6 ? 'Min. 6 caractères' : null,
                            ),

                            // Mot de passe oublié
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text('Mot de passe oublié ?',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Bouton connexion
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 4,
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 22, height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppTheme.primary,
                                        ),
                                      )
                                    : const Text('Se connecter',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Inscription
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Pas de compte ?",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 13,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/register'),
                                  child: const Row(
                                    children: [
                                      Text("S'inscrire",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_ios,
                                        size: 12, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: h * 0.04),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, String value) {
    final selected = _role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6, offset: const Offset(0, 2))]
                : [],
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppTheme.primary : Colors.white,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 14,
          ),
        ),
      ),
    );
  }
}

// Peintre de vague
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.12);
    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.1,
      size.width * 0.5, size.height * 0.25,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.4,
      size.width, size.height * 0.2,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final paint2 = Paint()..color = Colors.white.withOpacity(0.08);
    final path2 = Path();
    path2.moveTo(0, size.height * 0.45);
    path2.quadraticBezierTo(
      size.width * 0.3, size.height * 0.25,
      size.width * 0.6, size.height * 0.4,
    );
    path2.quadraticBezierTo(
      size.width * 0.8, size.height * 0.5,
      size.width, size.height * 0.35,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(_) => false;
}