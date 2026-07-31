import 'package:flutter/material.dart';
import '../models/seller_model.dart';
import '../models/transaction_model.dart';
import '../services/seller_service.dart';
import '../services/auth_service.dart';
import 'add_seller_screen.dart';
import 'seller_history_screen.dart';
import '../widgets/media_preview_widget.dart';

class SellerManagement extends StatefulWidget {
  const SellerManagement({super.key});

  @override
  State<SellerManagement> createState() => _SellerManagementState();
}

class _SellerManagementState extends State<SellerManagement> {
  final TextEditingController _searchController = TextEditingController();
  List<SellerModel> _sellers = [];
  List<SellerModel> _filteredSellers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSellers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSellers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final sellers = await SellerService.getAllSellers();
      
      if (mounted) {
        setState(() {
          _sellers = sellers;
          _filteredSellers = sellers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading sellers: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load sellers');
      }
    }
  }

  void _filterSellers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSellers = _sellers;
      } else {
        _filteredSellers = _sellers.where((seller) {
          return seller.sellerName.toLowerCase().contains(query.toLowerCase()) ||
                 seller.profileId.toLowerCase().contains(query.toLowerCase()) ||
                 seller.idNumber.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Seller Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddSellerScreen(),
                ),
              ).then((_) => _loadSellers());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSellers,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search sellers by name, profile ID, or ID number...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _filterSellers('');
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

          // Sellers List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : _filteredSellers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No sellers found'
                                  : 'No sellers match your search',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 18,
                              ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Add your first seller to get started',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSellers,
                        color: Colors.white,
                        backgroundColor: Colors.black,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredSellers.length,
                          itemBuilder: (context, index) {
                            final seller = _filteredSellers[index];
                            return _buildSellerCard(seller);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard(SellerModel seller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: seller.isActive ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Profile Picture
                seller.profilePicture != null
                    ? MediaPreviewWidget(
                        url: seller.profilePicture!,
                        width: 60,
                        height: 60,
                        borderRadius: BorderRadius.circular(30),
                      )
                    : CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                const SizedBox(width: 16),
                
                // Seller Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seller.sellerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${seller.idNumber}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Profile ID: ${seller.profileId}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Unique ID: ${seller.idNumber}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: seller.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    seller.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Balance Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Balance',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${seller.accountBalance.toStringAsFixed(0)}💎',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Add Balance Button
                      IconButton(
                        onPressed: () => _showBalanceDialog(seller, true),
                        icon: const Icon(
                          Icons.add_circle,
                          color: Colors.green,
                          size: 32,
                        ),
                        tooltip: 'Add Balance',
                      ),
                      // Minus Balance Button
                      IconButton(
                        onPressed: () => _showBalanceDialog(seller, false),
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                          size: 32,
                        ),
                        tooltip: 'Deduct Balance',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SellerHistoryScreen(sellerId: seller.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('View History'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleSellerStatus(seller),
                    icon: Icon(
                      seller.isActive ? Icons.person_off : Icons.person,
                    ),
                    label: Text(
                      seller.isActive ? 'Deactivate' : 'Activate',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: seller.isActive ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBalanceDialog(SellerModel seller, bool isAdd) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          isAdd ? 'Add Balance' : 'Deduct Balance',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount (💎)',
                labelStyle: const TextStyle(color: Colors.grey),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Reason',
                labelStyle: const TextStyle(color: Colors.grey),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
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
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              final reason = reasonController.text.trim();
              
              if (amount == null || amount <= 0) {
                _showErrorSnackBar('Please enter a valid amount');
                return;
              }
              
              if (reason.isEmpty) {
                _showErrorSnackBar('Please enter a reason');
                return;
              }
              
              Navigator.pop(context);
              
              final success = await SellerService.updateSellerBalance(
                sellerId: seller.id,
                amount: amount,
                type: isAdd ? TransactionType.add : TransactionType.minus,
                description: reason,
                adminId: AuthService.currentUser?.uid,
              );
              
              if (success) {
                _showSuccessSnackBar(
                  isAdd 
                    ? 'Balance added successfully' 
                    : 'Balance deducted successfully'
                );
                _loadSellers();
              } else {
                _showErrorSnackBar('Failed to update balance');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdd ? Colors.green : Colors.red,
            ),
            child: Text(isAdd ? 'Add' : 'Deduct'),
          ),
        ],
      ),
    );
  }

  void _toggleSellerStatus(SellerModel seller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          seller.isActive ? 'Deactivate Seller' : 'Activate Seller',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          seller.isActive
              ? 'Are you sure you want to deactivate this seller? They will lose all seller privileges.'
              : 'Are you sure you want to activate this seller? They will regain all seller privileges.',
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
              
              final success = await SellerService.toggleSellerStatus(
                sellerId: seller.id,
                isActive: !seller.isActive,
                adminId: AuthService.currentUser?.uid,
              );
              
              if (success) {
                _showSuccessSnackBar(
                  seller.isActive
                      ? 'Seller deactivated successfully'
                      : 'Seller activated successfully'
                );
                _loadSellers();
              } else {
                _showErrorSnackBar('Failed to update seller status');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: seller.isActive ? Colors.red : Colors.green,
            ),
            child: Text(seller.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }
}
