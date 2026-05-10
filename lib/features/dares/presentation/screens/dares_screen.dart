import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class DaresScreen extends StatefulWidget {
  const DaresScreen({super.key});

  @override
  State<DaresScreen> createState() => _DaresScreenState();
}

class _DaresScreenState extends State<DaresScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _dares = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDares();
  }

  Future<void> _fetchDares() async {
    try {
      final response = await _supabase
          .from('dares')
          .select('*, profiles(name, country)')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _dares = response as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Viral Dares',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.neonPink,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.electricBlue))
          : _dares.isEmpty
              ? Center(
                  child: Text(
                    'No active dares.\nBe the first to create one!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: AppTheme.textGrey, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _dares.length,
                  itemBuilder: (context, index) {
                    final dare = _dares[index];
                    final creator = dare['profiles'] ?? {};
                    return Card(
                      color: AppTheme.surfaceDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_fire_department, color: AppTheme.neonPink),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dare['title'] ?? 'Challenge',
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textWhite,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'By ${creator['name'] ?? 'Unknown'} (${creator['country'] ?? 'Global'})',
                              style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              dare['description'] ?? '',
                              style: const TextStyle(color: AppTheme.textWhite),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Entry: ₹${dare['entry_fee_inr'] ?? 0}',
                                  style: const TextStyle(
                                    color: AppTheme.electricBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Joining dare...')),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.neonPink,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Join Dare'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement create dare flow
        },
        backgroundColor: AppTheme.neonPink,
        child: const Icon(Icons.add, color: AppTheme.textWhite),
      ),
    );
  }
}
