import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() =>
      _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardAdmin(),
          _GestionChauffeurs(),
          _NotificationsAdmin(),
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
              _navItem(1, Icons.people_outline, 'Chauffeurs'),
              _navItem(
                  2, Icons.notifications_outlined, 'Notifs'),
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
              ? const Color(0xFF0C447C).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected
                    ? const Color(0xFF0C447C)
                    : Colors.grey[400],
                size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected
                      ? const Color(0xFF0C447C)
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

// ========== DASHBOARD ADMIN ==========
class _DashboardAdmin extends StatelessWidget {
  const _DashboardAdmin();

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
                colors: [Color(0xFF0C447C), Color(0xFF1565C0)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding:
                const EdgeInsets.fromLTRB(20, 52, 20, 24),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text('Administration',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70)),
                    Text('Tableau de bord',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'driver')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (_, snap) {
                    final count =
                        snap.data?.docs.length ?? 0;
                    return Stack(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white
                                .withValues(alpha: 0.2),
                          ),
                          child: const Icon(
                              Icons.notifications,
                              color: Colors.white,
                              size: 22),
                        ),
                        if (count > 0)
                          Positioned(
                            top: 0, right: 0,
                            child: Container(
                              width: 18, height: 18,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE24B4A),
                              ),
                              child: Center(
                                child: Text('$count',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight:
                                            FontWeight.w700)),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
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
                    _adminStat(
                      'En attente',
                      FirebaseFirestore.instance
                          .collection('users')
                          .where('role', isEqualTo: 'driver')
                          .where('status',
                              isEqualTo: 'pending'),
                      Icons.hourglass_empty,
                      const Color(0xFFBA7517),
                    ),
                    const SizedBox(width: 10),
                    _adminStat(
                      'Actifs',
                      FirebaseFirestore.instance
                          .collection('users')
                          .where('role', isEqualTo: 'driver')
                          .where('status',
                              isEqualTo: 'active'),
                      Icons.check_circle_outline,
                      const Color(0xFF085041),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _adminStat(
                      'Suspendus',
                      FirebaseFirestore.instance
                          .collection('users')
                          .where('role', isEqualTo: 'driver')
                          .where('status',
                              isEqualTo: 'suspended'),
                      Icons.block,
                      const Color(0xFF791f1f),
                    ),
                    const SizedBox(width: 10),
                    _adminStat(
                      'Trajets',
                      FirebaseFirestore.instance
                          .collection('trajets')
                          .where('status',
                              isEqualTo: 'active'),
                      Icons.directions_bus,
                      AppTheme.primary,
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Text('Nouvelles inscriptions',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'driver')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snap) {
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
                            Icon(Icons.check_circle_outline,
                                size: 40,
                                color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text(
                                'Aucune inscription en attente',
                                style: TextStyle(
                                    color:
                                        Colors.grey[500])),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: snap.data!.docs
                          .map((doc) => _inscriptionCard(
                              context,
                              doc.data()
                                  as Map<String, dynamic>,
                              doc.id))
                          .toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Bouton déconnexion
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

  Widget _adminStat(String label, Query query,
      IconData icon, Color color) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (_, snap) {
          final count = snap.data?.docs.length ?? 0;
          return Container(
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text('$count',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: color)),
                    Text(label,
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _inscriptionCard(BuildContext context,
      Map<String, dynamic> data, String docId) {
    final name = data['name'] ?? 'Chauffeur';
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : 'C';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary
                        .withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Text(initial,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      Text(data['phone'] ?? '',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500])),
                      Text(data['email'] ?? '',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFfaeeda),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('En attente',
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF633806),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _acceptDriver(context, docId, name),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accepter',
                        style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFe1f5ee),
                      foregroundColor:
                          const Color(0xFF085041),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _rejectDriver(context, docId, name),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Rejeter',
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
                          vertical: 10),
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

  Future<void> _acceptDriver(BuildContext context,
      String docId, String name) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(docId)
        .update({'status': 'active'});
    await FirebaseFirestore.instance
        .collection('notifications')
        .add({
      'userId': docId,
      'type': 'account_approved',
      'title': 'Compte approuvé',
      'message':
          'Bienvenue $name ! Votre compte chauffeur a été validé.',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $name accepté avec succès !'),
          backgroundColor: const Color(0xFF085041),
        ),
      );
    }
  }

  Future<void> _rejectDriver(BuildContext context,
      String docId, String name) async {
    final reasons = [
      'Document illisible ou incomplet',
      'Permis expiré ou invalide',
      'Véhicule non conforme',
      'Photo ID non conforme',
      'Autre',
    ];
    String? selectedReason;
    final noteCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Motif de rejet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...reasons.map((r) =>
                    RadioListTile<String>(
                      title: Text(r,
                          style: const TextStyle(
                              fontSize: 13)),
                      value: r,
                      groupValue: selectedReason,
                      activeColor: AppTheme.primary,
                      onChanged: (v) => setStateDialog(
                          () => selectedReason = v),
                      contentPadding: EdgeInsets.zero,
                    )),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    hintText:
                        'Message personnalisé (optionnel)',
                    hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.grey[300]!),
                    ),
                    contentPadding:
                        const EdgeInsets.all(10),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedReason == null) return;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(docId)
                    .update({
                  'status': 'rejected',
                  'rejectionReason': selectedReason,
                });
                await FirebaseFirestore.instance
                    .collection('notifications')
                    .add({
                  'userId': docId,
                  'type': 'account_rejected',
                  'title': 'Dossier rejeté',
                  'message':
                      'Motif : $selectedReason. ${noteCtrl.text}',
                  'read': false,
                  'createdAt':
                      FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                          'Dossier de $name rejeté.'),
                      backgroundColor:
                          const Color(0xFFE24B4A),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFfcebeb),
                foregroundColor: const Color(0xFF791f1f),
                elevation: 0,
              ),
              child: const Text('Envoyer le rejet'),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== GESTION CHAUFFEURS ==========
