# Flutter App Implementation Guide
## Admin Panel Features Integration

### 📋 Overview
This document provides complete implementation guidelines for integrating admin panel features into the main Flutter app. The admin panel manages users, store items, levels, and commissions - all of which need to be reflected in the user-facing app.

---

## 🔐 **1. USER AUTHENTICATION & BLOCKING SYSTEM**

### **1.1 Blocked User Login Prevention**

#### **Implementation Location**: `lib/services/auth_service.dart`

```dart
class AuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Enhanced login method with blocking check
  static Future<AuthResult> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // First, check if user is blocked
      final userQuery = await _firestore
          .collection('Users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        final userStatus = userData['status'] ?? 'active';
        
        // Check if user is blocked
        if (userStatus == 'blocked') {
          return AuthResult(
            success: false,
            errorMessage: 'Your account has been blocked. Please contact support.',
            user: null,
          );
        }
        
        // Check for active punishments
        final punishments = userData['punishments'] as List<dynamic>? ?? [];
        final activePunishments = punishments.where((p) => 
          p['isActive'] == true && 
          (p['expiresAt'] == null || DateTime.now().isBefore((p['expiresAt'] as Timestamp).toDate()))
        ).toList();
        
        if (activePunishments.isNotEmpty) {
          final punishment = activePunishments.first;
          final reason = punishment['reason'] ?? 'No reason provided';
          final type = punishment['type'] ?? 'block';
          
          return AuthResult(
            success: false,
            errorMessage: 'Account suspended: $reason',
            user: null,
          );
        }
      }
      
      // Proceed with normal authentication
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        return AuthResult(
          success: true,
          user: credential.user,
          errorMessage: null,
        );
      }
      
      return AuthResult(
        success: false,
        errorMessage: 'Login failed',
        user: null,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Login error: $e',
        user: null,
      );
    }
  }
}

class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;
  
  AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });
}
```

#### **Implementation Location**: `lib/screens/login_screen.dart`

```dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    
    final result = await AuthService.loginWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (result.success) {
      // Navigate to main app
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Login form fields
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading 
                ? CircularProgressIndicator() 
                : Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🏪 **2. STORE INTEGRATION**

### **2.1 Official Store Screen**

#### **Implementation Location**: `lib/screens/official_store_screen.dart`

```dart
class OfficialStoreScreen extends StatefulWidget {
  @override
  _OfficialStoreScreenState createState() => _OfficialStoreScreenState();
}

