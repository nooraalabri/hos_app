import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../models/invoice_model.dart';
import '../../l10n/app_localizations.dart';
import 'add_report_screen.dart';
import 'generate_invoice_screen.dart';
import 'medical_records.dart';
import 'doctor_invoice_detail_screen.dart';
import '../../services/notification_service.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  List<AppointmentModel> _appointments = [];
  Map<String, UserModel> _patientUsers = {};
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        print('Loading appointments for doctor UID: ${user.uid}');
        final appointments = await _firebaseService.getAppointmentsByDoctor(user.uid);
        print('Received ${appointments.length} appointments from service');
        
        // Fetch patient user information for each appointment
        for (var appointment in appointments) {
          if (!_patientUsers.containsKey(appointment.patientId)) {
            final patientUser = await _firebaseService.getUser(appointment.patientId);
            if (patientUser != null) {
              _patientUsers[appointment.patientId] = patientUser;
            }
          }
        }
        
        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
        
        if (mounted && appointments.isEmpty) {
          // Show a message if no appointments found (for debugging)
          print('No appointments found for doctor ${user.uid}');
        }
      } catch (e, stackTrace) {
        print('Error in _loadAppointments: $e');
        print('Stack trace: $stackTrace');
        setState(() => _isLoading = false);
        if (mounted) {
          final loc = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${loc?.error ?? "Error"} loading appointments: $e'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } else {
      setState(() => _isLoading = false);
      print('No current user found');
    }
  }

  List<AppointmentModel> _getFilteredAppointments(AppointmentStatus status) {
    return _appointments.where((a) => a.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final backgroundColor = const Color(0xFFDDE8EB);
    final darkButtonColor = const Color(0xFF2E4E53);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          loc?.my_appointments ?? 'My Appointments',
          style: const TextStyle(
            fontFamily: 'Serif',
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: darkButtonColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: darkButtonColor,
          tabs: [
            Tab(text: loc?.pending ?? 'Pending'),
            Tab(text: loc?.confirmed ?? 'Confirmed'),
            Tab(text: loc?.completed ?? 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentList(AppointmentStatus.pending, darkButtonColor, loc),
                _buildAppointmentList(AppointmentStatus.confirmed, darkButtonColor, loc),
                _buildAppointmentList(AppointmentStatus.completed, darkButtonColor, loc),
              ],
            ),
    );
  }

  Widget _buildAppointmentList(AppointmentStatus status, Color darkButtonColor, AppLocalizations? loc) {
    final filteredAppointments = _getFilteredAppointments(status);

    if (filteredAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '${loc?.no_appointments_yet ?? "No"} ${status.name} ${loc?.appointments ?? "appointments"}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredAppointments.length,
        itemBuilder: (context, index) {
          final appointment = filteredAppointments[index];
          return _buildAppointmentCard(appointment, darkButtonColor);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment, Color darkButtonColor) {
    final patientUser = _patientUsers[appointment.patientId];
    final patientName = patientUser != null 
        ? patientUser.fullName
        : 'Patient ${appointment.patientId.substring(0, 8)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE8EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person, color: darkButtonColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(appointment.status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          appointment.status.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(appointment.appointmentDate),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  appointment.timeSlot,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            if (appointment.symptoms != null && appointment.symptoms!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.medical_services, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.symptoms!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            // Action Buttons based on status
            _buildActionButtons(appointment, patientName, darkButtonColor),
          ],
        ),
      ),
    );
  }

  bool _isFutureAppointment(AppointmentModel appointment) {
    final today = DateTime.now();
    final appointmentDateOnly = DateTime(
      appointment.appointmentDate.year,
      appointment.appointmentDate.month,
      appointment.appointmentDate.day,
    );
    final todayOnly = DateTime(today.year, today.month, today.day);
    return appointmentDateOnly.isAfter(todayOnly);
  }

  Widget _buildActionButtons(AppointmentModel appointment, String patientName, Color darkButtonColor) {
    final loc = AppLocalizations.of(context);
    final isFuture = _isFutureAppointment(appointment);
    
    if (appointment.status == AppointmentStatus.pending) {
      // Accept/Reject buttons for pending appointments
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _acceptAppointment(appointment),
              icon: const Icon(Icons.check, size: 18),
              label: Text(loc?.confirm ?? 'Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _rejectAppointment(appointment),
              icon: const Icon(Icons.close, size: 18),
              label: Text(loc?.reject ?? 'Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    } else if (appointment.status == AppointmentStatus.confirmed) {
      // Add Report button for confirmed appointments - only show if not future appointment
      if (isFuture) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Report can only be added on or after the appointment date',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _navigateToAddReport(appointment, patientName),
          icon: const Icon(Icons.add_chart, size: 18),
          label: Text(loc?.add_report ?? 'Add Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: darkButtonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    } else if (appointment.status == AppointmentStatus.completed) {
      // Show buttons for completed appointments
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToMedicalRecord(appointment, patientName),
                  icon: const Icon(Icons.medical_services, size: 18),
                  label: Text(loc?.medical_record ?? 'View Medical Record'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToAddReport(appointment, patientName),
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(loc?.add_report ?? 'Edit Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<InvoiceModel?>(
            future: _getInvoiceForAppointment(appointment.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              
              final invoice = snapshot.data;
              if (invoice == null) {
                // No invoice yet - show Generate Invoice button
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToGenerateInvoice(appointment, patientName),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: Text(loc?.generate_invoice ?? 'Generate Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkButtonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                );
              } else {
                // Invoice exists - show View Invoice button
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToInvoiceDetail(invoice, patientName),
                    icon: Icon(
                      invoice.status == InvoiceStatus.paid ? Icons.check_circle : Icons.receipt_long,
                      size: 18,
                    ),
                    label: Text(
                      invoice.status == InvoiceStatus.paid 
                          ? (loc?.payment_completed ?? 'View Payment')
                          : (loc?.invoice_details ?? 'View Invoice'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: invoice.status == InvoiceStatus.paid ? Colors.green : darkButtonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }

  Future<void> _acceptAppointment(AppointmentModel appointment) async {
    try {
      await _firebaseService.updateAppointment(appointment.id, {
        'status': AppointmentStatus.confirmed.name,
      });

      // Also update in patient's collection
      final fs = FirebaseFirestore.instance;
      final patientApptQuery = await fs
          .collection('users')
          .doc(appointment.patientId)
          .collection('appointments')
          .where(FieldPath.documentId, isEqualTo: appointment.id)
          .limit(1)
          .get();
      
      if (patientApptQuery.docs.isNotEmpty) {
        await patientApptQuery.docs.first.reference.update({
          'status': AppointmentStatus.confirmed.name,
        });
      }

      // Send notification to patient
      await NotificationService.sendFCMNotification(
        userId: appointment.patientId,
        title: 'Appointment Confirmed',
        body: 'Your appointment has been confirmed by the doctor.',
        data: {
          'type': 'appointment_confirmed',
          'appointmentId': appointment.id,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment confirmed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectAppointment(AppointmentModel appointment) async {
    try {
      await _firebaseService.updateAppointment(appointment.id, {
        'status': AppointmentStatus.cancelled.name,
      });

      // Also update in patient's collection
      final fs = FirebaseFirestore.instance;
      final patientApptQuery = await fs
          .collection('users')
          .doc(appointment.patientId)
          .collection('appointments')
          .where(FieldPath.documentId, isEqualTo: appointment.id)
          .limit(1)
          .get();
      
      if (patientApptQuery.docs.isNotEmpty) {
        await patientApptQuery.docs.first.reference.update({
          'status': AppointmentStatus.cancelled.name,
        });
      }

      // Send notification to patient
      await NotificationService.sendFCMNotification(
        userId: appointment.patientId,
        title: 'Appointment Cancelled',
        body: 'Your appointment has been cancelled by the doctor.',
        data: {
          'type': 'appointment_cancelled',
          'appointmentId': appointment.id,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToAddReport(AppointmentModel appointment, String patientName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReport(
          appointmentId: appointment.id,
          patientId: appointment.patientId,
          doctorId: appointment.doctorId,
        ),
      ),
    ).then((_) => _loadAppointments());
  }

  void _navigateToMedicalRecord(AppointmentModel appointment, String patientName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicalRecord(
          patientId: appointment.patientId,
          appointmentId: appointment.id,
          doctorId: appointment.doctorId,
        ),
      ),
    );
  }

  void _navigateToGenerateInvoice(AppointmentModel appointment, String patientName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenerateInvoiceScreen(
          appointment: appointment,
          patientName: patientName,
        ),
      ),
    ).then((_) => _loadAppointments());
  }

  void _navigateToInvoiceDetail(InvoiceModel invoice, String patientName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorInvoiceDetailScreen(
          invoice: invoice,
          patientName: patientName,
        ),
      ),
    );
  }

  Future<InvoiceModel?> _getInvoiceForAppointment(String appointmentId) async {
    try {
      final fs = FirebaseFirestore.instance;
      final invoiceQuery = await fs
          .collection('invoices')
          .where('appointmentId', isEqualTo: appointmentId)
          .limit(1)
          .get();
      
      if (invoiceQuery.docs.isNotEmpty) {
        return InvoiceModel.fromMap(invoiceQuery.docs.first.data(), invoiceQuery.docs.first.id);
      }
      return null;
    } catch (e) {
      return null;
    }
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
