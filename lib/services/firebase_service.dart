import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';
import '../models/appointment_model.dart';
import '../models/medical_record_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Invoice methods
  Future<InvoiceModel?> getInvoice(String invoiceId) async {
    try {
      final doc = await _firestore.collection('invoices').doc(invoiceId).get();
      if (!doc.exists) return null;
      return InvoiceModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  Future<List<InvoiceModel>> getInvoicesByPatient(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('invoices')
          .where('patientId', isEqualTo: patientId)
          .orderBy('invoiceDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateInvoice(String invoiceId, Map<String, dynamic> data) async {
    await _firestore.collection('invoices').doc(invoiceId).update(data);
  }

  // Appointment methods
  Future<void> updateAppointment(String appointmentId, Map<String, dynamic> data) async {
    await _firestore.collection('appointments').doc(appointmentId).update(data);
  }

  // Medical Record methods
  Future<List<MedicalRecordModel>> getMedicalRecordsByAppointment(String appointmentId) async {
    try {
      final snapshot = await _firestore
          .collection('medical_records')
          .where('appointmentId', isEqualTo: appointmentId)
          .get();
      return snapshot.docs
          .map((doc) => MedicalRecordModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Review methods
  Future<List<ReviewModel>> getReviewsByDoctor(String doctorId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('doctorId', isEqualTo: doctorId)
          .get();
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> createReview(ReviewModel review) async {
    // Get patient name to include in review
    String patientName = 'Unknown';
    try {
      final patientDoc = await _firestore.collection('users').doc(review.patientId).get();
      if (patientDoc.exists) {
        final data = patientDoc.data()!;
        patientName = data['name'] ?? data['fullname'] ?? '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        if (patientName.isEmpty) patientName = 'Unknown';
      }
    } catch (e) {
      // Use default if fetch fails
    }
    
    final reviewData = review.toMap();
    reviewData['patientName'] = patientName;
    await _firestore.collection('reviews').add(reviewData);
  }

  // Appointment methods for doctors
  Future<List<AppointmentModel>> getAppointmentsByDoctor(String doctorId) async {
    try {
      print('Fetching appointments for doctor: $doctorId');
      
      // First, let's check if there are any appointments at all (for debugging)
      final allAppointmentsSnapshot = await _firestore
          .collection('appointments')
          .limit(5)
          .get();
      print('Total appointments in collection (sample): ${allAppointmentsSnapshot.docs.length}');
      if (allAppointmentsSnapshot.docs.isNotEmpty) {
        final sampleDoc = allAppointmentsSnapshot.docs.first;
        final sampleData = sampleDoc.data();
        print('Sample appointment fields: ${sampleData.keys.toList()}');
        print('Sample appointment doctorId: ${sampleData['doctorId']} (type: ${sampleData['doctorId'].runtimeType})');
        print('Looking for doctorId: $doctorId (type: ${doctorId.runtimeType})');
      }
      
      // Try query with where clause first
      QuerySnapshot<Map<String, dynamic>> snapshot;
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docsToProcess = [];
      
      try {
        snapshot = await _firestore
            .collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .get();
        docsToProcess = snapshot.docs;
        print('Found ${docsToProcess.length} appointment documents for doctor $doctorId using where query');
      } catch (e) {
        print('Where query failed: $e, trying fallback approach');
        // Fallback: get all appointments and filter in memory
        final allSnapshot = await _firestore
            .collection('appointments')
            .get();
        print('Fetched all ${allSnapshot.docs.length} appointments for manual filtering');
        docsToProcess = allSnapshot.docs;
      }
      
      // If no results with exact match, try to get all appointments and filter manually
      if (docsToProcess.isEmpty) {
        print('No results from where query, trying manual filter on all appointments');
        final allSnapshot = await _firestore
            .collection('appointments')
            .get();
        print('Total appointments in database: ${allSnapshot.docs.length}');
        
        docsToProcess = allSnapshot.docs.where((doc) {
          final data = doc.data();
          final docDoctorId = data['doctorId']?.toString() ?? '';
          final match = docDoctorId == doctorId || 
                 docDoctorId.toLowerCase() == doctorId.toLowerCase() ||
                 docDoctorId.trim() == doctorId.trim();
          if (match) {
            print('Found matching appointment: ${doc.id}, doctorId: $docDoctorId');
          }
          return match;
        }).toList();
        
        print('Found ${docsToProcess.length} appointments with manual filtering');
      }
      
      final appointments = <AppointmentModel>[];
      
      print('Processing ${docsToProcess.length} appointments');
      
      for (var doc in docsToProcess) {
        try {
          final data = doc.data();
          print('Processing appointment ${doc.id}: ${data.keys.toList()}');
          print('  doctorId in doc: ${data['doctorId']}, looking for: $doctorId');
          
          // Use AppointmentModel.fromMap for consistent parsing, but handle 'time' field
          // Convert 'time' to 'appointmentDate' and 'timeSlot' if needed
          final processedData = Map<String, dynamic>.from(data);
          
          if (data['time'] is Timestamp && data['appointmentDate'] == null) {
            final time = (data['time'] as Timestamp).toDate();
            processedData['appointmentDate'] = time;
            if (data['timeSlot'] == null) {
              processedData['timeSlot'] = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
            }
          }
          
          // Ensure hospitalId is set from shiftId if needed
          if (processedData['hospitalId'] == null && processedData['shiftId'] != null) {
            processedData['hospitalId'] = processedData['shiftId'];
          }
          
          final appointment = AppointmentModel.fromMap(processedData, doc.id);
          appointments.add(appointment);
          print('  Successfully parsed appointment ${doc.id}');
        } catch (e, stackTrace) {
          print('Error parsing appointment ${doc.id}: $e');
          print('Stack trace: $stackTrace');
          // Continue processing other appointments
        }
      }
      
      print('Successfully parsed ${appointments.length} appointments');
      
      // Sort by appointment date/time in descending order (newest first)
      appointments.sort((a, b) {
        // First compare by appointment date
        final dateCompare = b.appointmentDate.compareTo(a.appointmentDate);
        if (dateCompare != 0) return dateCompare;
        // If same date, compare by creation time
        return b.createdAt.compareTo(a.createdAt);
      });
      
      return appointments;
    } catch (e, stackTrace) {
      // Log the error for debugging but still return empty list
      print('Error fetching appointments for doctor $doctorId: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Invoice methods for doctors
  Future<List<InvoiceModel>> getInvoicesByDoctor(String doctorId) async {
    try {
      final snapshot = await _firestore
          .collection('invoices')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('invoiceDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get all invoices (for both doctors and patients)
  Future<List<InvoiceModel>> getAllInvoices() async {
    try {
      final snapshot = await _firestore
          .collection('invoices')
          .orderBy('invoiceDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // User methods
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      
      // Convert Firestore user data to UserModel
      // Note: Firestore might have 'name' instead of firstName/lastName
      final name = (data['name'] ?? '').toString();
      final nameParts = name.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      return UserModel(
        uid: doc.id,
        email: data['email'] ?? '',
        firstName: firstName,
        lastName: lastName,
        phoneNumber: data['phone'] ?? data['phoneNumber'] ?? '',
        role: UserRole.values.firstWhere(
          (e) => e.name == (data['role'] ?? 'patient'),
          orElse: () => UserRole.patient,
        ),
        status: AccountStatus.values.firstWhere(
          (e) => e.name == (data['status'] ?? (data['approved'] == true ? 'active' : 'pending')),
          orElse: () => AccountStatus.pending,
        ),
        createdAt: (data['createdAt'] is Timestamp)
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: data['updatedAt'] != null
            ? ((data['updatedAt'] is Timestamp)
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.parse(data['updatedAt']))
            : null,
        profileImageUrl: data['profileImageUrl'],
      );
    } catch (e) {
      return null;
    }
  }

  // Create invoice
  Future<String> createInvoice(InvoiceModel invoice) async {
    try {
      final docRef = await _firestore.collection('invoices').add(invoice.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }
}

