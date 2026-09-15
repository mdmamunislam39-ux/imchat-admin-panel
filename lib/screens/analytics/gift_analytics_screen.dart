import 'package:flutter/material.dart';
import '../../services/dashboard_analytics_service.dart';
import '../../widgets/base_screen.dart';
import 'package:intl/intl.dart';

class GiftAnalyticsScreen extends StatefulWidget {
  final String initialPeriod;

  const GiftAnalyticsScreen({
    super.key,
    this.initialPeriod = 'daily',
  });

  @override
  State<GiftAnalyticsScreen> createState() => _GiftAnalyticsScreenState();
}

class _GiftAnalyticsScreenState extends State<GiftAnalyticsScreen> {
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
    final res = await DashboardAnalyticsService.getGiftAnalytics(
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
  int get _totalGiftsCount => (_data['totalGiftsCount'] ?? 0) as int;
  List<dynamic> get _popularGifts => (_data['popularGifts'] as List<dynamic>?) ?? [];
  List<dynamic> get _topSenders => (_data['topSenders'] as List<dynamic>?) ?? [];
  List<dynamic> get _topReceivers => (_data['topReceivers'] as List<dynamic>?) ?? [];
  List<dynamic> get _transactions => (_data['transactions'] as List<dynamic>?) ?? [];

  List<dynamic> get _filteredTransactions {
    return _transactions.where((t) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final sender = (t['senderName'] ?? '').toString().toLowerCase();
      final receiver = (t['receiverName'] ?? '').toString().toLowerCase();
      final gift = (t['giftName'] ?? '').toString().toLowerCase();
      return sender.contains(query) || receiver.contains(query) || gift.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Gift Sending & Economy Analytics',
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
            _buildKpiCards(),
            const SizedBox(height: 24),

            // Popular Gifts & Leaderboard
            if (_popularGifts.isNotEmpty || _topSenders.isNotEmpty) ...[
              _buildRankingsRow(),
              const SizedBox(height: 24),
            ],

            // Gift Transactions Table
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
          colors: [Color(0xFF581C87), Color(0xFF7E22CE), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
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
            child: const Icon(Icons.card_giftcard, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gift Economy Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Monitor real-time gift sends, top gifting users, popular virtual gifts, and host earnings distribution.',
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
                selectedColor: const Color(0xFF9333EA),
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFFA855F7) : const Color(0xFF334155),
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
            title: 'Total Gifts Sent',
            value: _totalGiftsCount.toString(),
            subtitle: 'Gift Events Triggered',
            icon: Icons.card_giftcard,
            color: const Color(0xFFA855F7),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            title: 'Gift Diamond Value',
            value: '${_totalDiamonds.toStringAsFixed(0)} 💎',
            subtitle: 'Total Gift Circulation',
            icon: Icons.diamond,
            color: const Color(0xFFEC4899),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            title: 'Top Gift Senders',
            value: '${_topSenders.length} Active',
            subtitle: 'Generous Givers',
            icon: Icons.favorite,
            color: const Color(0xFFEF4444),
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

  Widget _buildRankingsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Gifts
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Popular Gifts Sent',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._popularGifts.take(5).map((g) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('🎁 ${g['name']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${g['count']} times', style: const TextStyle(color: Colors.purpleAccent, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Top Senders
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Top Gift Senders',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._topSenders.take(5).map((s) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('👑 ${s['name']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        Text('${(s['amount'] as num).toInt()} 💎', style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
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
                  'Gift Transaction Logs',
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
                      hintText: 'Search sender, receiver, gift...',
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
                  'No gift transaction logs found for this period',
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
                  DataColumn(label: Text('Sender', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Receiver / Host', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Gift Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Diamond Value', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Date & Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
                rows: filtered.map((t) {
                  final date = t['createdAt'] as DateTime;
                  final formatted = DateFormat('MMM dd, yyyy • hh:mm a').format(date);

                  return DataRow(
                    cells: [
                      DataCell(Text(t['senderName'] ?? 'Sender', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                      DataCell(Text(t['receiverName'] ?? 'Host', style: const TextStyle(color: Colors.cyanAccent))),
                      DataCell(Text('🎁 ${t['giftName'] ?? 'Gift'}', style: const TextStyle(color: Colors.purpleAccent))),
                      DataCell(Text('${(t['diamondAmount'] as num).toInt()} 💎', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold))),
                      DataCell(Text(formatted, style: TextStyle(color: Colors.grey[300], fontSize: 12))),
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
