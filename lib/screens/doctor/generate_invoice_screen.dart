import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/appointment_model.dart';
import '../../models/invoice_model.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../l10n/app_localizations.dart';

class GenerateInvoiceScreen extends StatefulWidget {
  final AppointmentModel appointment;
  final String patientName;

  const GenerateInvoiceScreen({
    super.key,
    required this.appointment,
    required this.patientName,
  });

  @override
  State<GenerateInvoiceScreen> createState() => _GenerateInvoiceScreenState();
}

class _GenerateInvoiceScreenState extends State<GenerateInvoiceScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final List<InvoiceItem> _items = [];
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController(text: '0');
  bool _isLoading = false;
  bool _medicationsLoaded = false; // Track if medications have been loaded

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicationsFromReport() async {
    if (_medicationsLoaded) {
      // Already loaded, don't load again to prevent duplicates
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medications have already been added. Clear items first if you want to reload.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final fs = FirebaseFirestore.instance;
      // Get report for this appointment
      final reportQuery = await fs
          .collection('reports')
          .where('appointmentId', isEqualTo: widget.appointment.id)
          .limit(1)
          .get();

      if (reportQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No report found for this appointment. Please add a report first.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final reportData = reportQuery.docs.first.data();
      final medicationsList = reportData['medicationsList'] as List<dynamic>?;

      if (medicationsList == null || medicationsList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No medications found in the report'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Filter out empty medication names and get exact count
      final validMedications = medicationsList
          .where((med) => med is Map<String, dynamic> && 
                         (med['name']?.toString().trim() ?? '').isNotEmpty)
          .toList();

      if (validMedications.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid medications found in the report'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Get existing item descriptions to check for duplicates
      final existingDescriptions = _items.map((item) => item.description.toLowerCase().trim()).toSet();

      // Add each medication as an invoice item, avoiding duplicates
      int addedCount = 0;
      setState(() {
        for (var med in validMedications) {
          if (med is Map<String, dynamic>) {
            final medName = med['name']?.toString().trim() ?? '';
            if (medName.isNotEmpty && !existingDescriptions.contains(medName.toLowerCase().trim())) {
              // Create invoice item with medication name
              // Amount will need to be entered manually or set to 0
              _items.add(InvoiceItem(
                description: medName,
                amount: 0.0, // Doctor needs to set the amount
                quantity: 1,
              ));
              addedCount++;
            }
          }
        }
        _medicationsLoaded = true;
      });

      if (addedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All medications are already in the invoice'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $addedCount medication(s) from report (exact count: ${validMedications.length}). Please set the amount for each.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading medications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addItem() {
    final loc = AppLocalizations.of(context);
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc?.required_field ?? 'Please enter description'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc?.invalid_amount ?? 'Please enter a valid amount'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _items.add(InvoiceItem(
        description: _descriptionController.text.trim(),
        amount: amount,
        quantity: 1,
      ));
      _descriptionController.clear();
      _amountController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      // Reset medications loaded flag if all items are removed
      if (_items.isEmpty) {
        _medicationsLoaded = false;
      }
    });
  }

  double get _subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  double get _tax {
    final taxPercent = double.tryParse(_taxController.text) ?? 0;
    return _subtotal * (taxPercent / 100);
  }

  double get _total {
    return _subtotal + _tax;
  }

  Future<void> _generateInvoice() async {
    final loc = AppLocalizations.of(context);
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc?.add_at_least_one_item ?? 'Please add at least one item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final invoice = InvoiceModel(
        id: const Uuid().v4(),
        appointmentId: widget.appointment.id,
        patientId: widget.appointment.patientId,
        doctorId: widget.appointment.doctorId,
        invoiceDate: DateTime.now(),
        items: _items,
        subtotal: _subtotal,
        tax: _tax,
        total: _total,
        status: InvoiceStatus.pending,
        createdAt: DateTime.now(),
      );

      final invoiceId = await _firebaseService.createInvoice(invoice);

      // Update appointment with invoice ID
      await _firebaseService.updateAppointment(
        widget.appointment.id,
        {'invoiceId': invoiceId},
      );

      // Get doctor name for notification
      final fs = FirebaseFirestore.instance;
      String doctorName = 'Doctor';
      try {
        final doctorDoc = await fs.collection('users').doc(widget.appointment.doctorId).get();
        doctorName = doctorDoc.data()?['name'] ?? doctorDoc.data()?['fullname'] ?? 'Doctor';
      } catch (e) {
        // Use default if fetch fails
      }

      // Send notification and email to patient about invoice
      await NotificationService.sendFCMNotification(
        userId: widget.appointment.patientId,
        title: 'New Invoice Generated',
        body: 'Dr. $doctorName has generated an invoice for your appointment. Total: OMR-${_total.toStringAsFixed(2)}',
        data: {
          'type': 'invoice_generated',
          'appointmentId': widget.appointment.id,
          'invoiceId': invoiceId,
          'amount': _total.toStringAsFixed(2),
        },
      );

      // Store notification in Firestore
      await fs.collection('notifications').add({
        'userId': widget.appointment.patientId,
        'toRole': 'patient',
        'title': 'New Invoice Generated',
        'body': 'Dr. $doctorName has generated an invoice for your appointment. Total: OMR-${_total.toStringAsFixed(2)}',
        'appointmentId': widget.appointment.id,
        'invoiceId': invoiceId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc?.invoice_generated_successfully ?? 'Invoice generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc?.error ?? "Failed"} to generate invoice: $e'),
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
          loc?.generate_invoice ?? 'Generate Invoice',
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
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Appointment Info Card
                    Container(
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
                            loc?.appointment_details ?? 'Appointment Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkButtonColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('${loc?.patient ?? "Patient"}: ${widget.patientName}'),
                          Text('${loc?.date ?? "Date"}: ${DateFormat('MMM dd, yyyy').format(widget.appointment.appointmentDate)}'),
                          Text('${loc?.time ?? "Time"}: ${widget.appointment.timeSlot}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Add Items Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc?.invoice_items ?? 'Invoice Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkButtonColor,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _loadMedicationsFromReport,
                          icon: const Icon(Icons.medication, size: 18),
                          label: const Text('Add Medications'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkButtonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: loc?.description ?? 'Description',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              labelText: '${loc?.amount ?? "Amount"} (OMR)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_circle),
                          color: darkButtonColor,
                          iconSize: 40,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Items List
                    if (_items.isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return ListTile(
                              title: Text(item.description),
                              subtitle: Text('${loc?.quantity ?? "Quantity"}: ${item.quantity}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Allow editing amount for items with 0 amount
                                  if (item.amount == 0.0)
                                    SizedBox(
                                      width: 80,
                                      child: TextFormField(
                                        initialValue: '0',
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Amount',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                        onChanged: (value) {
                                          final amount = double.tryParse(value) ?? 0.0;
                                          setState(() {
                                            _items[index] = InvoiceItem(
                                              description: item.description,
                                              amount: amount,
                                              quantity: item.quantity,
                                            );
                                          });
                                        },
                                      ),
                                    )
                                  else
                                    Text(
                                      'OMR-${item.totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _items.removeAt(index);
                                        // Reset medications loaded flag if all items are removed
                                        if (_items.isEmpty) {
                                          _medicationsLoaded = false;
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Tax Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _taxController,
                        decoration: InputDecoration(
                          labelText: '${loc?.tax ?? "Tax"} (%)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: darkButtonColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                loc?.subtotal ?? 'Subtotal',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              Text(
                                'OMR-${_subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${loc?.tax ?? "Tax"} (${_taxController.text}%)',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              Text(
                                'OMR-${_tax.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white70),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                loc?.total ?? 'Total',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'OMR-${_total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _generateInvoice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkButtonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                loc?.generate_invoice ?? 'Generate Invoice',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
