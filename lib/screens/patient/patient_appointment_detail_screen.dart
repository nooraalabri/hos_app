import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/medical_record_model.dart';
import '../../models/review_model.dart';
import '../../services/firebase_service.dart';
import '../../providers/auth_provider.dart';

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
  MedicalRecordModel? _medicalRecord;
  ReviewModel? _review;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load medical record
      final records = await _firebaseService.getMedicalRecordsByAppointment(widget.appointment.id);
      if (records.isNotEmpty) {
        _medicalRecord = records.first;
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

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showRatingDialog() async {
    double rating = 5.0;
    final TextEditingController commentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate Your Experience'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('How was your experience with the doctor?'),
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
                  decoration: const InputDecoration(
                    hintText: 'Share your feedback (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final review = ReviewModel(
        id: '',
        patientId: authProvider.currentUser!.uid,
        doctorId: widget.appointment.doctorId,
        appointmentId: widget.appointment.id,
        rating: rating,
        comment: comment.isEmpty ? null : comment,
        createdAt: DateTime.now(),
      );

      await _firebaseService.createReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'Appointment Details',
          style: TextStyle(
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
                    title: 'Doctor Information',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.person, 'Doctor', widget.doctorName),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Date',
                          DateFormat('MMMM dd, yyyy').format(widget.appointment.appointmentDate),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.access_time, 'Time', widget.appointment.timeSlot),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.info,
                          'Status',
                          widget.appointment.status.name.toUpperCase(),
                          valueColor: _getStatusColor(widget.appointment.status),
                        ),
                        if (widget.appointment.consultationFee > 0) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.attach_money,
                            'Consultation Fee',
                            '\$${widget.appointment.consultationFee.toStringAsFixed(2)}',
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Symptoms Card
                  if (widget.appointment.symptoms != null && widget.appointment.symptoms!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Your Symptoms',
                      child: Text(
                        widget.appointment.symptoms!,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                  // Cancel Reason Card
                  if (widget.appointment.cancelReason != null && widget.appointment.cancelReason!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Cancellation Reason',
                      child: Text(
                        widget.appointment.cancelReason!,
                        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.red),
                      ),
                    ),
                  ],

                  // Medical Record Card
                  if (_medicalRecord != null) ...[
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Medical Record',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.medical_services, 'Diagnosis', _medicalRecord!.diagnosis),
                          
                          if (_medicalRecord!.prescriptions.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Prescriptions:',
                              style: TextStyle(
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
                                    _buildPrescriptionDetail('Dosage', prescription.dosage),
                                    _buildPrescriptionDetail('Frequency', prescription.frequency),
                                    _buildPrescriptionDetail('Duration', '${prescription.durationDays} days'),
                                    if (prescription.instructions != null && prescription.instructions!.isNotEmpty)
                                      _buildPrescriptionDetail('Instructions', prescription.instructions!),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],

                          if (_medicalRecord!.labTests != null && _medicalRecord!.labTests!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Lab Tests:',
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

                  // Review Card
                  if (_review != null) ...[
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Your Review',
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

                  // Rate Button
                  if (widget.appointment.status == AppointmentStatus.completed && _review == null) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showRatingDialog,
                        icon: const Icon(Icons.star),
                        label: const Text('Rate Doctor'),
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

