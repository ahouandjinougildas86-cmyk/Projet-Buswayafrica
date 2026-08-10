import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userName = '';
  String _userInitial = 'U';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        final name = doc.data()?['name'] ?? 'Utilisateur';
        setState(() {
          _userName = name.split(' ').first;
          _userInitial = name.isNotEmpty
              ? name[0].toUpperCase()
              : 'U';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _userName = 'Utilisateur';
          _userInitial = 'U';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _TrajetsPage(
            userName: _userName,
            userInitial: _userInitial,
          ),
          const _ColisPage(),
          const _BilletsPage(),
          _ProfilPage(
            userName: _userName,
            userInitial: _userInitial,
          ),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, 'Accueil'),
              _navItem(
                  1, Icons.inventory_2_outlined, 'Colis'),
              _navItem(2,
                  Icons.confirmation_number_outlined, 'Billets'),
              _navItem(
                  3, Icons.person_outline_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected
                    ? AppTheme.primary
                    : Colors.grey[400],
                size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected
                      ? AppTheme.primary
                      : Colors.grey[400],
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}

// ===================== PAGE TRAJETS =====================
class _TrajetsPage extends StatelessWidget {
  final String userName;
  final String userInitial;
  const _TrajetsPage(
      {required this.userName, required this.userInitial});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header gradient
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1565C0),
                  AppTheme.primary,
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salutation + avatar
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('Bonjour 👋',
                            style: TextStyle(
                                color:
                                    Colors.white.withOpacity(0.8),
                                fontSize: 13)),
                        Text(
                          userName.isEmpty
                              ? 'Bienvenue'
                              : userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1.5),
                      ),
                      child: Center(
                        child: Text(userInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Barre de recherche
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text('Chercher un trajet...',
                          style: TextStyle(
                              color:
                                  Colors.white.withOpacity(0.7),
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Titre + compteur
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Trajets disponibles',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('trajets')
                      .where('status', isEqualTo: 'active')
                      .snapshots(),
                  builder: (_, snap) {
                    final count =
                        snap.data?.docs.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary
                            .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text('$count disponibles',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Liste trajets Firestore
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('trajets')
              .where('status', isEqualTo: 'active')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primary),
                  ),
                ),
              );
            }

            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.directions_bus_outlined,
                          size: 64,
                          color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Aucun trajet disponible',
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(
                          'Les trajets apparaîtront ici\ndès qu\'un chauffeur les publie.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12)),
                    ],
                  ),
                ),
              );
            }

            final trajets = snapshot.data!.docs;
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final data = trajets[index].data()
                        as Map<String, dynamic>;
                    return _TrajetCard(
                      trajetId: trajets[index].id,
                      data: data,
                    );
                  },
                  childCount: trajets.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ===================== CARD TRAJET =====================
class _TrajetCard extends StatelessWidget {
  final String trajetId;
  final Map<String, dynamic> data;
  const _TrajetCard(
      {required this.trajetId, required this.data});

  @override
  Widget build(BuildContext context) {
    final places = data['availableSeats'] ?? 0;
    final prix = data['price'] ?? 0;
    final chauffeur = data['driverName'] ?? 'Chauffeur';
    final rating =
        (data['driverRating'] ?? 0.0).toDouble();
    final depart = data['departure'] ?? '';
    final arrivee = data['destination'] ?? '';
    final hDepart = data['departureTime'] ?? '--:--';
    final hArrivee = data['arrivalTime'] ?? '--:--';

    Color placesColor = const Color(0xFF085041);
    Color placesBg = const Color(0xFFe1f5ee);
    if (places <= 3) {
      placesColor = const Color(0xFF791f1f);
      placesBg = const Color(0xFFfcebeb);
    } else if (places <= 8) {
      placesColor = const Color(0xFF633806);
      placesBg = const Color(0xFFfaeeda);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre colorée top
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1565C0),
                  AppTheme.primary,
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Départ → Arrivée
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(hDepart,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87)),
                          Text(depart,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppTheme.primary,
                            size: 22),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: const Text('Direct',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.primary,
                                  fontWeight:
                                      FontWeight.w500)),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Text(hArrivee,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87)),
                          Text(arrivee,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(color: Colors.grey[100], height: 1),
                const SizedBox(height: 10),

                // Chauffeur + places + prix
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary
                            .withOpacity(0.1),
                      ),
                      child: Center(
                        child: Text(
                          chauffeur.isNotEmpty
                              ? chauffeur[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(chauffeur,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFBA7517),
                                  size: 14),
                              Text(' $rating',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFBA7517),
                                      fontWeight:
                                          FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Places
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: placesBg,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text('$places places',
                          style: TextStyle(
                              fontSize: 11,
                              color: placesColor,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 10),
                    // Prix
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        Text('$prix F',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary)),
                        const Text('CFA',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bouton réserver
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => context.go(
                      '/booking',
                      extra: {
                        'trajetId': trajetId,
                        'data': data,
                      },
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_number_outlined,
                            size: 18),
                        SizedBox(width: 8),
                        Text('Réserver maintenant',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== PAGE COLIS =====================
class _ColisPage extends StatelessWidget {
  const _ColisPage();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), AppTheme.primary],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding:
                const EdgeInsets.fromLTRB(20, 52, 20, 24),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expédier un colis',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                SizedBox(height: 4),
                Text('Confiez votre colis à un chauffeur',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _inputField('Description du colis',
                    Icons.inventory_2_outlined,
                    hint: 'Ex: Vêtements 3kg'),
                const SizedBox(height: 14),
                _inputField('Destination',
                    Icons.location_on_outlined,
                    hint: 'Ex: Parakou'),
                const SizedBox(height: 14),
                _inputField(
                    'Téléphone destinataire',
                    Icons.phone_outlined,
                    hint: '+229 96 XX XX XX'),
                const SizedBox(height: 20),

                // Chauffeur dispo
                const Text('Chauffeur disponible',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.primary, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary
                              .withOpacity(0.1),
                        ),
                        child: const Center(
                          child: Text('KA',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('Koffi Amos · 06:00',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Row(
                              children: const [
                                Icon(Icons.star_rounded,
                                    color: Color(0xFFBA7517),
                                    size: 13),
                                Text(' 4.9',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            Color(0xFFBA7517))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Text('500 F',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14)),
                    ),
                    child: const Text('Envoyer le colis',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(height: 28),
                const Text('Suivi en temps réel',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _suiviColis(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _inputField(String label, IconData icon,
      {String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: Colors.grey[400], fontSize: 13),
              prefixIcon:
                  Icon(icon, color: AppTheme.primary, size: 20),
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
        ),
      ],
    );
  }

  Widget _suiviColis() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('#COL-20250611-0012',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFfaeeda),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('En transit',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF633806),
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _suiviStep('Collecté', 'Cotonou · 08:00',
              AppTheme.primary, true),
          _suiviLine(),
          _suiviStep('En route', 'km 180',
              const Color(0xFFBA7517), true),
          _suiviLine(),
          _suiviStep('Livré', 'Parakou (en attente)',
              Colors.grey[300]!, false),
        ],
      ),
    );
  }

  Widget _suiviStep(
      String title, String sub, Color color, bool done) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: done
                        ? Colors.black87
                        : Colors.grey[400])),
            Text(sub,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ],
    );
  }

  Widget _suiviLine() {
    return Container(
      margin: const EdgeInsets.only(left: 5),
      width: 2, height: 20,
      color: Colors.grey[200],
    );
  }
}

