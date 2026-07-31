import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../widgets/base_screen.dart';
import '../widgets/media_preview_widget.dart';

class DiamondsManagement extends StatefulWidget {
  const DiamondsManagement({super.key});

  @override
  State<DiamondsManagement> createState() => _DiamondsManagementState();
}

class _DiamondsManagementState extends State<DiamondsManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Statistics
  int _totaldiamonds = 0;
  int _usersWithdiamonds = 0;
  int _averagediamonds = 0;

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

      final querySnapshot = await _firestore.collection('Users').get();
      setState(() {
        _users = querySnapshot.docs;
        _isLoading = false;
      });
      
      _calculateStatistics();
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateStatistics() {
    int totaldiamonds = 0;
    int usersWithdiamonds = 0;
    
    for (final user in _users) {
      final data = user.data() as Map<String, dynamic>?;
      if (data != null) {
        final diamonds = (data['diamonds'] ?? 0) as int;
        if (diamonds > 0) {
          usersWithdiamonds++;
          totaldiamonds += diamonds;
        }
      }
    }
    
    setState(() {
      _totaldiamonds = totaldiamonds;
      _usersWithdiamonds = usersWithdiamonds;
      _averagediamonds = usersWithdiamonds > 0 ? (totaldiamonds / usersWithdiamonds).round() : 0;
    });
  }

  Future<void> _adddiamondsToUser(String userId, int diamonds) async {
    try {
      final userDoc = _firestore.collection('Users').doc(userId);
      final userData = await userDoc.get();
      
      if (userData.exists) {
        final currentdiamonds = userData.data()?['diamonds'] ?? 0;
        final newdiamonds = currentdiamonds + diamonds;
        
        final now = DateTime.now();
        final currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
        final lastMonth = userData.data()?['lastRechargeMonth'] as String? ?? '';
        final currentMonthlyRecharge = (userData.data()?['monthlyRechargeAmount'] as num?)?.toInt() ?? 0;
        
        int newMonthlyRecharge = diamonds;
        if (lastMonth == currentMonth) {
          newMonthlyRecharge = currentMonthlyRecharge + diamonds;
        }

        await userDoc.update({
          'diamonds': newdiamonds,
          'totalDiamonds': FieldValue.increment(diamonds),
          'monthlyRechargeAmount': newMonthlyRecharge,
          'lastRechargeMonth': currentMonth,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $diamonds diamonds to user. Total: $newdiamonds'),
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

  Future<void> _setUserdiamonds(String userId, int diamonds) async {
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

  Future<void> _deductdiamondsFromUser(String userId, int diamonds) async {
    try {
      final userDoc = _firestore.collection('Users').doc(userId);
      final userData = await userDoc.get();
      
      if (userData.exists) {
        final currentdiamonds = userData.data()?['diamonds'] ?? 0;
        final newdiamonds = (currentdiamonds - diamonds).clamp(0, currentdiamonds);
        
        await userDoc.update({'diamonds': newdiamonds});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deducted $diamonds diamonds from user. Remaining: $newdiamonds'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        
        _loadUsers(); // Refresh the list
      }
    } catch (e) {
      debugPrint('Error deducting diamonds: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deducting diamonds: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _ensurediamondsFieldExists() async {
    try {
      final usersQuery = await _firestore.collection('Users').get();
      int updatedCount = 0;
      
      for (final userDoc in usersQuery.docs) {
        final userData = userDoc.data();
        if (!userData.containsKey('diamonds')) {
          await userDoc.reference.update({'diamonds': 0});
          updatedCount++;
          debugPrint('Added diamonds field to user: ${userDoc.id}');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated $updatedCount users with diamonds field'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      _loadUsers();
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

  Future<void> _adddiamondsToAllUsers(int diamonds) async {
    try {
      final usersQuery = await _firestore.collection('Users').get();
      int updatedCount = 0;
      
      for (final userDoc in usersQuery.docs) {
        final userData = userDoc.data();
        final currentdiamonds = userData['diamonds'] ?? 0;
        final newdiamonds = currentdiamonds + diamonds;
        
        final now = DateTime.now();
        final currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
        final lastMonth = userData['lastRechargeMonth'] as String? ?? '';
        final currentMonthlyRecharge = (userData['monthlyRechargeAmount'] as num?)?.toInt() ?? 0;
        
        int newMonthlyRecharge = diamonds;
        if (lastMonth == currentMonth) {
          newMonthlyRecharge = currentMonthlyRecharge + diamonds;
        }
        
        await userDoc.reference.update({
          'diamonds': newdiamonds,
          'totalDiamonds': FieldValue.increment(diamonds),
          'monthlyRechargeAmount': newMonthlyRecharge,
          'lastRechargeMonth': currentMonth,
        });
        updatedCount++;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $diamonds diamonds to $updatedCount users'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      _loadUsers();
    } catch (e) {
      debugPrint('Error adding diamonds to all users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding diamonds to all users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<DocumentSnapshot> get _filteredUsers {
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
      title: 'diamonds Management',
      actions: [
        IconButton(
          onPressed: _ensurediamondsFieldExists,
          icon: const Icon(Icons.monetization_on),
          tooltip: 'Ensure diamonds Field',
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
                _buildStatisticsCards(),
                _buildSearchBar(),
                _buildBulkActions(),
                _buildUsersList(),
              ],
            ),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Total diamonds',
              value: _totaldiamonds.toString(),
              icon: Icons.monetization_on,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'Users with diamonds',
              value: _usersWithdiamonds.toString(),
              icon: Icons.people,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'Average diamonds',
              value: _averagediamonds.toString(),
              icon: Icons.trending_up,
              color: Colors.green,
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

  Widget _buildBulkActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showBulkAdddiamondsDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add to All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showBulkDeductdiamondsDialog(),
              icon: const Icon(Icons.remove),
              label: const Text('Deduct from All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
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
          
          final fullName = data['fullname']?.toString() ?? 'Unknown';
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
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'diamonds: $diamonds',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // diamond Management Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showAdddiamondsDialog(userId, fullName, diamonds),
                icon: const Icon(
                  Icons.add_circle,
                  color: Colors.green,
                  size: 24,
                ),
                tooltip: 'Add diamonds',
              ),
              IconButton(
                onPressed: () => _showSetdiamondsDialog(userId, fullName, diamonds),
                icon: const Icon(
                  Icons.edit,
                  color: Colors.blue,
                  size: 24,
                ),
                tooltip: 'Set diamonds',
              ),
              IconButton(
                onPressed: () => _showDeductdiamondsDialog(userId, fullName, diamonds),
                icon: const Icon(
                  Icons.remove_circle,
                  color: Colors.orange,
                  size: 24,
                ),
                tooltip: 'Deduct diamonds',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAdddiamondsDialog(String userId, String userName, int currentdiamonds) {
    final diamondsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Add diamonds to $userName',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current diamonds: $currentdiamonds',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: diamondsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'diamonds to add',
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
                  borderSide: const BorderSide(color: Colors.green),
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
                  _adddiamondsToUser(userId, diamonds);
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
              backgroundColor: Colors.green,
            ),
            child: const Text('Add diamonds'),
          ),
        ],
      ),
    );
  }

  void _showSetdiamondsDialog(String userId, String userName, int currentdiamonds) {
    final diamondsController = TextEditingController(text: currentdiamonds.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Set diamonds for $userName',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current diamonds: $currentdiamonds',
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
                  _setUserdiamonds(userId, diamonds);
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
              backgroundColor: Colors.blue,
            ),
            child: const Text('Set diamonds'),
          ),
        ],
      ),
    );
  }

  void _showDeductdiamondsDialog(String userId, String userName, int currentdiamonds) {
    final diamondsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Deduct diamonds from $userName',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current diamonds: $currentdiamonds',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: diamondsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'diamonds to deduct',
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
                  borderSide: const BorderSide(color: Colors.orange),
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
                if (diamonds != null && diamonds > 0 && diamonds <= currentdiamonds) {
                  _deductdiamondsFromUser(userId, diamonds);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid number (0 < diamonds <= $currentdiamonds)'),
                    backgroundColor: Colors.red,
                  ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Deduct diamonds'),
          ),
        ],
      ),
    );
  }

  void _showBulkAdddiamondsDialog() {
    final diamondsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Add diamonds to All Users',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will add diamonds to all ${_users.length} users',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: diamondsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'diamonds to add to each user',
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
                  borderSide: const BorderSide(color: Colors.green),
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
                  _adddiamondsToAllUsers(diamonds);
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
              backgroundColor: Colors.green,
            ),
            child: const Text('Add to All'),
          ),
        ],
      ),
    );
  }

  void _showBulkDeductdiamondsDialog() {
    final diamondsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Deduct diamonds from All Users',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will deduct diamonds from all ${_users.length} users',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: diamondsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'diamonds to deduct from each user',
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
                  borderSide: const BorderSide(color: Colors.orange),
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
                  // For bulk deduct, we'll add negative diamonds (which will be handled in the function)
                  _adddiamondsToAllUsers(-diamonds);
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
              backgroundColor: Colors.orange,
            ),
            child: const Text('Deduct from All'),
          ),
        ],
      ),
    );
  }
}
