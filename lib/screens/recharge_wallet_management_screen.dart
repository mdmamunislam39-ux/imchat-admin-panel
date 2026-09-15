import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/recharge_wallet_model.dart';
import '../services/recharge_wallet_service.dart';
import '../widgets/base_screen.dart';

/// Recharge Wallet Management Screen in Admin Panel
/// Allows editing of Diamond packages, Payment methods, verifying TrxID orders, and global wallet settings
class RechargeWalletManagementScreen extends StatefulWidget {
  const RechargeWalletManagementScreen({super.key});

  @override
  State<RechargeWalletManagementScreen> createState() =>
      _RechargeWalletManagementScreenState();
}

class _RechargeWalletManagementScreenState
    extends State<RechargeWalletManagementScreen>
    with SingleTickerProviderStateMixin {
  final RechargeWalletService _service = RechargeWalletService.instance;
  late TabController _tabController;

  // Search & Filter state for Orders
  String _ordersSearchQuery = '';
  final TextEditingController _ordersSearchController = TextEditingController();
  String _selectedOrderStatus = 'Pending';

  // Search & Filter state for Auto Payment Approve
  String _autoApproveSearchQuery = '';
  final TextEditingController _autoApproveSearchController = TextEditingController();
  String _selectedAutoApproveStatus = 'All';

  // SMS Simulator state
  final TextEditingController _simSmsController = TextEditingController();
  final TextEditingController _simSenderController = TextEditingController(text: 'bKash');
  bool _isSimulating = false;
  Map<String, dynamic>? _lastSimResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _service.seedDefaultPackagesIfEmpty();
    _service.seedDefaultPaymentMethodsIfEmpty();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ordersSearchController.dispose();
    _autoApproveSearchController.dispose();
    _simSmsController.dispose();
    _simSenderController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied: $text'),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAppDiamondIcon({double size = 22}) {
    return Image.asset(
      'assets/images/diamond_icon.webp',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.diamond, color: const Color(0xFFEC4899), size: size);
      },
    );
  }

  String _parseUserName(Map<String, dynamic>? data, String fallback) {
    if (data != null) {
      for (final key in ['fullname', 'name', 'username', 'displayName', 'nickname', 'fullName']) {
        final val = data[key];
        if (val != null && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
      }
    }
    return fallback.isNotEmpty ? fallback : 'Anonymous User';
  }

  String _parseUserPhoto(Map<String, dynamic>? data, String fallback) {
    if (data != null) {
      for (final key in ['photoUrl', 'profileImageUrl', 'avatar', 'imageUrl', 'photo', 'image', 'profileImage']) {
        final val = data[key];
        if (val != null && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
      }
    }
    return fallback;
  }

  String _parseSearchId(Map<String, dynamic>? data, String fallback) {
    if (data != null) {
      for (final key in ['searchId', 'user_id', 'numericId', 'uniqueId', 'shortId', 'id']) {
        final val = data[key];
        if (val != null && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
      }
    }
    return fallback;
  }

  String _parseUserPhone(Map<String, dynamic>? data, String fallback) {
    if (data != null) {
      for (final key in ['phone', 'number', 'phoneNumber', 'mobile', 'cell', 'userPhone']) {
        final val = data[key];
        if (val != null && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
      }
    }
    return fallback;
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Recharge Wallet Management',
      showBackButton: true,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF8B5CF6),
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[400],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: [
          const Tab(
            icon: Icon(Icons.diamond_outlined, size: 20),
            text: 'Diamond Packages',
          ),
          const Tab(
            icon: Icon(Icons.card_giftcard_rounded, size: 20),
            text: 'Weekly Benefits',
          ),
          const Tab(
            icon: Icon(Icons.account_balance_wallet_outlined, size: 20),
            text: 'Payment Methods',
          ),
          Tab(
            icon: StreamBuilder<int>(
              stream: _service.getPendingOrdersCountStream(),
              builder: (context, snap) {
                final pendingCount = snap.data ?? 0;
                return Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount'),
                  backgroundColor: const Color(0xFFF59E0B),
                  child: const Icon(Icons.receipt_long, size: 20),
                );
              },
            ),
            text: 'Recharge Orders',
          ),
          const Tab(
            icon: Icon(Icons.settings_suggest, size: 20),
            text: 'Wallet Settings',
          ),
          const Tab(
            icon: Icon(Icons.bolt_rounded, size: 20),
            text: 'Auto Payment Approve',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPackagesTab(),
          _buildWeeklyBenefitsTab(),
          _buildPaymentMethodsTab(),
          _buildOrdersTab(),
          _buildSettingsTab(),
          _buildAutoApproveTab(),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: DIAMOND PACKAGES MANAGEMENT
  // =========================================================================

  Widget _buildPackagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diamond Recharge Packages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Packages displayed to users on the app recharge wallet screen',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Package', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showAddEditPackageDialog(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Packages Grid
          StreamBuilder<List<RechargePackageModel>>(
            stream: _service.getPackagesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                  ),
                );
              }

              final packages = snapshot.data ?? [];
              if (packages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(Icons.diamond_outlined, size: 60, color: Colors.white24),
                        const SizedBox(height: 12),
                        const Text(
                          'No recharge packages configured yet.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _service.seedDefaultPackagesIfEmpty(),
                          child: const Text('Load Default Packages'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 1100
                      ? 4
                      : constraints.maxWidth > 750
                          ? 3
                          : constraints.maxWidth > 500
                              ? 2
                              : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.35,
                    ),
                    itemCount: packages.length,
                    itemBuilder: (context, index) {
                      return _buildPackageCard(packages[index]);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(RechargePackageModel pkg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pkg.isActive
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
              : Colors.white10,
          width: pkg.isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Status badge & Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pkg.isActive
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: pkg.isActive
                        ? const Color(0xFF10B981)
                        : Colors.grey,
                  ),
                ),
                child: Text(
                  pkg.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: pkg.isActive
                        ? const Color(0xFF10B981)
                        : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                    tooltip: 'Edit Package',
                    onPressed: () => _showAddEditPackageDialog(pkg),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    tooltip: 'Delete Package',
                    onPressed: () => _confirmDeletePackage(pkg),
                  ),
                ],
              ),
            ],
          ),

          // Center: Diamond and Price (Screenshot 2 style with real diamond icon + bonus badge)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: pkg.isActive
                    ? const Color(0xFFEC4899).withValues(alpha: 0.6)
                    : Colors.white12,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (pkg.bonusDiamonds > 0) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '+${pkg.bonusDiamonds} (${pkg.bonusPercentText} Extra)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAppDiamondIcon(size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '${pkg.diamondAmount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'BDT ${pkg.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Bottom: Quick switch & Sort order
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order: #${pkg.sortOrder}',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
              Switch(
                value: pkg.isActive,
                activeThumbColor: const Color(0xFF8B5CF6),
                onChanged: (val) async {
                  await _service.togglePackageStatus(pkg.id, pkg.isActive);
                  _showSuccess('Package ${pkg.isActive ? "deactivated" : "activated"}!');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddEditPackageDialog([RechargePackageModel? existing]) {
    final isEdit = existing != null;
    final amountCtrl = TextEditingController(text: existing != null ? existing.amount.toString() : '');
    final diamondCtrl = TextEditingController(text: existing != null ? existing.diamondAmount.toString() : '');
    final bonusCtrl = TextEditingController(
      text: existing != null && existing.bonusDiamonds > 0 ? existing.bonusDiamonds.toString() : '',
    );
    final sortCtrl = TextEditingController(text: existing != null ? existing.sortOrder.toString() : '0');
    bool isActive = existing != null ? existing.isActive : true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            final base = int.tryParse(diamondCtrl.text.trim()) ?? 0;
            final bonus = int.tryParse(bonusCtrl.text.trim()) ?? 0;
            final bonusPct = base > 0 ? (bonus / base) * 100 : 0.0;
            final total = base + bonus;

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEdit ? 'Edit Diamond Package' : 'Add Diamond Package',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Price in BDT (৳)',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixText: '৳ ',
                          prefixStyle: TextStyle(color: Color(0xFF10B981)),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B5CF6))),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: diamondCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Base Diamonds Amount',
                          labelStyle: const TextStyle(color: Colors.white70),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: _buildAppDiamondIcon(size: 20),
                          ),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B5CF6))),
                        ),
                        onChanged: (_) => setDlgState(() {}),
                      ),
                      const SizedBox(height: 12),

                      // Extra Bonus Diamonds field
                      TextField(
                        controller: bonusCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Extra Bonus Diamonds (e.g. 1000)',
                          labelStyle: TextStyle(color: Color(0xFFFBBF24)),
                          prefixIcon: Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 20),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFF59E0B))),
                        ),
                        onChanged: (_) => setDlgState(() {}),
                      ),

                      // Live Bonus Percentage & Total calculation preview
                      if (bonus > 0 && base > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Bonus: +$bonus 💎 (+${bonusPct.toStringAsFixed(bonusPct % 1 == 0 ? 0 : 1)}% Extra)\nTotal Credited: $total Diamonds',
                                  style: const TextStyle(
                                    color: Color(0xFFFBBF24),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      TextField(
                        controller: sortCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Sort Order (0, 1, 2...)',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B5CF6))),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Active in App:', style: TextStyle(color: Colors.white70)),
                          Switch(
                            value: isActive,
                            activeThumbColor: const Color(0xFF8B5CF6),
                            onChanged: (val) => setDlgState(() => isActive = val),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                  onPressed: () async {
                    final amount = num.tryParse(amountCtrl.text.trim()) ?? 0;
                    final diamonds = int.tryParse(diamondCtrl.text.trim()) ?? 0;
                    final bonus = int.tryParse(bonusCtrl.text.trim()) ?? 0;
                    final sort = int.tryParse(sortCtrl.text.trim()) ?? 0;

                    if (amount <= 0 || diamonds <= 0) {
                      _showError('Please enter valid amount and diamond values.');
                      return;
                    }

                    Navigator.pop(context);

                    try {
                      if (isEdit) {
                        await _service.updatePackage(
                          packageId: existing.id,
                          amount: amount,
                          diamondAmount: diamonds,
                          bonusDiamonds: bonus,
                          sortOrder: sort,
                          status: isActive ? 'active' : 'inactive',
                        );
                        _showSuccess('Package updated successfully!');
                      } else {
                        await _service.addPackage(
                          amount: amount,
                          diamondAmount: diamonds,
                          bonusDiamonds: bonus,
                          sortOrder: sort,
                          status: isActive ? 'active' : 'inactive',
                        );
                        _showSuccess('New diamond package added!');
                      }
                    } catch (e) {
                      _showError('Failed to save package: $e');
                    }
                  },
                  child: Text(isEdit ? 'UPDATE' : 'CREATE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeletePackage(RechargePackageModel pkg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Package?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${pkg.diamondAmount} Diamonds (৳${pkg.amount}) package?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.deletePackage(pkg.id);
                _showSuccess('Package deleted.');
              } catch (e) {
                _showError('Failed to delete package: $e');
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: PAYMENT METHODS MANAGEMENT
  // =========================================================================

  Widget _buildPaymentMethodsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recharge Payment Methods',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage receiver numbers (bKash, Nagad, Rocket, Bank) and on/off status',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Method', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showAddEditPaymentMethodDialog(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Methods List
          StreamBuilder<List<PaymentMethodModel>>(
            stream: _service.getPaymentMethodsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                  ),
                );
              }

              final methods = snapshot.data ?? [];
              if (methods.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(Icons.payments_outlined, size: 60, color: Colors.white24),
                        const SizedBox(height: 12),
                        const Text(
                          'No payment methods added yet.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _service.seedDefaultPaymentMethodsIfEmpty(),
                          child: const Text('Seed Default bKash & Nagad'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: methods.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildPaymentMethodCard(methods[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethodModel method) {
    Color brandColor = const Color(0xFF6366F1);
    final lowerName = method.name.toLowerCase();
    if (lowerName.contains('bkash')) brandColor = const Color(0xFFE2136E);
    if (lowerName.contains('nagad')) brandColor = const Color(0xFFF7941D);
    if (lowerName.contains('rocket')) brandColor = const Color(0xFF8C3494);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: method.isActive ? brandColor.withValues(alpha: 0.5) : Colors.white12,
          width: method.isActive ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Logo or initials container
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: brandColor.withValues(alpha: 0.4)),
            ),
            child: _buildPaymentLogoWidget(
              method.iconUrl,
              method.name,
              brandColor,
              size: 54,
              borderRadius: 14,
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      method.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: brandColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        method.type.toUpperCase(),
                        style: TextStyle(color: brandColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _copyToClipboard(method.number, 'Payment Number'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        method.number,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.copy, color: Colors.white54, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  method.instructions,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),

          // Actions & Live Switch
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    method.isActive ? 'LIVE ON' : 'DISABLED',
                    style: TextStyle(
                      color: method.isActive ? const Color(0xFF10B981) : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: method.isActive,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (val) async {
                      await _service.togglePaymentMethodStatus(method.id, method.isActive);
                      _showSuccess('${method.name} is now ${method.isActive ? "OFF" : "ON"}');
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                    tooltip: 'Edit Method',
                    onPressed: () => _showAddEditPaymentMethodDialog(method),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    tooltip: 'Delete Method',
                    onPressed: () => _confirmDeletePaymentMethod(method),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentLogoWidget(
    String iconUrl,
    String name,
    Color brandColor, {
    double size = 54,
    double borderRadius = 14,
  }) {
    final icon = iconUrl.trim();
    if (icon.isNotEmpty) {
      // 1. Data URI with base64 (e.g. data:image/png;base64,... or data:image/jpeg;base64,...)
      if (icon.startsWith('data:image/') || icon.startsWith('data:') || icon.contains(';base64,')) {
        try {
          final commaIndex = icon.indexOf(',');
          final rawBase64 = commaIndex != -1 ? icon.substring(commaIndex + 1) : icon;
          final cleanBase64 = rawBase64.replaceAll(RegExp(r'\s+'), '');
          final bytes = base64Decode(cleanBase64);
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: SizedBox(
              width: size,
              height: size,
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.payment, color: brandColor),
              ),
            ),
          );
        } catch (e) {
          debugPrint('Error decoding base64 in admin panel: $e');
        }
      }

      // 2. HTTP / HTTPS Network image (e.g. Firebase Storage)
      if (icon.startsWith('http://') || icon.startsWith('https://')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(
            width: size,
            height: size,
            child: CachedNetworkImage(
              imageUrl: icon,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Icon(Icons.payment, color: brandColor),
            ),
          ),
        );
      }

      // 3. Raw Base64 string without data: header
      if (icon.length > 50 && (!icon.contains('/') || icon.startsWith('/9j/') || icon.startsWith('iVBORw'))) {
        try {
          final cleanBase64 = icon.replaceAll(RegExp(r'\s+'), '');
          final bytes = base64Decode(cleanBase64);
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: SizedBox(
              width: size,
              height: size,
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.payment, color: brandColor),
              ),
            ),
          );
        } catch (_) {}
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            icon,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(Icons.payment, color: brandColor),
          ),
        ),
      );
    }

    return Center(
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
        style: TextStyle(color: brandColor, fontSize: size * 0.44, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAddEditPaymentMethodDialog([PaymentMethodModel? existing]) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final numberCtrl = TextEditingController(text: existing?.number ?? '');
    final typeCtrl = TextEditingController(text: existing?.type ?? 'Personal');
    final iconCtrl = TextEditingController(text: existing?.iconUrl ?? '');
    final instructionCtrl = TextEditingController(
      text: existing?.instructions ?? "'সেন্ড মানি' দিয়ে পরিশোধ করুন",
    );
    bool isStatusOn = existing != null ? existing.isActive : true;
    bool isUploadingLogo = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEdit ? 'Edit Payment Method' : 'Add Payment Method',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Preview & Upload Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                              ),
                              child: isUploadingLogo
                                  ? const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF8B5CF6),
                                        ),
                                      ),
                                    )
                                  : _buildPaymentLogoWidget(
                                      iconCtrl.text,
                                      nameCtrl.text.isNotEmpty ? nameCtrl.text : 'P',
                                      const Color(0xFF8B5CF6),
                                      size: 56,
                                      borderRadius: 12,
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B5CF6),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                                    label: Text(
                                      isUploadingLogo ? 'Uploading to Storage...' : 'Upload Logo Picture',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    onPressed: isUploadingLogo
                                        ? null
                                        : () async {
                                            try {
                                              final result = await FilePicker.platform.pickFiles(
                                                type: FileType.image,
                                                withData: true,
                                              );
                                              if (result != null && result.files.isNotEmpty) {
                                                final file = result.files.first;
                                                final bytes = file.bytes;
                                                if (bytes != null) {
                                                  setDlgState(() => isUploadingLogo = true);
                                                  final storageRef = FirebaseStorage.instance
                                                      .ref()
                                                      .child('payment_methods/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
                                                  final uploadTask = await storageRef.putData(bytes);
                                                  final downloadUrl = await uploadTask.ref.getDownloadURL();
                                                  setDlgState(() {
                                                    iconCtrl.text = downloadUrl;
                                                    isUploadingLogo = false;
                                                  });
                                                }
                                              }
                                            } catch (e) {
                                              setDlgState(() => isUploadingLogo = false);
                                              _showError('Logo upload failed: $e');
                                            }
                                          },
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Select PNG, JPG, or WebP file to upload',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: iconCtrl,
                        onChanged: (_) => setDlgState(() {}),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Logo URL or Base64 (Auto-filled on upload)',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B5CF6))),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        onChanged: (_) => setDlgState(() {}),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Payment Method Name (e.g. bKash, Nagad, Rocket)',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B5CF6))),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: numberCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Receiver Account Number (e.g. 01609738735)',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B5CF6))),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: typeCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Account Type (Personal / Agent / Merchant)',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B5CF6))),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: instructionCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Instructions / Bengali Note',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B5CF6))),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Live Status (ON/OFF):', style: TextStyle(color: Colors.white70)),
                          Switch(
                            value: isStatusOn,
                            activeThumbColor: const Color(0xFF10B981),
                            onChanged: (val) => setDlgState(() => isStatusOn = val),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final number = numberCtrl.text.trim();
                    final type = typeCtrl.text.trim();
                    final instructions = instructionCtrl.text.trim();
                    final iconUrl = iconCtrl.text.trim();

                    if (name.isEmpty || number.isEmpty) {
                      _showError('Name and receiver number are required.');
                      return;
                    }

                    Navigator.pop(context);

                    try {
                      if (isEdit) {
                        await _service.updatePaymentMethod(
                          methodId: existing.id,
                          name: name,
                          number: number,
                          type: type,
                          instructions: instructions,
                          iconUrl: iconUrl,
                          status: isStatusOn ? 'ON' : 'OFF',
                        );
                        _showSuccess('Payment method updated!');
                      } else {
                        await _service.addPaymentMethod(
                          name: name,
                          number: number,
                          type: type,
                          instructions: instructions,
                          iconUrl: iconUrl,
                          status: isStatusOn ? 'ON' : 'OFF',
                        );
                        _showSuccess('Payment method added!');
                      }
                    } catch (e) {
                      _showError('Failed to save payment method: $e');
                    }
                  },
                  child: Text(isEdit ? 'UPDATE' : 'ADD'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeletePaymentMethod(PaymentMethodModel method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Payment Method?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${method.name} (${method.number})?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.deletePaymentMethod(method.id);
                _showSuccess('${method.name} deleted.');
              } catch (e) {
                _showError('Failed to delete: $e');
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 3: RECHARGE ORDERS & TRXID VERIFICATION
  // =========================================================================

  Widget _buildOrdersTab() {
    final statusList = ['Pending', 'Approved', 'Rejected', 'All'];

    return Column(
      children: [
        // Controls Row: Search & Status Filter
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF0F172A),
          child: Row(
            children: [
              // Search field
              Expanded(
                child: TextField(
                  controller: _ordersSearchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by TrxID, User ID, User Name, or Order ID...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _ordersSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _ordersSearchController.clear();
                              setState(() => _ordersSearchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _ordersSearchQuery = val.trim().toLowerCase());
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Status Filter Chips
              Wrap(
                spacing: 8,
                children: statusList.map((status) {
                  final isSelected = _selectedOrderStatus == status;
                  return ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    selectedColor: const Color(0xFF8B5CF6),
                    backgroundColor: const Color(0xFF1E293B),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedOrderStatus = status);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Orders Stream List
        Expanded(
          child: StreamBuilder<List<RechargeOrderModel>>(
            stream: _service.getOrdersStream(
              statusFilter: _selectedOrderStatus == 'All' ? null : _selectedOrderStatus,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading orders: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }

              var orders = snapshot.data ?? [];

              // Search query filter (TrxID, User ID, Name, Order ID, Search ID, Phone)
              if (_ordersSearchQuery.isNotEmpty) {
                orders = orders.where((o) {
                  return o.transactionId.toLowerCase().contains(_ordersSearchQuery) ||
                      o.userId.toLowerCase().contains(_ordersSearchQuery) ||
                      o.userName.toLowerCase().contains(_ordersSearchQuery) ||
                      o.orderId.toLowerCase().contains(_ordersSearchQuery) ||
                      (o.searchId.isNotEmpty && o.searchId.toLowerCase().contains(_ordersSearchQuery)) ||
                      (o.userPhone.isNotEmpty && o.userPhone.toLowerCase().contains(_ordersSearchQuery));
                }).toList();
              }

              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, size: 64, color: Colors.white24),
                      const SizedBox(height: 12),
                      Text(
                        _selectedOrderStatus == 'Pending'
                            ? 'No pending recharge requests! 🎉'
                            : 'No $_selectedOrderStatus orders found.',
                        style: const TextStyle(color: Colors.white54, fontSize: 15),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  return _buildOrderCard(orders[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(RechargeOrderModel order) {
    Color statusColor = const Color(0xFFF59E0B); // Pending amber
    if (order.isApproved) statusColor = const Color(0xFF10B981); // Approved green
    if (order.isRejected) statusColor = const Color(0xFFEF4444); // Rejected red

    final formattedDate = order.createdAt != null
        ? '${order.createdAt!.day.toString().padLeft(2, '0')}/${order.createdAt!.month.toString().padLeft(2, '0')}/${order.createdAt!.year} ${order.createdAt!.hour.toString().padLeft(2, '0')}:${order.createdAt!.minute.toString().padLeft(2, '0')}'
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.isPending
              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
              : Colors.white12,
          width: order.isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Real-time User Info from Users/{userId} and Status Badge
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('Users').doc(order.userId).snapshots(),
            builder: (context, userSnap) {
              Map<String, dynamic>? userData;
              if (userSnap.hasData && userSnap.data?.data() != null) {
                userData = userSnap.data!.data() as Map<String, dynamic>?;
              }

              final realName = _parseUserName(userData, order.userName);
              final realPhoto = _parseUserPhoto(userData, order.userPhoto);
              final realSearchId = _parseSearchId(userData, order.searchId);
              final realPhone = _parseUserPhone(userData, order.userPhone);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF8B5CF6),
                    backgroundImage: realPhoto.isNotEmpty
                        ? CachedNetworkImageProvider(realPhoto)
                        : null,
                    child: realPhoto.isEmpty
                        ? Text(
                            realName.isNotEmpty ? realName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          realName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Search ID & User ID
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            if (realSearchId.isNotEmpty && realSearchId != '-')
                              InkWell(
                                onTap: () => _copyToClipboard(realSearchId, 'Search ID'),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Search ID: ',
                                            style: TextStyle(color: Colors.white60, fontSize: 11),
                                          ),
                                          Text(
                                            realSearchId,
                                            style: const TextStyle(
                                              color: Color(0xFFA78BFA),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.copy, color: Color(0xFFA78BFA), size: 12),
                                  ],
                                ),
                              ),

                            InkWell(
                              onTap: () => _copyToClipboard(order.userId, 'User ID'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'UID: ${order.userId}',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.copy, color: Colors.white38, size: 12),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Real-time Phone Number
                        if (realPhone.isNotEmpty && realPhone != '-') ...[
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _copyToClipboard(realPhone, 'Phone Number'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_iphone_rounded, color: Color(0xFF10B981), size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  'Phone: $realPhone',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.copy, color: Color(0xFF10B981), size: 12),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(color: Colors.white12, height: 24),

          // Order details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order ID: ${order.orderId}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              Text(formattedDate, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),

          // Pricing & Diamonds
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Amount', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    '৳${order.amount.toStringAsFixed(2)} BDT',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Diamonds Credited', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAppDiamondIcon(size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '+${order.totalDiamonds}',
                        style: const TextStyle(
                          color: Color(0xFFEC4899),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (order.bonusDiamonds > 0)
                    Text(
                      '(${order.diamondAmount} + ${order.bonusDiamonds} Bonus)',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Method & TrxID
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Method: ${order.paymentMethod}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('Target No: ${order.paymentNumber}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                const Divider(color: Colors.white12, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Transaction ID (TrxID):', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    InkWell(
                      onTap: () => _copyToClipboard(order.transactionId, 'TrxID'),
                      child: Row(
                        children: [
                          SelectableText(
                            order.transactionId,
                            style: const TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.copy, color: Color(0xFF8B5CF6), size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (order.isRejected && (order.rejectionReason?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Text(
              'Rejection Reason: ${order.rejectionReason}',
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
            ),
          ],

          if (order.isApproved && (order.verifiedBy?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Text(
              'Approved by: ${order.verifiedBy}',
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 12),
            ),
          ],

          // Approval & Rejection Buttons (If Pending)
          if (order.isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _rejectOrder(order),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('APPROVE & CREDIT', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _approveOrder(order),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _approveOrder(RechargeOrderModel order) async {
    final currentAdminId = FirebaseAuth.instance.currentUser?.uid ?? 'admin';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Approval & Credit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you verified the payment and want to approve?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Text('• User: ${order.userName} (${order.userId})', style: const TextStyle(color: Colors.white)),
            Text('• Amount Paid: ৳${order.amount}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            Text('• Diamonds to Credit: +${order.diamondAmount} Diamonds', style: const TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.bold)),
            Text('• TrxID: ${order.transactionId}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            const Text(
              '⚠️ This will atomically increment the user diamonds balance and cannot be reversed.',
              style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONFIRM & CREDIT'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6))),
      );

      await _service.approveOrder(
        orderId: order.orderId,
        adminId: currentAdminId,
      );

      if (mounted) Navigator.pop(context); // Dismiss loader
      _showSuccess('Order approved! +${order.diamondAmount} diamonds credited to user.');
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loader
      _showError('Failed to approve order: $e');
    }
  }

  Future<void> _rejectOrder(RechargeOrderModel order) async {
    final currentAdminId = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
    final reasonCtrl = TextEditingController(text: 'Invalid TrxID / Payment not received');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Recharge Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter reason for rejecting this order:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('REJECT ORDER'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.rejectOrder(
        orderId: order.orderId,
        adminId: currentAdminId,
        reason: reasonCtrl.text.trim(),
      );
      _showSuccess('Order ${order.orderId} rejected.');
    } catch (e) {
      _showError('Failed to reject order: $e');
    }
  }

  // =========================================================================
  // TAB 4: WALLET SETTINGS & GUIDELINES
  // =========================================================================

  Widget _buildSettingsTab() {
    return StreamBuilder<RechargeConfigModel>(
      stream: _service.getConfigStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
        }

        final config = snapshot.data ?? RechargeConfigModel();
        final noticeCtrl = TextEditingController(text: config.noticeText);
        final supportCtrl = TextEditingController(text: config.supportContact);
        final minCtrl = TextEditingController(text: config.minAmount.toString());
        final maxCtrl = TextEditingController(text: config.maxAmount.toString());
        bool isOnlineEnabled = config.isOnlineRechargeEnabled;

        return StatefulBuilder(
          builder: (context, setSettingsState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recharge Wallet System Settings',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Global guidelines, minimum/maximum recharge limits, and online recharge toggle',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Online Recharge Master Switch
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Online Recharge Master Switch',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isOnlineEnabled
                                  ? 'Users can currently recharge diamonds online in the app'
                                  : 'Online recharge is temporarily disabled for users',
                              style: TextStyle(color: Colors.grey[400], fontSize: 13),
                            ),
                          ],
                        ),
                        Switch(
                          value: isOnlineEnabled,
                          activeThumbColor: const Color(0xFF10B981),
                          onChanged: (val) => setSettingsState(() => isOnlineEnabled = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notice Text
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recharge Notice / Instructions for Users',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: noticeCtrl,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            hintText: 'Enter notice shown to users on recharge screen...',
                            hintStyle: const TextStyle(color: Colors.white38),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Support Contact
                        const Text(
                          'Recharge Support Contact (WhatsApp / Helpline)',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: supportCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            hintText: 'e.g. +8801609738735',
                            hintStyle: const TextStyle(color: Colors.white38),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Min and Max Limits
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Min Recharge BDT', style: TextStyle(color: Colors.white70)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: minCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.black.withValues(alpha: 0.3),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Max Recharge BDT', style: TextStyle(color: Colors.white70)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: maxCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.black.withValues(alpha: 0.3),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Save Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.save),
                            label: const Text('SAVE SETTINGS', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              final min = num.tryParse(minCtrl.text.trim()) ?? 50;
                              final max = num.tryParse(maxCtrl.text.trim()) ?? 50000;

                              try {
                                await _service.updateConfig(
                                  isOnlineRechargeEnabled: isOnlineEnabled,
                                  noticeText: noticeCtrl.text.trim(),
                                  supportContact: supportCtrl.text.trim(),
                                  minAmount: min,
                                  maxAmount: max,
                                );
                                _showSuccess('Recharge settings updated successfully!');
                              } catch (e) {
                                _showError('Failed to update settings: $e');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // TAB 6: AUTO PAYMENT APPROVE & SMS WEBHOOK
  // =========================================================================

  Widget _buildAutoApproveTab() {
    return StreamBuilder<AutoApproveConfigModel>(
      stream: _service.getAutoApproveConfigStream(),
      builder: (context, configSnap) {
        final config = configSnap.data ?? AutoApproveConfigModel();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: Color(0xFF10B981), size: 26),
                          SizedBox(width: 8),
                          Text(
                            'Auto Payment Approve & SMS Webhook',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Android ফোনের বিকাশ/নগদ/রকেট SMS পড়ে অটোমেটিক TrxID ও Amount ম্যাচ করে ইউজারকে ইনস্ট্যান্ট ডায়মন্ড যুক্ত করার সিস্টেম।',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Master Switch & Live Automation Status Card
              _buildAutoApproveMasterCard(config),
              const SizedBox(height: 20),

              // 3. Webhook URL & Secret Key Card
              _buildWebhookConfigCard(config),
              const SizedBox(height: 20),

              // 4. SMS Webhook Simulator / Test Tool Card
              _buildSmsSimulatorCard(config),
              const SizedBox(height: 24),

              // 5. Incoming Transactions Pool & History
              _buildIncomingTransactionsSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAutoApproveMasterCard(AutoApproveConfigModel config) {
    final isEnabled = config.isAutoApproveEnabled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : const Color(0xFF334155),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEnabled ? Icons.bolt_rounded : Icons.pause_circle_outline,
                      color: isEnabled ? const Color(0xFF10B981) : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Auto Payment Approval (অটো অ্যাপ্রুভ মাস্টার সুইচ)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEnabled
                            ? 'বর্তমানে চালু আছে: TrxID ও Amount মিললেই ইউজার অটোমেটিক ডায়মন্ড পাবে'
                            : 'বর্তমানে বন্ধ আছে: ট্রানজেকশন রেকর্ড হবে কিন্তু অ্যাডমিনের ম্যানুয়াল অনুমোদন লাগবে',
                        style: TextStyle(
                          color: isEnabled ? const Color(0xFF34D399) : Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: isEnabled,
                activeThumbColor: const Color(0xFF10B981),
                onChanged: (val) async {
                  try {
                    await _service.updateAutoApproveConfig(isAutoApproveEnabled: val);
                    _showSuccess(
                      val
                          ? 'Auto Payment Approval চালু করা হয়েছে!'
                          : 'Auto Payment Approval সাময়িকভাবে বন্ধ করা হয়েছে।',
                    );
                  } catch (e) {
                    _showError('Failed to update status: $e');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isEnabled
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isEnabled
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : const Color(0xFF334155),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isEnabled ? Icons.check_circle_outline : Icons.info_outline,
                  color: isEnabled ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEnabled
                        ? '🟢 অটো-অ্যাপ্রুভ সক্রিয়: বিকাশ/নগদে টাকা আসার মেসেজ পাওয়া মাত্রই সিস্টেম পেন্ডিং অর্ডারের সাথে মিলিয়ে সাথে সাথে একাউন্টে ডায়মন্ড যোগ করে দেবে।'
                        : '🟠 ম্যানুয়াল মোড সক্রিয়: SMS আসবে ও রেকর্ড হবে, তবে কোনো ডায়মন্ড স্বয়ংক্রিয়ভাবে ক্রেডিট হবে না। আপনাকে "Recharge Orders" ট্যাব থেকে রিভিউ করতে হবে।',
                    style: TextStyle(
                      color: isEnabled ? Colors.green[200] : const Color(0xFFFBBF24),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildWebhookConfigCard(AutoApproveConfigModel config) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.link_rounded, color: Color(0xFF8B5CF6), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'SMS Forwarder Webhook URL ও সিক্রেট কী (API Settings)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFA78BFA),
                  side: const BorderSide(color: Color(0xFF8B5CF6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Generate New Key'),
                onPressed: () => _confirmRegenerateSecret(config),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'এই Webhook URL ও Secret Key-টি আপনার বিকাশ/নগদ সিমে থাকা ফোনে SMS Forwarder অ্যাপে পেস্ট করে দিন।',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Webhook URL Box
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Webhook Target URL (HTTP POST):',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.http_rounded, color: Color(0xFF60A5FA), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SelectableText(
                        config.webhookUrl,
                        style: const TextStyle(
                          color: Color(0xFF93C5FD),
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                      tooltip: 'Copy Webhook URL',
                      onPressed: () => _copyToClipboard(config.webhookUrl, 'Webhook URL'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Webhook Secret Token Box
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Webhook Secret Key / API Token (Header: x-api-key):',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.key_rounded, color: Color(0xFFFBBF24), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SelectableText(
                        config.webhookSecret,
                        style: const TextStyle(
                          color: Color(0xFFFCD34D),
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                      tooltip: 'Copy Secret Key',
                      onPressed: () => _copyToClipboard(config.webhookSecret, 'Secret Key'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Template Copy & Setup Guide Row
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.code_rounded, size: 16),
                label: const Text('📋 Copy JSON Payload Template for App'),
                onPressed: () {
                  const template = '{"message": "%body", "sender": "%from"}';
                  _copyToClipboard(template, 'SMS Forwarder JSON Template');
                },
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Color(0xFF475569)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.help_outline_rounded, size: 16),
                label: const Text('📖 Android অ্যাপ সেটআপ গাইড দেখুন'),
                onPressed: _showSmsForwarderGuideDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmsSimulatorCard(AutoApproveConfigModel config) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.science_outlined, color: Color(0xFFEC4899), size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live SMS Webhook Simulator (পরীক্ষা টুল)',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'আসল টাকা পাঠানোর অপেক্ষা না করেই সিস্টেম কীভাবে SMS পড়ছে তা সরাসরি টেস্ট করুন।',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Preset Sample Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                backgroundColor: const Color(0xFFE2136E).withValues(alpha: 0.2),
                side: const BorderSide(color: Color(0xFFE2136E)),
                avatar: const Icon(Icons.send_to_mobile, size: 14, color: Color(0xFFF472B6)),
                label: const Text('bKash ৳500 SMS Demo', style: TextStyle(color: Colors.white, fontSize: 12)),
                onPressed: () {
                  final randomTrx = '9B${Random().nextInt(899999) + 100000}';
                  _simSenderController.text = 'bKash';
                  _simSmsController.text =
                      'You have received Tk 500.00 from 01712345678. Fee Tk 0.00. Balance Tk 2,500.00. TrxID $randomTrx at 10/09/2026 14:30';
                  setState(() {});
                },
              ),
              ActionChip(
                backgroundColor: const Color(0xFFF7941D).withValues(alpha: 0.2),
                side: const BorderSide(color: Color(0xFFF7941D)),
                avatar: const Icon(Icons.send_to_mobile, size: 14, color: Color(0xFFFDBA74)),
                label: const Text('Nagad ৳700 SMS Demo', style: TextStyle(color: Colors.white, fontSize: 12)),
                onPressed: () {
                  final randomTrx = '7NG${Random().nextInt(899999) + 100000}';
                  _simSenderController.text = 'Nagad';
                  _simSmsController.text =
                      'Received Tk 700.00 from 01912345678. TxnID: $randomTrx. Balance: Tk 1,700.00';
                  setState(() {});
                },
              ),
              ActionChip(
                backgroundColor: const Color(0xFF8C3494).withValues(alpha: 0.2),
                side: const BorderSide(color: Color(0xFF8C3494)),
                avatar: const Icon(Icons.send_to_mobile, size: 14, color: Color(0xFFE879F9)),
                label: const Text('Rocket ৳1000 SMS Demo', style: TextStyle(color: Colors.white, fontSize: 12)),
                onPressed: () {
                  final randomTrx = '8ROK${Random().nextInt(899999) + 100000}';
                  _simSenderController.text = 'Rocket';
                  _simSmsController.text =
                      'You have received Tk 1000.00 from 01812345678. TxID: $randomTrx. Balance: Tk 4,500.00';
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sender input & SMS text input
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _simSenderController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('Sender', icon: Icons.phone_android),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _simSmsController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration(
                    'SMS Text (বার্তা)',
                    icon: Icons.sms_outlined,
                    helper: 'Paste actual or test SMS from bKash / Nagad / Rocket',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Button & Live Status Output
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_lastSimResult != null)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _lastSimResult!['success'] == true
                          ? (_lastSimResult!['autoApproved'] == true
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFF3B82F6).withValues(alpha: 0.15))
                          : const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _lastSimResult!['success'] == true
                            ? (_lastSimResult!['autoApproved'] == true
                                ? const Color(0xFF10B981)
                                : const Color(0xFF3B82F6))
                            : const Color(0xFFEF4444),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _lastSimResult!['success'] == true
                              ? (_lastSimResult!['autoApproved'] == true
                                  ? Icons.check_circle
                                  : Icons.info_outline)
                              : Icons.error_outline,
                          size: 16,
                          color: _lastSimResult!['success'] == true
                              ? (_lastSimResult!['autoApproved'] == true
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF60A5FA))
                              : const Color(0xFFF87171),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _lastSimResult!['message']?.toString() ?? '',
                            style: TextStyle(
                              color: _lastSimResult!['success'] == true
                                  ? Colors.white
                                  : const Color(0xFFFCA5A5),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isSimulating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('🧪 TEST PROCESS SMS', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _isSimulating ? null : _runSmsSimulation,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _runSmsSimulation() async {
    final sms = _simSmsController.text.trim();
    final sender = _simSenderController.text.trim();
    if (sms.isEmpty) {
      _showError('Please enter or select a sample SMS to test.');
      return;
    }

    setState(() => _isSimulating = true);

    try {
      final result = await _service.processIncomingSms(
        rawMessage: sms,
        sender: sender.isNotEmpty ? sender : 'SMS',
      );

      setState(() {
        _lastSimResult = result;
        _isSimulating = false;
      });

      if (result['success'] == true) {
        if (result['autoApproved'] == true) {
          _showSuccess(
            '🎉 Matched & Auto-Approved! Order #${result['matchedOrderId']} credited with ${result['creditedDiamonds']} diamonds.',
          );
        } else {
          _showSuccess(
            '✅ TrxID: ${result['trxId']} (৳${result['amount']} BDT) saved in Unclaimed pool.',
          );
        }
      } else {
        _showError(result['message'] ?? 'Could not parse SMS.');
      }
    } catch (e) {
      setState(() {
        _isSimulating = false;
        _lastSimResult = {'success': false, 'message': 'Error: $e'};
      });
      _showError('Simulation failed: $e');
    }
  }

  Widget _buildIncomingTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const Row(
          children: [
            Icon(Icons.history_rounded, color: Color(0xFF8B5CF6), size: 22),
            SizedBox(width: 8),
            Text(
              'Incoming SMS & Auto-Payment History (আসা লেনদেনের তালিকা)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'ফোনের সিম থেকে Webhook-এর মাধ্যমে আসা সমস্ত ট্রানজেকশনের লাইভ রেকর্ড ও ক্লেইম হিস্ট্রি।',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        const SizedBox(height: 16),

        // StreamBuilder of incoming transactions
        StreamBuilder<List<IncomingTransactionModel>>(
          stream: _service.getIncomingTransactionsStream(
            statusFilter: _selectedAutoApproveStatus,
            searchQuery: _autoApproveSearchQuery,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                ),
              );
            }

            final transactions = snapshot.data ?? [];

            // Compute KPIs
            final totalCount = transactions.length;
            final claimedCount = transactions.where((t) => t.isClaimed).length;
            final unclaimedCount = transactions.where((t) => t.isUnclaimed).length;
            final totalBdt = transactions.fold<num>(0, (total, t) => total + t.amount);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Metric Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total SMS Received',
                        value: '$totalCount',
                        icon: Icons.mark_email_read_outlined,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Auto-Approved / Claimed',
                        value: '$claimedCount',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Unclaimed Pool',
                        value: '$unclaimedCount',
                        icon: Icons.hourglass_top_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Processed',
                        value: '৳${totalBdt.toStringAsFixed(0)}',
                        icon: Icons.account_balance_wallet_outlined,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search & Filter Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _autoApproveSearchController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search by TrxID, Sender, User ID, or Order ID...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF8B5CF6), size: 18),
                          suffixIcon: _autoApproveSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                                  onPressed: () {
                                    _autoApproveSearchController.clear();
                                    setState(() => _autoApproveSearchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF334155)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF334155)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                          ),
                        ),
                        onChanged: (val) => setState(() => _autoApproveSearchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _filterChip('All ($totalCount)', 'All', _selectedAutoApproveStatus, (val) {
                      setState(() => _selectedAutoApproveStatus = val);
                    }),
                    const SizedBox(width: 8),
                    _filterChip('Claimed ($claimedCount)', 'claimed', _selectedAutoApproveStatus, (val) {
                      setState(() => _selectedAutoApproveStatus = val);
                    }),
                    const SizedBox(width: 8),
                    _filterChip('Unclaimed ($unclaimedCount)', 'unclaimed', _selectedAutoApproveStatus, (val) {
                      setState(() => _selectedAutoApproveStatus = val);
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // Transactions List / Table
                if (transactions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inbox_outlined, color: Color(0xFF8B5CF6), size: 40),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Transactions Found',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SMS Forwarder থেকে মেসেজ আসলে অথবা উপরের সিমুলেটরে টেস্ট করলে এখানে হিস্ট্রি দেখতে পাবেন।',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = transactions[index];
                      return _buildTransactionCard(item);
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(IncomingTransactionModel item) {
    Color senderColor;
    final lowerSender = item.sender.toLowerCase();
    if (lowerSender.contains('bkash') || lowerSender.contains('বিকাশ')) {
      senderColor = const Color(0xFFE2136E);
    } else if (lowerSender.contains('nagad') || lowerSender.contains('নগদ')) {
      senderColor = const Color(0xFFF7941D);
    } else if (lowerSender.contains('rocket') || lowerSender.contains('রকেট')) {
      senderColor = const Color(0xFF8C3494);
    } else {
      senderColor = const Color(0xFF0D9488);
    }

    final isClaimed = item.isClaimed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isClaimed
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFF334155),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Operator Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: senderColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: senderColor.withValues(alpha: 0.6)),
            ),
            child: Text(
              item.sender,
              style: TextStyle(
                color: senderColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // TrxID & Amount
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SelectableText(
                      item.trxId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _copyToClipboard(item.trxId, 'TrxID'),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.copy, size: 14, color: Colors.white54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '৳${item.amount.toStringAsFixed(0)} BDT',
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.createdAt != null
                          ? '${item.createdAt!.day}/${item.createdAt!.month}/${item.createdAt!.year}  ${item.createdAt!.hour.toString().padLeft(2, '0')}:${item.createdAt!.minute.toString().padLeft(2, '0')}'
                          : 'Recent',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Claimed / Status Info
          Expanded(
            flex: 3,
            child: isClaimed
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 12, color: Color(0xFF34D399)),
                            SizedBox(width: 4),
                            Text(
                              'AUTO-APPROVED / CLAIMED',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'User: ${item.claimedByUserName ?? item.claimedByUserId ?? "Anonymous"}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.claimedOrderId != null)
                        Text(
                          'Order: #${item.claimedOrderId}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 11),
                        ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hourglass_empty, size: 12, color: Color(0xFFFBBF24)),
                        SizedBox(width: 4),
                        Text(
                          'UNCLAIMED (Waiting for Order)',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.sms_outlined, size: 18, color: Color(0xFF60A5FA)),
                tooltip: 'View Raw SMS Text',
                onPressed: () => _showRawSmsDialog(item),
              ),
              if (!isClaimed)
                IconButton(
                  icon: const Icon(Icons.link, size: 18, color: Color(0xFFA78BFA)),
                  tooltip: 'Manually Link with a Pending Order',
                  onPressed: () => _showManualMatchDialog(item),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFF87171)),
                tooltip: 'Delete Record',
                onPressed: () => _confirmDeleteTransaction(item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRawSmsDialog(IncomingTransactionModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.sms_outlined, color: Color(0xFF8B5CF6)),
            const SizedBox(width: 8),
            Text('Raw SMS Details: ${item.trxId}', style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: SelectableText(
                  item.rawMessage.isNotEmpty ? item.rawMessage : '(No raw SMS body recorded)',
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sender: ${item.sender}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  Text(
                    'Amount: ৳${item.amount.toStringAsFixed(0)} BDT',
                    style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showManualMatchDialog(IncomingTransactionModel item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.link, color: Color(0xFF8B5CF6)),
            const SizedBox(width: 8),
            Text('Match TrxID ${item.trxId} to Order', style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a pending recharge order to link with this ৳${item.amount} transaction. Linking will automatically approve the order and credit diamonds to the user.',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<RechargeOrderModel>>(
                  stream: _service.getOrdersStream(statusFilter: 'Pending'),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
                    }
                    final orders = snap.data ?? [];
                    if (orders.isEmpty) {
                      return Center(
                        child: Text(
                          'No pending recharge orders available to match.',
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: orders.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final ord = orders[idx];
                        final isAmountMatch = (ord.amount - item.amount).abs() < 1;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isAmountMatch ? const Color(0xFF10B981) : const Color(0xFF334155),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          ord.userName.isNotEmpty ? ord.userName : 'User ${ord.userId}',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        if (isAmountMatch) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('Amount Match', style: TextStyle(color: Color(0xFF34D399), fontSize: 10)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Order #${ord.orderId} | User TrxID: ${ord.transactionId}',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                    ),
                                    Text(
                                      '৳${ord.amount} BDT  →  +${ord.totalDiamonds} Diamonds',
                                      style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B5CF6),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onPressed: () async {
                                  Navigator.pop(dialogCtx);
                                  try {
                                    final currentAdminId = FirebaseAuth.instance.currentUser?.uid ?? 'Admin';
                                    await _service.manualMatchTransaction(
                                      trxId: item.trxId,
                                      orderId: ord.orderId,
                                      adminId: currentAdminId,
                                    );
                                    _showSuccess('Order #${ord.orderId} successfully matched & approved!');
                                  } catch (e) {
                                    _showError('Failed to match order: $e');
                                  }
                                },
                                child: const Text('APPROVE'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTransaction(IncomingTransactionModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete SMS Transaction?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete TrxID ${item.trxId} (৳${item.amount})? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.deleteIncomingTransaction(item.trxId);
                _showSuccess('Transaction ${item.trxId} deleted.');
              } catch (e) {
                _showError('Failed to delete transaction: $e');
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmRegenerateSecret(AutoApproveConfigModel config) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Regenerate Webhook Secret Key?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'নতুন সিক্রেট কী তৈরি করলে ফোনের SMS Forwarder অ্যাপেও নতুন কী-টি আপডেট করতে হবে, নয়তো আগের কী কাজ করবে না। আপনি কি নিশ্চিত?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final newKey = await _service.generateNewWebhookSecret();
                _showSuccess('New Secret Key generated: $newKey');
              } catch (e) {
                _showError('Failed to generate key: $e');
              }
            },
            child: const Text('REGENERATE KEY', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSmsForwarderGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.phone_android, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Android SMS Forwarder সেটআপ গাইড', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGuideStep(
                  step: '১',
                  title: 'যে ফোনে বিকাশ/নগদ সিম আছে সেই ফোনে অ্যাপ ইনস্টল করুন',
                  desc: 'Google Play Store থেকে "SMS Forwarder" (Cleanwatch) অথবা "SMS to URL" অ্যাপ ডাউনলোড করুন।',
                ),
                const SizedBox(height: 12),
                _buildGuideStep(
                  step: '২',
                  title: 'Sender Filter / প্রেরক নির্ধারণ করুন',
                  desc: 'শুধু বিকাশ/নগদের মেসেজ ফরওয়ার্ড করার জন্য Filter-এ bKash, Nagad, 16247, 16167, Rocket যোগ করুন।',
                ),
                const SizedBox(height: 12),
                _buildGuideStep(
                  step: '৩',
                  title: 'Forwarding টাইপ: Webhook / HTTP POST সিলেক্ট করুন',
                  desc: 'Target URL-এ আপনার স্ক্রিনে দেওয়া Webhook URL-টি পেস্ট করুন। Method: POST',
                ),
                const SizedBox(height: 12),
                _buildGuideStep(
                  step: '৪',
                  title: 'Header বা Body-তে সিক্রেট কী বসান',
                  desc: 'Headers অপশনে "x-api-key" দিয়ে আপনার Secret Key-টি বসান।',
                ),
                const SizedBox(height: 12),
                _buildGuideStep(
                  step: '৫',
                  title: 'JSON Payload টেমপ্লেট',
                  desc: 'অ্যাপের Payload সেকশনে নিচের JSON ফরম্যাটটি পেস্ট করুন:\n{"message": "%body", "sender": "%from"}',
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Color(0xFF34D399), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'টিপস: ফোনের ব্যাটারি অপটিমাইজেশন (Battery Optimization) অফ করে রাখবেন যাতে ব্যাকগ্রাউন্ডে মেসেজ আসার সাথে সাথে সাথে ফরওয়ার্ড হতে পারে।',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বুঝেছি (GOT IT)'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep({required String step, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: const Color(0xFF8B5CF6),
          child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon, String? helper}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      helperText: helper,
      helperStyle: const TextStyle(color: Colors.white54, fontSize: 11),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF8B5CF6), size: 18) : null,
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF334155)),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF8B5CF6)),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  // =========================================================================
  // TAB: WEEKLY RECHARGE BENEFITS MANAGEMENT
  // =========================================================================

  Widget _buildWeeklyBenefitsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Recharge Benefits (সাপ্তাহিক রিচার্জ বেনিফিট)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure store/official items (Frames, Entry Effects, Badges, etc.) as weekly recharge rewards.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('ADD BENEFIT TIER', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showAddEditBenefitDialog(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stream of weekly benefits
          StreamBuilder<List<WeeklyRechargeBenefitModel>>(
            stream: _service.getWeeklyBenefitsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading weekly benefits: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final benefits = snapshot.data ?? [];

              if (benefits.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          color: Color(0xFF8B5CF6),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Weekly Benefits Configured',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add official store items like Avatar Frames or Entry Effects as weekly rewards.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Benefit Tier'),
                        onPressed: () => _showAddEditBenefitDialog(),
                      ),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 1200
                      ? 4
                      : constraints.maxWidth > 800
                          ? 3
                          : constraints.maxWidth > 500
                              ? 2
                              : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: benefits.length,
                    itemBuilder: (context, index) {
                      final benefit = benefits[index];
                      return _buildBenefitCard(benefit);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(WeeklyRechargeBenefitModel benefit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: benefit.isActive ? const Color(0xFF8B5CF6).withValues(alpha: 0.5) : const Color(0xFF334155),
          width: benefit.isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: Tier badge & Active status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${benefit.order} ${benefit.tierName.isNotEmpty ? benefit.tierName : "Tier"}',
                  style: const TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: benefit.isActive
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  benefit.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: benefit.isActive ? const Color(0xFF34D399) : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Center: Item Thumbnail & Name
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: benefit.itemIcon.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: benefit.itemIcon,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6)),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFF59E0B),
                              size: 32,
                            ),
                          )
                        : const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B), size: 32),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  benefit.itemName.isNotEmpty ? benefit.itemName : 'Reward Item',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () => _copyToClipboard(benefit.itemId, 'Item ID'),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ID: ${benefit.itemId}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 11),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.copy, size: 12, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Target & Validity & Bonus Info
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildAppDiamondIcon(size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Target:',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      '${benefit.targetDiamonds} 💎',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (benefit.bonusDiamonds > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.card_giftcard, size: 14, color: Color(0xFFEC4899)),
                          SizedBox(width: 4),
                          Text(
                            'Bonus:',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        '+${benefit.bonusDiamonds} 💎',
                        style: const TextStyle(
                          color: Color(0xFFF472B6),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Color(0xFF34D399)),
                        SizedBox(width: 4),
                        Text(
                          'Validity:',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      '${benefit.validityDays} Days',
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (benefit.endDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: Color(0xFFF59E0B)),
                          SizedBox(width: 4),
                          Text(
                            'Expiry:',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                      Text(
                        '${benefit.endDate!.day}/${benefit.endDate!.month} ${benefit.endDate!.hour.toString().padLeft(2, '0')}:${benefit.endDate!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Bottom: Quick switch & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Switch(
                value: benefit.isActive,
                activeThumbColor: const Color(0xFF8B5CF6),
                onChanged: (val) async {
                  await _service.toggleWeeklyBenefitStatus(benefit.id, benefit.isActive);
                  _showSuccess('Benefit tier ${benefit.isActive ? "deactivated" : "activated"}!');
                },
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF60A5FA)),
                    tooltip: 'Edit Tier',
                    onPressed: () => _showAddEditBenefitDialog(benefit),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFF87171)),
                    tooltip: 'Delete Tier',
                    onPressed: () => _confirmDeleteBenefit(benefit),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBenefit(WeeklyRechargeBenefitModel benefit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Benefit Tier?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${benefit.tierName.isNotEmpty ? benefit.tierName : "Tier #${benefit.order}"} (${benefit.itemName})?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.deleteWeeklyBenefit(benefit.id);
                _showSuccess('Benefit tier deleted.');
              } catch (e) {
                _showError('Failed to delete benefit: $e');
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddEditBenefitDialog([WeeklyRechargeBenefitModel? existing]) {
    final isEdit = existing != null;
    final tierNameCtrl = TextEditingController(text: existing?.tierName ?? '');
    final targetCtrl = TextEditingController(
      text: existing != null ? existing.targetDiamonds.toString() : '5000',
    );
    final bonusDiamondsCtrl = TextEditingController(
      text: existing != null ? existing.bonusDiamonds.toString() : '0',
    );
    final itemIdCtrl = TextEditingController(text: existing?.itemId ?? '');
    final itemNameCtrl = TextEditingController(text: existing?.itemName ?? '');
    final itemIconCtrl = TextEditingController(text: existing?.itemIcon ?? '');
    final validityCtrl = TextEditingController(
      text: existing != null ? existing.validityDays.toString() : '7',
    );
    final orderCtrl = TextEditingController(
      text: existing != null ? existing.order.toString() : '1',
    );
    String selectedType = existing?.itemType ?? 'avatarFrame';
    bool isActive = existing?.isActive ?? true;
    DateTime? selectedEndDate = existing?.endDate;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            final targetDiamonds = int.tryParse(targetCtrl.text.trim()) ?? 0;
            final bonusDiamonds = int.tryParse(bonusDiamondsCtrl.text.trim()) ?? 0;
            final validityDays = int.tryParse(validityCtrl.text.trim()) ?? 7;

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEdit ? 'Edit Weekly Benefit Tier' : 'Add Weekly Benefit Tier',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tier Name & Order
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: tierNameCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Tier Name (e.g. Tier 1)', icon: Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: orderCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Order', icon: Icons.sort),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Recharge Target Diamonds & Diamond Bonus
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: targetCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              onChanged: (_) => setDlgState(() {}),
                              decoration: _inputDecoration(
                                'Recharge Target (Diamonds)',
                                icon: Icons.diamond_outlined,
                                helper: 'User must recharge this many diamonds',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: bonusDiamondsCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              onChanged: (_) => setDlgState(() {}),
                              decoration: _inputDecoration(
                                'Diamond Bonus (বোনাস)',
                                icon: Icons.card_giftcard,
                                helper: 'Extra diamonds awarded on claim',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Store Item Selection Button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reward Item (অফিশিয়াল/স্টোর আইটেম):',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.search, size: 18),
                              label: const Text('🔍 BROWSE OFFICIAL / STORE ITEMS'),
                              onPressed: () {
                                _showStoreItemPicker((picked) {
                                  setDlgState(() {
                                    itemIdCtrl.text = picked['id']?.toString() ?? '';
                                    itemNameCtrl.text = picked['name']?.toString() ?? picked['title']?.toString() ?? '';
                                    itemIconCtrl.text = picked['thumbnailUrl']?.toString() ??
                                        picked['fileUrl']?.toString() ??
                                        '';
                                    selectedType = picked['type']?.toString() ??
                                        picked['category']?.toString() ??
                                        'avatarFrame';
                                  });
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Item ID & Item Name
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: itemIdCtrl,
                              style: const TextStyle(color: Colors.white),
                              onChanged: (_) => setDlgState(() {}),
                              decoration: _inputDecoration('Item ID', icon: Icons.tag),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: itemNameCtrl,
                              style: const TextStyle(color: Colors.white),
                              onChanged: (_) => setDlgState(() {}),
                              decoration: _inputDecoration('Item Name', icon: Icons.label_outline),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Item Icon URL & Item Type Dropdown
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: itemIconCtrl,
                              style: const TextStyle(color: Colors.white),
                              onChanged: (_) => setDlgState(() {}),
                              decoration: _inputDecoration('Icon / Image URL', icon: Icons.image_outlined),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              initialValue: ['avatarFrame', 'entryEffect', 'badge', 'roomTheme', 'seatDecor', 'other']
                                      .contains(selectedType)
                                  ? selectedType
                                  : 'avatarFrame',
                              dropdownColor: const Color(0xFF1E293B),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _inputDecoration('Type'),
                              items: const [
                                DropdownMenuItem(value: 'avatarFrame', child: Text('Frame')),
                                DropdownMenuItem(value: 'entryEffect', child: Text('Entry Effect')),
                                DropdownMenuItem(value: 'badge', child: Text('Badge')),
                                DropdownMenuItem(value: 'roomTheme', child: Text('Room Theme')),
                                DropdownMenuItem(value: 'seatDecor', child: Text('Seat Decor')),
                                DropdownMenuItem(value: 'other', child: Text('Other')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDlgState(() => selectedType = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Validity (Days) & Active Switch
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: validityCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              onChanged: (_) => setDlgState(() {}),
                              decoration: _inputDecoration('Validity / মেয়াদ (Days)', icon: Icons.schedule),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              const Text('Active:', style: TextStyle(color: Colors.white, fontSize: 13)),
                              const SizedBox(width: 8),
                              Switch(
                                value: isActive,
                                activeThumbColor: const Color(0xFF8B5CF6),
                                onChanged: (val) => setDlgState(() => isActive = val),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Event Expiry (Live Countdown Timer Configuration)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.timer_outlined, color: Color(0xFFF59E0B), size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'Event Expiry / মেয়াদ (Live Countdown):',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                if (selectedEndDate != null)
                                  TextButton(
                                    onPressed: () => setDlgState(() => selectedEndDate = null),
                                    child: const Text('Reset', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Text(
                                      selectedEndDate != null
                                          ? 'Expires: ${selectedEndDate!.year}-${selectedEndDate!.month.toString().padLeft(2, '0')}-${selectedEndDate!.day.toString().padLeft(2, '0')} ${selectedEndDate!.hour.toString().padLeft(2, '0')}:${selectedEndDate!.minute.toString().padLeft(2, '0')}'
                                          : 'Expires: Current Week Sunday 23:59 (Default)',
                                      style: TextStyle(
                                        color: selectedEndDate != null ? const Color(0xFFF59E0B) : Colors.white60,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.calendar_today, size: 16),
                                  label: const Text('PICK DATE/TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  onPressed: () async {
                                    final now = DateTime.now();
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: selectedEndDate ?? now.add(const Duration(days: 7)),
                                      firstDate: now,
                                      lastDate: now.add(const Duration(days: 365)),
                                    );
                                    if (pickedDate != null) {
                                      if (!context.mounted) return;
                                      final pickedTime = await showTimePicker(
                                        context: context,
                                        initialTime: selectedEndDate != null
                                            ? TimeOfDay(hour: selectedEndDate!.hour, minute: selectedEndDate!.minute)
                                            : const TimeOfDay(hour: 23, minute: 59),
                                      );
                                      setDlgState(() {
                                        selectedEndDate = DateTime(
                                          pickedDate.year,
                                          pickedDate.month,
                                          pickedDate.day,
                                          pickedTime?.hour ?? 23,
                                          pickedTime?.minute ?? 59,
                                        );
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // LIVE PREVIEW
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: itemIconCtrl.text.trim().isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        itemIconCtrl.text.trim(),
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B)),
                                      ),
                                    )
                                  : const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemNameCtrl.text.trim().isNotEmpty
                                        ? itemNameCtrl.text.trim()
                                        : 'Preview Item Name',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Target: $targetDiamonds Diamonds | Bonus: +$bonusDiamonds Diamonds | Validity: $validityDays Days',
                                    style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final target = int.tryParse(targetCtrl.text.trim()) ?? 0;
                    final bonus = int.tryParse(bonusDiamondsCtrl.text.trim()) ?? 0;
                    final itemId = itemIdCtrl.text.trim();
                    final itemName = itemNameCtrl.text.trim();
                    final itemIcon = itemIconCtrl.text.trim();
                    final validity = int.tryParse(validityCtrl.text.trim()) ?? 7;
                    final order = int.tryParse(orderCtrl.text.trim()) ?? 1;
                    final tierName = tierNameCtrl.text.trim();

                    if (target <= 0) {
                      _showError('Please enter a valid recharge diamond target.');
                      return;
                    }
                    if (itemId.isEmpty) {
                      _showError('Please select or enter an Item ID.');
                      return;
                    }

                    Navigator.pop(dialogCtx);

                    try {
                      if (isEdit) {
                        await _service.updateWeeklyBenefit(
                          id: existing.id,
                          tierName: tierName,
                          targetDiamonds: target,
                          itemId: itemId,
                          itemName: itemName.isNotEmpty ? itemName : itemId,
                          itemIcon: itemIcon,
                          itemType: selectedType,
                          validityDays: validity,
                          bonusDiamonds: bonus,
                          endDate: selectedEndDate,
                          order: order,
                          isActive: isActive,
                        );
                        _showSuccess('Weekly benefit tier updated!');
                      } else {
                        await _service.addWeeklyBenefit(
                          tierName: tierName,
                          targetDiamonds: target,
                          itemId: itemId,
                          itemName: itemName.isNotEmpty ? itemName : itemId,
                          itemIcon: itemIcon,
                          itemType: selectedType,
                          validityDays: validity,
                          bonusDiamonds: bonus,
                          endDate: selectedEndDate,
                          order: order,
                          isActive: isActive,
                        );
                        _showSuccess('Weekly benefit tier added!');
                      }
                    } catch (e) {
                      _showError('Failed to save weekly benefit: $e');
                    }
                  },
                  child: Text(isEdit ? 'UPDATE TIER' : 'SAVE TIER', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStoreItemPicker(Function(Map<String, dynamic> item) onSelected) {
    String searchQuery = '';
    String selectedCategory = 'all';

    showDialog(
      context: context,
      builder: (pickerCtx) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Store / Official Item', style: TextStyle(color: Colors.white, fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(pickerCtx),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                height: 500,
                child: Column(
                  children: [
                    // Search & Category Chips
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Search by item name or ID...', icon: Icons.search),
                      onChanged: (val) {
                        setPickerState(() => searchQuery = val.trim().toLowerCase());
                      },
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('All', 'all', selectedCategory, (cat) => setPickerState(() => selectedCategory = cat)),
                          const SizedBox(width: 8),
                          _filterChip('Frames', 'avatarFrame', selectedCategory, (cat) => setPickerState(() => selectedCategory = cat)),
                          const SizedBox(width: 8),
                          _filterChip('Entry Effects', 'entryEffect', selectedCategory, (cat) => setPickerState(() => selectedCategory = cat)),
                          const SizedBox(width: 8),
                          _filterChip('Badges', 'badge', selectedCategory, (cat) => setPickerState(() => selectedCategory = cat)),
                          const SizedBox(width: 8),
                          _filterChip('Room Themes', 'roomTheme', selectedCategory, (cat) => setPickerState(() => selectedCategory = cat)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Items Grid from Firestore
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('market_items').snapshots(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
                          }

                          var docs = snap.data?.docs ?? [];
                          final filtered = docs.where((d) {
                            final data = d.data() as Map<String, dynamic>;
                            final name = (data['name'] ?? data['title'] ?? '').toString().toLowerCase();
                            final id = d.id.toLowerCase();
                            final type = (data['type'] ?? data['category'] ?? '').toString();

                            final matchesSearch = searchQuery.isEmpty || name.contains(searchQuery) || id.contains(searchQuery);
                            final matchesCategory = selectedCategory == 'all' || type.toLowerCase() == selectedCategory.toLowerCase();

                            return matchesSearch && matchesCategory;
                          }).toList();

                          if (filtered.isEmpty) {
                            return Center(
                              child: Text(
                                'No items found',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            );
                          }

                          return GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, idx) {
                              final doc = filtered[idx];
                              final data = doc.data() as Map<String, dynamic>;
                              final name = data['name'] ?? data['title'] ?? 'Item';
                              final imgUrl = data['thumbnailUrl'] ?? data['fileUrl'] ?? '';
                              final type = data['type'] ?? data['category'] ?? '';

                              return InkWell(
                                onTap: () {
                                  Navigator.pop(pickerCtx);
                                  onSelected({
                                    'id': doc.id,
                                    'name': name,
                                    'thumbnailUrl': imgUrl,
                                    'fileUrl': data['fileUrl'] ?? imgUrl,
                                    'type': type,
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF334155)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: imgUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: imgUrl,
                                                fit: BoxFit.contain,
                                                placeholder: (context, url) => const Center(
                                                  child: SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) => const Icon(
                                                  Icons.auto_awesome,
                                                  color: Color(0xFFF59E0B),
                                                ),
                                              )
                                            : const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B)),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        type,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterChip(String label, String value, String current, Function(String) onSelect) {
    final isSelected = current == value;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF334155)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[300],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

