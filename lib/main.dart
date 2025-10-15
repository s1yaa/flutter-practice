import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppRouter {
  static const String authWrapper = '/';
  static const String main = '/main';
  static const String editProfile = '/edit_profile';
  static const String stories = '/stories';
  static const String chatList = '/chat_list';
  static const String chat = '/chat';
  static const String progress = '/progress';
  static const String mentorDetail = '/mentor_detail';

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

const MaterialColor customPrimarySwatch = MaterialColor(
  0xFF7B4BFF,
  <int, Color>{
    50: Color(0xFFF1EDFF),
    100: Color(0xFFDCD0FF),
    200: Color(0xFFC5B0FF),
    300: Color(0xFFAF8FFF),
    400: Color(0xFF9B77FF),
    500: Color(0xFF875FFF),
    600: Color(0xFF7B4BFF),
    700: Color(0xFF6A38F7),
    800: Color(0xFF5A26E8),
    900: Color(0xFF4315D3),
  },
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MentorshipProvider()),
      ],
      child: const PeerMentorApp(),
    ),
  );
}

class PeerMentorApp extends StatelessWidget {
  const PeerMentorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PeerPath',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: customPrimarySwatch,
        primaryColor: customPrimarySwatch.shade600,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Poppins',
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.grey.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 16),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: customPrimarySwatch.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: customPrimarySwatch.shade600,
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: false,
          elevation: 5,
        ),
      ),
      initialRoute: AppRouter.authWrapper,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? university;
  final String? major;
  final int? graduationyear;
  final String? currentcompany;
  final List<String> interests;
  final List<String> skills;
  final String? location;
  final bool isVerified;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.university,
    this.major,
    this.graduationyear,
    this.currentcompany,
    this.interests = const [],
    this.skills = const [],
    this.location,
    this.isVerified = false,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    DateTime safeCreatedAt;
    try {
      safeCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } catch (_) {
      safeCreatedAt = DateTime.now();
    }

    return UserProfile(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'student',
      university: map['university'],
      major: map['major'],
      graduationyear: map['graduationYear'] is int ? map['graduationYear'] : null,
      currentcompany: map['currentCompany'] is String ? map['currentCompany'] : null,
      interests: List<String>.from(map['interests'] ?? []),
      skills: List<String>.from(map['skills'] ?? []),
      location: map['location'] is String ? map['location'] : null,
      isVerified: map['isVerified'] ?? false,
      createdAt: safeCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'university': university,
      'major': major,
      'graduationYear': graduationyear,
      'currentCompany': currentcompany,
      'interests': interests,
      'skills': skills,
      'location': location,
      'isVerified': isVerified,
      'createdAt': createdAt,
    };
  }
}

class MentorshipRequest {
  final String id;
  final String studentId;
  final String mentorId;
  final String status;
  final String message;
  final DateTime createdAt;

  MentorshipRequest({
    required this.id,
    required this.studentId,
    required this.mentorId,
    required this.status,
    required this.message,
    required this.createdAt,
  });

  factory MentorshipRequest.fromMap(Map<String, dynamic> map, String id) {
    return MentorshipRequest(
      id: id,
      studentId: map['studentId'] ?? '',
      mentorId: map['mentorId'] ?? '',
      status: map['status'] ?? 'pending',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'mentorId': mentorId,
      'status': status,
      'message': message,
      'createdAt': createdAt,
    };
  }
}

class Review {
  final String id;
  final String authorId;
  final String targetId;
  final String targetType;
  final double rating;
  final String title;
  final String content;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.authorId,
    required this.targetId,
    required this.targetType,
    required this.rating,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      authorId: map['authorId'] ?? '',
      targetId: map['targetId'] ?? '',
      targetType: map['targetType'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'targetId': targetId,
      'targetType': targetType,
      'rating': rating,
      'title': title,
      'content': content,
      'createdAt': createdAt,
    };
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
    };
  }
}

class Story {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    this.tags = const [],
    required this.createdAt,
  });

  factory Story.fromMap(Map<String, dynamic> map, String id) {
    return Story(
      id: id,
      authorId: map['authorId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'title': title,
      'content': content,
      'tags': tags,
      'createdAt': createdAt,
    };
  }
}

class ProgressTask {
  final String id;
  final String studentId;
  final String mentorId;
  final String description;
  final String status;
  final DateTime assignedAt;

