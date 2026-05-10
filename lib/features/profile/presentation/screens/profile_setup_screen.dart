import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  bool _isLoading = false;
  int _currentPage = 0;
  final int _totalPages = 5; // Increased steps to make each one shorter

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _countryController = TextEditingController();
  final _universityController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  
  final Set<String> _selectedInterests = {};
  final List<String> _availableInterests = [
    'Anime', 'Gaming', 'Coding', 'Music', 'Travel', 'Photography',
    'Foodie', 'Sports', 'Art', 'Movies', 'Fashion', 'Fitness', 'Reading', 'Dancing'
  ];

  final Set<String> _selectedLanguages = {};
  final List<String> _availableLanguages = [
    'English', 'Hindi', 'Spanish', 'French', 'Arabic',
    'Mandarin', 'German', 'Russian', 'Japanese', 'Korean', 'Tamil', 'Telugu'
  ];
  
  String _selectedGoal = 'Make Friends';
  final List<String> _goals = [
    'Make Friends',
    'Find Love',
    'Cultural Exchange',
    'Dare Challenges',
    'Blind Dates',
    'Events'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _countryController.dispose();
    _universityController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_nameController.text.trim().isEmpty || _usernameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name and username!')));
        return;
      }
    } else if (_currentPage == 1) {
      if (_countryController.text.trim().isEmpty || _universityController.text.trim().isEmpty || _cityController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out your university details!')));
        return;
      }
    } else if (_currentPage == 2) {
      if (_selectedInterests.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick at least one interest! ✨')));
        return;
      }
    } else if (_currentPage == 3) {
      if (_selectedLanguages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one language! 🗣️')));
        return;
      }
    }

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _saveProfile();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  Future<void> _saveProfile() async {
    if (_bioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write a short bio to finish!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'country': _countryController.text.trim(),
        'university': _universityController.text.trim(),
        'city': _cityController.text.trim(),
        'bio': _bioController.text.trim(),
        'interests': _selectedInterests.toList(),
        'languages': _selectedLanguages.toList(),
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
    double progress = (_currentPage + 1) / _totalPages;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textWhite), onPressed: _prevPage)
            : null,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surfaceDark,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.electricBlue),
            minHeight: 8,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (int page) => setState(() => _currentPage = page),
              children: [
                _buildStep1(), // Identity
                _buildStep2(), // Origins
                _buildStep3(), // Interests
                _buildStep4(), // Languages
                _buildStep5(), // Bio & Goal
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: AppTheme.textWhite.withValues(alpha: 0.1)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: AppTheme.textWhite)
                : Text(
                    _currentPage == _totalPages - 1 ? 'LFG! 🔥' : 'Continue 🚀',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: FadeInDown(
              child: Image.asset(
                'assets/images/qiviz.png',
                width: 80,
                height: 80,
              ),
            ),
          ),
          const SizedBox(height: 32),
          FadeInDown(child: Text('Who are you? 🎉', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.neonPink))),
          const SizedBox(height: 12),
          FadeInUp(delay: const Duration(milliseconds: 200), child: Text('Pick a unique username so people can find you.', style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textGrey))),
          const SizedBox(height: 40),
          FadeInUp(delay: const Duration(milliseconds: 400), child: _buildTextField(_nameController, 'Full Name', Icons.person)),
          const SizedBox(height: 20),
          FadeInUp(delay: const Duration(milliseconds: 600), child: _buildTextField(_usernameController, 'Username', Icons.alternate_email)),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInRight(child: Text('Your Journey 🌍', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.electricBlue))),
          const SizedBox(height: 12),
          FadeInUp(delay: const Duration(milliseconds: 200), child: Text('Tell us where you are based in India.', style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textGrey))),
          const SizedBox(height: 40),
          FadeInUp(delay: const Duration(milliseconds: 400), child: _buildTextField(_countryController, 'Home Country', Icons.flag)),
          const SizedBox(height: 20),
          FadeInUp(delay: const Duration(milliseconds: 600), child: _buildTextField(_universityController, 'University', Icons.school)),
          const SizedBox(height: 20),
          FadeInUp(delay: const Duration(milliseconds: 800), child: _buildTextField(_cityController, 'City', Icons.location_city)),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return _buildChipsStep(
      title: 'Interests ⚡',
      subtitle: 'Select what you love to do.',
      items: _availableInterests,
      selectedItems: _selectedInterests,
      activeColor: AppTheme.neonPink,
    );
  }

  Widget _buildStep4() {
    return _buildChipsStep(
      title: 'Languages 🗣️',
      subtitle: 'What languages do you speak?',
      items: _availableLanguages,
      selectedItems: _selectedLanguages,
      activeColor: AppTheme.electricBlue,
    );
  }

  Widget _buildChipsStep({required String title, required String subtitle, required List<String> items, required Set<String> selectedItems, required Color activeColor}) {
    return ListView(
      padding: const EdgeInsets.all(32.0),
      children: [
        FadeInRight(child: Text(title, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: activeColor))),
        const SizedBox(height: 12),
        FadeInUp(delay: const Duration(milliseconds: 200), child: Text(subtitle, style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textGrey))),
        const SizedBox(height: 32),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: items.map((item) {
            final isSelected = selectedItems.contains(item);
            return GestureDetector(
              onTap: () => setState(() => isSelected ? selectedItems.remove(item) : selectedItems.add(item)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : AppTheme.surfaceDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? activeColor : AppTheme.textGrey.withValues(alpha: 0.3)),
                ),
                child: Text(item, style: TextStyle(color: isSelected ? AppTheme.textWhite : AppTheme.textGrey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep5() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInRight(child: Text('Final Touch 🎯', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.electricBlue))),
          const SizedBox(height: 40),
          FadeInUp(delay: const Duration(milliseconds: 400), child: _buildTextField(_bioController, 'A short bio...', Icons.edit, maxLines: 3)),
          const SizedBox(height: 32),
          FadeInUp(delay: const Duration(milliseconds: 600), child: Text('Primary Goal', style: GoogleFonts.outfit(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.w600))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedGoal,
            dropdownColor: AppTheme.darkBackground,
            decoration: InputDecoration(filled: true, fillColor: AppTheme.surfaceDark, prefixIcon: const Icon(Icons.track_changes, color: AppTheme.electricBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
            items: _goals.map((goal) => DropdownMenuItem(value: goal, child: Text(goal, style: const TextStyle(color: AppTheme.textWhite)))).toList(),
            onChanged: (val) { if (val != null) setState(() => _selectedGoal = val); },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textWhite.withValues(alpha: 0.05)),
      ),
      child: TextFormField(
        controller: controller, maxLines: maxLines,
        style: const TextStyle(color: AppTheme.textWhite),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: AppTheme.textGrey.withValues(alpha: 0.5)),
          prefixIcon: Icon(icon, color: AppTheme.electricBlue),
          border: InputBorder.none, contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
