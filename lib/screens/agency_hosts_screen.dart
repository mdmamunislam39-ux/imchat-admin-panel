import 'package:flutter/material.dart';
import '../models/host_model.dart';
import '../models/agency_notification_model.dart';
import '../services/agency_service.dart';
import 'user_history_stats.dart';

class AgencyHostsScreen extends StatefulWidget {
  final String agencyId;
  
  const AgencyHostsScreen({
    super.key,
    required this.agencyId,
  });

  @override
  State<AgencyHostsScreen> createState() => _AgencyHostsScreenState();
}

class _AgencyHostsScreenState extends State<AgencyHostsScreen> {
  List<HostModel> _hosts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  HostStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadHosts();
  }

  Future<void> _loadHosts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final hosts = await AgencyService.getAgencyHosts(widget.agencyId);
      setState(() {
        _hosts = hosts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading hosts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<HostModel> get _filteredHosts {
    return _hosts.where((host) {
      final matchesSearch = host.hostName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          host.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          host.phone.contains(_searchQuery);
      
      final matchesStatus = _selectedStatus == null || host.status == _selectedStatus;
      
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Hosts Management',
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
            onPressed: _loadHosts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchAndFilterBar(),
          
          // Hosts List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : _buildHostsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHostDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search hosts...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                borderSide: const BorderSide(color: Colors.blue),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Status Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null),
                const SizedBox(width: 8),
                ...HostStatus.values.map((status) => 
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(
                      status.name.toUpperCase(),
                      status,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, HostStatus? status) {
    final isSelected = _selectedStatus == status;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
      },
      backgroundColor: Colors.grey[800],
      selectedColor: Colors.blue,
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildHostsList() {
    final filteredHosts = _filteredHosts;
    
    if (filteredHosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedStatus != null
                  ? 'No hosts found matching your criteria'
                  : 'No hosts found',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedStatus != null
                  ? 'Try adjusting your search or filter'
                  : 'Add your first host to get started',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredHosts.length,
      itemBuilder: (context, index) {
        final host = filteredHosts[index];
        return _buildHostCard(host);
      },
    );
  }

  Widget _buildHostCard(HostModel host) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Host Header
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue,
                  child: Text(
                    host.hostName.isNotEmpty ? host.hostName[0].toUpperCase() : 'H',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
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
                        host.hostName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        host.email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(host.status),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: Colors.grey[900],
                  onSelected: (value) {
                    if (value == 'history') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserHistoryStats(
                            userId: host.userId,
                            username: host.hostName,
                          ),
                        ),
                      );
                    } else if (value == 'details') {
                      _viewHostDetails(host);
                    } else if (value == 'edit') {
                      _editHost(host);
                    } else if (value == 'remove') {
                      _removeHost(host);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'history',
                      child: Row(
                        children: [
                          Icon(Icons.history, color: Colors.blue, size: 20),
                          SizedBox(width: 10),
                          Text('User History', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: Colors.green, size: 20),
                          SizedBox(width: 10),
                          Text('View Details', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.orange, size: 20),
                          SizedBox(width: 10),
                          Text('Edit Info', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle, color: Colors.red, size: 20),
                          SizedBox(width: 10),
                          Text('Remove Host', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Host Performance
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceItem(
                    'Diamonds',
                    host.performance.totalDiamonds.toStringAsFixed(0),
                    Icons.diamond,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildPerformanceItem(
                    'Points',
                    host.performance.totalDiamonds.toStringAsFixed(0),
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildPerformanceItem(
                    'Live Hours',
                    '${host.performance.totalLiveHours}',
                    Icons.schedule,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(HostStatus status) {
    Color color;
    switch (status) {
      case HostStatus.active:
        color = Colors.green;
        break;
      case HostStatus.pending:
        color = Colors.orange;
        break;
      case HostStatus.suspended:
        color = Colors.red;
        break;
      case HostStatus.terminated:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _viewHostDetails(HostModel host) {
    showDialog(
      context: context,
      builder: (context) => _HostDetailsDialog(host: host),
    );
  }

  void _editHost(HostModel host) {
    showDialog(
      context: context,
      builder: (context) => _EditHostDialog(
        host: host,
        onUpdated: _loadHosts,
      ),
    );
  }

  void _removeHost(HostModel host) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Remove Host',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove ${host.hostName} from the agency?',
          style: const TextStyle(color: Colors.grey),
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
            onPressed: () async {
              Navigator.pop(context);
              await _confirmRemoveHost(host);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveHost(HostModel host) async {
    try {
      final success = await AgencyService.removeHostFromAgency(host.id, host.agencyId);
      
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${host.hostName} removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadHosts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove host'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing host: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing host: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddHostDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddHostDialog(
        agencyId: widget.agencyId,
        onHostAdded: _loadHosts,
      ),
    );
  }
}

class _HostDetailsDialog extends StatelessWidget {
  final HostModel host;
  
  const _HostDetailsDialog({required this.host});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(
        'Host Details',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Name', host.hostName),
            _buildDetailRow('Email', host.email),
            _buildDetailRow('Phone', host.phone),
            _buildDetailRow('Status', host.status.name.toUpperCase()),
            _buildDetailRow('Joined Date', _formatDate(host.joinedDate)),
            if (host.lastActiveDate != null)
              _buildDetailRow('Last Active', _formatDate(host.lastActiveDate!)),
            const SizedBox(height: 16),
            const Text(
              'Performance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Total Diamonds', host.performance.totalDiamonds.toStringAsFixed(0)),
            _buildDetailRow('Total Diamonds', host.performance.totalDiamonds.toStringAsFixed(0)),
            _buildDetailRow('Live Hours', host.performance.totalLiveHours.toString()),
            _buildDetailRow('Gifts Received', host.performance.totalGiftsReceived.toString()),
            _buildDetailRow('Average Rating', host.performance.averageRating.toStringAsFixed(1)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _EditHostDialog extends StatefulWidget {
  final HostModel host;
  final VoidCallback onUpdated;
  
  const _EditHostDialog({
    required this.host,
    required this.onUpdated,
  });

  @override
  State<_EditHostDialog> createState() => _EditHostDialogState();
}

class _EditHostDialogState extends State<_EditHostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  HostStatus _selectedStatus = HostStatus.active;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.host.hostName;
    _emailController.text = widget.host.email;
    _phoneController.text = widget.host.phone;
    _notesController.text = widget.host.notes ?? '';
    _selectedStatus = widget.host.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        'Edit Host',
        style: TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Host Name',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter host name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<HostStatus>(
                initialValue: _selectedStatus,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Status',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                items: HostStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateHost,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateHost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedHost = widget.host.copyWith(
        hostName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        status: _selectedStatus,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final success = await AgencyService.updateHost(widget.host.id, updatedHost);
      
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Host updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update host'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating host: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating host: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _AddHostDialog extends StatefulWidget {
  final String agencyId;
  final VoidCallback onHostAdded;
  
  const _AddHostDialog({
    required this.agencyId,
    required this.onHostAdded,
  });

  @override
  State<_AddHostDialog> createState() => _AddHostDialogState();
}

class _AddHostDialogState extends State<_AddHostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _profileIdController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  bool _isSearching = false;
  
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
    _messageController.dispose();
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
    final isHost = user['userType'] == 'host' || 
                   (user['agencyId'] != null && user['agencyId'].toString().isNotEmpty);
    if (isHost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user['name']} is already a Host of another agency. They must leave their agency first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _foundUser = user;
      _profileIdController.text = user['profileId'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        'Invite Host',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 450,
        child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Section
              const Text(
                'Search User by Profile ID',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              TextField(
                controller: _profileIdController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter Profile ID...',
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
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                onChanged: _filterUsers,
              ),
              
              const SizedBox(height: 16),
              
              // Users List
              if (_filteredUsers.isNotEmpty)
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final isSelected = _foundUser?['id'] == user['id'];
                      final isHost = user['userType'] == 'host' || 
                                     (user['agencyId'] != null && user['agencyId'].toString().isNotEmpty);
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isHost ? Colors.red.shade900 : Colors.blue,
                          child: Text(
                            (user['name'] as String).isNotEmpty
                                ? user['name'][0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                user['name'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isHost) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.red, width: 0.5),
                                ),
                                child: const Text(
                                  'Already Host',
                                  style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          'Profile ID: ${user['profileId']}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: isHost
                            ? const Icon(
                                Icons.block,
                                color: Colors.red,
                                size: 20,
                              )
                            : (isSelected
                                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                : const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 20)),
                        onTap: () => _selectUser(user),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Selected User Info
              if (_foundUser != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green,
                        radius: 16,
                        child: Text(
                          _foundUser!['name'][0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _foundUser!['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Profile ID: ${_foundUser!['profileId']}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        onPressed: () {
                          setState(() {
                            _foundUser = null;
                            _profileIdController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Invitation Message (Optional)',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendInvitation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Send Invitation'),
        ),
      ],
    );
  }

  Future<void> _sendInvitation() async {
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
      final invitation = HostInvitationModel(
        id: '',
        agencyId: widget.agencyId,
        hostUserId: _foundUser!['id'],
        hostName: _foundUser!['name'],
        hostEmail: _foundUser!['email'] ?? '',
        hostPhone: _foundUser!['phone'],
        sentAt: DateTime.now(),
        message: _messageController.text.trim(),
      );

      await AgencyService.sendHostInvitation(invitation);
      
      if (!mounted) return;
      Navigator.pop(context);
      widget.onHostAdded();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error sending invitation: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending invitation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
