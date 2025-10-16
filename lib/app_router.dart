import 'package:flutter/material.dart';

import 'models/user_profile.dart';
import 'screens/achievements_screen.dart';
import 'screens/auth_wrapper.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/main_screen.dart';
import 'screens/mentor_detail_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/stories_screen.dart';


class AppRouter {
  static const String authWrapper = '/';
  static const String main = '/main';
  static const String editProfile = '/edit_profile';
  static const String stories = '/stories';
  static const String chatList = '/chat_list';
  static const String chat = '/chat';
  static const String progress = '/progress';
  static const String mentorDetail = '/mentor_detail';
  static const String achievements = '/achievements';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case authWrapper:
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
      case main:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case stories:
        final authorId = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => StoriesScreen(authorId: authorId));
      case chatList:
        return MaterialPageRoute(builder: (_) => const ChatListScreen());
      case progress:
        return MaterialPageRoute(builder: (_) => const ProgressScreen());
      case achievements:
        return MaterialPageRoute(builder: (_) => const AchievementsScreen());
      case mentorDetail:
        final mentor = settings.arguments as UserProfile;
        return MaterialPageRoute(builder: (_) => MentorDetailScreen(mentor: mentor));
      case chat:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => ChatScreen(
          recipientId: args['recipientId'],
          recipientName: args['recipientName'],
          chatId: args['chatId'],
        ));
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}