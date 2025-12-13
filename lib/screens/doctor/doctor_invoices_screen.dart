import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../models/invoice_model.dart';
import '../../models/user_model.dart';
import '../../l10n/app_localizations.dart';
import 'doctor_invoice_detail_screen.dart';

class DoctorInvoicesScreen extends StatefulWidget {
  const DoctorInvoicesScreen({super.key});

  @override
  State<DoctorInvoicesScreen> createState() => _DoctorInvoicesScreenState();
}

class _DoctorInvoicesScreenState extends State<DoctorInvoicesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<InvoiceModel> _invoices = [];
  Map<String, UserModel> _patientUsers = {}; // Stores both patients and doctors
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      // Load all invoices (not just doctor's own)
      final invoices = await _firebaseService.getAllInvoices();
      
      // Fetch patient user information for each invoice
      for (var invoice in invoices) {
        if (!_patientUsers.containsKey(invoice.patientId)) {
          final patientUser = await _firebaseService.getUser(invoice.patientId);
          if (patientUser != null) {
            _patientUsers[invoice.patientId] = patientUser;
          }
        }
        // Also fetch doctor information for display
        if (!_patientUsers.containsKey(invoice.doctorId)) {
          final doctorUser = await _firebaseService.getUser(invoice.doctorId);
          if (doctorUser != null) {
            _patientUsers[invoice.doctorId] = doctorUser;
          }
        }
      }
      
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc?.error ?? "Error"} loading invoices: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          loc?.my_invoices ?? 'My Invoices',
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
          : _invoices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        loc?.no_invoices_yet ?? 'No invoices yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInvoices,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = _invoices[index];
                      final patientName = _patientUsers[invoice.patientId]?.fullName ?? 'Unknown Patient';
                      final doctorName = _patientUsers[invoice.doctorId]?.fullName ?? 'Unknown Doctor';
                      return _buildInvoiceCard(invoice, patientName, doctorName, darkButtonColor, loc);
                    },
                  ),
                ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice, String patientName, String doctorName, Color darkButtonColor, AppLocalizations? loc) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorInvoiceDetailScreen(
              invoice: invoice,
              patientName: patientName,
            ),
          ),
        ).then((_) {
          _loadInvoices(); // Refresh list after returning
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${loc?.invoice ?? "Invoice"} #${invoice.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${loc?.patient ?? "Patient"}: $patientName',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${loc?.doctor ?? "Doctor"}: $doctorName',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, yyyy').format(invoice.invoiceDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: invoice.status == InvoiceStatus.paid ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    invoice.status == InvoiceStatus.paid 
                        ? (loc?.paid_status ?? 'PAID')
                        : (loc?.pending_status ?? 'PENDING'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc?.total_amount ?? 'Total Amount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'OMR-${invoice.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkButtonColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

