import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../l10n/app_localizations.dart';

class ReviewsScreen extends StatelessWidget {
  final String doctorId;
  const ReviewsScreen({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          t.patientReviews,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        centerTitle: true,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FS.doctorReviews(doctorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                t.noReviews,
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: theme.hintColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          DateTime? _parseDate(dynamic date) {
            if (date == null) return null;
            if (date is Timestamp) return date.toDate();
            if (date is String) {
              try {
                return DateTime.parse(date);
              } catch (e) {
                return null;
              }
            }
            if (date is DateTime) return date;
            return null;
          }

          final docs = snapshot.data!.docs
            ..sort(
                  (a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;
                final t1 = _parseDate(dataA['createdAt']) ?? DateTime(0);
                final t2 = _parseDate(dataB['createdAt']) ?? DateTime(0);
                return t2.compareTo(t1);
              },
            );

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final patientName = data['patientName'] ?? '—';
              final reviewText = data['review'] ?? data['comment'] ?? t.noComment;
              final stars = (data['stars'] ?? data['rating'] ?? 0).toInt();
              final createdAt = _parseDate(data['createdAt']);
              final formattedDate = createdAt != null
                  ? "${createdAt.day}/${createdAt.month}/${createdAt.year}"
                  : "—";

              return Card(
                elevation: 3,
                color: theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ======== Header Row ========
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.colorScheme.primary,
                            child: Icon(
                              Icons.person,
                              color: theme.colorScheme.onPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              patientName,
                              style: theme.textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ======== Stars ========
                      Row(
                        children: List.generate(
                          5,
                              (i) => Icon(
                            i < stars
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber.shade600,
                            size: 22,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ======== Review Text ========
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          reviewText,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: theme.colorScheme.onSurface,
                            height: 1.4,
                            fontSize: 15,
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
