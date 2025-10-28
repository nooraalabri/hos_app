import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/doctor_model.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../../models/shift_model.dart';
import '../../models/hospital_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import 'search_doctors_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  final DoctorModel doctor;
  final UserModel doctorUser;

  const BookAppointmentScreen({
    Key? key,
    required this.doctor,
    required this.doctorUser,
  }) : super(key: key);

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String? _selectedHospitalId;
  bool _isLoading = false;
  bool _isLoadingData = true;
  
  List<ShiftModel> _doctorShifts = [];
  Map<String, HospitalModel> _hospitals = {};
  List<String> _availableTimeSlots = [];

  @override
  void initState() {
    super.initState();
    _loadDoctorShiftsAndHospitals();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorShiftsAndHospitals() async {
    setState(() => _isLoadingData = true);
    try {
      // Load doctor's shifts
      _doctorShifts = await _firebaseService.getShiftsByDoctor(widget.doctor.uid);
      
      // Get unique hospital IDs from shifts
      final hospitalIds = _doctorShifts.map((shift) => shift.hospitalId).toSet();
      
      // Load hospital details
      for (String hospitalId in hospitalIds) {
        final hospital = await _firebaseService.getHospital(hospitalId);
        if (hospital != null) {
          _hospitals[hospitalId] = hospital;
        }
      }
      
      setState(() => _isLoadingData = false);
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load doctor shifts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> _getAvailableDaysOfWeek() {
    // Get unique days from shifts
    return _doctorShifts
        .map((shift) => shift.dayOfWeek)
        .toSet()
        .toList();
  }

  bool _isDayAvailable(DateTime date) {
    if (_selectedHospitalId == null) return false;
    
    final dayName = DateFormat('EEEE').format(date);
    
    // Check if doctor has a shift on this day for the selected hospital
    return _doctorShifts.any((shift) => 
        shift.hospitalId == _selectedHospitalId && 
        shift.dayOfWeek == dayName &&
        shift.isActive
    );
  }

  String _getDoctorAvailabilityForHospital(String hospitalId) {
    final hospitalShifts = _doctorShifts
        .where((shift) => shift.hospitalId == hospitalId && shift.isActive)
        .toList();
    
    if (hospitalShifts.isEmpty) return 'No shifts available';
    
    final daysMap = <String, String>{};
    for (var shift in hospitalShifts) {
      daysMap[shift.dayOfWeek] = shift.timeRange;
    }
    
    final days = daysMap.keys.toList();
    if (days.length <= 2) {
      return days.join(', ');
    } else {
      return '${days.take(2).join(', ')} and ${days.length - 2} more days';
    }
  }

  DateTime _parseTimeString(String timeString) {
    // Remove any whitespace
    timeString = timeString.trim();
    
    // Check if it contains AM/PM (12-hour format)
    if (timeString.toUpperCase().contains('AM') || timeString.toUpperCase().contains('PM')) {
      // Parse 12-hour format (e.g., "09:30 AM")
      try {
        final format = DateFormat('hh:mm a');
        final parsedTime = format.parse(timeString);
        return parsedTime;
      } catch (e) {
        // Try alternative format
        try {
          final format = DateFormat('h:mm a');
          final parsedTime = format.parse(timeString);
          return parsedTime;
        } catch (e) {
          // Fallback to 9:00 AM
          return DateTime(2024, 1, 1, 9, 0);
        }
      }
    } else {
      // Parse 24-hour format (e.g., "09:30" or "9:30")
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        // Remove any non-numeric characters from minutes
        final minuteStr = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
        int hour = int.parse(parts[0]);
        int minute = minuteStr.isNotEmpty ? int.parse(minuteStr) : 0;
        return DateTime(2024, 1, 1, hour, minute);
      }
      // Fallback to 9:00 AM
      return DateTime(2024, 1, 1, 9, 0);
    }
  }

  void _generateTimeSlots() {
    _availableTimeSlots.clear();
    _selectedTimeSlot = null;
    
    if (_selectedDate == null || _selectedHospitalId == null) return;
    
    final dayName = DateFormat('EEEE').format(_selectedDate!);
    
    // Find the shift for the selected day and hospital
    final shift = _doctorShifts.firstWhere(
      (s) => s.hospitalId == _selectedHospitalId && 
             s.dayOfWeek == dayName &&
             s.isActive,
      orElse: () => ShiftModel(
        id: '',
        doctorId: '',
        hospitalId: '',
        dayOfWeek: '',
        startTime: '09:00',
        endTime: '17:00',
        createdAt: DateTime.now(),
      ),
    );
    
    if (shift.id.isEmpty) return;
    
    // Parse start and end times using the helper function
    DateTime slotTime = _parseTimeString(shift.startTime);
    final endTime = _parseTimeString(shift.endTime);
    
    // Generate 30-minute time slots
    while (slotTime.add(const Duration(minutes: 30)).isBefore(endTime) ||
           slotTime.add(const Duration(minutes: 30)).isAtSameMomentAs(endTime)) {
      final slotStart = DateFormat('hh:mm a').format(slotTime);
      final slotEnd = DateFormat('hh:mm a').format(slotTime.add(const Duration(minutes: 30)));
      
      _availableTimeSlots.add('$slotStart - $slotEnd');
      slotTime = slotTime.add(const Duration(minutes: 30));
    }
  }

  DateTime _findNextAvailableDate() {
    // Find the first available date that matches doctor's shift
    DateTime checkDate = DateTime.now();
    final maxDate = DateTime.now().add(const Duration(days: 90));
    
    while (checkDate.isBefore(maxDate)) {
      checkDate = checkDate.add(const Duration(days: 1));
      if (_isDayAvailable(checkDate)) {
        return checkDate;
      }
    }
    
    // If no available date found, return tomorrow as fallback
    return DateTime.now().add(const Duration(days: 1));
  }

  Future<void> _selectDate() async {
    if (_selectedHospitalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a hospital first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Find the first available date
    final initialDate = _findNextAvailableDate();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      selectableDayPredicate: _isDayAvailable,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _generateTimeSlots();
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTimeSlot != null &&
        _selectedHospitalId != null) {
      setState(() => _isLoading = true);

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        final appointment = AppointmentModel(
          id: const Uuid().v4(),
          patientId: authProvider.currentUser!.uid,
          doctorId: widget.doctor.uid,
          hospitalId: _selectedHospitalId!,
          appointmentDate: _selectedDate!,
          timeSlot: _selectedTimeSlot!,
          status: AppointmentStatus.pending,
          symptoms: _symptomsController.text.trim(),
          createdAt: DateTime.now(),
          consultationFee: widget.doctor.consultationFee,
        );

        await _firebaseService.createAppointment(appointment);

        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment booked successfully! Awaiting confirmation.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to book appointment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const SearchDoctorsScreen()),
            );
          },
        ),
        title: const Text(
          'Book Appointment',
          style: TextStyle(
            fontFamily: 'Serif',
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : _hospitals.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No shifts available for this doctor.\nPlease contact the hospital for more information.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Info Card
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: backgroundColor,
                    child: Icon(Icons.person, size: 30, color: darkButtonColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${widget.doctorUser.fullName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.doctor.specialization,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fee: omr-${widget.doctor.consultationFee.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: darkButtonColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Booking Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hospital Selection
                  const Text(
                    'Select Hospital',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedHospitalId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Choose a hospital',
                    ),
                    items: _hospitals.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          entry.value.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedHospitalId = value;
                        _selectedDate = null;
                        _selectedTimeSlot = null;
                        _availableTimeSlots.clear();
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a hospital';
                      }
                      return null;
                    },
                  ),
                  if (_selectedHospitalId != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Doctor available: ${_getDoctorAvailabilityForHospital(_selectedHospitalId!)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Date Selection
                  const Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: darkButtonColor),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate != null
                                ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                                : 'Choose appointment date',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedDate != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time Slot Selection
                  const Text(
                    'Select Time Slot',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedDate == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please select a date first',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_availableTimeSlots.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No time slots available for the selected date',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTimeSlots.map((slot) {
                        final isSelected = _selectedTimeSlot == slot;
                        return InkWell(
                          onTap: () {
                            setState(() => _selectedTimeSlot = slot);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? darkButtonColor : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? darkButtonColor
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              slot,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),

                  // Symptoms
                  const Text(
                    'Symptoms / Reason for Visit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _symptomsController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe your symptoms...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please describe your symptoms';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Book Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _bookAppointment,
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
                        : const Text(
                            'Book Appointment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

