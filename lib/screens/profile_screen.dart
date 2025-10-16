import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_router.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.userProfile;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isStudent = profile.role == 'student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRouter.editProfile),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 48,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              profile.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                profile.role == 'mentor' ? 'Mentor' : 'Student',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              backgroundColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 32),

            _buildProgressCard(context, isStudent ? profile.goalsPercentage : profile.mentorScore, isStudent),

            const SizedBox(height: 16),

            ProfileSection(
              title: 'Education',
              children: [
                InfoRow(icon: Icons.school_rounded, label: 'University', value: profile.university ?? "Not set"),
                InfoRow(icon: Icons.book_rounded, label: 'Major', value: profile.major ?? "Not set"),
                if (profile.graduationyear != null)
                  InfoRow(icon: Icons.calendar_today_rounded, label: 'Graduation Year', value: profile.graduationyear.toString()),
              ],
            ),
            const SizedBox(height: 16),
            if (profile.role == 'mentor')
              ProfileSection(
                title: 'Career',
                children: [
                  InfoRow(icon: Icons.business_center_rounded, label: 'Company', value: profile.currentcompany ?? "Not set"),
                ],
              ),
            const SizedBox(height: 16),
            ProfileSection(
              title: 'My Interests / Skills',
              children: [
                if (profile.skills.isEmpty && profile.interests.isEmpty)
                  Text("No skills or interests added yet.", style: TextStyle(color: Colors.grey.shade600)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (profile.skills.isNotEmpty ? profile.skills : profile.interests).map((skill) => Chip(
                    label: Text(skill, style: TextStyle(color: customPrimarySwatch.shade800)),
                    backgroundColor: customPrimarySwatch.shade50,
                  )).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, int percentage, bool isStudent) {
    final title = isStudent ? "Monthly Goal Progress" : "Mentor Impact";
    final description = isStudent
        ? "You’ve completed $percentage% of your learning goals this month!"
        : "You've achieved a $percentage% impact score based on your activity.";

    return Card(
      elevation: 4,
      shadowColor: customPrimarySwatch.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 12,
                backgroundColor: customPrimarySwatch.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(customPrimarySwatch.shade600),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRouter.achievements),
                child: const Text('View All My Badges →'),
              ),
            )
          ],
        ),
      ),
    );
  }
}