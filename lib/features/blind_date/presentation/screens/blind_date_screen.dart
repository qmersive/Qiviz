import 'package:flutter/material.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class BlindDateScreen extends StatefulWidget {
  const BlindDateScreen({super.key});

  @override
  State<BlindDateScreen> createState() => _BlindDateScreenState();
}

class _BlindDateScreenState extends State<BlindDateScreen> {
  bool _isSearching = false;

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
    });

    if (_isSearching) {
      // Simulate finding a match after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isSearching) {
          setState(() {
            _isSearching = false;
          });
          _showMatchDialog();
        }
      });
    }
  }

  void _showMatchDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('It\'s a Match!', style: GoogleFonts.outfit(color: AppTheme.neonPink, fontWeight: FontWeight.bold, fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryPurple,
              child: Icon(Icons.person, size: 40, color: AppTheme.textWhite),
            ),
            const SizedBox(height: 16),
            const Text('You have matched with someone from Nigeria!', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textWhite, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Suggested Activity: Coffee Campus Walk', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.electricBlue)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Pass', style: TextStyle(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat started! (Coming soon)')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPink),
            child: const Text('Say Hi!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blind Date', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 100,
                color: _isSearching ? AppTheme.neonPink : AppTheme.textGrey,
              ),
              const SizedBox(height: 48),
              Text(
                'Join the Blind Date Pool',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We will find you a compatible match from a different culture for a quick campus coffee walk. No photos, just vibes!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textGrey, fontSize: 16),
              ),
              const SizedBox(height: 64),
              SizedBox(
                width: 200,
                height: 60,
                child: ElevatedButton(
                  onPressed: _toggleSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSearching ? AppTheme.surfaceDark : AppTheme.neonPink,
                    side: _isSearching ? const BorderSide(color: AppTheme.neonPink, width: 2) : BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isSearching
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: AppTheme.neonPink, strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Searching...', style: TextStyle(color: AppTheme.neonPink, fontSize: 18)),
                          ],
                        )
                      : const Text('Join Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
