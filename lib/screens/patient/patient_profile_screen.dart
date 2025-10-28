import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/patient_screen_wrapper.dart';
import 'edit_profile_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({Key? key}) : super(key: key);

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final patient = authProvider.currentPatient;
    final backgroundColor = const Color(0xFFDDE8EB);
    final darkButtonColor = const Color(0xFF2E4E53);
    const currentIndex = 3; // Profile tab

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: AppDrawer(
        menuItems: PatientScreenHelper.getDrawerItems(context, currentIndex),
      ),
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Serif',
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Picture
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: user?.profileImageUrl != null
                        ? ClipOval(
                            child: Image.network(
                              user!.profileImageUrl!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.person, size: 60, color: darkButtonColor),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile picture upload coming soon!'),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: darkButtonColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.fullName ?? 'User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Personal Information
            _buildInfoSection(
              'Personal Information',
              [
                _buildInfoTile('Phone', user?.phoneNumber ?? 'Not set'),
                if (patient != null) ...[
                  _buildInfoTile('Date of Birth',
                      DateFormat('MMM dd, yyyy').format(patient.dateOfBirth)),
                  _buildInfoTile('Age', '${patient.age} years'),
                  _buildInfoTile('Gender', patient.gender.isNotEmpty ? patient.gender : 'Not set'),
                  _buildInfoTile('Blood Group', patient.bloodGroup.isNotEmpty ? patient.bloodGroup : 'Not set'),
                ],
              ],
            ),

            // Health Information
            if (patient != null)
              _buildInfoSection(
                'Health Information',
                [
                  if (patient.height != null)
                    _buildInfoTile('Height', '${patient.height} cm'),
                  if (patient.weight != null)
                    _buildInfoTile('Weight', '${patient.weight} kg'),
                  if (patient.bmi != null)
                    _buildInfoTile('BMI', patient.bmi!.toStringAsFixed(1)),
                  if (patient.allergies.isNotEmpty)
                    _buildInfoTile('Allergies', patient.allergies.join(', ')),
                  if (patient.chronicDiseases.isNotEmpty)
                    _buildInfoTile('Chronic Diseases', patient.chronicDiseases.join(', ')),
                ],
              ),

            // Emergency Contact
            if (patient != null &&
                (patient.emergencyContactName != null ||
                    patient.emergencyContactPhone != null))
              _buildInfoSection(
                'Emergency Contact',
                [
                  if (patient.emergencyContactName != null)
                    _buildInfoTile('Name', patient.emergencyContactName!),
                  if (patient.emergencyContactPhone != null)
                    _buildInfoTile('Phone', patient.emergencyContactPhone!),
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) => PatientScreenHelper.navigateToTab(context, index, currentIndex),
        items: PatientScreenHelper.getBottomNavItems(),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