  ProgressTask({
    required this.id,
    required this.studentId,
    required this.mentorId,
    required this.description,
    required this.status,
    required this.assignedAt,
  });

  factory ProgressTask.fromMap(Map<String, dynamic> map, String id) {
    return ProgressTask(
      id: id,
      studentId: map['studentId'] ?? '',
      mentorId: map['mentorId'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      assignedAt: (map['assignedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'mentorId': mentorId,
      'description': description,
      'status': status,
      'assignedAt': assignedAt,
    };
  }
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  UserProfile? _userProfile;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
  }
  
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!, uid);
      }
    } catch (e) {
      print("Error getting user profile: $e");
    }
    return null;
  }


  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userProfile = UserProfile.fromMap(doc.data()!, uid);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    } catch (e) {
      print('CRITICAL PROFILE LOAD ERROR: $e');
      _userProfile = null;
      notifyListeners();
    }
  }

  // In AuthProvider class
Future<String?> signUp(String email, String password, String name, String role) async {
  try {
    print("STEP 1: Attempting to create user in Firebase Auth...");
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    print("SUCCESS: Auth user created. UID: ${credential.user!.uid}");

    final profile = UserProfile(
      uid: credential.user!.uid,
      email: email,
      name: name,
      role: role,
      isVerified: false, // Explicitly set for the new document
      createdAt: DateTime.now(),
    );

    print("STEP 2: Attempting to create user profile document in Firestore...");
    await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set(profile.toMap());
    print("SUCCESS: Firestore document created.");

    // The authStateChanges listener will automatically call _loadUserProfile after this
    return null;
  } catch (e) {
    print("---!!! SIGN UP FAILED !!!---");
    print("The process failed with this error:");
    print(e.toString());
    print("-----------------------------");
    return e.toString();
  }
}

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return;

    await _firestore.collection('users').doc(_user!.uid).update(data);
    await _loadUserProfile(_user!.uid);
  }
}

class MentorshipProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserProfile>> searchMentors({UserProfile? studentProfile}) async {
    final query = _firestore.collection('users').where('role', isEqualTo: 'mentor');
    
    final snapshot = await query.limit(50).get();
    final mentors = snapshot.docs
        .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
        .toList();

    if (studentProfile == null || studentProfile.interests.isEmpty) {
      return mentors;
    }
    
    mentors.sort((a, b) {
      final scoreA = _calculateMatchScore(a, studentProfile);
      final scoreB = _calculateMatchScore(b, studentProfile);
      return scoreB.compareTo(scoreA);
    });

