import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agency_model.dart';
import '../services/agency_service.dart';
import '../helpers/official_team_helper.dart';

class CreateAgencyScreen extends StatefulWidget {
  const CreateAgencyScreen({super.key});

  @override
  State<CreateAgencyScreen> createState() => _CreateAgencyScreenState();
}

class _CreateAgencyScreenState extends State<CreateAgencyScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSearching = false;
  
  // Controllers
  final _profileIdController = TextEditingController();
  final _agencyIdController = TextEditingController();
  
  // User data
  Map<String, dynamic>? _foundUser;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  @override
  void dispose() {
    _profileIdController.dispose();
    _agencyIdController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    try {
      setState(() {
        _isSearching = true;
      });

      final querySnapshot = await AgencyService.searchUser(_profileIdController.text);
      
      setState(() {
        _allUsers = querySnapshot;
        _filteredUsers = _allUsers;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        return user['profileId'].toLowerCase().contains(query.toLowerCase()) ||
               user['name'].toLowerCase().contains(query.toLowerCase()) ||
               user['phone'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _selectUser(Map<String, dynamic> user) {
    setState(() {
      _foundUser = user;
      _profileIdController.text = user['profileId'];
    });
  }

  Future<void> _createAgency() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_foundUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a user first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ownerUserId = _foundUser!['id'];

      // Check if user is already an owner of another agency
      final existingAgenciesQuery = await FirebaseFirestore.instance
          .collection('agencies')
          .where('ownerUserId', isEqualTo: ownerUserId)
          .limit(1)
          .get();

      if (existingAgenciesQuery.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This user is already an owner of an agency. Please terminate that agency first!'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final agency = AgencyModel(
        id: '',
        agencyName: 'Agency ${_agencyIdController.text}',
        agencyIdNumber: _agencyIdController.text,
        owner: AgencyOwner(
          name: _foundUser!['name'],
          phone: _foundUser!['phone'],
          email: _foundUser!['email'] ?? '',
          address: _foundUser!['address'] ?? '',
          userId: ownerUserId,
        ),
        logoUrl: '',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        totalCommissionEarned: 0.0,
        totalHosts: 0,
        hostIds: [],
      );

      final agencyId = await AgencyService.createAgency(agency);

      // Link agency to user in the database
      await FirebaseFirestore.instance
          .collection('agencies')
          .doc(agencyId)
          .update({
        'ownerUserId': ownerUserId,
        'owner.userId': ownerUserId,
      });

      // Update the user document to set isAgency: true and cache agency details
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(ownerUserId)
          .update({
        'isAgency': true,
        'agencyId': agencyId,
        'agencyName': 'Agency ${_agencyIdController.text}',
        'userType': 'agency_owner',
        'roles': FieldValue.arrayUnion(['agency']),
      });
      
      // Send congratulations message via imChat official team
      try {
        final ownerDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(ownerUserId)
            .get();
        final ownerName = ownerDoc.data()?['fullname'] ??
            ownerDoc.data()?['username'] ??
            _foundUser!['name'] ??
            'User';
        await OfficialTeamHelper.sendAgencyAssignedCongratulations(
          userId: ownerUserId,
          userName: ownerName,
          agencyName: 'Agency ${_agencyIdController.text.trim()}',
        );
      } catch (ex) {
        debugPrint('⚠️ Failed to send official team congratulations: $ex');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agency created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error creating agency: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating agency: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          'Create New Agency',
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
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Section
              _buildSearchSection(),
              
              const SizedBox(height: 24),
              
              // Agency ID Section
              _buildSectionTitle('Agency Information'),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _agencyIdController,
                label: 'Agency ID Number',
                hint: 'Enter unique agency ID',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter agency ID';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Selected User Info
              if (_foundUser != null) _buildSelectedUserCard(),
              
              const SizedBox(height: 32),
              
              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAgency,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Agency',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search User',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        TextField(
          controller: _profileIdController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter Profile ID to search...',
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.blue),
            suffixIcon: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search, color: Colors.blue),
                    onPressed: _loadAllUsers,
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          onChanged: _filterUsers,
        ),
        
        const SizedBox(height: 16),
        
        // Users List
        if (_filteredUsers.isNotEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                final isSelected = _foundUser?['id'] == user['id'];
                final isAgency = user['isAgency'] ?? false;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAgency ? Colors.orange : Colors.blue,
                    child: Text(
                      user['name'][0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Phone: ${user['phone']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: isAgency
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'AGENCY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                  onTap: isAgency ? null : () => _selectUser(user),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedUserCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected User',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green,
                child: Text(
                  _foundUser!['name'][0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _foundUser!['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Profile ID: ${_foundUser!['profileId']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'Phone: ${_foundUser!['phone']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _foundUser = null;
                    _profileIdController.clear();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.grey),
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
