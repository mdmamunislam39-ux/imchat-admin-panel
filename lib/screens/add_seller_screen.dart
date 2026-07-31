import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/seller_service.dart';
import '../services/auth_service.dart';

class AddSellerScreen extends StatefulWidget {
  const AddSellerScreen({super.key});

  @override
  State<AddSellerScreen> createState() => _AddSellerScreenState();
}

class _AddSellerScreenState extends State<AddSellerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _uniqueIdController = TextEditingController();
  
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  Map<String, dynamic>? _selectedUser;
  bool _isLoading = true;
  bool _isCreating = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _idNumberController.dispose();
    _uniqueIdController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _loadAllUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore.collection('Users').get();
      
      final users = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['fullname'] ?? 'Unknown',
          'profileId': data['searchId'] ?? '',
          'phone': data['number'] ?? '',
          'balance': (data['Diamonds'] ?? 0.0).toDouble(),
          'isSeller': data['isSeller'] ?? false,
          'uniqueId': data['uniqueId'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load users');
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((user) {
          return user['name'].toLowerCase().contains(query.toLowerCase()) ||
                 user['profileId'].toLowerCase().contains(query.toLowerCase()) ||
                 user['phone'].contains(query) ||
                 user['uniqueId'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _selectUser(Map<String, dynamic> user) {
    setState(() {
      _selectedUser = user;
      _searchController.text = user['name'];
    });
  }

  Future<void> _createSeller() async {
    if (_selectedUser == null) {
      _showErrorSnackBar('Please select a user first');
      return;
    }

    if (_selectedUser!['isSeller'] == true) {
      _showErrorSnackBar('This user is already a seller');
      return;
    }

    final idNumber = _idNumberController.text.trim();
    if (idNumber.isEmpty) {
      _showErrorSnackBar('Please enter an ID number');
      return;
    }

    final uniqueId = _uniqueIdController.text.trim();
    if (uniqueId.isEmpty) {
      _showErrorSnackBar('Please enter a unique ID');
      return;
    }

    // Check if unique ID already exists
    final existingUser = _allUsers.where((user) => 
      user['uniqueId'] == uniqueId && user['id'] != _selectedUser!['id']
    ).isNotEmpty;
    
    if (existingUser) {
      _showErrorSnackBar('This unique ID is already assigned to another user');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // First update the user with unique ID
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('Users').doc(_selectedUser!['id']).update({
        'uniqueId': uniqueId,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Then create the seller
      final sellerId = await SellerService.createSeller(
        userId: _selectedUser!['id'],
        sellerName: _selectedUser!['name'],
        profilePicture: null,
        idNumber: idNumber,
        profileId: _selectedUser!['profileId'],
        adminId: AuthService.currentUser?.uid,
      );

      if (mounted) {
        setState(() {
          _isCreating = false;
        });

        if (sellerId != null) {
          _showSuccessSnackBar('Seller created successfully!');
          Navigator.pop(context, true);
        } else {
          _showErrorSnackBar('Failed to create seller');
        }
      }
    } catch (e) {
      debugPrint('Error creating seller: $e');
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        _showErrorSnackBar('Failed to create seller');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Add New Seller',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllUsers,
            tooltip: 'Refresh Users',
          ),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Seller',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Select a user from the list below and assign them a unique ID to make them a seller.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterUsers,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users by name, profile ID, phone, or unique ID...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _filterUsers('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : _filteredUsers.isEmpty
                    ? Center(
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
                              _searchQuery.isEmpty
                                  ? 'No users found'
                                  : 'No users match your search',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isSelected = _selectedUser?['id'] == user['id'];
                          final isAlreadySeller = user['isSeller'] == true;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue[900] : Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.blue 
                                    : isAlreadySeller 
                                        ? Colors.orange 
                                        : Colors.grey[800]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[800],
                                child: Icon(
                                  isAlreadySeller ? Icons.store : Icons.person,
                                  color: isAlreadySeller ? Colors.orange : Colors.white,
                                ),
                              ),
                              title: Text(
                                user['name'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Profile ID: ${user['profileId']}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  Text(
                                    'Phone: ${user['phone']}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  Text(
                                    'Balance: ${user['balance'].toStringAsFixed(0)}💎',
                                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                                  ),
                                  if (user['uniqueId'].isNotEmpty)
                                    Text(
                                      'Unique ID: ${user['uniqueId']}',
                                      style: const TextStyle(color: Colors.green, fontSize: 12),
                                    ),
                                  if (isAlreadySeller)
                                    const Text(
                                      'Already a Seller',
                                      style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : isAlreadySeller
                                      ? const Icon(Icons.store, color: Colors.orange)
                                      : const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                              onTap: isAlreadySeller ? null : () => _selectUser(user),
                            ),
                          );
                        },
                      ),
          ),

          // Selected User and Form
          if (_selectedUser != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Selected User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedUser = null;
                            _searchController.clear();
                            _idNumberController.clear();
                            _uniqueIdController.clear();
                          });
                        },
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                    ],
                  ),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[800],
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedUser!['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Profile ID: ${_selectedUser!['profileId']}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ID Number Field
                  TextField(
                    controller: _idNumberController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Seller ID Number',
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintText: 'Enter unique seller ID number',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Unique ID Field
                  TextField(
                    controller: _uniqueIdController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Unique ID',
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintText: 'Enter unique identifier for this user',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Create Seller Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isCreating ? null : _createSeller,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add),
                      label: Text(_isCreating ? 'Creating Seller...' : 'Make Seller'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
