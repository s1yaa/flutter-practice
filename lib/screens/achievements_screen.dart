import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/achievement.dart';
import '../providers/auth_provider.dart';
import '../providers/gamification_provider.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final gamificationProvider = Provider.of<GamificationProvider>(context);
    final userId = authProvider.user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('My Achievements')),
      body: StreamBuilder<List<Achievement>>(
        stream: gamificationProvider.getAchievementsForUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_moon_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No Badges Yet!', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                  Text('Complete tasks to earn new achievements.', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          final achievements = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _BadgeCard(achievement: achievement);
            },
          );
        },
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Achievement achievement;
  const _BadgeCard({Key? key, required this.achievement}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconData(int.parse(achievement.badgeIcon), fontFamily: 'MaterialIcons'),
              size: 50,
              color: customPrimarySwatch.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              achievement.badgeName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}