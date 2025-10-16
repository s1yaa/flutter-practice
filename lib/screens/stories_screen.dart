import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/story.dart';
import '../providers/auth_provider.dart';
import '../providers/mentorship_provider.dart';

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

    final canPost = isMentor && widget.authorId == null;
    final appBarTitle = "Mentorship Stories";

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: canPost ? [
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
            await provider.postStory(context, story);
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