    return mentors;
  }
  
  int _calculateMatchScore(UserProfile mentor, UserProfile student) {
    int score = 0;
    final studentInterests = student.interests.toSet();
    
    for (String skill in mentor.skills) {
      if (studentInterests.contains(skill)) {
        score += 2; 
      }
    }
    for (String interest in mentor.interests) {
      if (studentInterests.contains(interest)) {
        score += 1;
      }
    }
    return score;
  }

  Future<void> sendMentorshipRequest(String mentorId, String message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
       print("Error: User is not signed in.");
       return;
    }

    final request = MentorshipRequest(
      id: '',
      studentId: user.uid,
      mentorId: mentorId,
      status: 'pending',
      createdAt: DateTime.now(),
      message: message,
    );
    try {
       await _firestore.collection('mentorship_requests').add(request.toMap());
       print("Mentorship request sent successfully!");
    } catch (e) {
        print("Error sending mentorship request: $e");
    }
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    await _firestore.collection('mentorship_requests').doc(requestId).update({
      'status': accept ? 'accepted' : 'rejected',
    });
    notifyListeners();
  }

  Stream<List<MentorshipRequest>> getPendingRequests(String userId) {
    return _firestore
        .collection('mentorship_requests')
        .where('mentorId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MentorshipRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> submitReview(Review review) async {
    await _firestore.collection('reviews').add(review.toMap());
    notifyListeners();
  }

  Stream<List<Review>> getReviews(String targetId) {
    return _firestore
        .collection('reviews')
        .where('targetId', isEqualTo: targetId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Review.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> postStory(Story story) async {
    await _firestore.collection('stories').add(story.toMap());
    notifyListeners();
  }

  Stream<List<Story>> getStories({List<String>? tags}) {
    Query query = _firestore.collection('stories').orderBy('createdAt', descending: true);
    
    if (tags != null && tags.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: tags);
    }

    return query.limit(20).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Story.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }
  
  Stream<List<Story>> getStoriesForMentor(String authorId) {
     return _firestore
        .collection('stories')
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Story.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<UserProfile>> getMatchedMenteesForMentor(String mentorId) {
    return _firestore
        .collection('mentorship_requests')
        .where('mentorId', isEqualTo: mentorId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((requestSnapshot) async {
      if (requestSnapshot.docs.isEmpty) {
        return <UserProfile>[];
      }

      final studentIds = requestSnapshot.docs
          .map((doc) => doc.data()['studentId'] as String)
          .toList();

      if (studentIds.isEmpty) {
        return <UserProfile>[];
      }
      
      final studentDocs = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: studentIds)
          .get();

      return studentDocs.docs
          .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  String getChatId(String user1, String user2) {
    return user1.compareTo(user2) < 0 ? '${user1}_$user2' : '${user2}_$user1';
  }
  
  Future<void> sendMessage(String chatId, String senderId, String recipientId, String text) async {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
    );
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());
        
    await _firestore.collection('chats').doc(chatId).set({
      'members': [senderId, recipientId],
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  
  Stream<QuerySnapshot> getChatsForUser(String userId) {
    return _firestore
      .collection('chats')
      .where('members', arrayContains: userId)
      .orderBy('lastMessageAt', descending: true)
      .snapshots();
  }

  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> assignTask(
      String studentId, String mentorId, String description) async {
    final task = ProgressTask(
      id: '',
      studentId: studentId,
      mentorId: mentorId,
      description: description,
      status: 'pending',
      assignedAt: DateTime.now(),
    );
    await _firestore.collection('progress').add(task.toMap());
    notifyListeners();
  }

  Stream<List<ProgressTask>> getMenteeTasks(String menteeId) {
    return _firestore
        .collection('progress')
        .where('studentId', isEqualTo: menteeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProgressTask.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _firestore.collection('progress').doc(taskId).update({'status': status});
    notifyListeners();
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Getting things ready...',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isAuthenticated) {
      if (authProvider.userProfile == null) {
        return const LoadingScreen();
      }
      return const MainScreen();
    }

    return const LoginScreen();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  final _nameController = TextEditingController();
  String _selectedRole = 'student';

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? error;

    if (_isLogin) {
      error = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      error = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _selectedRole,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else if (!_isLogin) {
        Navigator.of(context).pushReplacementNamed(AppRouter.main);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50),
              Icon(
                Icons.school_rounded,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                _isLogin ? 'Welcome Back!' : 'Create Account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'Login to continue your journey.' : 'Let\'s get you started!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (!_isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                obscureText: true,
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.work_outline_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'student', child: Text('I am a Student')),
                    DropdownMenuItem(
                        value: 'mentor', child: Text('I am a Mentor')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedRole = value!);
                  },
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                      )
                    : Text(_isLogin ? 'Login' : 'Sign Up'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() => _isLogin = !_isLogin);
                },
                child: Text.rich(
                  TextSpan(
                    text: _isLogin
                        ? 'Don\'t have an account? '
                        : 'Already have an account? ',
                    style: const TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: _isLogin ? 'Sign Up' : 'Login',
                        style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isMentor = authProvider.userProfile?.role == 'mentor';

    final List<Widget> screens = isMentor
        ? [
            HomeScreen(onTabChange: _changeTab),
            MenteesScreen(),
            RequestsScreen(),
            ProfileScreen(),
          ]
        : [
            HomeScreen(onTabChange: _changeTab),
            SearchScreen(),
            MyMentorsScreen(),
            ProfileScreen(),
          ];
          
    final List<BottomNavigationBarItem> navItems = isMentor
        ? const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Mentees'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Requests'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ]
        : const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.school_rounded), label: 'Mentors'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ];


    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _changeTab,
        items: navItems,
      ),
    );
  }
}

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

class MenteesScreen extends StatelessWidget {
  const MenteesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final mentorId = authProvider.user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Mentees'),
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: Provider.of<MentorshipProvider>(context).getMatchedMenteesForMentor(mentorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong fetching mentees."));
          }
          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No mentees yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      'Accept requests from the Requests tab to see them here.',
                      style: TextStyle(color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return _MenteeListCard(student: student, mentorId: mentorId);
            },
          );
        },
      ),
    );
  }
}

