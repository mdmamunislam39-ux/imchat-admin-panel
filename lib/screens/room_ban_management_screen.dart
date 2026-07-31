import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/base_screen.dart';

class RoomBanManagementScreen extends StatefulWidget {
  const RoomBanManagementScreen({super.key});

  @override
  State<RoomBanManagementScreen> createState() => _RoomBanManagementScreenState();
}

class _RoomBanManagementScreenState extends State<RoomBanManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _foundRoom;
  String? _foundRoomId;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchRoom() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundRoom = null;
      _foundRoomId = null;
      _errorMessage = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('audio_rooms_v2')
          .doc(query)
          .get();

      if (doc.exists) {
        setState(() {
          _foundRoom = doc.data();
          _foundRoomId = doc.id;
          _isSearching = false;
        });
        return;
      }

      setState(() {
        _errorMessage = 'No room found with that ID.';
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Search failed: $e';
        _isSearching = false;
      });
    }
  }

  Future<void> _toggleBan(bool banStatus) async {
    if (_foundRoomId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('audio_rooms_v2')
          .doc(_foundRoomId)
          .update({'isBanned': banStatus});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(banStatus ? 'Room banned successfully!' : 'Room unbanned successfully!'),
          backgroundColor: banStatus ? Colors.redAccent : Colors.green,
        ),
      );

      // Refresh room
      _searchRoom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update ban status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Room Ban Management',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter Room ID',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    ),
                    onSubmitted: (_) => _searchRoom(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSearching ? null : _searchRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  ),
                  child: _isSearching 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Search', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 16)),

            if (_foundRoom != null) ...[
              Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(top: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: _foundRoom!['imageUrl'] != null 
                              ? NetworkImage(_foundRoom!['imageUrl'])
                              : null,
                            backgroundColor: Colors.blueAccent.withOpacity(0.3),
                            child: _foundRoom!['imageUrl'] == null
                                ? const Icon(Icons.meeting_room, color: Colors.white, size: 40)
                                : null,
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _foundRoom!['name'] ?? 'Unknown Room',
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Room ID: $_foundRoomId',
                                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Creator ID: ${_foundRoom!['creatorId'] ?? 'Unknown'}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Room Status:', style: TextStyle(color: Colors.white, fontSize: 18)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: (_foundRoom!['isBanned'] == true) ? Colors.redAccent : Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (_foundRoom!['isBanned'] == true) ? 'BANNED' : 'ACTIVE',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _toggleBan(!(_foundRoom!['isBanned'] == true)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (_foundRoom!['isBanned'] == true) ? Colors.green : Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            (_foundRoom!['isBanned'] == true) ? 'UNBAN ROOM' : 'BAN ROOM',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
