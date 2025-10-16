import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_router.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/mentorship_provider.dart';
import '../widgets/user_summary_card.dart';

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
    return UserSummaryCard(
      user: mentor,
      isMentor: true,
      onTap: () => Navigator.pushNamed(context, AppRouter.mentorDetail, arguments: mentor),
    );
  }
}