import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
          _userInitial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
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
          _TrajetsPage(userName: _userName, userInitial: _userInitial),
          const _ColisPage(),
          const _BilletsPage(),
          _ProfilPage(userName: _userName, userInitial: _userInitial),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, 'Accueil'),
              _navItem(1, Icons.inventory_2_outlined, 'Colis'),
              _navItem(2, Icons.confirmation_number_outlined, 'Billets'),
              _navItem(3, Icons.person_outline_rounded, 'Profil'),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? AppTheme.primary : Colors.grey[400], size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? AppTheme.primary : Colors.grey[400],
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
  const _TrajetsPage({required this.userName, required this.userInitial});

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
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bonjour 👋',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                        Text(
                          userName.isEmpty ? 'Bienvenue' : userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                      ),
                      child: Center(
                        child: Text(userInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            )),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text('Chercher un trajet...',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Trajets disponibles',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('trajets')
                      .where('status', isEqualTo: 'active')
                      .snapshots(),
                  builder: (_, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$count disponibles',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('trajets')
              .where('status', isEqualTo: 'active')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.directions_bus_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Aucun trajet disponible',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('Les trajets apparaîtront ici\ndès qu\'un chauffeur les publie.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                ),
              );
            }

            final trajets = snapshot.data!.docs;
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final data = trajets[index].data() as Map<String, dynamic>;
                    return _TrajetCard(trajetId: trajets[index].id, data: data);
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
  const _TrajetCard({required this.trajetId, required this.data});

  @override
  Widget build(BuildContext context) {
    final places = data['availableSeats'] ?? 0;
    final prix = data['price'] ?? 0;
    final chauffeur = data['driverName'] ?? 'Chauffeur';
    final rating = (data['driverRating'] ?? 0.0).toDouble();
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
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1565C0), AppTheme.primary]),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hDepart,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
                          Text(depart, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        const Icon(Icons.arrow_forward_rounded, color: AppTheme.primary, size: 22),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Direct',
                              style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(hArrivee,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
                          Text(arrivee,
                              textAlign: TextAlign.end, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey[100], height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.1)),
                      child: Center(
                        child: Text(
                          chauffeur.isNotEmpty ? chauffeur[0].toUpperCase() : 'C',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(chauffeur, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFBA7517), size: 14),
                              Text(' $rating',
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFFBA7517), fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: placesBg, borderRadius: BorderRadius.circular(20)),
                      child: Text('$places places',
                          style: TextStyle(fontSize: 11, color: placesColor, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$prix F',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                        const Text('CFA', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => context.go('/booking', extra: {'trajetId': trajetId, 'data': data}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_number_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Réserver maintenant', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
class _ColisPage extends StatefulWidget {
  const _ColisPage();

  @override
  State<_ColisPage> createState() => _ColisPageState();
}

class _ColisPageState extends State<_ColisPage> {
  final _descriptionCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  String? _selectedDestination;
  num _calculatedPrice = 0;

  String? _selectedDriverId;
  String? _selectedDriverName;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyerColis() async {
    if (_descriptionCtrl.text.trim().isEmpty ||
        _selectedDestination == null ||
        _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Veuillez remplir tous les champs.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Veuillez choisir un chauffeur.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('Utilisateur non connecté.');
      }

      final id = 'COL-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';

      final description = _descriptionCtrl.text.trim();
      final destination = _selectedDestination!;
      final recipientPhone = _phoneCtrl.text.trim();
      final driverId = _selectedDriverId!;
      final driverName = _selectedDriverName ?? 'Chauffeur';
      final price = _calculatedPrice;

      await FirebaseFirestore.instance
          .collection('expeditions')
          .doc(id)
          .set({
            'id': id,
            'userId': uid,
            'description': description,
            'destination': destination,
            'recipientPhone': recipientPhone,
            'driverId': driverId,
            'driverName': driverName,
            'price': price,
            'status': 'En attente',
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              throw Exception('Délai dépassé. Vérifiez votre connexion Internet.');
            },
          );

      if (!mounted) return;

      _descriptionCtrl.clear();
      _phoneCtrl.clear();
      setState(() {
        _selectedDestination = null;
        _calculatedPrice = 0;
        _selectedDriverId = null;
        _selectedDriverName = null;
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ColisTicketScreen(
            colisId: id,
            description: description,
            destination: destination,
            recipientPhone: recipientPhone,
            driverName: driverName,
            driverId: driverId,
            price: price,
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur Firebase (${e.code}) : ${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur : ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expédier un colis',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                SizedBox(height: 4),
                Text('Confiez votre colis à un chauffeur',
                    style: TextStyle(fontSize: 13, color: Colors.white70)),
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
                _inputField('Description du colis', Icons.inventory_2_outlined,
                    controller: _descriptionCtrl, hint: 'Ex: Vêtements 3kg'),
                const SizedBox(height: 14),

                // ---- DESTINATION : liste déroulante branchée sur la grille tarifaire ----
                const Text('Destination',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
                const SizedBox(height: 6),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('colisTarifs').orderBy('price').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Erreur de chargement des tarifs : ${snapshot.error}',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      );
                    }

                    final tarifs = snapshot.data?.docs ?? [];

                    if (tarifs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                        child: const Text(
                          'Aucune grille tarifaire configurée. Ajoute des villes dans la collection "colisTarifs".',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedDestination,
                          hint: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Choisir une ville', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ),
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.keyboard_arrow_down, color: AppTheme.primary),
                          ),
                          items: tarifs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final price = (data['price'] ?? 0) as num;
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(doc.id, style: const TextStyle(fontSize: 13)),
                                    Text('${price.toInt()} F',
                                        style: const TextStyle(
                                            fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            final doc = tarifs.firstWhere((d) => d.id == value);
                            final data = doc.data() as Map<String, dynamic>;
                            setState(() {
                              _selectedDestination = value;
                              _calculatedPrice = (data['price'] ?? 0) as num;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),

                if (_selectedDestination != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tarif estimé', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        Text('${_calculatedPrice.toInt()} FCFA',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                _inputField('Téléphone destinataire', Icons.phone_outlined,
                    controller: _phoneCtrl, hint: '+229 96 XX XX XX', keyboardType: TextInputType.phone),
                const SizedBox(height: 20),

                // ---- LISTE DES CHAUFFEURS ----
                const Text('Choisir un chauffeur',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'driver')
                      .where('status', isEqualTo: 'active')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Erreur de chargement des chauffeurs : ${snapshot.error}',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      );
                    }

                    final drivers = snapshot.data?.docs ?? [];

                    if (drivers.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey[400]),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text('Aucun chauffeur disponible pour le moment.',
                                  style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: drivers.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final driverId = doc.id;
                        final name = data['name'] ?? 'Chauffeur';
                        final rating = (data['driverRating'] ?? 4.8).toDouble();
                        final isSelected = _selectedDriverId == driverId;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DriverCard(
                            name: name,
                            rating: rating,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedDriverId = driverId;
                                _selectedDriverName = name;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _envoyerColis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Envoyer le colis',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _inputField(String label, IconData icon,
      {required TextEditingController controller, String hint = '', TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ===================== CARTE CHAUFFEUR SÉLECTIONNABLE =====================
class _DriverCard extends StatelessWidget {
  final String name;
  final double rating;
  final bool isSelected;
  final VoidCallback onTap;

  const _DriverCard({
    required this.name,
    required this.rating,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.1)),
              child: Center(
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFBA7517), size: 13),
                      Text(' $rating', style: const TextStyle(fontSize: 11, color: Color(0xFFBA7517))),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppTheme.primary : Colors.grey[300],
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}


// ===================== BILLET / TICKET DE COLIS =====================
class ColisTicketScreen extends StatelessWidget {
  final String colisId;
  final String description;
  final String destination;
  final String recipientPhone;
  final String driverName;
  final String driverId;
  final num price;

  const ColisTicketScreen({
    super.key,
    required this.colisId,
    required this.description,
    required this.destination,
    required this.recipientPhone,
    required this.driverName,
    required this.driverId,
    required this.price,
  });

  String get _qrData => 'BUSWAY-COLIS|$colisId|$destination|$recipientPhone';

  static const List<String> _etapes = ['En attente', 'Collecté', 'En route', 'Livré'];

  Future<void> _telechargerPdf(BuildContext context, String currentStatus) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          build: (pw.Context ctx) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('BUSWAY AFRICA',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text('Billet de colis', style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 12),
                  pw.Divider(),
                  pw.SizedBox(height: 12),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: _qrData,
                    width: 140,
                    height: 140,
                  ),
                  pw.SizedBox(height: 16),
                  _pdfRow('N° de suivi', colisId),
                  _pdfRow('Description', description),
                  _pdfRow('Destination', destination),
                  _pdfRow('Téléphone destinataire', recipientPhone),
                  _pdfRow('Chauffeur', driverName),
                  _pdfRow('Prix', '${price.toInt()} FCFA'),
                  _pdfRow('Statut', currentStatus),
                  pw.SizedBox(height: 16),
                  pw.Divider(),
                  pw.Text(
                    'Présentez ce billet (ou le QR code) au chauffeur.',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'billet_colis_$colisId.pdf');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la génération du PDF : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 11)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Billet du colis'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('expeditions').doc(colisId).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final currentStatus = data?['status'] ?? 'En attente';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF085041), size: 64),
                        const SizedBox(height: 12),
                        const Text('Colis enregistré !',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('N° de suivi : $colisId', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 20),
                        QrImageView(data: _qrData, version: QrVersions.auto, size: 180.0),
                        const SizedBox(height: 20),
                        _detailRow('Description', description),
                        _detailRow('Destination', destination),
                        _detailRow('Téléphone destinataire', recipientPhone),
                        _detailRow('Chauffeur', driverName),
                        _detailRow('Prix', '${price.toInt()} FCFA', isBold: true),
                        _detailRow('Statut', currentStatus, isBold: true),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: () => _telechargerPdf(context, currentStatus),
                                  icon: const Icon(Icons.download_outlined, size: 18),
                                  label: const Text('Télécharger'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primary,
                                    side: const BorderSide(color: AppTheme.primary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Terminer',
                                      style: TextStyle(fontSize: 16, color: Colors.white)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Suivi en temps réel',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        _buildStepper(currentStatus),
                      ],
                    ),
                  ),
                ),

                // Bouton d'annulation, visible uniquement tant que le colis
                // n'a pas encore été pris en charge par le chauffeur.
                if (currentStatus == 'En attente') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _annulerColis(context),
                      icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                      label: const Text('Annuler ce colis', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],

                // Notation du chauffeur, visible uniquement une fois le colis livré.
                if (currentStatus == 'Livré') ...[
                  const SizedBox(height: 16),
                  _RatingCard(
                    colisId: colisId,
                    driverId: driverId,
                    existingRating: (data?['clientRating'] as num?)?.toInt(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _annulerColis(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler ce colis ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, annuler', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('expeditions')
          .doc(colisId)
          .update({'status': 'Annulé'});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Colis annulé.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStepper(String currentStatus) {
    final currentIndex = _etapes.indexOf(currentStatus);
    final effectiveIndex = currentIndex == -1 ? 0 : currentIndex;

    return Column(
      children: List.generate(_etapes.length, (i) {
        final done = i <= effectiveIndex;
        final isLast = i == _etapes.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppTheme.primary : Colors.grey[300],
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 32,
                    color: i < effectiveIndex ? AppTheme.primary : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 20),
              child: Text(
                _etapes[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                  color: done ? Colors.black87 : Colors.grey[400],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14),
          ),
        ],
      ),
    );
  }
}

// ===================== CARTE DE NOTATION DU CHAUFFEUR =====================
// Affichée uniquement quand le colis est livré. Écrit la note sur le
// document du colis (clientRating) ET met à jour la moyenne du chauffeur
// (driverRating / driverRatingCount) via une transaction Firestore.
class _RatingCard extends StatefulWidget {
  final String colisId;
  final String driverId;
  final int? existingRating;

  const _RatingCard({
    required this.colisId,
    required this.driverId,
    required this.existingRating,
  });

  @override
  State<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<_RatingCard> {
  int _selectedStars = 0;
  bool _submitting = false;

  Future<void> _envoyerNote() async {
    if (_selectedStars == 0) return;
    setState(() => _submitting = true);

    try {
      final expeditionRef = FirebaseFirestore.instance.collection('expeditions').doc(widget.colisId);
      final driverRef = FirebaseFirestore.instance.collection('users').doc(widget.driverId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final driverSnap = await transaction.get(driverRef);
        final oldAvg = ((driverSnap.data()?['driverRating'] ?? 0) as num).toDouble();
        final oldCount = (driverSnap.data()?['driverRatingCount'] ?? 0) as int;
        final newCount = oldCount + 1;
        final newAvg = ((oldAvg * oldCount) + _selectedStars) / newCount;

        transaction.update(expeditionRef, {'clientRating': _selectedStars});
        transaction.update(driverRef, {
          'driverRating': double.parse(newAvg.toStringAsFixed(2)),
          'driverRatingCount': newCount,
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Merci pour votre note !'), backgroundColor: Color(0xFF085041)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Déjà noté : on affiche juste le résultat, en lecture seule.
    if (widget.existingRating != null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Votre note', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < widget.existingRating! ? Icons.star_rounded : Icons.star_border_rounded,
                    color: const Color(0xFFBA7517),
                    size: 28,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text('Merci d\'avoir noté ce chauffeur.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notez votre chauffeur', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Comment s\'est passée la livraison ?',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                return IconButton(
                  onPressed: _submitting ? null : () => setState(() => _selectedStars = starIndex),
                  icon: Icon(
                    starIndex <= _selectedStars ? Icons.star_rounded : Icons.star_border_rounded,
                    color: const Color(0xFFBA7517),
                    size: 34,
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: (_selectedStars == 0 || _submitting) ? null : _envoyerNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Envoyer la note', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== PAGE BILLETS (TRAJETS + COLIS) =====================
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
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mes billets', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                SizedBox(height: 4),
                Text('Vos réservations et colis', style: TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
        ),
        if (uid == null)
          const SliverToBoxAdapter(child: Center(child: Text('Non connecté')))
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Trajets', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey[700])),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reservations')
                .where('clientId', isEqualTo: uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    child: Text('Aucune réservation de trajet', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final doc = snapshot.data!.docs[i];
                      final d = doc.data() as Map<String, dynamic>;
                      return _BilletCard(reservationId: doc.id, data: d);
                    },
                    childCount: snapshot.data!.docs.length,
                  ),
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Colis', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey[700])),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('expeditions')
                .where('userId', isEqualTo: uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                  ),
                );
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    child: Text(
                      'Erreur de chargement des colis : ${snapshot.error}\n\n'
                      'Si le message mentionne un index Firestore manquant, ouvre la console '
                      'du navigateur (F12) pour trouver le lien de création automatique.',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    child: Text('Aucun colis envoyé', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final doc = snapshot.data!.docs[i];
                      final d = doc.data() as Map<String, dynamic>;
                      return _ColisBilletCard(colisId: doc.id, data: d);
                    },
                    childCount: snapshot.data!.docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _BilletCard extends StatelessWidget {
  final String reservationId;
  final Map<String, dynamic> data;
  const _BilletCard({required this.reservationId, required this.data});

  bool get _isCancelled => data['status'] == 'cancelled';

  Future<void> _annulerReservation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la réservation ?'),
        content: const Text('Vos places seront libérées. Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, annuler', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final trajetId = data['trajetId'] as String?;
      final nbPlaces = (data['nbPlaces'] ?? 1) as num;
      final reservationRef = FirebaseFirestore.instance.collection('reservations').doc(reservationId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        if (trajetId != null) {
          final trajetRef = FirebaseFirestore.instance.collection('trajets').doc(trajetId);
          final trajetSnap = await transaction.get(trajetRef);
          if (trajetSnap.exists) {
            final currentSeats = (trajetSnap.data()?['availableSeats'] ?? 0) as num;
            transaction.update(trajetRef, {'availableSeats': currentSeats + nbPlaces});
          }
        }
        transaction.update(reservationRef, {'status': 'cancelled'});
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Réservation annulée.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: _isCancelled
                  ? null
                  : const LinearGradient(colors: [Color(0xFF1565C0), AppTheme.primary]),
              color: _isCancelled ? Colors.grey[400] : null,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${data['departure'] ?? ''} → ${data['destination'] ?? ''}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    _isCancelled ? 'Annulée' : (data['status'] == 'confirmed' ? 'Confirmé' : 'En attente'),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Départ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(data['departureTime'] ?? '--:--',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const Icon(Icons.directions_bus, color: AppTheme.primary, size: 28),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Arrivée', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(data['arrivalTime'] ?? '--:--',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
                Divider(color: Colors.grey[100], height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['driverName'] ?? 'Chauffeur',
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                        Text(
                          'Siège ${data['seat'] ?? '?'} · ${data['price'] ?? 0} FCFA',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const Icon(Icons.qr_code_2, color: AppTheme.primary, size: 36),
                  ],
                ),
                if (!_isCancelled) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () => _annulerReservation(context),
                      icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                      label: const Text('Annuler', style: TextStyle(color: Colors.red, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== CARTE COLIS DANS "MES BILLETS" =====================
class _ColisBilletCard extends StatelessWidget {
  final String colisId;
  final Map<String, dynamic> data;
  const _ColisBilletCard({required this.colisId, required this.data});

  bool get _isEnAttente => (data['status'] ?? 'En attente') == 'En attente';

  Future<void> _annulerColis(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler ce colis ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, annuler', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('expeditions').doc(colisId).update({'status': 'Annulé'});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Colis annulé.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'En attente';
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ColisTicketScreen(
              colisId: colisId,
              description: data['description'] ?? '',
              destination: data['destination'] ?? '',
              recipientPhone: data['recipientPhone'] ?? '',
              driverName: data['driverName'] ?? 'Chauffeur',
              driverId: data['driverId'] ?? '',
              price: (data['price'] ?? 0) as num,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1565C0), AppTheme.primary]),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Colis → ${data['destination'] ?? ''}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                    child: Text(status,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['description'] ?? 'Colis',
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                        Text(
                          '${data['driverName'] ?? 'Chauffeur'} · ${data['price'] ?? 0} FCFA',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.qr_code_2, color: AppTheme.primary, size: 36),
                ],
              ),
            ),
            if (_isEnAttente)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () => _annulerColis(context),
                    icon: const Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
                    label: const Text('Annuler', style: TextStyle(color: Colors.red, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ===================== PAGE PROFIL =====================
class _ProfilPage extends StatefulWidget {
  final String userName;
  final String userInitial;
  const _ProfilPage({required this.userName, required this.userInitial});

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
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      _nameCtrl.text = doc.data()?['name'] ?? '';
      _phoneCtrl.text = doc.data()?['phone'] ?? '';
      setState(() {});
    } catch (_) {}
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
    });
    setState(() => _editing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profil mis à jour !'), backgroundColor: Color(0xFF085041)),
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
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 30),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: Center(
                    child: Text(widget.userInitial,
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(widget.userName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Client', style: TextStyle(fontSize: 12, color: Colors.white)),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Informations personnelles',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    TextButton.icon(
                      onPressed: () => setState(() => _editing = !_editing),
                      icon: Icon(_editing ? Icons.close : Icons.edit, size: 16),
                      label: Text(_editing ? 'Annuler' : 'Modifier'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _profilField('Nom complet', Icons.person_outline, _nameCtrl, _editing),
                const SizedBox(height: 12),
                _profilField('Téléphone', Icons.phone_outlined, _phoneCtrl, _editing),
                const SizedBox(height: 12),
                _profilField(
                    'Email',
                    Icons.email_outlined,
                    TextEditingController(text: FirebaseAuth.instance.currentUser?.email ?? ''),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Enregistrer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
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
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _profilField(String label, IconData icon, TextEditingController ctrl, bool enabled) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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