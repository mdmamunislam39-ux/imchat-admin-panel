import 'package:flutter/material.dart';
import '../models/gift_transaction_model.dart';
import '../models/bean_conversion_model.dart';
import '../services/gift_receiving_service.dart';

class GiftTransactionsScreen extends StatefulWidget {
  const GiftTransactionsScreen({super.key});

  @override
  State<GiftTransactionsScreen> createState() => _GiftTransactionsScreenState();
}

class _GiftTransactionsScreenState extends State<GiftTransactionsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};
  List<GiftTransactionModel> _transactions = [];
  List<BeanConversionModel> _conversions = [];

  // Config controllers
  final TextEditingController _hostReceiverRateController = TextEditingController();
  final TextEditingController _hostAgencyRateController = TextEditingController();
  final TextEditingController _normalReceiverRateController = TextEditingController();
  final TextEditingController _beanToDiamondRateController = TextEditingController();
  bool _isSavingConfig = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _hostReceiverRateController.dispose();
    _hostAgencyRateController.dispose();
    _normalReceiverRateController.dispose();
    _beanToDiamondRateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final results = await Future.wait([
        GiftReceivingService.getGiftStatistics(),
        GiftReceivingService.getGiftTransactions(),
        GiftReceivingService.getBeanConversions(),
        GiftReceivingService.getConversionConfig(),
      ]);

      if (!mounted) return;
      setState(() {
        _statistics = results[0] as Map<String, dynamic>;
        _transactions = results[1] as List<GiftTransactionModel>;
        _conversions = results[2] as List<BeanConversionModel>;

        final config = results[3] as Map<String, dynamic>;
        _hostReceiverRateController.text =
            ((config['hostReceiverRate'] ?? 0.70) * 100).toStringAsFixed(0);
        _hostAgencyRateController.text =
            ((config['hostAgencyRate'] ?? 0.10) * 100).toStringAsFixed(0);
        _normalReceiverRateController.text =
            ((config['normalReceiverRate'] ?? 0.50) * 100).toStringAsFixed(0);
        _beanToDiamondRateController.text =
            (config['beanToDiamondRate'] ?? 1.0).toString();

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading gift data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text(
            'Gift Economy',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.blue,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Gift Transactions'),
              Tab(text: 'Bean Conversions'),
              Tab(text: 'Config'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : TabBarView(
                children: [
                  _buildGiftTransactionsTab(),
                  _buildBeanConversionsTab(),
                  _buildConfigTab(),
                ],
              ),
      ),
    );
  }

  // ─── Tab 1: Gift Transactions ───

  Widget _buildGiftTransactionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGiftStatCards(),
          const SizedBox(height: 24),
          const Text(
            'Recent Gift Transactions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_transactions.isEmpty)
            _buildEmptyState('No gift transactions found')
          else
            ..._transactions.map((txn) => _buildGiftTransactionCard(txn)),
        ],
      ),
    );
  }

  Widget _buildGiftStatCards() {
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
            'Gift Statistics',
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
                  'Total Gifts',
                  '${_statistics['totalGifts'] ?? 0}',
                  Icons.card_giftcard,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOverviewCard(
                  'Total Diamonds',
                  '${(_statistics['totalDiamonds'] ?? 0.0).toStringAsFixed(0)}',
                  Icons.diamond,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Beans Distributed',
                  '${(_statistics['totalBeansDistributed'] ?? 0.0).toStringAsFixed(0)}',
                  Icons.grain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOverviewCard(
                  'Platform Share',
                  '${(_statistics['totalPlatformShare'] ?? 0.0).toStringAsFixed(0)}',
                  Icons.account_balance,
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

  Widget _buildGiftTransactionCard(GiftTransactionModel txn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender → Receiver row
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        txn.senderName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      txn.receiverType == ReceiverType.host ? Icons.mic : Icons.person,
                      color: txn.receiverType == ReceiverType.host ? Colors.purple : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        txn.receiverName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: txn.receiverType == ReceiverType.host
                      ? Colors.purple.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  txn.receiverType == ReceiverType.host ? 'Host' : 'User',
                  style: TextStyle(
                    color: txn.receiverType == ReceiverType.host ? Colors.purple : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Gift + Diamond amount
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gift: ${txn.giftName}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  '${txn.diamondAmount.toStringAsFixed(0)} diamonds',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Bean splits
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSplitChip('Receiver', txn.beansToReceiver, Colors.green),
              if (txn.beansToAgency > 0)
                _buildSplitChip('Agency', txn.beansToAgency, Colors.orange),
              _buildSplitChip('Platform', txn.platformShare, Colors.blue),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            _formatDateTime(txn.createdAt),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitChip(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10),
          ),
          Text(
            '${value.toStringAsFixed(0)} beans',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 2: Bean Conversions ───

  Widget _buildBeanConversionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bean to Diamond Conversions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_conversions.isEmpty)
            _buildEmptyState('No bean conversions found')
          else
            ..._conversions.map((c) => _buildConversionCard(c)),
        ],
      ),
    );
  }

  Widget _buildConversionCard(BeanConversionModel conversion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.swap_horiz, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversion.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${conversion.beansSpent.toStringAsFixed(0)} beans -> ${conversion.diamondsReceived.toStringAsFixed(0)} diamonds',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(conversion.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${conversion.beansSpent.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              Text(
                '+${conversion.diamondsReceived.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Tab 3: Config ───

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                  'Gift Conversion Rates',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildConfigField(
                  label: 'Host Receiver Rate (%)',
                  controller: _hostReceiverRateController,
                  hint: 'e.g. 70',
                ),
                const SizedBox(height: 16),
                _buildConfigField(
                  label: 'Host Agency Rate (%)',
                  controller: _hostAgencyRateController,
                  hint: 'e.g. 10',
                ),
                const SizedBox(height: 16),
                _buildConfigField(
                  label: 'Normal User Receiver Rate (%)',
                  controller: _normalReceiverRateController,
                  hint: 'e.g. 50',
                ),
                const SizedBox(height: 16),
                _buildConfigField(
                  label: 'Bean to Diamond Rate',
                  controller: _beanToDiamondRateController,
                  hint: 'e.g. 1.0',
                ),
                const SizedBox(height: 24),
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
                          'Host receives their %, agency gets their %, and the platform keeps the remainder. Normal users receive their % and platform keeps the rest. These rates are read by the mobile app in real-time.',
                          style: TextStyle(color: Colors.blue, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingConfig ? null : _saveConfig,
                    icon: _isSavingConfig
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSavingConfig ? 'Saving...' : 'Save Config'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _initializeConfig,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset to Defaults'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[700]),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[700]!),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[800],
      ),
    );
  }

  Future<void> _saveConfig() async {
    final hostRate = double.tryParse(_hostReceiverRateController.text);
    final agencyRate = double.tryParse(_hostAgencyRateController.text);
    final normalRate = double.tryParse(_normalReceiverRateController.text);
    final diamondRate = double.tryParse(_beanToDiamondRateController.text);

    if (hostRate == null || agencyRate == null || normalRate == null || diamondRate == null) {
      _showSnackBar('Please enter valid numbers', Colors.red);
      return;
    }

    setState(() => _isSavingConfig = true);

    final success = await GiftReceivingService.updateConversionRates(
      newHostReceiverRate: hostRate / 100,
      newHostAgencyRate: agencyRate / 100,
      newNormalReceiverRate: normalRate / 100,
      newBeanToDiamondRate: diamondRate,
    );

    if (!mounted) return;
    setState(() => _isSavingConfig = false);

    if (success) {
      _showSnackBar('Config saved successfully', Colors.green);
    } else {
      _showSnackBar('Failed to save config', Colors.red);
    }
  }

  Future<void> _initializeConfig() async {
    await GiftReceivingService.initializeConversionConfig();
    _loadData();
    if (!mounted) return;
    _showSnackBar('Config reset to defaults', Colors.orange);
  }

  // ─── Helpers ───

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(
          message,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
