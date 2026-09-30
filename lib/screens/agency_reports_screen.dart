import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/host_model.dart';
import '../models/agency_model.dart';
import '../services/agency_service.dart';

class AgencyReportsScreen extends StatefulWidget {
  final String agencyId;
  
  const AgencyReportsScreen({
    super.key,
    required this.agencyId,
  });

  @override
  State<AgencyReportsScreen> createState() => _AgencyReportsScreenState();
}

class _AgencyReportsScreenState extends State<AgencyReportsScreen> {
  AgencyModel? _agency;
  List<HostModel> _hosts = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  String _selectedTimeRange = '7d';

  StreamSubscription<DocumentSnapshot>? _agencySub;
  StreamSubscription<List<HostModel>>? _hostsSub;

  @override
  void initState() {
    super.initState();
    _startRealtimeListeners();
  }

  @override
  void dispose() {
    _agencySub?.cancel();
    _hostsSub?.cancel();
    super.dispose();
  }

  void _startRealtimeListeners() {
    _agencySub?.cancel();
    _hostsSub?.cancel();

    if (mounted) setState(() => _isLoading = true);

    _agencySub = FirebaseFirestore.instance
        .collection('agencies')
        .doc(widget.agencyId)
        .snapshots()
        .listen(
          (doc) {
            if (!mounted) return;
            if (doc.exists) {
              setState(() {
                _agency = AgencyModel.fromFirestore(doc);
                _recalculateAnalytics();
                _isLoading = false;
              });
            }
          },
          onError: (e) {
            debugPrint('Error listening to agency: $e');
            if (mounted) setState(() => _isLoading = false);
          },
        );

    _hostsSub = AgencyService.getAgencyHostsStream(widget.agencyId).listen(
      (hosts) {
        if (!mounted) return;
        setState(() {
          _hosts = hosts;
          _recalculateAnalytics();
          _isLoading = false;
        });
      },
      onError: (e) {
        debugPrint('Error listening to hosts: $e');
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  void _recalculateAnalytics() {
    double totalDiamonds = 0.0;
    int totalLiveHours = 0;
    int totalGifts = 0;

    for (final host in _hosts) {
      totalDiamonds += host.performance.totalDiamonds;
      totalLiveHours += host.performance.totalLiveHours;
      totalGifts += host.performance.totalGiftsReceived;
    }

    final rate = _agency?.commissionRate ?? 0.10;
    final totalCommission = totalDiamonds * rate;

    _analytics = {
      'totalHosts': _hosts.length,
      'activeHosts': _hosts.where((h) => h.isActive).length,
      'totalDiamonds': totalDiamonds,
      'totalLiveHours': totalLiveHours,
      'totalGifts': totalGifts,
      'totalCommission': totalCommission,
      'commissionRate': rate,
      'isCommissionHeld': _agency?.isCommissionHeld ?? false,
      'averageHostRating': _hosts.isNotEmpty
          ? _hosts
                  .map((h) => h.performance.averageRating)
                  .reduce((a, b) => a + b) /
              _hosts.length
          : 0.0,
    };
  }

  Future<void> _loadReportsData() async {
    _startRealtimeListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : _buildReportsContent(),
    );
  }

  Widget _buildReportsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Range Selector
          _buildTimeRangeSelector(),
          
          const SizedBox(height: 24),
          
          // Key Metrics
          _buildKeyMetrics(),
          
          const SizedBox(height: 24),
          
          // Performance Charts
          _buildPerformanceCharts(),
          
          const SizedBox(height: 24),
          
          // Host Performance Table
          _buildHostPerformanceTable(),
          
          const SizedBox(height: 24),
          
          // Top Performers
          _buildTopPerformers(),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time Range',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTimeRangeChip('7D', '7d'),
              const SizedBox(width: 8),
              _buildTimeRangeChip('30D', '30d'),
              const SizedBox(width: 8),
              _buildTimeRangeChip('90D', '90d'),
              const SizedBox(width: 8),
              _buildTimeRangeChip('1Y', '1y'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeChip(String label, String value) {
    final isSelected = _selectedTimeRange == value;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedTimeRange = value;
          });
        }
      },
      backgroundColor: Colors.grey[800],
      selectedColor: Colors.blue,
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildKeyMetrics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[900]!, Colors.purple[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Performance Metrics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Hosts',
                  '${_analytics['totalHosts'] ?? 0}',
                  Icons.people,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Active Hosts',
                  '${_analytics['activeHosts'] ?? 0}',
                  Icons.person,
                  Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Diamonds',
                  '${(_analytics['totalDiamonds'] ?? 0.0).toStringAsFixed(0)}',
                  Icons.diamond,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Total Commission',
                  '${(_analytics['totalCommission'] ?? 0.0).toStringAsFixed(2)}',
                  Icons.monetization_on,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCharts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Trends',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Earnings Chart Placeholder
          SizedBox(
            height: 200,
            child: _buildChartPlaceholder('Earnings Trend', 'Chart visualization coming soon'),
          ),
          
          const SizedBox(height: 20),
          
          // Host Activity Chart Placeholder
          SizedBox(
            height: 200,
            child: _buildChartPlaceholder('Host Activity', 'Activity chart coming soon'),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder(String title, String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostPerformanceTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Host Performance Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_hosts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No hosts found',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey[800]),
                dataRowColor: WidgetStateProperty.all(Colors.grey[900]),
                columns: const [
                  DataColumn(
                    label: Text(
                      'Host Name',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Status',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Diamonds',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Diamonds',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Live Hours',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Rating',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: _hosts.map((host) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          host.hostName,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(host.status).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            host.status.name.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(host.status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          host.performance.totalDiamonds.toStringAsFixed(0),
                          style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          host.performance.totalDiamonds.toStringAsFixed(0),
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          host.performance.totalLiveHours.toString(),
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              host.performance.averageRating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
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

  Widget _buildTopPerformers() {
    final sortedHosts = List<HostModel>.from(_hosts);
    sortedHosts.sort((a, b) => b.performance.totalDiamonds.compareTo(a.performance.totalDiamonds));
    final topPerformers = sortedHosts.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Performers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (topPerformers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No performers found',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ...topPerformers.asMap().entries.map((entry) {
              final index = entry.key;
              final host = entry.value;
              return _buildTopPerformerCard(host, index + 1);
            }),
        ],
      ),
    );
  }

  Widget _buildTopPerformerCard(HostModel host, int rank) {
    Color rankColor;
    IconData rankIcon;
    
    switch (rank) {
      case 1:
        rankColor = Colors.amber;
        rankIcon = Icons.emoji_events;
        break;
      case 2:
        rankColor = Colors.grey[400]!;
        rankIcon = Icons.emoji_events;
        break;
      case 3:
        rankColor = Colors.orange[700]!;
        rankIcon = Icons.emoji_events;
        break;
      default:
        rankColor = Colors.grey;
        rankIcon = Icons.person;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: rankColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(rankIcon, color: rankColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  host.hostName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${host.performance.totalDiamonds.toStringAsFixed(0)} Diamonds',
                  style: const TextStyle(
                    color: Colors.purple,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  color: rankColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${host.performance.totalLiveHours}h',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(HostStatus status) {
    switch (status) {
      case HostStatus.active:
        return Colors.green;
      case HostStatus.pending:
        return Colors.orange;
      case HostStatus.suspended:
        return Colors.red;
      case HostStatus.terminated:
        return Colors.grey;
    }
  }
}
