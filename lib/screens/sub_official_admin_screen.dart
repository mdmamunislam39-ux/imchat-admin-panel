import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/sub_official_admin_model.dart';
import '../services/admin_auth_service.dart';
import '../services/sub_official_admin_service.dart';
import '../widgets/base_screen.dart';

class SubOfficialAdminScreen extends StatefulWidget {
  const SubOfficialAdminScreen({super.key});

  @override
  State<SubOfficialAdminScreen> createState() => _SubOfficialAdminScreenState();
}

class _SubOfficialAdminScreenState extends State<SubOfficialAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'active', 'inactive'

  // Default portal link for Sub Official Admin
  static const String defaultPortalUrl = 'https://official.imchatapp.com';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _generateRandomPassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#%*';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final isMain = AdminAuthService.isMainAdmin();

    if (!isMain) {
      return BaseScreen(
        title: 'Sub Official Admin',
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gavel_rounded, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  'Access Denied (Main Super Admin Only)',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Only the Main Super Admin has authorization to create sub-admin accounts and assign module permissions.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BaseScreen(
      title: 'Sub Official Admin',
      body: StreamBuilder<List<SubOfficialAdminModel>>(
        stream: SubOfficialAdminService.getSubAdminsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load sub-admin data: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          }

          final allAdmins = snapshot.data ?? [];

          // Filter by search and status
          final filteredAdmins = allAdmins.where((admin) {
            final matchesQuery = admin.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                admin.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                admin.phone.contains(_searchQuery);

            if (!matchesQuery) return false;

            if (_filterStatus == 'active') return admin.isActive;
            if (_filterStatus == 'inactive') return !admin.isActive;
            return true;
          }).toList();

          final totalAdmins = allAdmins.length;
          final activeAdmins = allAdmins.where((a) => a.isActive).length;
          final inactiveAdmins = totalAdmins - activeAdmins;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Banner: Dedicated Domain / Portal Link Card
                _buildPortalLinkCard(),

                const SizedBox(height: 20),

                // Stats Row
                _buildStatsRow(totalAdmins, activeAdmins, inactiveAdmins),

                const SizedBox(height: 24),

                // Search & Filter & Add Button Bar
                _buildControlsBar(),

                const SizedBox(height: 16),

                // Admins List
                if (filteredAdmins.isEmpty)
                  _buildEmptyState()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredAdmins.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      return _buildAdminCard(filteredAdmins[index]);
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(null),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text(
          'Add Sub Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Dedicated Link / Subdomain Portal Card
  Widget _buildPortalLinkCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.language, color: Colors.blueAccent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌐 Sub Official Admin Login Portal Domain & URL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Like the public landing website, Sub-Admins will use this dedicated link to log in with their email and password.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, color: Colors.cyanAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectableText(
                    defaultPortalUrl,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(
                    defaultPortalUrl,
                    'Admin portal URL copied to clipboard!',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy URL'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Stats Row
  Widget _buildStatsRow(int total, int active, int inactive) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        return GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? 2.0 : 2.4,
          children: [
            _buildStatCard('Total Sub Admins', '$total', Icons.people_alt, Colors.blueAccent),
            _buildStatCard('Active Admins', '$active', Icons.verified_user, Colors.greenAccent),
            _buildStatCard('Deactivated', '$inactive', Icons.person_off, Colors.orangeAccent),
            _buildStatCard('Access Modes', 'Editor / View', Icons.security, Colors.purpleAccent),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Controls: Search, Filter, Add Button
  Widget _buildControlsBar() {
    return Row(
      children: [
        // Search Input
        Expanded(
          flex: 2,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by email, name or phone...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Filter status dropdown
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filterStatus,
              dropdownColor: Colors.grey[900],
              icon: const Icon(Icons.filter_list, color: Colors.grey, size: 20),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Status')),
                DropdownMenuItem(value: 'active', child: Text('✅ Active Only')),
                DropdownMenuItem(value: 'inactive', child: Text('❌ Inactive Only')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _filterStatus = val);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Add Button
        ElevatedButton.icon(
          onPressed: () => _showAddEditDialog(null),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Sub Admin', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // Admin Card Item
  Widget _buildAdminCard(SubOfficialAdminModel admin) {
    final totalAssigned = admin.totalAssignedModules;
    final totalEdit = admin.totalEditModules;
    final totalView = admin.totalViewModules;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: admin.isActive ? Colors.grey[800]! : Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: admin.isActive ? Colors.blueAccent : Colors.grey[700],
                child: Text(
                  admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'A',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: admin.isActive ? Colors.greenAccent : Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                ),
              ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        admin.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: admin.isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: admin.isActive ? Colors.greenAccent : Colors.redAccent,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        admin.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: admin.isActive ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.email_outlined, color: Colors.grey, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    admin.email,
                    style: TextStyle(color: Colors.grey[300], fontSize: 13, fontFamily: 'monospace'),
                  ),
                  if (admin.phone.isNotEmpty) ...[
                    const SizedBox(width: 14),
                    const Icon(Icons.phone_outlined, color: Colors.grey, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      admin.phone,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // Permission summary badges
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Modules: $totalAssigned',
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (totalEdit > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '✏️ Editor: $totalEdit',
                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (totalView > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '👁️ View Only: $totalView',
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                border: Border(top: BorderSide(color: Colors.grey[800]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Credentials & Quick Copy Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('🔑 Login Credentials',
                                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Text('Password: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text(
                                    admin.password,
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          final detailsText = '''
🌐 IMChat Sub-Admin Login Credentials:
Portal URL: $defaultPortalUrl
Login Email: ${admin.email}
Password: ${admin.password}
Role: Sub Official Admin
Assigned Modules: $totalAssigned
''';
                          _copyToClipboard(detailsText, 'Login credentials copied to clipboard!');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.copy_all, size: 16),
                        label: const Text('Copy Credentials'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      // Active/Inactive Toggle Button
                      OutlinedButton.icon(
                        onPressed: () => _toggleStatus(admin),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: admin.isActive ? Colors.orangeAccent : Colors.greenAccent,
                          side: BorderSide(
                            color: admin.isActive ? Colors.orangeAccent : Colors.greenAccent,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(admin.isActive ? Icons.block : Icons.check_circle_outline, size: 16),
                        label: Text(admin.isActive ? 'Deactivate' : 'Activate'),
                      ),
                      const SizedBox(width: 10),

                      // Edit Button
                      ElevatedButton.icon(
                        onPressed: () => _showAddEditDialog(admin),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Permissions'),
                      ),
                      const Spacer(),

                      // Delete Button
                      IconButton(
                        onPressed: () => _confirmDelete(admin),
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'Delete Account',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 8),

                  // Assigned Modules Breakdown Grid
                  const Text(
                    'Assigned Module Permissions:',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildAssignedModulesBadges(admin.permissions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedModulesBadges(Map<String, String> permissions) {
    final activeEntries = permissions.entries.where((e) => e.value == 'edit' || e.value == 'view').toList();

    if (activeEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No module permissions assigned.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: activeEntries.map((e) {
        final isEdit = e.value == 'edit';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isEdit ? Colors.orange.withValues(alpha: 0.12) : Colors.cyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isEdit ? Colors.orangeAccent.withValues(alpha: 0.6) : Colors.cyanAccent.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isEdit ? Icons.edit_note : Icons.visibility_outlined,
                size: 14,
                color: isEdit ? Colors.orangeAccent : Colors.cyanAccent,
              ),
              const SizedBox(width: 6),
              Text(
                e.key,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(width: 6),
              Text(
                isEdit ? '(Editor)' : '(View)',
                style: TextStyle(
                  color: isEdit ? Colors.orangeAccent : Colors.cyanAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.manage_accounts_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Sub Official Admins Found',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "+ Add Sub Admin" button to create a new sub admin account.',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // Toggle active/inactive status
  Future<void> _toggleStatus(SubOfficialAdminModel admin) async {
    try {
      await SubOfficialAdminService.toggleSubAdminStatus(
        admin.id,
        admin.email,
        admin.name,
        admin.isActive,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            admin.isActive
                ? '${admin.name} account has been deactivated.'
                : '${admin.name} account is now active.',
          ),
          backgroundColor: admin.isActive ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Confirm delete dialog
  void _confirmDelete(SubOfficialAdminModel admin) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Sub Admin Account', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to permanently delete "${admin.name}" (${admin.email}) from Sub Official Admins?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await SubOfficialAdminService.deleteSubAdmin(admin.id, admin.email, admin.name);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sub Admin account deleted successfully.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Add / Edit Sub Admin Modal Dialog with Matrix
  void _showAddEditDialog(SubOfficialAdminModel? existingAdmin) {
    final isEditing = existingAdmin != null;

    final nameController = TextEditingController(text: existingAdmin?.name ?? '');
    final emailController = TextEditingController(text: existingAdmin?.email ?? '');
    final passwordController = TextEditingController(
      text: existingAdmin?.password ?? _generateRandomPassword(),
    );
    final phoneController = TextEditingController(text: existingAdmin?.phone ?? '');
    bool isActive = existingAdmin?.isActive ?? true;
    bool obscurePassword = false;

    // Working permissions map: module -> 'none' | 'view' | 'edit'
    Map<String, String> workingPerms = {};
    for (var module in SubOfficialAdminService.getAllModules()) {
      workingPerms[module] = existingAdmin?.getPermissionLevel(module) ?? 'none';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF18181B),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_note : Icons.person_add,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Sub Admin & Permissions' : 'Create New Sub Official Admin',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 750,
                height: 600,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Credentials
                      const Text(
                        '👤 Account & Login Credentials',
                        style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                labelStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.badge_outlined, color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey[900],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Phone Number (Optional)',
                                labelStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey[900],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Login Email',
                                labelStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey[900],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey[900],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setDialogState(() => obscurePassword = !obscurePassword);
                                      },
                                      tooltip: 'Toggle visibility',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.autorenew, color: Colors.cyanAccent, size: 20),
                                      onPressed: () {
                                        setDialogState(() {
                                          passwordController.text = _generateRandomPassword();
                                        });
                                      },
                                      tooltip: 'Generate Random Password',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (isEditing) ...[
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Account Status (Active)', style: TextStyle(color: Colors.white)),
                          subtitle: Text(
                            isActive ? 'Admin can currently log in to panel' : 'Login access is suspended',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                          value: isActive,
                          activeThumbColor: Colors.greenAccent,
                          onChanged: (val) => setDialogState(() => isActive = val),
                        ),
                      ],

                      const SizedBox(height: 20),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 12),

                      // Section 2: Permission Matrix
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🛡️ Module Access Permissions Matrix',
                                style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Select No Access, View Only, or Editor mode for each module',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                          // Quick Preset Buttons
                          Wrap(
                            spacing: 6,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  setDialogState(() {
                                    for (var m in SubOfficialAdminService.getAllModules()) {
                                      workingPerms[m] = 'edit';
                                    }
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  side: const BorderSide(color: Colors.orangeAccent),
                                ),
                                icon: const Icon(Icons.select_all, size: 14, color: Colors.orangeAccent),
                                label: const Text('Set All Edit', style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setDialogState(() {
                                    for (var m in SubOfficialAdminService.getAllModules()) {
                                      workingPerms[m] = 'view';
                                    }
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  side: const BorderSide(color: Colors.cyanAccent),
                                ),
                                icon: const Icon(Icons.visibility, size: 14, color: Colors.cyanAccent),
                                label: const Text('Set All View', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setDialogState(() {
                                    for (var m in SubOfficialAdminService.getAllModules()) {
                                      workingPerms[m] = 'none';
                                    }
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  side: const BorderSide(color: Colors.grey),
                                ),
                                icon: const Icon(Icons.clear, size: 14, color: Colors.grey),
                                label: const Text('Clear All', style: TextStyle(color: Colors.grey, fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Category Accordions
                      ...SubOfficialAdminService.moduleCategories.map((categoryMap) {
                        final catName = categoryMap['category'] as String;
                        final modules = List<String>.from(categoryMap['modules'] ?? []);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            title: Row(
                              children: [
                                Text(
                                  catName,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                // Category quick toggle
                                TextButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      for (var m in modules) {
                                        workingPerms[m] = 'edit';
                                      }
                                    });
                                  },
                                  child: const Text('All Edit', style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      for (var m in modules) {
                                        workingPerms[m] = 'view';
                                      }
                                    });
                                  },
                                  child: const Text('All View', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                                ),
                              ],
                            ),
                            children: modules.map((module) {
                              final currentLevel = workingPerms[module] ?? 'none';
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(top: BorderSide(color: Colors.grey[850]!)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        module,
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                      ),
                                    ),
                                    // 3-state selector: None, View, Edit
                                    _buildPermissionLevelSelector(
                                      currentLevel: currentLevel,
                                      onChanged: (newLevel) {
                                        setDialogState(() {
                                          workingPerms[module] = newLevel;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim().toLowerCase();
                    final password = passwordController.text.trim();
                    final phone = phoneController.text.trim();

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Email and Password are required!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      if (isEditing) {
                        await SubOfficialAdminService.updateSubAdmin(
                          id: existingAdmin.id,
                          name: name,
                          email: email,
                          password: password,
                          phone: phone,
                          isActive: isActive,
                          permissions: workingPerms,
                        );
                      } else {
                        await SubOfficialAdminService.createSubAdmin(
                          name: name,
                          email: email,
                          password: password,
                          phone: phone,
                          permissions: workingPerms,
                        );
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? 'Sub Admin details & permissions updated successfully!'
                                  : 'New Sub Admin created successfully!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    isEditing ? 'Update' : 'Save',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 3-way permission selector button group
  Widget _buildPermissionLevelSelector({
    required String currentLevel,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Option 1: None
          _buildLevelOption(
            title: '❌ No Access',
            isSelected: currentLevel == 'none',
            selectedColor: Colors.grey[700]!,
            onTap: () => onChanged('none'),
          ),
          // Option 2: View Only
          _buildLevelOption(
            title: '👁️ View Only',
            isSelected: currentLevel == 'view',
            selectedColor: Colors.cyanAccent.withValues(alpha: 0.3),
            textColor: currentLevel == 'view' ? Colors.cyanAccent : Colors.grey[400]!,
            onTap: () => onChanged('view'),
          ),
          // Option 3: Editor
          _buildLevelOption(
            title: '✏️ Editor',
            isSelected: currentLevel == 'edit',
            selectedColor: Colors.orangeAccent.withValues(alpha: 0.3),
            textColor: currentLevel == 'edit' ? Colors.orangeAccent : Colors.grey[400]!,
            onTap: () => onChanged('edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelOption({
    required String title,
    required bool isSelected,
    required Color selectedColor,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? (textColor == Colors.white ? Colors.white : textColor) : Colors.grey[500],
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
