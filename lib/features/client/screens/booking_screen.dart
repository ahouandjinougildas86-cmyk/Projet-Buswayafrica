import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_theme.dart';

class BookingScreen extends StatefulWidget {
  final String trajetId;
  final Map<String, dynamic> data;
  const BookingScreen({
    super.key,
    required this.trajetId,
    required this.data,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _step = 1; // 1=Infos, 2=Paiement, 3=Reçu
  String _payMethod = 'mtn';
  bool _loading = false;
  bool _downloadingPdf = false;
  String _reservationId = '';
  String _qrData = '';
  String _seat = '';

  // Infos passager
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  int _nbPlaces = 1;

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
          .get();
      if (mounted) {
        _nameCtrl.text = doc.data()?['name'] ?? '';
        _phoneCtrl.text = doc.data()?['phone'] ?? '';
      }
    } catch (_) {}
  }

  int get _total =>
      (widget.data['price'] ?? 0) * _nbPlaces + 100;

  Future<void> _confirmerPaiement() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final id =
          'BW-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
      final driverId = widget.data['driverId'];
      final seat = 'A${Random().nextInt(15) + 1}';

      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(id)
          .set({
        'id': id,
        'clientId': uid,
        'clientName': _nameCtrl.text.trim(),
        'clientPhone': _phoneCtrl.text.trim(),
        'trajetId': widget.trajetId,
        'departure': widget.data['departure'],
        'destination': widget.data['destination'],
        'departureTime': widget.data['departureTime'],
        'arrivalTime': widget.data['arrivalTime'],
        'driverName': widget.data['driverName'],
        'driverId': driverId,
        'price': widget.data['price'],
        'totalPaid': _total,
        'nbPlaces': _nbPlaces,
        'payMethod': _payMethod,
        // 'confirmed' = payé, en attente du trajet.
        // Passera à 'completed' quand le client confirmera la fin du trajet
        // (et pourra alors noter le chauffeur).
        'status': 'confirmed',
        'seat': seat,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Réduire les places disponibles sur le trajet
      await FirebaseFirestore.instance
          .collection('trajets')
          .doc(widget.trajetId)
          .update({
        'availableSeats': FieldValue.increment(-_nbPlaces),
      });

      // ✅ Incrémenter immédiatement les revenus du chauffeur
      // (dès que le paiement est confirmé, indépendamment du fait
      // que le trajet ait eu lieu ou non).
      if (driverId != null && driverId.toString().isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(driverId)
            .update({
          'revenue': FieldValue.increment(_total),
        });
      }

      setState(() {
        _reservationId = id;
        _seat = seat;
        _qrData =
            'BUSWAY|$id|${widget.data['departure']}|${widget.data['destination']}|${_nameCtrl.text}';
        _step = 3;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===== GÉNÉRATION & TÉLÉCHARGEMENT DU BILLET PDF =====
  Future<void> _telechargerRecu() async {
    setState(() => _downloadingPdf = true);
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          build: (context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(28),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: PdfColors.grey300, width: 1),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('BusWay Africa',
                          style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF1976D2))),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green100,
                          borderRadius:
                              pw.BorderRadius.circular(12),
                        ),
                        child: pw.Text('CONFIRMÉ',
                            style: pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.green900,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Billet de voyage',
                      style: pw.TextStyle(
                          fontSize: 11, color: PdfColors.grey700)),
                  pw.Divider(height: 24, color: PdfColors.grey300),

                  // Trajet
                  pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('DÉPART',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey600)),
                          pw.Text(
                              widget.data['departureTime'] ??
                                  '--:--',
                              style: pw.TextStyle(
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(widget.data['departure'] ?? ''),
                        ],
                      ),
                      pw.Text('→',
                          style: const pw.TextStyle(fontSize: 20)),
                      pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('ARRIVÉE',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey600)),
                          pw.Text(
                              widget.data['arrivalTime'] ??
                                  '--:--',
                              style: pw.TextStyle(
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(widget.data['destination'] ?? ''),
                        ],
                      ),
                    ],
                  ),
                  pw.Divider(height: 24, color: PdfColors.grey300),

                  // Infos passager
                  _pdfRow('Passager', _nameCtrl.text),
                  _pdfRow('Téléphone', _phoneCtrl.text),
                  _pdfRow('Chauffeur',
                      widget.data['driverName'] ?? ''),
                  _pdfRow('Places', '$_nbPlaces'),
                  _pdfRow('Siège', _seat),
                  _pdfRow('Montant payé', '$_total FCFA'),
                  _pdfRow('N° billet', _reservationId),

                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.BarcodeWidget(
                      barcode: Barcode.qrCode(),
                      data: _qrData,
                      width: 110,
                      height: 110,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Center(
                    child: pw.Text(
                        'Présentez ce QR code au chauffeur',
                        style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600)),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final bytes = await pdf.save();

      // Printing.sharePdf déclenche le téléchargement du fichier
      // dans le navigateur (Web) ou la boîte de partage (mobile).
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'billet_busway_$_reservationId.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération du PDF : $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 11, color: PdfColors.grey700)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header
          Container(
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
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_step > 1 && _step < 3) {
                          setState(() => _step--);
                        } else {
                          context.go('/client');
                        }
                      },
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('Réservation',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        Text(
                          '${widget.data['departure']} → ${widget.data['destination']}',
                          style: TextStyle(
                              color:
                                  Colors.white.withOpacity(0.8),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Indicateur étapes
                if (_step < 3) _buildStepIndicator(),
              ],
            ),
          ),

          // Contenu
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _step == 1
                  ? _buildStep1()
                  : _step == 2
                      ? _buildStep2()
                      : _buildStep3(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(2, (i) {
        final active = i + 1 <= _step;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                ),
                child: Center(
                  child: Text('${i + 1}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? AppTheme.primary
                              : Colors.white)),
                ),
              ),
              if (i < 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 6),
                    color: _step >= 2
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ===== ÉTAPE 1 : Informations =====
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Résumé trajet
        _trajetResume(),
        const SizedBox(height: 20),

        const Text('Vos informations',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        _field('Nom complet', Icons.person_outline,
            _nameCtrl),
        const SizedBox(height: 12),
        _field('Téléphone', Icons.phone_outlined, _phoneCtrl,
            keyboard: TextInputType.phone),
        const SizedBox(height: 16),

        // Nombre de places
        const Text('Nombre de places',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text('Places',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Row(
                children: [
                  _counterBtn(Icons.remove, () {
                    if (_nbPlaces > 1)
                      setState(() => _nbPlaces--);
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    child: Text('$_nbPlaces',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ),
                  _counterBtn(Icons.add, () {
                    if (_nbPlaces < 4)
                      setState(() => _nbPlaces++);
                  }),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Total estimé
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_nbPlaces place${_nbPlaces > 1 ? 's' : ''} × ${widget.data['price']} F',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600]),
                  ),
                  const Text('+ 100 F frais de service',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey)),
                ],
              ),
              Text('$_total FCFA',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary)),
            ],
          ),
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (_nameCtrl.text.isEmpty ||
                  _phoneCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Remplissez tous les champs')),
                );
                return;
              }
              setState(() => _step = 2);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Continuer → Paiement',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  // ===== ÉTAPE 2 : Paiement =====
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _trajetResume(),
        const SizedBox(height: 20),

        // Récapitulatif
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _recapRow('Passager', _nameCtrl.text),
              _recapRow('Téléphone', _phoneCtrl.text),
              _recapRow('Places', '$_nbPlaces'),
              _recapRow(
                  'Prix trajet',
                  '${(widget.data['price'] ?? 0) * _nbPlaces} FCFA'),
              _recapRow('Frais service', '100 FCFA'),
              const Divider(height: 20),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Text('$_total FCFA',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text('Mode de paiement',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        // MTN MoMo
        _payOption(
          'mtn',
          'MTN MoMo',
          '+229 97 XX XX XX',
          const Color(0xFFFFCC00),
          Colors.black,
          'MTN',
        ),
        const SizedBox(height: 10),
        // Moov Money
        _payOption(
          'moov',
          'Moov Money',
          'Ajouter un numéro',
          const Color(0xFF005EB8),
          Colors.white,
          'Moov',
        ),
        const SizedBox(height: 10),
        // CinetPay
        _payOption(
          'cinetpay',
          'CinetPay',
          'Carte / Mobile Money',
          const Color(0xFF00A651),
          Colors.white,
          'CP',
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _confirmerPaiement,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white))
                : Text('Payer $_total FCFA',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  // ===== ÉTAPE 3 : Reçu =====
  Widget _buildStep3() {
    return Column(
      children: [
        // Succès
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFe1f5ee),
            border: Border.all(
                color: const Color(0xFF085041), width: 2),
          ),
          child: const Icon(Icons.check_rounded,
              color: Color(0xFF085041), size: 36),
        ),
        const SizedBox(height: 12),
        const Text('Paiement confirmé !',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Votre billet est prêt',
            style: TextStyle(
                fontSize: 13, color: Colors.grey[500])),
        const SizedBox(height: 24),

        // Billet
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header billet
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1565C0),
                      AppTheme.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.data['departure']} → ${widget.data['destination']}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: const Text('Confirmé',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              // Tirets séparateurs
              Row(
                children: [
                  Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF5F7FA))),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (_, c) => Row(
                        children: List.generate(
                          (c.maxWidth / 10).floor(),
                          (_) => Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey[300],
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF5F7FA))),
                ],
              ),

              // Corps billet
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Horaires
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
                              widget.data['departureTime'] ??
                                  '--:--',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const Icon(Icons.directions_bus,
                            color: AppTheme.primary, size: 32),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            const Text('Arrivée',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey)),
                            Text(
                              widget.data['arrivalTime'] ??
                                  '--:--',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey[100]),
                    const SizedBox(height: 8),

                    // Infos passager + QR
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _billetInfo('Passager',
                                  _nameCtrl.text),
                              _billetInfo('Chauffeur',
                                  widget.data['driverName'] ??
                                      ''),
                              _billetInfo('N° billet',
                                  _reservationId.substring(
                                      0,
                                      min(16,
                                          _reservationId
                                              .length))),
                            ],
                          ),
                        ),
                        // QR Code
                        if (_qrData.isNotEmpty)
                          QrImageView(
                            data: _qrData,
                            version: QrVersions.auto,
                            size: 90,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Bouton télécharger
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed:
                _downloadingPdf ? null : _telechargerRecu,
            icon: _downloadingPdf
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white))
                : const Icon(Icons.download_rounded),
            label: Text(
                _downloadingPdf
                    ? 'Génération...'
                    : 'Télécharger le reçu PDF',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => context.go('/client'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(
                  color: AppTheme.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Retour à l\'accueil',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ===== WIDGETS HELPERS =====
  Widget _trajetResume() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.data['departure']} → ${widget.data['destination']}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Text(
                '${widget.data['driverName']} · ${widget.data['departureTime']}',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          Text(
            '${widget.data['price']} F',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, IconData icon,
      TextEditingController ctrl,
      {TextInputType keyboard = TextInputType.text}) {
    return Container(
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
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 18),
      ),
    );
  }

  Widget _payOption(String value, String label, String sub,
      Color badgeColor, Color badgeText, String badgeLabel) {
    final selected = _payMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _payMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : Colors.grey[200]!,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppTheme.primary
                      : Colors.grey[300]!,
                  width: 2,
                ),
                color: selected
                    ? AppTheme.primary
                    : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 12)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(sub,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badgeLabel,
                  style: TextStyle(
                      color: badgeText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recapRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[600])),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _billetInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: Colors.grey[500])),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}