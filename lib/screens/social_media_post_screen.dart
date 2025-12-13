import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/social_media_service.dart';
import '../l10n/app_localizations.dart';

class SocialMediaPostScreen extends StatefulWidget {
  const SocialMediaPostScreen({super.key});

  @override
  State<SocialMediaPostScreen> createState() => _SocialMediaPostScreenState();
}

class _SocialMediaPostScreenState extends State<SocialMediaPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _postController = TextEditingController();
  final SocialMediaService _socialMediaService = SocialMediaService();

  SocialMediaPlatform _selectedPlatform = SocialMediaPlatform.facebook;
  bool _isPosting = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _postToSocialMedia() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isPosting = true;
      _error = null;
      _success = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final postText = _postController.text.trim();

      final result = await _socialMediaService.postToPlatform(
        platform: _selectedPlatform,
        postText: postText,
        userId: user.uid,
      );

      // Save to history
      await FirebaseFirestore.instance.collection('social_media_posts').add({
        'userId': user.uid,
        'platform': _selectedPlatform.name,
        'postText': postText,
        'postedAt': FieldValue.serverTimestamp(),
        'status': result['success'] == true ? 'shared' : 'failed',
        'error': result['error'],
        'message': result['message'],
      });

      if (result['success'] == true) {
        setState(() {
          _success = result['message'] ?? 'Post published successfully!';
          _postController.clear();
        });
      } else {
        setState(() {
          _error = result['error'] ?? 'Failed to post';
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final backgroundColor = const Color(0xFFDDE8EB);
    final darkButtonColor = const Color(0xFF2E4E53);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          loc?.social_media ?? 'Social Media',
          style: const TextStyle(
            fontFamily: 'Serif',
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Facebook Card
              _buildPlatformCard(),

              const SizedBox(height: 24),

              // Post Editor
              _buildPostEditor(loc, darkButtonColor),

              const SizedBox(height: 24),

              // Error / Success Messages
              if (_error != null) _buildErrorCard(),
              if (_success != null) ...[
                const SizedBox(height: 12),
                _buildSuccessCard(),
              ],

              const SizedBox(height: 24),

              // Share button
              _buildShareButton(loc, darkButtonColor),

              const SizedBox(height: 24),

              // History
              Text(
                loc?.recent_posts ?? 'Recent Posts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkButtonColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildPostHistory(loc),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // UI COMPONENTS
  // -------------------------------------------------------------

  Widget _buildPlatformCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBox(
            icon: Icons.facebook,
            color: Colors.blue,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Facebook',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E4E53),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Post will be published directly to your Facebook page',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostEditor(AppLocalizations? loc, Color darkButtonColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc?.write_post ?? 'Write Your Post',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkButtonColor,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _postController,
            maxLines: 8,
            maxLength: 5000,
            decoration: InputDecoration(
              hintText: loc?.post_hint ?? 'What\'s on your mind?',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return loc?.required_field ?? 'Please write something';
              }
              if (value.length > 5000) {
                return loc?.post_too_long ?? 'Post is too long (max 5000 chars)';
              }
              return null;
            },
          ),

          ValueListenableBuilder(
            valueListenable: _postController,
            builder: (_, value, __) => Text(
              '${value.text.length}/5000',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return _statusMessageCard(
      color: Colors.red,
      message: _error!,
      icon: Icons.error,
    );
  }

  Widget _buildSuccessCard() {
    return _statusMessageCard(
      color: Colors.green,
      message: _success!,
      icon: Icons.check_circle,
    );
  }

  Widget _buildStatusChip(String status, AppLocalizations? loc) {
    final isSuccess = status == 'shared' || status == 'posted';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isSuccess ? (loc?.shared ?? 'Shared') : (loc?.failed ?? 'Failed'),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Widget _buildShareButton(AppLocalizations? loc, Color darkColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isPosting ? null : _postToSocialMedia,
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isPosting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                loc?.post_to_facebook ?? 'Post to Facebook',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // -------------------------------------------------------------
  // POST HISTORY
  // -------------------------------------------------------------

  Widget _buildPostHistory(AppLocalizations? loc) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('social_media_posts')
          .where('userId', isEqualTo: user.uid)
          .orderBy('postedAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _noPostsCard(loc);
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (_, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _historyItem(data, loc);
          },
        );
      },
    );
  }

  Widget _historyItem(Map<String, dynamic> data, AppLocalizations? loc) {
    final platformStr = data['platform'] ?? 'facebook';
    final postText = data['postText'] ?? '';
    final status = data['status'] ?? 'failed';
    final postedAt = data['postedAt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.facebook, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                platformStr.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              _buildStatusChip(status, loc),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            postText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (postedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              _formatDate(postedAt.toDate()),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // HELPERS
  // -------------------------------------------------------------

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
      ],
    );
  }

  Widget _iconBox({required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }

  Widget _statusMessageCard({required Color color, required String message, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color)),
          )
        ],
      ),
    );
  }

  Widget _noPostsCard(AppLocalizations? loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Text(
        loc?.no_posts_yet ?? 'No posts yet',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) return '${diff.inMinutes} minutes ago';
      return '${diff.inHours} hours ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
