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
  final int _totalPages = 4;

  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _countryController = TextEditingController();
  final _universityController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  
  // Vibe Check (Step 3) Collections
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
    _nicknameController.dispose();
    _countryController.dispose();
    _universityController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Validate current page before moving to next
    if (_currentPage == 0) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your full name!')));
        return;
      }
    } else if (_currentPage == 1) {
      if (_countryController.text.trim().isEmpty || _universityController.text.trim().isEmpty || _cityController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out your origin details!')));
        return;
      }
    } else if (_currentPage == 2) {
      if (_selectedInterests.isEmpty || _selectedLanguages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one interest and language!')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write a short bio!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'name': _nameController.text.trim(),
        'nickname': _nicknameController.text.trim(),
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
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Prevent manual swiping
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricBlue.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
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
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: AppTheme.textWhite)
                : Text(
                    _currentPage == _totalPages - 1 ? 'Start Exploring 🔥' : 'Continue 🚀',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textWhite,
                    ),
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
          FadeInDown(
            child: Text(
              'Welcome to Qiviz! 🎉',
              style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.neonPink),
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Let\'s get your identity set up so you can start connecting.',
              style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textGrey),
            ),
          ),
          const SizedBox(height: 40),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: _buildTextField(_nameController, 'Your Full Name', Icons.person),
          ),
          const SizedBox(height: 20),
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: _buildTextField(_nicknameController, 'A Cool Nickname (Optional)', Icons.alternate_email),
          ),
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
          FadeInRight(
            child: Text(
              'Your Origins 🌍',
              style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.electricBlue),
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Where are you from, and where are you studying?',
              style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textGrey),
            ),
          ),
          const SizedBox(height: 40),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: _buildTextField(_countryController, 'Home Country', Icons.flag),
          ),
          const SizedBox(height: 20),
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: _buildTextField(_universityController, 'University in India', Icons.school),
          ),
          const SizedBox(height: 20),
          FadeInUp(
            delay: const Duration(milliseconds: 800),
            child: _buildTextField(_cityController, 'Current City in India', Icons.location_city),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return ListView(
      padding: const EdgeInsets.all(32.0),
      children: [
        FadeInRight(
          child: Text(
            'Vibe Check ⚡',
            style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.neonPink),
          ),
        ),
        const SizedBox(height: 16),
        FadeInUp(
          delay: const Duration(milliseconds: 200),
          child: Text(
            'What are you into? Select your interests to find your tribe.',
            style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textGrey),
          ),
        ),
        const SizedBox(height: 32),
        FadeInUp(
          delay: const Duration(milliseconds: 400),
          child: Text('Interests', style: GoogleFonts.outfit(fontSize: 20, color: AppTheme.textWhite, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        FadeInUp(
          delay: const Duration(milliseconds: 600),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _availableInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else {
                      _selectedInterests.add(interest);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.neonPink : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.neonPink : AppTheme.textGrey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(
                      color: isSelected ? AppTheme.textWhite : AppTheme.textGrey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),
        FadeInUp(
          delay: const Duration(milliseconds: 800),
          child: Text('Languages I Speak', style: GoogleFonts.outfit(fontSize: 20, color: AppTheme.textWhite, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        FadeInUp(
          delay: const Duration(milliseconds: 1000),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _availableLanguages.map((lang) {
              final isSelected = _selectedLanguages.contains(lang);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedLanguages.remove(lang);
                    } else {
                      _selectedLanguages.add(lang);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.electricBlue : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.electricBlue : AppTheme.textGrey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    lang,
                    style: TextStyle(
                      color: isSelected ? AppTheme.textWhite : AppTheme.textGrey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep4() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInRight(
            child: Text(
              'Final Touch 🎯',
              style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.electricBlue),
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Tell people a little bit about yourself and what you are looking for on Qiviz.',
              style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textGrey),
            ),
          ),
          const SizedBox(height: 40),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: _buildTextField(_bioController, 'A short, catchy bio about you...', Icons.edit, maxLines: 4),
          ),
          const SizedBox(height: 32),
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: Text('My Primary Goal', style: GoogleFonts.outfit(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          FadeInUp(
            delay: const Duration(milliseconds: 800),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedGoal,
              dropdownColor: AppTheme.darkBackground,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceDark,
                prefixIcon: const Icon(Icons.track_changes, color: AppTheme.electricBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
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
          ),
        ],
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
        hintStyle: TextStyle(color: AppTheme.textGrey.withValues(alpha: 0.5)),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 70 : 0),
          child: Icon(icon, color: AppTheme.electricBlue),
        ),
        filled: true,
        fillColor: AppTheme.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.electricBlue, width: 2),
        ),
      ),
    );
  }
}
