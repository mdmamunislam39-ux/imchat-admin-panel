import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/withdrawal_model.dart';
import '../models/user_profile_model.dart';
import '../services/withdrawal_service.dart';
import '../services/user_profile_service.dart';
import '../services/auth_service.dart';
import '../widgets/web_image.dart';
import '../widgets/zoomable_image_dialog.dart';

class WithdrawalManagement extends StatefulWidget {
  const WithdrawalManagement({super.key});

  @override
  State<WithdrawalManagement> createState() => _WithdrawalManagementState();
}

class _WithdrawalManagementState extends State<WithdrawalManagement> {
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};
  Map<String, dynamic> _settings = {
    'beansPerUsd': 10000,
    'minWithdrawUsd': 20,
    'sellerDiamondPercent': 90,
    'isWithdrawalEnabled': true,
    'withdrawPackages': [20, 75, 100, 200, 500, 800, 1000, 3000],
  };
  List<WithdrawalModel> _withdrawals = [];
  List<WithdrawalModel> _filteredWithdrawals = [];
  String _selectedStatus = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final results = await Future.wait([
        WithdrawalService.getWithdrawalStatistics(),
        WithdrawalService.getWithdrawals(),
        WithdrawalService.getWithdrawalSettings(),
      ]);

      if (!mounted) return;
      setState(() {
        _statistics = results[0] as Map<String, dynamic>;
        _withdrawals = results[1] as List<WithdrawalModel>;
        _settings = results[2] as Map<String, dynamic>;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading withdrawal data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<WithdrawalModel> filtered = _withdrawals;

    // Status filter
    if (_selectedStatus == 'pending_admin_approval') {
      filtered = filtered
          .where((w) => w.status == WithdrawalStatus.pendingAdminApproval)
          .toList();
    } else if (_selectedStatus == 'pending') {
      filtered = filtered
          .where((w) => w.status == WithdrawalStatus.pending)
          .toList();
    } else if (_selectedStatus == 'approved') {
      filtered = filtered
          .where((w) => w.status == WithdrawalStatus.approved)
          .toList();
    } else if (_selectedStatus == 'rejected') {
      filtered = filtered
          .where((w) => w.status == WithdrawalStatus.rejected)
          .toList();
    }

    // Search filter (handles name, userId, searchId, bkash, seller name/id/searchId, notes)
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((w) {
        return w.username.toLowerCase().contains(query) ||
            w.userId.toLowerCase().contains(query) ||
            (w.userSearchId != null && w.userSearchId!.toLowerCase().contains(query)) ||
            w.accountNumber.toLowerCase().contains(query) ||
            (w.sellerName != null && w.sellerName!.toLowerCase().contains(query)) ||
            (w.sellerId != null && w.sellerId!.toLowerCase().contains(query)) ||
            (w.sellerSearchId != null && w.sellerSearchId!.toLowerCase().contains(query)) ||
            (w.sellerNote != null && w.sellerNote!.toLowerCase().contains(query)) ||
            (w.note != null && w.note!.toLowerCase().contains(query));
      }).toList();
    }

    _filteredWithdrawals = filtered;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: const Color(0xFF00B0FF),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => ZoomableImageDialog(imageUrl: imageUrl),
    );
  }

  void _openSettingsDialog() {
    final rateController = TextEditingController(
      text: (_settings['beansPerUsd'] ?? 10000).toString(),
    );
    final minUsdController = TextEditingController(
      text: (_settings['minWithdrawUsd'] ?? 20).toString(),
    );
    final sellerPercentController = TextEditingController(
      text: (_settings['sellerDiamondPercent'] ?? 90).toString(),
    );
    bool isEnabled = _settings['isWithdrawalEnabled'] ?? true;
    List<int> packages = List<int>.from(
      (_settings['withdrawPackages'] as List?) ??
          [20, 75, 100, 200, 500, 800, 1000, 3000],
    );
    final newPackageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final int currentRate = int.tryParse(rateController.text.trim()) ?? 10000;
          final int currentPercent = int.tryParse(sellerPercentController.text.trim()) ?? 90;

          return AlertDialog(
            backgroundColor: const Color(0xFF161D27),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.tune_rounded, color: Color(0xFF00B0FF), size: 24),
                SizedBox(width: 10),
                Text(
                  'Withdrawal & Rate Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Enable / Hide Withdrawal Switch
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? const Color(0xFF00E676).withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isEnabled
                              ? const Color(0xFF00E676).withValues(alpha: 0.3)
                              : Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEnabled
                                      ? 'Withdrawal Feature: ACTIVE (অন আছে)'
                                      : 'Withdrawal Feature: HIDDEN (হাইড করা আছে)',
                                  style: TextStyle(
                                    color: isEnabled ? const Color(0xFF00E676) : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isEnabled
                                      ? 'Users can view and request withdrawals in app.'
                                      : 'Withdrawal button & screen are hidden/disabled in app.',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isEnabled,
                            activeThumbColor: const Color(0xFF00E676),
                            activeTrackColor: const Color(0xFF00E676).withValues(alpha: 0.4),
                            onChanged: (val) {
                              setDialogState(() => isEnabled = val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 2. Conversion Rate (1 USD = ? Beans)
                    const Text(
                      '1 USD = How many Beans? (১ ডলার সমপরিমাণ বিন্স রেট):',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: rateController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.currency_exchange_rounded, color: Color(0xFF00B0FF)),
                        suffixText: 'Beans per \$1 USD',
                        suffixStyle: const TextStyle(color: Colors.grey),
                        hintText: 'e.g. 10000',
                        hintStyle: TextStyle(color: Colors.grey[700]),
                        filled: true,
                        fillColor: const Color(0xFF10141C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF00B0FF), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Example: \$20 = ${(20 * currentRate).toString()} beans | \$100 = ${(100 * currentRate).toString()} beans',
                      style: const TextStyle(color: Color(0xFF00B0FF), fontSize: 11),
                    ),

                    const SizedBox(height: 18),

                    // 3. Minimum Withdrawal in USD
                    const Text(
                      'Minimum Withdrawal in USD (সর্বনিম্ন উইথড্র ডলার):',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: minUsdController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.attach_money_rounded, color: Color(0xFF00E676)),
                        suffixText: 'USD',
                        suffixStyle: const TextStyle(color: Colors.grey),
                        hintText: 'e.g. 20',
                        hintStyle: TextStyle(color: Colors.grey[700]),
                        filled: true,
                        fillColor: const Color(0xFF10141C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 4. Seller Diamond Reward Percentage
                    const Text(
                      'Seller Diamond Reward % (সেলার বিন্স উইথড্র থেকে কত % ডায়মন্ড পাবে):',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: sellerPercentController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.diamond_rounded, color: Color(0xFFBB86FC)),
                        suffixText: '% Diamonds',
                        suffixStyle: const TextStyle(color: Colors.grey),
                        hintText: 'e.g. 90',
                        hintStyle: TextStyle(color: Colors.grey[700]),
                        filled: true,
                        fillColor: const Color(0xFF10141C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFBB86FC), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Example: 100,000 Beans withdrawal approved → Seller receives ${(100000 * (currentPercent / 100.0)).round()} Diamonds ($currentPercent%)',
                      style: const TextStyle(color: Color(0xFFBB86FC), fontSize: 11),
                    ),

                    const SizedBox(height: 18),

                    // 5. Withdrawal Packages Tiers
                    const Text(
                      'Preset Packages in App (\$ Tiers):',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: packages.map((usd) {
                        return Chip(
                          backgroundColor: const Color(0xFF1F2735),
                          side: const BorderSide(color: Color(0xFF00B0FF)),
                          label: Text(
                            '\$$usd (${(usd * currentRate)} 🪙)',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14, color: Colors.grey),
                          onDeleted: () {
                            setDialogState(() {
                              packages.remove(usd);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newPackageController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Add USD Tier (e.g. 50)',
                              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                              prefixText: '\$ ',
                              prefixStyle: const TextStyle(color: Colors.white),
                              filled: true,
                              fillColor: const Color(0xFF10141C),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final val = int.tryParse(newPackageController.text.trim());
                            if (val != null && val > 0 && !packages.contains(val)) {
                              setDialogState(() {
                                packages.add(val);
                                packages.sort();
                                newPackageController.clear();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B0FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Add Tier'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final newRate = int.tryParse(rateController.text.trim()) ?? 10000;
                  final newMinUsd = int.tryParse(minUsdController.text.trim()) ?? 20;
                  final newSellerPercent = int.tryParse(sellerPercentController.text.trim()) ?? 90;

                  Navigator.pop(dialogCtx);
                  setState(() => _isLoading = true);

                  final ok = await WithdrawalService.updateWithdrawalSettings(
                    beansPerUsd: newRate,
                    minWithdrawUsd: newMinUsd,
                    sellerDiamondPercent: newSellerPercent,
                    isWithdrawalEnabled: isEnabled,
                    withdrawPackages: packages,
                  );

                  if (mounted) {
                    if (ok) {
                      _showSnackBar(
                        'Settings saved! Real-time conversion rate & $newSellerPercent% seller diamond reward updated across apps.',
                        const Color(0xFF00E676),
                      );
                      _loadData();
                    } else {
                      _showSnackBar('Failed to update settings', Colors.red);
                      setState(() => _isLoading = false);
                    }
                  }
                },
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Save & Sync to App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================================
  // AUTHORIZED WITHDRAWAL SELLERS MANAGEMENT MODAL
  // =========================================================================
  void _openAuthorizedSellersDialog() {
    final searchUserController = TextEditingController();
    UserProfileModel? searchedUser;
    bool isSearching = false;
    String searchError = '';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF161D27),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.storefront_rounded, color: Color(0xFFBB86FC), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Authorized Withdrawal Sellers',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Add sellers by Search ID. Only these sellers appear in the app withdrawal list.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              height: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Search Box
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchUserController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Enter User Search ID or UID (চার্জ আইডি)...',
                            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFBB86FC), size: 20),
                            filled: true,
                            fillColor: const Color(0xFF10141C),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFBB86FC), width: 1.5),
                            ),
                          ),
                          onSubmitted: (query) async {
                            final clean = query.trim();
                            if (clean.isEmpty) return;
                            setDialogState(() {
                              isSearching = true;
                              searchError = '';
                              searchedUser = null;
                            });

                            final found = await UserProfileService.findUserBySearchIdOrUid(clean);
                            setDialogState(() {
                              isSearching = false;
                              if (found != null) {
                                searchedUser = found;
                              } else {
                                searchError = 'No user found with Search ID / UID: $clean';
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isSearching
                            ? null
                            : () async {
                                final query = searchUserController.text.trim();
                                if (query.isEmpty) return;
                                setDialogState(() {
                                  isSearching = true;
                                  searchError = '';
                                  searchedUser = null;
                                });

                                final found = await UserProfileService.findUserBySearchIdOrUid(query);
                                setDialogState(() {
                                  isSearching = false;
                                  if (found != null) {
                                    searchedUser = found;
                                  } else {
                                    searchError = 'No user found with Search ID / UID: $query';
                                  }
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBB86FC),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: isSearching
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                  if (searchError.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(searchError, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ],

                  // 2. Searched User Preview Card
                  if (searchedUser != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2735),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBB86FC).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: searchedUser!.profileImageUrl != null &&
                                    searchedUser!.profileImageUrl!.isNotEmpty
                                ? NetworkImage(searchedUser!.profileImageUrl!)
                                : null,
                            backgroundColor: const Color(0xFF2E3A4D),
                            child: searchedUser!.profileImageUrl == null ||
                                    searchedUser!.profileImageUrl!.isEmpty
                                ? Text(
                                    searchedUser!.username.isNotEmpty
                                        ? searchedUser!.username[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  searchedUser!.username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00B0FF).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Search ID: ${searchedUser!.searchId ?? 'N/A'}',
                                        style: const TextStyle(
                                          color: Color(0xFF00B0FF),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'UID: ${searchedUser!.userId}',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final u = searchedUser!;
                              final ok = await WithdrawalService.addWithdrawalSeller(
                                userId: u.userId,
                                username: u.username,
                                searchId: (u.searchId != null && u.searchId!.isNotEmpty)
                                    ? u.searchId!
                                    : u.userId,
                                photoUrl: u.profileImageUrl,
                                userType: u.userType.name,
                              );
                              if (ok) {
                                setDialogState(() {
                                  searchedUser = null;
                                  searchUserController.clear();
                                });
                                _showSnackBar(
                                  'Added ${u.username} as authorized withdrawal seller!',
                                  const Color(0xFF00E676),
                                );
                              } else {
                                _showSnackBar('Failed to add seller', Colors.red);
                              }
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Seller'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E676),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 6),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Authorized Sellers List (অনুমোদিত সেলার সমূহ):',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 3. Realtime Stream of Authorized Sellers
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: WithdrawalService.streamWithdrawalSellers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: Color(0xFFBB86FC), strokeWidth: 2),
                          );
                        }

                        final sellers = snapshot.data ?? [];
                        if (sellers.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_off_rounded, color: Colors.grey[700], size: 40),
                                const SizedBox(height: 8),
                                const Text(
                                  'No authorized withdrawal sellers added yet.\nSearch by Search ID above to add sellers.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: sellers.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final s = sellers[idx];
                            final sellerDocId = s['id'] ?? s['userId'] ?? '';
                            final name = s['name'] ?? s['username'] ?? 'Seller';
                            final searchId = s['searchId'] ?? '';
                            final userId = s['userId'] ?? '';
                            final photoUrl = s['photoUrl'] as String?;
                            final isActive = s['isActive'] as bool? ?? true;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10141C),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.red.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    backgroundColor: const Color(0xFF1F2735),
                                    child: photoUrl == null || photoUrl.isEmpty
                                        ? Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                            style: const TextStyle(
                                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            if (!isActive)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'INACTIVE',
                                                  style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF00B0FF).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Search ID: $searchId',
                                                style: const TextStyle(
                                                  color: Color(0xFF00B0FF),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'UID: $userId',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: isActive,
                                    activeThumbColor: const Color(0xFF00E676),
                                    activeTrackColor: const Color(0xFF00E676).withValues(alpha: 0.4),
                                    onChanged: (val) async {
                                      await WithdrawalService.toggleWithdrawalSellerStatus(sellerDocId, val);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                    tooltip: 'Remove Seller',
                                    onPressed: () async {
                                      await WithdrawalService.removeWithdrawalSeller(sellerDocId);
                                      _showSnackBar('Removed $name from authorized sellers', Colors.orange);
                                    },
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
                child: const Text('Close', style: TextStyle(color: Colors.grey)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1217),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161C24),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.currency_exchange_rounded, color: Color(0xFF00E676)),
            SizedBox(width: 10),
            Text(
              'Withdrawal Management',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            onPressed: _openAuthorizedSellersDialog,
            icon: const Icon(Icons.storefront_rounded, size: 16),
            label: const Text('👥 Authorized Sellers (উইথড্র সেলার)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E2633),
              foregroundColor: const Color(0xFFBB86FC),
              side: const BorderSide(color: Color(0xFFBB86FC)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _openSettingsDialog,
            icon: const Icon(Icons.settings_rounded, size: 16),
            label: const Text('Settings & Rates (রেট ও সেটিংস)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E2633),
              foregroundColor: const Color(0xFF00B0FF),
              side: const BorderSide(color: Color(0xFF00B0FF)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00B0FF)),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF00B0FF),
              backgroundColor: const Color(0xFF1E2633),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatCards(),
                    const SizedBox(height: 20),
                    _buildFilterRow(),
                    const SizedBox(height: 16),
                    if (_filteredWithdrawals.isEmpty)
                      _buildEmptyState()
                    else
                      ..._filteredWithdrawals.map((w) => _buildWithdrawalCard(w)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCards() {
    final pendingApproval = _statistics['pendingAdminApprovalCount'] ?? 0;
    final pendingSeller = _statistics['pendingSellerCount'] ?? 0;
    final approved = _statistics['approvedCount'] ?? 0;
    final totalReq = _statistics['totalRequests'] ?? 0;
    final totalDiamonds = _statistics['totalDiamondsRewarded'] ?? 0;
    final sellerPercent = _settings['sellerDiamondPercent'] ?? 90;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F2C), Color(0xFF131822)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Withdrawal & Seller Commission Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFBB86FC).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBB86FC).withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Seller $sellerPercent% Diamond Auto-Credit',
                  style: const TextStyle(
                    color: Color(0xFFE1BEE7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              if (isNarrow) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildOverviewCard(
                            'Needs Review',
                            '$pendingApproval',
                            Icons.pending_actions_rounded,
                            const Color(0xFF00B0FF),
                            highlight: pendingApproval > 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildOverviewCard(
                            'Waiting Seller',
                            '$pendingSeller',
                            Icons.hourglass_top_rounded,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOverviewCard(
                            'Approved',
                            '$approved',
                            Icons.check_circle_rounded,
                            const Color(0xFF00E676),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildOverviewCard(
                            '$sellerPercent% Diamonds Rewarded',
                            '💎 $totalDiamonds',
                            Icons.diamond_rounded,
                            const Color(0xFFBB86FC),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildOverviewCard(
                      'Total Requests',
                      '$totalReq',
                      Icons.receipt_long_rounded,
                      Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOverviewCard(
                      'Needs Review (Proofs)',
                      '$pendingApproval',
                      Icons.pending_actions_rounded,
                      const Color(0xFF00B0FF),
                      highlight: pendingApproval > 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOverviewCard(
                      'Waiting Seller',
                      '$pendingSeller',
                      Icons.hourglass_top_rounded,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOverviewCard(
                      'Approved',
                      '$approved',
                      Icons.check_circle_rounded,
                      const Color(0xFF00E676),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOverviewCard(
                      'Diamonds Credited',
                      '💎 $totalDiamonds',
                      Icons.diamond_rounded,
                      const Color(0xFFBB86FC),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    String label,
    String value,
    IconData icon,
    Color iconColor, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: highlight
            ? iconColor.withValues(alpha: 0.12)
            : const Color(0xFF222B38).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? iconColor.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 24),
              if (highlight)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 750;

        final searchBar = TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: (value) => setState(() => _applyFilters()),
          decoration: InputDecoration(
            hintText: 'Search by User/Seller Search ID, UID, Name, Bkash, Trx ID...',
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _applyFilters());
                    },
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF00B0FF)),
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: const Color(0xFF18202C),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
          ),
        );

        final filterTabs = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'All (${_withdrawals.length})', Icons.list_alt_rounded),
              const SizedBox(width: 8),
              _buildFilterChip(
                'pending_admin_approval',
                'Needs Review (${_statistics['pendingAdminApprovalCount'] ?? 0})',
                Icons.pending_actions_rounded,
                activeColor: const Color(0xFF00B0FF),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'pending',
                'Waiting Seller (${_statistics['pendingSellerCount'] ?? 0})',
                Icons.hourglass_top_rounded,
                activeColor: Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'approved',
                'Approved (${_statistics['approvedCount'] ?? 0})',
                Icons.check_circle_rounded,
                activeColor: const Color(0xFF00E676),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'rejected',
                'Rejected (${_statistics['rejectedCount'] ?? 0})',
                Icons.cancel_rounded,
                activeColor: const Color(0xFFFF5252),
              ),
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              searchBar,
              const SizedBox(height: 12),
              filterTabs,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: searchBar),
              ],
            ),
            const SizedBox(height: 12),
            filterTabs,
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon, {Color? activeColor}) {
    final isSelected = _selectedStatus == value;
    final color = activeColor ?? const Color(0xFF00B0FF);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = value;
          _applyFilters();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : const Color(0xFF18202C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? color : Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalCard(WithdrawalModel withdrawal) {
    final hasScreenshots = withdrawal.paymentScreenshots.isNotEmpty;
    final isPendingReview = withdrawal.status == WithdrawalStatus.pendingAdminApproval;
    final isPendingSeller = withdrawal.status == WithdrawalStatus.pending;
    final isApproved = withdrawal.status == WithdrawalStatus.approved;
    final isRejected = withdrawal.status == WithdrawalStatus.rejected;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161D27),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPendingReview
              ? const Color(0xFF00B0FF).withValues(alpha: 0.5)
              : withdrawal.statusColor.withValues(alpha: 0.25),
          width: isPendingReview ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: withdrawal.statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF263242),
                  child: Text(
                    withdrawal.username.isNotEmpty
                        ? withdrawal.username[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              withdrawal.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              withdrawal.userType,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (withdrawal.userSearchId != null &&
                              withdrawal.userSearchId!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B0FF).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: const Color(0xFF00B0FF).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.badge_rounded, size: 11, color: Color(0xFF00B0FF)),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Search ID: ${withdrawal.userSearchId}',
                                    style: const TextStyle(
                                      color: Color(0xFF00B0FF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => _copyToClipboard(
                                        withdrawal.userSearchId!, 'User Search ID'),
                                    child: const Icon(Icons.copy_rounded,
                                        size: 11, color: Color(0xFF00B0FF)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'UID: ${withdrawal.userId}',
                                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _copyToClipboard(withdrawal.userId, 'User ID'),
                                child: const Icon(Icons.copy_rounded, size: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: withdrawal.statusColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: withdrawal.statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isApproved
                            ? Icons.check_circle_rounded
                            : isRejected
                                ? Icons.cancel_rounded
                                : isPendingReview
                                    ? Icons.pending_actions_rounded
                                    : Icons.hourglass_top_rounded,
                        color: withdrawal.statusColor,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        withdrawal.statusDisplayName,
                        style: TextStyle(
                          color: withdrawal.statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seller Assignment info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2735),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded, color: Color(0xFFBB86FC), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              withdrawal.sellerName != null && withdrawal.sellerName!.isNotEmpty
                                  ? 'Assigned Seller: ${withdrawal.sellerName}'
                                  : 'Assigned Seller: N/A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (withdrawal.sellerSearchId != null &&
                                    withdrawal.sellerSearchId!.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFBB86FC).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.badge_rounded,
                                            size: 10, color: Color(0xFFBB86FC)),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Search ID: ${withdrawal.sellerSearchId}',
                                          style: const TextStyle(
                                            color: Color(0xFFE1BEE7),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        InkWell(
                                          onTap: () => _copyToClipboard(
                                              withdrawal.sellerSearchId!, 'Seller Search ID'),
                                          child: const Icon(Icons.copy_rounded,
                                              size: 10, color: Color(0xFFBB86FC)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (withdrawal.sellerId != null &&
                                    withdrawal.sellerId!.isNotEmpty) ...[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'UID: ${withdrawal.sellerId}',
                                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                      ),
                                      const SizedBox(width: 3),
                                      InkWell(
                                        onTap: () => _copyToClipboard(
                                            withdrawal.sellerId!, 'Seller UID'),
                                        child: const Icon(Icons.copy_rounded,
                                            size: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Diamond reward calculation indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBB86FC).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFBB86FC).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.diamond_rounded, color: Color(0xFFBB86FC), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '+${withdrawal.diamondReward} (${withdrawal.sellerDiamondPercent}%)',
                              style: const TextStyle(
                                color: Color(0xFFE1BEE7),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Financial Details & Target Account Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121720),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Withdrawal Amount',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          Row(
                            children: [
                              Text(
                                '${withdrawal.amount.toStringAsFixed(0)} Beans',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (withdrawal.usdAmount > 0) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '(\$${withdrawal.usdAmount.toStringAsFixed(2)})',
                                  style: const TextStyle(
                                    color: Color(0xFF00E676),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 18),
                      // Target Payment Bkash/Account Number
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Target Bkash / Phone',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2136E).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2136E).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_android_rounded,
                                    color: Color(0xFFE2136E), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  withdrawal.accountNumber.isNotEmpty
                                      ? withdrawal.accountNumber
                                      : 'N/A',
                                  style: const TextStyle(
                                    color: Color(0xFFFF4081),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (withdrawal.accountNumber.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _copyToClipboard(
                                        withdrawal.accountNumber, 'Bkash Number'),
                                    child: const Icon(
                                      Icons.copy_rounded,
                                      color: Color(0xFFE2136E),
                                      size: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (withdrawal.accountName != null &&
                          withdrawal.accountName!.isNotEmpty &&
                          withdrawal.accountName != withdrawal.username) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Account Name',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            Text(
                              withdrawal.accountName!,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      if (withdrawal.note != null && withdrawal.note!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'User Note',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                withdrawal.note!,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // SELLER PAYMENT PROOF / SCREENSHOT SECTION
                if (hasScreenshots) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B0FF).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF00B0FF).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.photo_library_rounded,
                                color: Color(0xFF00B0FF), size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Seller Payment Proof (Screenshots)',
                              style: TextStyle(
                                color: Color(0xFF00B0FF),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (withdrawal.proofSubmittedAt != null)
                              Text(
                                _formatDateTime(withdrawal.proofSubmittedAt!),
                                style: TextStyle(color: Colors.grey[400], fontSize: 11),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Horizontal Screenshots gallery
                        SizedBox(
                          height: 110,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: withdrawal.paymentScreenshots.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, idx) {
                              final imgUrl = withdrawal.paymentScreenshots[idx];
                              return Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF00B0FF).withValues(alpha: 0.4),
                                    width: 1.2,
                                  ),
                                  color: const Color(0xFF10141C),
                                ),
                                child: Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showImagePreview(context, imgUrl),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(9),
                                        child: kIsWeb
                                            ? buildWebImage(
                                                imgUrl,
                                                110,
                                                110,
                                                BoxFit.cover,
                                              )
                                            : Image.network(
                                                imgUrl,
                                                width: 110,
                                                height: 110,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, progress) {
                                                  if (progress == null) return child;
                                                  return const Center(
                                                    child: CircularProgressIndicator(
                                                      color: Color(0xFF00B0FF),
                                                      strokeWidth: 2,
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  color: Colors.black26,
                                                  child: const Center(
                                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                    // Zoom Button
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _showImagePreview(context, imgUrl),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black87,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.zoom_in_rounded,
                                              color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _showImagePreview(context, imgUrl),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black87,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.fullscreen_rounded,
                                              color: Color(0xFF00B0FF), size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        if (withdrawal.sellerNote != null &&
                            withdrawal.sellerNote!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.receipt_rounded,
                                    size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Seller Note / Trx ID: ${withdrawal.sellerNote}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _copyToClipboard(
                                      withdrawal.sellerNote!, 'Transaction ID / Note'),
                                  child: const Icon(Icons.copy_rounded,
                                      size: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else if (isPendingSeller) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Seller has not submitted payment proof screenshot yet.',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // APPROVED STATUS INFO
                if (isApproved) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00E676).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF00E676), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Approved by ${withdrawal.reviewedBy ?? 'Admin'}${withdrawal.reviewedAt != null ? ' on ${_formatDateTime(withdrawal.reviewedAt!)}' : ''}. Credited +${withdrawal.diamondReward} Diamonds (${withdrawal.sellerDiamondPercent}%) to seller.',
                            style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // REJECTED STATUS INFO
                if (isRejected &&
                    withdrawal.rejectionReason != null &&
                    withdrawal.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFFF5252), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Rejected: ${withdrawal.rejectionReason}. ${withdrawal.amount.toStringAsFixed(0)} Beans refunded to user wallet.',
                            style: const TextStyle(
                              color: Color(0xFFFF5252),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Requested Date footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Requested: ${_formatDateTime(withdrawal.createdAt)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                    Text(
                      'ID: ${withdrawal.id}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),

                // ACTION BUTTONS (For Pending & Pending Admin Approval)
                if (isPendingReview || isPendingSeller) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // APPROVE BUTTON
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmApproveWithdrawal(withdrawal),
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: Text(
                            'Approve & Credit ${withdrawal.sellerDiamondPercent}% Diamonds (+${withdrawal.diamondReward} 💎)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // REJECT BUTTON
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => _showRejectDialog(withdrawal),
                          icon: const Icon(Icons.cancel_rounded, size: 18),
                          label: const Text(
                            'Reject & Refund',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5252),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmApproveWithdrawal(WithdrawalModel withdrawal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2633),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF00E676)),
            SizedBox(width: 10),
            Text(
              'Approve Withdrawal',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you have verified the seller payment screenshot and want to approve this withdrawal?',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildDialogRow('User:', withdrawal.username),
                    if (withdrawal.userSearchId != null && withdrawal.userSearchId!.isNotEmpty)
                      _buildDialogRow('User Search ID:', withdrawal.userSearchId!),
                    _buildDialogRow('Withdraw Amount:', '${withdrawal.amount.toStringAsFixed(0)} Beans'),
                    _buildDialogRow('Target Bkash / Phone:', withdrawal.accountNumber),
                    _buildDialogRow('Assigned Seller:', withdrawal.sellerName ?? 'N/A'),
                    if (withdrawal.sellerSearchId != null && withdrawal.sellerSearchId!.isNotEmpty)
                      _buildDialogRow('Seller Search ID:', withdrawal.sellerSearchId!),
                    const Divider(color: Colors.white12, height: 16),
                    _buildDialogRow(
                      'Seller ${withdrawal.sellerDiamondPercent}% Reward:',
                      '+${withdrawal.diamondReward} Diamonds 💎',
                      valueColor: const Color(0xFF00E676),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '⚡ Approving will automatically credit +${withdrawal.sellerDiamondPercent}% Diamonds to the seller\'s account wallet and mark this withdrawal as complete.',
                style: const TextStyle(color: Color(0xFF00B0FF), fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeApprove(withdrawal);
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Confirm & Credit Diamonds'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeApprove(WithdrawalModel withdrawal) async {
    final adminId = AuthService.currentUser?.uid ?? 'admin';

    final success = await WithdrawalService.approveWithdrawal(
      withdrawalId: withdrawal.id,
      adminId: adminId,
    );

    if (!mounted) return;
    if (success) {
      _showSnackBar(
        'Withdrawal approved! +${withdrawal.diamondReward} Diamonds credited to seller.',
        const Color(0xFF00E676),
      );
      _loadData();
    } else {
      _showSnackBar('Failed to approve withdrawal', Colors.red);
    }
  }

  void _showRejectDialog(WithdrawalModel withdrawal) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2633),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Color(0xFFFF5252)),
            SizedBox(width: 10),
            Text(
              'Reject Withdrawal & Refund Beans',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rejecting withdrawal of ${withdrawal.amount.toStringAsFixed(0)} beans for ${withdrawal.username}. The beans will be refunded back to the user\'s wallet.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Rejection Reason (ইউজার ও সেলার দেখতে পাবে)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'e.g. Invalid payment screenshot, incorrect amount sent...',
                  hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFF5252)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF161D27),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                _showSnackBar('Please enter a rejection reason', Colors.orange);
                return;
              }

              Navigator.pop(context);
              final adminId = AuthService.currentUser?.uid ?? 'admin';

              final success = await WithdrawalService.rejectWithdrawal(
                withdrawalId: withdrawal.id,
                adminId: adminId,
                reason: reason,
              );

              if (!mounted) return;
              if (success) {
                _showSnackBar(
                  'Withdrawal rejected & ${withdrawal.amount.toStringAsFixed(0)} beans refunded to user.',
                  Colors.orange,
                );
                _loadData();
              } else {
                _showSnackBar('Failed to reject withdrawal', Colors.red);
              }
            },
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Reject & Refund Beans'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: Colors.grey[700], size: 64),
            const SizedBox(height: 16),
            const Text(
              'No withdrawal requests match the selected filter',
              style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

