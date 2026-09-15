import 'package:flutter/material.dart';
import '../models/custom_room_id_model.dart';
import '../services/room_customization_service.dart';
import '../widgets/media_preview_widget.dart';

class RoomIdCustomizationScreen extends StatefulWidget {
  const RoomIdCustomizationScreen({super.key});

  @override
  State<RoomIdCustomizationScreen> createState() => _RoomIdCustomizationScreenState();
}

class _RoomIdCustomizationScreenState extends State<RoomIdCustomizationScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _customIdController = TextEditingController();
  final _durationController = TextEditingController();
  late TabController _tabController;

  Map<String, dynamic>? _selectedRoom;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _customIdController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _searchController.clear();
      _customIdController.clear();
      _durationController.text = '30'; // Default 30 days
      _selectedRoom = null;
    });
  }

  Future<void> _searchRoom() async {
    final searchId = _searchController.text.trim();
    if (searchId.isEmpty) return;

    setState(() => _isSearching = true);
    
    try {
      final room = await RoomCustomizationService.searchRoomByOriginalId(searchId);
      setState(() {
        _selectedRoom = room;
        _isSearching = false;
      });
      
      if (room == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room not found! Ensure the ID is correct.'))
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

  Future<void> _assignCustomId() async {
    if (!_formKey.currentState!.validate() || _selectedRoom == null) return;

    try {
      final days = int.tryParse(_durationController.text) ?? 30;
      final customIdModel = CustomRoomIdModel(
        id: '',
        roomId: _selectedRoom!['id'],
        originalRoomId: _selectedRoom!['roomId'],
        customRoomId: _customIdController.text.trim(),
        roomName: _selectedRoom!['name'],
        roomImageUrl: _selectedRoom!['imageUrl'],
        assignedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: days)),
      );

      await RoomCustomizationService.assignCustomRoomId(customIdModel);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Custom Room ID assigned successfully')));
        Navigator.pop(context);
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _showAssignDialog(BuildContext context) {
    if (_durationController.text.isEmpty) {
      _durationController.text = '30';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('Assign Custom Room ID', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Section
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Original or Custom Room ID',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search, color: Colors.blue),
                          onPressed: () async {
                            setStateDialog(() => _isSearching = true);
                            await _searchRoom();
                            setStateDialog(() => _isSearching = false);
                          },
                        ),
                      ],
                    ),
                    
                    if (_selectedRoom != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            _selectedRoom!['imageUrl'].isNotEmpty
                                ? MediaPreviewWidget(
                                    url: _selectedRoom!['imageUrl'],
                                    width: 40,
                                    height: 40,
                                    borderRadius: BorderRadius.circular(20),
                                  )
                                : const CircleAvatar(child: Icon(Icons.room)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selectedRoom!['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text('ID: ${_selectedRoom!['roomId']}', style: TextStyle(color: Colors.grey[400])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customIdController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Custom Short ID',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Please enter a Custom ID' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _durationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Duration (Days)',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Please enter duration' : null,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetForm();
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: _selectedRoom != null ? _assignCustomId : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Assign'),
              ),
            ],
          );
        }
      ),
    ).then((_) {
      _resetForm();
    });
  }

  void _showEditDialog(BuildContext context, CustomRoomIdModel assignment) {
    final editIdController = TextEditingController(text: assignment.customRoomId);
    DateTime selectedDate = assignment.expiresAt;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('Edit Premium Room ID', style: TextStyle(color: Colors.white)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: editIdController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Custom Short ID',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    ),
                    validator: (value) => value!.isEmpty ? 'Please enter a Custom ID' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Expires:',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedDate.toLocal().toString().split(' ')[0],
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_month, color: Colors.blue),
                        onPressed: () async {
                          final newDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (newDate != null) {
                            setState(() {
                              selectedDate = newDate;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      await RoomCustomizationService.updateCustomRoomId(
                        assignment.id,
                        selectedDate,
                        assignment.isActive,
                        newCustomId: editIdController.text,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated successfully!')));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _getStyleIndicator(String customId) {
    final length = customId.length;
    Color bgColor;
    Color textColor = Colors.white;
    String label;
    IconData? icon;

    if (length == 1) {
      bgColor = Colors.black;
      textColor = Colors.amber;
      label = 'Premium Black';
      icon = Icons.star;
    } else if (length == 2) {
      bgColor = Colors.amber[700]!;
      label = 'Golden';
      icon = Icons.stars;
    } else if (length >= 3 && length <= 4) {
      bgColor = Colors.purple;
      label = 'Purple';
    } else if (length >= 5 && length <= 6) {
      bgColor = Colors.cyan;
      label = 'Aqua RGB';
    } else {
      bgColor = Colors.grey[700]!;
      label = 'Default';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: length == 1 ? Border.all(color: Colors.amber, width: 2) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAssignments() {
    return StreamBuilder<List<CustomRoomIdModel>>(
      stream: RoomCustomizationService.getCustomRoomIdsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blue));
        }

        final assignments = snapshot.data ?? [];

        if (assignments.isEmpty) {
          return const Center(
            child: Text('No custom room IDs assigned yet.', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            final isExpired = assignment.isExpired;

            return Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        assignment.roomImageUrl.isNotEmpty
                            ? MediaPreviewWidget(
                                url: assignment.roomImageUrl,
                                width: 40,
                                height: 40,
                                borderRadius: BorderRadius.circular(20),
                              )
                            : const CircleAvatar(child: Icon(Icons.room)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(assignment.roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text('Original: ${assignment.originalRoomId}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              assignment.customRoomId,
                              style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            _getStyleIndicator(assignment.customRoomId),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Colors.grey),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: ${!assignment.isActive ? "Deactivated" : (isExpired ? "Expired" : "Active")}',
                              style: TextStyle(color: !assignment.isActive ? Colors.grey : (isExpired ? Colors.red : Colors.green)),
                            ),
                            Text(
                              'Expires: ${assignment.expiresAt.toLocal().toString().split(' ')[0]}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                             Switch(
                               value: assignment.isActive && !isExpired,
                               onChanged: (value) async {
                                 if (isExpired && value) {
                                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot activate expired ID. Please delete and assign a new one.')));
                                   return;
                                 }
                                 try {
                                   await RoomCustomizationService.updateCustomRoomId(assignment.id, assignment.expiresAt, value);
                                 } catch (e) {
                                   if (mounted) {
                                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
                                   }
                                 }
                               },
                               activeThumbColor: Colors.blue,
                             ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showEditDialog(context, assignment);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.grey[900],
                                    title: const Text('Remove Assignment', style: TextStyle(color: Colors.white)),
                                    content: const Text('Are you sure you want to remove this Custom ID and restore the original ID?', style: TextStyle(color: Colors.grey)),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                      ElevatedButton(
                                        onPressed: () {
                                          RoomCustomizationService.deleteCustomRoomId(assignment.id);
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<dynamic>>(
      stream: RoomCustomizationService.getCustomRoomIdHistoryStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blue));
        }

        final historyLogs = snapshot.data ?? [];

        if (historyLogs.isEmpty) {
          return const Center(
            child: Text('No history found.', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          itemCount: historyLogs.length,
          itemBuilder: (context, index) {
            final log = historyLogs[index];
            IconData actionIcon;
            Color actionColor;

            switch (log.action.name) {
              case 'assign':
                actionIcon = Icons.add_circle;
                actionColor = Colors.green;
                break;
              case 'update':
                actionIcon = Icons.edit;
                actionColor = Colors.orange;
                break;
              case 'remove':
                actionIcon = Icons.delete;
                actionColor = Colors.red;
                break;
              default:
                actionIcon = Icons.info;
                actionColor = Colors.blue;
            }

            return ListTile(
              leading: Icon(actionIcon, color: actionColor),
              title: Text('Room: ${log.roomId} - Custom ID: ${log.customRoomId}', style: const TextStyle(color: Colors.white)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.notes ?? '', style: TextStyle(color: Colors.grey[400])),
                  Text('Admin: ${log.actionByAdminId}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              trailing: Text(
                log.timestamp.toLocal().toString().substring(0, 16),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Custom Room IDs'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Active Assignments'),
            Tab(text: 'History'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () {
                _resetForm();
                _showAssignDialog(context);
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveAssignments(),
          _buildHistoryTab(),
        ],
      ),
    );
  }
}
