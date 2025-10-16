import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../app_router.dart';
import '../constants/app_colors.dart';
import '../models/review.dart';
import '../models/story.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/mentorship_provider.dart';
import '../widgets/profile_widgets.dart';

class MentorDetailScreen extends StatefulWidget {
  final UserProfile mentor;
  const MentorDetailScreen({Key? key, required this.mentor}) : super(key: key);

  @override
  State<MentorDetailScreen> createState() => _MentorDetailScreenState();
}

class _MentorDetailScreenState extends State<MentorDetailScreen> {
  String _requestStatus = 'loading';

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  Future<void> _checkExistingRequest() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userProfile?.role != 'student') {
      setState(() => _requestStatus = 'not_applicable');
      return;
    }

    final studentId = authProvider.user!.uid;
    final mentorId = widget.mentor.uid;

    final query = await FirebaseFirestore.instance
        .collection('mentorship_requests')
        .where('studentId', isEqualTo: studentId)
        .where('mentorId', isEqualTo: mentorId)
        .limit(1)
        .get();

    if (mounted) {
      if (query.docs.isNotEmpty) {
        setState(() {
          _requestStatus = query.docs.first.data()['status'] ?? 'pending';
        });
      } else {
        setState(() {
          _requestStatus = 'not_sent';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.uid ?? '';
    final isMenteeViewing = authProvider.userProfile?.role == 'student';

    final userProfile = widget.mentor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 280,
              child: Stack(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  ),
                  Positioned(
                    top: 140,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: CircleAvatar(
                        radius: 64,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          child: Text(
                            userProfile.name.isNotEmpty ? userProfile.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 50,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      userProfile.name,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (userProfile.currentcompany != null)
                      Text(
                        '${userProfile.currentcompany}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    if (userProfile.isVerified)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Chip(
                          label: const Text('Verified Mentor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileSection(
                    title: "Education",
                    children: [
                      InfoRow(icon: Icons.school_rounded, label: "University", value: userProfile.university ?? "N/A"),
                      InfoRow(icon: Icons.book_rounded, label: "Major", value: userProfile.major ?? "N/A"),
                      if (userProfile.graduationyear != null)
                        InfoRow(icon: Icons.calendar_today_rounded, label: "Graduation Year", value: userProfile.graduationyear.toString()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (userProfile.role == 'mentor') ...[
                    ProfileSection(
                      title: "Skills",
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: userProfile.skills.map((skill) => Chip(
                            label: Text(skill, style: TextStyle(color: customPrimarySwatch.shade800, fontWeight: FontWeight.w500)),
                            backgroundColor: customPrimarySwatch.shade50,
                          )).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStoriesSection(context),
                    const SizedBox(height: 16),
                    if (isMenteeViewing && userProfile.uid != currentUserId && _requestStatus == 'accepted')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final chatId = Provider.of<MentorshipProvider>(context, listen: false).getChatId(currentUserId, userProfile.uid);
                            Navigator.pushNamed(context, AppRouter.chat, arguments: {
                              'recipientId': userProfile.uid,
                              'recipientName': userProfile.name,
                              'chatId': chatId,
                            });
                          },
                          icon: const Icon(Icons.chat_rounded),
                          label: const Text('Start Chat'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ),
                    ProfileSection(
                      title: 'Reviews',
                      children: [
                        StreamBuilder<List<Review>>(
                          stream: Provider.of<MentorshipProvider>(context, listen: false).getReviews(userProfile.uid),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final reviews = snapshot.data!;
                            if (reviews.isEmpty) {
                              return const Text('No reviews yet.');
                            }
                            return Column(
                              children: reviews.take(3).map((review) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          RatingBarIndicator(
                                            rating: review.rating,
                                            itemBuilder: (context, index) => const Icon(Icons.star_rounded, color: Colors.amber),
                                            itemCount: 5,
                                            itemSize: 16,
                                          ),
                                          const Spacer(),
                                          Text(
                                            DateFormat('MMM d, yyyy').format(review.createdAt),
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(review.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(review.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(context, isMenteeViewing, currentUserId),
    );
  }

  Widget _buildStoriesSection(BuildContext context) {
    return ProfileSection(
      title: "Stories & Insights",
      children: [
        StreamBuilder<List<Story>>(
          stream: Provider.of<MentorshipProvider>(context, listen: false).getStoriesForMentor(widget.mentor.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final stories = snapshot.data ?? [];
            if (stories.isEmpty) {
              return const Text("No stories posted yet.");
            }
            return Column(
              children: stories.map((story) => ListTile(
                title: Text(story.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(story.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () {},
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget? _buildBottomButton(BuildContext context, bool isMenteeViewing, String currentUserId) {
    if (!isMenteeViewing || widget.mentor.uid == currentUserId || widget.mentor.role != 'mentor') {
      return null;
    }

    if (_requestStatus == 'accepted') {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.rate_review_rounded),
            label: const Text('Leave a Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
            ),
            onPressed: () => _showReviewDialog(context),
          ),
        ),
      );
    }

    String text = 'Request Mentorship';
    VoidCallback? onPressed = () => _showRequestDialog(context);

    if (_requestStatus == 'pending') {
      text = 'Request Sent';
      onPressed = null;
    } else if (_requestStatus == 'loading') {
      text = 'Loading...';
      onPressed = null;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          icon: Icon(onPressed == null ? Icons.check_circle_rounded : Icons.person_add_alt_1_rounded),
          onPressed: onPressed,
          label: Text(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed == null ? Colors.grey.shade400 : customPrimarySwatch.shade600,
          ),
        ),
      ),
    );
  }

  void _showRequestDialog(BuildContext context) {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Request ${widget.mentor.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Send a personalized message to introduce yourself.'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'Why do you want to connect?',
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<MentorshipProvider>(context, listen: false);
              if (messageController.text.trim().isEmpty) {
                return;
              }
              await provider.sendMentorshipRequest(
                widget.mentor.uid,
                messageController.text,
              );
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mentorship Request sent! ✨')),
              );
              setState(() {
                _requestStatus = 'pending';
              });
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    double _rating = 3.0;

    showDialog(
      context: context,
      builder: (context) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Review ${widget.mentor.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Share your experience to help others.'),
                const SizedBox(height: 20),
                RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) {
                    _rating = rating;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Review Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Your Feedback'),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () async {
                final provider = Provider.of<MentorshipProvider>(context, listen: false);
                if (contentController.text.trim().isEmpty || authProvider.user == null) {
                  return;
                }
                final newReview = Review(
                  id: '',
                  authorId: authProvider.user!.uid,
                  targetId: widget.mentor.uid,
                  targetType: 'mentor',
                  rating: _rating,
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  createdAt: DateTime.now(),
                );

                await provider.submitReview(newReview);
                
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you for your review! ⭐')),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}