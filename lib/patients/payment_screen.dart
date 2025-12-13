import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../l10n/app_localizations.dart';

class PaymentScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const PaymentScreen({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String _formatCardNumber(String value) {
    // Remove all non-digits
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Limit to 16 digits
    final limitedDigits = digitsOnly.length > 16 ? digitsOnly.substring(0, 16) : digitsOnly;
    
    // Format as XXXX XXXX XXXX XXXX
    final buffer = StringBuffer();
    for (int i = 0; i < limitedDigits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(limitedDigits[i]);
    }
    return buffer.toString();
  }

  bool _isValidCardNumber(String cardNumber) {
    // Luhn algorithm validation
    if (cardNumber.length != 16) return false;
    
    int sum = 0;
    bool alternate = false;
    
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return (sum % 10) == 0;
  }

  String _formatExpiry(String value) {
    // Remove all non-digits
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Format as MM/YY
    if (digitsOnly.length >= 2) {
      return '${digitsOnly.substring(0, 2)}/${digitsOnly.length > 2 ? digitsOnly.substring(2, 4) : ''}';
    }
    return digitsOnly;
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Generate dummy transaction ID
      final transactionId = 'TXN${const Uuid().v4().substring(0, 8).toUpperCase()}';

      final fs = FirebaseFirestore.instance;
      
      // Get appointment details for notifications
      final appointmentDoc = await fs.collection('appointments').doc(widget.invoice.appointmentId).get();
      final appointmentData = appointmentDoc.data();
      final doctorId = appointmentData?['doctorId'] ?? '';
      final doctorName = appointmentData?['doctorName'] ?? '';
      final patientId = appointmentData?['patientId'] ?? '';
      final patientName = appointmentData?['patientName'] ?? '';
      final hospitalName = appointmentData?['hospitalName'] ?? '';

      // Update invoice status to paid
      await _firebaseService.updateInvoice(
        widget.invoice.id,
        {
          'status': InvoiceStatus.paid.name,
          'isPaid': true,
          'paidAt': DateTime.now().toIso8601String(),
          'paymentMethod': 'Card',
          'transactionId': transactionId,
        },
      );

      // Update appointment payment status and mark as completed
      await _firebaseService.updateAppointment(
        widget.invoice.appointmentId,
        {
          'isPaid': true,
          'paymentId': transactionId,
          'status': 'completed',
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Also update in patient's appointments subcollection
      if (patientId.isNotEmpty && widget.invoice.appointmentId.isNotEmpty) {
        try {
          // Try direct document reference first (more reliable)
          final patientApptRef = fs
              .collection('users')
              .doc(patientId)
              .collection('appointments')
              .doc(widget.invoice.appointmentId);
          
          final patientApptDoc = await patientApptRef.get();
          
          if (patientApptDoc.exists) {
            await patientApptRef.update({
              'isPaid': true,
              'paymentId': transactionId,
              'status': 'completed',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            // Fallback: try querying by appointmentId field if document ID doesn't match
            final patientApptQuery = await fs
                .collection('users')
                .doc(patientId)
                .collection('appointments')
                .where('appointmentId', isEqualTo: widget.invoice.appointmentId)
                .limit(1)
                .get();
            
            if (patientApptQuery.docs.isNotEmpty) {
              await patientApptQuery.docs.first.reference.update({
                'isPaid': true,
                'paymentId': transactionId,
                'status': 'completed',
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
        } catch (e) {
          // Log error but don't fail the payment
          debugPrint('Error updating patient appointment subcollection: $e');
        }
      }

      // Send FCM notification to doctor about payment
      if (doctorId.isNotEmpty) {
        await NotificationService.sendFCMNotification(
          userId: doctorId,
          title: 'Payment Received',
          body: 'Patient $patientName has paid OMR-${widget.invoice.total.toStringAsFixed(2)} for appointment. Transaction ID: $transactionId',
          data: {
            'type': 'payment_received',
            'appointmentId': widget.invoice.appointmentId,
            'invoiceId': widget.invoice.id,
            'amount': widget.invoice.total.toStringAsFixed(2),
            'transactionId': transactionId,
          },
        );

        await fs.collection('notifications').add({
          'userId': doctorId,
          'toRole': 'doctor',
          'doctorId': doctorId,
          'title': 'Payment Received',
          'body': 'Patient $patientName has paid OMR-${widget.invoice.total.toStringAsFixed(2)} for appointment. Transaction ID: $transactionId',
          'appointmentId': widget.invoice.appointmentId,
          'invoiceId': widget.invoice.id,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      // Send FCM notification to patient
      if (patientId.isNotEmpty) {
        await NotificationService.sendFCMNotification(
          userId: patientId,
          title: 'Payment Successful',
          body: 'Your payment of OMR-${widget.invoice.total.toStringAsFixed(2)} has been processed successfully. Transaction ID: $transactionId',
          data: {
            'type': 'payment_successful',
            'appointmentId': widget.invoice.appointmentId,
            'invoiceId': widget.invoice.id,
            'amount': widget.invoice.total.toStringAsFixed(2),
            'transactionId': transactionId,
          },
        );

        await fs.collection('notifications').add({
          'userId': patientId,
          'toRole': 'patient',
          'title': 'Payment Successful',
          'body': 'Your payment of OMR-${widget.invoice.total.toStringAsFixed(2)} has been processed successfully. Transaction ID: $transactionId',
          'appointmentId': widget.invoice.appointmentId,
          'invoiceId': widget.invoice.id,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
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
        title: Text(
          AppLocalizations.of(context)!.payment,
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
                    // Amount Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: darkButtonColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.total_amount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'OMR-${widget.invoice.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card Details Card
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
                            AppLocalizations.of(context)!.card_details,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkButtonColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _cardNumberController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.card_number,
                              hintText: '1234 5678 9012 3456',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.credit_card),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(16),
                            ],
                            onChanged: (value) {
                              final formatted = _formatCardNumber(value);
                              if (formatted != value) {
                                _cardNumberController.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(offset: formatted.length),
                                );
                              }
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter card number';
                              }
                              final digitsOnly = value.replaceAll(' ', '');
                              if (digitsOnly.length != 16) {
                                return 'Card number must be 16 digits';
                              }
                              // Check if all digits are zeros
                              if (digitsOnly == '0000000000000000' || 
                                  digitsOnly.replaceAll('0', '').isEmpty) {
                                return 'Invalid card number';
                              }
                              // Validate using Luhn algorithm
                              if (!_isValidCardNumber(digitsOnly)) {
                                return 'Invalid card number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _cardHolderController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.card_holder_name,
                              hintText: 'John Doe',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.person),
                            ),
                            textCapitalization: TextCapitalization.words,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter card holder name';
                              }
                              // Check if name contains only letters and spaces
                              if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                                return 'Name must contain only letters';
                              }
                              // Check if name has at least 2 characters
                              if (value.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _expiryController,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!.expiry_date,
                                    hintText: 'MM/YY',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: const Icon(Icons.calendar_today),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  onChanged: (value) {
                                    final formatted = _formatExpiry(value);
                                    if (formatted != value) {
                                      _expiryController.value = TextEditingValue(
                                        text: formatted,
                                        selection: TextSelection.collapsed(offset: formatted.length),
                                      );
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (value.length != 5) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _cvvController,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!.cvv,
                                    hintText: '123',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: const Icon(Icons.lock),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (value.length < 3 || value.length > 4) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Security Notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This is a dummy payment gateway. No real charges will be made.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pay Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _processPayment,
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
                                'Pay OMR-${widget.invoice.total.toStringAsFixed(2)}',
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
