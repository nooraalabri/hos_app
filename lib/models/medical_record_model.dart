import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecordModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String appointmentId;
  final DateTime recordDate;
  final String diagnosis;
  final String? symptoms;
  final List<PrescriptionItem> prescriptions;
  final String? labTests;
  final String? notes;
  final List<String>? attachments; // URLs to uploaded documents
  final DateTime createdAt;
  final DateTime? updatedAt;

  MedicalRecordModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentId,
    required this.recordDate,
    required this.diagnosis,
    this.symptoms,
    required this.prescriptions,
    this.labTests,
    this.notes,
    this.attachments,
    required this.createdAt,
    this.updatedAt,
  });

  factory MedicalRecordModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime _parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.parse(date);
      if (date is DateTime) return date;
      return DateTime.now();
    }

    return MedicalRecordModel(
      id: id,
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      appointmentId: map['appointmentId'] ?? '',
      recordDate: _parseDate(map['recordDate']),
      diagnosis: map['diagnosis'] ?? '',
      symptoms: map['symptoms'],
      prescriptions: (map['prescriptions'] as List<dynamic>?)
              ?.map((item) => PrescriptionItem.fromMap(item))
              .toList() ??
          [],
      labTests: map['labTests'],
      notes: map['notes'],
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : null,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? _parseDate(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'appointmentId': appointmentId,
      'recordDate': recordDate.toIso8601String(),
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'prescriptions': prescriptions.map((item) => item.toMap()).toList(),
      'labTests': labTests,
      'notes': notes,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class PrescriptionItem {
  final String medicineName;
  final String dosage;
  final String frequency;
  final int durationDays;
  final String? instructions;

  PrescriptionItem({
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
    this.instructions,
  });

  factory PrescriptionItem.fromMap(Map<String, dynamic> map) {
    return PrescriptionItem(
      medicineName: map['medicineName'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      durationDays: map['durationDays'] ?? 0,
      instructions: map['instructions'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineName': medicineName,
      'dosage': dosage,
      'frequency': frequency,
      'durationDays': durationDays,
      'instructions': instructions,
    };
  }
}

