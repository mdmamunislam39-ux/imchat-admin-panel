import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/family_service.dart';
import '../widgets/media_preview_widget.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFamilySettingsDialog() {
    final formKey = GlobalKey<FormState>();
    final levelController = TextEditingController();
    final diamondsController = TextEditingController();
    final memberLimitController = TextEditingController();
    final List<TextEditingController> levelControllers = [];
    
    bool isLoading = true;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> loadSettings() async {
            try {
              final doc = await FirebaseFirestore.instance
                  .collection('system_configs')
                  .doc('family_settings')
                  .get();

              List<dynamic> reqs = [];
              if (doc.exists && doc.data() != null) {
                final data = doc.data()!;
                levelController.text = (data['requiredLevel'] ?? 1).toString();
                diamondsController.text = (data['requiredDiamonds'] ?? 100).toString();
                memberLimitController.text = (data['memberLimit'] ?? 50).toString();
                reqs = data['levelRequirements'] ?? [1000, 5000, 10000, 20000, 50000];
              } else {
                levelController.text = '1';
                diamondsController.text = '100';
                memberLimitController.text = '50';
                reqs = [1000, 5000, 10000, 20000, 50000];
              }

              levelControllers.clear();
              for (var val in reqs) {
                levelControllers.add(TextEditingController(text: val.toString()));
              }

              setStateDialog(() {
                isLoading = false;
              });
            } catch (e) {
              debugPrint('Error loading family settings in dialog: $e');
              setStateDialog(() {
                isLoading = false;
              });
            }
          }

          if (isLoading) {
            loadSettings();
          }

          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Row(
              children: [
                Icon(Icons.settings, color: Colors.blue),
                SizedBox(width: 8),
                Text('Family System Settings', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: isLoading
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator(color: Colors.blue)),
                  )
                : SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: levelController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Required User Level to Create Family',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Level is required';
                              if (int.tryParse(val) == null) return 'Enter a valid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: diamondsController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Required Diamonds to Create Family',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Diamonds amount is required';
                              if (int.tryParse(val) == null) return 'Enter a valid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: memberLimitController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Family Member Limit (Max members)',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Member limit is required';
                              if (int.tryParse(val) == null) return 'Enter a valid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 8),
                          const Text(
                            'Family Level Requirements (Diamonds)',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(levelControllers.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Text(
                                    'Lv.${index + 2} Req:',
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: levelControllers[index],
                                      style: const TextStyle(color: Colors.white),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: 'Diamonds to reach Lv.${index + 2}',
                                        hintStyle: const TextStyle(color: Colors.white24),
                                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) return 'Required';
                                        if (int.tryParse(val) == null) return 'Enter a number';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  setStateDialog(() {
                                    final lastVal = levelControllers.isNotEmpty
                                        ? int.tryParse(levelControllers.last.text) ?? 1000
                                        : 500;
                                    levelControllers.add(TextEditingController(text: (lastVal * 2).toString()));
                                  });
                                },
                                icon: const Icon(Icons.add, color: Colors.blue, size: 18),
                                label: const Text('Add Level', style: TextStyle(color: Colors.blue)),
                              ),
                              if (levelControllers.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () {
                                    setStateDialog(() {
                                      final controller = levelControllers.removeLast();
                                      controller.dispose();
                                    });
                                  },
                                  icon: const Icon(Icons.remove, color: Colors.red, size: 18),
                                  label: const Text('Remove Level', style: TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () {
                  for (var c in levelControllers) {
                    c.dispose();
                  }
                  Navigator.pop(context);
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: (isSaving || isLoading)
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setStateDialog(() => isSaving = true);

                        try {
                          final reqs = levelControllers.map((c) => int.parse(c.text.trim())).toList();
                          await FirebaseFirestore.instance
                              .collection('system_configs')
                              .doc('family_settings')
                              .set({
                            'requiredLevel': int.parse(levelController.text.trim()),
                            'requiredDiamonds': int.parse(diamondsController.text.trim()),
                            'memberLimit': int.parse(memberLimitController.text.trim()),
                            'levelRequirements': reqs,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                          if (context.mounted) {
                            for (var c in levelControllers) {
                              c.dispose();
                            }
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Family settings updated successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update settings: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          setStateDialog(() => isSaving = false);
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Settings'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditFamilyDialog(Map<String, dynamic> family) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: family['familyName']);
    final descriptionController = TextEditingController(text: family['description'] ?? '');
    final logoController = TextEditingController(text: family['logoUrl'] ?? '');
    final pointsController = TextEditingController(text: (family['points'] ?? 0).toString());
    final levelController = TextEditingController(text: (family['level'] ?? 1).toString());
    final memberLimitController = TextEditingController(text: (family['memberLimit'] ?? 50).toString());
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text('Edit Family: ${family['familyName']}', style: const TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Family Name',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: logoController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Logo URL',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: pointsController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Points',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      ),
                      validator: (val) => val == null || int.tryParse(val) == null ? 'Enter valid number' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: levelController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Level',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      ),
                      validator: (val) => val == null || int.tryParse(val) == null ? 'Enter valid number' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: memberLimitController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Member Limit',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      ),
                      validator: (val) => val == null || int.tryParse(val) == null ? 'Enter valid number' : null,
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

                        final success = await FamilyService.updateFamily(family['id'], {
                          'familyName': nameController.text.trim(),
                          'description': descriptionController.text.trim(),
                          'logoUrl': logoController.text.trim(),
                          'points': int.parse(pointsController.text.trim()),
                          'level': int.parse(levelController.text.trim()),
                          'memberLimit': int.parse(memberLimitController.text.trim()),
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Family updated successfully!' : 'Failed to update family.'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> family) {
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text('Dissolve: ${family['familyName']}', style: const TextStyle(color: Colors.white))),
              ],
            ),
            content: const Text(
              'Are you sure you want to permanently dissolve/delete this family? This will remove all members from the family and cannot be undone.',
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setStateDialog(() => isDeleting = true);

                        final success = await FamilyService.deleteFamily(family['id']);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Family dissolved successfully!' : 'Failed to dissolve family.'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: isDeleting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Dissolve Family'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showManageMembersDialog(Map<String, dynamic> family) {
    List<dynamic> memberIds = List.from(family['memberIds'] ?? []);
    bool isFetching = true;
    List<Map<String, dynamic>> membersDetails = [];
    final addMemberIdController = TextEditingController();
    bool isAdding = false;
    Map<String, dynamic>? searchedUser;
    bool isSearchingUser = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> fetchMembers() async {
            setStateDialog(() => isFetching = true);
            final details = await FamilyService.getFamilyMembers(memberIds);
            setStateDialog(() {
              membersDetails = details;
              isFetching = false;
            });
          }

          if (isFetching && membersDetails.isEmpty && memberIds.isNotEmpty) {
            fetchMembers();
          } else if (memberIds.isEmpty && isFetching) {
            isFetching = false;
          }

          Future<void> searchUserToAdd() async {
            final profileId = addMemberIdController.text.trim();
            if (profileId.isEmpty) return;

            setStateDialog(() {
              isSearchingUser = true;
              searchedUser = null;
            });

            final user = await FamilyService.searchUserByProfileId(profileId);

            setStateDialog(() {
              isSearchingUser = false;
              searchedUser = user;
            });

            if (user == null) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User not found!')),
              );
            }
          }

          Future<void> addSearchedMember() async {
            if (searchedUser == null) return;
            final userId = searchedUser!['id'];

            if (memberIds.contains(userId)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User is already a member of this family!')),
              );
              return;
            }

            setStateDialog(() => isAdding = true);

            final success = await FamilyService.addMember(family['id'], family['familyName'], userId);

            if (success) {
              memberIds.add(userId);
              addMemberIdController.clear();
              searchedUser = null;
              await fetchMembers();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Member added successfully!'), backgroundColor: Colors.green),
              );
            } else {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to add member'), backgroundColor: Colors.red),
              );
            }

            setStateDialog(() => isAdding = false);
          }

          Future<void> removeFamilyMember(String userId) async {
            setStateDialog(() => isFetching = true);
            final success = await FamilyService.removeMember(family['id'], userId);

            if (success) {
              memberIds.remove(userId);
              await fetchMembers();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Member removed successfully!'), backgroundColor: Colors.green),
              );
            } else {
              setStateDialog(() => isFetching = false);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to remove member'), backgroundColor: Colors.red),
              );
            }
          }

          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text('Manage Members: ${family['familyName']}', style: const TextStyle(color: Colors.white)),
            content: SizedBox(
              width: 500,
              height: 500,
              child: Column(
                children: [
                  // Add Member input & search
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addMemberIdController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Add Member by User ID',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: isSearchingUser
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.search, color: Colors.blue),
                        onPressed: searchUserToAdd,
                      ),
                    ],
                  ),
                  if (searchedUser != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: searchedUser!['imageUrl'].toString().isNotEmpty
                                ? NetworkImage(searchedUser!['imageUrl'])
                                : null,
                            child: searchedUser!['imageUrl'].toString().isEmpty ? const Icon(Icons.person) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(searchedUser!['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('ID: ${searchedUser!['profileId']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                if (searchedUser!['familyId'].toString().isNotEmpty)
                                  Text(
                                    'Currently in: ${searchedUser!['familyName']}',
                                    style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: isAdding
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.add_circle, color: Colors.green),
                            onPressed: isAdding ? null : addSearchedMember,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),
                  Expanded(
                    child: isFetching
                        ? const Center(child: CircularProgressIndicator())
                        : memberIds.isEmpty
                            ? const Center(child: Text('No members in this family', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: membersDetails.length,
                                itemBuilder: (context, index) {
                                  final member = membersDetails[index];
                                  final isCreator = member['id'] == family['creatorId'];

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: member['imageUrl'].toString().isNotEmpty
                                          ? NetworkImage(member['imageUrl'])
                                          : null,
                                      child: member['imageUrl'].toString().isEmpty ? const Icon(Icons.person) : null,
                                    ),
                                    title: Row(
                                      children: [
                                        Text(member['name'], style: const TextStyle(color: Colors.white)),
                                        if (isCreator) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.blue, width: 0.5),
                                            ),
                                            child: const Text('Leader', style: TextStyle(color: Colors.blue, fontSize: 10)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text('ID: ${member['profileId']}', style: const TextStyle(color: Colors.grey)),
                                    trailing: isCreator
                                        ? null // Cannot remove the creator directly this way
                                        : IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                            onPressed: () => removeFamilyMember(member['id']),
                                          ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Done'),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Family Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _showFamilySettingsDialog,
              icon: const Icon(Icons.settings),
              label: const Text('Family Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search families by ID or Name...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FamilyService.getFamiliesStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading families: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blue));
                  }

                  final allFamilies = snapshot.data ?? [];
                  final filteredFamilies = allFamilies.where((f) {
                    final name = f['familyName'].toString().toLowerCase();
                    final id = f['familyId'].toString().toLowerCase();
                    return name.contains(_searchQuery) || id.contains(_searchQuery);
                  }).toList();

                  if (filteredFamilies.isEmpty) {
                    return const Center(child: Text('No families found', style: TextStyle(color: Colors.grey, fontSize: 16)));
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      childAspectRatio: 1.6,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredFamilies.length,
                    itemBuilder: (context, index) {
                      final family = filteredFamilies[index];
                      final members = family['memberIds'] as List<dynamic>? ?? [];

                      return Card(
                        color: Colors.grey[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[800]!, width: 0.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  family['logoUrl'] != null && family['logoUrl'].toString().isNotEmpty
                                      ? MediaPreviewWidget(
                                          url: family['logoUrl'],
                                          width: 48,
                                          height: 48,
                                          borderRadius: BorderRadius.circular(8),
                                        )
                                      : Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.family_restroom, color: Colors.blue),
                                        ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          family['familyName'],
                                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'ID: ${family['familyId']}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Lv ${family['level'] ?? 1}',
                                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                family['description'] ?? 'No description provided.',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('${members.length}/${family['memberLimit'] ?? 50} members', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.star_outline, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('${family['points'] ?? 0} pts', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(color: Colors.grey, height: 1),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.group, color: Colors.blue, size: 20),
                                    tooltip: 'Manage Members',
                                    onPressed: () => _showManageMembersDialog(family),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                                    tooltip: 'Edit Family',
                                    onPressed: () => _showEditFamilyDialog(family),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    tooltip: 'Dissolve Family',
                                    onPressed: () => _showDeleteConfirmDialog(family),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
