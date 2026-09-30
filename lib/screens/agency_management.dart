import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agency_model.dart';
import '../services/agency_service.dart';
import '../widgets/media_preview_widget.dart';
import 'agency_dashboard.dart';
import 'create_agency_screen.dart';
import 'agency_commission_tier_management.dart';

class AgencyManagement extends StatefulWidget {
  const AgencyManagement({super.key});

  @override
  State<AgencyManagement> createState() => _AgencyManagementState();
}

class _AgencyManagementState extends State<AgencyManagement> {
  List<AgencyModel> _agencies = [];
  bool _isLoading = true;
  String _searchQuery = '';
  StreamSubscription<List<AgencyModel>>? _agenciesSubscription;

  @override
  void initState() {
    super.initState();
    _startRealtimeListener();
  }

  @override
  void dispose() {
    _agenciesSubscription?.cancel();
    super.dispose();
  }

  void _startRealtimeListener() {
    _agenciesSubscription?.cancel();
    _agenciesSubscription = AgencyService.getAgenciesStream().listen(
      (agencies) {
        if (mounted) {
          setState(() {
            _agencies = agencies;
            _isLoading = false;
          });
        }
      },
      onError: (e) {
        debugPrint('Agency stream error: $e');
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  List<AgencyModel> get _filteredAgencies {
    if (_searchQuery.isEmpty) return _agencies;
    final q = _searchQuery.toLowerCase().trim();
    return _agencies.where((agency) {
      return agency.agencyName.toLowerCase().contains(q) ||
             agency.agencyIdNumber.toLowerCase().contains(q) ||
             agency.owner.name.toLowerCase().contains(q) ||
             agency.owner.email.toLowerCase().contains(q) ||
             agency.owner.phone.contains(q);
    }).toList();
  }

  void _openCommissionTiers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AgencyCommissionTierManagementScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Agency Management',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.military_tech_rounded, color: Colors.amber),
            tooltip: 'Level-Based Commission (লেভেল বেস কমিশন)',
            onPressed: _openCommissionTiers,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _startRealtimeListener,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildCommissionTiersBanner(),
          _buildSearchBar(),
          // Real-time live indicator
          _buildLiveIndicator(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _buildAgenciesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewAgency,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCommissionTiersBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Level-Based Commission (লেভেল বেস কমিশন)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Set diamond target thresholds, commission rates %, and weekly tier bonus rewards.',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _openCommissionTiers,
            icon: const Icon(Icons.tune_rounded, size: 14),
            label: const Text('Configure Tiers', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Live • ${_agencies.length} agencies',
            style: const TextStyle(color: Colors.green, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search agencies...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildAgenciesList() {
    final filteredAgencies = _filteredAgencies;

    if (filteredAgencies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No agencies found matching your search'
                  : 'No agencies found',
              style: const TextStyle(color: Colors.grey, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search criteria'
                  : 'Create your first agency to get started',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredAgencies.length,
      itemBuilder: (context, index) {
        final agency = filteredAgencies[index];
        return _buildAgencyCard(agency);
      },
    );
  }

  Widget _buildAgencyCard(AgencyModel agency) {
    final commissionPercent = (agency.commissionRate * 100).toStringAsFixed(1);
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: agency.isCommissionHeld
            ? const BorderSide(color: Colors.orange, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Agency Header ──────────────────────────────────────
            Row(
              children: [
                agency.logoUrl != null && agency.logoUrl!.isNotEmpty
                    ? MediaPreviewWidget(
                        url: agency.logoUrl!,
                        width: 50,
                        height: 50,
                        borderRadius: BorderRadius.circular(25),
                      )
                    : CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.blue[800],
                        child: const Icon(Icons.business, color: Colors.white, size: 24),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agency.agencyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${agency.agencyIdNumber}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(agency.isActive),
              ],
            ),

            const SizedBox(height: 14),

            // ── Owner Info (Real-time from Users collection) ────────
            _buildOwnerRow(agency),

            const SizedBox(height: 14),

            // ── Statistics Row ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Host count (real-time)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('hosts')
                        .where('agencyId', isEqualTo: agency.id)
                        .where('isActive', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData
                          ? snapshot.data!.docs.length
                          : agency.totalHosts;
                      return _buildStatItem('Hosts', '$count', Icons.people, Colors.blue);
                    },
                  ),
                  // Total commission earned
                  _buildStatItem(
                    'Earned',
                    agency.totalCommissionEarned.toStringAsFixed(0),
                    Icons.monetization_on,
                    Colors.green,
                  ),
                  // Commission rate
                  _buildStatItem(
                    'Rate',
                    '$commissionPercent%',
                    Icons.percent,
                    Colors.purple,
                  ),
                  // Commission hold status
                  _buildStatItem(
                    'Commission',
                    agency.isCommissionHeld ? 'HELD' : 'ACTIVE',
                    agency.isCommissionHeld ? Icons.pause_circle : Icons.play_circle,
                    agency.isCommissionHeld ? Colors.orange : Colors.teal,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Commission Hold Banner (if held) ────────────────────
            if (agency.isCommissionHeld)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Commission payouts are currently HELD by admin.',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            if (agency.isCommissionHeld) const SizedBox(height: 12),

            // ── Action Buttons ──────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  label: 'Dashboard',
                  icon: Icons.dashboard,
                  color: Colors.blue,
                  onTap: () => _viewAgencyDashboard(agency),
                ),
                _buildActionButton(
                  label: 'Edit',
                  icon: Icons.edit,
                  color: Colors.green,
                  onTap: () => _editAgency(agency),
                ),
                _buildActionButton(
                  label: 'Commission %',
                  icon: Icons.percent,
                  color: Colors.purple,
                  onTap: () => _showEditCommissionRateDialog(agency),
                ),
                _buildActionButton(
                  label: agency.isCommissionHeld ? 'Resume Pay' : 'Hold Pay',
                  icon: agency.isCommissionHeld ? Icons.play_arrow : Icons.pause,
                  color: agency.isCommissionHeld ? Colors.teal : Colors.orange,
                  onTap: () => _toggleCommissionHold(agency),
                ),
                _buildActionButton(
                  label: 'Delete',
                  icon: Icons.delete,
                  color: Colors.red,
                  onTap: () => _deleteAgency(agency),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerRow(AgencyModel agency) {
    if (agency.owner.userId == null || agency.owner.userId!.isEmpty) {
      final hasPhone = agency.owner.phone.isNotEmpty;
      final hasEmail = agency.owner.email.isNotEmpty;
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Owner: ${agency.owner.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (hasPhone || hasEmail) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (hasPhone) ...[
                    const Icon(Icons.phone_android_rounded, size: 13, color: Colors.greenAccent),
                    const SizedBox(width: 4),
                    Text(agency.owner.phone, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                  if (hasPhone && hasEmail) const SizedBox(width: 12),
                  if (hasEmail) ...[
                    const Icon(Icons.alternate_email_rounded, size: 13, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        agency.owner.email,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(agency.owner.userId)
          .snapshots(),
      builder: (context, snapshot) {
        String ownerName = agency.owner.name;
        String? ownerPhoto = agency.owner.profileImageUrl;
        String searchId = '';
        String ownerPhone = agency.owner.phone;
        String ownerEmail = agency.owner.email;

        if (snapshot.hasData && snapshot.data!.exists) {
          final ud = snapshot.data!.data() as Map<String, dynamic>;
          ownerName = ud['fullname'] ?? ud['name'] ?? ud['username'] ?? ownerName;
          ownerPhoto = ud['photoUrl'] ?? ud['profileImageUrl'] ?? ownerPhoto;
          searchId = ud['searchId']?.toString() ?? '';
          ownerPhone = (ud['number'] ?? ud['phone'] ?? ownerPhone).toString();
          ownerEmail = (ud['email'] ?? ud['googleEmail'] ?? ud['mail'] ?? ownerEmail).toString();
        }

        final hasPhone = ownerPhone.trim().isNotEmpty;
        final hasEmail = ownerEmail.trim().isNotEmpty;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owner Header Row
              Row(
                children: [
                  ownerPhoto != null && ownerPhoto.isNotEmpty
                      ? MediaPreviewWidget(
                          url: ownerPhoto,
                          width: 28,
                          height: 28,
                          borderRadius: BorderRadius.circular(14),
                        )
                      : const CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(0xFF3B82F6),
                          child: Icon(Icons.person, color: Colors.white, size: 16),
                        ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Owner: $ownerName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (searchId.isNotEmpty) ...[
                    const SizedBox(width: 6),
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
                          color: Colors.blueAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // Owner Contacts (Phone & Google / Email)
              Row(
                children: [
                  // Phone
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.phone_android_rounded, size: 14, color: Colors.greenAccent),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            hasPhone ? ownerPhone : 'No phone',
                            style: TextStyle(
                              color: hasPhone ? Colors.grey[200] : Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasPhone) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: ownerPhone));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Owner phone copied!'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Icon(Icons.copy_rounded, size: 12, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Google / Email
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            'G',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            hasEmail ? ownerEmail : 'No Google/email',
                            style: TextStyle(
                              color: hasEmail ? Colors.grey[200] : Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasEmail) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: ownerEmail));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Owner Google email copied!'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Icon(Icons.copy_rounded, size: 12, color: Colors.grey),
                          ),
                        ],
                      ],
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? Colors.green : Colors.red),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          color: isActive ? Colors.green : Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  // ── Dialog: Edit Commission Rate ───────────────────────────────────────────
  void _showEditCommissionRateDialog(AgencyModel agency) {
    final controller = TextEditingController(
      text: (agency.commissionRate * 100).toStringAsFixed(1),
    );
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Commission Rate',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                agency.agencyName,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter commission percentage (0–100):',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  suffixText: '%',
                  suffixStyle: const TextStyle(color: Colors.purple),
                  hintText: 'e.g. 10.0',
                  hintStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.purple),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Current rate: ${(agency.commissionRate * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              icon: isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save, size: 16),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: isSaving
                  ? null
                  : () async {
                      final parsed = double.tryParse(controller.text.trim());
                      if (parsed == null || parsed < 0 || parsed > 100) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid percentage (0–100)'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setD(() => isSaving = true);
                      final success = await AgencyService.updateCommissionRate(
                        agency.id,
                        parsed / 100,
                      );
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(success
                            ? 'Commission rate updated to ${parsed.toStringAsFixed(1)}%'
                            : 'Failed to update commission rate'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ));
                    },
            ),
          ],
        ),
      ),
    );
  }

  // ── Toggle Commission Hold ─────────────────────────────────────────────────
  void _toggleCommissionHold(AgencyModel agency) {
    final willHold = !agency.isCommissionHeld;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          willHold ? 'Hold Commission?' : 'Resume Commission?',
          style: TextStyle(
            color: willHold ? Colors.orange : Colors.teal,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          willHold
              ? 'This will PAUSE commission payouts for ${agency.agencyName}. The agency will not receive any commission until resumed.'
              : 'This will RESUME commission payouts for ${agency.agencyName}.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: Icon(willHold ? Icons.pause : Icons.play_arrow, size: 16),
            label: Text(willHold ? 'Hold' : 'Resume'),
            style: ElevatedButton.styleFrom(
              backgroundColor: willHold ? Colors.orange : Colors.teal,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await AgencyService.toggleCommissionHold(
                agency.id,
                hold: willHold,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(success
                    ? willHold
                        ? '${agency.agencyName} commission is now HELD'
                        : '${agency.agencyName} commission RESUMED'
                    : 'Failed to update commission hold'),
                backgroundColor: success
                    ? (willHold ? Colors.orange : Colors.teal)
                    : Colors.red,
              ));
            },
          ),
        ],
      ),
    );
  }

  // ── Existing Actions ───────────────────────────────────────────────────────
  void _viewAgencyDashboard(AgencyModel agency) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AgencyDashboard(agencyId: agency.id)),
    );
  }

