import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/host_model.dart';
import '../models/agency_model.dart';
import '../services/agency_service.dart';
import '../widgets/media_preview_widget.dart';

class AgencyIncomeScreen extends StatefulWidget {
  final String agencyId;
  
  const AgencyIncomeScreen({
    super.key,
    required this.agencyId,
  });

  @override
  State<AgencyIncomeScreen> createState() => _AgencyIncomeScreenState();
}

class _AgencyIncomeScreenState extends State<AgencyIncomeScreen> {
  AgencyModel? _agency;
  List<HostModel> _hosts = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  EarningPeriod _selectedPeriod = EarningPeriod.weekly;

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
        debugPrint('Error listening to agency hosts: $e');
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
    };
  }

  Future<void> _loadIncomeData() async {
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
          'Income & Payments',
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
            onPressed: _loadIncomeData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : _buildIncomeContent(),
    );
  }

  Widget _buildIncomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          _buildPeriodSelector(),
          
          const SizedBox(height: 24),
          
          // Income Overview
          _buildIncomeOverview(),
          
          const SizedBox(height: 24),
          
          // Commission Information
          _buildCommissionInfo(),
          
          const SizedBox(height: 24),
          
          // Host Earnings
          _buildHostEarningsSection(),
          
          const SizedBox(height: 24),
          
          // Payment History
          _buildPaymentHistory(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
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
            'Select Period',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: EarningPeriod.values.map((period) {
              final isSelected = _selectedPeriod == period;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      period.name.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPeriod = period;
                        });
                      }
                    },
                    backgroundColor: Colors.grey[800],
                    selectedColor: Colors.blue,
                    checkmarkColor: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeOverview() {
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
            'Income Overview',
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
                child: _buildOverviewItem(
                  'Total Diamonds',
                  '${(_analytics['totalDiamonds'] ?? 0.0).toStringAsFixed(0)}',
                  Icons.diamond,
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  'Total Diamonds',
                  '${(_analytics['totalDiamonds'] ?? 0.0).toStringAsFixed(0)}',
                  Icons.monetization_on,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  'Total Commission',
                  '${(_analytics['totalCommission'] ?? 0.0).toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  'Commission Rate',
                  '10%',
                  Icons.percent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
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
    );
  }

  Widget _buildCommissionInfo() {
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
            'Commission Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Commission Rate',
            '10% of total diamond earnings',
            Icons.percent,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Payment Schedule',
            'Every Sunday at 10:00 PM (Bangladesh Time)',
            Icons.schedule,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Payment Method',
            'Automatic transfer to agency account',
            Icons.account_balance,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Commission is calculated automatically based on your hosts\' diamond earnings and paid weekly.',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHostEarningsSection() {
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
            'Host Earnings Summary',
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
            ..._hosts.map((host) => _buildHostEarningCard(host)),
        ],
      ),
    );
  }

  Widget _buildHostEarningCard(HostModel host) {
    final rate = _agency?.commissionRate ?? 0.10;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(host.userId)
          .snapshots(),
      builder: (context, snapshot) {
        String displayName = host.hostName;
        String? photoUrl;
        String searchId = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final ud = snapshot.data!.data() as Map<String, dynamic>;
          displayName = ud['fullname'] ?? ud['username'] ?? displayName;
          photoUrl = ud['photoUrl'] ?? ud['profileImageUrl'];
          searchId = ud['searchId']?.toString() ?? '';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Row(
            children: [
              photoUrl != null && photoUrl.isNotEmpty
                  ? MediaPreviewWidget(
                      url: photoUrl,
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.circular(20),
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue,
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'H',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (searchId.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'ID: $searchId',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${host.status.name.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    host.performance.totalDiamonds.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.purple,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Diamonds',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    (host.performance.totalDiamonds * rate).toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Commission',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentHistory() {
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
            'Recent Payments',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentItem(
            'Weekly Commission',
            '2024-01-14',
            '${(_analytics['totalCommission'] ?? 0.0).toStringAsFixed(2)}',
            'Completed',
            Colors.green,
          ),
          const Divider(color: Colors.grey, height: 1),
          _buildPaymentItem(
            'Weekly Commission',
            '2024-01-07',
            '${((_analytics['totalCommission'] ?? 0.0) * 0.8).toStringAsFixed(2)}',
            'Completed',
            Colors.green,
          ),
          const Divider(color: Colors.grey, height: 1),
          _buildPaymentItem(
            'Weekly Commission',
            '2023-12-31',
            '${((_analytics['totalCommission'] ?? 0.0) * 0.6).toStringAsFixed(2)}',
            'Completed',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(String type, String date, String amount, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.payment,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
