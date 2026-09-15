import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_permission_model.dart';
import '../widgets/media_preview_widget.dart';
import '../services/admin_permission_service.dart';

class SuperAdminManagementScreen extends StatefulWidget {
  const SuperAdminManagementScreen({super.key});

  @override
  State<SuperAdminManagementScreen> createState() =>
      _SuperAdminManagementScreenState();
}

class _SuperAdminManagementScreenState
    extends State<SuperAdminManagementScreen> {
  final _searchController = TextEditingController();
  final _historySearchController = TextEditingController();

  Map<String, dynamic>? _selectedUser;
  bool _isSearching = false;
  String _historySearchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _historySearchController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final searchId = _searchController.text.trim();
    if (searchId.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final user = await AdminPermissionService.searchUserByProfileId(searchId);
      setState(() {
        _selectedUser = user;
        _isSearching = false;
      });

      if (user == null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not found!')));
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    }
  }

  void _showAdminFormDialog(
    BuildContext context, {
    AdminPermissionModel? admin,
  }) {
    bool isEditing = admin != null;

    Map<String, bool> currentPermissions = {};
    for (var module in AdminPermissionService.availableModules) {
      currentPermissions[module] = isEditing
          ? admin.hasPermission(module)
          : false;
    }

    if (isEditing) {
      _selectedUser = {
        'id': admin.userId,
        'name': admin.userName,
        'imageUrl': admin.userImageUrl,
      };
    } else {
      _selectedUser = null;
      _searchController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              isEditing ? 'Edit Permissions' : 'Assign Super Admin',
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'User ID',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: _isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search, color: Colors.blue),
                          onPressed: () async {
                            setStateDialog(() => _isSearching = true);
                            await _searchUser();
                            setStateDialog(() => _isSearching = false);
                          },
                        ),
                      ],
                    ),
                  ],

                  if (_selectedUser != null) ...[
                    const SizedBox(height: 16),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Users')
                          .doc(_selectedUser!['id'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        String name = _selectedUser!['name'];
                        String imageUrl = _selectedUser!['imageUrl'] ?? '';
                        String phone = '';

                        if (snapshot.hasData &&
                            snapshot.data != null &&
                            snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>? ??
                              {};
                          name = data['fullname'] ?? data['username'] ?? name;
                          imageUrl =
                              data['profileImage'] ??
                              data['profileImageUrl'] ??
                              imageUrl;
                          phone =
                              data['phone'] ??
                              data['phoneNumber'] ??
                              data['number'] ??
                              '';

                          _selectedUser!['name'] = name;
                          _selectedUser!['imageUrl'] = imageUrl;
                        }

                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (Colors.grey[800] ?? Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              imageUrl.isNotEmpty
                                  ? MediaPreviewWidget(
                                      url: imageUrl,
                                      width: 40,
                                      height: 40,
                                      borderRadius: BorderRadius.circular(20),
                                    )
                                  : const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (phone.isNotEmpty)
                                      Text(
                                        'Phone: $phone',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Permissions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...AdminPermissionService.availableModules.map((module) {
                      return CheckboxListTile(
                        title: Text(
                          module,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        value: currentPermissions[module],
                        onChanged: (val) {
                          setStateDialog(() {
                            currentPermissions[module] = val ?? false;
                          });
                        },
                        activeColor: Colors.blue,
                        checkColor: Colors.white,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: _selectedUser != null
                    ? () async {
                        try {
                          final newAdmin = AdminPermissionModel(
                            id: admin?.id ?? '',
                            userId: _selectedUser!['id'],
                            userName: _selectedUser!['name'],
                            userImageUrl: _selectedUser!['imageUrl'] ?? '',
                            permissions: currentPermissions,
                            assignedAt: admin?.assignedAt ?? DateTime.now(),
                            isActive: admin?.isActive ?? true,
                          );

                          await AdminPermissionService.assignOrUpdateAdmin(
                            newAdmin,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Admin permissions saved & logged successfully!',
                                ),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Save'),
              ),
            ],
          );
        },
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
          title: const Text('Super Admin Management'),
          bottom: const TabBar(
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: [
              Tab(icon: Icon(Icons.admin_panel_settings), text: 'Super Admins'),
              Tab(
                icon: Icon(Icons.history_edu, color: Colors.blue),
                text: 'Assign History 📜',
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAdminFormDialog(context),
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add),
        ),
        body: TabBarView(
          children: [_buildSuperAdminsListTab(), _buildAssignHistoryTab()],
        ),
      ),
    );
  }

  // Tab 1: Super Admins List
  Widget _buildSuperAdminsListTab() {
    return StreamBuilder<List<AdminPermissionModel>>(
      stream: AdminPermissionService.getSuperAdminsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }

        final admins = snapshot.data ?? [];

        if (admins.isEmpty) {
          return const Center(
            child: Text(
              'No super admins assigned yet.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: admins.length,
          itemBuilder: (context, index) {
            final admin = admins[index];

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(admin.userId)
                  .snapshots(),
              builder: (context, userSnapshot) {
                String name = admin.userName;
                String imageUrl = admin.userImageUrl;
                String profileId = '';
                String phone = '';

                if (userSnapshot.hasData &&
                    userSnapshot.data != null &&
                    userSnapshot.data!.exists) {
                  final data =
                      userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                  name = data['fullname'] ?? data['username'] ?? admin.userName;
                  imageUrl =
                      data['profileImage'] ??
                      data['profileImageUrl'] ??
                      admin.userImageUrl;
                  profileId =
                      (data['searchId'] ??
                              data['user_id'] ??
                              data['shortId'] ??
                              '')
                          .toString();
                  phone =
                      data['phone'] ??
                      data['phoneNumber'] ??
                      data['number'] ??
                      '';
                }

                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            imageUrl.isNotEmpty
                                ? MediaPreviewWidget(
                                    url: imageUrl,
                                    width: 40,
                                    height: 40,
                                    borderRadius: BorderRadius.circular(20),
                                  )
                                : const CircleAvatar(child: Icon(Icons.person)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (profileId.isNotEmpty)
                                    Text(
                                      'ID: $profileId',
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 13,
                                      ),
                                    ),
                                  if (phone.isNotEmpty)
                                    Text(
                                      'Phone: $phone',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  Text(
                                    'UID: ${admin.userId}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: admin.isActive,
                              onChanged: (val) =>
                                  AdminPermissionService.toggleAdminStatus(
                                    admin.id,
                                    val,
                                  ),
                              activeThumbColor: Colors.blue,
                            ),
                          ],
                        ),
                        const Divider(color: Colors.grey),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: admin.permissions.entries
                                .where((e) => e.value)
                                .map(
                                  (e) => Chip(
                                    label: Text(
                                      e.key,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.blue[900],
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _showAdminFormDialog(context, admin: admin),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.grey[900],
                                    title: const Text(
                                      'Remove Admin',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: const Text(
                                      'Are you sure you want to remove this super admin?',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          AdminPermissionService.deleteAdmin(
                                            admin.id,
                                          );
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Helper Widget for rendering Super Admin or Target User Identity with Profile Photo & Search ID
  Widget _buildUserHistoryIdentity({
    required String userId,
    required String defaultName,
    required String label,
    required Color labelColor,
  }) {
    final bool isSuperAdminLabel = label.contains('Admin');

    if (isSuperAdminLabel) {
      return StreamBuilder<DocumentSnapshot>(
        stream: (userId.isNotEmpty &&
                userId != 'root' &&
                userId != 'admin' &&
                userId != 'unknown_admin' &&
                userId != 'Super Admin')
            ? FirebaseFirestore.instance.collection('Users').doc(userId).snapshots()
            : null,
        builder: (context, snapshot) {
          String name = defaultName;
          String photoUrl = '';
          String searchId = '';
          String phone = '';

          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            name = (data['fullname'] ?? data['name'] ?? data['username'] ?? defaultName).toString();
            photoUrl = (data['photoUrl'] ?? data['imageUrl'] ?? data['profileImage'] ?? data['profileImageUrl'] ?? '').toString();
            searchId = (data['searchId'] ?? data['user_id'] ?? data['shortId'] ?? data['numericId'] ?? data['id'] ?? '').toString();
            phone = (data['phone'] ?? data['phoneNumber'] ?? data['number'] ?? '').toString();
          }

          // If searchId or photo is missing, query Users collection for admin user profile
          if (searchId.isEmpty || photoUrl.isEmpty) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .where('userType', isEqualTo: 'admin')
                  .limit(1)
                  .snapshots(),
              builder: (context, adminSnap) {
                if (adminSnap.hasData && adminSnap.data != null && adminSnap.data!.docs.isNotEmpty) {
                  final adminDocData = adminSnap.data!.docs.first.data() as Map<String, dynamic>? ?? {};
                  final adminName = (adminDocData['fullname'] ?? adminDocData['name'] ?? adminDocData['username'] ?? name).toString();
                  final adminPhoto = (adminDocData['photoUrl'] ?? adminDocData['imageUrl'] ?? adminDocData['profileImage'] ?? adminDocData['profileImageUrl'] ?? photoUrl).toString();
                  final adminSearchId = (adminDocData['searchId'] ?? adminDocData['user_id'] ?? adminDocData['shortId'] ?? adminDocData['numericId'] ?? adminDocData['id'] ?? searchId).toString();
                  final adminPhone = (adminDocData['phone'] ?? adminDocData['phoneNumber'] ?? adminDocData['number'] ?? phone).toString();

                  return _renderIdentityCardRow(
                    label: label,
                    labelColor: labelColor,
                    name: adminName.isNotEmpty ? adminName : 'Super Admin',
                    photoUrl: adminPhoto,
                    searchId: adminSearchId,
                    phone: adminPhone,
                  );
                }

                return _renderIdentityCardRow(
                  label: label,
                  labelColor: labelColor,
                  name: name.isNotEmpty ? name : 'Super Admin',
                  photoUrl: photoUrl,
                  searchId: searchId,
                  phone: phone,
                );
              },
            );
          }

          return _renderIdentityCardRow(
            label: label,
            labelColor: labelColor,
            name: name,
            photoUrl: photoUrl,
            searchId: searchId,
            phone: phone,
          );
        },
      );
    }

    // Target User Identity Stream
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('Users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        String name = defaultName;
        String photoUrl = '';
        String searchId = '';
        String phone = '';

        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          name = (data['fullname'] ?? data['name'] ?? data['username'] ?? defaultName).toString();
          photoUrl = (data['photoUrl'] ?? data['imageUrl'] ?? data['profileImage'] ?? data['profileImageUrl'] ?? '').toString();
          searchId = (data['searchId'] ?? data['user_id'] ?? data['shortId'] ?? data['numericId'] ?? data['id'] ?? '').toString();
          phone = (data['phone'] ?? data['phoneNumber'] ?? data['number'] ?? '').toString();
        }

        return _renderIdentityCardRow(
          label: label,
          labelColor: labelColor,
          name: name.isNotEmpty ? name : 'User',
          photoUrl: photoUrl,
          searchId: searchId,
          phone: phone,
        );
      },
    );
  }

  Widget _renderIdentityCardRow({
    required String label,
    required Color labelColor,
    required String name,
    required String photoUrl,
    required String searchId,
    required String phone,
  }) {
    return Row(
      children: [
        photoUrl.isNotEmpty
            ? MediaPreviewWidget(
                url: photoUrl,
                width: 38,
                height: 38,
                borderRadius: BorderRadius.circular(19),
              )
            : CircleAvatar(
                radius: 19,
                backgroundColor: labelColor.withValues(alpha: 0.2),
                child: Icon(
                  label.contains('Admin') ? Icons.admin_panel_settings : Icons.person,
                  color: labelColor,
                  size: 20,
                ),
              ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                name.isNotEmpty ? name : (label.contains('Admin') ? 'Super Admin' : 'User'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  if (searchId.isNotEmpty)
                    Text(
                      'ID: $searchId ',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (phone.isNotEmpty)
                    Flexible(
                      child: Text(
                        '| $phone',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Tab 2: Assign History Log Tab (Combined Real-Time Audit Log)
  Widget _buildAssignHistoryTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('super_admin_assign_history')
          .snapshots(),
      builder: (context, historySnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('user_store_items')
              .snapshots(),
          builder: (context, storeItemsSnapshot) {
            if (historySnapshot.connectionState == ConnectionState.waiting &&
                storeItemsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              );
            }

            final historyDocs = historySnapshot.data?.docs ?? [];
            final storeDocs = storeItemsSnapshot.data?.docs ?? [];

            // Combine all assignment sources into unified log items
            final List<Map<String, dynamic>> allLogItems = [];

            // 1. Logs from super_admin_assign_history
            for (final doc in historyDocs) {
              final data = doc.data();
              allLogItems.add({
                'id': doc.id,
                'dateString': data['dateString'] ?? '',
                'timestamp':
                    (data['timestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                'assignedByAdminName':
                    data['assignedByAdminName'] ?? 'Super Admin',
                'assignedByAdminId': data['assignedByAdminId'] ?? '',
                'targetUserName': data['targetUserName'] ?? 'User',
                'targetUserId': data['targetUserId'] ?? '',
                'targetPhone': data['targetPhone'] ?? '',
                'actionType': data['actionType'] ?? 'Assigned Action',
                'assignedItems': data['assignedItems'] is List
                    ? List<String>.from(data['assignedItems'])
                    : <String>[],
                'details': data['details'] ?? '',
              });
            }

            // 2. Logs from user_store_items (Entry Effects, Frames, Vehicles, Badges, SVIP)
            for (final doc in storeDocs) {
              final data = doc.data();
              final assignedAtTs =
                  (data['assignedAt'] as Timestamp?)?.toDate() ??
                  DateTime.now();
              final dateFormatted =
                  "${assignedAtTs.year}-${assignedAtTs.month.toString().padLeft(2, '0')}-${assignedAtTs.day.toString().padLeft(2, '0')} ${assignedAtTs.hour.toString().padLeft(2, '0')}:${assignedAtTs.minute.toString().padLeft(2, '0')}";

              final itemName =
                  (data['storeItemName'] ?? data['name'] ?? 'Store Item')
                      .toString();
              final rawType = (data['itemType'] ?? data['type'] ?? 'Store Item')
                  .toString();
              String itemTypeFormatted = rawType;
              if (rawType.contains('entry') || rawType.contains('effect')) {
                itemTypeFormatted = 'Entry Effect 🌌';
              } else if (rawType.contains('frame')) {
                itemTypeFormatted = 'Avatar Frame 🖼️';
              } else if (rawType.contains('badge')) {
                itemTypeFormatted = 'Badge 🏅';
              } else if (rawType.contains('vehicle') ||
                  rawType.contains('ride')) {
                itemTypeFormatted = 'Ride Vehicle 🚗';
              }

              final targetUserId =
                  (data['userId'] ?? data['userProfileId'] ?? '').toString();
              final targetUserName =
                  (data['userName'] ?? data['userProfileId'] ?? targetUserId)
                      .toString();
              final adminId = (data['assignedBy'] ?? 'Super Admin').toString();

              allLogItems.add({
                'id': doc.id,
                'dateString': dateFormatted,
                'timestamp': assignedAtTs,
                'assignedByAdminName': 'Super Admin',
                'assignedByAdminId': adminId,
                'targetUserName': targetUserName,
                'targetUserId': targetUserId,
                'targetPhone': '',
                'actionType': 'Assigned Store Item ($itemTypeFormatted)',
                'assignedItems': [itemName],
                'details':
                    'Assigned $itemTypeFormatted: "$itemName" to $targetUserName',
              });
            }

            // Sort all log entries descending by date/time
            allLogItems.sort((a, b) {
              final DateTime dtA = a['timestamp'] is DateTime
                  ? a['timestamp'] as DateTime
                  : DateTime.now();
              final DateTime dtB = b['timestamp'] is DateTime
                  ? b['timestamp'] as DateTime
                  : DateTime.now();
              return dtB.compareTo(dtA);
            });

            // Filter by search query
            final filteredLogs = allLogItems.where((data) {
              if (_historySearchQuery.isEmpty) return true;
              final superAdminName = (data['assignedByAdminName'] ?? '')
                  .toString()
                  .toLowerCase();
              final targetUserName = (data['targetUserName'] ?? '')
                  .toString()
                  .toLowerCase();
              final targetUserId = (data['targetUserId'] ?? '')
                  .toString()
                  .toLowerCase();
              final actionType = (data['actionType'] ?? '')
                  .toString()
                  .toLowerCase();
              final items =
                  (data['assignedItems'] is List
                          ? (data['assignedItems'] as List).join(' ')
                          : '')
                      .toString()
                      .toLowerCase();

              final query = _historySearchQuery.toLowerCase();
              return superAdminName.contains(query) ||
                  targetUserName.contains(query) ||
                  targetUserId.contains(query) ||
                  actionType.contains(query) ||
                  items.contains(query);
            }).toList();

            return Column(
              children: [
                // Search Bar for Assign History
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _historySearchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:
                          'Search history by Super Admin, Target Name, User ID, or Feature...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.blue),
                      suffixIcon: _historySearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _historySearchController.clear();
                                setState(() => _historySearchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => _historySearchQuery = value.trim()),
                  ),
                ),

                // Summary Banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Total History Logs: ${allLogItems.length}',
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Real-time Audit Log',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // History List
                Expanded(
                  child: filteredLogs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_toggle_off,
                                size: 64,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _historySearchQuery.isEmpty
                                    ? 'No assign history recorded yet.'
                                    : 'No history found matching "$_historySearchQuery"',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredLogs.length,
                          itemBuilder: (context, index) {
                            final data = filteredLogs[index];

                            final dateString =
                                data['dateString']?.toString() ??
                                'Unknown Date';
                            final superAdminName =
                                data['assignedByAdminName']?.toString() ??
                                'Super Admin';
                            final superAdminId =
                                data['assignedByAdminId']?.toString() ?? '';
                            final targetUserName =
                                data['targetUserName']?.toString() ?? 'User';
                            final targetUserId =
                                data['targetUserId']?.toString() ?? '';
                            final actionType =
                                data['actionType']?.toString() ??
                                'Assigned Action';
                            final details = data['details']?.toString() ?? '';
                            final assignedItems = data['assignedItems'] is List
                                ? List<String>.from(data['assignedItems'])
                                : <String>[];

                            Color actionColor = Colors.blue;
                            if (actionType.contains('Removed') ||
                                actionType.contains('Deactivated')) {
                              actionColor = Colors.red;
                            } else if (actionType.contains('Activated') ||
                                actionType.contains('Assigned') ||
                                actionType.contains('Item')) {
                              actionColor = Colors.green;
                            }

                            return Card(
                              color: Colors.grey[900],
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: actionColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: Action Badge + Time
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: actionColor.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: actionColor,
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            actionType,
                                            style: TextStyle(
                                              color: actionColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              color: Colors.grey,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              dateString,
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Super Admin & Target User Identity Box
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color:
                                              (Colors.grey[800] ?? Colors.grey),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          // 1. Super Admin Manager Identity (Who Assigned)
                                          _buildUserHistoryIdentity(
                                            userId: superAdminId,
                                            defaultName: superAdminName,
                                            label: 'Super Admin Manager 🛡️',
                                            labelColor: Colors.blueAccent,
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Divider(
                                                    color: Colors.grey,
                                                    height: 1,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.arrow_downward,
                                                        color: Colors.blue,
                                                        size: 14,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Assigned Item To',
                                                        style: TextStyle(
                                                          color: Colors.blue,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Divider(
                                                    color: Colors.grey,
                                                    height: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // 2. Target User Identity (Who Received Assignment)
                                          _buildUserHistoryIdentity(
                                            userId: targetUserId,
                                            defaultName: targetUserName,
                                            label: 'Assigned Target User 👤',
                                            labelColor: Colors.greenAccent,
                                          ),
                                        ],
                                      ),
                                    ),

                                    if (details.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Note: $details',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],

                                    // Assigned Items Chips
                                    if (assignedItems.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Assigned Items / Features:',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: assignedItems
                                            .map(
                                              (item) => Chip(
                                                label: Text(
                                                  item,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    Colors.blue[900],
                                                padding: EdgeInsets.zero,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
