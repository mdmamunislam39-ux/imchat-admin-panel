import 'package:flutter/material.dart';
import '../services/commission_service.dart';

class CommissionManagement extends StatefulWidget {
  const CommissionManagement({super.key});

  @override
  State<CommissionManagement> createState() => _CommissionManagementState();
}

class _CommissionManagementState extends State<CommissionManagement> {
  Map<String, dynamic> _statistics = {};
  final List<Map<String, dynamic>> _recentRuns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommissionData();
  }

  Future<void> _loadCommissionData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load commission statistics
      final stats = await CommissionService.getCommissionStatistics();
      _statistics = stats;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading commission data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Commission Management',
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
            onPressed: _loadCommissionData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : _buildCommissionContent(),
    );
  }

  Widget _buildCommissionContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Commission Overview
          _buildCommissionOverview(),
          
          const SizedBox(height: 24),
          
          // Commission Settings
          _buildCommissionSettings(),
          
          const SizedBox(height: 24),
          
          // Manual Actions
          _buildManualActions(),
          
          const SizedBox(height: 24),
          
          // Commission History
          _buildCommissionHistory(),
        ],
      ),
    );
  }

  Widget _buildCommissionOverview() {
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
            'Commission Overview',
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
                child: _buildOverviewCard(
                  'Total Paid',
                  '${(_statistics['totalCommissionPaid'] ?? 0.0).toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOverviewCard(
                  'This Month',
                  '${(_statistics['thisMonthCommission'] ?? 0.0).toStringAsFixed(2)}',
                  Icons.calendar_month,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Active Agencies',
                  '${_statistics['totalActiveAgencies'] ?? 0}',
                  Icons.business,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOverviewCard(
                  'Commission Rate',
                  '${((_statistics['commissionRate'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                  Icons.percent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
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
      ),
    );
  }

  Widget _buildCommissionSettings() {
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
            'Commission Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            'Commission Rate',
            '10% of total diamond earnings',
            Icons.percent,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            'Payment Schedule',
            'Every Sunday at 10:00 PM (Bangladesh Time)',
            Icons.schedule,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            'Payment Method',
            'Automatic transfer to agency accounts',
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
                    'Commission calculations are performed automatically based on host diamond earnings. The system tracks all earnings and calculates 10% commission for each agency.',
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

  Widget _buildSettingItem(String label, String value, IconData icon, Color color) {
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

  Widget _buildManualActions() {
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
            'Manual Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _processCommissionsNow,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Process Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _calculateWeekCommission,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Calculate Week'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _viewCommissionHistory,
              icon: const Icon(Icons.history),
              label: const Text('View Commission History'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionHistory() {
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
            'Recent Commission Runs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_recentRuns.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No commission runs found',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ..._recentRuns.map((run) => _buildCommissionRunItem(run)),
        ],
      ),
    );
  }

  Widget _buildCommissionRunItem(Map<String, dynamic> run) {
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
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
                  'Commission Run',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${run['processedAgencies']} agencies processed',
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
                '${(run['totalCommission'] ?? 0.0).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  run['status'] ?? 'unknown',
                  style: const TextStyle(
                    color: Colors.green,
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

  Future<void> _processCommissionsNow() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          backgroundColor: Colors.grey,
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(width: 16),
              Text(
                'Processing commissions...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      final results = await CommissionService.processWeeklyCommissions();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Commission Processing Complete',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Processed: ${results['processedAgencies']} agencies',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Total Commission: ${results['totalCommission'].toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white),
                ),
                if (results['errors'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Errors:',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  ...results['errors'].map<Widget>((error) => Text(
                    '• $error',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  )),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        );
        
        _loadCommissionData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing commissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _calculateWeekCommission() async {
    // Show date picker to select week
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (selectedDate != null) {
      if (!mounted) return;
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            backgroundColor: Colors.grey,
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(width: 16),
                Text(
                  'Calculating commission...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );

        final results = await CommissionService.calculateCommissionForWeek(selectedDate);
        
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Week Commission Calculation',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Week: ${_formatDate(results['weekStart'])} - ${_formatDate(results['weekEnd'])}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Commission: ${results['totalCommission'].toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Agency Breakdown:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...results['agencyCommissions'].map<Widget>((agency) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${agency['agencyName']}: ${agency['totalCommission'].toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error calculating commission: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _viewCommissionHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Commission History',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              _buildHistoryFilters(),
              const SizedBox(height: 16),
              Expanded(
                child: _buildHistoryList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: 'all',
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Filter by Status',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'paid', child: Text('Paid')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                // TODO: Implement filtering
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: 'all',
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Filter by Host',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Hosts')),
                DropdownMenuItem(value: 'host1', child: Text('Host 1')),
                DropdownMenuItem(value: 'host2', child: Text('Host 2')),
              ],
              onChanged: (value) {
                // TODO: Implement filtering
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    // Mock commission history data
    final historyData = [
      {
        'id': '1',
        'hostName': 'John Doe',
        'amount': 150.0,
        'status': 'paid',
        'date': '2024-01-15',
        'description': 'Commission for January 2024',
      },
      {
        'id': '2',
        'hostName': 'Jane Smith',
        'amount': 200.0,
        'status': 'pending',
        'date': '2024-01-20',
        'description': 'Commission for January 2024',
      },
      {
        'id': '3',
        'hostName': 'Mike Johnson',
        'amount': 100.0,
        'status': 'paid',
        'date': '2024-01-10',
        'description': 'Commission for December 2023',
      },
    ];

    return ListView.builder(
      itemCount: historyData.length,
      itemBuilder: (context, index) {
        final entry = historyData[index];
        return _buildHistoryEntry(entry);
      },
    );
  }

  Widget _buildHistoryEntry(Map<String, dynamic> entry) {
    final status = entry['status'] as String;
    final statusColor = status == 'paid' ? Colors.green : 
                       status == 'pending' ? Colors.orange : Colors.red;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['hostName'],
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  entry['description'],
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                Text(
                  'Date: ${entry['date']}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${entry['amount'].toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                status.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
