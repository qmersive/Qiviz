import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _supabase = Supabase.instance.client;
  int _totalUsers = 0;
  int _activeDares = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final usersResponse = await _supabase.from('profiles').select('id').count(CountOption.exact);
      final daresResponse = await _supabase.from('dares').select('id').eq('is_active', true).count(CountOption.exact);
      
      setState(() {
        _totalUsers = usersResponse.count;
        _activeDares = daresResponse.count;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching admin stats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Admin Panel', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.electricBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCard('Total Students', _totalUsers.toString(), Icons.people, AppTheme.primaryPurple),
                  const SizedBox(height: 16),
                  _buildStatCard('Active Dares', _activeDares.toString(), Icons.local_fire_department, AppTheme.neonPink),
                  const SizedBox(height: 32),
                  Text('Quick Actions', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                  const SizedBox(height: 16),
                  _buildActionTile('Approve Dare Videos', Icons.check_circle_outline),
                  _buildActionTile('Manage Events', Icons.event),
                  _buildActionTile('User Reports', Icons.report_problem_outlined),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
              Text(value, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon) {
    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.electricBlue),
        title: Text(title, style: const TextStyle(color: AppTheme.textWhite)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textGrey),
        onTap: () {},
      ),
    );
  }
}
