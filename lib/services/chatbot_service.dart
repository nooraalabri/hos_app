// lib/services/chatbot_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

enum ChatRole { patient, doctor, hospitaladmin, headadmin }

enum ChatIntent {
  projectInfo,
  timeSlots,
  doctorNames,
  freeTimeSlots,
  howToOpenApp,
  howToRegister,
  howToBook,
  paymentSteps,
  appointmentStatus,
  medicalRecords,
  invoices,
  appNavigation,
  generalHelp,
  unknown
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageType? type;
  final Map<String, dynamic>? data; // For interactive elements

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type,
    this.data,
  });
}

enum ChatMessageType {
  doctorList,      // List of doctors with clickable items
  timeSlotList,    // List of time slots with clickable items
  bookingConfirmation, // Booking confirmation message
}

class ChatbotService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get role-based welcome message
  static String getWelcomeMessage(ChatRole role) {
    switch (role) {
      case ChatRole.patient:
        return "Hello! I'm your healthcare assistant. I can help you with:\n\n"
            "• Booking appointments\n"
            "• Viewing your medical records\n"
            "• Understanding invoices and payments\n"
            "• Finding doctors and hospitals\n"
            "• Time slots and availability\n"
            "• General app navigation\n\n"
            "How can I help you today?";
      
      case ChatRole.doctor:
        return "Hello Doctor! I'm here to assist you with:\n\n"
            "• Managing appointments\n"
            "• Adding patient reports and medications\n"
            "• Generating invoices\n"
            "• Viewing patient records\n"
            "• Managing your shifts\n"
            "• Understanding reviews\n\n"
            "What would you like to know?";
      
      case ChatRole.hospitaladmin:
        return "Hello Hospital Administrator! I can help you with:\n\n"
            "• Managing hospital staff\n"
            "• Approving doctors\n"
            "• Viewing hospital reports\n"
            "• Managing shifts\n"
            "• Hospital profile management\n\n"
            "How can I assist you?";
      
      case ChatRole.headadmin:
        return "Hello Head Administrator! I'm here to help with:\n\n"
            "• Approving hospitals and doctors\n"
            "• Viewing system-wide reports\n"
            "• Managing the platform\n"
            "• Understanding analytics\n\n"
            "What do you need help with?";
    }
  }

  // Detect intent from user message
  static ChatIntent detectIntent(String message) {
    final lowerMessage = message.toLowerCase().trim();
    
    // Project info - more specific matching
    if (_matchesExact(lowerMessage, [
      'what is this app', 'what is the app', 'about the app', 'about app',
      'what does this app do', 'app purpose', 'what is this project',
      'explain the app', 'tell me about the app', 'app information'
    ]) || (_matchesAny(lowerMessage, ['what', 'about', 'explain', 'tell']) && 
           _matchesAny(lowerMessage, ['app', 'application', 'project', 'system']))) {
      return ChatIntent.projectInfo;
    }

    // Free time slots - check this BEFORE general time slots
    if (_matchesExact(lowerMessage, [
      'free slot', 'free slots', 'available slot', 'available slots', 'open slot',
      'open slots', 'free time', 'available time', 'when can i book', 
      'what slots are free', 'free appointment', 'available appointment',
      'what times are available', 'when is available'
    ])) {
      return ChatIntent.freeTimeSlots;
    }

    // Shifts (for doctors and admins) - check this BEFORE general time slots
    if (_matchesExact(lowerMessage, [
      'shift', 'shifts', 'manage shift', 'managing shift', 'manage shifts', 'managing shifts',
      'my shift', 'my shifts', 'weekly shift', 'weekly shifts', 'add shift', 'edit shift',
      'shift schedule', 'shift management', 'work schedule', 'my schedule'
    ])) {
      return ChatIntent.timeSlots; // Use timeSlots intent for shift-related queries
    }

    // Time slots - general
    if (_matchesExact(lowerMessage, [
      'time slot', 'time slots', 'available times', 'what times', 'when available',
      'schedule', 'timing', 'hours', 'working hours', 'shift time', 'what time'
    ])) {
      return ChatIntent.timeSlots;
    }

    // Doctor names - improved matching (check for doctor + any query word)
    final hasDoctor = lowerMessage.contains('doctor') || lowerMessage.contains('doctors');
    if (hasDoctor) {
      // If message contains doctor and any query word, it's asking about doctors
      if (_matchesAny(lowerMessage, [
        'available', 'list', 'show', 'who', 'which', 'what', 'name', 'names', 'all', 'see',
        'are', 'can', 'find', 'search', 'get', 'have', 'there', 'tell'
      ])) {
        return ChatIntent.doctorNames;
      }
      // Also match if it's just asking about doctors in general
      if (lowerMessage.split(' ').length <= 5 && hasDoctor) {
        // Short queries like "doctors", "show doctors", "list doctors"
        return ChatIntent.doctorNames;
      }
    }


    // How to open app
    if (_matches(lowerMessage, [
      'how to open', 'how do i open', 'open the app', 'launch app', 'start app',
      'how to start', 'how to use', 'how to access'
    ])) {
      return ChatIntent.howToOpenApp;
    }

    // How to register
    if (_matches(lowerMessage, [
      'how to register', 'how do i register', 'registration', 'sign up', 'create account',
      'new account', 'register as', 'how to sign up', 'create profile'
    ])) {
      return ChatIntent.howToRegister;
    }

    // How to book - more specific
    if (_matchesExact(lowerMessage, [
      'how to book', 'how do i book', 'book appointment', 'make appointment', 'schedule appointment',
      'book a slot', 'reserve appointment', 'how to schedule', 'booking process',
      'how can i book', 'how to make appointment', 'how to reserve', 'booking guide'
    ])) {
      return ChatIntent.howToBook;
    }

    // Payment steps - more specific
    if (_matchesExact(lowerMessage, [
      'how to pay', 'payment steps', 'pay invoice', 'how do i pay',
      'payment process', 'payment method', 'how to make payment', 'paying invoice',
      'how can i pay', 'payment guide', 'invoice payment', 'how to pay invoice'
    ]) || (_matchesAny(lowerMessage, ['how', 'what', 'when']) && 
           _matchesAny(lowerMessage, ['pay', 'payment', 'invoice']))) {
      return ChatIntent.paymentSteps;
    }

    // Appointment status - more specific
    if (_matchesExact(lowerMessage, [
      'my appointments', 'appointment status', 'view appointments', 'check appointment',
      'appointment list', 'appointments', 'my appointment', 'appointment details',
      'where are my appointments', 'show appointments', 'list appointments'
    ])) {
      return ChatIntent.appointmentStatus;
    }

    // Medical records - more specific
    if (_matchesExact(lowerMessage, [
      'medical record', 'medical records', 'my reports', 'my medical records',
      'view reports', 'view medical records', 'diagnosis', 'prescription', 
      'lab test', 'medical history', 'my diagnosis', 'my prescription'
    ]) || (_matchesAny(lowerMessage, ['my', 'view', 'see', 'show']) && 
           _matchesAny(lowerMessage, ['report', 'reports', 'medical', 'diagnosis', 'prescription']))) {
      return ChatIntent.medicalRecords;
    }

    // Invoices - more specific
    if (_matchesExact(lowerMessage, [
      'my invoices', 'invoice', 'invoices', 'my invoice', 'view invoices',
      'invoice list', 'bills', 'my bills', 'unpaid invoice', 'pending invoice'
    ]) || (_matchesAny(lowerMessage, ['my', 'view', 'see', 'show', 'unpaid', 'pending']) && 
           _matchesAny(lowerMessage, ['invoice', 'invoices', 'bill', 'bills']))) {
      return ChatIntent.invoices;
    }

    // App navigation
    if (_matchesAny(lowerMessage, [
      'navigation', 'navigate', 'menu', 'sidebar', 'where', 'how to find', 'how to go',
      'how to access', 'how do i get to', 'where is', 'how to open', 'how to view'
    ]) || (_matchesAny(lowerMessage, [
      'app', 'application'
    ]) && _matchesAny(lowerMessage, [
      'navigation', 'navigate', 'menu', 'use', 'how'
    ]))) {
      return ChatIntent.appNavigation;
    }

    // General help
    if (_matches(lowerMessage, [
      'help', 'what can you do', 'what do you do', 'guide me', 'assist me',
      'support', 'need help'
    ])) {
      return ChatIntent.generalHelp;
    }

    return ChatIntent.unknown;
  }

  // Process user message and return bot response (async to fetch from DB)
  // Returns a ChatMessage object for interactive elements
  static Future<ChatMessage> processMessage(String userMessage, ChatRole role, {String? action, Map<String, dynamic>? actionData}) async {
    final message = userMessage.toLowerCase().trim();

    // Handle actions (clicking on doctors, time slots, etc.)
    if (action != null && actionData != null) {
      if (action == 'select_doctor') {
        return await _handleDoctorSelection(actionData);
      } else if (action == 'select_timeslot') {
        return await _handleTimeSlotSelection(actionData, role);
      } else if (action == 'confirm_booking') {
        return await _handleBookingConfirmation(actionData, role);
      }
    }

    // Common greetings - only match exact greetings, not partial matches
    final isGreeting = message == 'hi' || 
                       message == 'hello' || 
                       message == 'hey' ||
                       message.startsWith('good morning') ||
                       message.startsWith('good afternoon') ||
                       message.startsWith('good evening') ||
                       message == 'hi there' ||
                       message == 'hello there';
    
    if (isGreeting) {
      return ChatMessage(
        text: "Hello! How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // Detect intent
    final intent = detectIntent(userMessage);

    // Handle based on intent
    switch (intent) {
      case ChatIntent.projectInfo:
        return ChatMessage(
          text: _getProjectInfo(),
          isUser: false,
          timestamp: DateTime.now(),
        );
      
      case ChatIntent.timeSlots:
        // For doctors asking about shifts, provide shift-specific info
        if (role == ChatRole.doctor && _matches(message, [
          'shift', 'shifts', 'manage shift', 'managing shift', 'manage shifts', 'managing shifts',
          'my shift', 'my shifts', 'weekly shift', 'weekly shifts'
        ])) {
          return ChatMessage(
            text: "To manage your shifts:\n\n"
                "1. Go to 'My Shifts' to add/edit shifts\n"
                "2. Go to 'Weekly Shifts' to view your schedule\n"
                "3. Patients can book appointments during your available shifts",
            isUser: false,
            timestamp: DateTime.now(),
          );
        }
        final text = await _getTimeSlotsInfo();
        return ChatMessage(
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
        );
      
      case ChatIntent.doctorNames:
        return await _getDoctorNamesMessage();
      
      case ChatIntent.freeTimeSlots:
        final text = await _getFreeTimeSlots();
        return ChatMessage(
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
        );
      
      case ChatIntent.howToOpenApp:
        return ChatMessage(
          text: _getHowToOpenApp(),
          isUser: false,
          timestamp: DateTime.now(),
        );
      
      case ChatIntent.howToRegister:
        return ChatMessage(
          text: _getHowToRegister(),
          isUser: false,
          timestamp: DateTime.now(),
        );
      
      case ChatIntent.howToBook:
        return ChatMessage(
          text: _getHowToBook(),
          isUser: false,
          timestamp: DateTime.now(),
        );
      
      case ChatIntent.paymentSteps:
        return ChatMessage(
          text: _getPaymentSteps(),
          isUser: false,
          timestamp: DateTime.now(),
        );
      
      case ChatIntent.appointmentStatus:
        return ChatMessage(
          text: _getAppointmentStatusInfo(role),
          isUser: false,
          timestamp: DateTime.now(),
        );
      
      case ChatIntent.medicalRecords:
        return ChatMessage(
          text: _getMedicalRecordsInfo(role),
          isUser: false,
          timestamp: DateTime.now(),
        );
      
      case ChatIntent.invoices:
        return ChatMessage(
          text: _getInvoicesInfo(role),
          isUser: false,
          timestamp: DateTime.now(),
        );
      
      case ChatIntent.appNavigation:
        return ChatMessage(
          text: _getAppNavigationInfo(role),
          isUser: false,
          timestamp: DateTime.now(),
        );
      
      case ChatIntent.generalHelp:
        return ChatMessage(
          text: getWelcomeMessage(role),
          isUser: false,
          timestamp: DateTime.now(),
        );
      
      case ChatIntent.unknown:
        // Fallback to role-specific handlers (use lowercased message for matching)
        return ChatMessage(
          text: _handleRoleSpecificMessage(message, role),
          isUser: false,
          timestamp: DateTime.now(),
        );
    }
  }

  static String _getProjectInfo() {
    return "🏥 **Hospital Appointment System**\n\n"
        "This is a comprehensive healthcare management app that connects patients with doctors and hospitals.\n\n"
        "**Key Features:**\n"
        "• Book appointments with doctors\n"
        "• View medical records and prescriptions\n"
        "• Manage invoices and payments\n"
        "• Search for doctors and hospitals\n"
        "• Receive appointment notifications\n"
        "• Access your medical history\n\n"
        "**For Patients:**\n"
        "You can search for doctors, book appointments, view your medical records, and pay invoices online.\n\n"
        "**For Doctors:**\n"
        "Manage appointments, add patient reports, generate invoices, and manage your schedule.\n\n"
        "**For Hospitals:**\n"
        "Manage staff, approve doctors, and view hospital analytics.";
  }

  static Future<String> _getTimeSlotsInfo() async {
    try {
      // Get sample shifts to show time slot format
      final shiftsSnapshot = await _firestore
          .collectionGroup('shifts')
          .where('isActive', isEqualTo: true)
          .limit(5)
          .get();

      if (shiftsSnapshot.docs.isEmpty) {
        return "**Time Slots Information:**\n\n"
            "Time slots are typically available during doctor shifts. Shifts usually run from morning to evening.\n\n"
            "**Common Time Slot Format:**\n"
            "• Morning: 09:00 - 12:00\n"
            "• Afternoon: 13:00 - 17:00\n"
            "• Evening: 18:00 - 21:00\n\n"
            "To see specific available time slots, search for a doctor and view their shifts.";
      }

      String response = "**Time Slots Information:**\n\n";
      response += "Here are some example time slots from active shifts:\n\n";

      for (var doc in shiftsSnapshot.docs) {
        final data = doc.data();
        final startTime = data['startTime'] ?? 'N/A';
        final endTime = data['endTime'] ?? 'N/A';
        final dayOfWeek = data['dayOfWeek'] ?? 'N/A';
        
        response += "• $dayOfWeek: $startTime - $endTime\n";
      }

      response += "\n**Note:** Time slots are usually in hourly intervals (e.g., 09:00, 10:00, 11:00).\n"
          "To see all available slots for a specific doctor, search for them in the app.";

      return response;
    } catch (e) {
      return "**Time Slots Information:**\n\n"
          "Time slots are available during doctor shifts. To view available time slots:\n\n"
          "1. Go to 'Search & Book'\n"
          "2. Find a doctor\n"
          "3. Tap 'View Shifts' to see their available time slots\n\n"
          "Time slots are typically in hourly intervals (e.g., 09:00, 10:00, 11:00).";
    }
  }

  // Helper method that returns ChatMessage for doctor names
  static Future<ChatMessage> _getDoctorNamesMessage() async {
    try {
      // Get approved doctors
      List<QueryDocumentSnapshot<Map<String, dynamic>>> approvedDoctors = [];
      
      try {
        final doctorsSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'doctor')
            .where('approved', isEqualTo: true)
            .limit(20)
            .get();
        
        approvedDoctors = doctorsSnapshot.docs;
      } catch (e) {
        final allDoctors = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'doctor')
            .limit(50)
            .get();
        
        approvedDoctors = allDoctors.docs.where((doc) {
          final data = doc.data();
          final approved = data['approved'];
          if (approved is bool) {
            return approved == true;
          }
          return false;
        }).toList();
      }

      if (approvedDoctors.isEmpty) {
        return ChatMessage(
          text: "**Doctors:**\n\n"
              "No approved doctors found in the system yet.\n\n"
              "Doctors need to be approved by hospital administrators before they appear in the system.",
          isUser: false,
          timestamp: DateTime.now(),
        );
      }

      String response = "**Available Doctors:**\n\n"
          "Click on a doctor below to see their available time slots:\n\n";
      
      final doctorsData = <Map<String, dynamic>>[];
      
      int count = 1;
      for (var doc in approvedDoctors) {
        final data = doc.data();
        final name = data['name'] ?? 'Unknown';
        final specialization = data['specialization'] ?? '';
        final doctorId = doc.id;
        final hospitalId = data['hospitalId'] ?? '';
        final hospitalName = data['hospitalName'] ?? '';
        
        response += "$count. Dr. $name";
        if (specialization.isNotEmpty) {
          response += " - $specialization";
        }
        response += "\n";
        
        doctorsData.add({
          'doctorId': doctorId,
          'doctorName': name,
          'specialization': specialization,
          'hospitalId': hospitalId,
          'hospitalName': hospitalName,
        });
        count++;
      }

      response += "\n**Total:** ${approvedDoctors.length} approved doctor(s)\n\n"
          "💡 Tap on a doctor name above to view their available time slots!";

      return ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        type: ChatMessageType.doctorList,
        data: {'doctors': doctorsData},
      );
    } catch (e) {
      return ChatMessage(
        text: "**Doctors:**\n\n"
            "To view all available doctors:\n\n"
            "1. Go to 'Search & Book' from the sidebar\n"
            "2. Browse or search for doctors\n"
            "3. You can filter by specialization or hospital\n\n"
            "All approved doctors will be listed there.",
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  // Handle doctor selection - fetch time slots
  static Future<ChatMessage> _handleDoctorSelection(Map<String, dynamic> data) async {
    final doctorId = data['doctorId'] as String;
    final doctorName = data['doctorName'] as String? ?? 'Unknown';
    final hospitalId = data['hospitalId'] as String? ?? '';
    final hospitalName = data['hospitalName'] as String? ?? '';

    try {
      // Get available shifts for the next 30 days
      final now = DateTime.now();
      final todayStart = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
      final endDate = Timestamp.fromDate(DateTime(now.year, now.month, now.day + 30));

      final shiftsSnapshot = await _firestore
          .collectionGroup('shifts')
          .where('doctorId', isEqualTo: doctorId)
          .where('isActive', isEqualTo: true)
          .where('dateTs', isGreaterThanOrEqualTo: todayStart)
          .where('dateTs', isLessThan: endDate)
          .orderBy('dateTs')
          .limit(20)
          .get();

      if (shiftsSnapshot.docs.isEmpty) {
        return ChatMessage(
          text: "**Dr. $doctorName**\n\n"
              "No available shifts found for the next 30 days.\n\n"
              "Please check back later or contact the hospital directly.",
          isUser: false,
          timestamp: DateTime.now(),
        );
      }

      // Get booked appointments to find free slots
      final bookedAppointments = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('time', isGreaterThanOrEqualTo: todayStart)
          .get();

      final bookedTimes = bookedAppointments.docs.map((doc) {
        final ts = doc.data()['time'] as Timestamp?;
        if (ts != null) {
          final dt = ts.toDate();
          return '${dt.year}-${dt.month}-${dt.day}-${dt.hour}-${dt.minute}';
        }
        return '';
      }).where((s) => s.isNotEmpty).toSet();

      String response = "**Dr. $doctorName**\n\n"
          "Available Time Slots (Next 30 Days):\n\n"
          "Click on a time slot to book:\n\n";

      final timeSlotsData = <Map<String, dynamic>>[];
      int slotCount = 0;

      for (var shiftDoc in shiftsSnapshot.docs) {
        if (slotCount >= 15) break; // Limit to 15 slots
        
        final shiftData = shiftDoc.data();
        final dateTs = shiftData['dateTs'] as Timestamp?;
        if (dateTs == null) continue;

        final date = dateTs.toDate();
        final startTime = shiftData['startTime'] ?? '09:00';
        final endTime = shiftData['endTime'] ?? '17:00';
        final shiftId = shiftDoc.reference.parent.parent?.id ?? shiftDoc.id;

        // Generate hourly slots
        final slots = _generateHourlySlots(startTime, endTime);
        
        for (var slot in slots) {
          if (slotCount >= 15) break;
          
          final slotParts = slot.split(':').map(int.parse).toList();
          final slotDateTime = DateTime(date.year, date.month, date.day, slotParts[0], slotParts[1]);
          
          // Skip past times
          if (slotDateTime.isBefore(now)) continue;
          
          final slotKey = '${date.year}-${date.month}-${date.day}-${slotParts[0]}-${slotParts[1]}';
          if (bookedTimes.contains(slotKey)) continue; // Skip booked slots

          final formattedDate = DateFormat('MMM dd, yyyy').format(date);
          response += "• $formattedDate at $slot\n";
          
          timeSlotsData.add({
            'doctorId': doctorId,
            'doctorName': doctorName,
            'hospitalId': hospitalId,
            'hospitalName': hospitalName,
            'shiftId': shiftId,
            'date': date.toIso8601String(),
            'timeSlot': slot,
            'formattedDate': formattedDate,
          });
          
          slotCount++;
        }
      }

      if (timeSlotsData.isEmpty) {
        return ChatMessage(
          text: "**Dr. $doctorName**\n\n"
              "All time slots are currently booked.\n\n"
              "Please check back later or try another doctor.",
          isUser: false,
          timestamp: DateTime.now(),
        );
      }

      response += "\n💡 Tap on a time slot above to confirm your booking!";

      return ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        type: ChatMessageType.timeSlotList,
        data: {
          'doctorId': doctorId,
          'doctorName': doctorName,
          'timeSlots': timeSlotsData,
        },
      );
    } catch (e) {
      return ChatMessage(
        text: "Sorry, I couldn't fetch time slots for Dr. $doctorName. Please try again.",
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  // Handle time slot selection - show booking confirmation
  static Future<ChatMessage> _handleTimeSlotSelection(Map<String, dynamic> data, ChatRole role) async {
    if (role != ChatRole.patient) {
      return ChatMessage(
        text: "Only patients can book appointments. Please log in as a patient.",
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    final doctorId = data['doctorId'] as String;
    final doctorName = data['doctorName'] as String? ?? 'Unknown';
    final hospitalId = data['hospitalId'] as String? ?? '';
    final hospitalName = data['hospitalName'] as String? ?? '';
    final dateStr = data['date'] as String;
    final timeSlot = data['timeSlot'] as String;
    final shiftId = data['shiftId'] as String? ?? '';

    final date = DateTime.parse(dateStr);
    final slotParts = timeSlot.split(':').map(int.parse).toList();
    final appointmentDateTime = DateTime(date.year, date.month, date.day, slotParts[0], slotParts[1]);

    return ChatMessage(
      text: "**Confirm Booking**\n\n"
          "Doctor: Dr. $doctorName\n"
          "Hospital: $hospitalName\n"
          "Date: ${DateFormat('MMMM dd, yyyy').format(date)}\n"
          "Time: $timeSlot\n\n"
          "Tap 'Confirm' below to book this appointment.",
      isUser: false,
      timestamp: DateTime.now(),
      type: ChatMessageType.bookingConfirmation,
      data: {
        'doctorId': doctorId,
        'doctorName': doctorName,
        'hospitalId': hospitalId,
        'hospitalName': hospitalName,
        'shiftId': shiftId,
        'date': dateStr,
        'timeSlot': timeSlot,
        'appointmentDateTime': appointmentDateTime.toIso8601String(),
      },
    );
  }

  // Handle booking confirmation - create appointment
  static Future<ChatMessage> _handleBookingConfirmation(Map<String, dynamic> data, ChatRole role) async {
    if (role != ChatRole.patient) {
      return ChatMessage(
        text: "Only patients can book appointments.",
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    try {
      final fs = FirebaseFirestore.instance;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return ChatMessage(
          text: "Please log in to book an appointment.",
          isUser: false,
          timestamp: DateTime.now(),
        );
      }

      final doctorId = data['doctorId'] as String;
      final doctorName = data['doctorName'] as String? ?? 'Unknown';
      final hospitalId = data['hospitalId'] as String? ?? '';
      final hospitalName = data['hospitalName'] as String? ?? '';
      final shiftId = data['shiftId'] as String? ?? '';
      final dateStr = data['date'] as String;
      final timeSlot = data['timeSlot'] as String;

      final date = DateTime.parse(dateStr);
      final slotParts = timeSlot.split(':').map(int.parse).toList();
      final appointmentDateTime = DateTime(date.year, date.month, date.day, slotParts[0], slotParts[1]);
      final ts = Timestamp.fromDate(appointmentDateTime);

      // Get patient info
      final patientDoc = await fs.collection('users').doc(user.uid).get();
      final patientName = patientDoc.data()?['name'] ?? 'Unknown';

      // Check for existing appointment at same time
      final existing = await fs
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('time', isEqualTo: ts)
          .get();

      if (existing.docs.isNotEmpty) {
        return ChatMessage(
          text: "❌ This time slot has already been booked. Please select another time slot.",
          isUser: false,
          timestamp: DateTime.now(),
        );
      }

      // Create appointment
      final apptData = {
        'patientId': user.uid,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'hospitalName': hospitalName,
        'hospitalId': hospitalId.isNotEmpty ? hospitalId : shiftId,
        'shiftId': shiftId,
        'time': ts,
        'appointmentDate': ts,
        'timeSlot': timeSlot,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final rootRef = await fs.collection('appointments').add(apptData);
      await fs.collection('users').doc(user.uid).collection('appointments').doc(rootRef.id).set(apptData);

      // Send notifications and emails via notification server
      try {
        // Send to patient (notification + email)
        await NotificationService.sendFCMNotification(
          userId: user.uid,
          title: 'Appointment Booked Successfully',
          body: 'Your appointment with Dr. $doctorName has been booked. Waiting for doctor confirmation.',
          data: {
            'type': 'appointment_booked',
            'appointmentId': rootRef.id,
            'doctorName': doctorName,
          },
        );

        // Send to doctor (notification + email)
        await NotificationService.sendFCMNotification(
          userId: doctorId,
          title: 'New Appointment Booking',
          body: 'Patient $patientName has booked an appointment.',
          data: {
            'type': 'new_appointment',
            'appointmentId': rootRef.id,
            'patientName': patientName,
          },
        );
      } catch (e) {
        // Notification error shouldn't fail the booking
        debugPrint('⚠️ Error sending notifications: $e');
      }

      // Store notifications in Firestore
      await fs.collection('notifications').add({
        'userId': user.uid,
        'toRole': 'patient',
        'title': 'Appointment Booked',
        'body': 'Your appointment with Dr. $doctorName has been booked successfully.',
        'appointmentId': rootRef.id,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      await fs.collection('notifications').add({
        'userId': doctorId,
        'toRole': 'doctor',
        'title': 'New Appointment',
        'body': 'Patient $patientName has booked an appointment.',
        'appointmentId': rootRef.id,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      return ChatMessage(
        text: "✅ **Appointment Booked Successfully!**\n\n"
            "Doctor: Dr. $doctorName\n"
            "Date: ${DateFormat('MMMM dd, yyyy').format(date)}\n"
            "Time: $timeSlot\n"
            "Status: Pending (Waiting for doctor approval)\n\n"
            "You'll receive a notification once the doctor confirms your appointment.\n\n"
            "You can view your appointments in 'My Appointments' from the sidebar.",
        isUser: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return ChatMessage(
        text: "❌ Error booking appointment: $e\n\nPlease try again or book through the app.",
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  // Helper to generate hourly slots
  static List<String> _generateHourlySlots(String start, String end) {
    try {
      final sParts = start.split(':').map(int.parse).toList();
      final eParts = end.split(':').map(int.parse).toList();
      final sTime = DateTime(2024, 1, 1, sParts[0], sParts[1]);
      final eTime = DateTime(2024, 1, 1, eParts[0], eParts[1]);
      final diff = eTime.difference(sTime).inHours;
      return List.generate(diff, (i) {
        final t = sTime.add(Duration(hours: i));
        return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      });
    } catch (_) {
      return [];
    }
  }

  static Future<String> _getFreeTimeSlots() async {
    try {
      // Get upcoming shifts with available slots
      final now = DateTime.now();
      final todayStart = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
      final endDate = Timestamp.fromDate(DateTime(now.year, now.month, now.day + 7));

      final shiftsSnapshot = await _firestore
          .collectionGroup('shifts')
          .where('isActive', isEqualTo: true)
          .where('dateTs', isGreaterThanOrEqualTo: todayStart)
          .where('dateTs', isLessThan: endDate)
          .limit(10)
          .get();

      if (shiftsSnapshot.docs.isEmpty) {
        return "**Free Time Slots:**\n\n"
            "No upcoming shifts found in the next 7 days.\n\n"
            "To find free time slots:\n"
            "1. Search for a doctor\n"
            "2. View their shifts\n"
            "3. Available time slots will be shown (excluding already booked times)";
      }

      String response = "**Free Time Slots (Next 7 Days):**\n\n";
      
      // Group by doctor
      Map<String, List<Map<String, dynamic>>> doctorShifts = {};
      
      for (var doc in shiftsSnapshot.docs) {
        final data = doc.data();
        final doctorId = data['doctorId'] ?? '';
        final dateTs = data['dateTs'] as Timestamp?;
        final startTime = data['startTime'] ?? '';
        final endTime = data['endTime'] ?? '';
        
        if (doctorId.isNotEmpty && dateTs != null) {
          if (!doctorShifts.containsKey(doctorId)) {
            doctorShifts[doctorId] = [];
          }
          
          // Get doctor name
          final doctorDoc = await _firestore.collection('users').doc(doctorId).get();
          final doctorName = doctorDoc.data()?['name'] ?? 'Unknown Doctor';
          
          final date = dateTs.toDate();
          doctorShifts[doctorId]!.add({
            'date': date,
            'startTime': startTime,
            'endTime': endTime,
            'doctorName': doctorName,
          });
        }
      }

      int slotCount = 0;
      for (var entry in doctorShifts.entries) {
        if (slotCount >= 5) break; // Limit to 5 examples
        
        final shifts = entry.value;
        if (shifts.isNotEmpty) {
          final shift = shifts.first;
          final date = shift['date'] as DateTime;
          final doctorName = shift['doctorName'] as String;
          final startTime = shift['startTime'] as String;
          final endTime = shift['endTime'] as String;
          
          response += "• ${DateFormat('MMM dd, yyyy').format(date)} - Dr. $doctorName\n"
              "  Available: $startTime - $endTime\n\n";
          slotCount++;
        }
      }

      response += "**To see all free slots:**\n"
          "1. Go to 'Search & Book'\n"
          "2. Select a doctor\n"
          "3. View their shifts to see all available time slots\n\n"
          "Free slots are those that haven't been booked yet.";

      return response;
    } catch (e) {
      return "**Free Time Slots:**\n\n"
          "To find free time slots:\n\n"
          "1. Go to 'Search & Book' from the sidebar\n"
          "2. Search for a doctor or hospital\n"
          "3. Tap 'View Shifts' on a doctor\n"
          "4. You'll see all available time slots\n\n"
          "Free slots are those that haven't been booked by other patients yet.\n"
          "Time slots are typically in hourly intervals.";
    }
  }

  static String _getHowToOpenApp() {
    return "**How to Open the App:**\n\n"
        "1. **Launch the App:**\n"
        "   • Tap the app icon on your device\n"
        "   • The app will open to the login screen\n\n"
        "2. **If You're Already Registered:**\n"
        "   • Enter your email and password\n"
        "   • Tap 'Login'\n"
        "   • You'll be taken to your home screen\n\n"
        "3. **If You're New:**\n"
        "   • Tap 'Register' or 'Sign Up'\n"
        "   • Choose your role (Patient, Doctor, or Hospital Admin)\n"
        "   • Follow the registration steps\n\n"
        "4. **Navigation:**\n"
        "   • Use the sidebar menu (☰) to access different features\n"
        "   • Tap on any menu item to navigate\n\n"
        "The app is designed to be intuitive and easy to use!";
  }

  static String _getHowToRegister() {
    return "**How to Register:**\n\n"
        "**For Patients:**\n"
        "1. Open the app and tap 'Register' or 'Sign Up'\n"
        "2. Select 'Patient' as your role\n"
        "3. Fill in your information:\n"
        "   • Full Name\n"
        "   • Email Address\n"
        "   • Password\n"
        "   • Phone Number\n"
        "   • Date of Birth\n"
        "   • Gender\n"
        "   • Address (optional)\n"
        "4. Tap 'Register'\n"
        "5. You'll receive a confirmation\n"
        "6. Login with your credentials\n\n"
        "**For Doctors:**\n"
        "1. Select 'Doctor' during registration\n"
        "2. Fill in additional details:\n"
        "   • Specialization\n"
        "   • Qualification\n"
        "   • License Number\n"
        "   • Experience Years\n"
        "3. Submit for approval\n"
        "4. Wait for hospital admin approval\n\n"
        "**For Hospital Admins:**\n"
        "1. Select 'Hospital Admin' during registration\n"
        "2. Fill in hospital details\n"
        "3. Submit for head admin approval\n\n"
        "Once registered, you can start using the app!";
  }

  static String _getHowToBook() {
    return "**How to Book an Appointment:**\n\n"
        "**Step-by-Step Guide:**\n\n"
        "1. **Search for a Doctor:**\n"
        "   • Go to 'Search & Book' from the sidebar\n"
        "   • Search by doctor name, specialization, or hospital\n"
        "   • Browse available doctors\n\n"
        "2. **Select a Doctor:**\n"
        "   • Tap on a doctor's card\n"
        "   • View their profile and details\n"
        "   • Tap 'View Shifts' to see available time slots\n\n"
        "3. **Choose Time Slot:**\n"
        "   • Browse available shifts (next 30 days)\n"
        "   • Select a date\n"
        "   • Choose an available time slot\n"
        "   • Free slots are shown (booked slots are hidden)\n\n"
        "4. **Confirm Booking:**\n"
        "   • Review your selection\n"
        "   • Add any symptoms or notes (optional)\n"
        "   • Tap 'Book Appointment'\n\n"
        "5. **Wait for Confirmation:**\n"
        "   • The appointment status will be 'Pending'\n"
        "   • Doctor will receive a notification\n"
        "   • Once doctor accepts, status becomes 'Confirmed'\n"
        "   • You'll receive a notification\n\n"
        "6. **View Your Appointment:**\n"
        "   • Go to 'My Appointments' to see all bookings\n"
        "   • Tap on an appointment to see details\n\n"
        "**Tips:**\n"
        "• Book in advance for better availability\n"
        "• You can cancel appointments if needed\n"
        "• Check appointment status regularly";
  }

  static String _getPaymentSteps() {
    return "**Payment Steps:**\n\n"
        "**How to Pay an Invoice:**\n\n"
        "1. **View Your Invoices:**\n"
        "   • Go to 'My Invoices' from the sidebar\n"
        "   • You'll see all your invoices\n"
        "   • Pending invoices show 'PENDING' status\n"
        "   • Paid invoices show 'PAID' status\n\n"
        "2. **Select an Invoice:**\n"
        "   • Tap on a pending invoice\n"
        "   • Review invoice details:\n"
        "     - Invoice items\n"
        "     - Subtotal\n"
        "     - Tax (if any)\n"
        "     - Total amount\n\n"
        "3. **Pay Now:**\n"
        "   • Tap 'Pay Now' button\n"
        "   • You'll be taken to the payment screen\n\n"
        "4. **Enter Payment Details:**\n"
        "   • Card Number (16 digits)\n"
        "   • Expiry Date (MM/YY)\n"
        "   • CVV (3 digits)\n"
        "   • Cardholder Name\n"
        "   • Review the total amount\n\n"
        "5. **Complete Payment:**\n"
        "   • Tap 'Pay Now'\n"
        "   • Payment will be processed\n"
        "   • You'll receive a transaction ID\n\n"
        "6. **Confirmation:**\n"
        "   • Payment confirmation message\n"
        "   • Invoice status changes to 'PAID'\n"
        "   • Appointment status changes to 'Completed'\n"
        "   • You can now rate the doctor\n\n"
        "**Note:** This is a demo payment system. In production, real payment gateways would be integrated.\n\n"
        "**After Payment:**\n"
        "• Appointment is marked as completed\n"
        "• You can view and download invoice\n"
        "• You can rate the doctor's service";
  }

  static String _getAppointmentStatusInfo(ChatRole role) {
    if (role == ChatRole.patient) {
      return "**View Your Appointments:**\n\n"
          "1. Go to 'My Appointments' from the sidebar\n"
          "2. You'll see all your appointments with:\n"
          "   • Doctor name\n"
          "   • Hospital name\n"
          "   • Date and time\n"
          "   • Status (Booked, Confirmed, Completed, Cancelled)\n\n"
          "**Appointment Statuses:**\n"
          "• **Booked/Pending:** Waiting for doctor approval\n"
          "• **Confirmed:** Doctor has accepted\n"
          "• **Completed:** Appointment finished (after payment)\n"
          "• **Cancelled:** Appointment was cancelled\n\n"
          "**Actions:**\n"
          "• Tap on an appointment to see full details\n"
          "• Cancel appointments (if status is Booked/Confirmed)\n"
          "• View medical reports (if completed)\n"
          "• Rate doctor (if completed)";
    } else {
      return "**Manage Appointments:**\n\n"
          "1. Go to 'My Appointments' from the home screen\n"
          "2. View appointments in tabs:\n"
          "   • Pending: Accept or reject\n"
          "   • Confirmed: Add reports\n"
          "   • Completed: View records\n\n"
          "3. For pending appointments:\n"
          "   • Tap 'Accept' to confirm\n"
          "   • Tap 'Reject' to decline\n\n"
          "4. For confirmed appointments:\n"
          "   • Add medical report after consultation\n"
          "   • Generate invoice when done";
    }
  }

  static String _getMedicalRecordsInfo(ChatRole role) {
    if (role == ChatRole.patient) {
      return "**View Medical Records:**\n\n"
          "1. Go to 'Medical Reports' from the sidebar\n"
          "2. You'll see all your medical reports\n\n"
          "**Report Information Includes:**\n"
          "• Diagnosis\n"
          "• Prescriptions/Medications\n"
          "• Lab Tests\n"
          "• Notes\n"
          "• Chronic Diseases\n"
          "• Allergies\n\n"
          "**You can also view reports from:**\n"
          "• Appointment details page\n"
          "• 'My Medicines' section\n\n"
          "All your medical history is stored securely in the app.";
    } else {
      return "**Add Medical Reports:**\n\n"
          "1. Go to 'My Appointments'\n"
          "2. Select a confirmed appointment\n"
          "3. Tap 'Add Report'\n"
          "4. Fill in:\n"
          "   • Diagnosis/General Report\n"
          "   • Prescription medications\n"
          "   • Lab tests (if any)\n"
          "   • Notes\n"
          "   • Chronic diseases\n"
          "   • Allergies\n"
          "5. Save the report\n\n"
          "The report will be visible to the patient and stored in their medical records.";
    }
  }

  static String _getInvoicesInfo(ChatRole role) {
    if (role == ChatRole.patient) {
      return "**View and Pay Invoices:**\n\n"
          "1. Go to 'My Invoices' from the sidebar\n"
          "2. View all your invoices\n"
          "3. Tap on an invoice to see details\n"
          "4. For pending invoices, tap 'Pay Now'\n"
          "5. Complete payment process\n\n"
          "**Invoice Details Include:**\n"
          "• Invoice number\n"
          "• Date\n"
          "• Items and amounts\n"
          "• Tax (if applicable)\n"
          "• Total amount\n"
          "• Payment status\n\n"
          "After payment, the appointment is marked as completed.";
    } else {
      return "**Generate Invoices:**\n\n"
          "1. Go to 'My Appointments'\n"
          "2. Select a completed appointment\n"
          "3. Tap 'Generate Invoice'\n"
          "4. Add invoice items:\n"
          "   • Description\n"
          "   • Amount\n"
          "5. Set tax percentage (if needed)\n"
          "6. Generate invoice\n\n"
          "**View Payments:**\n"
          "1. Go to 'My Invoices'\n"
          "2. View all invoices\n"
          "3. See payment status and details\n\n"
          "Patients will receive notifications when invoices are generated.";
    }
  }

  static String _getAppNavigationInfo(ChatRole role) {
    switch (role) {
      case ChatRole.patient:
        return "**App Navigation for Patients:**\n\n"
            "**Main Menu (Sidebar):**\n"
            "• **Home:** Your dashboard\n"
            "• **Search & Book:** Find doctors and book appointments\n"
            "• **My Appointments:** View all your appointments\n"
            "• **My Invoices:** View and pay invoices\n"
            "• **Medical Reports:** View your medical records\n"
            "• **My Medicines:** View prescribed medications\n"
            "• **My Profile:** Edit your profile information\n"
            "• **QR Code:** View your QR code\n"
            "• **Chatbot:** Ask questions (you're here!)\n\n"
            "**How to Navigate:**\n"
            "1. Tap the menu icon (☰) in the top-left corner\n"
            "2. Select any menu item to navigate\n"
            "3. Use the back button to return\n"
            "4. Each screen has its own features and options\n\n"
            "**Quick Access:**\n"
            "• Tap on appointment cards to see details\n"
            "• Tap on invoice cards to view and pay\n"
            "• Use search to find doctors quickly";
      
      case ChatRole.doctor:
        return "**App Navigation for Doctors:**\n\n"
            "**Main Menu:**\n"
            "• **Home:** Your dashboard\n"
            "• **My Appointments:** Manage patient appointments\n"
            "• **My Invoices:** View all invoices and payments\n"
            "• **My Shifts:** Add and manage your shifts\n"
            "• **Weekly Shifts:** View your weekly schedule\n"
            "• **Reviews:** View patient reviews\n"
            "• **My Profile:** Edit your profile\n"
            "• **Chatbot:** Ask questions\n\n"
            "**How to Navigate:**\n"
            "1. Use the menu icon (☰) to access features\n"
            "2. Tabs in appointments screen:\n"
            "   - Pending: Accept/reject requests\n"
            "   - Confirmed: Add reports\n"
            "   - Completed: Generate invoices";
      
      case ChatRole.hospitaladmin:
        return "**App Navigation for Hospital Admins:**\n\n"
            "**Main Menu:**\n"
            "• **My Staff:** Approve/reject doctors\n"
            "• **Hospital Reports:** View analytics\n"
            "• **Manage Shifts:** Manage doctor shifts\n"
            "• **My Profile:** Hospital profile\n"
            "• **Chatbot:** Ask questions\n\n"
            "**How to Navigate:**\n"
            "1. Use the sidebar menu to access features\n"
            "2. Each section has specific management tools";
      
      case ChatRole.headadmin:
        return "**App Navigation for Head Admins:**\n\n"
            "**Main Menu:**\n"
            "• **Approve Hospitals:** Review hospital registrations\n"
            "• **Approve Doctors:** Review doctor registrations\n"
            "• **Head Admin Reports:** System-wide analytics\n"
            "• **Chatbot:** Ask questions\n\n"
            "**How to Navigate:**\n"
            "1. Use the sidebar menu\n"
            "2. Review and approve registrations\n"
            "3. View system reports";
    }
  }

  // Fallback to role-specific handlers
  static String _handleRoleSpecificMessage(String message, ChatRole role) {
    switch (role) {
      case ChatRole.patient:
        return _handlePatientMessage(message);
      
      case ChatRole.doctor:
        return _handleDoctorMessage(message);
      
      case ChatRole.hospitaladmin:
        return _handleHospitalAdminMessage(message);
      
      case ChatRole.headadmin:
        return _handleHeadAdminMessage(message);
    }
  }

  static String _handlePatientMessage(String message) {
    // Search related
    if (_matches(message, ['search', 'find doctor', 'find hospital'])) {
      return "To search for doctors or hospitals:\n\n"
          "1. Go to 'Search & Book' from the sidebar\n"
          "2. Use the search bar or browse by:\n"
          "   - Hospitals\n"
          "   - Specializations\n"
          "   - Doctors\n"
          "3. Tap 'View Shifts' to see available appointment slots";
    }

    // QR Code
    if (_matches(message, ['qr', 'qr code', 'code'])) {
      return "To view your QR code:\n\n"
          "1. Go to 'QR Code' from the sidebar\n"
          "2. Your QR code will be displayed\n"
          "3. Others can scan it to view your profile information";
    }

    // Profile
    if (_matches(message, ['profile', 'my profile', 'edit profile'])) {
      return "To view or edit your profile:\n\n"
          "1. Open the sidebar menu\n"
          "2. Tap on 'My Profile'\n"
          "3. You can view and update your information";
    }

    // More specific responses based on message content
    if (_matchesAny(message, ['cancel', 'delete', 'remove'])) {
      return "To cancel an appointment:\n\n"
          "1. Go to 'My Appointments'\n"
          "2. Find the appointment you want to cancel\n"
          "3. Tap on it to view details\n"
          "4. Tap 'Cancel Appointment'\n"
          "5. Confirm the cancellation\n\n"
          "Note: You can only cancel appointments that are pending or confirmed.";
    }

    if (_matchesAny(message, ['change', 'modify', 'edit', 'update'])) {
      return "To modify an appointment:\n\n"
          "You'll need to cancel the existing appointment and book a new one:\n"
          "1. Cancel your current appointment\n"
          "2. Book a new appointment with your preferred time\n\n"
          "Alternatively, contact the doctor or hospital directly.";
    }

    if (_matchesAny(message, ['notification', 'notify', 'alert', 'reminder'])) {
      return "About Notifications:\n\n"
          "You'll receive notifications for:\n"
          "• Appointment confirmations\n"
          "• Appointment reminders\n"
          "• New invoices\n"
          "• Payment confirmations\n"
          "• Medical reports\n\n"
          "Make sure notifications are enabled in your device settings.";
    }

    // Default response
    return "I understand you're asking about '$message'. "
        "I can help you with:\n\n"
        "• Booking appointments\n"
        "• Viewing invoices and payments\n"
        "• Medical records and reports\n"
        "• Finding doctors\n"
        "• Time slots and availability\n"
        "• App navigation\n\n"
        "Try asking: 'How do I book an appointment?' or 'What doctors are available?'";
  }

  static String _handleDoctorMessage(String message) {
    // Shifts - improved matching
    if (_matches(message, ['shift', 'shifts', 'schedule', 'availability', 'manage shift', 'managing shift', 'manage shifts', 'managing shifts', 'my shift', 'my shifts', 'weekly shift', 'weekly shifts'])) {
      return "To manage your shifts:\n\n"
          "1. Go to 'My Shifts' to add/edit shifts\n"
          "2. Go to 'Weekly Shifts' to view your schedule\n"
          "3. Patients can book appointments during your available shifts";
    }

    // Reviews
    if (_matches(message, ['review', 'reviews', 'rating', 'feedback'])) {
      return "To view patient reviews:\n\n"
          "1. Go to 'Reviews' from the home screen\n"
          "2. You'll see all reviews from patients\n"
          "3. Reviews include ratings and comments";
    }

    // More specific responses for doctors
    if (_matchesAny(message, ['patient', 'patients'])) {
      return "To view patient information:\n\n"
          "1. Go to 'My Appointments'\n"
          "2. Select an appointment\n"
          "3. View patient details and medical history\n"
          "4. Add reports and medications\n\n"
          "Patient information is available in appointment details.";
    }

    if (_matchesAny(message, ['report', 'add report', 'create report'])) {
      return "To add a patient report:\n\n"
          "1. Go to 'My Appointments'\n"
          "2. Select a confirmed appointment\n"
          "3. Tap 'Add Report'\n"
          "4. Fill in diagnosis, medications, and notes\n"
          "5. Save the report\n\n"
          "The report will be visible to the patient.";
    }

    if (_matchesAny(message, ['invoice', 'generate invoice', 'create invoice'])) {
      return "To generate an invoice:\n\n"
          "1. Go to 'My Appointments'\n"
          "2. Select a completed appointment\n"
          "3. Tap 'Generate Invoice'\n"
          "4. Add invoice items and amounts\n"
          "5. Set tax percentage (if needed)\n"
          "6. Generate the invoice\n\n"
          "The patient will receive a notification.";
    }

    // Default
    return "I can help you with:\n\n"
        "• Managing appointments\n"
        "• Adding patient reports\n"
        "• Generating invoices\n"
        "• Viewing payments\n"
        "• Managing shifts\n\n"
        "Try asking: 'How do I add a report?' or 'How do I generate an invoice?'";
  }

  static String _handleHospitalAdminMessage(String message) {
    if (_matches(message, ['doctor', 'doctors', 'staff', 'approve doctor'])) {
      return "To manage doctors:\n\n"
          "1. Go to 'My Staff' from the sidebar\n"
          "2. You'll see pending and approved doctors\n"
          "3. Tap 'Approve' or 'Reject' for pending doctors\n"
          "4. Approved doctors can start using the system";
    }

    if (_matches(message, ['report', 'reports', 'hospital report'])) {
      return "To view hospital reports:\n\n"
          "1. Go to 'Hospital Reports' from the sidebar\n"
          "2. View statistics and analytics\n"
          "3. See doctor and patient reports";
    }

    if (_matches(message, ['shift', 'shifts', 'manage shifts'])) {
      return "To manage shifts:\n\n"
          "1. Go to 'Manage Shifts' from the sidebar\n"
          "2. You can view and manage shifts for all doctors in your hospital";
    }

    return "I can help you with:\n\n"
        "• Managing hospital staff\n"
        "• Approving doctors\n"
        "• Viewing reports\n"
        "• Managing shifts\n\n"
        "What would you like to know?";
  }

  static String _handleHeadAdminMessage(String message) {
    if (_matches(message, ['hospital', 'hospitals', 'approve hospital'])) {
      return "To manage hospitals:\n\n"
          "1. Go to 'Approve Hospitals' from the sidebar\n"
          "2. Review pending hospital registrations\n"
          "3. Approve or reject hospitals";
    }

    if (_matches(message, ['doctor', 'doctors', 'approve doctor'])) {
      return "To manage doctors:\n\n"
          "1. Go to 'Approve Doctors' from the sidebar\n"
          "2. Review doctor registrations\n"
          "3. Approve or reject doctors";
    }

    if (_matches(message, ['report', 'reports'])) {
      return "To view system reports:\n\n"
          "1. Go to 'Head Admin Reports' from the sidebar\n"
          "2. View system-wide statistics\n"
          "3. Analyze platform usage";
    }

    return "I can help you with:\n\n"
        "• Approving hospitals and doctors\n"
        "• Viewing system reports\n"
        "• Platform management\n\n"
        "How can I assist you?";
  }

  // Helper to check if message matches any keywords
  static bool _matches(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }

  // Helper for exact phrase matching (more specific)
  static bool _matchesExact(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }

  // Helper to check if message contains any of the keywords (more flexible)
  static bool _matchesAny(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }
}