class _MenteeListCard extends StatelessWidget {
  final UserProfile student;
  final String mentorId;

  const _MenteeListCard({Key? key, required this.student, required this.mentorId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: customPrimarySwatch.shade100,
                  child: Text(
                    student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 22, color: customPrimarySwatch.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      Text(student.major ?? 'No major specified', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Start Chat'),
                  onPressed: () {
                    final provider = Provider.of<MentorshipProvider>(context, listen: false);
                    final chatId = provider.getChatId(mentorId, student.uid);
                    Navigator.pushNamed(context, AppRouter.chat, arguments: {
                      'recipientId': student.uid,
                      'recipientName': student.name,
                      'chatId': chatId,
                    });
                  },
                ),
              ],
            )
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
                  if(user.isVerified)
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

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<UserProfile> _allMentors = [];
  List<UserProfile> _filteredMentors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAndSortMentors();
  }

  Future<void> _fetchAndSortMentors() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<MentorshipProvider>(context, listen: false);
    
    final mentors = await provider.searchMentors(studentProfile: authProvider.userProfile);
    
    if (mounted) {
      setState(() {
        _allMentors = mentors;
        _filteredMentors = mentors;
        _isLoading = false;
      });
    }
  }
  
  void _filterMentors(String query) {
    final filtered = _allMentors.where((mentor) {
      final input = query.toLowerCase();
      return mentor.name.toLowerCase().contains(input) ||
             (mentor.major?.toLowerCase().contains(input) ?? false) ||
             mentor.skills.any((s) => s.toLowerCase().contains(input));
    }).toList();
    
    setState(() {
      _filteredMentors = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Mentor'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, major, skills...',
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
              ),
              onChanged: _filterMentors,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMentors.isEmpty
                    ? Center(
                        child: Text(
                          "No mentors found.",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : RefreshIndicator(
                      onRefresh: _fetchAndSortMentors,
                      child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredMentors.length,
                          itemBuilder: (context, index) {
                            return MentorCard(mentor: _filteredMentors[index]);
                          },
                        ),
                    ),
          ),
        ],
      ),
    );
  }
}

