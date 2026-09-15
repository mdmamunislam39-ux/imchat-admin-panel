import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:imchat_adminpanel/widgets/web_iframe_view.dart';
import 'html5_games/king_queen_slot_management_view.dart';
import 'html5_games/greedy_delicious_management_view.dart';
import 'html5_games/greedy_cat_management_view.dart';
import 'html5_games/gem_spin_slot_management_view.dart';
import 'html5_games/ludo_game_management_view.dart';

class Html5GameManagementScreen extends StatefulWidget {
  const Html5GameManagementScreen({super.key});

  @override
  State<Html5GameManagementScreen> createState() =>
      _Html5GameManagementScreenState();
}

class _Html5GameManagementScreenState extends State<Html5GameManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Multi-game serial switcher state
  String _selectedGameKey = 'greedy_market'; // 'greedy_market', 'greedy_delicious', 'king_queen_slot'

  String get _currentConfigDoc =>
      _selectedGameKey == 'greedy_delicious'
          ? 'html5_greedy_delicious'
          : 'html5_greedy_game';

  String get _currentGameId =>
      _selectedGameKey == 'greedy_delicious'
          ? 'html5_greedy_delicious'
          : 'html5_greedy_market';

  String get _currentGameName =>
      _selectedGameKey == 'greedy_delicious'
          ? 'Greedy Delicious'
          : 'Greedy Market';

  String get _currentGameUrl =>
      _selectedGameKey == 'greedy_delicious'
          ? 'https://greedy-delicious-game.web.app'
          : 'https://greedy-market-game.web.app';

  String get _currentLocalUrl =>
      _selectedGameKey == 'greedy_delicious'
          ? 'http://localhost:8080'
          : 'http://localhost:3000';

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isActive = true;

  // --- 1. UI & Themes Controllers ---
  final TextEditingController _logoUrlCtrl = TextEditingController();
  final TextEditingController _gameBackgroundUrlCtrl = TextEditingController();
  final TextEditingController _basicBgCtrl = TextEditingController();
  final TextEditingController _advanceBgCtrl = TextEditingController();
  final TextEditingController _diamondIconCtrl = TextEditingController();
  final TextEditingController _jackpotIconCtrl = TextEditingController();
  final TextEditingController _trophyIconCtrl = TextEditingController();
  final TextEditingController _winBannerCtrl = TextEditingController();

  // --- Fruit and Pizza Badge Pictures & Labels ---
  final TextEditingController _fruitBadgeIconCtrl = TextEditingController(
    text: 'https://cdn-icons-png.flaticon.com/512/3143/3143643.png',
  );
  final TextEditingController _pizzaBadgeIconCtrl = TextEditingController(
    text: 'https://cdn-icons-png.flaticon.com/512/3595/3595455.png',
  );
  final TextEditingController _fruitBadgeLabelCtrl = TextEditingController(
    text: 'Fruit',
  );
  final TextEditingController _pizzaBadgeLabelCtrl = TextEditingController(
    text: 'Pizza',
  );

  // --- 2. 8 Game Items & Multipliers Controllers ---
  final List<TextEditingController> _itemNames = [];
  final List<TextEditingController> _itemIcons = [];
  final List<TextEditingController> _itemMultipliers = [];

  // --- 3. 5 Chip Options Controllers ---
  final List<TextEditingController> _chipLabels = [];
  final List<TextEditingController> _chipValues = [];
  final List<TextEditingController> _chipIcons = [];
  final List<TextEditingController> _chipColors = [];

  // --- 4. Game Rules & Mechanics Controllers ---
  double _winRatio = 65.0;
  final TextEditingController _betTimeCtrl = TextEditingController(text: '30');
  final TextEditingController _spinTimeCtrl = TextEditingController(text: '6');
  final TextEditingController _resultTimeCtrl = TextEditingController(
    text: '5',
  );
  final TextEditingController _jackpotBaseCtrl = TextEditingController(
    text: '1258400',
  );
  int _forceWinnerIndex = -1; // -1 = Random RTP, 0-7 = specific slot

  // Uploading state tracking
  final Map<String, bool> _uploadingStates = {};

  // --- 5. COMPREHENSIVE UI LAYOUT STATE FOR EVERY SINGLE ELEMENT ---
  double _wheelScale = 1.0;
  Map<String, dynamic> _spokesLayout = {
    'strokeWidth': 4.5,
    'color': '#8A4128',
    'opacity': 0.9,
  };
  List<Map<String, double>> _slotLayouts = [];
  Map<String, double> _hubLayout = {'top': 106.0, 'left': 106.0, 'size': 108.0};
  Map<String, double> _fruitBadgeLayout = {
    'top': 246.0,
    'left': 8.0,
    'width': 48.0,
    'height': 34.0,
  };
  Map<String, double> _pizzaBadgeLayout = {
    'top': 246.0,
    'left': 268.0,
    'width': 48.0,
    'height': 34.0,
  };
  Map<String, double> _topHeaderLayout = {'top': 0.0};
  Map<String, double> _trophyLayout = {'top': 46.0, 'left': 10.0};
  Map<String, double> _rightActionsLayout = {'top': 0.0, 'right': 0.0};
  Map<String, double> _arenaLayout = {'marginTop': 14.0, 'marginBottom': 8.0};
  Map<String, double> _skylineLayout = {'top': 360.0, 'height': 110.0};
  Map<String, double> _todaysWinLayout = {'marginTop': 0.0};
  Map<String, double> _wagerPromptLayout = {'marginTop': 0.0};
  Map<String, double> _chipTrayLayout = {'marginTop': 0.0};
  Map<String, double> _milestonesLayout = {'marginTop': 0.0};
  Map<String, double> _historyRowLayout = {'marginTop': 0.0};

  int _selectedElementIndex = 0;
  double _wheelCircleRadius = 120.0;
  double _globalCardWidth = 70.0;
  double _globalCardHeight = 76.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    // Initialize 8 items default controllers
    for (int i = 0; i < 8; i++) {
      _itemNames.add(TextEditingController());
      _itemIcons.add(TextEditingController());
      _itemMultipliers.add(TextEditingController(text: '5'));
    }

    // Initialize 5 chips default controllers
    for (int i = 0; i < 5; i++) {
      _chipLabels.add(TextEditingController());
      _chipValues.add(TextEditingController());
      _chipIcons.add(TextEditingController());
      _chipColors.add(TextEditingController());
    }

    _initDefaultLayouts();
    _loadGameConfig();
  }

  void _initDefaultLayouts() {
    _wheelScale = 1.0;
    _spokesLayout = {'strokeWidth': 4.5, 'color': '#8A4128', 'opacity': 0.9};
    _slotLayouts = [
      {
        'top': 0.0,
        'left': 125.0,
        'width': 70.0,
        'height': 76.0,
        'scale': 1.0,
      }, // 0: Apple (12:00)
      {
        'top': 32.0,
        'left': 216.0,
        'width': 70.0,
        'height': 76.0,
        'scale': 1.0,
      }, // 1: Lemon (1:30)
      {
        'top': 122.0,
        'left': 250.0,
        'width': 70.0,
        'height': 76.0,
        'scale': 1.0,
      }, // 2: Strawberry (3:00)
      {
        'top': 212.0,
        'left': 216.0,
        'width': 70.0,
        'height': 76.0,
        'scale': 1.0,
      }, // 3: Mango (4:30)
      {
        'top': 244.0,
        'left': 125.0,
        'width': 70.0,
        'height': 76.0,
        'scale': 1.0,
      }, // 4: Fish (6:00)
      {
        'top': 212.0,
        'left': 34.0,
        'width': 70.0,
        'height': 76.0,
        'scale': 1.0,
      }, // 5: Burger (7:30)
      {
        'top': 122.0,
        'left': 0.0,
        'width': 70.0,
        'height': 76.0,
        'scale': 1.0,
      }, // 6: Pizza (9:00)
      {
        'top': 32.0,
        'left': 34.0,
        'width': 70.0,
        'height': 76.0,
        'scale': 1.0,
      }, // 7: Chicken (10:30)
    ];
    _hubLayout = {'top': 106.0, 'left': 106.0, 'size': 108.0, 'scale': 1.0};
    _fruitBadgeLayout = {
      'top': 246.0,
      'left': 8.0,
      'width': 48.0,
      'height': 34.0,
      'scale': 1.0,
    };
    _pizzaBadgeLayout = {
      'top': 246.0,
      'left': 268.0,
      'width': 48.0,
      'height': 34.0,
      'scale': 1.0,
    };
    _topHeaderLayout = {'top': 0.0};
    _trophyLayout = {'top': 46.0, 'left': 10.0};
    _rightActionsLayout = {'top': 0.0, 'right': 0.0};
    _arenaLayout = {'marginTop': 14.0, 'marginBottom': 8.0};
    _skylineLayout = {'top': 360.0, 'height': 110.0};
    _todaysWinLayout = {'marginTop': 0.0};
    _wagerPromptLayout = {'marginTop': 0.0};
    _chipTrayLayout = {'marginTop': 0.0};
    _milestonesLayout = {'marginTop': 0.0};
    _historyRowLayout = {'marginTop': 0.0};
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logoUrlCtrl.dispose();
    _gameBackgroundUrlCtrl.dispose();
    _basicBgCtrl.dispose();
    _advanceBgCtrl.dispose();
    _diamondIconCtrl.dispose();
    _jackpotIconCtrl.dispose();
    _trophyIconCtrl.dispose();
    _winBannerCtrl.dispose();
    _fruitBadgeIconCtrl.dispose();
    _pizzaBadgeIconCtrl.dispose();
    _fruitBadgeLabelCtrl.dispose();
    _pizzaBadgeLabelCtrl.dispose();
    _betTimeCtrl.dispose();
    _spinTimeCtrl.dispose();
    _resultTimeCtrl.dispose();
    _jackpotBaseCtrl.dispose();

    for (var c in _itemNames) {
      c.dispose();
    }
    for (var c in _itemIcons) {
      c.dispose();
    }
    for (var c in _itemMultipliers) {
      c.dispose();
    }

    for (var c in _chipLabels) {
      c.dispose();
    }
    for (var c in _chipValues) {
      c.dispose();
    }
    for (var c in _chipIcons) {
      c.dispose();
    }
    for (var c in _chipColors) {
      c.dispose();
    }

    super.dispose();
  }

  Future<void> _loadGameConfig() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _firestore
          .collection('config')
          .doc(_currentConfigDoc)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _isActive = data['isActive'] ?? true;
        _logoUrlCtrl.text = data['logoUrl'] ?? '';
        _gameBackgroundUrlCtrl.text =
            data['gameBackgroundUrl'] ?? data['basicBg'] ?? '';
        _basicBgCtrl.text = data['basicBg'] ?? '';
        _advanceBgCtrl.text = data['advanceBg'] ?? '';
        _diamondIconCtrl.text =
            data['diamondIcon'] ??
            'https://cdn-icons-png.flaticon.com/512/9496/9496739.png';
        _jackpotIconCtrl.text =
            data['jackpotIcon'] ??
            'https://cdn-icons-png.flaticon.com/512/2645/2645897.png';
        _trophyIconCtrl.text =
            data['trophyIcon'] ??
            'https://cdn-icons-png.flaticon.com/512/3112/3112946.png';
        _winBannerCtrl.text =
            data['winBannerUrl'] ??
            'https://cdn-icons-png.flaticon.com/512/10303/10303668.png';

        _fruitBadgeIconCtrl.text =
            data['fruitBadgeIcon'] ??
            'https://cdn-icons-png.flaticon.com/512/3143/3143643.png';
        _pizzaBadgeIconCtrl.text =
            data['pizzaBadgeIcon'] ??
            'https://cdn-icons-png.flaticon.com/512/3595/3595455.png';
        _fruitBadgeLabelCtrl.text = data['fruitBadgeLabel'] ?? 'Fruit';
        _pizzaBadgeLabelCtrl.text = data['pizzaBadgeLabel'] ?? 'Pizza';

        _winRatio = (data['winRatio'] as num?)?.toDouble() ?? 65.0;
        _betTimeCtrl.text = (data['betTime'] ?? 30).toString();
        _spinTimeCtrl.text = (data['spinTime'] ?? 6).toString();
        _resultTimeCtrl.text = (data['resultTime'] ?? 5).toString();
        _jackpotBaseCtrl.text = (data['jackpotBase'] ?? 1258400).toString();
        _forceWinnerIndex = data['forceWinnerIndex'] ?? -1;

        // Load 8 Items
        final List<dynamic>? items = data['items'];
        if (items != null && items.length == 8) {
          for (int i = 0; i < 8; i++) {
            _itemNames[i].text = items[i]['name'] ?? '';
            _itemIcons[i].text = items[i]['icon'] ?? '';
            _itemMultipliers[i].text = (items[i]['multiplier'] ?? 5).toString();
          }
        } else {
          _populateDefaultItems();
        }

        // Load 5 Chips
        final List<dynamic>? chips = data['chips'];
        if (chips != null && chips.length >= 5) {
          for (int i = 0; i < 5; i++) {
            _chipLabels[i].text = chips[i]['label'] ?? '';
            _chipValues[i].text = (chips[i]['value'] ?? 100).toString();
            _chipIcons[i].text = chips[i]['icon'] ?? '';
            _chipColors[i].text = chips[i]['color'] ?? '#2ce8f5';
          }
        } else {
          _populateDefaultChips();
        }

        // Load Visual UI Layout
        final Map<String, dynamic>? uiLayout = data['uiLayout'];
        if (uiLayout != null) {
          _wheelScale = (uiLayout['wheelScale'] as num?)?.toDouble() ?? 1.0;
          if (uiLayout['spokes'] is Map) {
            _spokesLayout = {
              'strokeWidth':
                  (uiLayout['spokes']['strokeWidth'] as num?)?.toDouble() ??
                  4.5,
              'color': uiLayout['spokes']['color'] ?? '#8A4128',
              'opacity':
                  (uiLayout['spokes']['opacity'] as num?)?.toDouble() ?? 0.9,
            };
          }
          if (uiLayout['slotOffsets'] is List &&
              (uiLayout['slotOffsets'] as List).length == 8) {
            final list = uiLayout['slotOffsets'] as List;
            for (int i = 0; i < 8; i++) {
              _slotLayouts[i] = {
                'top':
                    (list[i]['top'] as num?)?.toDouble() ??
                    _slotLayouts[i]['top']!,
                'left':
                    (list[i]['left'] as num?)?.toDouble() ??
                    _slotLayouts[i]['left']!,
                'width': (list[i]['width'] as num?)?.toDouble() ?? 70.0,
                'height': (list[i]['height'] as num?)?.toDouble() ?? 76.0,
                'scale': (list[i]['scale'] as num?)?.toDouble() ?? 1.0,
              };
            }
          }
          if (uiLayout['hub'] is Map) {
            _hubLayout = {
              'top': (uiLayout['hub']['top'] as num?)?.toDouble() ?? 106.0,
              'left': (uiLayout['hub']['left'] as num?)?.toDouble() ?? 106.0,
              'size': (uiLayout['hub']['size'] as num?)?.toDouble() ?? 108.0,
              'scale': (uiLayout['hub']['scale'] as num?)?.toDouble() ?? 1.0,
            };
          }
          if (uiLayout['fruitBadge'] is Map) {
            _fruitBadgeLayout = {
              'top':
                  (uiLayout['fruitBadge']['top'] as num?)?.toDouble() ?? 246.0,
              'left':
                  (uiLayout['fruitBadge']['left'] as num?)?.toDouble() ?? 8.0,
              'width':
                  (uiLayout['fruitBadge']['width'] as num?)?.toDouble() ?? 48.0,
              'height':
                  (uiLayout['fruitBadge']['height'] as num?)?.toDouble() ??
                  34.0,
              'scale':
                  (uiLayout['fruitBadge']['scale'] as num?)?.toDouble() ?? 1.0,
            };
          }
          if (uiLayout['pizzaBadge'] is Map) {
            _pizzaBadgeLayout = {
              'top':
                  (uiLayout['pizzaBadge']['top'] as num?)?.toDouble() ?? 246.0,
              'left':
                  (uiLayout['pizzaBadge']['left'] as num?)?.toDouble() ?? 268.0,
              'width':
                  (uiLayout['pizzaBadge']['width'] as num?)?.toDouble() ?? 48.0,
              'height':
                  (uiLayout['pizzaBadge']['height'] as num?)?.toDouble() ??
                  34.0,
              'scale':
                  (uiLayout['pizzaBadge']['scale'] as num?)?.toDouble() ?? 1.0,
            };
          }
          if (uiLayout['topHeader'] is Map) {
            _topHeaderLayout = {
              'top': (uiLayout['topHeader']['top'] as num?)?.toDouble() ?? 0.0,
            };
          }
          if (uiLayout['trophy'] is Map) {
            _trophyLayout = {
              'top': (uiLayout['trophy']['top'] as num?)?.toDouble() ?? 46.0,
              'left': (uiLayout['trophy']['left'] as num?)?.toDouble() ?? 10.0,
            };
          }
          if (uiLayout['rightActions'] is Map) {
            _rightActionsLayout = {
              'top':
                  (uiLayout['rightActions']['top'] as num?)?.toDouble() ?? 0.0,
              'right':
                  (uiLayout['rightActions']['right'] as num?)?.toDouble() ??
                  0.0,
            };
          }
          if (uiLayout['arena'] is Map) {
            _arenaLayout = {
              'marginTop':
                  (uiLayout['arena']['marginTop'] as num?)?.toDouble() ?? 14.0,
              'marginBottom':
                  (uiLayout['arena']['marginBottom'] as num?)?.toDouble() ??
                  8.0,
            };
          }
          if (uiLayout['skyline'] is Map) {
            _skylineLayout = {
              'top': (uiLayout['skyline']['top'] as num?)?.toDouble() ?? 360.0,
              'height':
                  (uiLayout['skyline']['height'] as num?)?.toDouble() ?? 110.0,
            };
          }
          if (uiLayout['todaysWin'] is Map) {
            _todaysWinLayout = {
              'marginTop':
                  (uiLayout['todaysWin']['marginTop'] as num?)?.toDouble() ??
                  0.0,
            };
          }
          if (uiLayout['wagerPrompt'] is Map) {
            _wagerPromptLayout = {
              'marginTop':
                  (uiLayout['wagerPrompt']['marginTop'] as num?)?.toDouble() ??
                  0.0,
            };
          }
          if (uiLayout['chipTray'] is Map) {
            _chipTrayLayout = {
              'marginTop':
                  (uiLayout['chipTray']['marginTop'] as num?)?.toDouble() ??
                  0.0,
            };
          }
          if (uiLayout['milestones'] is Map) {
            _milestonesLayout = {
              'marginTop':
                  (uiLayout['milestones']['marginTop'] as num?)?.toDouble() ??
                  0.0,
            };
          }
          if (uiLayout['historyRow'] is Map) {
            _historyRowLayout = {
              'marginTop':
                  (uiLayout['historyRow']['marginTop'] as num?)?.toDouble() ??
                  0.0,
            };
          }
        }
      } else {
        _populateDefaultUI();
        _populateDefaultItems();
        _populateDefaultChips();
      }
    } catch (e) {
      debugPrint('Error loading HTML5 game config: $e');
      _populateDefaultUI();
      _populateDefaultItems();
      _populateDefaultChips();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateDefaultUI() {
    _logoUrlCtrl.text =
        'https://cdn-icons-png.flaticon.com/512/3081/3081840.png';
    _diamondIconCtrl.text =
        'https://cdn-icons-png.flaticon.com/512/9496/9496739.png';
    _jackpotIconCtrl.text =
        'https://cdn-icons-png.flaticon.com/512/2645/2645897.png';
    _trophyIconCtrl.text =
        'https://cdn-icons-png.flaticon.com/512/3112/3112946.png';
    _winBannerCtrl.text =
        'https://cdn-icons-png.flaticon.com/512/10303/10303668.png';
  }

  void _populateDefaultItems() {
    final isDelicious = _selectedGameKey == 'greedy_delicious';
    final defaultList = isDelicious
        ? [
            {
              'name': 'Hot Dog',
              'icon': 'https://cdn-icons-png.flaticon.com/512/3075/3075977.png',
              'multiplier': 10,
            },
            {
              'name': 'BBQ Skewer',
              'icon': 'https://cdn-icons-png.flaticon.com/512/3595/3595455.png',
              'multiplier': 15,
            },
            {
              'name': 'Ham Leg',
              'icon': 'https://cdn-icons-png.flaticon.com/512/3143/3143643.png',
              'multiplier': 25,
            },
            {
              'name': 'Steak',
              'icon': 'https://cdn-icons-png.flaticon.com/512/3075/3075977.png',
              'multiplier': 45,
            },
            {
              'name': 'Carrot',
              'icon': 'https://cdn-icons-png.flaticon.com/512/415/415733.png',
              'multiplier': 5,
            },
            {
              'name': 'Corn',
              'icon': 'https://cdn-icons-png.flaticon.com/512/1791/1791336.png',
              'multiplier': 5,
            },
            {
              'name': 'Cabbage',
              'icon': 'https://cdn-icons-png.flaticon.com/512/590/590685.png',
              'multiplier': 5,
            },
            {
              'name': 'Tomato',
              'icon': 'https://cdn-icons-png.flaticon.com/512/2909/2909890.png',
              'multiplier': 5,
            },
          ]
        : [
            {
              'name': 'Apple',
              'icon': 'https://cdn-icons-png.flaticon.com/512/415/415733.png',
              'multiplier': 5,
            },
            {
              'name': 'Lemon',
              'icon': 'https://cdn-icons-png.flaticon.com/512/1791/1791336.png',
              'multiplier': 5,
            },
            {
              'name': 'Strawberry',
              'icon': 'https://cdn-icons-png.flaticon.com/512/590/590685.png',
              'multiplier': 5,
            },
            {
              'name': 'Mango',
              'icon': 'https://cdn-icons-png.flaticon.com/512/2909/2909890.png',
              'multiplier': 5,
            },
            {
              'name': 'Roast Fish',
              'icon': 'https://cdn-icons-png.flaticon.com/512/2253/2253308.png',
              'multiplier': 10,
            },
            {
              'name': 'Burger',
              'icon': 'https://cdn-icons-png.flaticon.com/512/3075/3075977.png',
              'multiplier': 15,
            },
            {
              'name': 'Pizza Slice',
              'icon': 'https://cdn-icons-png.flaticon.com/512/1404/1404945.png',
              'multiplier': 25,
            },
            {
              'name': 'Roast Chicken',
              'icon': 'https://cdn-icons-png.flaticon.com/512/1046/1046751.png',
              'multiplier': 45,
            },
          ];

    for (int i = 0; i < 8; i++) {
      _itemNames[i].text = defaultList[i]['name'] as String;
      _itemIcons[i].text = defaultList[i]['icon'] as String;
      _itemMultipliers[i].text = defaultList[i]['multiplier'].toString();
    }

    if (isDelicious) {
      _fruitBadgeLabelCtrl.text = 'Salad';
      _pizzaBadgeLabelCtrl.text = 'Pizza';
    } else {
      _fruitBadgeLabelCtrl.text = 'Fruit';
      _pizzaBadgeLabelCtrl.text = 'Pizza';
    }
  }

  void _populateDefaultChips() {
    final defaultChips = [
      {'label': '100', 'value': '100', 'color': '#2ce8f5'},
      {'label': '1K', 'value': '1000', 'color': '#33ff77'},
      {'label': '10K', 'value': '10000', 'color': '#0099ff'},
      {'label': '50K', 'value': '50000', 'color': '#ff9900'},
      {'label': '100K', 'value': '100000', 'color': '#ff3355'},
    ];

    for (int i = 0; i < 5; i++) {
      _chipLabels[i].text = defaultChips[i]['label']!;
      _chipValues[i].text = defaultChips[i]['value']!;
      _chipColors[i].text = defaultChips[i]['color']!;
      _chipIcons[i].text = '';
    }
  }

  Future<void> _pickAndUploadImage(
    TextEditingController targetController,
    String keyId,
    String folder,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() => _uploadingStates[keyId] = true);

        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
        final ref = _storage.ref().child('html5_games/$folder/$fileName');

        final uploadTask = ref.putData(
          result.files.single.bytes!,
          SettableMetadata(contentType: 'image/png'),
        );

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          targetController.text = downloadUrl;
          _uploadingStates[keyId] = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image uploaded successfully! ($keyId)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _uploadingStates[keyId] = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _publishToGame() async {
    setState(() => _isSaving = true);
    try {
      // Build 8 items list
      final List<Map<String, dynamic>> itemsList = [];
      for (int i = 0; i < 8; i++) {
        itemsList.add({
          'id': i,
          'name': _itemNames[i].text.trim(),
          'icon': _itemIcons[i].text.trim(),
          'multiplier': int.tryParse(_itemMultipliers[i].text.trim()) ?? 5,
          'optionId': 20 + i,
        });
      }

      // Build 5 chips list
      final List<Map<String, dynamic>> chipsList = [];
      for (int i = 0; i < 5; i++) {
        chipsList.add({
          'label': _chipLabels[i].text.trim(),
          'value': int.tryParse(_chipValues[i].text.trim()) ?? 100,
          'icon': _chipIcons[i].text.trim(),
          'color': _chipColors[i].text.trim().isEmpty
              ? '#2ce8f5'
              : _chipColors[i].text.trim(),
        });
      }

      // Build complete payload including dynamic UI layout coordinates
      final payload = {
        'isActive': _isActive,
        'logoUrl': _logoUrlCtrl.text.trim(),
        'gameBackgroundUrl': _gameBackgroundUrlCtrl.text.trim(),
        'basicBg': _gameBackgroundUrlCtrl.text.trim().isNotEmpty
            ? _gameBackgroundUrlCtrl.text.trim()
            : _basicBgCtrl.text.trim(),
        'advanceBg': _advanceBgCtrl.text.trim(),
        'diamondIcon': _diamondIconCtrl.text.trim(),
        'jackpotIcon': _jackpotIconCtrl.text.trim(),
        'trophyIcon': _trophyIconCtrl.text.trim(),
        'winBannerUrl': _winBannerCtrl.text.trim(),
        'fruitBadgeIcon': _fruitBadgeIconCtrl.text.trim(),
        'pizzaBadgeIcon': _pizzaBadgeIconCtrl.text.trim(),
        'fruitBadgeLabel': _fruitBadgeLabelCtrl.text.trim(),
        'pizzaBadgeLabel': _pizzaBadgeLabelCtrl.text.trim(),
        'items': itemsList,
        'chips': chipsList,
        'winRatio': _winRatio.round(),
        'betTime': int.tryParse(_betTimeCtrl.text.trim()) ?? 30,
        'spinTime': int.tryParse(_spinTimeCtrl.text.trim()) ?? 6,
        'resultTime': int.tryParse(_resultTimeCtrl.text.trim()) ?? 5,
        'jackpotBase': int.tryParse(_jackpotBaseCtrl.text.trim()) ?? 1258400,
        'forceWinnerIndex': _forceWinnerIndex,
        'uiLayout': {
          'wheelScale': _wheelScale,
          'spokes': _spokesLayout,
          'slotOffsets': _slotLayouts,
          'hub': _hubLayout,
          'fruitBadge': _fruitBadgeLayout,
          'pizzaBadge': _pizzaBadgeLayout,
          'topHeader': _topHeaderLayout,
          'trophy': _trophyLayout,
          'rightActions': _rightActionsLayout,
          'arena': _arenaLayout,
          'skyline': _skylineLayout,
          'todaysWin': _todaysWinLayout,
          'wagerPrompt': _wagerPromptLayout,
          'chipTray': _chipTrayLayout,
          'milestones': _milestonesLayout,
          'historyRow': _historyRowLayout,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('config')
          .doc(_currentConfigDoc)
          .set(payload, SetOptions(merge: true));

      if (_selectedGameKey == 'greedy_market') {
        await _firestore
            .collection('config')
            .doc('html5_greedy_market')
            .set(payload, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  '$_currentGameName এর সব ছবি, ব্যাকগ্রাউন্ড, পজিশন ও সেটিংস সফলভাবে পাবলিশ হয়েছে!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing config: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openGamePreview() {
    _showGameUrlDialog();
  }

  Future<void> _syncToGameWall() async {
    try {
      final logoUrl = _logoUrlCtrl.text.trim().isNotEmpty
          ? _logoUrlCtrl.text.trim()
          : 'https://cdn-icons-png.flaticon.com/512/3081/3081840.png';

      final gameData = {
        'id': _currentGameId,
        'gameCode': _currentGameId,
        'gameId': _currentGameId,
        'name': _currentGameName,
        'title': _currentGameName,
        'thumbnailUrl': logoUrl,
        'icon': logoUrl,
        'image': logoUrl,
        'gameUrl': _currentGameUrl,
        'url': _currentGameUrl,
        'link': _currentGameUrl,
        'webViewUrl': _currentGameUrl,
        'type': 'html5',
        'isHtml5': true,
        'isWebView': true,
        'winRatio': _winRatio,
        'isActive': true,
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('games')
          .doc(_currentGameId)
          .set(gameData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ গেমটি সফলভাবে গেম ওয়ালে (Game Wall) সিঙ্ক ও অ্যাড করা হয়েছে!',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing to game wall: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showGameUrlDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.sports_esports, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'HTML 5 Game ID & Launch URLs',
              style: TextStyle(color: Colors.amber, fontSize: 16),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Game ID
              const Text(
                '🎮 Official Game ID / Code:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _currentGameId,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        color: Colors.amber,
                        size: 18,
                      ),
                      tooltip: 'Copy Game ID',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _currentGameId),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Copied Game ID: $_currentGameId',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Direct Web Launch URL
              const Text(
                '🔗 Direct Game URL:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyan.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _currentGameUrl,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        color: Colors.cyan,
                        size: 18,
                      ),
                      tooltip: 'Copy Game URL',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: _currentGameUrl,
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied Game URL!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2.5. Open in perfect mobile popup window
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    openWebPopup(_currentGameUrl, width: 440, height: 740);
                  },
                  icon: const Icon(Icons.open_in_new, color: Colors.black),
                  label: const Text(
                    '📱 ওপেন করুন লাইভ মোবাইল পপ-আপ (নিখুঁত সাইজ)',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 3. 1-Click Game Wall Sync Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _syncToGameWall();
                  },
                  icon: const Icon(Icons.flash_on, color: Colors.black),
                  label: const Text(
                    '🚀 ১-ক্লিকে গেম ওয়ালে অ্যাড/সিঙ্ক করুন',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _autoAlignCircle() {
    setState(() {
      const double centerX = 125.0;
      const double centerY = 122.0;
      final double r = _wheelCircleRadius;

      for (int i = 0; i < 8; i++) {
        final double angle = -math.pi / 2 + (i * 2 * math.pi / 8);
        final double posX = centerX + r * math.cos(angle);
        final double posY = centerY + r * math.sin(angle);

        _slotLayouts[i]['left'] = posX.clamp(-40.0, 280.0);
        _slotLayouts[i]['top'] = posY.clamp(-40.0, 280.0);
        _slotLayouts[i]['width'] = _globalCardWidth;
        _slotLayouts[i]['height'] = _globalCardHeight;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '🎯 ৮টি আইটেম কার্ড সফলভাবে সমান্তরাল বৃত্তে সাজানো হয়েছে!',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _nudgeSelected({double dx = 0, double dy = 0}) {
    setState(() {
      if (_selectedElementIndex >= 0 && _selectedElementIndex < 8) {
        _slotLayouts[_selectedElementIndex]['left'] =
            (_slotLayouts[_selectedElementIndex]['left']! + dx).clamp(
              -50.0,
              320.0,
            );
        _slotLayouts[_selectedElementIndex]['top'] =
            (_slotLayouts[_selectedElementIndex]['top']! + dy).clamp(
              -50.0,
              320.0,
            );
      } else if (_selectedElementIndex == 8) {
        _hubLayout['left'] = (_hubLayout['left']! + dx).clamp(-50.0, 300.0);
        _hubLayout['top'] = (_hubLayout['top']! + dy).clamp(-50.0, 300.0);
      } else if (_selectedElementIndex == 9) {
        _fruitBadgeLayout['left'] = (_fruitBadgeLayout['left']! + dx).clamp(
          -50.0,
          300.0,
        );
        _fruitBadgeLayout['top'] = (_fruitBadgeLayout['top']! + dy).clamp(
          -50.0,
          320.0,
        );
      } else if (_selectedElementIndex == 10) {
        _pizzaBadgeLayout['left'] = (_pizzaBadgeLayout['left']! + dx).clamp(
          -50.0,
          300.0,
        );
        _pizzaBadgeLayout['top'] = (_pizzaBadgeLayout['top']! + dy).clamp(
          -50.0,
          320.0,
        );
      } else if (_selectedElementIndex == 11) {
        _topHeaderLayout['top'] = (_topHeaderLayout['top']! + dy).clamp(
          -100.0,
          300.0,
        );
      } else if (_selectedElementIndex == 12) {
        _trophyLayout['left'] = (_trophyLayout['left']! + dx).clamp(
          -50.0,
          300.0,
        );
        _trophyLayout['top'] = (_trophyLayout['top']! + dy).clamp(-50.0, 300.0);
      } else if (_selectedElementIndex == 13) {
        _rightActionsLayout['right'] = (_rightActionsLayout['right']! - dx)
            .clamp(-50.0, 300.0);
        _rightActionsLayout['top'] = (_rightActionsLayout['top']! + dy).clamp(
          -50.0,
          300.0,
        );
      } else if (_selectedElementIndex == 14) {
        _arenaLayout['marginTop'] = (_arenaLayout['marginTop']! + dy).clamp(
          -100.0,
          300.0,
        );
      } else if (_selectedElementIndex == 15) {
        _skylineLayout['top'] = (_skylineLayout['top']! + dy).clamp(0.0, 600.0);
      } else if (_selectedElementIndex == 16) {
        _todaysWinLayout['marginTop'] = (_todaysWinLayout['marginTop']! + dy)
            .clamp(-100.0, 300.0);
      } else if (_selectedElementIndex == 17) {
        _wagerPromptLayout['marginTop'] =
            (_wagerPromptLayout['marginTop']! + dy).clamp(-100.0, 300.0);
      } else if (_selectedElementIndex == 18) {
        _chipTrayLayout['marginTop'] = (_chipTrayLayout['marginTop']! + dy)
            .clamp(-100.0, 300.0);
      } else if (_selectedElementIndex == 19) {
        _milestonesLayout['marginTop'] = (_milestonesLayout['marginTop']! + dy)
            .clamp(-100.0, 300.0);
      } else if (_selectedElementIndex == 20) {
        _historyRowLayout['marginTop'] = (_historyRowLayout['marginTop']! + dy)
            .clamp(-100.0, 300.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedGameKey == 'ludo_game') {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 4,
          title: const Row(
            children: [
              Icon(Icons.casino, color: Colors.amber, size: 28),
              SizedBox(width: 12),
              Text(
                'HTML 5 Game Management - Ludo Champion (লুডু গেম)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: _buildGameSelectorBar(),
          ),
        ),
        body: LudoGameManagementView(
          onBackToCatalog: () =>
              setState(() => _selectedGameKey = 'greedy_market'),
        ),
      );
    }

    if (_selectedGameKey == 'gem_spin_slot') {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 4,
          title: const Row(
            children: [
              Icon(Icons.diamond, color: Colors.cyanAccent, size: 28),
              SizedBox(width: 12),
              Text(
                'HTML 5 Game Management - Gem Spin Slot (Arabian Nights)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: _buildGameSelectorBar(),
          ),
        ),
        body: GemSpinSlotManagementView(
          onBackToCatalog: () =>
              setState(() => _selectedGameKey = 'greedy_market'),
        ),
      );
    }

    if (_selectedGameKey == 'king_queen_slot') {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 4,
          title: const Row(
            children: [
              Icon(Icons.casino, color: Colors.amber, size: 28),
              SizedBox(width: 12),
              Text(
                'HTML 5 Game Management - King Queen Slot Game',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: _buildGameSelectorBar(),
          ),
        ),
        body: KingQueenSlotManagementView(
          onBackToCatalog: () =>
              setState(() => _selectedGameKey = 'greedy_market'),
        ),
      );
    }

    if (_selectedGameKey == 'greedy_delicious') {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 4,
          title: const Row(
            children: [
              Icon(Icons.restaurant, color: Colors.orangeAccent, size: 28),
              SizedBox(width: 12),
              Text(
                'HTML 5 Game Management - Greedy Delicious',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: _buildGameSelectorBar(),
          ),
        ),
        body: GreedyDeliciousManagementView(
          onBackToCatalog: () =>
              setState(() => _selectedGameKey = 'greedy_market'),
        ),
      );
    }

    if (_selectedGameKey == 'greedy_cat') {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 4,
          title: const Row(
            children: [
              Icon(Icons.pets, color: Colors.pinkAccent, size: 28),
              SizedBox(width: 12),
              Text(
                'HTML 5 Game Management - Greedy Cat',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: _buildGameSelectorBar(),
          ),
        ),
        body: GreedyCatManagementView(
          onBackToCatalog: () =>
              setState(() => _selectedGameKey = 'greedy_market'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 4,
        title: Row(
          children: [
            Icon(
              _selectedGameKey == 'greedy_delicious'
                  ? Icons.restaurant
                  : Icons.sports_esports,
              color: _selectedGameKey == 'greedy_delicious'
                  ? Colors.orangeAccent
                  : Colors.amber,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'HTML 5 $_currentGameName - Full Admin Management',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _isActive
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isActive ? Colors.green : Colors.red,
                ),
              ),
              child: Text(
                _isActive ? 'LIVE ACTIVE' : 'MAINTENANCE',
                style: TextStyle(
                  color: _isActive ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: _openGamePreview,
            icon: const Icon(Icons.link, color: Colors.cyanAccent, size: 18),
            label: const Text(
              'Game Link & ID',
              style: TextStyle(color: Colors.cyanAccent),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.cyanAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _publishToGame,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.cloud_upload, color: Colors.black, size: 20),
            label: Text(
              _isSaving ? 'Publishing...' : 'Save & Publish (লাইভ আপডেট)',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              _buildGameSelectorBar(),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.amber,
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.pan_tool_alt),
                    text: '🎨 Game UI Setup (ড্র্যাগ ও মুভিং এডিটর)',
                  ),
                  Tab(
                    icon: Icon(Icons.image),
                    text: 'UI & Theme (ব্যাকগ্রাউন্ড ও ছবি)',
                  ),
                  Tab(icon: Icon(Icons.fastfood), text: '8 Items (৮টি আইটেম পিকচার)'),
                  Tab(
                    icon: Icon(Icons.monetization_on),
                    text: '5 Chips (চিপস ও কয়েন)',
                  ),
                  Tab(icon: Icon(Icons.emoji_events), text: 'Winning (উইনার মোডাল)'),
                  Tab(icon: Icon(Icons.settings), text: 'Game Rules & Control'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVisualUISetupTab(),
                _buildUIThemeTab(),
                _buildItemsTab(),
                _buildChipsTab(),
                _buildWinningTab(),
                _buildRulesControlTab(),
              ],
            ),
    );
  }

  // Serial Game Selector Bar
  Widget _buildGameSelectorBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFF0F172A),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              '🎮 Games:',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 12),
            _buildGameSelectCard(
              id: 'greedy_market',
              title: '🎡 Greedy Market',
              subtitle: 'Ferris Wheel Spin • greedy-market-game.web.app',
              isSelected: _selectedGameKey == 'greedy_market',
              onTap: () {
                if (_selectedGameKey != 'greedy_market') {
                  setState(() => _selectedGameKey = 'greedy_market');
                  _loadGameConfig();
                }
              },
            ),
            const SizedBox(width: 10),
            _buildGameSelectCard(
              id: 'ludo_game',
              title: '🎲 Ludo Champion (HTML5)',
              subtitle: 'Multiplayer Ludo • public_games/ludugame-1',
              isSelected: _selectedGameKey == 'ludo_game',
              onTap: () => setState(() => _selectedGameKey = 'ludo_game'),
            ),
            const SizedBox(width: 10),
            _buildGameSelectCard(
              id: 'gem_spin_slot',
              title: '💎 Arabian Spin Game',
              subtitle: '5-Reel Arabian • 75% RTP • arabian-spin-game.web.app',
              isSelected: _selectedGameKey == 'gem_spin_slot',
              onTap: () => setState(() => _selectedGameKey = 'gem_spin_slot'),
            ),
            _buildGameSelectCard(
              id: 'king_queen_slot',
              title: '👑 King Queen Slot Game',
              subtitle: '5-Reel Royal Slot • king-queen-slot-game.web.app',
              isSelected: _selectedGameKey == 'king_queen_slot',
              onTap: () => setState(() => _selectedGameKey = 'king_queen_slot'),
            ),
            const SizedBox(width: 10),
            _buildGameSelectCard(
              id: 'greedy_delicious',
              title: '🍖 Greedy Delicious',
              subtitle: 'Food Ferris Wheel • greedy-delicious-game.web.app',
              isSelected: _selectedGameKey == 'greedy_delicious',
              onTap: () => setState(() => _selectedGameKey = 'greedy_delicious'),
            ),
            const SizedBox(width: 10),
            _buildGameSelectCard(
              id: 'greedy_cat',
              title: '🐱 Greedy Cat',
              subtitle: 'Cat Ferris Wheel • greedy-cat-game.web.app',
              isSelected: _selectedGameKey == 'greedy_cat',
              onTap: () => setState(() => _selectedGameKey = 'greedy_cat'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _showAddNewGameDialog,
              icon: const Icon(Icons.add_circle, color: Colors.amber, size: 16),
              label: const Text(
                '+ Add New Game',
                style: TextStyle(color: Colors.amber, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.amber),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSelectCard({
    required String id,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.withValues(alpha: 0.15)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.amber : const Color(0xFF334155),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? Colors.amber : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.amberAccent.withValues(alpha: 0.8)
                        : Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: Colors.amber, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddNewGameDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final iconCtrl = TextEditingController(
      text: 'https://cdn-icons-png.flaticon.com/512/3081/3081840.png',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: Colors.amber),
            SizedBox(width: 10),
            Text(
              'Add New HTML5 Game',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Game Name (e.g. Crazy Roulette)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Game Code (e.g. html5_crazy_roulette)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Web / Hosting URL',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Thumbnail / Icon URL',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final code = codeCtrl.text.trim();
              final url = urlCtrl.text.trim();
              final icon = iconCtrl.text.trim();
              if (name.isEmpty || url.isEmpty) return;

              final gId = code.isNotEmpty
                  ? code
                  : name.toLowerCase().replaceAll(' ', '_');
              await _firestore.collection('games').doc(gId).set({
                'id': gId,
                'gameCode': gId,
                'name': name,
                'title': name,
                'gameUrl': url,
                'url': url,
                'thumbnailUrl': icon,
                'icon': icon,
                'picture': icon,
                'gameType': 'html5',
                'type': 'html5',
                'isHtml5': true,
                'isWebView': true,
                'isEnabled': true,
                'isActive': true,
                'status': 'active',
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Game "$name" added to games collection!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text(
              'Add Game',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // --- 0. VISUAL DRAG & DROP GAME UI SETUP TAB (সম্পূর্ণ ড্র্যাগ ও মুভিং এডিটর) ---
  // =========================================================================
  Widget _buildVisualUISetupTab() {
    String selectedName = 'Unknown';
    double currentX = 0;
    double currentY = 0;
    double currentW = 70;

    if (_selectedElementIndex >= 0 && _selectedElementIndex < 8) {
      selectedName =
          'Slot #${_selectedElementIndex + 1}: ${_itemNames[_selectedElementIndex].text} (${_itemMultipliers[_selectedElementIndex].text}x)';
      currentX = _slotLayouts[_selectedElementIndex]['left'] ?? 0;
      currentY = _slotLayouts[_selectedElementIndex]['top'] ?? 0;
      currentW = _slotLayouts[_selectedElementIndex]['width'] ?? 70;
    } else if (_selectedElementIndex == 8) {
      selectedName = '🐻 Center Bear Hub Mascot & Timer (সেন্টার হাব)';
      currentX = _hubLayout['left'] ?? 106;
      currentY = _hubLayout['top'] ?? 106;
      currentW = _hubLayout['size'] ?? 108;
    } else if (_selectedElementIndex == 9) {
      selectedName = '🥗 Fruit Category Badge (Left Side)';
      currentX = _fruitBadgeLayout['left'] ?? 8;
      currentY = _fruitBadgeLayout['top'] ?? 246;
      currentW = _fruitBadgeLayout['width'] ?? 48;
    } else if (_selectedElementIndex == 10) {
      selectedName = '🍕 Pizza Category Badge (Right Side)';
      currentX = _pizzaBadgeLayout['left'] ?? 268;
      currentY = _pizzaBadgeLayout['top'] ?? 246;
      currentW = _pizzaBadgeLayout['width'] ?? 48;
    } else if (_selectedElementIndex == 11) {
      selectedName = '💎 Top Header & Diamond Balance Pill (টপ হেডার)';
      currentY = _topHeaderLayout['top'] ?? 0;
    } else if (_selectedElementIndex == 12) {
      selectedName = '🏆 Top 10 Trophy Icon (টপ ১০ ট্রফি)';
      currentX = _trophyLayout['left'] ?? 10;
      currentY = _trophyLayout['top'] ?? 46;
    } else if (_selectedElementIndex == 13) {
      selectedName = '📜 Top Right Actions (হিস্ট্রি, সাউন্ড, রুলস, ক্লোজ)';
      currentX = _rightActionsLayout['right'] ?? 0;
      currentY = _rightActionsLayout['top'] ?? 0;
    } else if (_selectedElementIndex == 14) {
      selectedName = '🎡 Ferris Wheel Arena (চাকা এরিনা মার্জিন)';
      currentY = _arenaLayout['marginTop'] ?? 14;
    } else if (_selectedElementIndex == 15) {
      selectedName = '🏙️ City Skyline Background Graphic (সিটি ব্যাকগ্রাউন্ড)';
      currentY = _skylineLayout['top'] ?? 360;
    } else if (_selectedElementIndex == 16) {
      selectedName = "⭐ Today's Win Bar (টুডেস উইন বার)";
      currentY = _todaysWinLayout['marginTop'] ?? 0;
    } else if (_selectedElementIndex == 17) {
      selectedName = '💬 Wager Instruction Pill (বেটিং নির্দেশিকা বার)';
      currentY = _wagerPromptLayout['marginTop'] ?? 0;
    } else if (_selectedElementIndex == 18) {
      selectedName = '🎰 Chip Tray Panel (৫টি চিপস প্যানেল)';
      currentY = _chipTrayLayout['marginTop'] ?? 0;
    } else if (_selectedElementIndex == 19) {
      selectedName = '🎁 Milestones Chests Bar (মাইলস্টোন চেস্ট বার)';
      currentY = _milestonesLayout['marginTop'] ?? 0;
    } else if (_selectedElementIndex == 20) {
      selectedName = '📜 Past Round History Row (হিস্ট্রি ক্যাপসুল রো)';
      currentY = _historyRowLayout['marginTop'] ?? 0;
    } else if (_selectedElementIndex == 21) {
      selectedName = '🔍 Entire Wheel Zoom / Scale (হুইল জুম ইন / জুম আউট)';
      currentW = (_wheelScale * 100);
    } else if (_selectedElementIndex == 22) {
      selectedName = '🪵 Wheel Spokes / Sticks (কাঠির সাইজ - মোটা / চিকন)';
      currentW = (_spokesLayout['strokeWidth'] as num?)?.toDouble() ?? 4.5;
    }

    final bgImage = _gameBackgroundUrlCtrl.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Background Image Quick Bar
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.cyanAccent, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.wallpaper,
                    color: Colors.cyanAccent,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🖼️ Game Background Picture (গেম ব্যাকগ্রাউন্ড পিকচার পরিবর্তন):',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _gameBackgroundUrlCtrl,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Enter Background Image URL (https://...) or Upload',
                                  hintStyle: const TextStyle(
                                    color: Colors.white38,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () => _pickAndUploadImage(
                                _gameBackgroundUrlCtrl,
                                'gameBackgroundUrl',
                                'backgrounds',
                              ),
                              icon:
                                  _uploadingStates['gameBackgroundUrl'] == true
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.upload,
                                      color: Colors.black,
                                      size: 18,
                                    ),
                              label: const Text(
                                'Upload BG',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent,
                              ),
                            ),
                            if (bgImage.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.redAccent,
                                ),
                                tooltip: 'Clear Background',
                                onPressed: () => setState(
                                  () => _gameBackgroundUrlCtrl.clear(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Quick Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '🎨 Universal Visual Game UI & Position Editor',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'গেমের ভেতরের প্রতিটি আইটেম, Fruit/Pizza ব্যাজ, হেডার, চাকা ও বাটন টেনে টেনে মুভ করুন:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _autoAlignCircle,
                    icon: const Icon(Icons.circle_outlined, size: 18),
                    label: const Text('🎯 Auto-Circle Align (সমান্তরাল গোল)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _initDefaultLayouts());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('লেআউট ডিফল্টে রিসেট করা হয়েছে!'),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.refresh,
                      size: 18,
                      color: Colors.orangeAccent,
                    ),
                    label: const Text(
                      'Reset Layout',
                      style: TextStyle(color: Colors.orangeAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Layout Area: Canvas on Left + Live Controls on Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- INTERACTIVE PHONE CANVAS ---
              Container(
                width: 360,
                height: 600,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1738),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.amber, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Background Image or Starry Gradient BG
                      Positioned.fill(
                        child: bgImage.isNotEmpty
                            ? Image.network(
                                bgImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment(0, -0.3),
                                      radius: 1.0,
                                      colors: [
                                        Color(0xFF184594),
                                        Color(0xFF0D2766),
                                        Color(0xFF061338),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: const BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment(0, -0.3),
                                    radius: 1.0,
                                    colors: [
                                      Color(0xFF184594),
                                      Color(0xFF0D2766),
                                      Color(0xFF061338),
                                    ],
                                  ),
                                ),
                              ),
                      ),

                      // Skyline Graphic (Draggable)
                      Positioned(
                        top: (_skylineLayout['top'] ?? 360) * (600 / 780),
                        left: 0,
                        right: 0,
                        height: (_skylineLayout['height'] ?? 110) * (600 / 780),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedElementIndex = 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF061436).withOpacity(0.6),
                              border: Border.all(
                                color: _selectedElementIndex == 15
                                    ? Colors.cyanAccent
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '🏙️ Skyline Graphic',
                                style: TextStyle(
                                  color: Colors.white30,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Top Mini Header & Diamond Pill (Draggable)
                      Positioned(
                        top: 10 + (_topHeaderLayout['top'] ?? 0),
                        left: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedElementIndex = 11),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedElementIndex == 11
                                    ? Colors.amber
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.amber.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.diamond,
                                        color: Colors.cyanAccent,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '128,822',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _selectedElementIndex = 13,
                                  ),
                                  child: Row(
                                    children: [
                                      for (var icon in [
                                        Icons.history,
                                        Icons.volume_up,
                                        Icons.help_outline,
                                        Icons.close,
                                      ])
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: Colors.black38,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _selectedElementIndex == 13
                                                  ? Colors.amber
                                                  : Colors.transparent,
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            icon,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Floating Trophy Top 10 Icon (Draggable)
                      Positioned(
                        top: (_trophyLayout['top'] ?? 46) * (600 / 780),
                        left: (_trophyLayout['left'] ?? 10) * (360 / 430),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedElementIndex = 12),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedElementIndex == 12
                                    ? Colors.amber
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: const Text(
                              '🏆',
                              style: TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      ),

                      // --- WHEEL STAGE CANVAS (320 x 320 with Live Zoom & Spokes) ---
                      Positioned(
                        top: 50 + (_arenaLayout['marginTop'] ?? 14),
                        left: 20,
                        width: 320,
                        height: 320,
                        child: Transform.scale(
                          scale: _wheelScale,
                          alignment: Alignment.center,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Spokes Lines (Dynamic Stroke Width & Color)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _SpokesPainter(
                                    strokeWidth:
                                        (_spokesLayout['strokeWidth'] as num?)
                                            ?.toDouble() ??
                                        4.5,
                                    color: _spokesLayout['color'] ?? '#8A4128',
                                  ),
                                ),
                              ),

                              // Center Mascot Bear Hub (Draggable)
                              Positioned(
                                top: _hubLayout['top']!,
                                left: _hubLayout['left']!,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedElementIndex = 8),
                                  onPanUpdate: (details) {
                                    setState(() {
                                      _selectedElementIndex = 8;
                                      _hubLayout['left'] =
                                          (_hubLayout['left']! +
                                                  details.delta.dx)
                                              .clamp(0.0, 220.0);
                                      _hubLayout['top'] =
                                          (_hubLayout['top']! +
                                                  details.delta.dy)
                                              .clamp(0.0, 240.0);
                                    });
                                  },
                                  child: Transform.scale(
                                    scale: _hubLayout['scale'] ?? 1.0,
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: _hubLayout['size']!,
                                      height: _hubLayout['size']!,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6823),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _selectedElementIndex == 8
                                              ? Colors.white
                                              : const Color(0xFFFFBA42),
                                          width: _selectedElementIndex == 8
                                              ? 3.5
                                              : 2.5,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Text(
                                            '🐻',
                                            style: TextStyle(fontSize: 26),
                                          ),
                                          Text(
                                            'Bet Time',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '30s',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 8 Item Cards (Individually Draggable with Mouse)
                              for (int i = 0; i < 8; i++)
                                Positioned(
                                  top: _slotLayouts[i]['top']!,
                                  left: _slotLayouts[i]['left']!,
                                  child: Transform.scale(
                                    scale: _slotLayouts[i]['scale'] ?? 1.0,
                                    alignment: Alignment.center,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedElementIndex = i,
                                      ),
                                      onPanUpdate: (details) {
                                        setState(() {
                                          _selectedElementIndex = i;
                                          _slotLayouts[i]['left'] =
                                              (_slotLayouts[i]['left']! +
                                                      details.delta.dx)
                                                  .clamp(-40.0, 280.0);
                                          _slotLayouts[i]['top'] =
                                              (_slotLayouts[i]['top']! +
                                                      details.delta.dy)
                                                  .clamp(-40.0, 280.0);
                                        });
                                      },
                                      child: Container(
                                        width: _slotLayouts[i]['width']!,
                                        height: _slotLayouts[i]['height']!,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Color(0xFFFFF7C2),
                                              Color(0xFFFFDE59),
                                              Color(0xFFFCA800),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: _selectedElementIndex == i
                                                ? Colors.white
                                                : const Color(0xFFFF9D00),
                                            width: _selectedElementIndex == i
                                                ? 3
                                                : 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _selectedElementIndex == i
                                                  ? Colors.amberAccent.withValues(
                                                      alpha: 0.8,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.4,
                                                    ),
                                              blurRadius:
                                                  _selectedElementIndex == i
                                                  ? 12
                                                  : 6,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _itemIcons[i].text.isNotEmpty
                                                ? Image.network(
                                                    _itemIcons[i].text,
                                                    width:
                                                        (_slotLayouts[i]['width']! *
                                                                0.6)
                                                            .clamp(24.0, 60.0),
                                                    height:
                                                        (_slotLayouts[i]['height']! *
                                                                0.55)
                                                            .clamp(24.0, 60.0),
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, __, ___) =>
                                                        const Icon(
                                                          Icons.fastfood,
                                                          size: 24,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.fastfood,
                                                    size: 24,
                                                    color: Colors.white,
                                                  ),
                                            Text(
                                              '${_itemMultipliers[i].text}x',
                                              style: const TextStyle(
                                                color: Colors.brown,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Fruit side badge (Left - Draggable & Zoomable)
                              Positioned(
                                top: _fruitBadgeLayout['top']!,
                                left: _fruitBadgeLayout['left']!,
                                child: Transform.scale(
                                  scale: _fruitBadgeLayout['scale'] ?? 1.0,
                                  alignment: Alignment.center,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedElementIndex = 9),
                                    onPanUpdate: (details) {
                                      setState(() {
                                        _selectedElementIndex = 9;
                                        _fruitBadgeLayout['left'] =
                                            (_fruitBadgeLayout['left']! +
                                                    details.delta.dx)
                                                .clamp(-20.0, 280.0);
                                        _fruitBadgeLayout['top'] =
                                            (_fruitBadgeLayout['top']! +
                                                    details.delta.dy)
                                                .clamp(-20.0, 310.0);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF7EE6FF),
                                            Color(0xFF0096E6),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _selectedElementIndex == 9
                                              ? Colors.white
                                              : Colors.white70,
                                          width: _selectedElementIndex == 9
                                              ? 2.5
                                              : 1.5,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black45,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _fruitBadgeIconCtrl.text.isNotEmpty
                                              ? Image.network(
                                                  _fruitBadgeIconCtrl.text,
                                                  width: (_fruitBadgeLayout['width'] ?? 48.0) * 0.5,
                                                  height: (_fruitBadgeLayout['height'] ?? 34.0) * 0.6,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Text('🍎', style: TextStyle(fontSize: 12)),
                                                )
                                              : const Text('🍎', style: TextStyle(fontSize: 12)),
                                          const SizedBox(width: 4),
                                          Text(
                                            _fruitBadgeLabelCtrl.text.isNotEmpty
                                                ? _fruitBadgeLabelCtrl.text
                                                : 'Fruit',
                                            style: const TextStyle(
                                              color: Color(0xFF032B47),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Pizza side badge (Right - Draggable & Zoomable)
                              Positioned(
                                top: _pizzaBadgeLayout['top']!,
                                left: _pizzaBadgeLayout['left']!,
                                child: Transform.scale(
                                  scale: _pizzaBadgeLayout['scale'] ?? 1.0,
                                  alignment: Alignment.center,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedElementIndex = 10,
                                    ),
                                    onPanUpdate: (details) {
                                      setState(() {
                                        _selectedElementIndex = 10;
                                        _pizzaBadgeLayout['left'] =
                                            (_pizzaBadgeLayout['left']! +
                                                    details.delta.dx)
                                                .clamp(-20.0, 280.0);
                                        _pizzaBadgeLayout['top'] =
                                            (_pizzaBadgeLayout['top']! +
                                                    details.delta.dy)
                                                .clamp(-20.0, 310.0);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF7EE6FF),
                                            Color(0xFF0096E6),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _selectedElementIndex == 10
                                              ? Colors.white
                                              : Colors.white70,
                                          width: _selectedElementIndex == 10
                                              ? 2.5
                                              : 1.5,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black45,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _pizzaBadgeIconCtrl.text.isNotEmpty
                                              ? Image.network(
                                                  _pizzaBadgeIconCtrl.text,
                                                  width: (_pizzaBadgeLayout['width'] ?? 48.0) * 0.5,
                                                  height: (_pizzaBadgeLayout['height'] ?? 34.0) * 0.6,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Text('🍕', style: TextStyle(fontSize: 12)),
                                                )
                                              : const Text('🍕', style: TextStyle(fontSize: 12)),
                                          const SizedBox(width: 4),
                                          Text(
                                            _pizzaBadgeLabelCtrl.text.isNotEmpty
                                                ? _pizzaBadgeLabelCtrl.text
                                                : 'Pizza',
                                            style: const TextStyle(
                                              color: Color(0xFF032B47),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                       ),
                                     ),
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         ),
                       ),

                      // Bottom Panels Mockup (Clickable / Selectable)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Column(
                          children: [
                            // Today's Win Bar (Uses Transform.translate to avoid negative margin assertion)
                            Transform.translate(
                              offset: Offset(
                                0,
                                _todaysWinLayout['marginTop'] ?? 0,
                              ),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedElementIndex = 16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F265C),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _selectedElementIndex == 16
                                          ? Colors.white
                                          : Colors.amber.withValues(alpha: 0.5),
                                      width: _selectedElementIndex == 16
                                          ? 2
                                          : 1,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "TODAY'S WIN 0",
                                      style: TextStyle(
                                        color: Colors.amber,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),

                            // Wager Prompt Pill
                            Transform.translate(
                              offset: Offset(
                                0,
                                _wagerPromptLayout['marginTop'] ?? 0,
                              ),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedElementIndex = 17),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _selectedElementIndex == 17
                                          ? Colors.white
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: const Text(
                                    "Choose wager -> Choose max 6 items",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),

                            // Chip Tray
                            Transform.translate(
                              offset: Offset(
                                0,
                                _chipTrayLayout['marginTop'] ?? 0,
                              ),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedElementIndex = 18),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _selectedElementIndex == 18
                                          ? Colors.white
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      for (var label in [
                                        '100',
                                        '1K',
                                        '10K',
                                        '50K',
                                        '100K',
                                      ])
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              label,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 7,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // --- RIGHT CONTROLS PANEL (SLIDERS & STEPPERS) ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Selection Card
                    Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.amber, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Selected Element (সিলেক্টেড আইটেম):',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                DropdownButton<int>(
                                  value: _selectedElementIndex,
                                  dropdownColor: const Color(0xFF0F172A),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  items: [
                                    for (int i = 0; i < 8; i++)
                                      DropdownMenuItem(
                                        value: i,
                                        child: Text(
                                          'Slot #${i + 1}: ${_itemNames[i].text} (${_itemMultipliers[i].text}x)',
                                        ),
                                      ),
                                    const DropdownMenuItem(
                                      value: 8,
                                      child: Text(
                                        '🐻 Center Bear Hub Mascot & Timer',
                                      ),
                                    ),
                                    const DropdownMenuItem(
                                      value: 9,
                                      child: Text(
                                        '🥗 Fruit Category Badge (Left)',
                                      ),
                                    ),
                                    const DropdownMenuItem(
                                      value: 10,
                                      child: Text(
                                        '🍕 Pizza Category Badge (Right)',
                                      ),
                                    ),
                                    const DropdownMenuItem(
                                      value: 11,
                                      child: Text(
                                        '💎 Top Header & Diamond Balance Pill',
                                      ),
                                    ),
                                    const DropdownMenuItem(
                                      value: 12,
                                      child: Text('🏆 Top 10 Trophy Icon'),
                                    ),
                                    const DropdownMenuItem(
                                      value: 13,
                                      child: Text('📜 Top Right Action Icons'),
                                    ),
                                    const DropdownMenuItem(
                                      value: 14,
                                      child: Text(
                                        '🎡 Ferris Wheel Arena (মার্জিন)',
                                      ),
                                    ),
                                    const DropdownMenuItem(
                                      value: 15,
                                      child: Text('🏙️ City Skyline Graphic'),
                                    ),
                                    const DropdownMenuItem(
                                      value: 16,
                                      child: Text("⭐ Today's Win Bar"),
                                    ),
                                    const DropdownMenuItem(
                                      value: 17,
                                      child: Text('💬 Wager Instruction Pill'),
                                    ),
                                    const DropdownMenuItem(
                                      value: 18,
                                      child: Text('🎰 Chip Tray Panel'),
                                    ),
                                    const DropdownMenuItem(
                                      value: 19,
                                      child: Text('🎁 Milestones Chests Bar'),
                                    ),
                                    const DropdownMenuItem(
                                      value: 20,
                                      child: Text('📜 Past Round History Row'),
                                    ),
                                    const DropdownMenuItem(
                                      value: 21,
                                      child: Text(
                                        '🔍 Entire Wheel Zoom / Scale (হুইল জুম ইন/আউট)',
                                      ),
                                    ),
                                    const DropdownMenuItem(
                                      value: 22,
                                      child: Text(
                                        '🪵 Wheel Spokes / Sticks (কাঠি মোটা-চিকন)',
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null)
                                      setState(
                                        () => _selectedElementIndex = val,
                                      );
                                  },
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24, height: 20),
                            Text(
                              selectedName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ==========================================
                    // 🎡 1. DEDICATED WHEEL ZOOM IN / OUT CARD
                    // ==========================================
                    Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: _selectedElementIndex == 21
                              ? Colors.greenAccent
                              : Colors.cyanAccent.withOpacity(0.5),
                          width: _selectedElementIndex == 21 ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.zoom_in,
                                      color: Colors.greenAccent,
                                      size: 22,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '🔍 Entire Wheel Zoom (পুরো হুইল জুম ইন / আউট):',
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                  child: Text(
                                    '${(_wheelScale * 100).toStringAsFixed(0)}% (${_wheelScale.toStringAsFixed(2)}x)',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Slider(
                              value: _wheelScale.clamp(0.5, 1.8),
                              min: 0.5,
                              max: 1.8,
                              divisions: 26,
                              activeColor: Colors.greenAccent,
                              inactiveColor: Colors.white24,
                              label:
                                  '${(_wheelScale * 100).toStringAsFixed(0)}%',
                              onChanged: (val) {
                                setState(() {
                                  _wheelScale = val;
                                  _selectedElementIndex = 21;
                                });
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _wheelScale = (_wheelScale - 0.05).clamp(
                                        0.5,
                                        1.8,
                                      );
                                      _selectedElementIndex = 21;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.zoom_out,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Zoom Out (-5%)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _wheelScale = 1.0;
                                      _selectedElementIndex = 21;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.restart_alt,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                  label: const Text(
                                    '100% Reset',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _wheelScale = (_wheelScale + 0.05).clamp(
                                        0.5,
                                        1.8,
                                      );
                                      _selectedElementIndex = 21;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.zoom_in,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Zoom In (+5%)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ==========================================
                    // 🪵 2. DEDICATED SPOKES / STICKS THICKNESS CARD
                    // ==========================================
                    Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: _selectedElementIndex == 22
                              ? Colors.amber
                              : Colors.orangeAccent.withOpacity(0.5),
                          width: _selectedElementIndex == 22 ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.linear_scale,
                                      color: Colors.orangeAccent,
                                      size: 22,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '🪵 Spokes Sticks Thickness (কাঠি মোটা / চিকন):',
                                      style: TextStyle(
                                        color: Colors.orangeAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orangeAccent,
                                    ),
                                  ),
                                  child: Text(
                                    '${((_spokesLayout['strokeWidth'] as num?)?.toDouble() ?? 4.5).toStringAsFixed(1)} px',
                                    style: const TextStyle(
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Slider(
                              value:
                                  ((_spokesLayout['strokeWidth'] as num?)
                                              ?.toDouble() ??
                                          4.5)
                                      .clamp(1.0, 15.0),
                              min: 1.0,
                              max: 15.0,
                              divisions: 28,
                              activeColor: Colors.orangeAccent,
                              inactiveColor: Colors.white24,
                              label:
                                  '${((_spokesLayout['strokeWidth'] as num?)?.toDouble() ?? 4.5).toStringAsFixed(1)} px',
                              onChanged: (val) {
                                setState(() {
                                  _spokesLayout['strokeWidth'] = val;
                                  _selectedElementIndex = 22;
                                });
                              },
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                for (var preset in [
                                  {'label': 'খুব চিকন (2px)', 'val': 2.0},
                                  {'label': 'স্বাভাবিক (4.5px)', 'val': 4.5},
                                  {'label': 'মোটা (8px)', 'val': 8.0},
                                  {'label': 'খুব মোটা (12px)', 'val': 12.0},
                                ])
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _spokesLayout['strokeWidth'] =
                                            preset['val'];
                                        _selectedElementIndex = 22;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      side: BorderSide(
                                        color:
                                            ((_spokesLayout['strokeWidth']
                                                            as num?)
                                                        ?.toDouble() ??
                                                    4.5) ==
                                                preset['val']
                                            ? Colors.orangeAccent
                                            : Colors.white30,
                                      ),
                                    ),
                                    child: Text(
                                      preset['label'] as String,
                                      style: TextStyle(
                                        color:
                                            ((_spokesLayout['strokeWidth']
                                                            as num?)
                                                        ?.toDouble() ??
                                                    4.5) ==
                                                preset['val']
                                            ? Colors.orangeAccent
                                            : Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Color Selector for Spokes
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  '🎨 কাঠির কালার:',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                for (var colorOption in [
                                  {'color': '#8A4128', 'name': 'কাঠ'},
                                  {'color': '#FFD700', 'name': 'গোল্ড'},
                                  {'color': '#FFFFFF', 'name': 'সাদা'},
                                  {'color': '#3E170A', 'name': 'গাঢ় বাদামি'},
                                  {'color': '#00E5FF', 'name': 'নিয়ন'},
                                ])
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _spokesLayout['color'] =
                                            colorOption['color'];
                                        _selectedElementIndex = 22;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(
                                          int.parse(
                                            'FF${(colorOption['color'] as String).replaceAll('#', '')}',
                                            radix: 16,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color:
                                              _spokesLayout['color'] ==
                                                  colorOption['color']
                                              ? Colors.amberAccent
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        colorOption['name'] as String,
                                        style: TextStyle(
                                          color:
                                              colorOption['color'] ==
                                                      '#FFFFFF' ||
                                                  colorOption['color'] ==
                                                      '#FFD700'
                                              ? Colors.black
                                              : Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Directional Nudge Stepper (Up/Down/Left/Right)
                    Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🕹️ Live Position Controls (উপরে, নিচে, ডানে, বামে সরান):',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton.filled(
                                  onPressed: () => _nudgeSelected(dy: -5),
                                  icon: const Icon(Icons.arrow_upward),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                  ),
                                  tooltip: 'Move UP 5px',
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton.filled(
                                  onPressed: () => _nudgeSelected(dx: -5),
                                  icon: const Icon(Icons.arrow_back),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                  ),
                                  tooltip: 'Move LEFT 5px',
                                ),
                                const SizedBox(width: 24),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'X: ${currentX.toStringAsFixed(0)} | Y: ${currentY.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                IconButton.filled(
                                  onPressed: () => _nudgeSelected(dx: 5),
                                  icon: const Icon(Icons.arrow_forward),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                  ),
                                  tooltip: 'Move RIGHT 5px',
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton.filled(
                                  onPressed: () => _nudgeSelected(dy: 5),
                                  icon: const Icon(Icons.arrow_downward),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                  ),
                                  tooltip: 'Move DOWN 5px',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sliders for Exact Pixel Fine-tuning
                    Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // X Position Slider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '↔️ Left / X Position (ডানে-বামে):',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${currentX.toStringAsFixed(0)} px',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: currentX.clamp(-50.0, 320.0),
                              min: -50.0,
                              max: 320.0,
                              activeColor: Colors.amber,
                              onChanged: (val) {
                                setState(() {
                                  if (_selectedElementIndex >= 0 &&
                                      _selectedElementIndex < 8) {
                                    _slotLayouts[_selectedElementIndex]['left'] =
                                        val;
                                  } else if (_selectedElementIndex == 8) {
                                    _hubLayout['left'] = val;
                                  } else if (_selectedElementIndex == 9) {
                                    _fruitBadgeLayout['left'] = val;
                                  } else if (_selectedElementIndex == 10) {
                                    _pizzaBadgeLayout['left'] = val;
                                  } else if (_selectedElementIndex == 12) {
                                    _trophyLayout['left'] = val;
                                  }
                                });
                              },
                            ),

                            // Y Position Slider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '↕️ Top / Y Position (উপরে-নিচে):',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${currentY.toStringAsFixed(0)} px',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: currentY.clamp(-100.0, 600.0),
                              min: -100.0,
                              max: 600.0,
                              activeColor: Colors.amber,
                              onChanged: (val) {
                                setState(() {
                                  if (_selectedElementIndex >= 0 &&
                                      _selectedElementIndex < 8) {
                                    _slotLayouts[_selectedElementIndex]['top'] =
                                        val;
                                  } else if (_selectedElementIndex == 8) {
                                    _hubLayout['top'] = val;
                                  } else if (_selectedElementIndex == 9) {
                                    _fruitBadgeLayout['top'] = val;
                                  } else if (_selectedElementIndex == 10) {
                                    _pizzaBadgeLayout['top'] = val;
                                  } else if (_selectedElementIndex == 11) {
                                    _topHeaderLayout['top'] = val;
                                  } else if (_selectedElementIndex == 12) {
                                    _trophyLayout['top'] = val;
                                  } else if (_selectedElementIndex == 14) {
                                    _arenaLayout['marginTop'] = val;
                                  } else if (_selectedElementIndex == 15) {
                                    _skylineLayout['top'] = val;
                                  } else if (_selectedElementIndex == 16) {
                                    _todaysWinLayout['marginTop'] = val;
                                  } else if (_selectedElementIndex == 17) {
                                    _wagerPromptLayout['marginTop'] = val;
                                  } else if (_selectedElementIndex == 18) {
                                    _chipTrayLayout['marginTop'] = val;
                                  } else if (_selectedElementIndex == 19) {
                                    _milestonesLayout['marginTop'] = val;
                                  } else if (_selectedElementIndex == 20) {
                                    _historyRowLayout['marginTop'] = val;
                                  }
                                });
                              },
                            ),

                            // Width/Size Slider (if applicable)
                            if (_selectedElementIndex < 11) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '🔍 Card Width / Size (প্রস্থ / বড়-ছোট):',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${currentW.toStringAsFixed(0)} px',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: currentW.clamp(30.0, 150.0),
                                min: 30.0,
                                max: 150.0,
                                activeColor: Colors.greenAccent,
                                onChanged: (val) {
                                  setState(() {
                                    if (_selectedElementIndex >= 0 &&
                                        _selectedElementIndex < 8) {
                                      _slotLayouts[_selectedElementIndex]['width'] =
                                          val;
                                    } else if (_selectedElementIndex == 8) {
                                      _hubLayout['size'] = val;
                                    } else if (_selectedElementIndex == 9) {
                                      _fruitBadgeLayout['width'] = val;
                                    } else if (_selectedElementIndex == 10) {
                                      _pizzaBadgeLayout['width'] = val;
                                    }
                                  });
                                },
                              ),
                            ],

                            // Height Slider for 8 slot cards and badges
                            if ((_selectedElementIndex >= 0 && _selectedElementIndex < 8) || _selectedElementIndex == 9 || _selectedElementIndex == 10) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '📏 Card Height (উচ্চতা):',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${((_selectedElementIndex < 8 ? _slotLayouts[_selectedElementIndex]['height'] : _selectedElementIndex == 9 ? _fruitBadgeLayout['height'] : _pizzaBadgeLayout['height']) ?? 76.0).toStringAsFixed(0)} px',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: ((_selectedElementIndex < 8 ? _slotLayouts[_selectedElementIndex]['height'] : _selectedElementIndex == 9 ? _fruitBadgeLayout['height'] : _pizzaBadgeLayout['height']) ?? 76.0).clamp(30.0, 160.0),
                                min: 30.0,
                                max: 160.0,
                                activeColor: Colors.greenAccent,
                                onChanged: (val) {
                                  setState(() {
                                    if (_selectedElementIndex >= 0 && _selectedElementIndex < 8) {
                                      _slotLayouts[_selectedElementIndex]['height'] = val;
                                    } else if (_selectedElementIndex == 9) {
                                      _fruitBadgeLayout['height'] = val;
                                    } else if (_selectedElementIndex == 10) {
                                      _pizzaBadgeLayout['height'] = val;
                                    }
                                  });
                                },
                              ),
                            ],

                            // Zoom In / Zoom Out (Scale) Controls for ALL 8 Slot Items, Bear Hub, Fruit & Pizza Badges
                            if (_selectedElementIndex <= 10) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '🔎 Zoom In / Zoom Out Scale (জুম ইন/আউট):',
                                    style: TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${((_selectedElementIndex < 8 ? _slotLayouts[_selectedElementIndex]['scale'] : _selectedElementIndex == 8 ? _hubLayout['scale'] : _selectedElementIndex == 9 ? _fruitBadgeLayout['scale'] : _pizzaBadgeLayout['scale']) ?? 1.0).toStringAsFixed(2)}x',
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: ((_selectedElementIndex < 8 ? _slotLayouts[_selectedElementIndex]['scale'] : _selectedElementIndex == 8 ? _hubLayout['scale'] : _selectedElementIndex == 9 ? _fruitBadgeLayout['scale'] : _pizzaBadgeLayout['scale']) ?? 1.0).clamp(0.4, 2.5),
                                min: 0.4,
                                max: 2.5,
                                activeColor: Colors.cyanAccent,
                                onChanged: (val) {
                                  setState(() {
                                    if (_selectedElementIndex >= 0 && _selectedElementIndex < 8) {
                                      _slotLayouts[_selectedElementIndex]['scale'] = val;
                                    } else if (_selectedElementIndex == 8) {
                                      _hubLayout['scale'] = val;
                                    } else if (_selectedElementIndex == 9) {
                                      _fruitBadgeLayout['scale'] = val;
                                    } else if (_selectedElementIndex == 10) {
                                      _pizzaBadgeLayout['scale'] = val;
                                    }
                                  });
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  for (var zoomOption in [
                                    {'label': '0.6x', 'val': 0.6},
                                    {'label': '0.8x', 'val': 0.8},
                                    {'label': '1.0x (স্বাভাবিক)', 'val': 1.0},
                                    {'label': '1.3x', 'val': 1.3},
                                    {'label': '1.6x', 'val': 1.6},
                                    {'label': '2.0x', 'val': 2.0},
                                  ])
                                    OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          final val = zoomOption['val'] as double;
                                          if (_selectedElementIndex >= 0 && _selectedElementIndex < 8) {
                                            _slotLayouts[_selectedElementIndex]['scale'] = val;
                                          } else if (_selectedElementIndex == 8) {
                                            _hubLayout['scale'] = val;
                                          } else if (_selectedElementIndex == 9) {
                                            _fruitBadgeLayout['scale'] = val;
                                          } else if (_selectedElementIndex == 10) {
                                            _pizzaBadgeLayout['scale'] = val;
                                          }
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        side: BorderSide(
                                          color: ((_selectedElementIndex < 8 ? _slotLayouts[_selectedElementIndex]['scale'] : _selectedElementIndex == 8 ? _hubLayout['scale'] : _selectedElementIndex == 9 ? _fruitBadgeLayout['scale'] : _pizzaBadgeLayout['scale']) ?? 1.0) == zoomOption['val']
                                              ? Colors.cyanAccent
                                              : Colors.white24,
                                        ),
                                      ),
                                      child: Text(
                                        zoomOption['label'] as String,
                                        style: TextStyle(
                                          color: ((_selectedElementIndex < 8 ? _slotLayouts[_selectedElementIndex]['scale'] : _selectedElementIndex == 8 ? _hubLayout['scale'] : _selectedElementIndex == 9 ? _fruitBadgeLayout['scale'] : _pizzaBadgeLayout['scale']) ?? 1.0) == zoomOption['val']
                                              ? Colors.cyanAccent
                                              : Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // --- 1. UI & THEME MANAGEMENT TAB ---
  // =========================================================================
  Widget _buildUIThemeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎨 Game Assets & Theme Configuration',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildUploaderCard(
            'Game Background Image (গেম ব্যাকগ্রাউন্ড)',
            _gameBackgroundUrlCtrl,
            'gameBackgroundUrl',
            'backgrounds',
          ),
          const SizedBox(height: 16),
          _buildUploaderCard(
            'Game Logo (গেমের লোগো)',
            _logoUrlCtrl,
            'logoUrl',
            'logos',
          ),
          const SizedBox(height: 16),
          _buildUploaderCard(
            'Diamond Icon (ডায়মন্ড আইকন)',
            _diamondIconCtrl,
            'diamondIcon',
            'icons',
          ),
          const SizedBox(height: 16),
          _buildUploaderCard(
            'Trophy Icon (টপ ১০ ট্রফি)',
            _trophyIconCtrl,
            'trophyIcon',
            'icons',
          ),
          const SizedBox(height: 16),
          _buildUploaderCard(
            'Winner Banner (উইনার ব্যানার)',
            _winBannerCtrl,
            'winBannerUrl',
            'banners',
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // --- 2. 8 FOOD/FRUIT ITEMS TAB ---
  // =========================================================================
  Widget _buildItemsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Fruit & Pizza Category Badges Pictures & Labels
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.cyanAccent, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.category, color: Colors.cyanAccent, size: 24),
                      SizedBox(width: 10),
                      Text(
                        '🥗 Side Category Badges (Fruit & Pizza Picture & Labels)',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Fruit Badge Row
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                        ),
                        child: _fruitBadgeIconCtrl.text.isNotEmpty
                            ? Image.network(
                                _fruitBadgeIconCtrl.text,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image, color: Colors.white30),
                              )
                            : const Icon(Icons.fastfood, color: Colors.cyanAccent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _fruitBadgeLabelCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Fruit Badge Label',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: TextField(
                          controller: _fruitBadgeIconCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            labelText: 'Fruit Image URL (https://...)',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _pickAndUploadImage(_fruitBadgeIconCtrl, 'fruitBadge', 'badges'),
                        icon: _uploadingStates['fruitBadge'] == true
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.upload, size: 16, color: Colors.black),
                        label: const Text('Upload', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Pizza Badge Row
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                        ),
                        child: _pizzaBadgeIconCtrl.text.isNotEmpty
                            ? Image.network(
                                _pizzaBadgeIconCtrl.text,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image, color: Colors.white30),
                              )
                            : const Icon(Icons.local_pizza, color: Colors.orangeAccent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _pizzaBadgeLabelCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Pizza Badge Label',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: TextField(
                          controller: _pizzaBadgeIconCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            labelText: 'Pizza Image URL (https://...)',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _pickAndUploadImage(_pizzaBadgeIconCtrl, 'pizzaBadge', 'badges'),
                        icon: _uploadingStates['pizzaBadge'] == true
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.upload, size: 16, color: Colors.black),
                        label: const Text('Upload', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. 8 Wheel Betting Items Header
          const Text(
            '🍔 8 Wheel Betting Items & Multipliers Configuration',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < 8; i++) ...[
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.amber.withOpacity(0.2),
                      child: Text(
                        '#${i + 1}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _itemNames[i],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _itemMultipliers[i],
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Multiplier (x)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _itemIcons[i],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Icon Image URL',
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _pickAndUploadImage(
                              _itemIcons[i],
                              'item_$i',
                              'items',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                            ),
                            child: const Text(
                              'Upload',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // --- 3. 5 CHIPS TAB ---
  // =========================================================================
  Widget _buildChipsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🪙 5 Casino Betting Chips Configuration',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < 5; i++) ...[
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.cyan.withOpacity(0.2),
                      child: Text(
                        '#${i + 1}',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _chipLabels[i],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Chip Label (e.g. 1K)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _chipValues[i],
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Diamond Value',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _chipColors[i],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Hex Color (e.g. #33ff77)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // --- 4. WINNING TAB ---
  // =========================================================================
  Widget _buildWinningTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 Result of Round Winner Modal Configuration',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Modal Theme: Red Bottom-Sheet Modal Card',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Features Floating 86px glowing item emblem at top center.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    '• Shows 1-2-3 Biggest Winners of the round with gold/cyan/bronze badges.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    '• Shows exact user win/loss status with live diamond increments.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // --- 5. GAME RULES & CONTROL TAB ---
  // =========================================================================
  Widget _buildRulesControlTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ Game Timing, RTP & Server Controls',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _betTimeCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Betting Phase Duration (Seconds)',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _spinTimeCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Wheel Spin Duration (Seconds)',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _resultTimeCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Result Modal Duration (Seconds)',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Win Ratio (RTP Return to Player):',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Slider(
                          value: _winRatio,
                          min: 10,
                          max: 95,
                          divisions: 17,
                          activeColor: Colors.greenAccent,
                          label: '${_winRatio.round()}%',
                          onChanged: (val) => setState(() => _winRatio = val),
                        ),
                      ),
                      Text(
                        '${_winRatio.round()}%',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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

  Widget _buildUploaderCard(
    String title,
    TextEditingController controller,
    String keyId,
    String folder,
  ) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter Image URL or Upload...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () =>
                      _pickAndUploadImage(controller, keyId, folder),
                  icon: _uploadingStates[keyId] == true
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.upload, color: Colors.black, size: 18),
                  label: const Text(
                    'Upload',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                ),
              ],
            ),
            if (controller.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  controller.text,
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SpokesPainter extends CustomPainter {
  final double strokeWidth;
  final String color;

  _SpokesPainter({this.strokeWidth = 4.5, this.color = '#8A4128'});

  @override
  void paint(Canvas canvas, Size size) {
    Color paintColor = const Color(0xFF8A4128);
    try {
      final hex = color.replaceAll('#', '');
      if (hex.length == 6) {
        paintColor = Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}

    final paint = Paint()
      ..color = paintColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    const radius = 115.0;

    for (int i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + (i * 2 * math.pi / 8);
      final p2 = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpokesPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth || oldDelegate.color != color;
}
