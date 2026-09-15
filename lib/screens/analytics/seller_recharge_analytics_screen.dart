import 'package:flutter/material.dart';
import '../../services/dashboard_analytics_service.dart';
import '../../widgets/base_screen.dart';
import '../seller_history_screen.dart';

class SellerRechargeAnalyticsScreen extends StatefulWidget {
  final String initialPeriod;

  const SellerRechargeAnalyticsScreen({
    super.key,
    this.initialPeriod = 'daily',
  });

  @override
  State<SellerRechargeAnalyticsScreen> createState() =>
      _SellerRechargeAnalyticsScreenState();
}

class _SellerRechargeAnalyticsScreenState
    extends State<SellerRechargeAnalyticsScreen> {
  late String _selectedPeriod;
  DateTimeRange? _customDateRange;
  bool _isLoading = true;
  Map<String, dynamic> _data = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    final res = await DashboardAnalyticsService.getSellerRechargeAnalytics(
      period: _selectedPeriod,
      customRange: _customDateRange,
    );
    if (!mounted) return;
    setState(() {
      _data = res;
      _isLoading = false;
    });
  }

  double get _totalVolume => (_data['totalVolume'] ?? 0.0).toDouble();
  List<dynamic> get _sellers => (_data['sellers'] as List<dynamic>?) ?? [];
  List<dynamic> get _transactions => (_data['transactions'] as List<dynamic>?) ?? [];

  List<dynamic> get _filteredSellers {
    return _sellers.where((s) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final name = (s['name'] ?? '').toString().toLowerCase();
      final pid = (s['profileId'] ?? '').toString().toLowerCase();
      return name.contains(query) || pid.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Seller Recharge Analytics',
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

            // KPI Cards
            _buildKpiCards(),
            const SizedBox(height: 24),

            // Sellers Performance Table
            _buildSellersTableSection(),
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
          colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.2),
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
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seller Recharge Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Track seller coin distributions, quota balance, top performing vendors, and recharge volume.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
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
                selectedColor: const Color(0xFF059669),
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF10B981) : const Color(0xFF334155),
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

  Widget _buildKpiCards() {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: 'Seller Volume',
            value: '${_totalVolume.toStringAsFixed(0)} 💎',
            subtitle: 'Coins Distributed',
            icon: Icons.currency_exchange,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            title: 'Active Sellers',
            value: _sellers.where((s) => s['isActive'] == true).length.toString(),
            subtitle: 'Registered Vendors',
            icon: Icons.store,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            title: 'Transactions Logged',
            value: _transactions.length.toString(),
            subtitle: 'Recharge Operations',
            icon: Icons.history,
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
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
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
                  color: color.withValues(alpha: 0.15),
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSellersTableSection() {
    final filtered = _filteredSellers;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seller Sales & Distribution (${filtered.length} Sellers)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search seller by name or ID...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF334155), height: 1),

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
                  'No sellers found matching criteria',
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
                  DataColumn(label: Text('Seller Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Seller ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Total Sales Volume', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Account Balance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Users Recharged', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
                rows: filtered.map((s) {
                  final isActive = s['isActive'] == true;

                  return DataRow(
                    cells: [
                      DataCell(Text(s['name'] ?? 'Seller', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                      DataCell(Text(s['profileId'] ?? '', style: const TextStyle(color: Colors.cyanAccent))),
                      DataCell(Text('${(s['totalSales'] as num).toInt()} 💎', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold))),
                      DataCell(Text('${(s['balance'] as num).toInt()} 💎', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold))),
                      DataCell(Text('${s['usersRecharged']} users', style: const TextStyle(color: Colors.white70))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(color: isActive ? Colors.greenAccent : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.receipt_long, color: Colors.white70, size: 20),
                          tooltip: 'Seller History',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SellerHistoryScreen(
                                  sellerId: s['id'] ?? '',
                                ),
                              ),
                            );
                          },
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
