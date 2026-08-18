import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AppTheme {
  static const Color primary = Color(0xFF1E88E5);
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color border = Color(0xFFE0E0E0);
}

class BookingScreen extends StatefulWidget {
  final String trajetId;
  final Map<String, dynamic> data;

  const BookingScreen({
    Key? key,
    required this.trajetId,
    required this.data,
  }) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _step = 1; // 1: Formulaire, 2: Paiement, 3: Confirmation
  int _nbPlaces = 1;
  String _payMethod = 'Wave';
  bool _loading = false;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String? _reservationId;
  String? _seat;
  String? _qrData;

  double get _unitPrice {
    final raw = widget.data['price'] ?? widget.data['prix'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  double get _total => _unitPrice * _nbPlaces;

  int get _maxSeats {
    final rawSeats = widget.data['availableSeats'] ?? widget.data['places'] ?? 1;
    if (rawSeats is num) return rawSeats.toInt();
    return int.tryParse(rawSeats.toString()) ?? 1;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Récupération intelligente des données de l'utilisateur connecté
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String name = user.displayName ?? '';
      String phone = user.phoneNumber ?? '';

      // Si manquant dans Auth, chercher dans le document Firestore 'users'
      if (name.isEmpty || phone.isEmpty) {
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            final data = userDoc.data();
            if (data != null) {
              if (name.isEmpty) name = data['name'] ?? data['fullName'] ?? data['displayName'] ?? '';
              if (phone.isEmpty) phone = data['phone'] ?? data['phoneNumber'] ?? '';
            }
          }
        } catch (e) {
          debugPrint('Erreur chargement user profile: $e');
        }
      }

      if (mounted) {
        setState(() {
          _nameCtrl.text = name;
          _phoneCtrl.text = phone;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // --- LOGIQUE DE RÉSERVATION SÉCURISÉE ---
  Future<void> _confirmerPaiement() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('Utilisateur non connecté.');
      }

      final id = 'BW-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
      final seat = 'A${Random().nextInt(15) + 1}';
      final trajetRef = FirebaseFirestore.instance.collection('trajets').doc(widget.trajetId);
      final reservationRef = FirebaseFirestore.instance.collection('reservations').doc(id);

      // Transaction atomique
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(trajetRef);

        if (!snapshot.exists) {
          throw Exception("Ce trajet n'existe plus.");
        }

        final rawSeats = snapshot.data()?['availableSeats'] ?? 0;
        final availableSeats = rawSeats is num ? rawSeats.toInt() : (int.tryParse(rawSeats.toString()) ?? 0);

        if (availableSeats < _nbPlaces) {
          throw Exception("Nombre de places insuffisant (restantes : $availableSeats).");
        }

        // Décrémentation sécurisée
        transaction.update(trajetRef, {
          'availableSeats': availableSeats - _nbPlaces,
        });

        // Création de la réservation
        transaction.set(reservationRef, {
          'id': id,
          'clientId': uid,
          'clientName': _nameCtrl.text.trim(),
          'clientPhone': _phoneCtrl.text.trim(),
          'trajetId': widget.trajetId,
          'departure': widget.data['departure'] ?? widget.data['depart'] ?? 'Inconnu',
          'destination': widget.data['destination'] ?? widget.data['arrivee'] ?? 'Inconnu',
          'departureTime': widget.data['departureTime'] ?? '',
          'arrivalTime': widget.data['arrivalTime'] ?? '',
          'driverName': widget.data['driverName'] ?? '',
          'driverId': widget.data['driverId'] ?? '',
          'price': _unitPrice,
          'totalPaid': _total,
          'nbPlaces': _nbPlaces,
          'payMethod': _payMethod,
          'status': 'confirmed',
          'seat': seat,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      setState(() {
        _reservationId = id;
        _seat = seat;
        _qrData = 'BUSWAY|$id|${widget.data['departure']}|${widget.data['destination']}|${_nameCtrl.text.trim()}';
        _step = 3;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_titreEtape),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStepper(),
            const SizedBox(height: 20),
            if (_step == 1) _buildStepFormulaire(),
            if (_step == 2) _buildStepPaiement(),
            if (_step == 3) _buildStepConfirmation(),
          ],
        ),
      ),
    );
  }

  String get _titreEtape {
    switch (_step) {
      case 1:
        return 'Informations passager';
      case 2:
        return 'Paiement';
      case 3:
        return 'Billet confirmé';
      default:
        return 'Réservation';
    }
  }

  Widget _buildStepper() {
    return Row(
      children: [
        _buildStepCircle(1, 'Infos'),
        _buildStepLine(1),
        _buildStepCircle(2, 'Paiement'),
        _buildStepLine(2),
        _buildStepCircle(3, 'Billet'),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _step >= step;
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isActive ? AppTheme.primary : Colors.grey[300],
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppTheme.primary : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _step > step;
    return Container(
      width: 40,
      height: 2,
      color: isActive ? AppTheme.primary : Colors.grey[300],
    );
  }

  Widget _buildStepFormulaire() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTrajetSummary(),
              const Divider(height: 32),
              const Text(
                'Coordonnées du passager',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Veuillez entrer votre nom' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Veuillez entrer votre numéro' : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nombre de places', style: TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _nbPlaces > 1
                            ? () => setState(() => _nbPlaces--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_nbPlaces', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: _nbPlaces < _maxSeats
                            ? () => setState(() => _nbPlaces++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _step = 2);
                    }
                  },
                  child: const Text('Continuer vers le paiement', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepPaiement() {
    final departure = widget.data['departure'] ?? widget.data['depart'] ?? 'Départ';
    final destination = widget.data['destination'] ?? widget.data['arrivee'] ?? 'Arrivée';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Récapitulatif de la commande',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRowDetail('Trajet', '$departure → $destination'),
            _buildRowDetail('Passager', _nameCtrl.text),
            _buildRowDetail('Places', '$_nbPlaces'),
            _buildRowDetail('Prix unitaire', '$_unitPrice FCFA'),
            const Divider(),
            _buildRowDetail('Total à payer', '$_total FCFA', isBold: true),
            const SizedBox(height: 20),
            const Text(
              'Moyen de paiement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            RadioListTile<String>(
              title: const Text('Wave'),
              value: 'Wave',
              groupValue: _payMethod,
              onChanged: (val) => setState(() => _payMethod = val!),
            ),
            RadioListTile<String>(
              title: const Text('Airtel Money / MTN Mobile Money'),
              value: 'Mobile Money',
              groupValue: _payMethod,
              onChanged: (val) => setState(() => _payMethod = val!),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => setState(() => _step = 1),
                    child: const Text('Retour'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                    onPressed: _loading ? null : _confirmerPaiement,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Payer maintenant', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepConfirmation() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.success, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Réservation confirmée !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'N° de réservation : $_reservationId',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            if (_qrData != null)
              SizedBox(
                height: 180,
                width: 180,
                child: QrImageView(
                  data: _qrData!,
                  version: QrVersions.auto,
                  size: 180.0,
                ),
              ),
            const SizedBox(height: 20),
            _buildRowDetail('Place attribuée', _seat ?? 'Non assignée', isBold: true),
            _buildRowDetail('Départ', widget.data['departure'] ?? widget.data['depart'] ?? '—'),
            _buildRowDetail('Destination', widget.data['destination'] ?? widget.data['arrivee'] ?? '—'),
            _buildRowDetail('Heure de départ', widget.data['departureTime'] ?? 'Non spécifiée'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Terminer', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrajetSummary() {
    final departure = widget.data['departure'] ?? widget.data['depart'] ?? '';
    final destination = widget.data['destination'] ?? widget.data['arrivee'] ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(departure, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.data['departureTime'] ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
        const Icon(Icons.arrow_forward, color: AppTheme.primary),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(destination, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.data['arrivalTime'] ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildRowDetail(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}