import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; 
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

const MaterialColor customPrimarySwatch = MaterialColor(
  0xFF00ADB5, // Primary Color (Teal/Cyan)
  <int, Color>{
    50: Color(0xFFE0F7FA),
    100: Color(0xFFB3EBF5),
    200: Color(0xFF80DEEA),
    300: Color(0xFF4DD0E1),
    400: Color(0xFF26C6DA),
    500: Color(0xFF00BCD4), // Base Teal
    600: Color(0xFF00ACC1),
    700: Color(0xFF0097A7),
    800: Color(0xFF00838F), // Used for App Bar
    900: Color(0xFF006064),
  },
);

void main() async {
  // 1. Initialize Flutter Bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. 🔑 CRITICAL: Load the .env file asynchronously
  await dotenv.load(fileName: ".env");

  // 3. Initialize Firebase (This uses the generated firebase_options.dart)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4. Run the application
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
        // UI FIX: Use custom primary swatch
        primarySwatch: customPrimarySwatch,
        primaryColor: customPrimarySwatch.shade800,
        // UI FIX: Soft pastel background color inspired by the theme
        scaffoldBackgroundColor: const Color(0xFFF0F5F5), 
        cardColor: Colors.white, // Crisp white cards
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          color: customPrimarySwatch.shade800,
          titleTextStyle: const TextStyle(
            color: Colors.white, 
            fontSize: 22, 
            fontWeight: FontWeight.bold
          ),
        ),
        // UI FIX: Use rounded borders for inputs and buttons
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: customPrimarySwatch.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3, // Soft lift
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

// ============================================================================
// MODELS (ADJUSTED TO USER'S FIELDS/CASING)
// ============================================================================

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String role; // 'student' or 'mentor'
  final String? university;
  final String? major;
  final int? graduationyear; // User-specified property
  final String? currentcompany; // User-specified property
  final List<String> interests;
  final List<String> skills;
  final String? location;
  final bool isverified; // User-specified property
  final DateTime createdat; // User-specified property

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.university,
    this.major,
    int? graduationYear, // Temporary parameter for Firestore mapping
    String? currentCompany, // Temporary parameter for Firestore mapping
    this.interests = const [],
    this.skills = const [],
    this.location,
    bool isVerified = false, // Temporary parameter for Firestore mapping
    required DateTime createdAt, // Temporary parameter for Firestore mapping
  }) : graduationyear = graduationYear,
       currentcompany = currentCompany,
       isverified = isVerified,
       createdat = createdAt;


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
      // MAPPING: Reading Firestore camelCase keys into Dart properties
      graduationYear: map['graduationYear'] is int ? map['graduationYear'] : null,
      currentCompany: map['currentCompany'] is String ? map['currentCompany'] : null,
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
      // MAPPING: Writing Dart properties to Firestore camelCase keys
      'graduationYear': graduationyear,
      'currentCompany': currentcompany,
      'interests': interests,
      'skills': skills,
      'location': location,
      'isVerified': isverified,
      'createdAt': createdat,
    };
  }
}

class MentorshipRequest {
  final String id;
  final String studentId; 
  final String mentorId; 
  final String status; // 'pending', 'accepted', 'rejected'
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
  final String targetId; // mentor or university/company
  final String targetType; // 'mentor', 'university', 'company'
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
  final String status; // 'pending', 'in_progress', 'completed'
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

// ============================================================================
// PROVIDERS
// ============================================================================

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

  Future<String?> signUp(String email, String password, String name, String role) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final profile = UserProfile(
        uid: credential.user!.uid,
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
      );
      
      await _firestore.collection('users').doc(credential.user!.uid).set(profile.toMap());
      return null;
    } catch (e) {
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
  
  Future<void> createDummyUser(String email, String password, String name, String role) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = credential.user!.uid;

      final profile = UserProfile(
        uid: uid,
        email: email,
        name: name,
        role: role,
        university: role == 'mentor' ? 'State University' : 'Local College',
        major: role == 'mentor' ? 'Software Engineering' : 'Computer Science',
        currentCompany: role == 'mentor' ? 'TechCorp' : null,
        isVerified: role == 'mentor',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(profile.toMap());
      await _auth.signOut(); 
      print('Successfully created dummy $role: $email');
    } catch (e) {
      print('Error creating dummy user: $e');
    }
  }
}

class MentorshipProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserProfile>> searchMentors({
    String? major,
    String? university,
    List<String>? interests,
  }) async {
    Query query = _firestore.collection('users').where('role', isEqualTo: 'mentor');
    
    if (major != null && major.isNotEmpty) {
      query = query.where('major', isEqualTo: major);
    }
    
    final snapshot = await query.limit(20).get();
    return snapshot.docs
        .map((doc) => UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // --- Mentorship Requests (Existing) ---
  Future<void> sendMentorshipRequest(String mentorId, String message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final request = MentorshipRequest(
      id: '',
      studentId: user.uid,
      mentorId: mentorId,
      status: 'pending',
      createdAt: DateTime.now(),
      message: message,
    );

    await _firestore.collection('mentorship_requests').add(request.toMap());
    notifyListeners();
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
  // ------------------------------------

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
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromMap(doc.data(), doc.id))
            .toList());
  }
  
  // --- New: Stories Methods ---
  Future<void> postStory(Story story) async {
    await _firestore.collection('stories').add(story.toMap());
    notifyListeners();
  }

  Stream<List<Story>> getStories({List<String>? tags}) {
    Query query = _firestore.collection('stories').orderBy('createdAt', descending: true);
    return query.limit(10).snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => Story.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList()
    );
  }
  
  Stream<List<UserProfile>> getMenteesForMentor(UserProfile mentorProfile) {
    // FIX: Show all students as potential matches for the Mentor Dashboard
    return _firestore
      .collection('users')
      .where('role', isEqualTo: 'student')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => UserProfile.fromMap(doc.data(), doc.id)).toList());
  }
  
  // ----------------------------

  // --- New: Chat Methods ---
  String getChatId(String user1, String user2) {
    return user1.compareTo(user2) < 0 ? '${user1}_$user2' : '${user2}_$user1';
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
    );
    await _firestore.collection('chats').doc(chatId).collection('messages').add(message.toMap());
  }

  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList());
  }
  // -------------------------
  
  // --- New: Progress Methods ---
  Future<void> assignTask(String studentId, String mentorId, String description) async {
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
      .map((snapshot) => snapshot.docs.map((doc) => ProgressTask.fromMap(doc.data(), doc.id)).toList());
  }
  
  Future<void> updateTaskStatus(String taskId, String status) async {
    await _firestore.collection('progress').doc(taskId).update({'status': status});
    notifyListeners();
  }
  // -----------------------------
}

// ============================================================================
// SCREENS
// ============================================================================

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading profile data...'),
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
    
    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }
    
    if (authProvider.userProfile == null) {
      return const LoadingScreen();
    }

    return const MainScreen();
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
    
    setState(() => _isLoading = false);
    
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.school,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'PeerPath',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Connect with mentors who\'ve been there',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (!_isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'I am a',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student (Looking for guidance)')),
                    DropdownMenuItem(value: 'mentor', child: Text('Recent Graduate (Want to help)')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedRole = value!);
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isLogin ? 'Login' : 'Sign Up'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() => _isLogin = !_isLogin);
                },
                child: Text(
                  _isLogin
                      ? 'Don\'t have an account? Sign Up'
                      : 'Already have an account? Login',
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

    final screens = [
      HomeScreen(onTabChange: _changeTab),
      const SearchScreen(),
      if (isMentor) const RequestsScreen() else const MyMentorsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _changeTab,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(isMentor ? Icons.notifications : Icons.people),
            label: isMentor ? 'Requests' : 'Mentors',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
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
        title: const Text('PeerPath'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // UI FIX: Highlighted Welcome Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${profile?.name ?? "User"}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMentor
                          ? 'Review pending requests and post new stories to guide students.'
                          : 'Find a mentor and check out the latest student stories.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isMentor ? 'Matching Students' : 'Recommended Mentors',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 16),
            // Ensure profile is not null before passing to dashboard widget
            if (profile != null)
              isMentor ? _MentorHomeDashboard(mentorProfile: profile) : _MenteeHomeDashboard()
            else
              const Center(child: Text("Profile data loading...")),
            
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 16),
            // UI FIX: Grid view for quick actions
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                // FIX: Removed const keyword from QuickActionCards
                _QuickActionCard(
                  icon: Icons.search,
                  title: 'Find Mentors',
                  color: customPrimarySwatch.shade600,
                  onTap: () => onTabChange(1),  
                ),
                _QuickActionCard(
                  icon: isMentor ? Icons.article : Icons.amp_stories,
                  title: isMentor ? 'Post Story' : 'View Stories',
                  color: Colors.deepOrange.shade400,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => StoriesScreen(isMentor: isMentor)));
                  },
                ),
                _QuickActionCard(
                  icon: Icons.check_circle_outline,
                  title: 'Progress Tracker',
                  color: Colors.green.shade600,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen()));
                  },
                ),
                _QuickActionCard(
                  icon: Icons.chat,
                  title: 'My Chats',
                  color: Colors.purple.shade400,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen(recipientId: 'placeholder_id', recipientName: 'My Contacts')));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- NEW DASHBOARD SECTIONS ---

