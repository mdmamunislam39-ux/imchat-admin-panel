import 'package:flutter/material.dart';
import '../models/agency_commission_tier_model.dart';
import '../services/agency_commission_tier_service.dart';

class AgencyCommissionTierManagementScreen extends StatefulWidget {
  const AgencyCommissionTierManagementScreen({super.key});

  @override
  State<AgencyCommissionTierManagementScreen> createState() =>
      _AgencyCommissionTierManagementScreenState();
}

class _AgencyCommissionTierManagementScreenState
    extends State<AgencyCommissionTierManagementScreen> {
  bool _isSeeding = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        title: const Text(
          'Level-Based Commission Management',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high, color: Colors.amber),
            tooltip: 'Seed / Reset Default Tiers',
            onPressed: _isSeeding ? null : _confirmSeedDefaults,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
            tooltip: 'Add Commission Tier',
            onPressed: () => _showAddEditDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<AgencyCommissionTierModel>>(
        stream: AgencyCommissionTierService.getTiersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading tiers: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final tiers = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoBanner(tiers.length),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Commission & Reward Tiers (${tiers.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Tier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (tiers.isEmpty)
                  _buildEmptyState()
                else
                  _buildTiersList(tiers),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBanner(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
            blurRadius: 15,
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
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agency Commission Growth Track (লেভেল বেস কমিশন)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure weekly diamond earnings thresholds, commission rates %, and bonus reward diamonds.',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildInfoStatChip(
                label: 'Configured Tiers',
                value: '$count Levels',
                icon: Icons.layers_rounded,
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 16),
              _buildInfoStatChip(
                label: 'Cycle Type',
                value: 'Weekly (Mon - Mon)',
                icon: Icons.calendar_month_rounded,
                color: Colors.amber,
              ),
              const SizedBox(width: 16),
              _buildInfoStatChip(
                label: 'Sync Status',
                value: 'Realtime Live',
                icon: Icons.bolt_rounded,
                color: Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStatChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(Icons.military_tech_outlined,
              size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          const Text(
            'No Commission Tiers Configured',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up diamond targets and commission percentages, or load default standard tiers.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _confirmSeedDefaults,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Load Default Tiers (Tier 1-5)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Custom Tier'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  side: const BorderSide(color: Colors.blueAccent),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTiersList(List<AgencyCommissionTierModel> tiers) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final tier = tiers[index];
        return _buildTierCard(tier, index);
      },
    );
  }

  Widget _buildTierCard(AgencyCommissionTierModel tier, int index) {
    Color tierColor = _parseColor(tier.badgeColorHex);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tier.isActive ? tierColor.withValues(alpha: 0.5) : Colors.grey.shade800,
          width: tier.isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (tier.isActive)
            BoxShadow(
              color: tierColor.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tierColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, color: tierColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      tier.tierName.isNotEmpty ? tier.tierName : 'Tier ${tier.tierLevel}',
                      style: TextStyle(
                        color: tierColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tier.isActive
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: tier.isActive ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  tier.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: tier.isActive ? Colors.green : Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                tooltip: 'Edit Tier',
                onPressed: () => _showAddEditDialog(tier),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                tooltip: 'Delete Tier',
                onPressed: () => _confirmDeleteTier(tier),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Target Diamonds
              Expanded(
                child: _buildMetricTile(
                  label: 'Weekly Diamond Target',
                  value: '${_formatNumber(tier.minTargetDiamonds)} 💎',
                  subText: 'pts required to unlock',
                  icon: Icons.diamond_rounded,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              // Commission Rate
              Expanded(
                child: _buildMetricTile(
                  label: 'Commission Rate',
                  value: '${tier.commissionPercentage.toStringAsFixed(1)}%',
                  subText: 'agency earning rate',
                  icon: Icons.percent_rounded,
                  color: Colors.purpleAccent,
                ),
              ),
              const SizedBox(width: 12),
              // Bonus Diamond Reward
              Expanded(
                child: _buildMetricTile(
                  label: 'Next Tier Reward',
                  value: '+${_formatNumber(tier.bonusRewardDiamonds)} 💎',
                  subText: 'bonus unlocked at tier',
                  icon: Icons.card_giftcard_rounded,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
          if (tier.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              tier.description,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subText,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subText,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Dialog: Add / Edit Tier ────────────────────────────────────────────────
  void _showAddEditDialog([AgencyCommissionTierModel? tier]) {
    final isEditing = tier != null;
    final formKey = GlobalKey<FormState>();

    final levelController = TextEditingController(
      text: isEditing ? tier.tierLevel.toString() : '1',
    );
    final nameController = TextEditingController(
      text: isEditing ? tier.tierName : 'Tier 1',
    );
    final targetDiamondsController = TextEditingController(
      text: isEditing ? tier.minTargetDiamonds.toString() : '10000',
    );
    final commissionPercentageController = TextEditingController(
      text: isEditing ? tier.commissionPercentage.toStringAsFixed(1) : '10.0',
    );
    final rewardDiamondsController = TextEditingController(
      text: isEditing ? tier.bonusRewardDiamonds.toString() : '500',
    );
    final descriptionController = TextEditingController(
      text: isEditing ? tier.description : '',
    );

    String selectedColor = isEditing ? tier.badgeColorHex : '#FFB300';
    bool isActive = isEditing ? tier.isActive : true;
    bool isSaving = false;

    final colorOptions = [
      {'name': 'Amber / Gold', 'hex': '#FFB300'},
      {'name': 'Green', 'hex': '#4CAF50'},
      {'name': 'Blue', 'hex': '#2196F3'},
      {'name': 'Purple', 'hex': '#9C27B0'},
      {'name': 'Pink / Rose', 'hex': '#E91E63'},
      {'name': 'Orange', 'hex': '#FF9800'},
      {'name': 'Teal', 'hex': '#009688'},
    ];

    bool autoCalcEnabled = true;

    void calculateBonus() {
      if (!autoCalcEnabled) return;
      final target = double.tryParse(targetDiamondsController.text.trim()) ?? 0;
      final rate = double.tryParse(commissionPercentageController.text.trim()) ?? 0;
      if (target > 0 && rate > 0) {
        final bonus = (target * (rate / 100)).round();
        rewardDiamondsController.text = bonus.toString();
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final targetVal = double.tryParse(targetDiamondsController.text.trim()) ?? 0;
          final rateVal = double.tryParse(commissionPercentageController.text.trim()) ?? 0;
          final calculatedBonus = (targetVal * (rateVal / 100)).round();

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text(
              isEditing ? 'Edit Commission Tier' : 'Add New Commission Tier',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: 500,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: levelController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('Tier Level (1, 2, 3...)'),
                              validator: (val) {
                                final n = int.tryParse(val?.trim() ?? '');
                                if (n == null || n < 1) return 'Min 1';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Tier Label / Name (e.g. Tier 1)'),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: targetDiamondsController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          'Required Diamond Target (Weekly)',
                          suffixText: '💎 Points',
                        ),
                        onChanged: (val) {
                          setD(() {
                            calculateBonus();
                          });
                        },
                        validator: (val) {
                          final n = int.tryParse(val?.trim() ?? '');
                          if (n == null || n < 0) return 'Invalid diamond target';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: commissionPercentageController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              decoration: _inputDecoration(
                                'Commission Rate %',
                                suffixText: '%',
                              ),
                              onChanged: (val) {
                                setD(() {
                                  calculateBonus();
                                });
                              },
                              validator: (val) {
                                final n = double.tryParse(val?.trim() ?? '');
                                if (n == null || n < 0 || n > 100) {
                                  return '0 to 100%';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: rewardDiamondsController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(
                                'Bonus Reward Diamonds',
                                suffixText: '💎 Bonus',
                              ),
                              onChanged: (_) {
                                setD(() {
                                  autoCalcEnabled = false;
                                });
                              },
                              validator: (val) {
                                final n = int.tryParse(val?.trim() ?? '');
                                if (n == null || n < 0) return 'Invalid bonus';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Auto calculate helper info bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calculate_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                targetVal > 0 && rateVal > 0
                                    ? 'Auto: ${_formatNumber(targetVal)} 💎 × $rateVal% = ${_formatNumber(calculatedBonus)} 💎 Bonus'
                                    : 'Bonus auto-calculates from Target × Commission %',
                                style: TextStyle(
                                  color: Colors.amber.shade200,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!autoCalcEnabled)
                              InkWell(
                                onTap: () {
                                  setD(() {
                                    autoCalcEnabled = true;
                                    calculateBonus();
                                  });
                                },
                                child: Text(
                                  'Reset Auto',
                                  style: TextStyle(
                                    color: Colors.blueAccent.shade100,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Description / Note (Optional)'),
                      ),
                      const SizedBox(height: 16),
                      // Badge Color Picker
                      const Text(
                        'Badge Theme Color:',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: colorOptions.map((c) {
                          final hex = c['hex']!;
                          final isSelected = selectedColor == hex;
                          final color = _parseColor(hex);
                          return InkWell(
                            onTap: () => setD(() => selectedColor = hex),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active Status',
                            style: TextStyle(color: Colors.white)),
                        subtitle: const Text(
                          'When active, this tier applies to agencies.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        value: isActive,
                        activeThumbColor: Colors.blueAccent,
                        onChanged: (val) => setD(() => isActive = val),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton.icon(
                icon: isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save, size: 16),
                label: const Text('Save Tier'),
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setD(() => isSaving = true);

                        final newTier = AgencyCommissionTierModel(
                          id: isEditing ? tier.id : '',
                          tierLevel: int.parse(levelController.text.trim()),
                          tierName: nameController.text.trim(),
                          minTargetDiamonds:
                              int.parse(targetDiamondsController.text.trim()),
                          commissionPercentage: double.parse(
                              commissionPercentageController.text.trim()),
                          bonusRewardDiamonds:
                              int.parse(rewardDiamondsController.text.trim()),
                          description: descriptionController.text.trim(),
                          badgeColorHex: selectedColor,
                          isActive: isActive,
                        );

                        final success =
                            await AgencyCommissionTierService.saveTier(newTier);

                        if (!mounted) return;
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(success
                                ? 'Commission Tier saved successfully!'
                                : 'Failed to save tier.'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ));
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Delete Confirmation ────────────────────────────────────────────────────
  void _confirmDeleteTier(AgencyCommissionTierModel tier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Commission Tier',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${tier.tierName} (${_formatNumber(tier.minTargetDiamonds)} 💎)?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success =
                  await AgencyCommissionTierService.deleteTier(tier.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(success
                    ? 'Tier deleted successfully'
                    : 'Failed to delete tier'),
                backgroundColor: success ? Colors.green : Colors.red,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Seed Defaults ──────────────────────────────────────────────────────────
  void _confirmSeedDefaults() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Seed Default Commission Tiers?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will populate standard tiers (Tier 1: 10K 💎, Tier 2: 50K 💎, Tier 3: 100K 💎, Tier 4: 500K 💎, Tier 5: 1M 💎) with matching rewards.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.auto_fix_high, size: 16),
            label: const Text('Load Defaults'),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isSeeding = true);
              final success =
                  await AgencyCommissionTierService.seedDefaultTiers();
              if (mounted) {
                setState(() => _isSeeding = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? 'Default commission tiers loaded successfully!'
                      : 'Failed to load default tiers'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ));
              }
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? suffixText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      suffixText: suffixText,
      suffixStyle: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return Colors.amber;
    }
  }

  String _formatNumber(num n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M';
    } else if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    }
    return n.toString();
  }
}
