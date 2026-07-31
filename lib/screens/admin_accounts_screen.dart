import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_auth_service.dart';
import '../widgets/base_screen.dart';

class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  final _firestore = FirebaseFirestore.instance;
  
  // Available modules/permissions for master admins
  final List<String> _availableModules = [
    'Users Management', 'Rooms Management', 'Gift Management',
    'Emoji Management', 'Diamonds Management', 'Reports Analytics',
    'Settings', 'Agency Management', 'Commission Management',
    'Seller Management', 'Store Management', 'Daily Check-in',
    'Market Management', 'Blocked Users', 'Ban Management',
    'Level System Management', 'Host Agency Management',
    'Event Management', 'Game Management', 'Feedback Management'
  ];

  @override
  Widget build(BuildContext context) {
    if (!AdminAuthService.isMainAdmin()) {
      return BaseScreen(
        title: 'Admin Accounts',
        body: const Center(
          child: Text('Access Denied. Only Main Admin can manage accounts.', 
            style: TextStyle(color: Colors.red, fontSize: 18)
          ),
        ),
      );
    }

    return BaseScreen(
      title: 'Admin Accounts',
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('web_admins').orderBy('createdAt', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isMain = data['role'] == 'main_admin';
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(data['email'] ?? 'No Email', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    isMain ? 'Main Admin' : 'Master Admin\nPermissions: ${List<String>.from(data['permissions'] ?? []).length}',
                    style: TextStyle(color: isMain ? Colors.blue : Colors.grey[400]),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => _showEditDialog(docs[index].id, data),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(null, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditDialog(String? docId, Map<String, dynamic>? data) {
    final isNew = docId == null;
    final isMain = data?['role'] == 'main_admin';
    
    final emailController = TextEditingController(text: data?['email']);
    final passwordController = TextEditingController(text: data?['password']);
    List<String> selectedPermissions = List<String>.from(data?['permissions'] ?? []);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                isNew ? 'Create Master Admin' : (isMain ? 'Edit Main Admin' : 'Edit Master Admin'),
                style: const TextStyle(color: Colors.white)
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Login Email', labelStyle: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: Colors.grey)),
                        obscureText: false,
                      ),
                      if (!isMain) ...[
                        const SizedBox(height: 24),
                        const Text('Permissions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _availableModules.map((module) {
                            final isSelected = selectedPermissions.contains(module);
                            return FilterChip(
                              label: Text(module, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                              selected: isSelected,
                              selectedColor: Colors.blue,
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    selectedPermissions.add(module);
                                  } else {
                                    selectedPermissions.remove(module);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        )
                      ]
                    ],
                  ),
                ),
              ),
              actions: [
                if (!isNew && !isMain)
                  TextButton(
                    onPressed: () async {
                      await _firestore.collection('web_admins').doc(docId).delete();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
                      return;
                    }
                    
                    final Map<String, dynamic> saveData = {
                      'email': emailController.text.trim(),
                      'password': passwordController.text.trim(),
                    };

                    if (!isMain) {
                      saveData['permissions'] = selectedPermissions;
                    }

                    if (isNew) {
                      saveData['role'] = 'master_admin';
                      saveData['createdAt'] = FieldValue.serverTimestamp();
                      await _firestore.collection('web_admins').add(saveData);
                    } else {
                      await _firestore.collection('web_admins').doc(docId).update(saveData);
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