  void _editAgency(AgencyModel agency) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: agency.agencyName);
    final idNumberController = TextEditingController(text: agency.agencyIdNumber);
    final logoController = TextEditingController(text: agency.logoUrl ?? '');
    bool isActive = agency.isActive;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Edit Agency Details',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Agency Name',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Name cannot be empty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: idNumberController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Agency ID Number',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'ID Number cannot be empty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: logoController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Logo URL',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Active Status', style: TextStyle(color: Colors.white)),
                      value: isActive,
                      onChanged: (val) => setStateDialog(() => isActive = val),
                      activeThumbColor: Colors.blue,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setStateDialog(() => isSaving = true);
                        try {
                          final updatedAgency = agency.copyWith(
                            agencyName: nameController.text.trim(),
                            agencyIdNumber: idNumberController.text.trim(),
                            logoUrl: logoController.text.trim(),
                            isActive: isActive,
                            updatedAt: DateTime.now(),
                          );
                          final success = await AgencyService.updateAgency(agency.id, updatedAgency);
                          if (success && agency.owner.userId != null && agency.owner.userId!.isNotEmpty && agency.agencyName != updatedAgency.agencyName) {
                            await FirebaseFirestore.instance.collection('Users').doc(agency.owner.userId).update({
                              'agencyName': updatedAgency.agencyName,
                            });
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(success ? 'Agency updated successfully!' : 'Failed to update agency.'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ));
                            if (success) Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Error updating: $e'),
                              backgroundColor: Colors.red,
                            ));
                          }
                        } finally {
                          setStateDialog(() => isSaving = false);
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: isSaving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteAgency(AgencyModel agency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Agency', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${agency.agencyName}? This action cannot be undone.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmDeleteAgency(agency);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAgency(AgencyModel agency) async {
    try {
      final success = await AgencyService.deleteAgency(agency.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? '${agency.agencyName} deleted successfully'
            : 'Failed to delete agency'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    } catch (e) {
      debugPrint('Error deleting agency: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error deleting agency: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _createNewAgency() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateAgencyScreen()),
    );
    // No need to call _loadAgencies() – real-time stream auto-updates
  }
}