// ===================== PAGE BILLETS =====================
class _BilletsPage extends StatelessWidget {
  const _BilletsPage();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), AppTheme.primary],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding:
                const EdgeInsets.fromLTRB(20, 52, 20, 24),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mes billets',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                SizedBox(height: 4),
                Text('Vos réservations et historique',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70)),
              ],
            ),
          ),
        ),
        if (uid == null)
          const SliverToBoxAdapter(
            child: Center(child: Text('Non connecté')),
          )
        else
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reservations')
                .where('clientId', isEqualTo: uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary)),
                  ),
                );
              }
              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                            Icons
                                .confirmation_number_outlined,
                            size: 64,
                            color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('Aucune réservation',
                            style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final d = snapshot.data!.docs[i]
                          .data() as Map<String, dynamic>;
                      return _BilletCard(data: d);
                    },
                    childCount:
                        snapshot.data!.docs.length,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _BilletCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BilletCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), AppTheme.primary],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${data['departure'] ?? ''} → ${data['destination'] ?? ''}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data['status'] == 'confirmed'
                        ? 'Confirmé'
                        : 'En attente',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('Départ',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey)),
                        Text(
                          data['departureTime'] ?? '--:--',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const Icon(Icons.directions_bus,
                        color: AppTheme.primary, size: 28),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        const Text('Arrivée',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey)),
                        Text(
                          data['arrivalTime'] ?? '--:--',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                ),
                Divider(color: Colors.grey[100], height: 20),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['driverName'] ?? 'Chauffeur',
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12),
                        ),
                        Text(
                          'Siège ${data['seat'] ?? '?'} · ${data['price'] ?? 0} FCFA',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const Icon(Icons.qr_code_2,
                        color: AppTheme.primary, size: 36),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== PAGE PROFIL =====================
class _ProfilPage extends StatefulWidget {
  final String userName;
  final String userInitial;
  const _ProfilPage(
      {required this.userName, required this.userInitial});

  @override
  State<_ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<_ProfilPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      _nameCtrl.text = doc.data()?['name'] ?? '';
      _phoneCtrl.text = doc.data()?['phone'] ?? '';
      setState(() {});
    } catch (_) {}
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
    });
    setState(() => _editing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profil mis à jour !'),
          backgroundColor: Color(0xFF085041),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), AppTheme.primary],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding:
                const EdgeInsets.fromLTRB(20, 52, 20, 30),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(
                        color: Colors.white, width: 2.5),
                  ),
                  child: Center(
                    child: Text(widget.userInitial,
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(widget.userName,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Client',
                      style: TextStyle(
                          fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Infos
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Informations personnelles',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _editing = !_editing),
                      icon: Icon(
                          _editing ? Icons.close : Icons.edit,
                          size: 16),
                      label: Text(_editing
                          ? 'Annuler'
                          : 'Modifier'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _profilField('Nom complet',
                    Icons.person_outline, _nameCtrl, _editing),
                const SizedBox(height: 12),
                _profilField('Téléphone', Icons.phone_outlined,
                    _phoneCtrl, _editing),
                const SizedBox(height: 12),
                _profilField(
                    'Email',
                    Icons.email_outlined,
                    TextEditingController(
                        text: FirebaseAuth.instance
                                .currentUser?.email ??
                            ''),
                    false),
                if (_editing) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14)),
                      ),
                      child: const Text('Enregistrer',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Déconnexion
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        context.go('/');
                      }
                    },
                    icon: const Icon(Icons.logout,
                        color: Colors.red),
                    label: const Text('Se déconnecter',
                        style:
                            TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _profilField(String label, IconData icon,
      TextEditingController ctrl, bool enabled) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: Colors.grey[500], fontSize: 12),
          prefixIcon:
              Icon(icon, color: AppTheme.primary, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: enabled
              ? Colors.white
              : Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }
}