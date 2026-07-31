import 'package:flutter/material.dart';
import '../services/seller_service.dart';
import '../services/auth_service.dart';

class SellerRechargeScreen extends StatefulWidget {
  const SellerRechargeScreen({super.key});

  @override
  State<SellerRechargeScreen> createState() => _SellerRechargeScreenState();
}

class _SellerRechargeScreenState extends State<SellerRechargeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<double> _predefinedAmounts = [500, 1000, 5000, 10000, 20000];
  
  Map<String, dynamic>? _foundUser;
  double? _selectedAmount;
  bool _isSearching = false;
  bool _isRecharging = false;
  bool _isCustomAmount = false;
  final TextEditingController _customAmountController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _customAmountController.dispose();
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

  Future<void> _searchUser() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _showErrorSnackBar('Please enter a Profile ID or Phone Number');
      return;
    }

    setState(() {
      _isSearching = true;
      _foundUser = null;
      _selectedAmount = null;
    });

    try {
      final user = await SellerService.searchUser(query);
      
      if (mounted) {
        setState(() {
          _isSearching = false;
          _foundUser = user;
        });

        if (user == null) {
          _showErrorSnackBar('User not found');
        }
      }
    } catch (e) {
      debugPrint('Error searching user: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        _showErrorSnackBar('Failed to search user');
      }
    }
  }

  Future<void> _rechargeUser() async {
    if (_foundUser == null) {
      _showErrorSnackBar('Please search for a user first');
      return;
    }

    if (_selectedAmount == null) {
      _showErrorSnackBar('Please select an amount');
      return;
    }

    if (_selectedAmount! <= 0) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }

    setState(() {
      _isRecharging = true;
    });

    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('User not authenticated');
        return;
      }

      final seller = await SellerService.getSellerByUserId(currentUser.uid);
      if (seller == null) {
        _showErrorSnackBar('Seller account not found');
        return;
      }

      if (!seller.isActive) {
        _showErrorSnackBar('Your seller account is inactive');
        return;
      }

      if (seller.accountBalance < _selectedAmount!) {
        _showErrorSnackBar('Insufficient balance');
        return;
      }

      final success = await SellerService.rechargeUser(
        sellerId: seller.id,
        userId: _foundUser!['id'],
        userProfileId: _foundUser!['profileId'],
        userPhoneNumber: _foundUser!['phone'],
        userName: _foundUser!['name'],
        amount: _selectedAmount!,
      );

      if (mounted) {
        setState(() {
          _isRecharging = false;
        });

        if (success) {
          _showSuccessSnackBar('User recharged successfully!');
          _resetForm();
        } else {
          _showErrorSnackBar('Failed to recharge user');
        }
      }
    } catch (e) {
      debugPrint('Error recharging user: $e');
      if (mounted) {
        setState(() {
          _isRecharging = false;
        });
        _showErrorSnackBar('Failed to recharge user');
      }
    }
  }

  void _resetForm() {
    setState(() {
      _foundUser = null;
      _selectedAmount = null;
      _isCustomAmount = false;
      _customAmountController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Recharge User',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recharge User Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Search for a user and add diamonds to their account. The amount will be deducted from your seller balance.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Search Section
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
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter Profile ID or Phone Number',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSearching ? null : _searchUser,
                icon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_isSearching ? 'Searching...' : 'Search User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Found User Section
            if (_foundUser != null) ...[
              const Text(
                'User Found',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[800],
                          child: const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _foundUser!['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Profile ID: ${_foundUser!['profileId'] ?? 'N/A'}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Phone: ${_foundUser!['phone'] ?? 'N/A'}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Current Balance: ${(_foundUser!['balance'] ?? 0.0).toStringAsFixed(0)}💎',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Amount Selection
              const Text(
                'Select Amount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Predefined Amounts
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _predefinedAmounts.map((amount) {
                  final isSelected = _selectedAmount == amount && !_isCustomAmount;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAmount = amount;
                        _isCustomAmount = false;
                        _customAmountController.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[800]!,
                        ),
                      ),
                      child: Text(
                        '${amount.toStringAsFixed(0)}💎',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Custom Amount
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isCustomAmount = true;
                    _selectedAmount = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _isCustomAmount ? Colors.blue : Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isCustomAmount ? Colors.blue : Colors.grey[800]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Custom Amount',
                        style: TextStyle(
                          color: _isCustomAmount ? Colors.white : Colors.grey,
                          fontSize: 16,
                          fontWeight: _isCustomAmount ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (_isCustomAmount) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _customAmountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Amount',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              final amount = double.tryParse(value);
                              if (amount != null && amount > 0) {
                                setState(() {
                                  _selectedAmount = amount;
                                });
                              } else {
                                setState(() {
                                  _selectedAmount = null;
                                });
                              }
                            },
                          ),
                        ),
                        const Text(
                          '💎',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Recharge Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isRecharging || _selectedAmount == null ? null : _rechargeUser,
                  icon: _isRecharging
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.account_balance_wallet),
                  label: Text(_isRecharging ? 'Recharging...' : 'Recharge User'),
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

              const SizedBox(height: 16),

              // Reset Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Help Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to Recharge:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Search for the user by Profile ID or Phone Number\n'
                    '2. Select a predefined amount or enter a custom amount\n'
                    '3. Click "Recharge User" to confirm the transaction\n'
                    '4. The amount will be deducted from your seller balance\n'
                    '5. The user will receive a notification about the recharge',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
