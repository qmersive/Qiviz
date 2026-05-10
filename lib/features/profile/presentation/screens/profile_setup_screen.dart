import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _countryController = TextEditingController();
  final _universityController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  
  // For simplicity in MVP, using comma separated strings for arrays
  final _interestsController = TextEditingController();
  final _languagesController = TextEditingController();
  
  String _selectedGoal = 'Make Friends';
  final List<String> _goals = [
    'Make Friends',
    'Find Love',
    'Cultural Exchange',
    'Dare Challenges',
    'Blind Dates',
    'Events'
  ];

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final interests = _interestsController.text.split(',').map((e) => e.trim()).toList();
      final languages = _languagesController.text.split(',').map((e) => e.trim()).toList();

      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'name': _nameController.text.trim(),
        'nickname': _nicknameController.text.trim(),
        'country': _countryController.text.trim(),
        'university': _universityController.text.trim(),
        'city': _cityController.text.trim(),
        'bio': _bioController.text.trim(),
        'interests': interests,
        'languages': languages,
        'relationship_goals': [_selectedGoal],
        'is_onboarded': true,
      });

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Tell us about yourself!',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.electricBlue,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(_nameController, 'Full Name', Icons.person),
            const SizedBox(height: 16),
            _buildTextField(_nicknameController, 'Nickname (Optional)', Icons.alternate_email),
            const SizedBox(height: 16),
            _buildTextField(_countryController, 'Home Country', Icons.flag),
            const SizedBox(height: 16),
            _buildTextField(_universityController, 'University in India', Icons.school),
            const SizedBox(height: 16),
            _buildTextField(_cityController, 'Current City', Icons.location_city),
            const SizedBox(height: 16),
            _buildTextField(_interestsController, 'Interests (comma separated)', Icons.star),
            const SizedBox(height: 16),
            _buildTextField(_languagesController, 'Languages (comma separated)', Icons.language),
            const SizedBox(height: 16),
            _buildTextField(_bioController, 'Short Bio', Icons.edit, maxLines: 3),
            const SizedBox(height: 24),
            Text('Primary Goal', style: GoogleFonts.outfit(color: AppTheme.textWhite, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedGoal,
              dropdownColor: AppTheme.surfaceDark,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.track_changes, color: AppTheme.textGrey),
              ),
              items: _goals.map((goal) {
                return DropdownMenuItem(
                  value: goal,
                  child: Text(goal, style: const TextStyle(color: AppTheme.textWhite)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedGoal = val);
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const CircularProgressIndicator(color: AppTheme.textWhite)
                  : const Text('Complete Setup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textWhite),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textGrey),
      ),
      validator: (value) {
        if (hint.contains('Optional')) return null;
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $hint';
        }
        return null;
      },
    );
  }
}
