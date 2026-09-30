import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isSavingConfig = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    GiftReceivingService.initializeDefaultExchangePackages();
  }

  @override
  void dispose() {
    _hostReceiverRateController.dispose();
    _hostAgencyRateController.dispose();
    _normalReceiverRateController.dispose();
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
      length: 4,
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
              Tab(text: 'Beans Wall'),
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
                  _buildBeansWallTab(),
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

  // ─── Tab 4: Beans Wall (Exchange Packages) ───

  Widget _buildBeansWallTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: GiftReceivingService.streamExchangePackages(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading packages: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final docs = snapshot.data?.docs ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF4511E).withValues(alpha: 0.15),
                      const Color(0xFFFF8A65).withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF4511E).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4511E).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.currency_exchange, color: Color(0xFFFF8A65), size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Exchange To Diamonds Wall',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage bean-to-diamond exchange packages displayed on the mobile app in real-time. Changes apply instantly.',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditPackageDialog(),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add Package'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4511E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Packages (${docs.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await GiftReceivingService.initializeDefaultExchangePackages();
                      _showSnackBar('Default packages checked/restored', Colors.orange);
                    },
                    icon: const Icon(Icons.restore, size: 16, color: Colors.grey),
                    label: const Text('Restore Missing Defaults', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                _buildEmptyState('No exchange packages found. Click "Add Package" above to create one.')
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 1100
                        ? 4
                        : constraints.maxWidth > 700
                            ? 3
                            : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final diamonds = (data['diamonds'] as num?)?.toInt() ?? 0;
                        final beans = (data['beans'] as num?)?.toInt() ?? 0;
                        return _buildPackageCard(doc.id, diamonds, beans);
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPackageCard(String packageId, int diamonds, int beans) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.diamond, color: Colors.amber, size: 28),
              const SizedBox(width: 8),
              Text(
                _formatNumber(diamonds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.orangeAccent, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${_formatNumber(beans)} Beans',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                tooltip: 'Edit Package',
                onPressed: () => _showAddEditPackageDialog(
                  packageId: packageId,
                  currentDiamonds: diamonds,
                  currentBeans: beans,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                tooltip: 'Delete Package',
                onPressed: () => _showDeletePackageDialog(packageId, diamonds, beans),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddEditPackageDialog({
    String? packageId,
    int? currentDiamonds,
    int? currentBeans,
  }) {
    final isEditing = packageId != null;
    final diamondsCtrl = TextEditingController(
      text: currentDiamonds != null ? currentDiamonds.toString() : '',
    );
    final beansCtrl = TextEditingController(
      text: currentBeans != null ? currentBeans.toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          isEditing ? 'Edit Exchange Package' : 'Add New Exchange Package',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: diamondsCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Diamonds Received',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: 'e.g. 1000',
                hintStyle: TextStyle(color: Colors.grey[700]),
                prefixIcon: const Icon(Icons.diamond, color: Colors.amber),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: beansCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Beans Required',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: 'e.g. 1000',
                hintStyle: TextStyle(color: Colors.grey[700]),
                prefixIcon: const Icon(Icons.monetization_on, color: Colors.orangeAccent),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final diamonds = int.tryParse(diamondsCtrl.text.replaceAll(',', ''));
              final beans = int.tryParse(beansCtrl.text.replaceAll(',', ''));
              if (diamonds == null || beans == null || diamonds <= 0 || beans <= 0) {
                _showSnackBar('Please enter valid positive numbers', Colors.red);
                return;
              }

              Navigator.pop(ctx);

              bool success;
              if (isEditing) {
                success = await GiftReceivingService.updateExchangePackage(
                  packageId: packageId,
                  diamonds: diamonds,
                  beans: beans,
                );
              } else {
                success = await GiftReceivingService.addExchangePackage(
                  diamonds: diamonds,
                  beans: beans,
                );
              }

              if (success) {
                _showSnackBar(
                  isEditing ? 'Package updated successfully' : 'Package added successfully',
                  Colors.green,
                );
              } else {
                _showSnackBar('Failed to save package', Colors.red);
              }
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showDeletePackageDialog(String packageId, int diamonds, int beans) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Package', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete the package ${_formatNumber(diamonds)} Diamonds for ${_formatNumber(beans)} Beans?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await GiftReceivingService.deleteExchangePackage(packageId);
              if (success) {
                _showSnackBar('Package deleted', Colors.orange);
              } else {
                _showSnackBar('Failed to delete package', Colors.red);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String mathFunc(Match match) => '${match[1]},';
    return number.toString().replaceAllMapped(reg, mathFunc);
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

    if (hostRate == null || agencyRate == null || normalRate == null) {
      _showSnackBar('Please enter valid numbers', Colors.red);
      return;
    }

    setState(() => _isSavingConfig = true);

    final success = await GiftReceivingService.updateConversionRates(
      newHostReceiverRate: hostRate / 100,
      newHostAgencyRate: agencyRate / 100,
      newNormalReceiverRate: normalRate / 100,
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
