import 'package:flutter/material.dart';
import '../../services/dashboard_analytics_service.dart';
import '../../widgets/base_screen.dart';
import '../../widgets/media_preview_widget.dart';
import '../user_profile_management.dart';
import 'package:intl/intl.dart';

class UserRegistrationAnalyticsScreen extends StatefulWidget {
  final String initialPeriod;

  const UserRegistrationAnalyticsScreen({
    super.key,
    this.initialPeriod = 'daily',
  });

  @override
  State<UserRegistrationAnalyticsScreen> createState() =>
      _UserRegistrationAnalyticsScreenState();
}

class _UserRegistrationAnalyticsScreenState
    extends State<UserRegistrationAnalyticsScreen> {
  late String _selectedPeriod;
  DateTimeRange? _customDateRange;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'online', 'verified'

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await DashboardAnalyticsService.getRegisteredUsersAnalytics(
      period: _selectedPeriod,
      customRange: _customDateRange,
    );
    if (!mounted) return;
    setState(() {
      _users = data;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredUsers {
    return _users.where((u) {
      final name = (u['fullname'] ?? '').toString().toLowerCase();
      final id = (u['searchId'] ?? '').toString().toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          id.contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_statusFilter == 'online') {
        return u['isOnline'] == true;
      } else if (_statusFilter == 'verified') {
        return u['isVerified'] == true;
      }
      return true;
    }).toList();
  }

  int get _onlineCount => _users.where((u) => u['isOnline'] == true).length;
  int get _verifiedCount => _users.where((u) => u['isVerified'] == true).length;

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'User Registration Analytics',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh',
          onPressed: _loadData,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            _buildHeaderBanner(),
            const SizedBox(height: 20),

            // Period Selector
            _buildPeriodSelector(),
            const SizedBox(height: 20),

            // KPI Summary Row
            _buildKpiSummaryRow(),
            const SizedBox(height: 24),

            // Registered Users List / Table
            _buildUsersTableSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Registration Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Track user growth, registration rates, verification and onboarding metrics across Daily, Weekly, and Monthly cycles.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'id': 'daily', 'label': 'Today', 'icon': Icons.today},
      {'id': 'weekly', 'label': 'This Week', 'icon': Icons.date_range},
      {'id': 'monthly', 'label': 'This Month', 'icon': Icons.calendar_month},
      {'id': 'all', 'label': 'All Time', 'icon': Icons.all_inclusive},
      {'id': 'custom', 'label': 'Custom Range', 'icon': Icons.tune},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: periods.map((p) {
            final isSelected = _selectedPeriod == p['id'];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                showCheckmark: false,
                avatar: Icon(
                  p['icon'] as IconData,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.grey[400],
                ),
                label: Text(
                  p['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[300],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF2563EB),
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF334155),
                  ),
                ),
                onSelected: (selected) async {
                  if (p['id'] == 'custom') {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                      initialDateRange: _customDateRange ??
                          DateTimeRange(
                            start: DateTime.now().subtract(const Duration(days: 7)),
                            end: DateTime.now(),
                          ),
                    );
                    if (range != null) {
                      setState(() {
                        _selectedPeriod = 'custom';
                        _customDateRange = range;
                      });
                      _loadData();
                    }
                  } else {
                    setState(() {
                      _selectedPeriod = p['id'] as String;
                    });
                    _loadData();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildKpiSummaryRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final cardWidth = isDesktop
            ? (constraints.maxWidth - 32) / 3
            : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'Total Registrations',
                value: _users.length.toString(),
                subtitle: 'In Selected Period',
                icon: Icons.group_add,
                color: const Color(0xFF3B82F6),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'Active / Online',
                value: _onlineCount.toString(),
                subtitle: 'Currently Connected',
                icon: Icons.circle,
                color: const Color(0xFF10B981),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'Verified Profiles',
                value: _verifiedCount.toString(),
                subtitle: 'Official Badge Holders',
                icon: Icons.verified,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isLoading ? '...' : value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTableSection() {
    final filtered = _filteredUsers;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by username or ID...',
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
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        dropdownColor: const Color(0xFF0F172A),
                        icon: const Icon(Icons.filter_list, color: Colors.white70, size: 20),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Users')),
                          DropdownMenuItem(value: 'online', child: Text('Online Only')),
                          DropdownMenuItem(value: 'verified', child: Text('Verified Only')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _statusFilter = val);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF334155), height: 1),

          // Table
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No registered users found in this period',
                  style: TextStyle(color: Colors.grey[400], fontSize: 15),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
                columns: const [
                  DataColumn(label: Text('User Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Search ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Registered At', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Diamonds', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Device', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
                rows: filtered.map((u) {
                  final createdAt = u['createdAt'] as DateTime;
                  final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt);
                  final isOnline = u['isOnline'] == true;
                  final isVerified = u['isVerified'] == true;

                  return DataRow(
                    cells: [
                      // Profile Info
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (u['image'] != null && u['image'].toString().isNotEmpty)
                              MediaPreviewWidget(
                                url: u['image'].toString(),
                                width: 34,
                                height: 34,
                                borderRadius: BorderRadius.circular(17),
                              )
                            else
                              CircleAvatar(
                                radius: 17,
                                backgroundColor: const Color(0xFF3B82F6),
                                child: Text(
                                  (u['fullname'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            const SizedBox(width: 10),
                            Text(
                              u['fullname'] ?? 'IMChat User',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: Colors.blueAccent, size: 16),
                            ],
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          u['searchId'] ?? '',
                          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w500),
                        ),
                      ),
                      DataCell(
                        Text(
                          formattedDate,
                          style: TextStyle(color: Colors.grey[300], fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? Colors.green.withOpacity(0.15)
                                : Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: isOnline ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: isOnline ? Colors.greenAccent : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${u['diamonds']} 💎',
                          style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          u['device'] ?? 'Android',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
