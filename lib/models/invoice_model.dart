import 'package:cloud_firestore/cloud_firestore.dart';

enum InvoiceStatus { pending, paid }

class InvoiceModel {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final DateTime invoiceDate;
  final List<InvoiceItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final InvoiceStatus status;
  final bool isPaid;
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? transactionId;
  final DateTime createdAt;

  InvoiceModel({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.invoiceDate,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.status = InvoiceStatus.pending,
    this.isPaid = false,
    this.paidAt,
    this.paymentMethod,
    this.transactionId,
    required this.createdAt,
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime _parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.parse(date);
      if (date is DateTime) return date;
      return DateTime.now();
    }

    return InvoiceModel(
      id: id,
      appointmentId: map['appointmentId'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      invoiceDate: _parseDate(map['invoiceDate']),
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromMap(item))
              .toList() ??
          [],
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      status: map['status'] != null
          ? (map['status'] == 'paid' || map['status'] == InvoiceStatus.paid.name)
              ? InvoiceStatus.paid
              : InvoiceStatus.pending
          : (map['isPaid'] ?? false) ? InvoiceStatus.paid : InvoiceStatus.pending,
      isPaid: map['isPaid'] ?? false,
      paidAt: map['paidAt'] != null ? _parseDate(map['paidAt']) : null,
      paymentMethod: map['paymentMethod'],
      transactionId: map['transactionId'],
      createdAt: _parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'patientId': patientId,
      'doctorId': doctorId,
      'invoiceDate': invoiceDate.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'status': status.name,
      'isPaid': isPaid,
      'paidAt': paidAt?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  InvoiceModel copyWith({
    String? appointmentId,
    String? patientId,
    String? doctorId,
    DateTime? invoiceDate,
    List<InvoiceItem>? items,
    double? subtotal,
    double? tax,
    double? total,
    InvoiceStatus? status,
    bool? isPaid,
    DateTime? paidAt,
    String? paymentMethod,
    String? transactionId,
  }) {
    return InvoiceModel(
      id: id,
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt,
    );
  }
}

class InvoiceItem {
  final String description;
  final double amount;
  final int quantity;

  InvoiceItem({
    required this.description,
    required this.amount,
    this.quantity = 1,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
      'quantity': quantity,
    };
  }

  double get totalAmount => amount * quantity;
}