class MentorCard extends StatelessWidget {
  final UserProfile mentor;
  const MentorCard({Key? key, required this.mentor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _UserSummaryCard(
      user: mentor,
      isMentor: true,
      onTap: () => Navigator.pushNamed(context, AppRouter.mentorDetail, arguments: mentor),
    );
  }
}

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
                            widget.mentor.name.isNotEmpty ? widget.mentor.name[0].toUpperCase() : '?',
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
                      widget.mentor.name,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (widget.mentor.currentcompany != null)
                      Text(
                        '${widget.mentor.currentcompany}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    if (widget.mentor.isVerified)
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
                  _ProfileSection(
                    title: "Education",
                    children: [
                      _InfoRow(icon: Icons.school_rounded, label: "University", value: widget.mentor.university ?? "N/A"),
                      _InfoRow(icon: Icons.book_rounded, label: "Major", value: widget.mentor.major ?? "N/A"),
                      if (widget.mentor.graduationyear != null)
                        _InfoRow(icon: Icons.calendar_today_rounded, label: "Graduation Year", value: widget.mentor.graduationyear.toString()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ProfileSection(
                    title: "Skills",
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.mentor.skills.map((skill) => Chip(
                          label: Text(skill, style: TextStyle(color: customPrimarySwatch.shade800, fontWeight: FontWeight.w500)),
                          backgroundColor: customPrimarySwatch.shade50,
                        )).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStoriesSection(context),
                  const SizedBox(height: 16),
                  if (isMenteeViewing && widget.mentor.uid != currentUserId && _requestStatus == 'accepted')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final chatId = Provider.of<MentorshipProvider>(context, listen: false).getChatId(currentUserId, widget.mentor.uid);
                          Navigator.pushNamed(context, AppRouter.chat, arguments: {
                            'recipientId': widget.mentor.uid,
                            'recipientName': widget.mentor.name,
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
                  
                  _ProfileSection(
                    title: 'Reviews',
                    children: [
                       StreamBuilder<List<Review>>(
                        stream: Provider.of<MentorshipProvider>(context, listen: false).getReviews(widget.mentor.uid),
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
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(context, isMenteeViewing, currentUserId),
    );
  }
  
  Widget _buildStoriesSection(BuildContext context) {
    return _ProfileSection(
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
    if (!isMenteeViewing || widget.mentor.uid == currentUserId) {
      return null;
    }
    
    String text = 'Request Mentorship';
    VoidCallback? onPressed = () => _showRequestDialog(context);

    if (_requestStatus == 'pending') {
      text = 'Request Sent';
      onPressed = null;
    } else if (_requestStatus == 'accepted') {
      return null;
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
}

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentorship Requests'),
      ),
      body: StreamBuilder<List<MentorshipRequest>>(
        stream: Provider.of<MentorshipProvider>(context).getPendingRequests(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No pending requests', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Your inbox is all clear for now!', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          final requests = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return RequestCard(request: requests[index]);
            },
          );
        },
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final MentorshipRequest request;

  const RequestCard({Key? key, required this.request}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(request.studentId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.data!.exists) {
                  return const Text("Mentee profile not found.");
                }

                final mentee = UserProfile.fromMap(
                  snapshot.data!.data() as Map<String, dynamic>,
                  request.studentId,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text(
                            mentee.name[0].toUpperCase(),
                            style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mentee.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (mentee.university != null)
                                Text(
                                  mentee.university!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Message:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(request.message),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await Provider.of<MentorshipProvider>(context, listen: false).respondToRequest(request.id, false);
                            },
                            child: const Text('Decline'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await Provider.of<MentorshipProvider>(context, listen: false).respondToRequest(request.id, true);
                            },
                            child: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MyMentorsScreen extends StatelessWidget {
  const MyMentorsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Mentors'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mentorship_requests')
            .where('studentId', isEqualTo: userId)
            .where('status', isEqualTo: 'accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No active mentors yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Use the Explore tab to find and connect!', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final request = MentorshipRequest.fromMap(
                snapshot.data!.docs[index].data() as Map<String, dynamic>,
                snapshot.data!.docs[index].id,
              );
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(request.mentorId).get(),
                builder: (context, mentorSnapshot) {
                  if (!mentorSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final mentor = UserProfile.fromMap(
                    mentorSnapshot.data!.data() as Map<String, dynamic>,
                    request.mentorId,
                  );
                  return MentorCard(mentor: mentor);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.userProfile;

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            _ProfileSection(
              title: 'Education',
              children: [
                _InfoRow(icon: Icons.school_rounded, label: 'University', value: profile.university ?? "Not set"),
                _InfoRow(icon: Icons.book_rounded, label: 'Major', value: profile.major ?? "Not set"),
                if (profile.graduationyear != null)
                  _InfoRow(icon: Icons.calendar_today_rounded, label: 'Graduation Year', value: profile.graduationyear.toString()),
              ],
            ),
            const SizedBox(height: 16),
            if (profile.role == 'mentor')
              _ProfileSection(
                title: 'Career',
                children: [
                  _InfoRow(icon: Icons.business_center_rounded, label: 'Company', value: profile.currentcompany ?? "Not set"),
                ],
              ),
            const SizedBox(height: 16),
            _ProfileSection(
              title: 'My Interests / Skills',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.skills.map((skill) => Chip(
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
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _universityController = TextEditingController();
  final _majorController = TextEditingController();
  final _gradYearController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final List<String> _skills = [];
  final _skillController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AuthProvider>(context, listen: false).userProfile;
    if (profile != null) {
      _universityController.text = profile.university ?? '';
      _majorController.text = profile.major ?? '';
      _gradYearController.text = profile.graduationyear?.toString() ?? '';
      _companyController.text = profile.currentcompany ?? '';
      _locationController.text = profile.location ?? '';
      _skills.addAll(profile.skills);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'university': _universityController.text,
      'major': _majorController.text,
      'graduationYear': int.tryParse(_gradYearController.text),
      'currentCompany': _companyController.text,
      'location': _locationController.text,
      'skills': _skills,
      'interests': _skills,
    };

    await Provider.of<AuthProvider>(context, listen: false).updateProfile(data);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isMentor = authProvider.userProfile?.role == 'mentor';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _universityController,
              decoration: const InputDecoration(labelText: 'University', hintText: 'e.g. Stanford University'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _majorController,
              decoration: const InputDecoration(labelText: 'Major', hintText: 'e.g. Computer Science'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gradYearController,
              decoration: const InputDecoration(labelText: 'Graduation Year', hintText: 'e.g. 2024'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
             if (isMentor) ...[
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(labelText: 'Current Company', hintText: 'e.g. Google'),
                ),
                const SizedBox(height: 16),
             ],
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location', hintText: 'e.g. New York, USA'),
            ),
            const SizedBox(height: 24),
            Text(isMentor ? 'My Skills' : 'My Interests', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillController,
                    decoration: InputDecoration(hintText: isMentor ? 'Add a skill (e.g. Python)' : 'Add an interest (e.g. AI)'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_skillController.text.isNotEmpty) {
                      setState(() {
                        _skills.add(_skillController.text.trim());
                        _skillController.clear();
                      });
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.map((skill) {
                return Chip(
                  label: Text(skill),
                  onDeleted: () {
                    setState(() => _skills.remove(skill));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class StoriesScreen extends StatefulWidget {
  final String? authorId;

  const StoriesScreen({Key? key, this.authorId}) : super(key: key);

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  List<String> _selectedTags = [];

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isMentor = authProvider.userProfile?.role == 'mentor';
    final provider = Provider.of<MentorshipProvider>(context, listen: false);

    final isViewingOwnStories = isMentor && widget.authorId != null && widget.authorId == authProvider.user!.uid;
    final appBarTitle = isViewingOwnStories ? "My Stories" : "Mentorship Stories";

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: isViewingOwnStories ? [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            onPressed: () {
              _showPostStoryDialog(context, provider);
            },
          )
        ] : null,
      ),
      body: Column(
        children: [
          if (_selectedTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8,
                children: _selectedTags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => _toggleTag(tag),
                )).toList(),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Story>>(
              stream: widget.authorId != null
                  ? provider.getStoriesForMentor(widget.authorId!)
                  : provider.getStories(tags: _selectedTags.isEmpty ? null : _selectedTags),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.amp_stories_rounded, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _selectedTags.isEmpty ? 'No stories available yet.' : 'No stories found with selected tags.',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                final stories = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: stories.length,
                  itemBuilder: (context, index) {
                    final story = stories[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(story.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text(story.content, maxLines: 5, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 12),
                            if (story.tags.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                children: story.tags.map((tag) => InkWell(
                                  onTap: () => _toggleTag(tag),
                                  child: Chip(
                                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                                    padding: EdgeInsets.zero,
                                    backgroundColor: _selectedTags.contains(tag) ? customPrimarySwatch.shade200 : customPrimarySwatch.shade50,
                                  ),
                                )).toList(),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPostStoryDialog(BuildContext context, MentorshipProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _PostStoryDialog(
        onPost: (title, content, tags) async {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            if (title.isNotEmpty && content.isNotEmpty && authProvider.user != null) {
              final story = Story(
                id: '',
                authorId: authProvider.user!.uid,
                title: title,
                content: content,
                tags: tags,
                createdAt: DateTime.now(),
              );
              await provider.postStory(story);
              Navigator.pop(context);
            }
        }
      ),
    );
  }
}

class _PostStoryDialog extends StatefulWidget {
  final Function(String title, String content, List<String> tags) onPost;
  const _PostStoryDialog({Key? key, required this.onPost}) : super(key: key);

  @override
  State<_PostStoryDialog> createState() => _PostStoryDialogState();
}

class _PostStoryDialogState extends State<_PostStoryDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];

  void _addTag() {
    if (_tagController.text.isNotEmpty && !_tags.contains(_tagController.text.trim())) {
      setState(() {
        _tags.add(_tagController.text.trim());
        _tagController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Post New Story', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _tagController, decoration: const InputDecoration(labelText: 'Add Tag'))),
                IconButton(icon: const Icon(Icons.add), onPressed: _addTag),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _tags.map((tag) => Chip(
                label: Text(tag),
                onDeleted: () => setState(() => _tags.remove(tag)),
              )).toList(),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
        ),
        ElevatedButton(
          onPressed: () => widget.onPost(_titleController.text.trim(), _contentController.text.trim(), _tags),
          child: const Text('Post'),
        ),
      ],
    );
  }
}

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final mentorshipProvider = Provider.of<MentorshipProvider>(context);
    final currentUserId = authProvider.user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: mentorshipProvider.getChatsForUser(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No chats yet.', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                  Text('Start a conversation with a mentor!', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final chatDoc = snapshot.data!.docs[index];
              final members = List<String>.from(chatDoc['members']);
              final recipientId = members.firstWhere((id) => id != currentUserId, orElse: () => '');
              final lastMessage = chatDoc['lastMessage'] ?? '';
              
              if(recipientId.isEmpty) return const SizedBox.shrink();

              return FutureBuilder<UserProfile?>(
                future: authProvider.getUserProfile(recipientId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text("Loading chat..."));
                  }
                  final recipient = userSnapshot.data;
                  if (recipient == null) {
                    return const SizedBox.shrink();
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Text(
                        recipient.name.isNotEmpty ? recipient.name[0].toUpperCase() : '?',
                        style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(recipient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.chat, arguments: {
                        'recipientId': recipient.uid,
                        'recipientName': recipient.name,
                        'chatId': chatDoc.id
                      });
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  final String recipientId;
  final String recipientName;
  final String? chatId;

  const ChatScreen({
    Key? key,
    required this.recipientId,
    required this.recipientName,
    this.chatId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context).user?.uid ?? '';
    final provider = Provider.of<MentorshipProvider>(context, listen: false);
    final finalChatId = chatId ?? provider.getChatId(currentUserId, recipientId);
    final messageController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text(recipientName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: provider.getChatMessages(finalChatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if(snapshot.data!.isEmpty) {
                  return const Center(child: Text('Say hello! 👋'));
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: isMe ? Theme.of(context).primaryColor : Colors.grey.shade200,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      if (messageController.text.isNotEmpty) {
                        provider.sendMessage(
                          finalChatId,
                          currentUserId,
                          recipientId,
                          messageController.text.trim(),
                        );
                        messageController.clear();
                      }
                    },
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isMentor = authProvider.userProfile?.role == 'mentor';
    final userId = authProvider.user?.uid ?? '';
    final provider = Provider.of<MentorshipProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isMentor ? 'Student Progress' : 'My Progress'),
        actions: isMentor ? [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            onPressed: () => _showAssignTaskDialog(context, provider, userId),
          )
        ] : null,
      ),
      body: StreamBuilder<List<ProgressTask>>(
        stream: isMentor 
            ? FirebaseFirestore.instance.collection('progress').where('mentorId', isEqualTo: userId).snapshots().map((s) => s.docs.map((d) => ProgressTask.fromMap(d.data(), d.id)).toList())
            : provider.getMenteeTasks(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    isMentor ? 'You haven\'t assigned any tasks.' : 'Your progress tracker is empty.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final tasks = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final isCompleted = task.status == 'completed';

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  leading: CircleAvatar(
                    backgroundColor: isCompleted ? Colors.green.shade100 : customPrimarySwatch.shade100,
                    child: Icon(
                      isCompleted ? Icons.check_rounded : Icons.hourglass_empty_rounded,
                      color: isCompleted ? Colors.green.shade700 : customPrimarySwatch.shade700,
                    ),
                  ),
                  title: Text(task.description, style: TextStyle(fontWeight: FontWeight.w600, decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none)),
                  subtitle: Text('Status: ${task.status.toUpperCase()}'),
                  onTap: !isMentor ? () {
                    if (!isCompleted) {
                      provider.updateTaskStatus(task.id, 'completed');
                    }
                  } : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  void _showAssignTaskDialog(BuildContext context, MentorshipProvider provider, String mentorId) {
    final descriptionController = TextEditingController();
    UserProfile? selectedMentee;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Assign New Task', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FutureBuilder<List<UserProfile>>(
                    future: provider.getMatchedMenteesForMentor(mentorId).first,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final mentees = snapshot.data ?? [];
                      if (mentees.isEmpty) return const Text("You have no mentees to assign tasks to.");

                      return DropdownButtonFormField<UserProfile>(
                        value: selectedMentee,
                        hint: const Text("Select a Mentee"),
                        items: mentees.map((mentee) => DropdownMenuItem(
                          value: mentee,
                          child: Text(mentee.name),
                        )).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedMentee = value);
                        },
                      );
                    }
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Task Description'),
                    maxLines: 3,
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
                    if (descriptionController.text.isNotEmpty && selectedMentee != null) {
                      await provider.assignTask(
                        selectedMentee!.uid,
                        mentorId,
                        descriptionController.text.trim(),
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task Assigned!')),
                      );
                    }
                  },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}