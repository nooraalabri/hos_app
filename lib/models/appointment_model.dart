import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { pending, confirmed, cancelled, completed, rescheduled }

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String hospitalId;
  final DateTime appointmentDate;
  final String timeSlot; // e.g., "10:00 AM - 10:30 AM"
  final AppointmentStatus status;
  final String? symptoms;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double consultationFee;
  final bool isPaid;
  final String? paymentId;
  final String? cancelReason;
  final String? invoiceId;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.hospitalId,
    required this.appointmentDate,
    required this.timeSlot,
    required this.status,
    this.symptoms,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    required this.consultationFee,
    this.isPaid = false,
    this.paymentId,
    this.cancelReason,
    this.invoiceId,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime _parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.parse(date);
      if (date is DateTime) return date;
      return DateTime.now();
    }

    return AppointmentModel(
      id: id,
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      hospitalId: map['hospitalId'] ?? '',
      appointmentDate: _parseDate(map['appointmentDate']),
      timeSlot: map['timeSlot'] ?? '',
      status: () {
        final statusStr = (map['status'] ?? 'pending').toString().toLowerCase();
        // Handle both 'booked' and 'pending' as pending
        if (statusStr == 'booked' || statusStr == 'pending') {
          return AppointmentStatus.pending;
        }
        return AppointmentStatus.values.firstWhere(
          (e) => e.name == statusStr,
          orElse: () => AppointmentStatus.pending,
        );
      }(),
      symptoms: map['symptoms'],
      notes: map['notes'],
      createdAt: _parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? _parseDate(map['updatedAt']) : null,
      consultationFee: (map['consultationFee'] ?? 0).toDouble(),
      isPaid: map['isPaid'] ?? false,
      paymentId: map['paymentId'],
      cancelReason: map['cancelReason'],
      invoiceId: map['invoiceId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'hospitalId': hospitalId,
      'appointmentDate': appointmentDate.toIso8601String(),
      'timeSlot': timeSlot,
      'status': status.name,
      'symptoms': symptoms,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'consultationFee': consultationFee,
      'isPaid': isPaid,
      'paymentId': paymentId,
      'cancelReason': cancelReason,
      'invoiceId': invoiceId,
    };
  }

  AppointmentModel copyWith({
    String? patientId,
    String? doctorId,
    String? hospitalId,
    DateTime? appointmentDate,
    String? timeSlot,
    AppointmentStatus? status,
    String? symptoms,
    String? notes,
    DateTime? updatedAt,
    double? consultationFee,
    bool? isPaid,
    String? paymentId,
    String? cancelReason,
    String? invoiceId,
  }) {
    return AppointmentModel(
      id: id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      hospitalId: hospitalId ?? this.hospitalId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      consultationFee: consultationFee ?? this.consultationFee,
      isPaid: isPaid ?? this.isPaid,
      paymentId: paymentId ?? this.paymentId,
      cancelReason: cancelReason ?? this.cancelReason,
      invoiceId: invoiceId ?? this.invoiceId,
    );
  }
}

