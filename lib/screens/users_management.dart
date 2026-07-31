import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../widgets/base_screen.dart';
import '../services/firebase_data_service.dart';
import '../widgets/media_preview_widget.dart';

// Helper class to mimic DocumentSnapshot behavior
class _UserDocument {
  final String id;
  final Map<String, dynamic> _data;
  
  _UserDocument(Map<String, dynamic> userData) 
      : id = userData['id'] ?? '',
        _data = userData;
  
  bool get exists => _data.isNotEmpty;
  
  Map<String, dynamic> data() => _data;
}

class UsersManagement extends StatefulWidget {
  const UsersManagement({super.key});

  @override
  State<UsersManagement> createState() => _UsersManagementState();
}

class _UsersManagementState extends State<UsersManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<_UserDocument> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final usersData = await FirebaseDataService.getAllUsers();
      setState(() {
        _users = usersData.map((userData) => _UserDocument(userData)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addDiamondsToUser(String userId, int diamonds) async {
    try {
      final userDoc = _firestore.collection('Users').doc(userId);
      final userData = await userDoc.get();
      
      if (userData.exists) {
        final currentDiamonds = userData.data()?['diamonds'] ?? 0;
        final newDiamonds = currentDiamonds + diamonds;
        
        await userDoc.update({'diamonds': newDiamonds});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $diamonds diamonds to user. Total: $newDiamonds'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        _loadUsers(); // Refresh the list
      }
    } catch (e) {
      debugPrint('Error adding diamonds: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding diamonds: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _ensureDiamondsFieldExists() async {
    try {
      final usersQuery = await _firestore.collection('Users').get();
      
      for (final userDoc in usersQuery.docs) {
        final userData = userDoc.data();
        if (!userData.containsKey('diamonds')) {
          await userDoc.reference.update({'diamonds': 0});
          debugPrint('Added diamonds field to user: ${userDoc.id}');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ensured all users have diamonds field'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error ensuring diamonds field: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ensuring diamonds field: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setUserDiamonds(String userId, int diamonds) async {
    try {
      await _firestore.collection('Users').doc(userId).update({'diamonds': diamonds});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Set user diamonds to $diamonds'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      _loadUsers();
    } catch (e) {
      debugPrint('Error setting diamonds: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting diamonds: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<_UserDocument> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _users;
    }
    return _users.where((user) {
      final data = user.data() as Map<String, dynamic>?;
      if (data == null) return false;
      
      final fullName = data['fullname']?.toString().toLowerCase() ?? '';
      final number = data['number']?.toString().toLowerCase() ?? '';
      final searchLower = _searchQuery.toLowerCase();
      
      return fullName.contains(searchLower) || number.contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Users Management',
      actions: [
        IconButton(
          onPressed: _ensureDiamondsFieldExists,
          icon: const Icon(Icons.diamond),
          tooltip: 'Ensure Diamonds Field',
        ),
      ],
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : Column(
              children: [
                _buildSearchBar(),
                _buildUsersList(),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search users by name or number...',
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
    );
  }

  Widget _buildUsersList() {
    final filteredUsers = _filteredUsers;
    
    if (filteredUsers.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty ? 'No users found' : 'No users match your search',
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          final data = user.data() as Map<String, dynamic>?;
          
          if (data == null) return const SizedBox.shrink();
          
          final fullName = data['fullname']?.toString() ?? 'Unknown User';
          final number = data['number']?.toString() ?? 'No number';
          final photoUrl = data['photoUrl']?.toString();
          final diamonds = data['diamonds'] ?? 0;
          final isOnline = data['isOnline'] ?? false;
          final isVerified = data['isVerified'] ?? false;
          
          return _buildUserCard(
            userId: user.id,
            fullName: fullName,
            number: number,
            photoUrl: photoUrl,
            diamonds: diamonds,
            isOnline: isOnline,
            isVerified: isVerified,
          );
        },
      ),
    );
  }

  Widget _buildUserCard({
    required String userId,
    required String fullName,
    required String number,
    String? photoUrl,
    required int diamonds,
    required bool isOnline,
    required bool isVerified,
  }) {
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
          photoUrl != null && photoUrl.isNotEmpty
              ? MediaPreviewWidget(
                  url: photoUrl,
                  width: 60,
                  height: 60,
                  borderRadius: BorderRadius.circular(30),
                )
              : CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[800],
                  child: const Icon(Icons.person, color: Colors.white, size: 30),
                ),
          const SizedBox(width: 16),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isVerified)
                      const Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 20,
                      ),
                    const SizedBox(width: 8),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  number,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.diamond,
                      color: Colors.pink,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Diamonds: $diamonds',
                      style: const TextStyle(
                        color: Colors.pink,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Diamond Management Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showAddDiamondsDialog(userId, fullName, diamonds),
                icon: const Icon(
                  Icons.add_circle,
                  color: Colors.blue,
                  size: 24,
                ),
                tooltip: 'Add Diamonds',
              ),
              IconButton(
                onPressed: () => _showSetDiamondsDialog(userId, fullName, diamonds),
                icon: const Icon(
                  Icons.edit,
                  color: Colors.orange,
                  size: 24,
                ),
                tooltip: 'Set Diamonds',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddDiamondsDialog(String userId, String userName, int currentDiamonds) {
    final diamondsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Add Diamonds to $userName',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current diamonds: $currentDiamonds',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: diamondsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Diamonds to add',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
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
          ],
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
            onPressed: () {
              final diamondsText = diamondsController.text.trim();
              if (diamondsText.isNotEmpty) {
                final diamonds = int.tryParse(diamondsText);
                if (diamonds != null && diamonds > 0) {
                  _addDiamondsToUser(userId, diamonds);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid positive number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Add Diamonds'),
          ),
        ],
      ),
    );
  }

  void _showSetDiamondsDialog(String userId, String userName, int currentDiamonds) {
    final diamondsController = TextEditingController(text: currentDiamonds.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Set Diamonds for $userName',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current diamonds: $currentDiamonds',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: diamondsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'New diamond amount',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
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
          ],
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
            onPressed: () {
              final diamondsText = diamondsController.text.trim();
              if (diamondsText.isNotEmpty) {
                final diamonds = int.tryParse(diamondsText);
                if (diamonds != null && diamonds >= 0) {
                  _setUserDiamonds(userId, diamonds);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid non-negative number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Set Diamonds'),
          ),
        ],
      ),
    );
  }
}