class _OfficialStoreScreenState extends State<OfficialStoreScreen> {
  List<StoreItemModel> _storeItems = [];
  List<StoreItemModel> _userItems = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadStoreItems();
    _loadUserItems();
  }

  Future<void> _loadStoreItems() async {
    try {
      final items = await StoreService.getActiveStoreItems();
      setState(() {
        _storeItems = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading store items: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserItems() async {
    try {
      final userItems = await StoreService.getUserStoreItems();
      setState(() {
        _userItems = userItems;
      });
    } catch (e) {
      debugPrint('Error loading user items: $e');
    }
  }

  List<StoreItemModel> get _filteredItems {
    if (_selectedCategory == 'all') return _storeItems;
    return _storeItems.where((item) => 
      item.category.name.toLowerCase() == _selectedCategory.toLowerCase()
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Official Store'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () => _showUserItems(),
          ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildCategoryFilter(),
              Expanded(
                child: _buildStoreItems(),
              ),
            ],
          ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip('all', 'All'),
          _buildCategoryChip('badge', 'Badges'),
          _buildCategoryChip('frame', 'Frames'),
          _buildCategoryChip('entry_effect', 'Entry Effects'),
          _buildCategoryChip('background', 'Backgrounds'),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
      ),
    );
  }

  Widget _buildStoreItems() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _buildStoreItemCard(item);
      },
    );
  }

  Widget _buildStoreItemCard(StoreItemModel item) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item preview
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.thumbnailUrl != null
                ? Image.network(
                    item.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.image, size: 50);
                    },
                  )
                : Icon(Icons.image, size: 50),
            ),
          ),
          // Item details
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.diamondPrice.toStringAsFixed(0)} 💎',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _purchaseItem(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: Size(60, 30),
                        ),
                        child: Text('Buy', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseItem(StoreItemModel item) async {
    try {
      // Check if user has enough diamonds
      final userProfile = await UserProfileService.getCurrentUserProfile();
      if (userProfile.totalDiamonds < item.diamondPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Insufficient diamonds'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Purchase Item'),
          content: Text('Buy ${item.name} for ${item.diamondPrice.toStringAsFixed(0)} diamonds?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Purchase'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Process purchase
        await StoreService.purchaseItem(
          itemId: item.id,
          userId: userProfile.userId,
          diamondPrice: item.diamondPrice,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item purchased successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh data
        _loadStoreItems();
        _loadUserItems();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserItems() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('My Items'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: _userItems.isEmpty
            ? Center(child: Text('No items purchased yet'))
            : ListView.builder(
                itemCount: _userItems.length,
                itemBuilder: (context, index) {
                  final item = _userItems[index];
                  return ListTile(
                    leading: Icon(Icons.shopping_bag),
                    title: Text(item.name),
                    subtitle: Text('Purchased'),
                    trailing: IconButton(
                      icon: Icon(Icons.use),
                      onPressed: () => _useItem(item),
                    ),
                  );
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _useItem(StoreItemModel item) async {
    // Implement item usage logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} is now active!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
```

### **2.2 Store Service Implementation**

#### **Implementation Location**: `lib/services/store_service.dart`

```dart
class StoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get all active store items
  static Future<List<StoreItemModel>> getActiveStoreItems() async {
    try {
      final snapshot = await _firestore
          .collection('marketItems')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => StoreItemModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting store items: $e');
      return [];
    }
  }

  // Get user's purchased items
  static Future<List<StoreItemModel>> getUserStoreItems() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      final snapshot = await _firestore
          .collection('userStoreItems')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      return snapshot.docs.map((doc) => StoreItemModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user items: $e');
      return [];
    }
  }

  // Purchase an item
  static Future<bool> purchaseItem({
    required String itemId,
    required String userId,
    required double diamondPrice,
  }) async {
    try {
      final batch = _firestore.batch();

      // Add item to user's collection
      final userItemRef = _firestore.collection('userStoreItems').doc();
      batch.set(userItemRef, {
        'userId': userId,
        'itemId': itemId,
        'purchasedAt': Timestamp.now(),
        'isActive': true,
      });

      // Deduct diamonds from user
      final userRef = _firestore.collection('Users').doc(userId);
      batch.update(userRef, {
        'diamonds': FieldValue.increment(-diamondPrice),
        'updatedAt': Timestamp.now(),
      });

      // Record transaction
      final transactionRef = _firestore.collection('transactions').doc();
      batch.set(transactionRef, {
        'userId': userId,
        'type': 'purchase',
        'amount': diamondPrice,
        'itemId': itemId,
        'createdAt': Timestamp.now(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error purchasing item: $e');
      return false;
    }
  }
}
```

---

## 🎯 **3. USER LEVEL SYSTEM**

### **3.1 Level Display in Profile**

#### **Implementation Location**: `lib/screens/profile_screen.dart`

```dart
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfileModel? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await UserProfileService.getCurrentUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        body: Center(child: Text('Error loading profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showSettings(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            SizedBox(height: 20),
            _buildLevelCards(),
            SizedBox(height: 20),
            _buildStatsCards(),
            SizedBox(height: 20),
            _buildCustomizationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: _userProfile!.profileImageUrl != null
                  ? NetworkImage(_userProfile!.profileImageUrl!)
                  : null,
              child: _userProfile!.profileImageUrl == null
                  ? Icon(Icons.person, size: 40)
                  : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userProfile!.username,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _userProfile!.bio,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.diamond, color: Colors.blue, size: 16),
                      SizedBox(width: 4),
                      Text('${_userProfile!.totalDiamonds.toStringAsFixed(0)}'),
                      SizedBox(width: 16),
                      Icon(Icons.coffee, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text('${_userProfile!.totalBeans.toStringAsFixed(0)}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCards() {
    return Row(
      children: [
        Expanded(
          child: _buildLevelCard(
            'Sending Level',
            _userProfile!.sendingLevel,
            Colors.blue,
            Icons.send,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildLevelCard(
            'Receiving Level',
            _userProfile!.receivingLevel,
            Colors.green,
            Icons.receive,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(String title, UserLevel level, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Level ${level.level}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              level.levelName,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: level.progressPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            SizedBox(height: 8),
            Text(
              '${level.currentProgress.toStringAsFixed(0)} / ${level.requiredForNext.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Diamonds Sent',
                    _userProfile!.diamondsSent.toStringAsFixed(0),
                    Icons.send,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Diamonds Received',
                    _userProfile!.diamondsReceived.toStringAsFixed(0),
                    Icons.receive,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Daily Sent',
                    _userProfile!.activityStats.dailyDiamondsSent.toStringAsFixed(0),
                    Icons.today,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Daily Received',
                    _userProfile!.activityStats.dailyDiamondsReceived.toStringAsFixed(0),
                    Icons.today,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCustomizationSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customization',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCustomizationItem(
                    'Badges',
                    _userProfile!.customization.ownedBadges.length,
                    Icons.workspace_premium,
                    () => _showCustomization('badges'),
                  ),
                ),
                Expanded(
                  child: _buildCustomizationItem(
                    'Frames',
                    _userProfile!.customization.ownedFrames.length,
                    Icons.crop_square,
                    () => _showCustomization('frames'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCustomizationItem(
                    'Entry Effects',
                    _userProfile!.customization.ownedEntryEffects.length,
                    Icons.animation,
                    () => _showCustomization('entry_effects'),
                  ),
                ),
                Expanded(
                  child: _buildCustomizationItem(
                    'Backgrounds',
                    _userProfile!.customization.ownedBackgroundThemes.length,
                    Icons.landscape,
                    () => _showCustomization('backgrounds'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomizationItem(String title, int count, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24),
            SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomization(String type) {
    // Navigate to customization screen
    Navigator.pushNamed(context, '/customization', arguments: type);
  }

  void _showSettings() {
    // Navigate to settings screen
    Navigator.pushNamed(context, '/settings');
  }
}
```

---

## 🎨 **4. CUSTOMIZATION SYSTEM**

### **4.1 Customization Screen**

#### **Implementation Location**: `lib/screens/customization_screen.dart`

```dart
class CustomizationScreen extends StatefulWidget {
  final String type;

  const CustomizationScreen({Key? key, required this.type}) : super(key: key);

  @override
  _CustomizationScreenState createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
  List<StoreItemModel> _items = [];
  String? _selectedItemId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadCurrentSelection();
  }

  Future<void> _loadItems() async {
    try {
      final items = await StoreService.getUserStoreItemsByType(widget.type);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading items: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCurrentSelection() async {
    try {
      final profile = await UserProfileService.getCurrentUserProfile();
      setState(() {
        switch (widget.type) {
          case 'badges':
            _selectedItemId = profile.customization.selectedBadgeId;
            break;
          case 'frames':
            _selectedItemId = profile.customization.selectedFrameId;
            break;
          case 'entry_effects':
            _selectedItemId = profile.customization.selectedEntryEffectId;
            break;
          case 'backgrounds':
            _selectedItemId = profile.customization.selectedBackgroundThemeId;
            break;
        }
      });
    } catch (e) {
      debugPrint('Error loading current selection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.type.toUpperCase()} Customization'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text('No ${widget.type} available'))
              : GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final isSelected = _selectedItemId == item.id;
                    return _buildItemCard(item, isSelected);
                  },
                ),
    );
  }

  Widget _buildItemCard(StoreItemModel item, bool isSelected) {
    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? Colors.blue[50] : null,
      child: InkWell(
        onTap: () => _selectItem(item),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.thumbnailUrl != null
                    ? Image.network(
                        item.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image, size: 50);
                        },
                      )
                    : Icon(Icons.image, size: 50),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    if (isSelected)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'SELECTED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectItem(StoreItemModel item) async {
    try {
      await UserProfileService.updateCustomization(
        type: widget.type,
        itemId: item.id,
      );

      setState(() {
        _selectedItemId = item.id;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} is now active!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating customization: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

---

## 📊 **5. COMMISSION SYSTEM**

### **5.1 Host Dashboard**

#### **Implementation Location**: `lib/screens/host_dashboard.dart`

```dart
class HostDashboard extends StatefulWidget {
  @override
  _HostDashboardState createState() => _HostDashboardState();
}

class _HostDashboardState extends State<HostDashboard> {
  Map<String, dynamic> _commissionData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommissionData();
  }

  Future<void> _loadCommissionData() async {
    try {
      final data = await CommissionService.getHostCommissionData();
      setState(() {
        _commissionData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading commission data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Host Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => _showCommissionHistory(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCommissionOverview(),
                  SizedBox(height: 20),
                  _buildRecentEarnings(),
                  SizedBox(height: 20),
                  _buildPerformanceMetrics(),
                ],
              ),
            ),
    );
  }

  Widget _buildCommissionOverview() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commission Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Earnings',
                    '\$${(_commissionData['totalEarnings'] ?? 0.0).toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'This Month',
                    '\$${(_commissionData['monthlyEarnings'] ?? 0.0).toStringAsFixed(2)}',
                    Icons.calendar_month,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    '\$${(_commissionData['pendingAmount'] ?? 0.0).toStringAsFixed(2)}',
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Commission Rate',
                    '${(_commissionData['commissionRate'] ?? 0.0).toStringAsFixed(1)}%',
                    Icons.percent,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEarnings() {
    final recentEarnings = _commissionData['recentEarnings'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Earnings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (recentEarnings.isEmpty)
              Center(
                child: Text('No recent earnings'),
              )
            else
              ...recentEarnings.map((earning) => _buildEarningItem(earning)),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningItem(Map<String, dynamic> earning) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.attach_money, color: Colors.green),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  earning['description'] ?? 'Commission',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  earning['date'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '\$${(earning['amount'] ?? 0.0).toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildMetricRow('Diamonds Earned', '${(_commissionData['diamondsEarned'] ?? 0).toStringAsFixed(0)} 💎'),
            _buildMetricRow('Host Rating', '${(_commissionData['rating'] ?? 0.0).toStringAsFixed(1)} ⭐'),
            _buildMetricRow('Total Sessions', '${_commissionData['totalSessions'] ?? 0}'),
            _buildMetricRow('Average Session Time', '${(_commissionData['avgSessionTime'] ?? 0).toStringAsFixed(1)} min'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showCommissionHistory() {
    Navigator.pushNamed(context, '/commission_history');
  }
}
```

---

## 🔧 **6. REQUIRED SERVICE IMPLEMENTATIONS**

### **6.1 User Profile Service**

#### **Implementation Location**: `lib/services/user_profile_service.dart`

```dart
class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user profile
  static Future<UserProfileModel> getCurrentUserProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final doc = await _firestore.collection('Users').doc(currentUser.uid).get();
      if (doc.exists) {
        return UserProfileModel.fromFirestore(doc);
      } else {
        throw Exception('User profile not found');
      }
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      rethrow;
    }
  }

  // Update customization
  static Future<bool> updateCustomization({
    required String type,
    required String itemId,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final updateData = <String, dynamic>{};
      
      switch (type) {
        case 'badges':
          updateData['customization.selectedBadgeId'] = itemId;
          break;
        case 'frames':
          updateData['customization.selectedFrameId'] = itemId;
          break;
        case 'entry_effects':
          updateData['customization.selectedEntryEffectId'] = itemId;
          break;
        case 'backgrounds':
          updateData['customization.selectedBackgroundThemeId'] = itemId;
          break;
      }

      updateData['customization.lastUpdated'] = Timestamp.now();
      updateData['updatedAt'] = Timestamp.now();

      await _firestore.collection('Users').doc(currentUser.uid).update(updateData);
      return true;
    } catch (e) {
      debugPrint('Error updating customization: $e');
      return false;
    }
  }
}
```

### **6.2 Commission Service**

#### **Implementation Location**: `lib/services/commission_service.dart`

```dart
class CommissionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get host commission data
  static Future<Map<String, dynamic>> getHostCommissionData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return {};

      // Get host data
      final hostDoc = await _firestore
          .collection('hosts')
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (hostDoc.docs.isEmpty) return {};

      final hostData = hostDoc.docs.first.data();

      // Get commission data
      final commissionSnapshot = await _firestore
          .collection('commissions')
          .where('hostId', isEqualTo: currentUser.uid)
          .get();

      double totalEarnings = 0.0;
      double monthlyEarnings = 0.0;
      double pendingAmount = 0.0;
      final recentEarnings = <Map<String, dynamic>>[];

      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month);

      for (final doc in commissionSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0.0).toDouble();
        final status = data['status'] ?? 'pending';
        final createdAt = (data['createdAt'] as Timestamp).toDate();

        totalEarnings += amount;

        if (createdAt.isAfter(thisMonth)) {
          monthlyEarnings += amount;
        }

        if (status == 'pending') {
          pendingAmount += amount;
        }

        if (recentEarnings.length < 5) {
          recentEarnings.add({
            'amount': amount,
            'description': data['description'] ?? 'Commission',
            'date': DateFormat('MMM dd, yyyy').format(createdAt),
          });
        }
      }

      return {
        'totalEarnings': totalEarnings,
        'monthlyEarnings': monthlyEarnings,
        'pendingAmount': pendingAmount,
        'commissionRate': hostData['commissionRate'] ?? 10.0,
        'recentEarnings': recentEarnings,
        'diamondsEarned': hostData['totalDiamonds'] ?? 0.0,
        'rating': hostData['averageRating'] ?? 0.0,
        'totalSessions': hostData['totalSessions'] ?? 0,
        'avgSessionTime': hostData['averageSessionTime'] ?? 0.0,
      };
    } catch (e) {
      debugPrint('Error getting commission data: $e');
      return {};
    }
  }
}
```

---

## 🚀 **7. IMPLEMENTATION CHECKLIST**

### **Phase 1: Authentication & Security**
- [ ] Implement blocked user login prevention
- [ ] Add punishment system checks
- [ ] Create user status validation
- [ ] Add security error messages

### **Phase 2: Store Integration**
- [ ] Create official store screen
- [ ] Implement item purchase system
- [ ] Add user inventory management
- [ ] Create customization interface

### **Phase 3: User Profile & Levels**
- [ ] Display user levels and progress
- [ ] Show activity statistics
- [ ] Implement level progression
- [ ] Add customization options

### **Phase 4: Commission System**
- [ ] Create host dashboard
- [ ] Display commission data
- [ ] Show earnings history
- [ ] Add performance metrics

### **Phase 5: Testing & Optimization**
- [ ] Test all user flows
- [ ] Validate error handling
- [ ] Optimize performance
- [ ] Add loading states

---

## 📱 **8. NAVIGATION ROUTES**

Add these routes to your `main.dart` or routing configuration:

```dart
// In your main app routing
routes: {
  '/home': (context) => HomeScreen(),
  '/store': (context) => OfficialStoreScreen(),
  '/profile': (context) => ProfileScreen(),
  '/customization': (context) => CustomizationScreen(
    type: ModalRoute.of(context)!.settings.arguments as String,
  ),
  '/host_dashboard': (context) => HostDashboard(),
  '/commission_history': (context) => CommissionHistoryScreen(),
  '/settings': (context) => SettingsScreen(),
}
```

---

## 🔒 **9. SECURITY CONSIDERATIONS**

1. **Always validate user status** before allowing access to features
2. **Check punishment status** on every app launch
3. **Validate purchases** before processing transactions
4. **Implement proper error handling** for all Firebase operations
5. **Add loading states** for better user experience
6. **Use try-catch blocks** for all async operations

---

## 🎮 **11. HTML5 GAME LAUNCHER (VOICE ROOM & WALLET SCREEN)**

The admin panel allows creating/editing games with **Game ID / Code** (e.g. `html5_greedy_market`, `greedy_market`) or **Game URL** (e.g. `https://greedy-market-game.web.app`).

### **11.1 Game Launcher Service** (`lib/services/game_launcher_service.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/game_model.dart';

class GameLauncherService {
  // Known predefined URL maps for Game IDs
  static final Map<String, String> _gameIdUrlMap = {
    'html5_greedy_market': 'https://greedy-market-game.web.app',
    'greedy_market': 'https://greedy-market-game.web.app',
    'fruit_wheel': 'https://greedy-market-game.web.app',
    'html5_king_queen_slot': 'https://king-queen-slot-game.web.app',
    'king_queen_slot': 'https://king-queen-slot-game.web.app',
    'html5_greedy_delicious': 'https://greedy-delicious-game.web.app',
    'greedy_delicious': 'https://greedy-delicious-game.web.app',
    'html5_greedy_cat': 'https://greedy-cat-game.web.app',
    'greedy_cat': 'https://greedy-cat-game.web.app',
  };

  static String resolveGameUrl({
    required GameModel game,
    required String currentUserId,
    String? roomId,
  }) {
    String baseUrl = game.gameUrl.trim();
    if (baseUrl.isEmpty) {
      baseUrl = _gameIdUrlMap[game.gameCode] ??
                _gameIdUrlMap[game.id] ??
                'https://greedy-market-game.web.app';
    }

    // Replace placeholders if present
    baseUrl = baseUrl.replaceAll('{USER_ID}', currentUserId)
                     .replaceAll('{ROOM_ID}', roomId ?? '');

    // Append userId and roomId query parameters if missing
    if (!baseUrl.contains('userId=')) {
      final sep = baseUrl.contains('?') ? '&' : '?';
      baseUrl += '${sep}userId=$currentUserId';
      if (roomId != null && roomId.isNotEmpty) {
        baseUrl += '&roomId=$roomId';
      }
    }

    return baseUrl;
  }

  // 1. Open in Voice Room as Compact Half/Bottom Sheet (65% Screen Height)
  static void openInVoiceRoom({
    required BuildContext context,
    required GameModel game,
    required String currentUserId,
    required String roomId,
  }) {
    final url = resolveGameUrl(game: game, currentUserId: currentUserId, roomId: roomId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.68, // Compact height inside voice room
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            color: const Color(0xFF030A1C),
            child: BorderlessGameWebView(url: url, title: game.name),
          ),
        ),
      ),
    );
  }

  // 2. Open from Wallet / Main Navigation as 100% Full Screen
  static void openInFullScreen({
    required BuildContext context,
    required GameModel game,
    required String currentUserId,
  }) {
    final url = resolveGameUrl(game: game, currentUserId: currentUserId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFF030A1C),
          body: SafeArea(
            child: BorderlessGameWebView(url: url, title: game.name, isFullScreen: true),
          ),
        ),
      ),
    );
  }
}

// Borderless, Headless Game WebView Widget (Zero browser bars / Zero URL text)
class BorderlessGameWebView extends StatefulWidget {
  final String url;
  final String title;
  final bool isFullScreen;

  const BorderlessGameWebView({
    super.key,
    required this.url,
    required this.title,
    this.isFullScreen = false,
  });

  @override
  State<BorderlessGameWebView> createState() => _BorderlessGameWebViewState();
}

class _BorderlessGameWebViewState extends State<BorderlessGameWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF030A1C))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          ),
      ],
    );
  }
}
```

---

## 📞 **10. SUPPORT & MAINTENANCE**

- Monitor user blocking effectiveness
- Track store purchase analytics
- Monitor level progression rates
- Review commission payouts
- Update customization options regularly

This implementation guide provides everything needed to integrate the admin panel features into your main Flutter app. Each section includes complete code examples and implementation details.

