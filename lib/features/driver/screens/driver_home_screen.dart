import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() =>
      _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      // Sécurité : si jamais l'utilisateur n'est pas connecté
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    // ⚡ StreamBuilder temps réel sur le document du chauffeur
    // -> toute modif (validation admin, stats, statut) se reflète
    //    immédiatement sans recharger l'écran.
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return const Scaffold(
            body: Center(
              child: Text('Profil chauffeur introuvable.'),
            ),
          );
        }

        final driverData =
            snap.data!.data() as Map<String, dynamic>? ?? {};

        // Chauffeur en attente de validation
        if (driverData['status'] == 'pending') {
          return _buildPendingScreen(driverData);
        }

        // Chauffeur suspendu
        if (driverData['status'] == 'suspended') {
          return _buildSuspendedScreen(driverData);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _DashboardPage(driverData: driverData),
              _MesTrajetsPage(driverData: driverData),
              _MesColisPage(driverData: driverData),
              _DriverProfilPage(driverData: driverData),
            ],
          ),
          bottomNavigationBar: _buildNavBar(),
        );
      },
    );
  }

  Widget _buildPendingScreen(Map<String, dynamic> driverData) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1565C0), AppTheme.primary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                          color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.access_time,
                        color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 24),
                  const Text('Compte en attente',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(
                    'Votre dossier est en cours d\'examen par un administrateur. '
                    'Vous recevrez une notification dès la validation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white
                              .withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        _docStatus('Permis de conduire', true),
                        const SizedBox(height: 8),
                        _docStatus('Carte grise', true),
                        const SizedBox(height: 8),
                        _docStatus('Photo ID', true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Délai estimé : 24-48h',
                        style: TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) context.go('/');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                            color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(25)),
                      ),
                      child: const Text('Se déconnecter'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuspendedScreen(Map<String, dynamic> driverData) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: const Icon(Icons.block,
                        color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 24),
                  const Text('Compte suspendu',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('Motif de suspension :',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12)),
                        const SizedBox(height: 6),
                        Text(
                          driverData['suspensionReason'] ??
                              'Non précisé',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Contactez le support pour plus d\'informations.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) context.go('/');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                            color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(25)),
                      ),
                      child: const Text('Se déconnecter'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _docStatus(String label, bool received) {
    return Row(
      children: [
        Icon(
          received
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color: received ? Colors.white : Colors.white54,
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 13)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('✓ Reçu',
              style: TextStyle(
                  color: Colors.white, fontSize: 11)),
        ),
      ],
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
              _navItem(0, Icons.dashboard_outlined, 'Dashboard'),
              _navItem(1, Icons.directions_bus_outlined, 'Trajets'),
              _navItem(2, Icons.inventory_2_outlined, 'Colis'),
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
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.1)
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

// ========== DASHBOARD ==========
class _DashboardPage extends StatelessWidget {
  final Map<String, dynamic> driverData;
  const _DashboardPage({required this.driverData});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final name = driverData['name'] ?? 'Chauffeur';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';
    final rating = (driverData['rating'] ?? 0.0).toDouble();
    final totalTrips = driverData['totalTrips'] ?? 0;
    final revenue = driverData['revenue'] ?? 0;

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
              children: [
                Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                            color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(initial,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('Bonjour, $name',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFCC00),
                                  size: 14),
                              Text(' $rating',
                                  style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.9),
                                      fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFe1f5ee),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Actif',
                          style: TextStyle(
                              color: Color(0xFF085041),
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats
                Row(
                  children: [
                    _statCard('Voyages', '$totalTrips',
                        Icons.directions_bus, AppTheme.primary),
                    const SizedBox(width: 10),
                    _statCard('Revenus', '$revenue F',
                        Icons.account_balance_wallet,
                        const Color(0xFF085041)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statCard('Note', '$rating ★',
                        Icons.star_rounded,
                        const Color(0xFFBA7517)),
                    const SizedBox(width: 10),
                    _statCard('Colis', '0',
                        Icons.inventory_2_outlined,
                        const Color(0xFF7B1FA2)),
                  ],
                ),

                const SizedBox(height: 20),

                // Réservations du jour
                const Text('Réservations du jour',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),

                if (uid != null)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reservations')
                        .where('driverId', isEqualTo: uid)
                        .orderBy('createdAt', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primary));
                      }

                      // ⚠️ Si la requête échoue (souvent : index Firestore
                      // manquant pour where('driverId') + orderBy('createdAt')),
                      // on affiche l'erreur au lieu de la cacher silencieusement.
                      if (snap.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFfcebeb),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Erreur de chargement : ${snap.error}',
                            style: const TextStyle(
                                color: Color(0xFF791f1f),
                                fontSize: 12),
                          ),
                        );
                      }

                      if (!snap.hasData ||
                          snap.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                  Icons
                                      .confirmation_number_outlined,
                                  size: 40,
                                  color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              Text('Aucune réservation',
                                  style: TextStyle(
                                      color: Colors.grey[500])),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: snap.data!.docs.map((doc) {
                          final d = doc.data()
                              as Map<String, dynamic>;
                          return _reservationCard(d);
                        }).toList(),
                      );
                    },
                  ),

                const SizedBox(height: 20),

                // Bouton ajouter trajet
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddTrajetDialog(
                        context, uid ?? '', name),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Ajouter ma disponibilité',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
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

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color)),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reservationCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                (data['clientName'] ?? 'P')[0].toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['clientName'] ?? 'Passager',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(
                  '${data['departure']} → ${data['destination']}',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${data['totalPaid'] ?? 0} F',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFe1f5ee),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Confirmé',
                    style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF085041))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Ajout du paramètre driverName : on utilise le nom réel
  // (venant de Firestore) au lieu de currentUser?.displayName
  // qui est presque toujours null en Firebase Auth.
  void _showAddTrajetDialog(
      BuildContext context, String uid, String driverName) {
    final departCtrl = TextEditingController();
    final destCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final hDepCtrl = TextEditingController();
    final hArrCtrl = TextEditingController();
    final placesCtrl = TextEditingController();
    final prixCtrl = TextEditingController();
    final vehiculeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 20, left: 20, right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ajouter un trajet',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _sheetField('Départ', departCtrl,
                  Icons.location_on_outlined),
              _sheetField('Destination', destCtrl,
                  Icons.flag_outlined),
              _sheetField('Date (ex: 13 juin 2025)',
                  dateCtrl, Icons.calendar_today_outlined),
              _sheetField('Heure départ (ex: 07:30)',
                  hDepCtrl, Icons.access_time),
              _sheetField('Heure arrivée (ex: 14:00)',
                  hArrCtrl, Icons.access_time_filled),
              _sheetField('Nombre de places', placesCtrl,
                  Icons.people_outline,
                  keyboard: TextInputType.number),
              _sheetField('Prix / place (FCFA)', prixCtrl,
                  Icons.payments_outlined,
                  keyboard: TextInputType.number),
              _sheetField('Véhicule', vehiculeCtrl,
                  Icons.directions_bus_outlined),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (departCtrl.text.isEmpty ||
                        destCtrl.text.isEmpty) return;
                    try {
                      await FirebaseFirestore.instance
                          .collection('trajets')
                          .add({
                        'departure': departCtrl.text.trim(),
                        'destination': destCtrl.text.trim(),
                        'date': dateCtrl.text.trim(),
                        'departureTime': hDepCtrl.text.trim(),
                        'arrivalTime': hArrCtrl.text.trim(),
                        'availableSeats': int.tryParse(
                                placesCtrl.text) ??
                            0,
                        'price': int.tryParse(prixCtrl.text) ??
                            0,
                        'vehicle': vehiculeCtrl.text.trim(),
                        'driverId': uid,
                        // ✅ FIX : nom réel du chauffeur (Firestore),
                        // plus jamais 'Chauffeur' par défaut.
                        'driverName': driverName,
                        'driverRating': 0.0,
                        'status': 'active',
                        'createdAt':
                            FieldValue.serverTimestamp(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                                '✅ Trajet publié avec succès !'),
                            backgroundColor:
                                Color(0xFF085041),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(content: Text('Erreur: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14)),
                  ),
                  child: const Text('Publier le trajet',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(String label,
      TextEditingController ctrl, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: keyboard,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
                color: Colors.grey[500], fontSize: 13),
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
    );
  }
}

// ========== MES TRAJETS ==========
class _MesTrajetsPage extends StatelessWidget {
  final Map<String, dynamic> driverData;
  const _MesTrajetsPage({required this.driverData});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
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
                Text('Mes trajets',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                SizedBox(height: 4),
                Text('Vos trajets publiés',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70)),
              ],
            ),
          ),
        ),
        if (uid != null)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('trajets')
                .where('driverId', isEqualTo: uid)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState ==
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
              if (!snap.hasData ||
                  snap.data!.docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.directions_bus_outlined,
                            size: 64,
                            color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('Aucun trajet publié',
                            style: TextStyle(
                                color: Colors.grey[500])),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final d = snap.data!.docs[i].data()
                          as Map<String, dynamic>;
                      final docId = snap.data!.docs[i].id;
                      return _trajetDriverCard(
                          context, d, docId);
                    },
                    childCount: snap.data!.docs.length,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _trajetDriverCard(BuildContext context,
      Map<String, dynamic> data, String docId) {
    final isActive = data['status'] == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primary
                  : Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
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
                    Text(
                      '${data['departure']} → ${data['destination']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFe1f5ee)
                            : Colors.grey[100],
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Actif' : 'Inactif',
                        style: TextStyle(
                            fontSize: 11,
                            color: isActive
                                ? const Color(0xFF085041)
                                : Colors.grey[500],
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 14, color: Colors.grey[500]),
                    Text(
                      ' ${data['departureTime']} → ${data['arrivalTime']}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    Icon(Icons.people_outline,
                        size: 14, color: Colors.grey[500]),
                    Text(
                      ' ${data['availableSeats']} places',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    Text(
                      '${data['price']} F',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                          fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('trajets')
                              .doc(docId)
                              .update({
                            'status': isActive
                                ? 'inactive'
                                : 'active'
                          });
                        },
                        icon: Icon(
                          isActive
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          size: 16,
                        ),
                        label: Text(
                            isActive ? 'Désactiver' : 'Activer',
                            style: const TextStyle(
                                fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(
                              color: AppTheme.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('trajets')
                              .doc(docId)
                              .delete();
                        },
                        icon: const Icon(Icons.delete_outline,
                            size: 16),
                        label: const Text('Supprimer',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFfcebeb),
                          foregroundColor:
                              const Color(0xFF791f1f),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8),
                        ),
                      ),
                    ),
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

// ========== MES COLIS ==========
class _MesColisPage extends StatelessWidget {
  final Map<String, dynamic> driverData;
  const _MesColisPage({required this.driverData});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
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
                Text('Mes colis',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                SizedBox(height: 4),
                Text('Colis à expédier',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('Aucun colis assigné',
                    style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ========== PROFIL CHAUFFEUR ==========
class _DriverProfilPage extends StatefulWidget {
  final Map<String, dynamic> driverData;
  const _DriverProfilPage({required this.driverData});

  @override
  State<_DriverProfilPage> createState() =>
      _DriverProfilPageState();
}

class _DriverProfilPageState
    extends State<_DriverProfilPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.driverData['name'] ?? '';
    _phoneCtrl.text = widget.driverData['phone'] ?? '';
  }

  @override
  void didUpdateWidget(covariant _DriverProfilPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Le StreamBuilder parent peut reconstruire ce widget avec de
    // nouvelles données (ex: mise à jour depuis un autre appareil) ;
    // on ne réécrase le champ que si l'utilisateur n'est pas en train
    // de modifier pour ne pas perdre sa saisie en cours.
    if (!_editing) {
      _nameCtrl.text = widget.driverData['name'] ?? '';
      _phoneCtrl.text = widget.driverData['phone'] ?? '';
    }
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
    final name = widget.driverData['name'] ?? 'Chauffeur';
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : 'C';
    final rating =
        (widget.driverData['rating'] ?? 0.0).toDouble();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
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
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                        color: Colors.white, width: 2.5),
                  ),
                  child: Center(
                    child: Text(initial,
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFCC00), size: 16),
                    Text(' $rating',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Chauffeur',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white)),
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
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Informations',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    TextButton.icon(
                      onPressed: () => setState(
                          () => _editing = !_editing),
                      icon: Icon(
                          _editing
                              ? Icons.close
                              : Icons.edit,
                          size: 16),
                      label: Text(
                          _editing ? 'Annuler' : 'Modifier'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _profilField('Nom', Icons.person_outline,
                    _nameCtrl, _editing),
                const SizedBox(height: 12),
                _profilField('Téléphone', Icons.phone_outlined,
                    _phoneCtrl, _editing),
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
                      child: const Text('Enregistrer'),
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
                      if (context.mounted) context.go('/');
                    },
                    icon: const Icon(Icons.logout,
                        color: Colors.red),
                    label: const Text('Se déconnecter',
                        style: TextStyle(color: Colors.red)),
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
            color: Colors.black.withValues(alpha: 0.05),
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
          fillColor:
              enabled ? Colors.white : Colors.grey[50],
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