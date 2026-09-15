import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../widgets/base_screen.dart';
import '../services/firebase_data_service.dart';
import '../widgets/media_preview_widget.dart';
import '../widgets/room_edit_dialog.dart';
import 'room_create_decoration_screen.dart';

class RoomsManagement extends StatefulWidget {
  const RoomsManagement({super.key});

  @override
  State<RoomsManagement> createState() => _RoomsManagementState();
}

class _RoomsManagementState extends State<RoomsManagement> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDeleteRoom(String roomId, String roomName) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete room "$roomName" (ID: $roomId)?\nThis will permanently delete the room in real-time.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await FirebaseDataService.deleteAudioRoom(roomId);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Room "$roomName" deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete room'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting room: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Rooms Management',
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseDataService.getAudioRoomsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading rooms: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // Dynamic statistics calculation
          int totalRooms = docs.length;
          int activeRooms = 0;
          int totalParticipants = 0;

          for (final doc in docs) {
            final data = doc.data();
            final isActive = data['isActive'] ?? data['status'] == 'active' ?? true;
            if (isActive) {
              activeRooms++;
            }

            final participants = data['participants'] ?? data['users'] ?? data['memberCount'] ?? 0;
            if (participants is int) {
              totalParticipants += participants;
            } else if (participants is List) {
              totalParticipants += participants.length;
            }
          }

          // Filter docs by search query
          final filteredDocs = docs.where((doc) {
            if (_searchQuery.isEmpty) return true;
            final data = doc.data();
            final roomName = data['name']?.toString().toLowerCase() ?? '';
            final roomId = doc.id.toLowerCase();
            final searchLower = _searchQuery.toLowerCase();
            return roomName.contains(searchLower) || roomId.contains(searchLower);
          }).toList();

          return Column(
            children: [
              _buildStatisticsCards(totalRooms, activeRooms, totalParticipants),
              _buildSearchBar(),
              _buildRoomsList(filteredDocs),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCards(int totalRooms, int activeRooms, int totalParticipants) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Total Rooms',
              value: totalRooms.toString(),
              icon: Icons.room,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'Active Rooms',
              value: activeRooms.toString(),
              icon: Icons.room_preferences,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'Total Participants',
              value: totalParticipants.toString(),
              icon: Icons.people,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search rooms by name or ID...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RoomCreateDecorationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
            label: const Text('New Room Decoration', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList(List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs) {
    if (filteredDocs.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.room_outlined,
                size: 64,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty ? 'No rooms found' : 'No rooms match your search',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredDocs.length,
        itemBuilder: (context, index) {
          final doc = filteredDocs[index];
          final data = doc.data();
          final roomId = doc.id;
          final roomName = data['name']?.toString() ?? 'Unnamed Room';
          final participants = data['participants'] ?? data['users'] ?? data['memberCount'] ?? 0;
          final isActive = data['isActive'] ?? data['status'] == 'active' ?? true;
          final createdAt = data['createdAt'];
          final imageUrl = data['imageUrl'] ?? data['roomImage'] ?? data['image']?.toString();

          return _buildRoomCard(
            roomId: roomId,
            roomName: roomName,
            participants: participants,
            isActive: isActive,
            createdAt: createdAt,
            imageUrl: imageUrl?.toString(),
            roomData: {'id': roomId, ...data},
          );
        },
      ),
    );
  }

  Widget _buildRoomCard({
    required String roomId,
    required String roomName,
    required dynamic participants,
    required bool isActive,
    dynamic createdAt,
    String? imageUrl,
    required Map<String, dynamic> roomData,
  }) {
    int participantCount = 0;
    if (participants is int) {
      participantCount = participants;
    } else if (participants is List) {
      participantCount = participants.length;
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
          // Room Icon or Image
          imageUrl != null && imageUrl.isNotEmpty
              ? MediaPreviewWidget(
                  url: imageUrl,
                  width: 56,
                  height: 56,
                  borderRadius: BorderRadius.circular(8),
                )
              : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.room,
                    color: isActive ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                ),
          const SizedBox(width: 16),

          // Room Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        roomName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $roomId',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.people,
                      color: Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Participants: $participantCount',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => RoomEditDialog(
                      roomData: roomData,
                      roomId: roomId,
                      onSaved: () {},
                    ),
                  );
                },
                icon: const Icon(
                  Icons.edit,
                  color: Colors.blue,
                  size: 24,
                ),
                tooltip: 'Edit Room',
              ),
              IconButton(
                onPressed: () => _confirmAndDeleteRoom(roomId, roomName),
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: 24,
                ),
                tooltip: 'Delete Room',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
