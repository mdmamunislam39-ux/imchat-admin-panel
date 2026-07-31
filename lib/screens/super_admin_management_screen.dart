import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_permission_model.dart';
import '../widgets/media_preview_widget.dart';
import '../services/admin_permission_service.dart';

class SuperAdminManagementScreen extends StatefulWidget {
  const SuperAdminManagementScreen({super.key});

  @override
  State<SuperAdminManagementScreen> createState() => _SuperAdminManagementScreenState();
}

class _SuperAdminManagementScreenState extends State<SuperAdminManagementScreen> {
  final _searchController = TextEditingController();
  
  Map<String, dynamic>? _selectedUser;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found!'))
        );
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e'))
        );
      }
    }
  }

  void _showAdminFormDialog(BuildContext context, {AdminPermissionModel? admin}) {
    bool isEditing = admin != null;
    
    // Initialize permissions map
    Map<String, bool> currentPermissions = {};
    for (var module in AdminPermissionService.availableModules) {
      currentPermissions[module] = isEditing ? admin.hasPermission(module) : false;
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
            title: Text(isEditing ? 'Edit Permissions' : 'Assign Super Admin', style: const TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isEditing) ...[
                    // Search Section
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'User ID',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search, color: Colors.blue),
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
                      stream: FirebaseFirestore.instance.collection('Users').doc(_selectedUser!['id']).snapshots(),
                      builder: (context, snapshot) {
                        String name = _selectedUser!['name'];
                        String imageUrl = _selectedUser!['imageUrl'] ?? '';
                        String phone = '';

                        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                          name = data['fullname'] ?? data['username'] ?? name;
                          imageUrl = data['profileImage'] ?? data['profileImageUrl'] ?? imageUrl;
                          phone = data['phone'] ?? data['phoneNumber'] ?? data['number'] ?? '';
                          
                          // Update the selectedUser map directly so the Save button uses the latest info
                          _selectedUser!['name'] = name;
                          _selectedUser!['imageUrl'] = imageUrl;
                        }

                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                          child: Row(
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
                                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    if (phone.isNotEmpty) Text('Phone: $phone', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Permissions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...AdminPermissionService.availableModules.map((module) {
                      return CheckboxListTile(
                        title: Text(module, style: const TextStyle(color: Colors.white70)),
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
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: _selectedUser != null ? () async {
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
                    
                    await AdminPermissionService.assignOrUpdateAdmin(newAdmin);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin saved successfully')));
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                } : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Save'),
              ),
            ],
          );
        }
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
        title: const Text('Super Admin Management'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdminFormDialog(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<AdminPermissionModel>>(
        stream: AdminPermissionService.getSuperAdminsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue));
          }

          final admins = snapshot.data ?? [];

          if (admins.isEmpty) {
            return const Center(
              child: Text('No super admins assigned yet.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('Users').doc(admin.userId).snapshots(),
                builder: (context, userSnapshot) {
                  String name = admin.userName;
                  String imageUrl = admin.userImageUrl;
                  String profileId = '';
                  String phone = '';

                  if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                    final data = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                    name = data['fullname'] ?? data['username'] ?? admin.userName;
                    imageUrl = data['profileImage'] ?? data['profileImageUrl'] ?? admin.userImageUrl;
                    profileId = data['searchId'] ?? '';
                    phone = data['phone'] ?? data['phoneNumber'] ?? data['number'] ?? '';
                  }

                  return Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    if (profileId.isNotEmpty) Text('ID: $profileId', style: TextStyle(color: Colors.grey[300], fontSize: 13)),
                                    if (phone.isNotEmpty) Text('Phone: $phone', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                    Text('UID: ${admin.userId}', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: admin.isActive,
                                onChanged: (val) => AdminPermissionService.toggleAdminStatus(admin.id, val),
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
                              .map((e) => Chip(
                                    label: Text(e.key, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                    backgroundColor: Colors.blue[900],
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showAdminFormDialog(context, admin: admin),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.grey[900],
                                  title: const Text('Remove Admin', style: TextStyle(color: Colors.white)),
                                  content: const Text('Are you sure you want to remove this super admin?', style: TextStyle(color: Colors.grey)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () {
                                        AdminPermissionService.deleteAdmin(admin.id);
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
              ); // Closes Card
            }, // Closes StreamBuilder<DocumentSnapshot> builder
          ); // Closes StreamBuilder<DocumentSnapshot>
        }, // Closes ListView.builder itemBuilder
      ); // Closes ListView.builder
    }, // Closes StreamBuilder<List<AdminPermissionModel>> builder
  ), // Closes StreamBuilder<List<AdminPermissionModel>>
); // Closes Scaffold
  }
}
