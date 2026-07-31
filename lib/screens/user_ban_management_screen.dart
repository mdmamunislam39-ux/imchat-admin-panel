import 'package:flutter/material.dart';
import '../models/ban_model.dart';
import '../services/ban_service.dart';
import '../services/firebase_data_service.dart';
import '../widgets/media_preview_widget.dart';
import 'package:intl/intl.dart';

class UserBanManagementScreen extends StatefulWidget {
  const UserBanManagementScreen({super.key});

  @override
  State<UserBanManagementScreen> createState() => _UserBanManagementScreenState();
}

class _UserBanManagementScreenState extends State<UserBanManagementScreen> {
  bool _isLoading = true;
  
  // Bans Data
  List<BanModel> _activeBans = [];
  String _banSearchQuery = '';
  final TextEditingController _banSearchController = TextEditingController();

  // Users Data
  List<Map<String, dynamic>> _allUsers = [];
  String _userSearchQuery = '';
  final TextEditingController _userSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _banSearchController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final bans = await BanService.getAllBans();
      
      List<Map<String, dynamic>> usersData = _allUsers;
      if (usersData.isEmpty) {
        usersData = await FirebaseDataService.getAllUsers();
      }
      
      if (mounted) {
        setState(() {
          _activeBans = bans.where((b) => b.isActive).toList();
          _allUsers = usersData;
        });
      }
    } catch (e) {
      debugPrint('Error loading ban screen data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showBanDialog({String? initialTargetId}) {
    String targetId = initialTargetId ?? '';
    BanType selectedType = BanType.login;
    String reason = '';
    bool isPermanent = false;
    DateTime? selectedExpiryDate = DateTime.now().add(const Duration(days: 1));
    
    final targetIdController = TextEditingController(text: targetId);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Apply Ban', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<BanType>(
                      initialValue: selectedType,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Ban Type',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                      items: BanType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: targetIdController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: selectedType == BanType.device ? 'Device ID' : (selectedType == BanType.room ? 'Room ID' : 'User ID / Phone'),
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                      onChanged: (val) => targetId = val,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Reason',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                      onChanged: (val) => reason = val,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Permanent Ban', style: TextStyle(color: Colors.white)),
                      value: isPermanent,
                      onChanged: (val) {
                        setDialogState(() => isPermanent = val);
                      },
                    ),
                    if (!isPermanent) ...[
                      const SizedBox(height: 16),
                      ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        tileColor: Colors.grey[800],
                        title: const Text('Expiration Date & Time', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        subtitle: Text(
                          selectedExpiryDate == null 
                            ? 'Not Set' 
                            : selectedExpiryDate.toString().substring(0, 16),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        trailing: const Icon(Icons.calendar_today, color: Colors.blue),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: builderContext,
                            initialDate: selectedExpiryDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                          );
                          if (date != null && builderContext.mounted) {
                            final time = await showTimePicker(
                              context: builderContext,
                              initialTime: TimeOfDay.fromDateTime(selectedExpiryDate ?? DateTime.now()),
                            );
                            if (time != null) {
                              setDialogState(() {
                                selectedExpiryDate = DateTime(
                                  date.year, date.month, date.day,
                                  time.hour, time.minute,
                                );
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    if (targetId.trim().isEmpty) return;

                    final newBan = BanModel(
                      id: '', // Generated by Firestore
                      targetId: targetId.trim(),
                      type: selectedType,
                      reason: reason.trim(),
                      issuedAt: DateTime.now(),
                      expiresAt: isPermanent ? null : selectedExpiryDate,
                      issuedBy: 'Admin', // In real app, fetch admin ID
                      isPermanent: isPermanent,
                    );

                    Navigator.pop(dialogContext);
                    setState(() => _isLoading = true);
                    final success = await BanService.applyBan(newBan);
                    if (success) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ban applied successfully'), backgroundColor: Colors.green),
                        );
                        _loadData();
                      }
                    } else {
                      if (mounted) {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to apply ban'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Apply Ban'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _revokeBan(BanModel ban) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Revoke Ban', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to revoke this ban? Access will be instantly restored.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await BanService.revokeBan(ban);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ban revoked successfully'), backgroundColor: Colors.green),
          );
        }
        _loadData();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to revoke ban'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ----- USERS TAB -----
  
  List<Map<String, dynamic>> get _filteredUsers {
    if (_userSearchQuery.isEmpty) return _allUsers;
    return _allUsers.where((user) {
      final name = (user['fullname'] ?? user['username'] ?? '').toString().toLowerCase();
      final number = (user['number'] ?? '').toString().toLowerCase();
      final docId = (user['id'] ?? user['userId'] ?? '').toString().toLowerCase();
      final searchId = (user['searchId'] ?? user['imchatId'] ?? '').toString().toLowerCase();
      final query = _userSearchQuery.toLowerCase();
      return name.contains(query) || number.contains(query) || docId.contains(query) || searchId.contains(query);
    }).toList();
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        _buildSearchBar(
          controller: _userSearchController,
          hint: 'Search Users by Name or ID...',
          onChanged: (val) => setState(() => _userSearchQuery = val),
        ),
        Expanded(
          child: _filteredUsers.isEmpty
              ? const Center(child: Text('No users found.', style: TextStyle(color: Colors.grey, fontSize: 18)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return _buildUserCard(user);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userId = user['id'] ?? user['userId'] ?? '';
    final fullName = user['fullname'] ?? user['username'] ?? 'Unknown User';
    final number = user['number'] ?? 'No number';
    final photoUrl = user['photoUrl'] ?? user['profileImageUrl'];
    final diamonds = (user['diamonds'] ?? user['totalDiamonds'] ?? 0).toString();
    final searchId = (user['searchId'] ?? user['imchatId'] ?? '').toString();
    final deviceName = (user['deviceName'] ?? user['device'] ?? user['deviceInfo'] ?? '').toString();
    
    // Level fetching logic based on data structure
    String level = '1';
    if (user['sendingLevel'] is Map) {
      level = user['sendingLevel']['level']?.toString() ?? '1';
    } else if (user['level'] != null) {
      level = user['level'].toString();
    }

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
          // Profile Picture
          photoUrl != null && photoUrl.toString().isNotEmpty
              ? MediaPreviewWidget(
                  url: photoUrl.toString(),
                  width: 50,
                  height: 50,
                  borderRadius: BorderRadius.circular(25),
                )
              : CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[800],
                  child: const Icon(Icons.person, color: Colors.white, size: 25),
                ),
          const SizedBox(width: 16),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $userId',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (searchId.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Search ID: $searchId',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (number != 'No number') ...[
                  const SizedBox(height: 2),
                  Text(
                    'Phone: $number',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
                if (deviceName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Device: $deviceName',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Lv. $level', style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.diamond, color: Colors.pink, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      diamonds,
                      style: const TextStyle(color: Colors.pink, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Ban Action Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.block, size: 16),
            label: const Text('Ban'),
            onPressed: () => _showBanDialog(initialTargetId: userId),
          ),
        ],
      ),
    );
  }

  // ----- BANS TAB -----
  
  List<BanModel> get _filteredBans {
    if (_banSearchQuery.isEmpty) return _activeBans;
    return _activeBans.where((ban) {
      return ban.targetId.toLowerCase().contains(_banSearchQuery.toLowerCase()) ||
             ban.reason.toLowerCase().contains(_banSearchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildBansTab() {
    return Column(
      children: [
        _buildSearchBar(
          controller: _banSearchController,
          hint: 'Search Active Bans by ID or Reason...',
          onChanged: (val) => setState(() => _banSearchQuery = val),
        ),
        Expanded(
          child: _filteredBans.isEmpty
              ? const Center(child: Text('No active bans found.', style: TextStyle(color: Colors.grey, fontSize: 18)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredBans.length,
                  itemBuilder: (context, index) {
                    final ban = _filteredBans[index];
                    return _buildBanCard(ban);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBanCard(BanModel ban) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    
    // Find the user details if available for this target ID
    final userMatch = _allUsers.where((u) => u['id'] == ban.targetId || u['userId'] == ban.targetId).firstOrNull;
    
    final userName = userMatch != null ? (userMatch['fullname'] ?? userMatch['username'] ?? 'Unknown User') : null;
    final photoUrl = userMatch != null ? (userMatch['photoUrl'] ?? userMatch['profileImageUrl']) : null;
    final diamonds = userMatch != null ? (userMatch['diamonds'] ?? userMatch['totalDiamonds'] ?? 0).toString() : null;
    final number = userMatch != null ? (userMatch['number'] ?? 'No number').toString() : null;
    final searchId = userMatch != null ? (userMatch['searchId'] ?? userMatch['imchatId'] ?? '').toString() : null;
    
    String? level;
    if (userMatch != null) {
      if (userMatch['sendingLevel'] is Map) {
        level = userMatch['sendingLevel']['level']?.toString() ?? '1';
      } else if (userMatch['level'] != null) {
        level = userMatch['level'].toString();
      } else {
        level = '1';
      }
    }
    
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    ban.type.name.toUpperCase(),
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _revokeBan(ban),
                  icon: const Icon(Icons.undo, color: Colors.green, size: 20),
                  label: const Text('Revoke', style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (userMatch != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  photoUrl != null && photoUrl.toString().isNotEmpty
                      ? MediaPreviewWidget(
                          url: photoUrl.toString(),
                          width: 50,
                          height: 50,
                          borderRadius: BorderRadius.circular(25),
                        )
                      : CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[800],
                          child: const Icon(Icons.person, color: Colors.white, size: 25),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName ?? 'Unknown User',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Target ID: ${ban.targetId}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        if (searchId != null && searchId.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Search ID: $searchId',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (number != null && number != 'No number') ...[
                          const SizedBox(height: 2),
                          Text(
                            'Phone: $number',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Lv. ${level ?? "1"}', style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.diamond, color: Colors.pink, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              diamonds ?? '0',
                              style: const TextStyle(color: Colors.pink, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Text(
                'Target ID: ${ban.targetId}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 12),
            Text(
              'Reason: ${ban.reason.isEmpty ? "N/A" : ban.reason}',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(color: Colors.grey),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Issued: ${dateFormat.format(ban.issuedAt)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  ban.isPermanent ? 'Expires: NEVER' : (ban.expiresAt != null ? 'Expires: ${dateFormat.format(ban.expiresAt!)}' : 'Expires: N/A'),
                  style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar({
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () => _showBanDialog(),
            backgroundColor: Colors.red,
            mini: true,
            tooltip: 'Custom Ban (ID)',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Ban Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.red,
            labelColor: Colors.red,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Search Users'),
              Tab(icon: Icon(Icons.block), text: 'Active Bans'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : TabBarView(
                children: [
                  _buildUsersTab(),
                  _buildBansTab(),
                ],
              ),
      ),
    );
  }
}
