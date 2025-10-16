import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

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