class _GestionChauffeurs extends StatefulWidget {
  const _GestionChauffeurs();

  @override
  State<_GestionChauffeurs> createState() =>
      _GestionChauffeursState();
}

class _GestionChauffeursState
    extends State<_GestionChauffeurs> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0C447C),
                  Color(0xFF1565C0),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
                20, 52, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gestion chauffeurs',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('Tous', 'all'),
                      const SizedBox(width: 8),
                      _filterChip('Actifs', 'active'),
                      const SizedBox(width: 8),
                      _filterChip('Suspendus', 'suspended'),
                      const SizedBox(width: 8),
                      _filterChip('En attente', 'pending'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        StreamBuilder<QuerySnapshot>(
          stream: _filter == 'all'
              ? FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'driver')
                  .snapshots()
              : FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'driver')
                  .where('status', isEqualTo: _filter)
                  .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData ||
                snap.data!.docs.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline,
                          size: 64,
                          color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Aucun chauffeur',
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
                    return _chauffeurCard(
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

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected
                    ? const Color(0xFF0C447C)
                    : Colors.white,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.w400,
                fontSize: 12)),
      ),
    );
  }

  Widget _chauffeurCard(BuildContext context,
      Map<String, dynamic> data, String docId) {
    final name = data['name'] ?? 'Chauffeur';
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : 'C';
    final status = data['status'] ?? 'active';
    final rating = (data['rating'] ?? 0.0).toDouble();

    Color statusColor;
    Color statusBg;
    String statusLabel;
    switch (status) {
      case 'active':
        statusColor = const Color(0xFF085041);
        statusBg = const Color(0xFFe1f5ee);
        statusLabel = 'Actif';
        break;
      case 'suspended':
        statusColor = const Color(0xFF791f1f);
        statusBg = const Color(0xFFfcebeb);
        statusLabel = 'Suspendu';
        break;
      case 'pending':
        statusColor = const Color(0xFF633806);
        statusBg = const Color(0xFFfaeeda);
        statusLabel = 'En attente';
        break;
      default:
        statusColor = Colors.grey;
        statusBg = Colors.grey[100]!;
        statusLabel = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary
                        .withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Text(initial,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFBA7517),
                              size: 13),
                          Text(' $rating',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color:
                                      Color(0xFFBA7517))),
                          Text(
                              ' · ${data['totalTrips'] ?? 0} voyages',
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (status == 'active')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _suspendDialog(
                          context, docId, name),
                      icon: const Icon(Icons.block,
                          size: 14),
                      label: const Text('Suspendre',
                          style:
                              TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFfcebeb),
                        foregroundColor:
                            const Color(0xFF791f1f),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    10)),
                        padding:
                            const EdgeInsets.symmetric(
                                vertical: 8),
                      ),
                    ),
                  ),
                if (status == 'suspended') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(docId)
                            .update({'status': 'active'});
                        await FirebaseFirestore.instance
                            .collection('notifications')
                            .add({
                          'userId': docId,
                          'type': 'account_reactivated',
                          'title': 'Compte réactivé',
                          'message':
                              'Votre compte a été réactivé.',
                          'read': false,
                          'createdAt':
                              FieldValue.serverTimestamp(),
                        });
                      },
                      icon: const Icon(
                          Icons.check_circle_outline,
                          size: 14),
                      label: const Text('Réactiver',
                          style:
                              TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFe1f5ee),
                        foregroundColor:
                            const Color(0xFF085041),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    10)),
                        padding:
                            const EdgeInsets.symmetric(
                                vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text('Motif :',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey)),
                          Text(
                            data['suspensionReason'] ??
                                'Non précisé',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w500),
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _suspendDialog(BuildContext context,
      String docId, String name) async {
    final reasons = [
      'Plainte passager grave',
      'Non-respect des horaires',
      'Comportement inapproprié',
      'Fraude ou escroquerie',
      'Autre',
    ];
    String? selectedReason;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Suspendre $name',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons
                .map((r) => RadioListTile<String>(
                      title: Text(r,
                          style: const TextStyle(
                              fontSize: 13)),
                      value: r,
                      groupValue: selectedReason,
                      activeColor: AppTheme.primary,
                      onChanged: (v) => setStateDialog(
                          () => selectedReason = v),
                      contentPadding: EdgeInsets.zero,
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedReason == null) return;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(docId)
                    .update({
                  'status': 'suspended',
                  'suspensionReason': selectedReason,
                });
                await FirebaseFirestore.instance
                    .collection('notifications')
                    .add({
                  'userId': docId,
                  'type': 'account_suspended',
                  'title': 'Compte suspendu',
                  'message':
                      'Motif : $selectedReason. Contactez le support.',
                  'read': false,
                  'createdAt':
                      FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text('$name suspendu.'),
                      backgroundColor:
                          const Color(0xFFE24B4A),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFfcebeb),
                foregroundColor: const Color(0xFF791f1f),
                elevation: 0,
              ),
              child: const Text('Suspendre'),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== NOTIFICATIONS ADMIN ==========
class _NotificationsAdmin extends StatelessWidget {
  const _NotificationsAdmin();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0C447C),
                  Color(0xFF1565C0),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
                20, 52, 20, 24),
            child: const Text('Notifications envoyées',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData ||
                snap.data!.docs.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Aucune notification',
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
                    return _notifCard(d);
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

  Widget _notifCard(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    Color color;
    Color bg;
    IconData icon;
    switch (type) {
      case 'account_approved':
        color = const Color(0xFF085041);
        bg = const Color(0xFFe1f5ee);
        icon = Icons.check_circle;
        break;
      case 'account_rejected':
        color = const Color(0xFF791f1f);
        bg = const Color(0xFFfcebeb);
        icon = Icons.cancel;
        break;
      case 'account_suspended':
        color = const Color(0xFF791f1f);
        bg = const Color(0xFFfcebeb);
        icon = Icons.block;
        break;
      case 'account_reactivated':
        color = AppTheme.primary;
        bg = const Color(0xFFE6F1FB);
        icon = Icons.refresh;
        break;
      default:
        color = Colors.grey;
        bg = Colors.grey[100]!;
        icon = Icons.notifications;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 3),
                Text(data['message'] ?? '',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}