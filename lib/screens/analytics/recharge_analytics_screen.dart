import 'package:flutter/material.dart';
import '../../services/dashboard_analytics_service.dart';
import '../../widgets/base_screen.dart';
import 'package:intl/intl.dart';

class RechargeAnalyticsScreen extends StatefulWidget {
  final String initialPeriod;

  const RechargeAnalyticsScreen({
    super.key,
    this.initialPeriod = 'daily',
  });

  @override
  State<RechargeAnalyticsScreen> createState() =>
      _RechargeAnalyticsScreenState();
}

class _RechargeAnalyticsScreenState extends State<RechargeAnalyticsScreen> {
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
    final res = await DashboardAnalyticsService.getRechargeAnalytics(
      period: _selectedPeriod,
      customRange: _customDateRange,
    );
    if (!mounted) return;
    setState(() {
      _data = res;
      _isLoading = false;
    });
  }

  double get _totalDiamonds => (_data['totalDiamonds'] ?? 0.0).toDouble();
  int get _transactionCount => (_data['transactionCount'] ?? 0) as int;
  List<dynamic> get _topUsers => (_data['topUsers'] as List<dynamic>?) ?? [];
  List<dynamic> get _transactions => (_data['transactions'] as List<dynamic>?) ?? [];

  List<dynamic> get _filteredTransactions {
    return _transactions.where((t) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final userName = (t['userName'] ?? '').toString().toLowerCase();
      final sellerName = (t['sellerName'] ?? '').toString().toLowerCase();
      return userName.contains(query) || sellerName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Diamond Recharge Analytics',
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

            // Top Recharged Users Leaderboard
            if (_topUsers.isNotEmpty) ...[
              _buildTopUsersSection(),
              const SizedBox(height: 24),
            ],

            // Detailed Transactions Table
            _buildTransactionsSection(),
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
          colors: [Color(0xFF78350F), Color(0xFFD97706), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.2),
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
            child: const Icon(Icons.diamond_outlined, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diamond Recharge Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Analyze diamond purchases, seller recharges, buyer trends, and transaction velocity.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
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
                selectedColor: const Color(0xFFD97706),
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF334155),
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
    final avgRecharge = _transactionCount > 0
        ? (_totalDiamonds / _transactionCount).toStringAsFixed(1)
        : '0';

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: 'Total Diamonds Recharged',
            value: '${_totalDiamonds.toStringAsFixed(0)} 💎',
            subtitle: 'Recharge Volume',
            icon: Icons.monetization_on,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            title: 'Total Transactions',
            value: _transactionCount.toString(),
            subtitle: 'Successful Recharges',
            icon: Icons.receipt_long,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            title: 'Average Recharge',
            value: '$avgRecharge 💎',
            subtitle: 'Per Transaction',
            icon: Icons.query_stats,
            color: const Color(0xFF6366F1),
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
              fontSize: 24,
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

  Widget _buildTopUsersSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Recharging Users',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _topUsers.take(6).map((u) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      u['name'] ?? 'User',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(u['amount'] as num).toInt()} 💎',
                      style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
    final filtered = _filteredTransactions;

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
                const Text(
                  'Recharge Transactions',
                  style: TextStyle(
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
                      hintText: 'Search user or seller...',
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
                  'No recharge records found for this period',
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
                  DataColumn(label: Text('Recipient User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Seller / Source', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Diamonds', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Date & Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
                rows: filtered.map((t) {
                  final date = t['createdAt'] as DateTime;
                  final formatted = DateFormat('MMM dd, yyyy • hh:mm a').format(date);

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          t['userName'] ?? 'User',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        Text(
                          t['sellerName'] ?? 'Official Seller',
                          style: const TextStyle(color: Colors.cyanAccent),
                        ),
                      ),
                      DataCell(
                        Text(
                          '+${(t['amount'] as num).toInt()} 💎',
                          style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          formatted,
                          style: TextStyle(color: Colors.grey[300], fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
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
