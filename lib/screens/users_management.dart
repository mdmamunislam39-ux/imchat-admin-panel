import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/base_screen.dart';
import '../widgets/media_preview_widget.dart';
import 'user_profile_management.dart';
import 'users_history_screen.dart';
import 'user_position_management_screen.dart';
import '../services/user_position_service.dart';

class UsersManagement extends StatefulWidget {
  const UsersManagement({super.key});

  @override
  State<UsersManagement> createState() => _UsersManagementState();
}

class _UsersManagementState extends State<UsersManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSubscription;
  StreamSubscription<DocumentSnapshot>? _themeSubscription;

  List<Map<String, dynamic>> _rawUsers = [];
  bool _isLoading = true;

  // Real-time app theme PNG URLs for Diamond and Beans
  String? _diamondIconUrl;
  String? _beansIconUrl;

  // View state: 'all' or 'analytics'
  String _currentView = 'all';

  // Search & Filters
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedGender = 'Gender'; // 'Gender' (All), 'Male', 'Female', 'Other'
  String _selectedStatus = 'All Status'; // 'All Status', 'Active', 'Blocked', 'Suspended', 'Online', 'Offline'
  String _selectedUserType = 'All User Type'; // 'All User Type', 'Regular', 'Host', 'Seller', 'Admin', 'Agency'
  String _selectedLevel = 'Select Level'; // 'Select Level', 'All Levels', 'Sending Lv 1', etc.

  // Sorting
  String _sortBy = 'none'; // 'none', 'beans', 'diamond', 'send_level', 'receive_level'
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _startRealtimeUsersListener();
    _startThemeListener();
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _themeSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Real-time listener for Users collection
  void _startRealtimeUsersListener() {
    _usersSubscription?.cancel();
    _usersSubscription = _firestore.collection('Users').snapshots().listen(
      (snapshot) {
        if (!mounted) return;
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();

        setState(() {
          _rawUsers = list;
          _isLoading = false;
        });
      },
      onError: (e) {
        debugPrint('Error listening to users collection: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  // Real-time theme listener for App's Diamonds and Beans PNGs
  void _startThemeListener() {
    _themeSubscription?.cancel();
    _themeSubscription = _firestore
        .collection('global_settings')
        .doc('app_theme')
        .snapshots()
        .listen((docSnap) {
      if (docSnap.exists && mounted) {
        final data = docSnap.data() ?? {};
        setState(() {
          _diamondIconUrl = data['diamondIconUrl']?.toString();
          _beansIconUrl = data['beansIconUrl']?.toString();
        });
      }
    }, onError: (e) {
      debugPrint('Realtime theme listener error: $e');
    });
  }

  // Widget to display Beans PNG / icon
  Widget _buildBeansIcon({double size = 18}) {
    if (_beansIconUrl != null && _beansIconUrl!.trim().isNotEmpty) {
      return MediaPreviewWidget(
        url: _beansIconUrl!,
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(4),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        'B',
        style: TextStyle(
          color: Colors.white,
          fontSize: (size * 0.55).clamp(8.0, 14.0),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Widget to display Diamond PNG / icon
  Widget _buildDiamondIcon({double size = 18}) {
    if (_diamondIconUrl != null && _diamondIconUrl!.trim().isNotEmpty) {
      return MediaPreviewWidget(
        url: _diamondIconUrl!,
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(4),
      );
    }
    return Icon(Icons.diamond, color: const Color(0xFFF59E0B), size: size);
  }

  // Helper to format large numbers e.g. 12100 -> 12.1k, 1000000 -> 1M
  String _formatNumber(num value) {
    if (value >= 1000000) {
      final formatted = (value / 1000000).toStringAsFixed(1);
      return '${formatted.endsWith('.0') ? formatted.substring(0, formatted.length - 2) : formatted}M';
    } else if (value >= 1000) {
      final formatted = (value / 1000).toStringAsFixed(1);
      return '${formatted.endsWith('.0') ? formatted.substring(0, formatted.length - 2) : formatted}k';
    } else {
      return value.toInt().toString();
    }
  }

  // Parse Real-time Search ID
  String _getSearchId(Map<String, dynamic> user) {
    for (final key in ['searchId', 'user_id', 'numericId', 'uniqueId', 'shortId', 'id']) {
      final val = user[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return user['id'] ?? '-';
  }

  // Parse Real-time Phone Number
  String _getPhoneNumber(Map<String, dynamic> user) {
    for (final key in ['phone', 'number', 'phoneNumber', 'mobile', 'cell', 'userPhone']) {
      final val = user[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return '-';
  }

  // Parse Real-time Google / Email Address
  String _getEmail(Map<String, dynamic> user) {
    for (final key in ['email', 'googleEmail', 'userEmail', 'mail', 'google', 'user_email']) {
      final val = user[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return '';
  }

  // Parse login provider
  String _getLoginProvider(Map<String, dynamic> user) {
    for (final key in ['loginProvider', 'provider', 'authProvider', 'login_provider']) {
      final val = user[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim().toLowerCase();
      }
    }
    return '';
  }

  String _getFullName(Map<String, dynamic> user) {
    for (final key in ['fullname', 'name', 'username', 'displayName', 'nickname', 'fullName']) {
      final val = user[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return '-';
  }

  String _getPhotoUrl(Map<String, dynamic> user) {
    for (final key in ['photoUrl', 'profileImageUrl', 'avatar', 'imageUrl', 'photo', 'image', 'profileImage']) {
      final val = user[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return '';
  }

  String _getGender(Map<String, dynamic> user) {
    final raw = (user['gender'] ?? user['sex'] ?? '').toString().trim().toLowerCase();
    if (raw == 'male' || raw == 'm' || raw == '1') return 'Male';
    if (raw == 'female' || raw == 'f' || raw == '2') return 'Female';
    if (raw.isNotEmpty && raw != '-') return raw[0].toUpperCase() + raw.substring(1);
    return '-';
  }

  // Beans (formerly Rcoin)
  num _getBeans(Map<String, dynamic> user) {
    for (final key in ['beans', 'totalBeans', 'walletBeans', 'bean', 'beansEarned', 'rcoin', 'rcoins']) {
      final val = user[key];
      if (val != null) {
        if (val is num) return val;
        final parsed = num.tryParse(val.toString());
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  // Real-time Diamonds balance
  num _getDiamonds(Map<String, dynamic> user) {
    for (final key in ['diamonds', 'totalDiamonds', 'walletDiamonds', 'diamond']) {
      final val = user[key];
      if (val != null) {
        if (val is num) return val;
        final parsed = num.tryParse(val.toString());
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  // 1. Sending Level (Wealth / সেন্ডিং লেভেল)
  int _getSendingLevel(Map<String, dynamic> user) {
    if (user['sendingLevel'] is Map) {
      final lvl = user['sendingLevel']['level'];
      if (lvl is num) return lvl.toInt();
      final p = int.tryParse(lvl?.toString() ?? '');
      if (p != null) return p;
    }
    for (final key in ['sendingLevel', 'sending_level', 'sendLevel', 'wealthLevel', 'send_level']) {
      final val = user[key];
      if (val is num) return val.toInt();
      final p = int.tryParse(val?.toString() ?? '');
      if (p != null) return p;
    }
    if (user['level'] != null) {
      final l = user['level'].toString();
      final match = RegExp(r'\d+').firstMatch(l);
      if (match != null) return int.tryParse(match.group(0)!) ?? 1;
    }
    return 1;
  }

  // 2. Receiving Level (Charm / রিসিভিং লেভেল)
  int _getReceivingLevel(Map<String, dynamic> user) {
    if (user['receivingLevel'] is Map) {
      final lvl = user['receivingLevel']['level'];
      if (lvl is num) return lvl.toInt();
      final p = int.tryParse(lvl?.toString() ?? '');
      if (p != null) return p;
    }
    for (final key in ['receivingLevel', 'receiving_level', 'receiveLevel', 'charmLevel', 'receive_level']) {
      final val = user[key];
      if (val is num) return val.toInt();
      final p = int.tryParse(val?.toString() ?? '');
      if (p != null) return p;
    }
    return 1;
  }

  // VIP Level detection: returns "VIP 1", "VIP 2", etc. or "No"
  String _getVipText(Map<String, dynamic> user) {
    int lvl = 0;
    for (final key in ['activeVipLevel', 'vipLevel', 'vip_level']) {
      final v = user[key];
      if (v is num && v > 0) {
        lvl = v.toInt();
        break;
      } else if (v != null) {
        final p = int.tryParse(v.toString());
        if (p != null && p > 0) {
          lvl = p;
          break;
        }
      }
    }

    if (lvl > 0) return 'VIP $lvl';
    if (user['isVIP'] == true || user['isVip'] == true || user['vip'] == true) return 'VIP 1';
    return 'No';
  }

  // SVIP Level detection: returns "SVIP 1", "SVIP 2", etc. or "No"
  String _getSvipText(Map<String, dynamic> user) {
    int lvl = 0;
    for (final key in ['activeSvipLevel', 'svipLevel', 'svip_level']) {
      final v = user[key];
      if (v is num && v > 0) {
        lvl = v.toInt();
        break;
      } else if (v != null) {
        final p = int.tryParse(v.toString());
        if (p != null && p > 0) {
          lvl = p;
          break;
        }
      }
    }

    if (lvl > 0) return 'SVIP $lvl';
    if (user['isSVIP'] == true || user['isSvip'] == true || user['svip'] == true) return 'SVIP 1';
    return 'No';
  }

  // Country detection from phone number dial code & current user location
  String _codeToFlag(String countryCode) {
    final clean = countryCode.trim().toUpperCase();
    if (clean.length != 2) return '🌐';
    try {
      final first = clean.codeUnitAt(0) - 0x41 + 0x1F1E6;
      final second = clean.codeUnitAt(1) - 0x41 + 0x1F1E6;
      return String.fromCharCode(first) + String.fromCharCode(second);
    } catch (_) {
      return '🌐';
    }
  }

  String _detectCountryCode({String? phone, String? countryStr}) {
    if (phone != null && phone.trim().isNotEmpty) {
      String p = phone.trim().replaceAll(RegExp(r'[^\d+]'), '');
      if (p.startsWith('+')) p = p.substring(1);

      // 3-digit dial codes
      if (p.startsWith('880')) return 'BD';
      if (p.startsWith('966')) return 'SA';
      if (p.startsWith('971')) return 'AE';
      if (p.startsWith('974')) return 'QA';
      if (p.startsWith('965')) return 'KW';
      if (p.startsWith('968')) return 'OM';
      if (p.startsWith('973')) return 'BH';
      if (p.startsWith('964')) return 'IQ';
      if (p.startsWith('962')) return 'JO';
      if (p.startsWith('961')) return 'LB';
      if (p.startsWith('963')) return 'SY';
      if (p.startsWith('967')) return 'YE';
      if (p.startsWith('977')) return 'NP';
      if (p.startsWith('886')) return 'TW';
      if (p.startsWith('852')) return 'HK';
      if (p.startsWith('234')) return 'NG';
      if (p.startsWith('212')) return 'MA';
      if (p.startsWith('213')) return 'DZ';
      if (p.startsWith('216')) return 'TN';
      if (p.startsWith('249')) return 'SD';
      if (p.startsWith('254')) return 'KE';

      // 2-digit dial codes
      if (p.startsWith('91')) return 'IN';
      if (p.startsWith('92')) return 'PK';
      if (p.startsWith('60')) return 'MY';
      if (p.startsWith('65')) return 'SG';
      if (p.startsWith('66')) return 'TH';
      if (p.startsWith('84')) return 'VN';
      if (p.startsWith('62')) return 'ID';
      if (p.startsWith('63')) return 'PH';
      if (p.startsWith('90')) return 'TR';
      if (p.startsWith('20')) return 'EG';
      if (p.startsWith('49')) return 'DE';
      if (p.startsWith('33')) return 'FR';
      if (p.startsWith('39')) return 'IT';
      if (p.startsWith('34')) return 'ES';
      if (p.startsWith('44')) return 'GB';
      if (p.startsWith('81')) return 'JP';
      if (p.startsWith('82')) return 'KR';
      if (p.startsWith('86')) return 'CN';
      if (p.startsWith('55')) return 'BR';
      if (p.startsWith('98')) return 'IR';
      if (p.startsWith('93')) return 'AF';
      if (p.startsWith('94')) return 'LK';
      if (p.startsWith('27')) return 'ZA';

      // 1-digit dial codes
      if (p.startsWith('1')) return 'US';
      if (p.startsWith('7')) return 'RU';

      // Bangladesh local mobile prefixes: 013, 014, 015, 016, 017, 018, 019
      if (RegExp(r'^01[3-9]').hasMatch(p)) return 'BD';
    }

    if (countryStr != null && countryStr.trim().isNotEmpty) {
      final c = countryStr.trim().toUpperCase();
      if (c == 'BANGLADESH' || c == 'BD') return 'BD';
      if (c == 'INDIA' || c == 'IN') return 'IN';
      if (c == 'PAKISTAN' || c == 'PK') return 'PK';
      if (c == 'INDONESIA' || c == 'ID') return 'ID';
      if (c == 'SAUDI ARABIA' || c == 'KSA' || c == 'SA') return 'SA';
      if (c == 'UAE' || c == 'UNITED ARAB EMIRATES' || c == 'AE') return 'AE';
      if (c == 'QATAR' || c == 'QA') return 'QA';
      if (c == 'KUWAIT' || c == 'KW') return 'KW';
      if (c == 'OMAN' || c == 'OM') return 'OM';
      if (c == 'BAHRAIN' || c == 'BH') return 'BH';
      if (c == 'MALAYSIA' || c == 'MY') return 'MY';
      if (c == 'USA' || c == 'UNITED STATES' || c == 'US') return 'US';
      if (c == 'UK' || c == 'UNITED KINGDOM' || c == 'GB') return 'GB';
      if (c == 'NEPAL' || c == 'NP') return 'NP';
      if (c == 'PHILIPPINES' || c == 'PH') return 'PH';
      if (c.length == 2) return c;
    }

    return 'BD';
  }

  String _getCountryNameFromCode(String code, {String? fallback}) {
    switch (code.toUpperCase()) {
      case 'BD':
        return 'Bangladesh';
      case 'IN':
        return 'India';
      case 'PK':
        return 'Pakistan';
      case 'ID':
        return 'Indonesia';
      case 'SA':
        return 'Saudi Arabia';
      case 'AE':
        return 'UAE';
      case 'QA':
        return 'Qatar';
      case 'KW':
        return 'Kuwait';
      case 'OM':
        return 'Oman';
      case 'BH':
        return 'Bahrain';
      case 'MY':
        return 'Malaysia';
      case 'SG':
        return 'Singapore';
      case 'US':
        return 'United States';
      case 'GB':
        return 'United Kingdom';
      case 'NP':
        return 'Nepal';
      case 'PH':
        return 'Philippines';
      case 'TH':
        return 'Thailand';
      case 'VN':
        return 'Vietnam';
      case 'TR':
        return 'Turkey';
      case 'EG':
        return 'Egypt';
      case 'NG':
        return 'Nigeria';
      case 'CA':
        return 'Canada';
      default:
        if (fallback != null && fallback.trim().isNotEmpty && fallback.length > 2) {
          return fallback.trim();
        }
        return code;
    }
  }

  Map<String, String> _getCountryData(Map<String, dynamic> user) {
    final phone = _getPhoneNumber(user);
    final countryStr = (user['country'] ?? user['countryName'] ?? user['location'] ?? user['countryCode'] ?? user['isoCountryCode'] ?? user['region'] ?? '').toString();

    final iso = _detectCountryCode(phone: phone, countryStr: countryStr);
    final flag = _codeToFlag(iso);
    final name = _getCountryNameFromCode(iso, fallback: countryStr);

    return {
      'code': iso,
      'flag': flag,
      'name': name,
    };
  }

  bool _isHost(Map<String, dynamic> user) {
    if (user['isHost'] == true || user['host'] == true) return true;
    final userType = (user['userType'] ?? '').toString().toLowerCase();
    if (userType == 'host') return true;
    final roles = user['roles'];
    if (roles is List && roles.any((r) => r.toString().toLowerCase() == 'host')) return true;
    return false;
  }

  String _getStatus(Map<String, dynamic> user) {
    if (user['isBlocked'] == true || user['status'] == 'blocked') return 'Blocked';
    if (user['isSuspended'] == true || user['status'] == 'suspended') return 'Suspended';
    if (user['isOnline'] == true) return 'Online';
    return 'Active';
  }

  String _getUserType(Map<String, dynamic> user) {
    final type = (user['userType'] ?? '').toString().toLowerCase();
    if (type.isNotEmpty) {
      return type[0].toUpperCase() + type.substring(1);
    }
    if (_isHost(user)) return 'Host';
    return 'Regular';
  }

  List<Map<String, dynamic>> get _filteredUsers {
    var list = List<Map<String, dynamic>>.from(_rawUsers);

    // Search filter (real-time name, searchId, phone, email, country, id)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((u) {
        final name = _getFullName(u).toLowerCase();
        final sid = _getSearchId(u).toLowerCase();
        final phone = _getPhoneNumber(u).toLowerCase();
        final email = _getEmail(u).toLowerCase();
        final cData = _getCountryData(u);
        final country = cData['name']!.toLowerCase();
        final id = (u['id'] ?? '').toString().toLowerCase();
        return name.contains(q) || sid.contains(q) || phone.contains(q) || email.contains(q) || country.contains(q) || id.contains(q);
      }).toList();
    }

    // Gender filter
    if (_selectedGender != 'Gender') {
      list = list.where((u) {
        final g = _getGender(u);
        return g.toLowerCase() == _selectedGender.toLowerCase();
      }).toList();
    }

    // Status filter
    if (_selectedStatus != 'All Status') {
      list = list.where((u) {
        final status = _getStatus(u);
        if (_selectedStatus == 'Online') return u['isOnline'] == true;
        if (_selectedStatus == 'Offline') return u['isOnline'] != true;
        return status.toLowerCase() == _selectedStatus.toLowerCase();
      }).toList();
    }

    // User Type filter
    if (_selectedUserType != 'All User Type') {
      list = list.where((u) {
        final type = _getUserType(u);
        if (_selectedUserType == 'Host') return _isHost(u);
        return type.toLowerCase() == _selectedUserType.toLowerCase();
      }).toList();
    }

    // Level filter
    if (_selectedLevel != 'Select Level' && _selectedLevel != 'All Levels') {
      list = list.where((u) {
        final sendLvl = _getSendingLevel(u);
        final recvLvl = _getReceivingLevel(u);
        if (_selectedLevel.startsWith('Send Lv')) {
          final target = int.tryParse(_selectedLevel.replaceAll(RegExp(r'[^\d]'), '')) ?? 1;
          return sendLvl >= target;
        } else if (_selectedLevel.startsWith('Receive Lv')) {
          final target = int.tryParse(_selectedLevel.replaceAll(RegExp(r'[^\d]'), '')) ?? 1;
          return recvLvl >= target;
        } else {
          final target = int.tryParse(_selectedLevel.replaceAll(RegExp(r'[^\d]'), '')) ?? 1;
          return sendLvl == target || recvLvl == target;
        }
      }).toList();
    }

    // Sorting
    if (_sortBy == 'beans') {
      list.sort((a, b) {
        final valA = _getBeans(a);
        final valB = _getBeans(b);
        return _sortAscending ? valA.compareTo(valB) : valB.compareTo(valA);
      });
    } else if (_sortBy == 'diamond') {
      list.sort((a, b) {
        final valA = _getDiamonds(a);
        final valB = _getDiamonds(b);
        return _sortAscending ? valA.compareTo(valB) : valB.compareTo(valA);
      });
    } else if (_sortBy == 'send_level') {
      list.sort((a, b) {
        final valA = _getSendingLevel(a);
        final valB = _getSendingLevel(b);
        return _sortAscending ? valA.compareTo(valB) : valB.compareTo(valA);
      });
    } else if (_sortBy == 'receive_level') {
      list.sort((a, b) {
        final valA = _getReceivingLevel(a);
        final valB = _getReceivingLevel(b);
        return _sortAscending ? valA.compareTo(valB) : valB.compareTo(valA);
      });
    }

    return list;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Copied $label: $text', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;

    return BaseScreen(
      title: 'Users Management',
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UsersHistoryScreen()),
            );
          },
          icon: const Icon(Icons.manage_history, color: Colors.amberAccent),
          tooltip: 'Users History & Activity',
        ),
        IconButton(
          onPressed: _showAddDiamondsOrBeansDialog,
          icon: const Icon(Icons.currency_exchange, color: Colors.blueAccent),
          tooltip: 'Bulk Economy Operations',
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserProfileManagement()),
            );
          },
          icon: const Icon(Icons.tune, color: Colors.purpleAccent),
          tooltip: 'Advanced Profile & Market Management',
        ),
      ],
      body: Container(
        color: const Color(0xFF0F1015),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
            : _currentView == 'analytics'
                ? _buildAnalyticsView()
                : Column(
                    children: [
                      // Top Row: All / Analytics buttons + Search bar
                      _buildTopHeaderBar(),

                      // Filter Row: Gender, All Status, All User Type, Select Level
                      _buildFilterRow(),

                      const SizedBox(height: 12),

                      // Main Table view
                      Expanded(
                        child: _buildUsersTable(filtered),
                      ),
                    ],
                  ),
      ),
    );
  }

  // 1. Top Header Bar (All, Analytics, Search)
  Widget _buildTopHeaderBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          // "All" Button
          InkWell(
            onTap: () {
              setState(() {
                _currentView = 'all';
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: _currentView == 'all' ? const Color(0xFF4C6EF5) : const Color(0xFF1E202B),
                borderRadius: BorderRadius.circular(10),
                boxShadow: _currentView == 'all'
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4C6EF5).withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                'All',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: _currentView == 'all' ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // "Analytics ∨" Button
          InkWell(
            onTap: () {
              _showAnalyticsBottomSheet();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D3D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3B3E52)),
              ),
              child: const Row(
                children: [
                  Text(
                    'Analytics',
                    style: TextStyle(
                      color: Color(0xFF93C5FD),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.keyboard_arrow_down, color: Color(0xFF93C5FD), size: 18),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Search Bar (Real-time by Name, SearchId, Phone or Country)
          Container(
            width: 380,
            constraints: const BoxConstraints(maxWidth: 420),
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1B1D28),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2D3042)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name, searchId, phone, Google/email, country',
                hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                border: InputBorder.none,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Color(0xFFF43F5E), size: 20),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Filter Row (Gender, All Status, All User Type, Select Level)
  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Gender Filter Dropdown
          Expanded(
            child: _buildDropdownFilter(
              value: _selectedGender,
              items: ['Gender', 'Male', 'Female', 'Other'],
              onChanged: (val) {
                setState(() {
                  _selectedGender = val ?? 'Gender';
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // Status Filter Dropdown
          Expanded(
            child: _buildDropdownFilter(
              value: _selectedStatus,
              items: ['All Status', 'Active', 'Blocked', 'Suspended', 'Online', 'Offline'],
              onChanged: (val) {
                setState(() {
                  _selectedStatus = val ?? 'All Status';
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // User Type Filter Dropdown
          Expanded(
            child: _buildDropdownFilter(
              value: _selectedUserType,
              items: ['All User Type', 'Regular', 'Host', 'Seller', 'Admin', 'Agency'],
              onChanged: (val) {
                setState(() {
                  _selectedUserType = val ?? 'All User Type';
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // Level Filter Dropdown (Supports Sending & Receiving levels)
          Expanded(
            child: _buildDropdownFilter(
              value: _selectedLevel,
              items: [
                'Select Level',
                'All Levels',
                'Send Lv 1+',
                'Send Lv 3+',
                'Send Lv 5+',
                'Send Lv 10+',
                'Receive Lv 1+',
                'Receive Lv 3+',
                'Receive Lv 5+',
                'Receive Lv 10+',
                'Level 1',
                'Level 2',
                'Level 3',
                'Level 4',
                'Level 5+',
              ],
              onChanged: (val) {
                setState(() {
                  _selectedLevel = val ?? 'Select Level';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final effectiveValue = items.contains(value) ? value : items.first;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1D28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2D3042)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF), size: 18),
          dropdownColor: const Color(0xFF1E2130),
          isExpanded: true,
          style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13, fontWeight: FontWeight.w500),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: item == effectiveValue ? const Color(0xFF60A5FA) : const Color(0xFFD1D5DB),
                  fontWeight: item == effectiveValue ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 3. Main Table View
  Widget _buildUsersTable(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No users matching "$_searchQuery"' : 'No users found',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double minTableWidth = 1580;
        final double effectiveWidth = constraints.maxWidth < minTableWidth ? minTableWidth : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: effectiveWidth,
            child: Column(
              children: [
                // Table Header Row
                _buildTableHeaderRow(),

                const SizedBox(height: 6),

                // Table List of Rows
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _buildTableRow(index + 1, user);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Header row for table
  Widget _buildTableHeaderRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF13151D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 36, child: Text('No.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w600))),
          const SizedBox(width: 55, child: Text('Image', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w600))),
          const Expanded(flex: 3, child: Text('Name', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w600))),
          const Expanded(flex: 3, child: Text('Search Id', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w600))),
          const Expanded(flex: 4, child: Text('Phone & Google Account', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w600))),
          const Expanded(flex: 2, child: Text('Gender', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w600))),
          
          // Beans Sort Header (with PNG Icon)
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (_sortBy == 'beans') {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortBy = 'beans';
                    _sortAscending = false;
                  }
                });
              },
              child: Row(
                children: [
                  _buildBeansIcon(size: 15),
                  const SizedBox(width: 5),
                  Text(
                    'Beans',
                    style: TextStyle(
                      color: _sortBy == 'beans' ? const Color(0xFF60A5FA) : const Color(0xFF9CA3AF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    _sortBy == 'beans'
                        ? (_sortAscending ? Icons.arrow_drop_up : Icons.arrow_drop_down)
                        : Icons.arrow_drop_down,
                    color: _sortBy == 'beans' ? const Color(0xFF60A5FA) : const Color(0xFF9CA3AF),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Diamond Sort Header (with PNG Icon & Real-time balance)
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (_sortBy == 'diamond') {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortBy = 'diamond';
                    _sortAscending = false;
                  }
                });
              },
              child: Row(
                children: [
                  _buildDiamondIcon(size: 15),
                  const SizedBox(width: 5),
                  Text(
                    'Diamond',
                    style: TextStyle(
                      color: _sortBy == 'diamond' ? const Color(0xFFFBBF24) : const Color(0xFF9CA3AF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    _sortBy == 'diamond'
                        ? (_sortAscending ? Icons.arrow_drop_up : Icons.arrow_drop_down)
                        : Icons.arrow_drop_down,
                    color: _sortBy == 'diamond' ? const Color(0xFFFBBF24) : const Color(0xFF9CA3AF),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Country Header (Phone / Location based)
          const Expanded(flex: 3, child: Text('Country', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w600))),

          // Sending Level Header
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (_sortBy == 'send_level') {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortBy = 'send_level';
                    _sortAscending = false;
                  }
                });
              },
              child: Row(
                children: [
                  const Text('📤 Send Lv', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 2),
                  Icon(
                    _sortBy == 'send_level'
                        ? (_sortAscending ? Icons.arrow_drop_up : Icons.arrow_drop_down)
                        : Icons.arrow_drop_down,
                    color: const Color(0xFF38BDF8),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Receiving Level Header
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (_sortBy == 'receive_level') {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortBy = 'receive_level';
                    _sortAscending = false;
                  }
                });
              },
              child: Row(
                children: [
                  const Text('📥 Recv Lv', style: TextStyle(color: Color(0xFFF472B6), fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 2),
                  Icon(
                    _sortBy == 'receive_level'
                        ? (_sortAscending ? Icons.arrow_drop_up : Icons.arrow_drop_down)
                        : Icons.arrow_drop_down,
                    color: const Color(0xFFF472B6),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // VIP Column Header
          const SizedBox(width: 75, child: Text('VIP', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),

          // SVIP Column Header
          const SizedBox(width: 75, child: Text('SVIP', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),

          // Host Header
          const SizedBox(width: 65, child: Text('is Host', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w600))),

          // Actions Header
          const SizedBox(width: 80, child: Text('Actions', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  // Row item in table
  Widget _buildTableRow(int index, Map<String, dynamic> user) {
    final name = _getFullName(user);
    final photoUrl = _getPhotoUrl(user);
    final searchId = _getSearchId(user);
    final phone = _getPhoneNumber(user);
    final email = _getEmail(user);
    final provider = _getLoginProvider(user);
    final hasPhone = phone != '-' && phone.trim().isNotEmpty;
    final hasEmail = email.isNotEmpty && email != '-';
    final gender = _getGender(user);
    final beans = _getBeans(user);
    final diamonds = _getDiamonds(user);
    final countryData = _getCountryData(user);
    final sendLevel = _getSendingLevel(user);
    final recvLevel = _getReceivingLevel(user);
    final vipText = _getVipText(user);
    final svipText = _getSvipText(user);
    final isHost = _isHost(user);
    final isAgency = user['isAgency'] == true || user['agency'] == true;
    final isSeller = user['isSeller'] == true || user['seller'] == true;
    final isOfficial = user['isOfficial'] == true || user['official'] == true;
    final isOfficialAssistant = user['isOfficialAssistant'] == true;
    final isOnline = user['isOnline'] == true;
    final isVerified = user['isVerified'] == true || user['verified'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151722),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isVerified ? const Color(0xFF2563EB).withValues(alpha: 0.3) : const Color(0xFF222533),
        ),
      ),
      child: Row(
        children: [
          // 1. Index No.
          SizedBox(
            width: 36,
            child: Text(
              '$index',
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),

          // 2. Avatar Image
          SizedBox(
            width: 55,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                photoUrl.isNotEmpty
                    ? MediaPreviewWidget(
                        url: photoUrl,
                        width: 40,
                        height: 40,
                        borderRadius: BorderRadius.circular(8),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E3346),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person, color: Colors.white60, size: 22),
                      ),
                if (isOnline)
                  Positioned(
                    bottom: -2,
                    right: 15,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF151722), width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 3. Name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 16),
                ],
              ],
            ),
          ),

          // 4. Search ID with Copy Icon (Real-time Search ID)
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    searchId,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE5E7EB),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _copyToClipboard(searchId, 'Search ID'),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(Icons.copy, color: Color(0xFF9CA3AF), size: 14),
                  ),
                ),
              ],
            ),
          ),

          // 5. Contact Info: Phone Number & Google / Email Account
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasPhone)
                  Row(
                    children: [
                      const Icon(Icons.phone_iphone, color: Color(0xFF34D399), size: 13),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          phone,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 12.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _copyToClipboard(phone, 'Phone Number'),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(Icons.copy, color: Color(0xFF9CA3AF), size: 12),
                        ),
                      ),
                    ],
                  ),
                if (hasPhone && hasEmail)
                  const SizedBox(height: 3),
                if (hasEmail)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: (provider == 'google' || email.toLowerCase().contains('gmail'))
                              ? const Color(0xFFEA4335).withValues(alpha: 0.2)
                              : const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: (provider == 'google' || email.toLowerCase().contains('gmail'))
                                ? const Color(0xFFEA4335).withValues(alpha: 0.4)
                                : const Color(0xFF3B82F6).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          (provider == 'google' || email.toLowerCase().contains('gmail')) ? 'G' : '@',
                          style: TextStyle(
                            color: (provider == 'google' || email.toLowerCase().contains('gmail'))
                                ? const Color(0xFFF87171)
                                : const Color(0xFF60A5FA),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFCA5A5),
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _copyToClipboard(email, 'Google / Email'),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(Icons.copy, color: Color(0xFF9CA3AF), size: 12),
                        ),
                      ),
                    ],
                  ),
                if (!hasPhone && !hasEmail)
                  const Text(
                    '-',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
              ],
            ),
          ),

          // 6. Gender
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (gender.toLowerCase() == 'male') ...[
                  const Icon(Icons.male, color: Color(0xFF60A5FA), size: 16),
                  const SizedBox(width: 4),
                  const Text('Male', style: TextStyle(color: Color(0xFFE5E7EB), fontSize: 13)),
                ] else if (gender.toLowerCase() == 'female') ...[
                  const Icon(Icons.female, color: Color(0xFFF472B6), size: 16),
                  const SizedBox(width: 4),
                  const Text('Female', style: TextStyle(color: Color(0xFFE5E7EB), fontSize: 13)),
                ] else ...[
                  const Icon(Icons.transgender, color: Color(0xFF9CA3AF), size: 15),
                  const SizedBox(width: 4),
                  Text(gender == '-' ? '-' : gender, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                ],
              ],
            ),
          ),

          // 7. Beans (App PNG / Icon + formatted number)
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _buildBeansIcon(size: 18),
                const SizedBox(width: 6),
                Text(
                  _formatNumber(beans),
                  style: const TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 8. Diamond (App Real-time PNG / Icon + formatted number)
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _buildDiamondIcon(size: 18),
                const SizedBox(width: 5),
                Text(
                  _formatNumber(diamonds),
                  style: const TextStyle(
                    color: Color(0xFFFCD34D),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 9. Country (Detected from phone dial code / location + flag emoji)
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text(
                  countryData['flag'] ?? '🌐',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    countryData['name'] ?? 'Bangladesh',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 10. Sending Level (Real-time Lv)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.send_rounded, color: Color(0xFF38BDF8), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Lv.$sendLevel',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 11. Receiving Level (Real-time Lv)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDB2777).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF472B6).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.call_received_rounded, color: Color(0xFFF472B6), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Lv.$recvLevel',
                    style: const TextStyle(
                      color: Color(0xFFF472B6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 12. VIP Level (e.g. VIP 1, VIP 2 or No)
          SizedBox(
            width: 75,
            child: Center(
              child: vipText != 'No'
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        vipText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const Text(
                      'No',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
            ),
          ),

          // 13. SVIP Level (e.g. SVIP 1, SVIP 2, SVIP 3 or No)
          SizedBox(
            width: 75,
            child: Center(
              child: svipText != 'No'
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFA855F7).withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        svipText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const Text(
                      'No',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
            ),
          ),

          // 14. is Host
          SizedBox(
            width: 65,
            child: Text(
              isHost ? 'Yes' : 'No',
              style: TextStyle(
                color: isHost ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                fontSize: 13,
                fontWeight: isHost ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          // 15. Actions Menu
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_note, color: Color(0xFF60A5FA), size: 20),
                  tooltip: 'Edit Balance, Search ID, Levels & VIP',
                  onPressed: () => _showUserEditDialog(user),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF9CA3AF), size: 18),
                  color: const Color(0xFF1E2130),
                  onSelected: (action) => _handleUserAction(action, user),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit_balance',
                      child: Row(
                        children: [
                          const Icon(Icons.currency_exchange, color: Colors.blueAccent, size: 18),
                          const SizedBox(width: 8),
                          Text('Edit User Data', style: TextStyle(color: Colors.grey[200], fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 8),
                    PopupMenuItem(
                      value: 'toggle_host',
                      child: Row(
                        children: [
                          Icon(isHost ? Icons.mic_off : Icons.mic, color: const Color(0xFF10B981), size: 18),
                          const SizedBox(width: 8),
                          Text(isHost ? 'Remove Host' : 'Make Host 🎙️', style: TextStyle(color: Colors.grey[200], fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_agency',
                      child: Row(
                        children: [
                          Icon(isAgency ? Icons.domain_disabled : Icons.apartment, color: const Color(0xFF3B82F6), size: 18),
                          const SizedBox(width: 8),
                          Text(isAgency ? 'Remove Agency' : 'Make Agency 🏢', style: TextStyle(color: Colors.grey[200], fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_seller',
                      child: Row(
                        children: [
                          Icon(isSeller ? Icons.remove_shopping_cart : Icons.store, color: const Color(0xFFF59E0B), size: 18),
                          const SizedBox(width: 8),
                          Text(isSeller ? 'Remove Seller' : 'Make Seller 🛒', style: TextStyle(color: Colors.grey[200], fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_official',
                      child: Row(
                        children: [
                          Icon(isOfficial ? Icons.remove_moderator : Icons.verified, color: const Color(0xFF8B5CF6), size: 18),
                          const SizedBox(width: 8),
                          Text(isOfficial ? 'Remove Official' : 'Make Official 🛡️', style: TextStyle(color: Colors.grey[200], fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_official_assistant',
                      child: Row(
                        children: [
                          Icon(isOfficialAssistant ? Icons.person_off : Icons.support_agent, color: const Color(0xFFEC4899), size: 18),
                          const SizedBox(width: 8),
                          Text(isOfficialAssistant ? 'Remove Official Asst' : 'Make Official Asst 🎖️', style: TextStyle(color: Colors.grey[200], fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'manage_positions',
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium, color: Color(0xFF38BDF8), size: 18),
                          const SizedBox(width: 8),
                          Text('Positions Manager', style: TextStyle(color: Colors.grey[200], fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 8),
                    PopupMenuItem(
                      value: 'toggle_vip',
                      child: Row(
                        children: [
                          Icon(vipText != 'No' ? Icons.star_border : Icons.star, color: Colors.amberAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(vipText != 'No' ? 'Remove VIP' : 'Set as VIP (Lv 1)', style: TextStyle(color: Colors.grey[200], fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_svip',
                      child: Row(
                        children: [
                          Icon(svipText != 'No' ? Icons.diamond_outlined : Icons.diamond, color: Colors.purpleAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(svipText != 'No' ? 'Remove SVIP' : 'Set as SVIP (Lv 1)', style: TextStyle(color: Colors.grey[200], fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_verified',
                      child: Row(
                        children: [
                          Icon(isVerified ? Icons.verified_user_outlined : Icons.verified, color: Colors.cyanAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(isVerified ? 'Remove Verified' : 'Verify Badge', style: TextStyle(color: Colors.grey[200], fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 8),
                    PopupMenuItem(
                      value: 'toggle_block',
                      child: Row(
                        children: [
                          Icon(user['isBlocked'] == true ? Icons.lock_open : Icons.block, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(user['isBlocked'] == true ? 'Unblock User' : 'Block User', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Analytics Sheet / View
  void _showAnalyticsBottomSheet() {
    final total = _rawUsers.length;
    final online = _rawUsers.where((u) => u['isOnline'] == true).length;
    final hosts = _rawUsers.where((u) => _isHost(u)).length;
    final vips = _rawUsers.where((u) => _getVipText(u) != 'No').length;
    final svips = _rawUsers.where((u) => _getSvipText(u) != 'No').length;
    num totalDiamonds = 0;
    num totalBeans = 0;

    for (final u in _rawUsers) {
      totalDiamonds += _getDiamonds(u);
      totalBeans += _getBeans(u);
    }

    // Country distribution based on phone/location
    final Map<String, int> countryCounts = {};
    for (final u in _rawUsers) {
      final c = _getCountryData(u);
      final key = '${c['flag']} ${c['name']}';
      countryCounts[key] = (countryCounts[key] ?? 0) + 1;
    }
    final sortedCountries = countryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF13151F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, color: Color(0xFF60A5FA), size: 26),
                  const SizedBox(width: 10),
                  const Text(
                    'User Community Analytics',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Total Users', '$total', Icons.people, const Color(0xFF3B82F6))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMetricCard('Online Now', '$online', Icons.wifi, const Color(0xFF10B981))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMetricCard('Active Hosts', '$hosts', Icons.mic, const Color(0xFF8B5CF6))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMetricCard('VIPs / SVIPs', '$vips / $svips', Icons.star, const Color(0xFFF59E0B))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181A26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildDiamondIcon(size: 22),
                              const Spacer(),
                              Text(
                                _formatNumber(totalDiamonds),
                                style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Total Diamonds (Live)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181A26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildBeansIcon(size: 22),
                              const Spacer(),
                              Text(
                                _formatNumber(totalBeans),
                                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Total Beans', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Phone Location & Demographics',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sortedCountries.take(6).map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2130),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2D3042)),
                    ),
                    child: Text(
                      '${e.key}: ${e.value}',
                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _currentView = 'all';
                  });
                },
              ),
              const Text(
                'Platform User Analytics',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Metrics
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Users', '${_rawUsers.length}', Icons.people, const Color(0xFF3B82F6))),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('Online Users', '${_rawUsers.where((u) => u['isOnline'] == true).length}', Icons.wifi, const Color(0xFF10B981))),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('Hosts', '${_rawUsers.where((u) => _isHost(u)).length}', Icons.mic, const Color(0xFF8B5CF6))),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('VIPs', '${_rawUsers.where((u) => _getVipText(u) != "No").length}', Icons.star, const Color(0xFFF59E0B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181A26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
        ],
      ),
    );
  }

  // 5. Actions Handlers & Modals
  void _handleUserAction(String action, Map<String, dynamic> user) async {
    final userId = user['id'] ?? '';
    final name = _getFullName(user);

    switch (action) {
      case 'edit_balance':
        _showUserEditDialog(user);
        break;

      case 'manage_positions':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UserPositionManagementScreen(),
          ),
        );
        break;

      case 'toggle_host':
        final isHost = _isHost(user);
        final nextHost = !isHost;
        await _firestore.collection('Users').doc(userId).update({
          'isHost': nextHost,
          'userType': nextHost ? 'host' : 'regular',
        });
        try {
          if (nextHost) {
            await UserPositionService.applyPositionToUser(
              userId: userId,
              positionKey: 'host',
              userName: name,
            );
          } else {
            await UserPositionService.removePositionFromUser(
              userId: userId,
              positionKey: 'host',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error updating host position items: $e');
        }
        _showSuccessSnackBar('$name is now ${nextHost ? "a Host 🎙️" : "a Regular User"}');
        break;

      case 'toggle_agency':
        final isAgency = user['isAgency'] == true || user['agency'] == true;
        final nextAgency = !isAgency;
        await _firestore.collection('Users').doc(userId).update({
          'isAgency': nextAgency,
          'userType': nextAgency ? 'agency' : 'regular',
        });
        try {
          if (nextAgency) {
            await UserPositionService.applyPositionToUser(
              userId: userId,
              positionKey: 'agency',
              userName: name,
            );
          } else {
            await UserPositionService.removePositionFromUser(
              userId: userId,
              positionKey: 'agency',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error updating agency position items: $e');
        }
        _showSuccessSnackBar('$name is now ${nextAgency ? "an Agency 🏢" : "a Regular User"}');
        break;

      case 'toggle_seller':
        final isSeller = user['isSeller'] == true || user['seller'] == true;
        final nextSeller = !isSeller;
        await _firestore.collection('Users').doc(userId).update({
          'isSeller': nextSeller,
        });
        try {
          if (nextSeller) {
            await UserPositionService.applyPositionToUser(
              userId: userId,
              positionKey: 'seller',
              userName: name,
            );
          } else {
            await UserPositionService.removePositionFromUser(
              userId: userId,
              positionKey: 'seller',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error updating seller position items: $e');
        }
        _showSuccessSnackBar('$name is now ${nextSeller ? "a Seller 🛒" : "a Regular User"}');
        break;

      case 'toggle_official':
        final isOfficial = user['isOfficial'] == true || user['official'] == true;
        final nextOfficial = !isOfficial;
        await _firestore.collection('Users').doc(userId).update({
          'isOfficial': nextOfficial,
        });
        try {
          if (nextOfficial) {
            await UserPositionService.applyPositionToUser(
              userId: userId,
              positionKey: 'official',
              userName: name,
            );
          } else {
            await UserPositionService.removePositionFromUser(
              userId: userId,
              positionKey: 'official',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error updating official position items: $e');
        }
        _showSuccessSnackBar('$name is now ${nextOfficial ? "an Official 🛡️" : "a Regular User"}');
        break;

      case 'toggle_official_assistant':
        final isOfficialAsst = user['isOfficialAssistant'] == true;
        final nextOfficialAsst = !isOfficialAsst;
        await _firestore.collection('Users').doc(userId).update({
          'isOfficialAssistant': nextOfficialAsst,
        });
        try {
          if (nextOfficialAsst) {
            await UserPositionService.applyPositionToUser(
              userId: userId,
              positionKey: 'official_assistant',
              userName: name,
            );
          } else {
            await UserPositionService.removePositionFromUser(
              userId: userId,
              positionKey: 'official_assistant',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error updating official assistant position items: $e');
        }
        _showSuccessSnackBar('$name is now ${nextOfficialAsst ? "an Official Assistant 🎖️" : "a Regular User"}');
        break;

      case 'toggle_vip':
        final isVip = _getVipText(user) != 'No';
        final nextVip = !isVip;
        await _firestore.collection('Users').doc(userId).update({
          'isVIP': nextVip,
          'isVip': nextVip,
          'activeVipLevel': nextVip ? 1 : 0,
          'vipLevel': nextVip ? 1 : 0,
        });
        _showSuccessSnackBar('$name VIP status updated to ${nextVip ? "Active (VIP 1)" : "No"}');
        break;

      case 'toggle_svip':
        final isSvip = _getSvipText(user) != 'No';
        final nextSvip = !isSvip;
        await _firestore.collection('Users').doc(userId).update({
          'isSVIP': nextSvip,
          'isSvip': nextSvip,
          'activeSvipLevel': nextSvip ? 1 : 0,
          'svipLevel': nextSvip ? 1 : 0,
        });
        _showSuccessSnackBar('$name SVIP status updated to ${nextSvip ? "Active (SVIP 1)" : "No"}');
        break;

      case 'toggle_verified':
        final isVerified = user['isVerified'] == true || user['verified'] == true;
        final nextVerified = !isVerified;
        if (nextVerified) {
          await _firestore.collection('Users').doc(userId).update({
            'isVerified': true,
            'verified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
            'verifiedBadge': 'blue_tick',
            'verifiedTitle': 'Verified User',
          });
        } else {
          await _firestore.collection('Users').doc(userId).update({
            'isVerified': false,
            'verified': false,
            'verifiedAt': FieldValue.delete(),
            'verifiedBadge': FieldValue.delete(),
            'verifiedTitle': FieldValue.delete(),
          });
        }
        _showSuccessSnackBar('$name badge ${nextVerified ? "Verified ✅" : "Removed ❌"}');
        break;

      case 'toggle_block':
        final isBlocked = user['isBlocked'] == true || user['status'] == 'blocked';
        final nextBlocked = !isBlocked;
        await _firestore.collection('Users').doc(userId).update({
          'isBlocked': nextBlocked,
          'status': nextBlocked ? 'blocked' : 'active',
        });
        _showSuccessSnackBar('$name is now ${nextBlocked ? "Blocked 🚫" : "Active ✅"}');
        break;
    }
  }

  void _showUserEditDialog(Map<String, dynamic> user) {
    final userId = user['id'] ?? '';
    final name = _getFullName(user);
    final currentSearchId = _getSearchId(user);
    final currentPhone = _getPhoneNumber(user);
    final currentEmail = _getEmail(user);
    final currentDiamonds = _getDiamonds(user);
    final currentBeans = _getBeans(user);
    final currentSendLevel = _getSendingLevel(user);
    final currentRecvLevel = _getReceivingLevel(user);
    
    // Parse VIP level number
    int currentVipLvl = 0;
    final vipStr = _getVipText(user);
    if (vipStr.startsWith('VIP ')) {
      currentVipLvl = int.tryParse(vipStr.replaceAll('VIP ', '')) ?? 1;
    }

    // Parse SVIP level number
    int currentSvipLvl = 0;
    final svipStr = _getSvipText(user);
    if (svipStr.startsWith('SVIP ')) {
      currentSvipLvl = int.tryParse(svipStr.replaceAll('SVIP ', '')) ?? 1;
    }

    final searchIdController = TextEditingController(text: currentSearchId == '-' ? '' : currentSearchId);
    final phoneController = TextEditingController(text: currentPhone == '-' ? '' : currentPhone);
    final emailController = TextEditingController(text: currentEmail == '-' ? '' : currentEmail);
    final diamondsController = TextEditingController(text: currentDiamonds.toString());
    final beansController = TextEditingController(text: currentBeans.toString());
    final sendLevelController = TextEditingController(text: currentSendLevel.toString());
    final recvLevelController = TextEditingController(text: currentRecvLevel.toString());
    final vipLevelController = TextEditingController(text: currentVipLvl.toString());
    final svipLevelController = TextEditingController(text: currentSvipLvl.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E2130),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Color(0xFF60A5FA)),
            const SizedBox(width: 8),
            Text('Edit User Data: $name', style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchIdController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.fingerprint, color: Color(0xFF60A5FA), size: 20),
                          labelText: 'Search ID',
                          labelStyle: const TextStyle(color: Color(0xFF93C5FD)),
                          filled: true,
                          fillColor: const Color(0xFF141622),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.phone, color: Color(0xFF34D399), size: 20),
                          labelText: 'Phone Number',
                          labelStyle: const TextStyle(color: Color(0xFF34D399)),
                          filled: true,
                          fillColor: const Color(0xFF141622),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFFF87171), size: 20),
                    labelText: 'Google / Email Account',
                    labelStyle: const TextStyle(color: Color(0xFFF87171)),
                    filled: true,
                    fillColor: const Color(0xFF141622),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: diamondsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: _buildDiamondIcon(size: 20),
                    ),
                    labelText: 'Diamonds (Live App Balance)',
                    labelStyle: const TextStyle(color: Color(0xFFF59E0B)),
                    filled: true,
                    fillColor: const Color(0xFF141622),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: beansController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: _buildBeansIcon(size: 20),
                    ),
                    labelText: 'Beans',
                    labelStyle: const TextStyle(color: Color(0xFF60A5FA)),
                    filled: true,
                    fillColor: const Color(0xFF141622),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sendLevelController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Sending Lv 📤',
                          labelStyle: const TextStyle(color: Color(0xFF38BDF8)),
                          filled: true,
                          fillColor: const Color(0xFF141622),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: recvLevelController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Receiving Lv 📥',
                          labelStyle: const TextStyle(color: Color(0xFFF472B6)),
                          filled: true,
                          fillColor: const Color(0xFF141622),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: vipLevelController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'VIP Level (0 = No)',
                          labelStyle: const TextStyle(color: Color(0xFFF59E0B)),
                          filled: true,
                          fillColor: const Color(0xFF141622),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: svipLevelController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'SVIP Level (0 = No)',
                          labelStyle: const TextStyle(color: Color(0xFFA855F7)),
                          filled: true,
                          fillColor: const Color(0xFF141622),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final newSearchId = searchIdController.text.trim();
              final newPhone = phoneController.text.trim();
              final newEmail = emailController.text.trim();
              final newDiamonds = int.tryParse(diamondsController.text) ?? currentDiamonds.toInt();
              final newBeans = int.tryParse(beansController.text) ?? currentBeans.toInt();
              final newSendLevel = int.tryParse(sendLevelController.text) ?? currentSendLevel;
              final newRecvLevel = int.tryParse(recvLevelController.text) ?? currentRecvLevel;
              final newVipLvl = int.tryParse(vipLevelController.text) ?? 0;
              final newSvipLvl = int.tryParse(svipLevelController.text) ?? 0;

              final updateData = <String, dynamic>{
                'diamonds': newDiamonds,
                'totalDiamonds': newDiamonds,
                'walletDiamonds': newDiamonds,
                'beans': newBeans,
                'totalBeans': newBeans,
                'walletBeans': newBeans,
                'rcoin': newBeans,
                'rcoins': newBeans,
                'email': newEmail,
                'googleEmail': newEmail,
                'sendingLevel': {
                  'level': newSendLevel,
                  'levelName': 'Level $newSendLevel',
                  'lastUpdated': FieldValue.serverTimestamp(),
                },
                'receivingLevel': {
                  'level': newRecvLevel,
                  'levelName': 'Level $newRecvLevel',
                  'lastUpdated': FieldValue.serverTimestamp(),
                },
                'activeVipLevel': newVipLvl,
                'vipLevel': newVipLvl,
                'isVIP': newVipLvl > 0,
                'isVip': newVipLvl > 0,
                'activeSvipLevel': newSvipLvl,
                'svipLevel': newSvipLvl,
                'isSVIP': newSvipLvl > 0,
                'isSvip': newSvipLvl > 0,
              };

              if (newSearchId.isNotEmpty) {
                updateData['searchId'] = newSearchId;
                updateData['uniqueId'] = newSearchId;
                updateData['user_id'] = newSearchId;
              }

              if (newPhone.isNotEmpty) {
                updateData['phone'] = newPhone;
                updateData['number'] = newPhone;
                updateData['phoneNumber'] = newPhone;
              }

              await _firestore.collection('Users').doc(userId).update(updateData);

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              _showSuccessSnackBar('Data updated for $name');
            },
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddDiamondsOrBeansDialog() {
    final amountController = TextEditingController();
    String currencyType = 'diamonds';
    String? selectedUserId;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E2130),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Add Currency to User', style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF141622),
                    initialValue: currencyType,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Currency Type',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF141622),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'diamonds',
                        child: Row(
                          children: [
                            _buildDiamondIcon(size: 18),
                            const SizedBox(width: 8),
                            const Text('Diamonds'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'beans',
                        child: Row(
                          children: [
                            _buildBeansIcon(size: 18),
                            const SizedBox(width: 8),
                            const Text('Beans'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => currencyType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF141622),
                    initialValue: selectedUserId,
                    hint: const Text('Select User', style: TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Select Target User',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF141622),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: _rawUsers.map((u) {
                      final sid = _getSearchId(u);
                      final uname = _getFullName(u);
                      return DropdownMenuItem(
                        value: u['id']?.toString() ?? '',
                        child: Text('$uname (Search ID: $sid)', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() => selectedUserId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Amount to Add',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF141622),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                onPressed: () async {
                  if (selectedUserId == null || amountController.text.trim().isEmpty) return;
                  final addAmt = int.tryParse(amountController.text.trim()) ?? 0;
                  if (addAmt <= 0) return;

                  final docRef = _firestore.collection('Users').doc(selectedUserId);
                  if (currencyType == 'diamonds') {
                    await docRef.update({
                      'diamonds': FieldValue.increment(addAmt),
                      'totalDiamonds': FieldValue.increment(addAmt),
                      'walletDiamonds': FieldValue.increment(addAmt),
                    });
                  } else {
                    await docRef.update({
                      'beans': FieldValue.increment(addAmt),
                      'totalBeans': FieldValue.increment(addAmt),
                      'walletBeans': FieldValue.increment(addAmt),
                      'rcoin': FieldValue.increment(addAmt),
                      'rcoins': FieldValue.increment(addAmt),
                    });
                  }

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  _showSuccessSnackBar('Added $addAmt $currencyType to user!');
                },
                child: const Text('Add Currency', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSuccessSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
