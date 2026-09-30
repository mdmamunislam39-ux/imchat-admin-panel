import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/seller_service.dart';
import '../services/admin_auth_service.dart';
import '../widgets/media_preview_widget.dart';

/// Admin Panel screen to review, approve, reject seller diamond top-up requests
/// and directly credit seller diamond balance with custom Admin Notes.
class SellerRequestsScreen extends StatefulWidget {
  const SellerRequestsScreen({super.key});

  @override
  State<SellerRequestsScreen> createState() => _SellerRequestsScreenState();
}

/// Backward compatibility alias
typedef AdminSellerRequestsScreen = SellerRequestsScreen;

class _SellerRequestsScreenState extends State<SellerRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _selectedPaymentMethodFilter = 'All';

  final List<String> _tabs = ['Pending', 'Approved', 'Rejected', 'All Requests'];
  final List<String> _paymentMethods = ['All', 'bKash', 'Nagad', 'Rocket', 'Bank Transfer', 'Other'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('$label copied: $text', style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: const Color(0xFF6C5CE7),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return 'N/A';
    }
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $ampm';
  }

  // --- Approval Dialog & Action ---
  Future<void> _approveRequest(Map<String, dynamic> request) async {
    final adminId = AdminAuthService.currentUserId ?? 'admin';
    final adminName = AdminAuthService.currentUserName ?? 'Admin';
    final String reqId = request['requestId'] ?? request['id'] ?? '';
    final String sellerId = request['sellerId'] ?? request['userId'] ?? '';
    final String sellerName = request['sellerName'] ?? request['userName'] ?? 'Seller';
    final String sellerSearchId = request['sellerSearchId'] ?? request['searchId'] ?? '';
    final int amount = (request['amount'] as num?)?.toInt() ?? 0;
    final String paymentMethod = request['paymentMethod'] ?? 'bKash';
    final String trxId = request['transactionId'] ?? '';

    final noteController = TextEditingController(
      text: 'Approved payment via $paymentMethod${trxId.isNotEmpty ? ' (TrxID: $trxId)' : ''}',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E142B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00E676), size: 24),
            SizedBox(width: 8),
            Text(
              'Approve Seller Top-Up',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1B3D),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seller: $sellerName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    if (sellerSearchId.isNotEmpty)
                      Text('Search ID: $sellerSearchId', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Diamonds to Credit: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const Icon(Icons.diamond_rounded, color: Colors.amberAccent, size: 18),
                        const SizedBox(width: 4),
                        Text('+$amount', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 17)),
                      ],
                    ),
                    if (trxId.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('TrxID: $trxId', style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
                    ],
                    if (paymentMethod.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Method: $paymentMethod', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('Admin Note (Saved in Seller Balance History):',
                  style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: noteController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF2A1B3D),
                  hintText: 'Enter note/remarks for seller...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B074),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('APPROVE & CREDIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
      ),
    );

    final success = await SellerService.approveSellerDiamondRequest(
      requestId: reqId,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerSearchId: sellerSearchId,
      amount: amount,
      adminId: adminId,
      adminName: adminName,
      adminNote: noteController.text.trim(),
      paymentMethod: paymentMethod,
      transactionId: trxId,
    );

    if (mounted) {
      Navigator.pop(context); // close loader
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Successfully approved and credited $amount diamonds to $sellerName!'),
            backgroundColor: const Color(0xFF00B074),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to approve request.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Rejection Dialog & Action ---
  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    final adminId = AdminAuthService.currentUserId ?? 'admin';
    final adminName = AdminAuthService.currentUserName ?? 'Admin';
    final String reqId = request['requestId'] ?? request['id'] ?? '';
    final String sellerName = request['sellerName'] ?? request['userName'] ?? 'Seller';

    final noteController = TextEditingController(text: 'Payment not received / Invalid Transaction ID');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E142B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text('Reject Top-Up Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject request from $sellerName?', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            const Text('Reason / Note for Seller:', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: noteController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2A1B3D),
                hintText: 'Enter rejection reason...',
                hintStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('REJECT REQUEST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await SellerService.rejectSellerDiamondRequest(
      requestId: reqId,
      adminId: adminId,
      adminName: adminName,
      rejectionReason: noteController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request marked as Rejected'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reject request'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Direct Credit Seller Dialog ---
  void _openDirectCreditDialog() {
    final searchController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController(text: 'Admin manual diamond top-up');
    Map<String, dynamic>? selectedUser;
    bool isSearching = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E142B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: Color(0xFF6C5CE7)),
                  SizedBox(width: 8),
                  Text('Direct Credit Seller Diamonds', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Search Seller by Search ID or User ID:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF2A1B3D),
                                hintText: 'Enter Search ID or UID',
                                hintStyle: const TextStyle(color: Colors.white38),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5CE7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: isSearching
                                ? null
                                : () async {
                                    final query = searchController.text.trim();
                                    if (query.isEmpty) return;
                                    setDialogState(() => isSearching = true);
                                    try {
                                      final snap = await _firestore
                                          .collection('Users')
                                          .where('searchId', isEqualTo: query)
                                          .limit(1)
                                          .get();
                                      if (snap.docs.isNotEmpty) {
                                        setDialogState(() {
                                          final data = snap.docs.first.data();
                                          data['userId'] = snap.docs.first.id;
                                          selectedUser = data;
                                          isSearching = false;
                                        });
                                      } else {
                                        final doc = await _firestore.collection('Users').doc(query).get();
                                        setDialogState(() {
                                          if (doc.exists) {
                                            final data = doc.data() ?? {};
                                            data['userId'] = doc.id;
                                            selectedUser = data;
                                          } else {
                                            selectedUser = null;
                                          }
                                          isSearching = false;
                                        });
                                      }
                                    } catch (e) {
                                      setDialogState(() => isSearching = false);
                                    }
                                  },
                            child: isSearching
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Search', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      if (selectedUser != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A1B3D),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              MediaPreviewWidget(
                                url: selectedUser!['photoUrl'] ?? selectedUser!['profilePicture'] ?? '',
                                width: 44,
                                height: 44,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(selectedUser!['fullname'] ?? selectedUser!['name'] ?? 'User',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('Search ID: ${selectedUser!['searchId'] ?? 'N/A'}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text('UID: ${selectedUser!['userId'] ?? selectedUser!['id'] ?? 'N/A'}',
                                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 22),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Diamond Amount to Add *',
                            labelStyle: const TextStyle(color: Color(0xFF6C5CE7)),
                            filled: true,
                            fillColor: const Color(0xFF2A1B3D),
                            prefixIcon: const Icon(Icons.diamond_rounded, color: Colors.amberAccent),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: noteController,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Admin Note (visible to seller)',
                            labelStyle: const TextStyle(color: Colors.amberAccent),
                            filled: true,
                            fillColor: const Color(0xFF2A1B3D),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                if (selectedUser != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B074),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final amt = int.tryParse(amountController.text.trim()) ?? 0;
                            if (amt <= 0) {
                              ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                const SnackBar(content: Text('Please enter valid diamond quantity'), backgroundColor: Colors.red),
                              );
                              return;
                            }

                            setDialogState(() => isSubmitting = true);

                            final adminId = AdminAuthService.currentUserId ?? 'admin';
                            final adminName = AdminAuthService.currentUserName ?? 'Admin';
                            final sId = selectedUser!['userId'] ?? selectedUser!['id'] ?? '';
                            final sName = selectedUser!['fullname'] ?? selectedUser!['name'] ?? 'Seller';
                            final sSearchId = selectedUser!['searchId'] ?? '';

                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(dialogCtx);

                            final success = await SellerService.directCreditSellerDiamonds(
                              sellerId: sId,
                              sellerName: sName,
                              sellerSearchId: sSearchId,
                              amount: amt,
                              adminId: adminId,
                              adminName: adminName,
                              adminNote: noteController.text.trim(),
                            );

                            nav.pop();

                            if (mounted) {
                              if (success) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('✅ Successfully loaded $amt diamonds to $sName!'),
                                    backgroundColor: const Color(0xFF00B074),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(content: Text('Failed to credit diamonds'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('CREDIT DIAMONDS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Screenshot Full Image Preview Modal ---
  void _showImagePreview(String imageUrl) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MediaPreviewWidget(
                  url: imageUrl,
                  width: 600,
                  height: 600,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1433),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.diamond_rounded, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seller Diamond Top-Up Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Review seller payment requests & direct diamond balance credit',
                  style: TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.add_circle_rounded, size: 18),
            label: const Text('Direct Credit Seller', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: _openDirectCreditDialog,
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6C5CE7),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.hourglass_top_rounded, size: 18), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle_rounded, size: 18), text: 'Approved'),
            Tab(icon: Icon(Icons.cancel_rounded, size: 18), text: 'Rejected'),
            Tab(icon: Icon(Icons.list_alt_rounded, size: 18), text: 'All Requests'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: SellerService.getSellerRequestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading requests: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];
          final allRequests = allDocs.map((d) {
            final map = Map<String, dynamic>.from(d.data());
            map['requestId'] = d.id;
            return map;
          }).toList();

          // Categorize lists
          final pendingList = allRequests
              .where((r) => (r['status'] ?? 'pending').toString().toLowerCase() == 'pending')
              .toList();
          final approvedList = allRequests
              .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'approved')
              .toList();
          final rejectedList = allRequests
              .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'rejected')
              .toList();

          int totalPendingDiamonds = 0;
          for (var r in pendingList) {
            totalPendingDiamonds += (r['amount'] as num?)?.toInt() ?? 0;
          }

          int totalApprovedDiamonds = 0;
          for (var r in approvedList) {
            totalApprovedDiamonds += (r['amount'] as num?)?.toInt() ?? 0;
          }

          return Column(
            children: [
              // Top Stats Banner
              _buildStatsOverview(
                totalCount: allRequests.length,
                pendingCount: pendingList.length,
                approvedCount: approvedList.length,
                rejectedCount: rejectedList.length,
                pendingDiamonds: totalPendingDiamonds,
                approvedDiamonds: totalApprovedDiamonds,
              ),

              // Search & Filter bar
              _buildSearchFilterBar(),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestsList(_filterRequests(pendingList), 'pending'),
                    _buildRequestsList(_filterRequests(approvedList), 'approved'),
                    _buildRequestsList(_filterRequests(rejectedList), 'rejected'),
                    _buildRequestsList(_filterRequests(allRequests), 'all'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Top Stats Banner ---
  Widget _buildStatsOverview({
    required int totalCount,
    required int pendingCount,
    required int approvedCount,
    required int rejectedCount,
    required int pendingDiamonds,
    required int approvedDiamonds,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF140D2B),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          return Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.start,
            children: [
              _buildStatCard(
                title: 'Total Requests',
                value: '$totalCount',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF6C5CE7),
                isWide: isWide,
              ),
              _buildStatCard(
                title: 'Pending Action',
                value: '$pendingCount',
                subValue: '$pendingDiamonds 💎',
                icon: Icons.hourglass_top_rounded,
                color: Colors.orangeAccent,
                isWide: isWide,
              ),
              _buildStatCard(
                title: 'Approved & Credited',
                value: '$approvedCount',
                subValue: '$approvedDiamonds 💎',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF00E676),
                isWide: isWide,
              ),
              _buildStatCard(
                title: 'Rejected',
                value: '$rejectedCount',
                icon: Icons.cancel_rounded,
                color: Colors.redAccent,
                isWide: isWide,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subValue,
    required IconData icon,
    required Color color,
    required bool isWide,
  }) {
    return Container(
      width: isWide ? 220 : 160,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1438),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                Row(
                  children: [
                    Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                    if (subValue != null) ...[
                      const SizedBox(width: 6),
                      Text(subValue, style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Search and Payment Method Filter ---
  Widget _buildSearchFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF140D2B),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by Seller Name, Search ID, TrxID, Phone Number, or UID...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white38),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1E1438),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Method Filter: ', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(width: 6),
                ..._paymentMethods.map((method) {
                  final isSelected = _selectedPaymentMethodFilter == method;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(method, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF6C5CE7),
                      backgroundColor: const Color(0xFF1E1438),
                      onSelected: (selected) {
                        setState(() {
                          _selectedPaymentMethodFilter = selected ? method : 'All';
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterRequests(List<Map<String, dynamic>> list) {
    return list.where((req) {
      // Payment method filter
      if (_selectedPaymentMethodFilter != 'All') {
        final pMethod = (req['paymentMethod'] ?? '').toString().toLowerCase();
        if (!pMethod.contains(_selectedPaymentMethodFilter.toLowerCase())) {
          return false;
        }
      }

      // Search query filter
      if (_searchQuery.isEmpty) return true;
      final name = (req['sellerName'] ?? req['userName'] ?? '').toString().toLowerCase();
      final sId = (req['sellerSearchId'] ?? req['searchId'] ?? '').toString().toLowerCase();
      final uId = (req['sellerId'] ?? req['userId'] ?? '').toString().toLowerCase();
      final trx = (req['transactionId'] ?? '').toString().toLowerCase();
      final phone = (req['senderNumber'] ?? req['phoneNumber'] ?? req['accountNumber'] ?? '').toString().toLowerCase();

      return name.contains(_searchQuery) ||
          sId.contains(_searchQuery) ||
          uId.contains(_searchQuery) ||
          trx.contains(_searchQuery) ||
          phone.contains(_searchQuery);
    }).toList();
  }

  // --- Requests List and Card Builder ---
  Widget _buildRequestsList(List<Map<String, dynamic>> requests, String tabType) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 14),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching requests found for "$_searchQuery"'
                  : 'No ${tabType.toUpperCase()} seller top-up requests',
              style: const TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final data = requests[index];
        return _buildRequestCard(data);
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> data) {
    final amount = (data['amount'] as num?)?.toInt() ?? 0;
    final sellerName = data['sellerName'] ?? data['userName'] ?? 'Seller';
    final sellerSearchId = data['sellerSearchId'] ?? data['searchId'] ?? '';
    final sellerId = data['sellerId'] ?? data['userId'] ?? '';
    final sellerPhoto = data['sellerPhoto'] ?? data['sellerPhotoUrl'] ?? data['photoUrl'] ?? '';
    final paymentMethod = data['paymentMethod'] ?? 'bKash';
    final trxId = data['transactionId'] ?? '';
    final senderNumber = data['senderNumber'] ?? data['phoneNumber'] ?? data['accountNumber'] ?? '';
    final screenshotUrl = data['screenshotUrl'] ?? data['screenshot'] ?? '';
    final sellerNote = data['note'] ?? data['sellerNote'] ?? '';
    final adminNote = data['adminNote'] ?? '';
    final processedBy = data['processedBy'] ?? '';
    final status = (data['status'] as String?)?.toLowerCase() ?? 'pending';
    final timestamp = data['createdAt'];

    Color statusColor = Colors.orangeAccent;
    if (status == 'approved') statusColor = const Color(0xFF00E676);
    if (status == 'rejected') statusColor = Colors.redAccent;

    // Payment method color badge
    Color methodColor = const Color(0xFF6C5CE7);
    final pLower = paymentMethod.toString().toLowerCase();
    if (pLower.contains('bkash')) methodColor = const Color(0xFFE2136E);
    if (pLower.contains('nagad')) methodColor = const Color(0xFFF7941D);
    if (pLower.contains('rocket')) methodColor = const Color(0xFF8C3494);
    if (pLower.contains('bank')) methodColor = const Color(0xFF1E88E5);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1433),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Search ID, Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MediaPreviewWidget(
                url: sellerPhoto,
                width: 46,
                height: 46,
                borderRadius: BorderRadius.circular(23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sellerName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (sellerSearchId.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A1B3D),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ID: $sellerSearchId',
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        if (sellerId.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _copyToClipboard(sellerId, 'UID'),
                            child: Text(
                              'UID: ${sellerId.length > 8 ? '${sellerId.substring(0, 8)}...' : sellerId}',
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const Divider(color: Colors.white12, height: 24),

          // Core details: Amount, Payment Method, TrxID, Sender phone
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Diamond Amount Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.diamond_rounded, color: Colors.amberAccent, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '+$amount',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Text('💎', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Payment Method Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: methodColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  paymentMethod,
                  style: TextStyle(color: methodColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Transaction ID & Sender Phone Number
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (trxId.toString().isNotEmpty)
                InkWell(
                  onTap: () => _copyToClipboard(trxId, 'TrxID'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1B3D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('TrxID: ', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(
                          trxId,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.copy_rounded, color: Colors.white54, size: 14),
                      ],
                    ),
                  ),
                ),
              if (senderNumber.toString().isNotEmpty)
                InkWell(
                  onTap: () => _copyToClipboard(senderNumber, 'Sender Number'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1B3D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Sender: ', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(
                          senderNumber,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.copy_rounded, color: Colors.white54, size: 14),
                      ],
                    ),
                  ),
                ),
              if (screenshotUrl.toString().isNotEmpty)
                InkWell(
                  onTap: () => _showImagePreview(screenshotUrl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_rounded, color: Colors.purpleAccent, size: 16),
                        SizedBox(width: 6),
                        Text('View Receipt Screenshot', style: TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Seller's Note
          if (sellerNote.toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1B3D).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                'Seller Note: $sellerNote',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],

          // Admin Note & Processed Details
          if (adminNote.toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1B3D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Note: $adminNote',
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                  ),
                  if (processedBy.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Processed by: $processedBy',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Footer: Timestamp & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Requested: ${_formatDateTime(timestamp)}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              if (status == 'pending')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _rejectRequest(data),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B074),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _approveRequest(data),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
