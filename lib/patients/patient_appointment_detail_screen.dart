import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/appointment_model.dart';
import '../../models/medical_record_model.dart';
import '../../models/review_model.dart';
import '../../models/invoice_model.dart';
import '../../services/firebase_service.dart';
import '../../l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_screen.dart';

class PatientAppointmentDetailScreen extends StatefulWidget {
  final AppointmentModel appointment;
  final String doctorName;

  const PatientAppointmentDetailScreen({
    Key? key,
    required this.appointment,
    required this.doctorName,
  }) : super(key: key);

  @override
  State<PatientAppointmentDetailScreen> createState() => _PatientAppointmentDetailScreenState();
}

class _PatientAppointmentDetailScreenState extends State<PatientAppointmentDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  MedicalRecordModel? _medicalRecord;
  ReviewModel? _review;
  InvoiceModel? _invoice;
  Map<String, dynamic>? _reportData; // For reports from reports collection
  AppointmentModel? _currentAppointment; // Current appointment state (may be updated after payment)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentAppointment = widget.appointment;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Reload appointment data to get latest status
      DocumentSnapshot<Map<String, dynamic>>? appointmentDoc;
      appointmentDoc = await _firestore
          .collection('appointments')
          .doc(widget.appointment.id)
          .get();
      
      if (appointmentDoc.exists) {
        final apptData = appointmentDoc.data()!;
        // Convert to AppointmentModel
        final processedData = Map<String, dynamic>.from(apptData);
        
        // Handle 'time' field conversion
        if (apptData['time'] is Timestamp && apptData['appointmentDate'] == null) {
          final time = (apptData['time'] as Timestamp).toDate();
          processedData['appointmentDate'] = time;
          if (apptData['timeSlot'] == null) {
            processedData['timeSlot'] = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          }
        }
        
        if (processedData['hospitalId'] == null && processedData['shiftId'] != null) {
          processedData['hospitalId'] = processedData['shiftId'];
        }
        
        _currentAppointment = AppointmentModel.fromMap(processedData, widget.appointment.id);
      }
      
      // Load medical record from medical_records collection
      final records = await _firebaseService.getMedicalRecordsByAppointment(widget.appointment.id);
      if (records.isNotEmpty) {
        _medicalRecord = records.first;
      }

      // Also check reports collection (legacy format)
      if (_medicalRecord == null) {
        final reportsSnapshot = await _firestore
            .collection('reports')
            .where('appointmentId', isEqualTo: widget.appointment.id)
            .limit(1)
            .get();
        
        if (reportsSnapshot.docs.isNotEmpty) {
          _reportData = reportsSnapshot.docs.first.data();
        }
      }

      // Also check appointment document for report/medicines (another legacy format)
      // Use the appointmentDoc we already fetched above
      if (_medicalRecord == null && _reportData == null && appointmentDoc.exists) {
        final apptData = appointmentDoc.data()!;
        if (apptData['report'] != null || apptData['medicines'] != null) {
          _reportData = {
            'diagnosis': apptData['report'] ?? '',
            'notes': apptData['medicines'] ?? '',
            'medicationsList': apptData['medicationsList'] ?? [],
          };
        }
      }

      // Load review if exists
      final reviews = await _firebaseService.getReviewsByDoctor(widget.appointment.doctorId);
      _review = reviews.firstWhere(
        (r) => r.appointmentId == widget.appointment.id,
        orElse: () => ReviewModel(
          id: '',
          patientId: '',
          doctorId: '',
          appointmentId: '',
          rating: 0,
          createdAt: DateTime.now(),
        ),
      );
      if (_review!.id.isEmpty) {
        _review = null;
      }

      // Load invoice if exists
      final currentAppt = _currentAppointment ?? widget.appointment;
      if (currentAppt.invoiceId != null && currentAppt.invoiceId!.isNotEmpty) {
        _invoice = await _firebaseService.getInvoice(currentAppt.invoiceId!);
      } else {
        // Also try to find invoice by appointmentId
        final invoiceQuery = await _firestore
            .collection('invoices')
            .where('appointmentId', isEqualTo: currentAppt.id)
            .limit(1)
            .get();
        
        if (invoiceQuery.docs.isNotEmpty) {
          _invoice = InvoiceModel.fromMap(invoiceQuery.docs.first.data(), invoiceQuery.docs.first.id);
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showRatingDialog() async {
    double rating = 5.0;
    final TextEditingController commentController = TextEditingController();
    final currentStatus = (_currentAppointment ?? widget.appointment).status;
    final isCancelled = currentStatus == AppointmentStatus.cancelled;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            isCancelled 
                ? 'Rate Doctor Service (Appointment Unavailable)'
                : AppLocalizations.of(context)!.rate_your_experience,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCancelled
                      ? 'Please rate your experience with the doctor\'s service, even though the appointment was unavailable.'
                      : AppLocalizations.of(context)!.how_was_experience,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1.0;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  '${rating.toInt()} out of 5',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: isCancelled
                        ? 'Share your feedback about the doctor\'s service or appointment availability...'
                        : AppLocalizations.of(context)!.share_feedback,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.submit),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _submitReview(rating, commentController.text);
    }
  }

  Future<void> _submitReview(double rating, String comment) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      
      final review = ReviewModel(
        id: '',
        patientId: uid,
        doctorId: (_currentAppointment ?? widget.appointment).doctorId,
        appointmentId: (_currentAppointment ?? widget.appointment).id,
        rating: rating,
        comment: comment.isEmpty ? null : comment,
        createdAt: DateTime.now(),
      );

      await _firebaseService.createReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.review_submitted),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFDDE8EB);
    final darkButtonColor = const Color(0xFF2E4E53);
    final appointmentStatus = (_currentAppointment ?? widget.appointment).status;
    final canRate = (appointmentStatus == AppointmentStatus.completed || 
                    appointmentStatus == AppointmentStatus.cancelled ||
                    (_invoice != null && (_invoice!.isPaid || _invoice!.status == InvoiceStatus.paid)));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.appointment_details,
          style: const TextStyle(
            fontFamily: 'Serif',
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor Information Card
                  _buildCard(
                    title: AppLocalizations.of(context)!.doctor_information,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.person, AppLocalizations.of(context)!.doctor, widget.doctorName),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.calendar_today,
                          AppLocalizations.of(context)!.date,
                          DateFormat('MMMM dd, yyyy').format((_currentAppointment ?? widget.appointment).appointmentDate),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.access_time, AppLocalizations.of(context)!.time, (_currentAppointment ?? widget.appointment).timeSlot),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.info,
                          AppLocalizations.of(context)!.status,
                          (_currentAppointment ?? widget.appointment).status.name.toUpperCase(),
                          valueColor: _getStatusColor((_currentAppointment ?? widget.appointment).status),
                        ),
                        if ((_currentAppointment ?? widget.appointment).consultationFee > 0) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.attach_money,
                            AppLocalizations.of(context)!.consultation_fee,
                            'OMR-${(_currentAppointment ?? widget.appointment).consultationFee.toStringAsFixed(2)}',
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Symptoms Card
                  if ((_currentAppointment ?? widget.appointment).symptoms != null && (_currentAppointment ?? widget.appointment).symptoms!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCard(
                      title: AppLocalizations.of(context)!.your_symptoms,
                      child: Text(
                        (_currentAppointment ?? widget.appointment).symptoms!,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],

                  // Cancel Reason Card
                  if ((_currentAppointment ?? widget.appointment).cancelReason != null && (_currentAppointment ?? widget.appointment).cancelReason!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCard(
                      title: AppLocalizations.of(context)!.cancellation_reason,
                      child: Text(
                        (_currentAppointment ?? widget.appointment).cancelReason!,
                        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.red),
                      ),
                    ),
                  ],

                  // Medical Record Card (from medical_records collection)
                  if (_medicalRecord != null) ...[
                    const SizedBox(height: 16),
                    _buildCard(
                      title: AppLocalizations.of(context)!.medical_record,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.medical_services, AppLocalizations.of(context)!.diagnosis, _medicalRecord!.diagnosis),
                          
                          if (_medicalRecord!.prescriptions.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              '${AppLocalizations.of(context)!.prescriptions}:',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._medicalRecord!.prescriptions.map((prescription) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: darkButtonColor.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.medication, size: 20, color: darkButtonColor),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            prescription.medicineName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _buildPrescriptionDetail(AppLocalizations.of(context)!.dosage, prescription.dosage),
                                    _buildPrescriptionDetail(AppLocalizations.of(context)!.frequency, prescription.frequency),
                                    _buildPrescriptionDetail(AppLocalizations.of(context)!.duration, '${prescription.durationDays} ${AppLocalizations.of(context)!.days}'),
                                    if (prescription.instructions != null && prescription.instructions!.isNotEmpty)
                                      _buildPrescriptionDetail(AppLocalizations.of(context)!.instructions, prescription.instructions!),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],

                          if (_medicalRecord!.labTests != null && _medicalRecord!.labTests!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              '${AppLocalizations.of(context)!.lab_tests}:',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.science, size: 20, color: darkButtonColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _medicalRecord!.labTests!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (_medicalRecord!.notes != null && _medicalRecord!.notes!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Doctor\'s Notes:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.note, size: 20, color: darkButtonColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _medicalRecord!.notes!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Medical Report Card (from reports collection or appointment document - legacy format)
                  if (_medicalRecord == null && _reportData != null) ...[
                    const SizedBox(height: 16),
                    _buildCard(
                      title: AppLocalizations.of(context)!.medical_record,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_reportData!['diagnosis'] != null && _reportData!['diagnosis'].toString().isNotEmpty)
                            _buildInfoRow(
                              Icons.medical_services,
                              AppLocalizations.of(context)!.diagnosis,
                              _reportData!['diagnosis'].toString(),
                            ),
                          
                          if (_reportData!['notes'] != null && _reportData!['notes'].toString().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              '${AppLocalizations.of(context)!.notes}:',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.note, size: 20, color: darkButtonColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _reportData!['notes'].toString(),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (_reportData!['medicationsList'] != null && 
                              _reportData!['medicationsList'] is List &&
                              (_reportData!['medicationsList'] as List).isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              '${AppLocalizations.of(context)!.prescriptions}:',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...(_reportData!['medicationsList'] as List).map((med) {
                              final medMap = med is Map ? med : {};
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: darkButtonColor.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.medication, size: 20, color: darkButtonColor),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            medMap['name']?.toString() ?? 'Unknown Medicine',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (medMap['dosage'] != null && medMap['dosage'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Dosage: ${medMap['dosage']}'),
                                    ],
                                    if (medMap['days'] != null && medMap['days'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Duration: ${medMap['days']} days'),
                                    ],
                                    if (medMap['notes'] != null && medMap['notes'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Notes: ${medMap['notes']}'),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Invoice Card
                  if (_invoice != null) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        if (_invoice!.status == InvoiceStatus.pending && !_invoice!.isPaid) {
                          // Navigate to payment screen if not paid
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentScreen(
                                invoice: _invoice!,
                              ),
                            ),
                          ).then((result) {
                            // Reload data after payment to get updated appointment status
                            if (result == true) {
                              _loadData();
                            }
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: _buildCard(
                        title: AppLocalizations.of(context)!.invoice,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.receipt, size: 20, color: Colors.grey[600]),
                                          const SizedBox(width: 12),
                                          Text(
                                            AppLocalizations.of(context)!.total_amount,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'OMR-${_invoice!.total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _invoice!.isPaid || _invoice!.status == InvoiceStatus.paid
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _invoice!.isPaid || _invoice!.status == InvoiceStatus.paid
                                        ? AppLocalizations.of(context)!.paid_status
                                        : AppLocalizations.of(context)!.pending_status,
                                    style: TextStyle(
                                      color: _invoice!.isPaid || _invoice!.status == InvoiceStatus.paid
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_invoice!.items.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)!.invoice_items,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._invoice!.items.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.description,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      Text(
                                        'OMR-${item.totalAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.subtotal,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'OMR-${_invoice!.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              if (_invoice!.tax > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.tax,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'OMR-${_invoice!.tax.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                            if (_invoice!.isPaid || _invoice!.status == InvoiceStatus.paid) ...[
                              const SizedBox(height: 12),
                              if (_invoice!.paidAt != null)
                                _buildInfoRow(
                                  Icons.check_circle,
                                  AppLocalizations.of(context)!.paid_on,
                                  DateFormat('yyyy-MM-dd • hh:mm a').format(_invoice!.paidAt!),
                                ),
                              if (_invoice!.transactionId != null)
                                _buildInfoRow(
                                  Icons.receipt_long,
                                  AppLocalizations.of(context)!.transaction_id,
                                  _invoice!.transactionId!,
                                ),
                            ] else ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.payment, size: 20, color: darkButtonColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.pay_now,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: darkButtonColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.arrow_forward_ios, size: 16, color: darkButtonColor),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Review Card
                  if (_review != null) ...[
                    const SizedBox(height: 16),
                    _buildCard(
                      title: AppLocalizations.of(context)!.your_review,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < _review!.rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 24,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                '${_review!.rating.toInt()}/5',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (_review!.comment != null && _review!.comment!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _review!.comment!,
                              style: const TextStyle(fontSize: 14, height: 1.5),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Rate Button - Show for completed appointments (including after payment) or cancelled
                  if (canRate && _review == null) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showRatingDialog,
                        icon: const Icon(Icons.star),
                        label: Text(
                          appointmentStatus == AppointmentStatus.completed || 
                          (_invoice != null && (_invoice!.isPaid || _invoice!.status == InvoiceStatus.paid))
                              ? AppLocalizations.of(context)!.rate_doctor
                              : 'Rate Doctor Service',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkButtonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.completed:
        return Colors.blue;
      case AppointmentStatus.rescheduled:
        return Colors.purple;
    }
  }
}