class _MentorHomeDashboard extends StatelessWidget {
  final UserProfile mentorProfile;
  const _MentorHomeDashboard({Key? key, required this.mentorProfile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show matching students stream
    return StreamBuilder<List<UserProfile>>(
      stream: Provider.of<MentorshipProvider>(context).getMenteesForMentor(mentorProfile),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final students = snapshot.data ?? [];
        if (students.isEmpty) {
          return const Center(child: Text("No matching students found yet."));
        }
        
        return Column(
          children: students.take(3).map((student) {
            return _UserSummaryCard(
              user: student,  
              isMentor: false,
              onTap: () {
                // Navigate to a student detail screen (using MentorDetail as template for now)
                Navigator.push(context, MaterialPageRoute(builder: (_) => MentorDetailScreen(mentor: student)));
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _MenteeHomeDashboard extends StatelessWidget {
  const _MenteeHomeDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show recommended mentors
    return FutureBuilder<List<UserProfile>>(
      future: Provider.of<MentorshipProvider>(context).searchMentors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final mentors = snapshot.data ?? [];
        if (mentors.isEmpty) {
          return const Center(child: Text("No recommended mentors found. Try expanding your profile interests."));
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
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    // UI FIX: Clean card with subtle shadow
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24, // Smaller avatar for card
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          // Using user's specific properties
                          isMentor  
                            ? 'Works at: ${user.currentcompany ?? 'N/A'}'
                            : '${user.major ?? 'Unknown'} in ${user.university ?? 'Unknown'}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  // Icon for status/role
                  Icon(user.isverified ? Icons.verified_user : Icons.school, 
                       color: user.isverified ? Colors.blue.shade700 : Colors.grey.shade500,
                       size: 20),
                ],
              ),
              const SizedBox(height: 12),
              if (user.skills.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.skills.take(3).map((skill) => Chip(
                    label: Text(skill, style: TextStyle(fontSize: 12, color: customPrimarySwatch.shade800)),
                    backgroundColor: customPrimarySwatch.shade50, // Light colored background for chip
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  )).toList(),
                ),
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
    // UI FIX: Raised card design with clear icon focus
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color), // Smaller, colored icon
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
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
  List<UserProfile> _mentors = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchMentors();
  }

  Future<void> _searchMentors() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<MentorshipProvider>(context, listen: false);
    final mentors = await provider.searchMentors();
    setState(() {
      _mentors = mentors;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Mentors'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            // UI FIX: Input field uses the new InputDecoration theme
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by major, university, or skills',
                prefixIcon: Icon(Icons.search, color: customPrimarySwatch.shade600),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.grey),
                  onPressed: () {
                    // Show filter dialog
                  },
                ),
              ),
              onSubmitted: (_) => _searchMentors(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _mentors.length,
                    itemBuilder: (context, index) {
                      return MentorCard(mentor: _mentors[index]);
                    },
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
    // Uses the generalized summary card with the new styling
    return _UserSummaryCard(
      user: mentor,
      isMentor: true,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MentorDetailScreen(mentor: mentor),
          ),
        );
      },
    );
  }
}

class MentorDetailScreen extends StatelessWidget {
  final UserProfile mentor;

  const MentorDetailScreen({Key? key, required this.mentor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context).user?.uid ?? '';
    final isMentee = Provider.of<AuthProvider>(context).userProfile?.role == 'student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // UI FIX: Profile Header Section (Consistent with Theme)
            Container(
              color: Theme.of(context).primaryColor,
              padding: const EdgeInsets.all(30),
              width: double.infinity,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      mentor.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 40,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    mentor.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (mentor.currentcompany != null)
                    Text(
                      '${mentor.currentcompany}',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  if (mentor.isverified)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Chip(
                        label: Text('Verified Mentor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Education Section (Placeholder structure)
                  _ProfileSection(
                    title: "Education",
                    children: [
                      _InfoRow(icon: Icons.school, label: "University", value: mentor.university ?? "N/A"),
                      _InfoRow(icon: Icons.book, label: "Major", value: mentor.major ?? "N/A"),
                      if(mentor.graduationyear != null)
                        _InfoRow(icon: Icons.calendar_today, label: "Graduation Year", value: mentor.graduationyear.toString()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Skills Section
                  _ProfileSection(
                    title: "Skills",
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: mentor.skills.map((skill) => Chip(
                          label: Text(skill, style: TextStyle(color: customPrimarySwatch.shade800)),
                          backgroundColor: customPrimarySwatch.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        )).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (isMentee && mentor.uid != currentUserId)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final chatId = Provider.of<MentorshipProvider>(context, listen: false).getChatId(currentUserId, mentor.uid);
                          Navigator.push(
                            context,  
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(recipientId: mentor.uid, recipientName: mentor.name, chatId: chatId)
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Start Chat'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: customPrimarySwatch.shade600,
                        ),
                      ),
                    ),
                  
                  Text(
                    'Reviews',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Review>>(
                    stream: Provider.of<MentorshipProvider>(context, listen: false)
                        .getReviews(mentor.uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final reviews = snapshot.data!;
                      if (reviews.isEmpty) {
                        return const Text('No reviews yet');
                      }
                      return Column(
                        children: reviews.take(3).map((review) {
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      RatingBarIndicator(
                                        rating: review.rating,
                                        itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                                        itemCount: 5,
                                        itemSize: 20,
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormat('MMM d, yyyy').format(review.createdAt),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(review.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(review.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isMentee && mentor.uid != currentUserId ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _showRequestDialog(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: customPrimarySwatch.shade800,
            ),
            child: const Text('Request Mentorship'),
          ),
        ),
      ) : null,
    );
  }

  void _showRequestDialog(BuildContext context) {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request Mentorship from ${mentor.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Send a personalized message to ${mentor.name}'),
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
              if (messageController.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message cannot be empty!')),
                );
                return;
              }
              await provider.sendMentorshipRequest(
                mentor.uid,
                messageController.text,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mentorship Request sent successfully!')),
              );
            },
            child: const Text('Send Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: customPrimarySwatch.shade800,
            ),
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
        stream: Provider.of<MentorshipProvider>(context)
            .getPendingRequests(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No pending requests', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(request.studentId) // Use studentId here
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
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
                          backgroundColor: Theme.of(context).primaryColor,
                          radius: 18,
                          child: Text(
                            mentee.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mentee.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                    const SizedBox(height: 12),
                    const Text(
                      'Message:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(request.message, maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    Text(
                      'Requested: ${DateFormat('MMM d, yyyy').format(request.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await Provider.of<MentorshipProvider>(
                                context,
                                listen: false,
                              ).respondToRequest(request.id, false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Request declined')),
                              );
                            },
                            child: const Text('Decline'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await Provider.of<MentorshipProvider>(
                                context,
                                listen: false,
                              ).respondToRequest(request.id, true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Request accepted!')),
                              );
                            },
                            child: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: customPrimarySwatch.shade800,
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No active mentors.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Check the Explore tab to send a request!', style: TextStyle(color: Colors.grey)),
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
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(request.mentorId)
                    .get(),
                builder: (context, mentorSnapshot) {
                  if (!mentorSnapshot.hasData) {
                    return const SizedBox();
                  }
                  final mentor = UserProfile.fromMap(
                    mentorSnapshot.data!.data() as Map<String, dynamic>,
                    request.mentorId,
                  );
                  // Display the accepted mentor using the stylish card
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
        title: const Text('Profile'),
        actions: [
          // EDIT PROFILE BUTTON (Already present)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              );
            },
          ),
          // 🛑 LOGOUT BUTTON (RESTORED)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // This calls the signOut method in the AuthProvider
              // which clears the user and navigates back to LoginScreen via AuthWrapper.
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20), // UI FIX: Increased padding
        child: Column(
          children: [
            // UI FIX: Centered Profile Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                profile.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 48,
                  color: Colors.white,
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
            const SizedBox(height: 24),
            
            // Education Section
            _ProfileSection(
              title: 'Education',
              children: [
                _InfoRow(icon: Icons.school, label: 'University', value: profile.university ?? "N/A"),
                _InfoRow(icon: Icons.book, label: 'Major', value: profile.major ?? "N/A"),
                if (profile.graduationyear != null)
                  _InfoRow(icon: Icons.calendar_today, label: 'Graduation Year', value: profile.graduationyear.toString()),
              ],
            ),
            const SizedBox(height: 16),

            // Career Section (Mentor Only)
            if (profile.role == 'mentor') 
              _ProfileSection(
                title: 'Career',
                children: [
                  _InfoRow(icon: Icons.business, label: 'Company', value: profile.currentcompany ?? "N/A"),
                ],
              ),
            const SizedBox(height: 16),

            // Skills Section
            if (profile.skills.isNotEmpty)
              _ProfileSection(
                title: 'Skills',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.skills.map((skill) => Chip(
                      label: Text(skill, style: TextStyle(color: customPrimarySwatch.shade800)),
                      backgroundColor: customPrimarySwatch.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    )).toList(),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            
            // Add other profile details as needed
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
    // UI FIX: Elevated card section
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
            const Divider(height: 20, color: Color(0xFFE0E0E0)),
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
    // UI FIX: Clean info row design
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: customPrimarySwatch.shade600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
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
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: 'Current Company', hintText: 'e.g. Google'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location', hintText: 'e.g. New York, USA'),
            ),
            const SizedBox(height: 24),
            Text('Skills', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillController,
                    decoration: InputDecoration(hintText: 'Add a skill', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_skillController.text.isNotEmpty) {
                      setState(() {
                        _skills.add(_skillController.text);
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
              child: const Text('Save Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- NEW FEATURE SCREENS (Completed Implementation) ---

class StoriesScreen extends StatelessWidget {
  final bool isMentor;
  const StoriesScreen({Key? key, required this.isMentor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MentorshipProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(isMentor ? 'Post New Story' : 'Mentorship Stories'),
        actions: isMentor ? [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showPostStoryDialog(context, provider);
            },
          )
        ] : null,
      ),
      body: StreamBuilder<List<Story>>(
        stream: provider.getStories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.amp_stories, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    isMentor ? 'Post your first story/tip!' : 'No stories found.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
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
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(story.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(story.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(DateFormat('MMM d').format(story.createdAt)),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Viewing story: ${story.title}')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  void _showPostStoryDialog(BuildContext context, MentorshipProvider provider) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post New Story', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
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
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty && authProvider.user != null) {
                final story = Story(
                  id: '', 
                  authorId: authProvider.user!.uid, 
                  title: titleController.text.trim(), 
                  content: contentController.text.trim(), 
                  createdAt: DateTime.now(),
                );
                await provider.postStory(story);
                Navigator.pop(context);
              }
            },
            child: const Text('Post'),
          ),
        ],
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

    // Placeholder for chat list overview
    if (recipientId == 'placeholder_id') {
      return Scaffold(
        appBar: AppBar(title: const Text('My Chats')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('Chat list interface goes here!', style: TextStyle(color: Colors.grey.shade600)),
              Text('Start a chat from an accepted connection or mentor profile.', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }
    
    // Actual 1:1 Chat View
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with $recipientName'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: provider.getChatMessages(finalChatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Start the conversation!'));
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isMe = message.senderId == currentUserId;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Theme.of(context).primaryColor : Colors.grey.shade300,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Send a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200,
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
                        messageController.text.trim()
                      );
                      messageController.clear();
                    }
                  },
                  child: const Icon(Icons.send),
                ),
              ],
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
        title: Text(isMentor ? 'Assigned Tasks' : 'My Progress Tracker'),
      ),
      body: StreamBuilder<List<ProgressTask>>(
        stream: provider.getMenteeTasks(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 60, color: Colors.green.shade400),
                  const SizedBox(height: 16),
                  Text(
                    isMentor ? 'Use the + button to assign a task.' : 'No tasks assigned yet. Reach out to your mentor!',
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
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCompleted ? Colors.green.shade100 : customPrimarySwatch.shade100,
                    child: Icon(
                      isCompleted ? Icons.check : Icons.hourglass_empty,
                      color: isCompleted ? Colors.green.shade700 : customPrimarySwatch.shade700,
                    ),
                  ),
                  title: Text(task.description, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                  subtitle: Text('Assigned: ${DateFormat('MMM d, yyyy').format(task.assignedAt)} | Status: ${task.status.toUpperCase()}'),
                  onTap: isMentor ? null : () {
                    // Mentee marks as complete
                    if (!isCompleted) {
                      provider.updateTaskStatus(task.id, 'completed');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task marked as completed!')),
                      );
                    }
                  },
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
    String? selectedMenteeId; 

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign New Task', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mentee Selection (In a full app, a dropdown of connected mentees would be here.)'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Target Mentee UID (Test Only)'),
              onChanged: (value) => selectedMenteeId = value,
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
              if (descriptionController.text.isNotEmpty && selectedMenteeId != null) {
                await provider.assignTask(
                  selectedMenteeId!, 
                  mentorId, 
                  descriptionController.text.trim()
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
      ),
    );
  }
}