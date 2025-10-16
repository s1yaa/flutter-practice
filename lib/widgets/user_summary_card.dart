import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/user_profile.dart';

class UserSummaryCard extends StatelessWidget {
  final UserProfile user;
  final bool isMentor;
  final VoidCallback onTap;

  const UserSummaryCard({
    Key? key,
    required this.user,
    required this.isMentor,
    required this.onTap,
  }) : super(key: key);

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