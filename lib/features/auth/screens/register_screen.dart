import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'client';
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'uid': cred.user!.uid,
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'role': _role,
        'status': _role == 'driver' ? 'pending' : 'active',
        'createdAt': FieldValue.serverTimestamp(),
        if (_role == 'driver') ...{
          'documents': {
            'permis': '',
            'carteGrise': '',
            'photoId': '',
          },
          'rating': 0.0,
          'totalTrips': 0,
          'revenue': 0,
        }
      });
      if (!mounted) return;
      if (_role == 'driver') {
        _showPendingDialog();
      } else {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        context.go('/login');
      }
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

  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFfaeeda),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.access_time,
                  color: Color(0xFF633806), size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Compte en attente',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              "Votre dossier est en cours d'examen. "
              'Vous serez notifié sous 24-48h.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _docRow('Permis de conduire'),
            _docRow('Carte grise'),
            _docRow('Photo ID'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                  elevation: 0,
                ),
                child: const Text('Compris',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _docRow(String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.check_circle,
                color: Color(0xFF085041), size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(fontSize: 13)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFe1f5ee),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('✓ Reçu',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF085041))),
            ),
          ],
        ),
      );

  String _errMsg(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email déjà utilisé.';
      case 'weak-password':
        return 'Mot de passe trop faible.';
      case 'invalid-email':
        return 'Email invalide.';
      default:
        return "Erreur d'inscription.";
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
            colors: [
              Color(0xFF1565C0),
              AppTheme.primary,
              Color(0xFF42A5F5),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Vagues décoratives
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomPaint(
                size: Size(
                    MediaQuery.of(context).size.width, h * 0.5),
                painter: _WavePainter(),
              ),
            ),

            // Cercles décoratifs
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: h * 0.02),

                    // Bouton retour
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: h * 0.02),

                    // Logo
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                        ),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                          child: const Center(
                            child: Text('B',
                                style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Text('Créer un compte',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text('Rejoignez BusWay Africa',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 1)),

                    SizedBox(height: h * 0.03),

                    // Formulaire
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Onglets Client / Chauffeur
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  _tab('Client', 'client'),
                                  _tab('Chauffeur', 'driver'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Champs
                            _field(
                              controller: _nameCtrl,
                              hint: 'Nom complet',
                              icon: Icons.person_outline,
                              validator: (v) =>
                                  v!.isEmpty ? 'Requis' : null,
                            ),
                            const SizedBox(height: 12),
                            _field(
                              controller: _phoneCtrl,
                              hint: '+229 97 XX XX XX',
                              icon: Icons.phone_outlined,
                              keyboard: TextInputType.phone,
                              validator: (v) =>
                                  v!.isEmpty ? 'Requis' : null,
                            ),
                            const SizedBox(height: 12),
                            _field(
                              controller: _emailCtrl,
                              hint: 'Email',
                              icon: Icons.email_outlined,
                              keyboard:
                                  TextInputType.emailAddress,
                              validator: (v) =>
                                  v!.isEmpty ? 'Requis' : null,
                            ),
                            const SizedBox(height: 12),
                            _field(
                              controller: _passCtrl,
                              hint: 'Mot de passe',
                              icon: Icons.lock_outline,
                              obscure: _obscure,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons
                                          .visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscure = !_obscure),
                              ),
                              validator: (v) => v!.length < 6
                                  ? 'Min. 6 caractères'
                                  : null,
                            ),

                            // Section documents chauffeur
                            if (_role == 'driver') ...[
                              const SizedBox(height: 16),
                              Container(
                                padding:
                                    const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons
                                                .folder_outlined,
                                            color: Colors.white,
                                            size: 18),
                                        const SizedBox(width: 8),
                                        const Text(
                                            'Documents requis',
                                            style: TextStyle(
                                                color:
                                                    Colors.white,
                                                fontWeight:
                                                    FontWeight
                                                        .w600,
                                                fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _docUpload(
                                        'Permis de conduire',
                                        Icons.badge_outlined),
                                    const SizedBox(height: 8),
                                    _docUpload(
                                        'Carte grise',
                                        Icons
                                            .directions_car_outlined),
                                    const SizedBox(height: 8),
                                    _docUpload('Photo ID',
                                        Icons.person_outlined),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding:
                                    const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.white,
                                        size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Compte activé après validation par un administrateur.',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            // Bouton créer compte
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed:
                                    _loading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor:
                                      AppTheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            26),
                                  ),
                                  elevation: 4,
                                  shadowColor: Colors.black
                                      .withOpacity(0.2),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppTheme.primary,
                                        ),
                                      )
                                    : const Text(
                                        'Créer mon compte',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                                FontWeight.w700),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Lien connexion
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text('Déjà un compte ?',
                                    style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.85),
                                        fontSize: 13)),
                                TextButton(
                                  onPressed: () =>
                                      context.go('/login'),
                                  child: const Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      Text('Se connecter',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.w700,
                                              fontSize: 13)),
                                      SizedBox(width: 4),
                                      Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: Colors.white),
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
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  selected ? AppTheme.primary : Colors.white,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _docUpload(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black87)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F1FB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.upload_outlined,
                    size: 13, color: AppTheme.primary),
                SizedBox(width: 4),
                Text('Upload',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary)),
              ],
            ),
          ),
        ],
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
            blurRadius: 10,
            offset: const Offset(0, 4),
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
          hintStyle: TextStyle(
              color: Colors.grey[400], fontSize: 13),
          prefixIcon:
              Icon(icon, color: AppTheme.primary, size: 20),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = Colors.white.withOpacity(0.1);
    final path1 = Path();
    path1.moveTo(0, size.height * 0.35);
    path1.quadraticBezierTo(size.width * 0.25,
        size.height * 0.15, size.width * 0.5, size.height * 0.3);
    path1.quadraticBezierTo(size.width * 0.75,
        size.height * 0.45, size.width, size.height * 0.25);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, p1);

    final p2 = Paint()..color = Colors.white.withOpacity(0.07);
    final path2 = Path();
    path2.moveTo(0, size.height * 0.5);
    path2.quadraticBezierTo(size.width * 0.3,
        size.height * 0.3, size.width * 0.6, size.height * 0.45);
    path2.quadraticBezierTo(size.width * 0.8,
        size.height * 0.55, size.width, size.height * 0.4);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, p2);

    final p3 = Paint()..color = Colors.white.withOpacity(0.04);
    final path3 = Path();
    path3.moveTo(0, size.height * 0.65);
    path3.quadraticBezierTo(size.width * 0.4,
        size.height * 0.48, size.width * 0.7, size.height * 0.6);
    path3.quadraticBezierTo(size.width * 0.85,
        size.height * 0.68, size.width, size.height * 0.55);
    path3.lineTo(size.width, size.height);
    path3.lineTo(0, size.height);
    path3.close();
    canvas.drawPath(path3, p3);
  }

  @override
  bool shouldRepaint(_) => false;
}