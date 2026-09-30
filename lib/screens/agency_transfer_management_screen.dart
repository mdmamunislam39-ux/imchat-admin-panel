import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agency_model.dart';
import '../services/agency_service.dart';
import '../services/admin_auth_service.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile_model.dart';

class AgencyTransferManagementScreen extends StatefulWidget {
  const AgencyTransferManagementScreen({super.key});

  @override
  State<AgencyTransferManagementScreen> createState() =>
      _AgencyTransferManagementScreenState();
}

class _AgencyTransferManagementScreenState
    extends State<AgencyTransferManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied: $text'),
        backgroundColor: const Color(0xFF6C5CE7),
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
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
              child: const Icon(Icons.published_with_changes_rounded, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agency Change & Transfer Approval',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Review host agency change requests & transfer management',
                  style: TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Manual Agency Transfer',
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF00E676)),
            onPressed: _showManualTransferDialog,
          ),
          const SizedBox(width: 8),
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
        stream: AgencyService.getTransferRequestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8E2DE2)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading transfer requests: ${snapshot.error}',
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

          // Calculate stats
          final pendingList = allRequests
              .where((r) => (r['status'] ?? 'pending').toString().toLowerCase() == 'pending')
              .toList();
          final approvedList = allRequests
              .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'approved')
              .toList();
          final rejectedList = allRequests
              .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'rejected')
              .toList();

          return Column(
            children: [
              // Top Stats Banner
              _buildStatsOverview(
                totalCount: allRequests.length,
                pendingCount: pendingList.length,
                approvedCount: approvedList.length,
                rejectedCount: rejectedList.length,
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

  List<Map<String, dynamic>> _filterRequests(List<Map<String, dynamic>> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((req) {
      final name = (req['userName'] ?? '').toString().toLowerCase();
      final searchId = (req['userSearchId'] ?? '').toString().toLowerCase();
      final userId = (req['userId'] ?? '').toString().toLowerCase();
      final curAgency = (req['currentAgencyName'] ?? '').toString().toLowerCase();
      final targetAgency = (req['targetAgencyName'] ?? '').toString().toLowerCase();
      final targetIdNum = (req['targetAgencyIdNumber'] ?? '').toString().toLowerCase();
      final reason = (req['reason'] ?? '').toString().toLowerCase();

      return name.contains(_searchQuery) ||
          searchId.contains(_searchQuery) ||
          userId.contains(_searchQuery) ||
          curAgency.contains(_searchQuery) ||
          targetAgency.contains(_searchQuery) ||
          targetIdNum.contains(_searchQuery) ||
          reason.contains(_searchQuery);
    }).toList();
  }

  Widget _buildStatsOverview({
    required int totalCount,
    required int pendingCount,
    required int approvedCount,
    required int rejectedCount,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1433),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF322659)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              label: 'Pending Requests',
              count: pendingCount,
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFFFFB300),
              isAlert: pendingCount > 0,
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFF322659)),
          Expanded(
            child: _buildStatItem(
              label: 'Approved',
              count: approvedCount,
              icon: Icons.verified_rounded,
              color: const Color(0xFF00E676),
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFF322659)),
          Expanded(
            child: _buildStatItem(
              label: 'Rejected',
              count: rejectedCount,
              icon: Icons.cancel_outlined,
              color: const Color(0xFFFF5252),
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFF322659)),
          Expanded(
            child: _buildStatItem(
              label: 'Total History',
              count: totalCount,
              icon: Icons.all_inclusive_rounded,
              color: const Color(0xFF6C5CE7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    bool isAlert = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (isAlert) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFB300),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1B1433),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF322659)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by User Name, UID, Search ID, Current Agency, Target Agency...',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showManualTransferDialog,
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Direct Transfer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(List<Map<String, dynamic>> requests, String tabType) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tabType == 'pending'
                  ? Icons.mark_email_read_rounded
                  : Icons.inbox_rounded,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 12),
            Text(
              tabType == 'pending'
                  ? 'No pending agency transfer requests!'
                  : 'No transfer records found',
              style: const TextStyle(color: Colors.white60, fontSize: 15),
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'No results match "$_searchQuery"',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final String requestId = request['requestId'] ?? '';
    final String status = (request['status'] ?? 'pending').toString().toLowerCase();
    final String userName = request['userName'] ?? 'Unknown Host';
    final String userSearchId = request['userSearchId'] ?? '';
    final String userId = request['userId'] ?? '';
    final String userPhotoUrl = request['userPhotoUrl'] ?? '';
    
    final String curAgencyName = request['currentAgencyName'] ?? 'None / Regular';
    final String curAgencyIdNumber = request['currentAgencyIdNumber'] ?? '';
    
    final String targetAgencyName = request['targetAgencyName'] ?? 'Target Agency';
    final String targetAgencyIdNumber = request['targetAgencyIdNumber'] ?? '';
    final String targetOwnerName = request['targetOwnerName'] ?? '';
    final String reason = request['reason'] ?? '';
    final String rejectionReason = request['rejectionReason'] ?? '';
    final String reviewedBy = request['reviewedBy'] ?? '';

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF00E676);
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'APPROVED';
        break;
      case 'rejected':
        statusColor = const Color(0xFFFF5252);
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'REJECTED';
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.remove_circle_outline;
        statusLabel = 'CANCELLED';
        break;
      default:
        statusColor = const Color(0xFFFFB300);
        statusIcon = Icons.hourglass_top_rounded;
        statusLabel = 'PENDING APPROVAL';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1433),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'pending'
              ? const Color(0xFFFFB300).withOpacity(0.4)
              : const Color(0xFF322659),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: User Info + Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.3),
                  backgroundImage: userPhotoUrl.isNotEmpty ? NetworkImage(userPhotoUrl) : null,
                  child: userPhotoUrl.isEmpty
                      ? const Icon(Icons.person_rounded, color: Colors.white70)
                      : null,
                ),
                const SizedBox(width: 14),
                // Name & SearchId
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.4)),
                            ),
                            child: const Text(
                              'HOST',
                              style: TextStyle(
                                color: Color(0xFFA29BFE),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'UID: ${userSearchId.isNotEmpty ? userSearchId : userId}',
                            style: const TextStyle(fontSize: 12, color: Colors.white60),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _copyToClipboard(
                              userSearchId.isNotEmpty ? userSearchId : userId,
                              'User ID',
                            ),
                            child: const Icon(Icons.copy_rounded, size: 14, color: Colors.white38),
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
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFF2D224D), height: 1),
            const SizedBox(height: 16),

            // Visual Transfer Route (Current Agency -> Target Agency)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF130E26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2D224D)),
              ),
              child: Row(
                children: [
                  // FROM: Current Agency
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.arrow_back_rounded, size: 12, color: Color(0xFFFF7675)),
                            SizedBox(width: 4),
                            Text(
                              'FROM (Current Agency)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF7675),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          curAgencyName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (curAgencyIdNumber.isNotEmpty)
                          Text(
                            'ID: $curAgencyIdNumber',
                            style: const TextStyle(fontSize: 11, color: Colors.white54),
                          ),
                      ],
                    ),
                  ),

                  // Transfer Arrow Indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.5)),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFFA29BFE), size: 18),
                  ),
                  const SizedBox(width: 14),

                  // TO: Target Agency
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF00E676)),
                            SizedBox(width: 4),
                            Text(
                              'TO (Target Agency)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00E676),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          targetAgencyName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00E676),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (targetAgencyIdNumber.isNotEmpty)
                          Text(
                            'ID: $targetAgencyIdNumber',
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        if (targetOwnerName.isNotEmpty)
                          Text(
                            'Owner: $targetOwnerName',
                            style: const TextStyle(fontSize: 10, color: Colors.white38),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Reason / Notes
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.comment_rounded, size: 14, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason: $reason',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Rejection reason (if rejected)
            if (status == 'rejected' && rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 14, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rejection Reason: $rejectionReason',
                        style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Bottom Info & Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Timestamp
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(
                      'Applied: ${_formatDateTime(request['createdAt'])}',
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                    if (reviewedBy.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• Reviewed: ${_formatDateTime(request['approvedAt'] ?? request['rejectedAt'])}',
                        style: const TextStyle(fontSize: 11, color: Colors.white38),
                      ),
                    ],
                  ],
                ),

                // Action buttons for Pending requests
                if (status == 'pending') ...[
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _confirmRejectDialog(request),
                        icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFFF5252)),
                        label: const Text('Reject', style: TextStyle(color: Color(0xFFFF5252))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFF5252)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _confirmApproveDialog(request),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Approve Transfer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  IconButton(
                    tooltip: 'Delete Log',
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 18),
                    onPressed: () => _confirmDeleteDialog(requestId),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Confirmation Dialogs
  // ==========================================

  Future<void> _confirmApproveDialog(Map<String, dynamic> request) async {
    final String requestId = request['requestId'] ?? '';
    final String userName = request['userName'] ?? 'Host';
    final String userSearchId = request['userSearchId'] ?? '';
    final String curAgency = request['currentAgencyName'] ?? 'Current Agency';
    final String targetAgency = request['targetAgencyName'] ?? 'New Agency';
    final String targetIdNum = request['targetAgencyIdNumber'] ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1433),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF00E676)),
            SizedBox(width: 8),
            Text('Approve Agency Transfer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to approve this agency transfer request?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF130E26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2D224D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Host: $userName (ID: $userSearchId)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('• From Agency: $curAgency', style: const TextStyle(color: Color(0xFFFF7675))),
                  const SizedBox(height: 4),
                  Text('• To Agency: $targetAgency ($targetIdNum)', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚡ Action Effect:\n1. User agencyId in Users collection will update to target agency.\n2. Host record will be updated or linked under the target agency.\n3. User will receive approval notification.',
              style: TextStyle(color: Colors.amberAccent, fontSize: 11, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('APPROVE TRANSFER', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      final currentAdminId = AdminAuthService.currentUserId ?? 'admin';
      await AgencyService.approveTransferRequest(
        requestId: requestId,
        adminId: currentAdminId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Agency transfer approved successfully!'),
            backgroundColor: Color(0xFF00E676),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error approving transfer: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _confirmRejectDialog(Map<String, dynamic> request) async {
    final String requestId = request['requestId'] ?? '';
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1433),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Color(0xFFFF5252)),
            SizedBox(width: 8),
            Text('Reject Agency Transfer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejecting this transfer request:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Contract period active, agency policy violation...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF130E26),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF2D224D)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF2D224D)),
                ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('REJECT REQUEST'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      final currentAdminId = AdminAuthService.currentUserId ?? 'admin';
      await AgencyService.rejectTransferRequest(
        requestId: requestId,
        adminId: currentAdminId,
        rejectionReason: reasonController.text.trim().isNotEmpty
            ? reasonController.text.trim()
            : 'Rejected by admin',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agency transfer request rejected.'),
            backgroundColor: Color(0xFFFF5252),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error rejecting transfer: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteDialog(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1433),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Transfer Log', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to remove this transfer record from history?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AgencyService.deleteTransferRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log deleted successfully')),
        );
      }
    }
  }

  // ==========================================
  // Manual / Direct Agency Transfer Dialog
  // ==========================================

  void _showManualTransferDialog() {
    final searchUserCtrl = TextEditingController();
    final searchAgencyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    UserProfileModel? selectedUser;
    AgencyModel? selectedAgency;
    bool isSearchingUser = false;
    bool isSearchingAgency = false;
    String? userError;
    String? agencyError;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1B1433),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.swap_horizontal_circle_rounded, color: Color(0xFF6C5CE7)),
                  SizedBox(width: 10),
                  Text(
                    'Direct Host Agency Transfer',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Directly move any user or host into a target agency without needing them to send a request.',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 18),

                      // Step 1: Select User
                      const Text(
                        '1. Find User / Host (Search by UID / Search ID):',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchUserCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Enter User UID or Search ID...',
                                hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                                filled: true,
                                fillColor: const Color(0xFF130E26),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5CE7),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onPressed: isSearchingUser
                                ? null
                                : () async {
                                    final query = searchUserCtrl.text.trim();
                                    if (query.isEmpty) return;
                                    setModalState(() {
                                      isSearchingUser = true;
                                      userError = null;
                                      selectedUser = null;
                                    });

                                    try {
                                      final user = await UserProfileService.findUserBySearchIdOrUid(query);
                                      setModalState(() {
                                        isSearchingUser = false;
                                        if (user == null) {
                                          userError = 'No user found for "$query"';
                                        } else {
                                          selectedUser = user;
                                        }
                                      });
                                    } catch (e) {
                                      setModalState(() {
                                        isSearchingUser = false;
                                        userError = 'Search failed: $e';
                                      });
                                    }
                                  },
                            child: isSearchingUser
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Find User'),
                          ),
                        ],
                      ),

                      if (userError != null) ...[
                        const SizedBox(height: 6),
                        Text(userError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ],

                      if (selectedUser != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: (selectedUser!.profileImageUrl != null &&
                                        selectedUser!.profileImageUrl!.isNotEmpty)
                                    ? NetworkImage(selectedUser!.profileImageUrl!)
                                    : null,
                                child: (selectedUser!.profileImageUrl == null ||
                                        selectedUser!.profileImageUrl!.isEmpty)
                                    ? const Icon(Icons.person, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedUser!.username,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'UID: ${(selectedUser!.searchId != null && selectedUser!.searchId!.isNotEmpty) ? selectedUser!.searchId! : selectedUser!.userId} | Current Agency: ${selectedUser!.agencyName ?? "None"}',
                                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 20),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Step 2: Select Target Agency
                      const Text(
                        '2. Find Target Agency (Search by Agency ID or Name):',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchAgencyCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Enter Agency ID Number (e.g. 10001) or Name...',
                                hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                                filled: true,
                                fillColor: const Color(0xFF130E26),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E676),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onPressed: isSearchingAgency
                                ? null
                                : () async {
                                    final query = searchAgencyCtrl.text.trim().toLowerCase();
                                    if (query.isEmpty) return;
                                    setModalState(() {
                                      isSearchingAgency = true;
                                      agencyError = null;
                                      selectedAgency = null;
                                    });

                                    try {
                                      final agencies = await AgencyService.getAllAgencies();
                                      // 1. Exact match on agencyIdNumber
                                      AgencyModel? found = agencies.cast<AgencyModel?>().firstWhere(
                                            (a) => a?.agencyIdNumber.toLowerCase() == query,
                                            orElse: () => null,
                                          );

                                      // 2. Exact match on document id
                                      found ??= agencies.cast<AgencyModel?>().firstWhere(
                                            (a) => a?.id.toLowerCase() == query,
                                            orElse: () => null,
                                          );

                                      // 3. Exact match on agencyName
                                      found ??= agencies.cast<AgencyModel?>().firstWhere(
                                            (a) => a?.agencyName.trim().toLowerCase() == query,
                                            orElse: () => null,
                                          );

                                      // 4. Starts with agencyName
                                      found ??= agencies.cast<AgencyModel?>().firstWhere(
                                            (a) => a?.agencyName.trim().toLowerCase().startsWith(query) ?? false,
                                            orElse: () => null,
                                          );

                                      // 5. Contains agencyName
                                      found ??= agencies.cast<AgencyModel?>().firstWhere(
                                            (a) => a?.agencyName.toLowerCase().contains(query) ?? false,
                                            orElse: () => null,
                                          );

                                      setModalState(() {
                                        isSearchingAgency = false;
                                        if (found != null) {
                                          selectedAgency = found;
                                        } else {
                                          agencyError = 'No agency found for "$query". Please check the ID or name.';
                                        }
                                      });
                                    } catch (e) {
                                      setModalState(() {
                                        isSearchingAgency = false;
                                        agencyError = 'Search error: $e';
                                      });
                                    }
                                  },
                            child: isSearchingAgency
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Text('Find Agency', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),

                      if (agencyError != null) ...[
                        const SizedBox(height: 6),
                        Text(agencyError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ],

                      if (selectedAgency != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00E676).withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF00E676),
                                backgroundImage: (selectedAgency!.logoUrl != null && selectedAgency!.logoUrl!.isNotEmpty)
                                    ? NetworkImage(selectedAgency!.logoUrl!)
                                    : null,
                                child: (selectedAgency!.logoUrl == null || selectedAgency!.logoUrl!.isEmpty)
                                    ? const Icon(Icons.business_rounded, color: Colors.black, size: 22)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedAgency!.agencyName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'ID: ${selectedAgency!.agencyIdNumber.isNotEmpty ? selectedAgency!.agencyIdNumber : selectedAgency!.id}  |  Owner: ${selectedAgency!.owner.name.isNotEmpty ? selectedAgency!.owner.name : selectedAgency!.ownerUserId}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 22),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Text(
                        '3. Transfer Notes (Optional):',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: reasonCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g. Direct Admin Assignment / Transferred per user request',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF130E26),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: (selectedUser == null || selectedAgency == null || isSubmitting)
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(dialogCtx);
                          try {
                            final currentAdminId = AdminAuthService.currentUserId ?? 'admin';
                            final sUser = selectedUser!;
                            final sAgency = selectedAgency!;
                            final searchIdVal = (sUser.searchId != null && sUser.searchId!.isNotEmpty)
                                ? sUser.searchId!
                                : sUser.userId;

                            await AgencyService.manualTransferHost(
                              userId: sUser.userId,
                              userName: sUser.username,
                              userSearchId: searchIdVal,
                              userPhotoUrl: sUser.profileImageUrl ?? '',
                              currentAgencyId: sUser.agencyId ?? '',
                              currentAgencyName: sUser.agencyName ?? 'None',
                              targetAgency: sAgency,
                              adminId: currentAdminId,
                              reason: reasonCtrl.text.trim().isNotEmpty
                                  ? reasonCtrl.text.trim()
                                  : 'Direct Admin Transfer',
                            );

                            if (mounted) {
                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '✅ Successfully transferred ${sUser.username} to "${sAgency.agencyName}"',
                                  ),
                                  backgroundColor: const Color(0xFF00E676),
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('❌ Error: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Execute Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
