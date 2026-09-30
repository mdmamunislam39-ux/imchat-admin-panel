import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/seller_model.dart';
import '../models/transaction_model.dart';
import '../services/seller_service.dart';
import '../services/auth_service.dart';
import 'add_seller_screen.dart';
import 'seller_history_screen.dart';
import 'seller_requests_screen.dart';
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
  StreamSubscription<List<SellerModel>>? _sellersSubscription;

  @override
  void initState() {
    super.initState();
    _startRealtimeListener();
  }

  @override
  void dispose() {
    _sellersSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startRealtimeListener() {
    _sellersSubscription?.cancel();
    setState(() => _isLoading = true);

    _sellersSubscription = SellerService.getSellersStream().listen(
      (sellers) {
        if (mounted) {
          setState(() {
            _sellers = sellers;
            _filterSellers(_searchQuery);
            _isLoading = false;
          });
        }
      },
      onError: (e) {
        debugPrint('Error loading real-time sellers: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Failed to load sellers stream');
        }
      },
    );
  }

  Future<void> _loadSellers() async {
    _startRealtimeListener();
  }

  void _filterSellers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSellers = _sellers;
      } else {
        final q = query.toLowerCase().trim();
        _filteredSellers = _sellers.where((seller) {
          return seller.sellerName.toLowerCase().contains(q) ||
                 seller.profileId.toLowerCase().contains(q) ||
                 seller.idNumber.toLowerCase().contains(q) ||
                 seller.email.toLowerCase().contains(q) ||
                 seller.phone.contains(q);
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.diamond_rounded, size: 16, color: Colors.amberAccent),
            label: const Text('Top-Up Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SellerRequestsScreen(),
                ),
              ).then((_) => _loadSellers());
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Add New Seller',
            icon: const Icon(Icons.add_rounded, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddSellerScreen(),
                ),
              ).then((_) => _loadSellers());
            },
          ),
          const SizedBox(width: 8),
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('Users').doc(seller.id).snapshots(),
      builder: (context, snapshot) {
        String displayName = seller.sellerName;
        String? displayPhoto = seller.profilePicture;
        String displaySearchId = seller.profileId.isNotEmpty ? seller.profileId : seller.idNumber;
        String displayPhone = seller.phone;
        String displayEmail = seller.email;
        double displayDiamonds = seller.accountBalance;

        if (snapshot.hasData && snapshot.data!.exists) {
          final ud = snapshot.data!.data() as Map<String, dynamic>;
          displayName = ud['fullname'] ?? ud['name'] ?? ud['username'] ?? displayName;
          displayPhoto = ud['photoUrl'] ?? ud['profileImageUrl'] ?? displayPhoto;
          displaySearchId = ud['searchId']?.toString() ?? displaySearchId;
          displayPhone = (ud['number'] ?? ud['phone'] ?? displayPhone).toString();
          displayEmail = (ud['email'] ?? ud['googleEmail'] ?? ud['mail'] ?? displayEmail).toString();
          if (ud['diamonds'] != null) {
            displayDiamonds = (ud['diamonds'] as num).toDouble();
          }
        }

        final hasPhone = displayPhone.trim().isNotEmpty;
        final hasEmail = displayEmail.trim().isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: seller.isActive ? const Color(0xFF10B981) : Colors.redAccent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (seller.isActive ? const Color(0xFF10B981) : Colors.redAccent).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                    displayPhoto != null && displayPhoto.isNotEmpty
                        ? MediaPreviewWidget(
                            url: displayPhoto,
                            width: 54,
                            height: 54,
                            borderRadius: BorderRadius.circular(27),
                          )
                        : CircleAvatar(
                            radius: 27,
                            backgroundColor: Colors.grey[800],
                            child: const Icon(
                              Icons.person,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                    const SizedBox(width: 14),

                    // Seller Name & ID
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  'ID: $displaySearchId',
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Doc ID: ${seller.id}',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (seller.isActive ? Colors.green : Colors.red).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: seller.isActive ? Colors.green : Colors.red),
                      ),
                      child: Text(
                        seller.isActive ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          color: seller.isActive ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Contact Information (Phone & Google / Email)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                  ),
                  child: Column(
                    children: [
                      // Phone Row
                      Row(
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 15, color: Colors.greenAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasPhone ? displayPhone : 'No phone linked',
                              style: TextStyle(
                                color: hasPhone ? Colors.white : Colors.grey[600],
                                fontSize: 13,
                                fontWeight: hasPhone ? FontWeight.w500 : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasPhone)
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: displayPhone));
                                _showSuccessSnackBar('Phone number copied!');
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(2.0),
                                child: Icon(Icons.copy_rounded, size: 14, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Google / Email Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              'G',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasEmail ? displayEmail : 'No Google/Email linked',
                              style: TextStyle(
                                color: hasEmail ? Colors.white : Colors.grey[600],
                                fontSize: 13,
                                fontWeight: hasEmail ? FontWeight.w500 : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasEmail)
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: displayEmail));
                                _showSuccessSnackBar('Google email copied!');
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(2.0),
                                child: Icon(Icons.copy_rounded, size: 14, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Balance Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live Balance (💎)',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${displayDiamonds.toStringAsFixed(0)} 💎',
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 19,
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
                              color: Colors.greenAccent,
                              size: 30,
                            ),
                            tooltip: 'Add Balance',
                          ),
                          // Minus Balance Button
                          IconButton(
                            onPressed: () => _showBalanceDialog(seller, false),
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.redAccent,
                              size: 30,
                            ),
                            tooltip: 'Deduct Balance',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showEditSellerDialog(seller, displayName, displaySearchId, displayPhone, displayEmail),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Edit Info'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                        icon: const Icon(Icons.history, size: 16),
                        label: const Text('History'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleSellerStatus(seller),
                        icon: Icon(
                          seller.isActive ? Icons.person_off : Icons.person,
                          size: 16,
                        ),
                        label: Text(
                          seller.isActive ? 'Deactivate' : 'Activate',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: seller.isActive ? Colors.red[800] : Colors.green[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditSellerDialog(
    SellerModel seller,
    String currentName,
    String currentSearchId,
    String currentPhone,
    String currentEmail,
  ) {
    final nameCtrl = TextEditingController(text: currentName);
    final searchIdCtrl = TextEditingController(text: currentSearchId);
    final phoneCtrl = TextEditingController(text: currentPhone);
    final emailCtrl = TextEditingController(text: currentEmail);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.edit_note_rounded, color: Colors.tealAccent),
                SizedBox(width: 8),
                Text('Edit Seller Info', style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.person, color: Colors.grey),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchIdCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Search / Profile ID',
                      labelStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.badge, color: Colors.grey),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (📱)',
                      labelStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.phone, color: Colors.greenAccent),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Google / Email Account (🌐)',
                      labelStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.email, color: Colors.redAccent),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);
                        final ok = await SellerService.updateSellerInfo(
                          sellerId: seller.id,
                          userId: seller.userId.isNotEmpty ? seller.userId : seller.id,
                          sellerName: nameCtrl.text.trim(),
                          idNumber: seller.idNumber,
                          profileId: searchIdCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                        );
                        if (mounted) {
                          nav.pop();
                          if (ok) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Seller info updated in real time!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update seller info'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
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
              decoration: const InputDecoration(
                labelText: 'Amount (💎)',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Reason',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
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
