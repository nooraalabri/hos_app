import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../models/doctor_model.dart';
import '../../models/user_model.dart';
import '../../models/hospital_model.dart';
import 'book_appointment_screen.dart';
import 'patient_home_screen.dart';

class SearchDoctorsScreen extends StatefulWidget {
  const SearchDoctorsScreen({Key? key}) : super(key: key);

  @override
  State<SearchDoctorsScreen> createState() => _SearchDoctorsScreenState();
}

class _SearchDoctorsScreenState extends State<SearchDoctorsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<DoctorModel> _doctors = [];
  List<UserModel> _doctorUsers = [];
  List<HospitalModel> _hospitals = [];
  bool _isLoading = false;
  
  String? _selectedSpecialization;
  String? _selectedHospital;
  int? _minExperience;

  final List<String> _specializations = [
    'Cardiology',
    'Dermatology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'General Medicine',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      final hospitals = await _firebaseService.getAllHospitals();
      final doctors = await _firebaseService.getAllDoctors();
      
      // Load user data for approved doctors only
      List<UserModel> doctorUsers = [];
      for (var doctor in doctors) {
        final user = await _firebaseService.getUser(doctor.uid);
        if (user != null && user.status == AccountStatus.active) {
          doctorUsers.add(user);
        }
      }

      setState(() {
        _hospitals = hospitals;
        _doctors = doctors.where((d) {
          final user = doctorUsers.firstWhere(
            (u) => u.uid == d.uid,
            orElse: () => UserModel(
              uid: '',
              email: '',
              firstName: '',
              lastName: '',
              phoneNumber: '',
              role: UserRole.doctor,
              status: AccountStatus.rejected,
              createdAt: DateTime.now(),
            ),
          );
          return user.status == AccountStatus.active;
        }).toList();
        _doctorUsers = doctorUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading doctors: $e')),
        );
      }
    }
  }

  Future<void> _searchDoctors() async {
    setState(() => _isLoading = true);

    try {
      final doctors = await _firebaseService.searchDoctors(
        specialization: _selectedSpecialization,
        hospitalId: _selectedHospital,
        minExperience: _minExperience,
      );

      // Filter approved doctors
      List<UserModel> doctorUsers = [];
      for (var doctor in doctors) {
        final user = await _firebaseService.getUser(doctor.uid);
        if (user != null && user.status == AccountStatus.active) {
          doctorUsers.add(user);
        }
      }

      setState(() {
        _doctors = doctors.where((d) {
          final user = doctorUsers.firstWhere(
            (u) => u.uid == d.uid,
            orElse: () => UserModel(
              uid: '',
              email: '',
              firstName: '',
              lastName: '',
              phoneNumber: '',
              role: UserRole.doctor,
              status: AccountStatus.rejected,
              createdAt: DateTime.now(),
            ),
          );
          return user.status == AccountStatus.active;
        }).toList();
        _doctorUsers = doctorUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFDDE8EB);
    final darkButtonColor = const Color(0xFF2E4E53);

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          // Navigation handled by system
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const PatientHomeScreen()),
              );
            },
          ),
          title: const Text(
            'Search Doctors',
            style: TextStyle(
              fontFamily: 'Serif',
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
        ),
      body: Column(
        children: [
          // Search Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search by name
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by doctor name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: backgroundColor.withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: 12),

                // Specialization filter
                DropdownButtonFormField<String>(
                  value: _selectedSpecialization,
                  decoration: InputDecoration(
                    labelText: 'Specialization',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: backgroundColor.withOpacity(0.3),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ..._specializations.map((spec) {
                      return DropdownMenuItem(value: spec, child: Text(spec));
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedSpecialization = value);
                  },
                ),
                const SizedBox(height: 12),

                // Hospital filter
                DropdownButtonFormField<String>(
                  value: _selectedHospital,
                  decoration: InputDecoration(
                    labelText: 'Hospital Location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: backgroundColor.withOpacity(0.3),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ..._hospitals.map((hospital) {
                      return DropdownMenuItem(
                        value: hospital.id,
                        child: Text(hospital.name),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedHospital = value);
                  },
                ),
                const SizedBox(height: 12),

                // Search button
                ElevatedButton(
                  onPressed: _searchDoctors,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkButtonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search),
                      SizedBox(width: 8),
                      Text('Search'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _doctors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No doctors found',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _doctors.length,
                        itemBuilder: (context, index) {
                          final doctor = _doctors[index];
                          final user = _doctorUsers.firstWhere(
                            (u) => u.uid == doctor.uid,
                            orElse: () => UserModel(
                              uid: '',
                              email: '',
                              firstName: 'Unknown',
                              lastName: 'Doctor',
                              phoneNumber: '',
                              role: UserRole.doctor,
                              status: AccountStatus.active,
                              createdAt: DateTime.now(),
                            ),
                          );
                          return _buildDoctorCard(doctor, user);
                        },
                      ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor, UserModel user) {
    final darkButtonColor = const Color(0xFF2E4E53);

    return Container(
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
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFDDE8EB),
                child: user.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user.profileImageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(Icons.person, size: 30, color: darkButtonColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${user.fullName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialization,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor.rating.toStringAsFixed(1)} (${doctor.totalReviews} reviews)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '${doctor.experienceYears} years experience',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
              Text(
                '\$${doctor.consultationFee.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  _showDoctorDetails(doctor, user);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: darkButtonColor,
                  side: BorderSide(color: darkButtonColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View Profile'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookAppointmentScreen(
                        doctor: doctor,
                        doctorUser: user,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkButtonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Book Appointment'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDoctorDetails(DoctorModel doctor, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Dr. ${user.fullName}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doctor.specialization,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Qualification', doctor.qualification),
                  _buildDetailRow('Experience', '${doctor.experienceYears} years'),
                  _buildDetailRow('License', doctor.licenseNumber),
                  _buildDetailRow('Consultation Fee', '\omr-${doctor.consultationFee.toStringAsFixed(0)}'),
                  if (doctor.about != null && doctor.about!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'About',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(doctor.about!),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

