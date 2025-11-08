import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../patients/patient_drawer.dart';
import '../../patients/profile_page.dart';
import '../../services/firestore_service.dart';

class ProfilePage extends StatelessWidget {
  static const route = '/patient/profile'; // route ثابت للصفحة
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      drawer: PatientDrawer(),
      body: SafeArea(
        child: ProfilePageBody(),
      ),
    );
  }
}

class ReviewsScreen extends StatelessWidget {
  final String doctorId;
  const ReviewsScreen({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    // 🎨 ألوان موحدة من الثيم
    const primaryColor = Color(0xFF00695C); // Teal 800
    const lightColor = Color(0xFFE0F2F1);   // Teal 50
    const accentColor = Color(0xFF009688);  // Teal 500

    return Scaffold(
      backgroundColor: lightColor,
      appBar: AppBar(
        title: const Text(
          "Patient Reviews",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FS.doctorReviews(doctorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No reviews yet",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs
            ..sort((a, b) {
              final t1 = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              final t2 = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              return t2.compareTo(t1);
            });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final patientName = data['patientName'] ?? 'Unknown';
              final reviewText = data['review'] ?? 'No comment provided';
              final stars = (data['stars'] ?? 0).toInt();
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final formattedDate = createdAt != null
                  ? "${createdAt.day}/${createdAt.month}/${createdAt.year}"
                  : "—";

              return Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: accentColor.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: accentColor,
                            child: Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              patientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(
                          5,
                              (i) => Icon(
                            i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                            color: Colors.amber.shade600,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: lightColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          reviewText,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
