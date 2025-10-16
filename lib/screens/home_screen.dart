import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_router.dart';
import '../constants/app_colors.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/mentorship_provider.dart';
import 'mentor_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int) onTabChange;

  const HomeScreen({
    Key? key,
    required this.onTabChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.userProfile;
    final isMentor = profile?.role == 'mentor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [customPrimarySwatch.shade400, customPrimarySwatch.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${profile?.name.split(' ').first ?? "User"}! 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isMentor
                        ? 'Let\'s inspire the next generation.'
                        : 'Find the perfect guide for your journey.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isMentor ? 'Your Mentees' : 'Top Mentor Matches',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (profile != null)
              isMentor
                  ? _MentorHomeDashboard(mentorProfile: profile)
                  : _MenteeHomeDashboard(studentProfile: profile)
            else
              const Center(child: Text("Profile data loading...")),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _QuickActionCard(
                  icon: Icons.search_rounded,
                  title: isMentor ? 'Find Students' : 'Find Mentors',
                  color: Colors.blue.shade400,
                  onTap: () {
                    onTabChange(1);
                  },
                ),
                _QuickActionCard(
                  icon: isMentor ? Icons.article_rounded : Icons.amp_stories_rounded,
                  title: isMentor ? 'Post Story' : 'View Stories',
                  color: Colors.orange.shade400,
                  onTap: () => Navigator.pushNamed(context, AppRouter.stories),
                ),
                _QuickActionCard(
                  icon: Icons.check_circle_outline_rounded,
                  title: isMentor ? 'Student Progress' : 'My Progress',
                  color: Colors.green.shade400,
                  onTap: () => Navigator.pushNamed(context, AppRouter.progress),
                ),
                _QuickActionCard(
                  icon: Icons.chat_rounded,
                  title: 'My Chats',
                  color: Colors.purple.shade400,
                  onTap: () => Navigator.pushNamed(context, AppRouter.chatList),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MentorHomeDashboard extends StatelessWidget {
  final UserProfile mentorProfile;
  const _MentorHomeDashboard({Key? key, required this.mentorProfile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProfile>>(
      stream: Provider.of<MentorshipProvider>(context).getMatchedMenteesForMentor(mentorProfile.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong."));
        }
        final students = snapshot.data ?? [];
        if (students.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text("No mentees matched yet.\nAccept requests to see them here!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ),
          );
        }
        return Column(
          children: students.map((student) {
            return _UserSummaryCard(
              user: student,
              isMentor: false,
              onTap: () => Navigator.pushNamed(context, AppRouter.mentorDetail, arguments: student),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MenteeHomeDashboard extends StatelessWidget {
  final UserProfile studentProfile;
  const _MenteeHomeDashboard({Key? key, required this.studentProfile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserProfile>>(
      future: Provider.of<MentorshipProvider>(context).searchMentors(studentProfile: studentProfile),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final mentors = snapshot.data ?? [];
        if (mentors.isEmpty) {
          return const Center(child: Text("No recommended mentors found."));
        }
        return Column(
          children: mentors.take(3).map((mentor) {
            return MentorCard(mentor: mentor);
          }).toList(),
        );
      },
    );
  }
}

class _UserSummaryCard extends StatelessWidget {
  final UserProfile user;
  final bool isMentor;
  final VoidCallback onTap;

  const _UserSummaryCard({
    required this.user,
    required this.isMentor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 24, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          isMentor
                              ? 'Works at: ${user.currentcompany ?? 'N/A'}'
                              : '${user.major ?? 'Unknown Major'}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (user.isVerified)
                    Icon(Icons.verified_user, color: Colors.blue.shade600, size: 22),
                ],
              ),
              if (user.skills.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.skills.take(3).map((skill) => Chip(
                    label: Text(skill, style: TextStyle(fontSize: 12, color: customPrimarySwatch.shade800, fontWeight: FontWeight.w500)),
                    backgroundColor: customPrimarySwatch.shade50,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color.withGreen(50),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}