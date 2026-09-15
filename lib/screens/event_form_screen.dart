import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/event_model.dart';
import '../services/firebase_data_service.dart';
import '../widgets/media_preview_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventFormScreen extends StatefulWidget {
  final EventModel? event;
  final String? initialEventType;

  const EventFormScreen({super.key, this.event, this.initialEventType});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();
  final _eligibleGiftIdsController = TextEditingController();
  final _bgColorController = TextEditingController();
  final _accentColorController = TextEditingController();
  final _bgImageUrlController = TextEditingController();
  Uint8List? _bgImageBytes;
  String? _bgImageFileName;

  String _rankingType = 'Top Sender';
  String _status = 'inactive';
  String _eventType = 'weekly_star';
  bool _hasRegistrationForm = false;

  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(days: 7));

  List<Map<String, dynamic>> _rewards = [];
  List<Map<String, dynamic>> _clickableAreas = [];

  Map<String, dynamic> _themeConfig = {
    'backgroundColor': '#0F0B21',
    'accentColor': '#FFC107',
    'backgroundImageUrl': '',
  };
  List<Map<String, dynamic>> _layoutBlocks = [];

  String _bannerUrl = '';
  late String _eventId;
  bool _isSaving = false;

  final List<String> _rankingTypes = [
    'Top Sender',
    'Top Receiver',
    'Weekly Star',
    'Room Ranking',
    'Family Ranking',
    'Couple Ranking',
    'Recharge Ranking',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _eventId = widget.event!.eventId;
      _nameController.text = widget.event!.eventName;
      _descriptionController.text = widget.event!.description;
      _rulesController.text = widget.event!.rules;
      _rankingType = widget.event!.rankingType;
      _status = widget.event!.status;
      _startTime = widget.event!.startTime;
      _endTime = widget.event!.endTime;
      _bannerUrl = widget.event!.banner;
      _rewards = List.from(widget.event!.rewards);
      _hasRegistrationForm = widget.event!.hasRegistrationForm;
      _eligibleGiftIdsController.text = widget.event!.eligibleGiftIds.join(', ');
      _clickableAreas = List.from(widget.event!.bannerClickableAreas);
      _eventType = widget.event!.eventType;

      _themeConfig = Map<String, dynamic>.from(widget.event!.themeConfig);
      if (_themeConfig.isEmpty) {
        _themeConfig = {
          'backgroundColor': '#0F0B21',
          'accentColor': '#FFC107',
          'backgroundImageUrl': '',
        };
      }

      _layoutBlocks = List<Map<String, dynamic>>.from(widget.event!.layoutBlocks);

      if (_layoutBlocks.isEmpty && _bannerUrl.isNotEmpty) {
        _layoutBlocks.add({
          'type': 'image',
          'imageUrl': _bannerUrl,
          'clickableAreas': _clickableAreas,
        });
      }
    } else {
      _eventId = 'EVT${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      _eventType = widget.initialEventType ?? 'weekly_star';
      _initializeLayoutBlocksForType(_eventType);
    }
    _bgColorController.text = _themeConfig['backgroundColor'] ?? '#0F0B21';
    _accentColorController.text = _themeConfig['accentColor'] ?? '#FFC107';
    _bgImageUrlController.text = _themeConfig['backgroundImageUrl'] ?? '';
  }

  void _initializeLayoutBlocksForType(String type, {bool force = false}) {
    if (_layoutBlocks.isNotEmpty && !force) return;

    setState(() {
      _layoutBlocks.clear();
      
      String bg = '#0F0B21';
      String accent = '#FFC107';
      if (type == 'game_star') {
        bg = '#0F1E29';
        accent = '#FFD700';
      } else if (type == 'gifter_receiver') {
        bg = '#260D1E';
        accent = '#E91E63';
      } else if (type == 'top_room') {
        bg = '#072124';
        accent = '#00E5FF';
      } else if (type == 'top_active') {
        bg = '#241A07';
        accent = '#FF9800';
      } else if (type == 'stacked_join') {
        bg = '#000000';
        accent = '#4CAF50';
      } else if (type == 'recharge') {
        bg = '#120024';
        accent = '#E040FB';
      } else if (type == 'agency_battle') {
        bg = '#3E1F0B';
        accent = '#FF5722';
      }
      _themeConfig['backgroundColor'] = bg;
      _themeConfig['accentColor'] = accent;
      _bgColorController.text = bg;
      _accentColorController.text = accent;

      if (type == 'stacked_join') {
        _layoutBlocks.add({
          'type': 'image',
          'imageUrl': 'https://placehold.co/600x300/png?text=First+Image',
          'clickableAreas': <Map<String, dynamic>>[],
        });
        _layoutBlocks.add({
          'type': 'image',
          'imageUrl': 'https://placehold.co/600x300/png?text=Second+Image',
          'clickableAreas': <Map<String, dynamic>>[],
        });
        _layoutBlocks.add({
          'type': 'image',
          'imageUrl': 'https://placehold.co/600x300/png?text=Third+Image',
          'clickableAreas': <Map<String, dynamic>>[],
        });
        _layoutBlocks.add({
          'type': 'spacer',
          'height': 15.0,
          'color': 'transparent',
        });
        _layoutBlocks.add({
          'type': 'join_room',
          'roomId': '234570756',
          'buttonText': 'Click here to enter room 234570756',
          'buttonColor': '#00C853',
          'textColor': '#ffffff',
        });
      } else {
        _layoutBlocks.add({
          'type': 'image',
          'imageUrl': _bannerUrl.isNotEmpty ? _bannerUrl : 'https://placehold.co/600x400/png',
          'clickableAreas': <Map<String, dynamic>>[],
        });

        if (type == 'weekly_star') {
          _layoutBlocks.add({
            'type': 'action_row',
            'items': [
              {'icon': 'history', 'label': 'Last Week', 'action': 'open_url', 'data': ''},
              {'icon': 'description', 'label': 'Rules', 'action': 'open_rules', 'data': ''},
              {'icon': 'emoji_events', 'label': 'Hall of Fame', 'action': 'open_url', 'data': ''},
            ],
          });
        } else {
          _layoutBlocks.add({
            'type': 'action_row',
            'items': [
              {'icon': 'description', 'label': 'Rules', 'action': 'open_rules', 'data': ''},
            ],
          });
        }

        String color1 = '#8E2DE2';
        String color2 = '#4A00E0';
        if (type == 'game_star') {
          color1 = '#1F4068';
          color2 = '#162447';
        } else if (type == 'gifter_receiver') {
          color1 = '#D63447';
          color2 = '#7A0826';
        } else if (type == 'top_room') {
          color1 = '#00ADB5';
          color2 = '#222831';
        } else if (type == 'top_active') {
          color1 = '#F08A5D';
          color2 = '#B83B5E';
        } else if (type == 'recharge') {
          color1 = '#833ab4';
          color2 = '#fd1d1d';
        }

        _layoutBlocks.add({
          'type': 'countdown',
          'style': 'gradient',
          'color1': color1,
          'color2': color2,
          'textColor': '#ffffff',
        });

        if (type == 'weekly_star') {
          _layoutBlocks.add({
            'type': 'tabbed_leaderboard',
            'activeTabColor': accent,
            'inactiveTabColor': '#9E9E9E',
            'showPodium': true,
            'tabs': [
              {'title': 'Charming Star', 'rankType': 'receiver', 'limit': 100},
              {'title': 'Wealthy Star', 'rankType': 'sender', 'limit': 100},
            ],
          });
        } else if (type == 'game_star') {
          _layoutBlocks.add({
            'type': 'tabbed_leaderboard',
            'activeTabColor': accent,
            'inactiveTabColor': '#9E9E9E',
            'showPodium': true,
            'tabs': [
              {'title': 'Greedy Game', 'rankType': 'greedy_game', 'limit': 100},
              {'title': 'Fruit Wheel', 'rankType': 'fruit_wheel', 'limit': 100},
            ],
          });
        } else if (type == 'gifter_receiver') {
          _layoutBlocks.add({
            'type': 'tabbed_leaderboard',
            'activeTabColor': accent,
            'inactiveTabColor': '#9E9E9E',
            'showPodium': true,
            'tabs': [
              {'title': 'Top Receiver', 'rankType': 'receiver', 'limit': 100},
              {'title': 'Top Gifter', 'rankType': 'sender', 'limit': 100},
            ],
          });
        } else if (type == 'top_room') {
          _layoutBlocks.add({
            'type': 'tabbed_leaderboard',
            'activeTabColor': accent,
            'inactiveTabColor': '#9E9E9E',
            'showPodium': false,
            'tabs': [
              {'title': 'Top Rooms', 'rankType': 'room', 'limit': 50},
            ],
          });
        } else if (type == 'top_active') {
          _layoutBlocks.add({
            'type': 'tabbed_leaderboard',
            'activeTabColor': accent,
            'inactiveTabColor': '#9E9E9E',
            'showPodium': false,
            'tabs': [
              {'title': 'Active Rooms', 'rankType': 'active_room', 'limit': 50},
              {'title': 'Active Users', 'rankType': 'active_user', 'limit': 50},
            ],
          });
        } else if (type == 'recharge') {
          _layoutBlocks.add({
            'type': 'tabbed_leaderboard',
            'activeTabColor': accent,
            'inactiveTabColor': '#9E9E9E',
            'showPodium': true,
            'tabs': [
              {'title': 'Top Recharge', 'rankType': 'recharge', 'limit': 100},
            ],
          });
        }
      }
    });
  }

  Future<void> _pickImageForBlock(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _layoutBlocks[index]['imageBytes'] = result.files.first.bytes;
        _layoutBlocks[index]['imageFileName'] = result.files.first.name;
        _layoutBlocks[index]['imageUrl'] = null;
      });
    }
  }

  Future<String?> _uploadBlockImage(Uint8List bytes, String fileName) async {
    try {
      final storageName = 'event_layouts/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = FirebaseStorage.instance.ref().child(storageName);
      final uploadTask = await ref.putData(bytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading layout image: $e');
      return null;
    }
  }

  void _showColorPickerDialog({required bool isBackground}) {
    final List<Map<String, dynamic>> premiumColors = [
      {'name': 'Deep Violet', 'hex': '#0F0B21'},
      {'name': 'Night Blue', 'hex': '#1A1B2F'},
      {'name': 'Maroon', 'hex': '#260D1E'},
      {'name': 'Dark Teal', 'hex': '#072124'},
      {'name': 'Dark Amber', 'hex': '#241A07'},
      {'name': 'Forest Green', 'hex': '#07241A'},
      {'name': 'Pure Black', 'hex': '#000000'},
      {'name': 'Slate Grey', 'hex': '#121212'},
      {'name': 'Cyan Accent', 'hex': '#00E5FF'},
      {'name': 'Amber Accent', 'hex': '#FFC107'},
      {'name': 'Green Accent', 'hex': '#4CAF50'},
      {'name': 'Blue Accent', 'hex': '#2196F3'},
      {'name': 'Pink Accent', 'hex': '#E91E63'},
      {'name': 'Red Accent', 'hex': '#F44336'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        String currentHex = isBackground ? _bgColorController.text : _accentColorController.text;
        final customColorController = TextEditingController(text: currentHex);

        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            isBackground ? 'Select Background Color' : 'Select Accent Color',
            style: const TextStyle(color: Colors.white),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: premiumColors.map((colorInfo) {
                      final String hex = colorInfo['hex'];
                      Color parsedColor = Colors.white;
                      try {
                        parsedColor = Color(int.parse(hex.replaceAll('#', '0xFF')));
                      } catch (_) {}

                      final isSelected = currentHex.toLowerCase() == hex.toLowerCase();

                      return Tooltip(
                        message: colorInfo['name'],
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isBackground) {
                                _bgColorController.text = hex;
                                _themeConfig['backgroundColor'] = hex;
                              } else {
                                _accentColorController.text = hex;
                                _themeConfig['accentColor'] = hex;
                              }
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: parsedColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey[700]!,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: customColorController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Custom Hex Color (e.g. #FF5722)',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) {
                      currentHex = v;
                    },
                  ),
                ],
              );
            }
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (customColorController.text.isNotEmpty) {
                  String hex = customColorController.text.trim();
                  if (!hex.startsWith('#')) hex = '#$hex';
                  setState(() {
                    if (isBackground) {
                      _bgColorController.text = hex;
                      _themeConfig['backgroundColor'] = hex;
                    } else {
                      _accentColorController.text = hex;
                      _themeConfig['accentColor'] = hex;
                    }
                  });
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickBackgroundImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _bgImageBytes = result.files.first.bytes;
        _bgImageFileName = result.files.first.name;
        _bgImageUrlController.text = '';
        _themeConfig['backgroundImageUrl'] = '';
      });
    }
  }

  Color _parseHexColor(String hexStr, {required Color defaultColor}) {
    if (hexStr.isEmpty) return defaultColor;
    try {
      return Color(int.parse(hexStr.replaceAll('#', '0xFF')));
    } catch (_) {
      return defaultColor;
    }
  }

  Future<void> _selectDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : _endTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Colors.blue,
                onPrimary: Colors.white,
                surface: Color(0xFF1E1E1E),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (time != null) {
        setState(() {
          final newDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          if (isStart) {
            _startTime = newDateTime;
          } else {
            _endTime = newDateTime;
          }
        });
      }
    }
  }

  void _addReward() {
    String selectedCategory = 'Diamonds';
    final rankController = TextEditingController(text: 'Top 1');
    final itemIdController = TextEditingController();
    final valueController = TextEditingController();
    List<Map<String, dynamic>> fetchedItems = [];
    List<bool> selectedItems = [];
    bool isFetching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configure Reward',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: rankController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Rank/Position (e.g., Top 1, Top 2-5)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[850],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Diamonds',
                        'Coins',
                        'Item',
                        'Badge',
                        'Frame',
                        'Room Background Theme',
                      ].map((cat) {
                        return ChoiceChip(
                          label: Text(cat),
                          selected: selectedCategory == cat,
                          onSelected: (selected) {
                            if (selected) {
                              setStateModal(() {
                                selectedCategory = cat;
                                fetchedItems.clear();
                                selectedItems.clear();
                              });
                            }
                          },
                          selectedColor: Colors.blue.withValues(alpha: 0.3),
                          labelStyle: TextStyle(
                            color: selectedCategory == cat ? Colors.blue : Colors.grey,
                          ),
                          backgroundColor: Colors.grey[800],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    if (selectedCategory == 'Diamonds' || selectedCategory == 'Coins') ...[
                      TextFormField(
                        controller: valueController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: itemIdController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Item IDs (comma separated)',
                                labelStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey[850],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              if (itemIdController.text.isEmpty) return;
                              setStateModal(() => isFetching = true);

                              final ids = itemIdController.text
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList();
                              List<Map<String, dynamic>> items = [];

                              for (var id in ids) {
                                final item = await FirebaseDataService.fetchItemById(id);
                                if (item != null) {
                                  items.add(item);
                                }
                              }

                              setStateModal(() {
                                fetchedItems = items;
                                selectedItems = List.generate(items.length, (index) => true);
                                isFetching = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isFetching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Fetch All'),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () => _showItemBrowserDialog(setStateModal, fetchedItems, selectedItems),
                              icon: const Icon(Icons.manage_search, color: Colors.blue),
                              tooltip: 'Browse All Items',
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                      ),
                      if (fetchedItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: fetchedItems.length,
                            itemBuilder: (context, index) {
                              final item = fetchedItems[index];
                              return CheckboxListTile(
                                value: selectedItems[index],
                                onChanged: (val) {
                                  setStateModal(() => selectedItems[index] = val ?? false);
                                },
                                title: Text(
                                  item['name'] ?? 'Unknown Item',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'ID: ${item['id']} | Type: ${item['type'] ?? item['category'] ?? 'Item'}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                secondary: item['fileUrl'] != null
                                    ? MediaPreviewWidget(url: item['fileUrl'], width: 40, height: 40)
                                    : const Icon(Icons.check_circle, color: Colors.green),
                                activeColor: Colors.blue,
                                tileColor: Colors.grey[850],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: valueController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Duration (Days) - 0 for Permanent (applies to all)',
                            labelStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[850],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedCategory != 'Diamonds' && selectedCategory != 'Coins') {
                            if (fetchedItems.isEmpty || !selectedItems.contains(true)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fetch and select at least one valid item.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            setState(() {
                              for (int i = 0; i < fetchedItems.length; i++) {
                                if (selectedItems[i]) {
                                  _rewards.add({
                                    'rank': rankController.text.trim().isEmpty ? 'All' : rankController.text.trim(),
                                    'category': selectedCategory,
                                    'amount': valueController.text.isNotEmpty ? int.tryParse(valueController.text) ?? 0 : 0,
                                    'itemId': fetchedItems[i]['id'],
                                    'itemName': fetchedItems[i]['name'],
                                    'itemCollection': fetchedItems[i]['collection'],
                                    'fileUrl': fetchedItems[i]['fileUrl'],
                                  });
                                }
                              }
                            });
                          } else {
                            setState(() {
                              _rewards.add({
                                'rank': rankController.text.trim().isEmpty ? 'All' : rankController.text.trim(),
                                'category': selectedCategory,
                                'amount': valueController.text.isNotEmpty ? int.tryParse(valueController.text) ?? 0 : 0,
                              });
                            });
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          selectedCategory == 'Diamonds' || selectedCategory == 'Coins' ? 'Add Reward' : 'Add Selected Rewards',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addClickableArea(int blockIndex) {
    final xController = TextEditingController(text: '0');
    final yController = TextEditingController(text: '0');
    final wController = TextEditingController(text: '50');
    final hController = TextEditingController(text: '20');
    String actionType = 'open_registration';
    final actionDataController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Add Clickable Area', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Define area by percentage (0-100) relative to banner size.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: xController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'X (%)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: yController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Y (%)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: wController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Width (%)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: hController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Height (%)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: actionType,
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'open_registration', child: Text('Open Registration')),
                        DropdownMenuItem(value: 'join_event', child: Text('Join Event')),
                        DropdownMenuItem(value: 'open_url', child: Text('Open URL')),
                        DropdownMenuItem(value: 'open_rules', child: Text('Open Rules')),
                      ],
                      onChanged: (v) => setStateDialog(() => actionType = v!),
                      decoration: const InputDecoration(labelText: 'Action'),
                    ),
                    if (actionType == 'open_url') ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: actionDataController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'URL'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _layoutBlocks[blockIndex]['clickableAreas'] = _layoutBlocks[blockIndex]['clickableAreas'] ?? [];
                      (_layoutBlocks[blockIndex]['clickableAreas'] as List).add({
                        'x': double.tryParse(xController.text) ?? 0,
                        'y': double.tryParse(yController.text) ?? 0,
                        'w': double.tryParse(wController.text) ?? 50,
                        'h': double.tryParse(hController.text) ?? 20,
                        'action': actionType,
                        'data': actionDataController.text,
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    if (_bgImageBytes != null) {
      final uploadedUrl = await _uploadBlockImage(
        _bgImageBytes!,
        _bgImageFileName!,
      );
      if (uploadedUrl != null) {
        _themeConfig['backgroundImageUrl'] = uploadedUrl;
      }
    }

    for (int i = 0; i < _layoutBlocks.length; i++) {
      if (_layoutBlocks[i]['type'] == 'image' && _layoutBlocks[i]['imageBytes'] != null) {
        final uploadedUrl = await _uploadBlockImage(
          _layoutBlocks[i]['imageBytes'],
          _layoutBlocks[i]['imageFileName'],
        );
        if (uploadedUrl != null) {
          _layoutBlocks[i]['imageUrl'] = uploadedUrl;
        }
        _layoutBlocks[i].remove('imageBytes');
        _layoutBlocks[i].remove('imageFileName');
      }
    }

    if (_layoutBlocks.isNotEmpty && _layoutBlocks.first['type'] == 'image') {
      _bannerUrl = _layoutBlocks.first['imageUrl'] ?? '';
      _clickableAreas = List<Map<String, dynamic>>.from(_layoutBlocks.first['clickableAreas'] ?? []);
    }

    final data = {
      'eventId': _eventId,
      'eventName': _nameController.text,
      'banner': _bannerUrl,
      'description': _descriptionController.text,
      'rules': _rulesController.text,
      'rewards': _rewards,
      'rankingType': _rankingType,
      'startTime': Timestamp.fromDate(_startTime),
      'endTime': Timestamp.fromDate(_endTime),
      'status': _status,
      'eventLink': widget.event?.eventLink ?? 'https://appdomain.com/event/$_eventId',
      'deepLink': widget.event?.deepLink ?? 'imchat://event/$_eventId',
      'createdAt': widget.event?.createdAt != null
          ? Timestamp.fromDate(widget.event!.createdAt)
          : FieldValue.serverTimestamp(),
      'hasRegistrationForm': _hasRegistrationForm,
      'bannerClickableAreas': _clickableAreas,
      'eventType': _eventType,
      'eligibleGiftIds': _eligibleGiftIdsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'themeConfig': _themeConfig,
      'layoutBlocks': _layoutBlocks,
      'viewsCount': widget.event?.viewsCount ?? 0,
      'likesCount': widget.event?.likesCount ?? 0,
    };

    if (widget.event == null) {
      await FirebaseDataService.createEvent(data);
    } else {
      await FirebaseDataService.updateEvent(widget.event!.id, data);
    }

    setState(() => _isSaving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.event == null ? 'Create Event' : 'Edit Event',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          _isSaving
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: Colors.blue),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check, color: Colors.blue, size: 30),
                  onPressed: _save,
                ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 1000;

          final formWidget = Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildThemeAndLayoutBuilder(),
                const Divider(color: Colors.grey, height: 32),
                _buildEventDetailsForm(),
                const SizedBox(height: 80),
              ],
            ),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(flex: 3, child: formWidget),
                const VerticalDivider(color: Colors.grey, width: 1),
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.grey[950],
                    child: Center(
                      child: _buildPhoneSimulator(),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Editor', icon: Icon(Icons.edit)),
                      Tab(text: 'Preview', icon: Icon(Icons.phone_android)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        formWidget,
                        Container(
                          color: Colors.grey[950],
                          child: Center(
                            child: _buildPhoneSimulator(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildEventDetailsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Details',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text('Event ID:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _eventId,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.blue),
                tooltip: 'Copy ID',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _eventId));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied Event ID!')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(_nameController, 'Event Name', required: true),
        const SizedBox(height: 12),
        _buildTextField(_descriptionController, 'Description', maxLines: 3),
        const SizedBox(height: 12),
        _buildTextField(_rulesController, 'Rules', maxLines: 3),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
          child: SwitchListTile(
            title: const Text('Registration Required', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Users must register before participating', style: TextStyle(color: Colors.grey, fontSize: 12)),
            value: _hasRegistrationForm,
            activeThumbColor: Colors.blue,
            onChanged: (v) => setState(() => _hasRegistrationForm = v),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTimeSelector('Start Time', _startTime, true)),
            const SizedBox(width: 12),
            Expanded(child: _buildTimeSelector('End Time', _endTime, false)),
          ],
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          'Event Type (Template)',
          _eventType,
          [
            'weekly_star',
            'game_star',
            'gifter_receiver',
            'top_room',
            'top_active',
            'stacked_join',
            'recharge',
            'agency_battle',
          ],
          (v) => _handleEventTypeChange(v!),
        ),
        if (_eventType == 'weekly_star') ...[
          const SizedBox(height: 16),
          _buildTextField(_eligibleGiftIdsController, 'Eligible Gift IDs (comma separated)', maxLines: 2),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdown('Ranking Type', _rankingType, _rankingTypes, (v) => setState(() => _rankingType = v!)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown('Status', _status, ['active', 'inactive', 'expired'], (v) => setState(() => _status = v!)),
            ),
          ],
        ),
        const Divider(color: Colors.grey, height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Event Rewards', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _addReward,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Reward'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._rewards.asMap().entries.map((entry) {
          int idx = entry.key;
          Map<String, dynamic> reward = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: reward['fileUrl'] != null
                  ? MediaPreviewWidget(url: reward['fileUrl'], width: 40, height: 40)
                  : CircleAvatar(
                      backgroundColor: Colors.grey[850],
                      child: Icon(
                        reward['category'] == 'Diamonds' ? Icons.diamond : Icons.monetization_on,
                        color: Colors.yellow,
                        size: 20,
                      ),
                    ),
              title: Text(
                '${reward['rank'] != null ? '[${reward['rank']}] ' : ''}${reward['itemName'] ?? reward['category']}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                reward['itemId'] != null
                    ? 'ID: ${reward['itemId']} | Duration: ${reward['amount'] == 0 ? 'Permanent' : '${reward['amount']} Days'}'
                    : 'Amount: ${reward['amount']}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => _rewards.removeAt(idx)),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _handleEventTypeChange(String newType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Reset Layout Blocks?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Changing the template type can initialize default design blocks for the selected template. Do you want to reset current layout blocks?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Current Blocks'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Reset & Preload'),
          ),
        ],
      ),
    );

    setState(() {
      _eventType = newType;
      if (_eventType == 'weekly_star') _rankingType = 'Weekly Star';
      if (_eventType == 'gifter_receiver') _rankingType = 'Top Sender';
      if (_eventType == 'top_room') _rankingType = 'Room Ranking';
      if (_eventType == 'stacked_join') _rankingType = 'Room Ranking';
      if (_eventType == 'recharge') _rankingType = 'Recharge Ranking';
      if (_eventType == 'agency_battle') _rankingType = 'Agency Ranking';

      if (confirm == true) {
        _initializeLayoutBlocksForType(_eventType, force: true);
      }
    });
  }

  Widget _buildPhoneSimulator() {
    Color pageBgColor = const Color(0xFF0F0B21);
    if (_themeConfig.containsKey('backgroundColor') && _themeConfig['backgroundColor'].toString().isNotEmpty) {
      try {
        final hex = _themeConfig['backgroundColor'].toString();
        pageBgColor = Color(int.parse(hex.replaceAll('#', '0xFF')));
      } catch (_) {}
    }

    String? bgImgUrl = _themeConfig['backgroundImageUrl'];

    return Container(
      width: 360,
      height: 640,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.grey[800]!, width: 12),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: pageBgColor,
          child: Stack(
            children: [
              if (_bgImageBytes != null)
                Positioned.fill(
                  child: Image.memory(
                    _bgImageBytes!,
                    fit: BoxFit.cover,
                  ),
                )
              else if (bgImgUrl != null && bgImgUrl.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    bgImgUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const SizedBox(),
                  ),
                ),
              Column(
                children: [
                  Container(
                    height: 24,
                    color: Colors.black.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('11:22', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Icon(Icons.wifi, color: Colors.white, size: 10),
                            SizedBox(width: 4),
                            Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 10),
                            SizedBox(width: 4),
                            Icon(Icons.battery_std, color: Colors.white, size: 10),
                          ],
                        )
                      ],
                    ),
                  ),
                  Container(
                    height: 48,
                    color: Colors.black26,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back_ios, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _nameController.text.isNotEmpty ? _nameController.text : 'Event Name',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.more_vert, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _layoutBlocks.length + 1, // Add 1 for footer mock
                      itemBuilder: (context, index) {
                        if (index == _layoutBlocks.length) {
                          // Preview footer
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.visibility, color: Colors.grey, size: 12),
                                    SizedBox(width: 4),
                                    Text('6,508', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('441 likes', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 6),
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.white10,
                                      child: Icon(Icons.favorite, color: Colors.red[400], size: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                        return _buildSimulatorBlock(_layoutBlocks[index], index);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimulatorBlock(Map<String, dynamic> block, int index) {
    final String type = block['type'] ?? '';
    switch (type) {
      case 'image':
        final String imageUrl = block['imageUrl'] ?? '';
        return Container(
          width: double.infinity,
          color: Colors.grey[900],
          child: block['imageBytes'] != null
              ? Image.memory(block['imageBytes'], fit: BoxFit.fitWidth)
              : imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
                    )
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
        );
      case 'spacer':
        final double height = (block['height'] as num? ?? 20).toDouble() / 2.0;
        final String hexColor = block['color'] ?? '';
        Color color = Colors.transparent;
        if (hexColor.isNotEmpty && hexColor != 'transparent') {
          try {
            color = Color(int.parse(hexColor.replaceAll('#', '0xFF')));
          } catch (_) {}
        }
        return Container(height: height, color: color);
      case 'text':
        final String content = block['content'] ?? '';
        final double fontSize = (block['fontSize'] as num? ?? 14).toDouble() - 2;
        final String hexColor = block['color'] ?? '#ffffff';
        Color color = Colors.white;
        try {
          color = Color(int.parse(hexColor.replaceAll('#', '0xFF')));
        } catch (_) {}
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Text(
            content,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: block['fontWeight'] == 'bold' ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: block['alignment'] == 'center' ? TextAlign.center : TextAlign.left,
          ),
        );
      case 'action_button':
        final String text = block['text'] ?? 'Button';
        final String hexColor = block['buttonColor'] ?? '#2196F3';
        final String textHex = block['textColor'] ?? '#ffffff';
        Color btnColor = Colors.blue;
        Color txtColor = Colors.white;
        try {
          btnColor = Color(int.parse(hexColor.replaceAll('#', '0xFF')));
          txtColor = Color(int.parse(textHex.replaceAll('#', '0xFF')));
        } catch (_) {}
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: btnColor, borderRadius: BorderRadius.circular(16)),
            child: Center(
              child: Text(
                text,
                style: TextStyle(color: txtColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      case 'join_room':
        final String roomId = block['roomId'] ?? '234570756';
        final String btnText = block['buttonText'] ?? 'Click here to enter room $roomId';
        final String hexColor = block['buttonColor'] ?? '#00C853';
        final String textHex = block['textColor'] ?? '#ffffff';
        Color btnColor = Colors.green;
        Color txtColor = Colors.white;
        try {
          btnColor = Color(int.parse(hexColor.replaceAll('#', '0xFF')));
          txtColor = Color(int.parse(textHex.replaceAll('#', '0xFF')));
        } catch (_) {}
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: btnColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                btnText,
                style: TextStyle(color: txtColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      case 'action_row':
        final items = List.from(block['items'] ?? []);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.map<Widget>((item) {
              IconData icon = Icons.info;
              if (item['icon'] == 'history') icon = Icons.history;
              if (item['icon'] == 'description') icon = Icons.description;
              if (item['icon'] == 'emoji_events') icon = Icons.emoji_events;
              if (item['icon'] == 'star') icon = Icons.star;
              if (item['icon'] == 'favorite') icon = Icons.favorite;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white12,
                    child: Icon(icon, color: Colors.amber, size: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(item['label'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 9)),
                ],
              );
            }).toList(),
          ),
        );
      case 'countdown':
        final String c1 = block['color1'] ?? '#8E2DE2';
        final String c2 = block['color2'] ?? '#4A00E0';
        Color col1 = Colors.purple;
        Color col2 = Colors.blue;
        try {
          col1 = Color(int.parse(c1.replaceAll('#', '0xFF')));
          col2 = Color(int.parse(c2.replaceAll('#', '0xFF')));
        } catch (_) {}
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [col1, col2]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer, color: Colors.white, size: 12),
              SizedBox(width: 6),
              Text(
                'Ends in: 2d 12:34:56',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      case 'rewards_showcase':
        final String title = block['title'] ?? 'Event Rewards';
        return Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (i) => Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.card_giftcard, color: Colors.amber, size: 24),
                )),
              )
            ],
          ),
        );
      case 'tabbed_leaderboard':
        final tabs = List.from(block['tabs'] ?? []);
        final accent = block['activeTabColor'] ?? '#FFC107';
        Color accentColor = Colors.amber;
        try {
          accentColor = Color(int.parse(accent.replaceAll('#', '0xFF')));
        } catch (_) {}
        final showPodium = block['showPodium'] ?? true;

        return Column(
          children: [
            if (tabs.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: tabs.asMap().entries.map<Widget>((entry) {
                  final idx = entry.key;
                  final tab = entry.value;
                  final isSelected = idx == 0;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? accentColor : Colors.transparent),
                    ),
                    child: Text(
                      tab['title'] ?? 'Tab',
                      style: TextStyle(color: isSelected ? accentColor : Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            if (showPodium)
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(radius: 12, backgroundColor: Colors.grey[700], child: const Icon(Icons.person, size: 12, color: Colors.grey)),
                        const SizedBox(height: 2),
                        const Text('User 2', style: TextStyle(color: Colors.white, fontSize: 7)),
                        const Text('9,000', style: TextStyle(color: Colors.cyan, fontSize: 7)),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(radius: 16, backgroundColor: Colors.amber[700], child: const Icon(Icons.person, size: 16, color: Colors.white)),
                        const SizedBox(height: 2),
                        const Text('User 1', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                        const Text('12,500', style: TextStyle(color: Colors.cyan, fontSize: 7, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(radius: 12, backgroundColor: Colors.brown[400], child: const Icon(Icons.person, size: 12, color: Colors.white)),
                        const SizedBox(height: 2),
                        const Text('User 3', style: TextStyle(color: Colors.white, fontSize: 7)),
                        const Text('7,800', style: TextStyle(color: Colors.cyan, fontSize: 7)),
                      ],
                    ),
                  ],
                ),
              ),
            Column(
              children: List.generate(3, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    Text('${i + 4}', style: const TextStyle(color: Colors.grey, fontSize: 8)),
                    const SizedBox(width: 8),
                    CircleAvatar(radius: 8, backgroundColor: Colors.grey[800]),
                    const SizedBox(width: 8),
                    Text('User ${i + 4}', style: const TextStyle(color: Colors.white, fontSize: 8)),
                    const Spacer(),
                    const Icon(Icons.diamond, color: Colors.cyan, size: 8),
                    const SizedBox(width: 2),
                    const Text('3,200', style: TextStyle(color: Colors.cyan, fontSize: 8)),
                  ],
                ),
              )),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, bool required = false}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: required ? (v) => v!.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _buildTimeSelector(String label, DateTime time, bool isStart) {
    return GestureDetector(
      onTap: () => _selectDateTime(isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              time.toString().split('.')[0],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemBrowserDialog(StateSetter setModalState, List<Map<String, dynamic>> fetchedItems, List<bool> selectedItems) {
    showDialog(
      context: context,
      builder: (context) {
        List<Map<String, dynamic>> allItems = [];
        List<bool> localSelected = [];
        bool dataLoaded = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Browse All Items', style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: !dataLoaded
                    ? FutureBuilder(
                        future: Future.wait([
                          FirebaseFirestore.instance.collection('market_items').get(),
                          FirebaseFirestore.instance.collection('official_items').get(),
                        ]),
                        builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.blue));
                          }
                          if (!snapshot.hasData) {
                            return const Center(child: Text('No items found', style: TextStyle(color: Colors.grey)));
                          }

                          if (!dataLoaded) {
                            allItems = [
                              ...snapshot.data![0].docs.map((d) => {
                                    'id': d.id,
                                    'collection': 'market_items',
                                    ...d.data() as Map<String, dynamic>,
                                  }),
                              ...snapshot.data![1].docs.map((d) => {
                                    'id': d.id,
                                    'collection': 'official_items',
                                    ...d.data() as Map<String, dynamic>,
                                  }),
                            ];
                            localSelected = List.generate(allItems.length, (index) => false);
                            for (int i = 0; i < allItems.length; i++) {
                              final item = allItems[i];
                              if (fetchedItems.any((f) =>
                                  f['id']?.toString() == item['id']?.toString() ||
                                  f['id']?.toString() == item['displayId']?.toString())) {
                                localSelected[i] = true;
                              }
                            }
                            Future.microtask(() => setDialogState(() => dataLoaded = true));
                            return const Center(child: CircularProgressIndicator(color: Colors.blue));
                          }
                          return const SizedBox();
                        },
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: allItems.length,
                        itemBuilder: (context, index) {
                          final item = allItems[index];
                          final displayId = item['displayId']?.toString() ?? item['id']?.toString() ?? 'N/A';
                          final fileUrl = (item['thumbnailUrl'] ?? item['fileUrl'] ?? '').toString();
                          final isChecked = localSelected[index];

                          return InkWell(
                            onTap: () {
                              setDialogState(() => localSelected[index] = !localSelected[index]);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isChecked ? Colors.blue : Colors.transparent, width: 2),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (fileUrl.isNotEmpty && !fileUrl.endsWith('.svga'))
                                          MediaPreviewWidget(url: fileUrl, width: 40, height: 40)
                                        else
                                          const Icon(Icons.card_giftcard, color: Colors.blue, size: 40),
                                        const SizedBox(height: 8),
                                        Text(
                                          item['name'] ?? 'Unknown',
                                          style: const TextStyle(color: Colors.white, fontSize: 10),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                        Text('ID: $displayId', style: const TextStyle(color: Colors.grey, fontSize: 9)),
                                      ],
                                    ),
                                  ),
                                  if (isChecked)
                                    const Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Icon(Icons.check_circle, color: Colors.blue, size: 20),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () {
                    setModalState(() {
                      for (int i = 0; i < allItems.length; i++) {
                        if (localSelected[i]) {
                          final item = allItems[i];
                          if (!fetchedItems.any((f) =>
                              f['id']?.toString() == item['id']?.toString() ||
                              f['id']?.toString() == item['displayId']?.toString())) {
                            fetchedItems.add({
                              'id': item['displayId'] ?? item['id'],
                              'name': item['name'],
                              'type': item['type'] ?? item['category'],
                              'fileUrl': item['fileUrl'] ?? item['thumbnailUrl'],
                              'collection': item['collection'],
                            });
                            selectedItems.add(true);
                          }
                        }
                      }
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: Colors.grey[850],
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      items: items.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildThemeAndLayoutBuilder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theme & Layout Builder',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('BG Color:', style: TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _bgColorController,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                      onChanged: (v) => setState(() => _themeConfig['backgroundColor'] = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showColorPickerDialog(isBackground: true),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _parseHexColor(_bgColorController.text, defaultColor: const Color(0xFF0F0B21)),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('Accent:', style: TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _accentColorController,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                      onChanged: (v) => setState(() => _themeConfig['accentColor'] = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showColorPickerDialog(isBackground: false),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _parseHexColor(_accentColorController.text, defaultColor: const Color(0xFFFFC107)),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('BG Image:', style: TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _bgImageUrlController,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        hintText: 'https://...',
                      ),
                      onChanged: (v) {
                        setState(() {
                          _themeConfig['backgroundImageUrl'] = v;
                          _bgImageBytes = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _bgImageBytes != null ? Icons.photo : Icons.add_photo_alternate,
                      color: _bgImageBytes != null ? Colors.green : Colors.blue,
                    ),
                    tooltip: 'Upload Background from Gallery',
                    onPressed: _pickBackgroundImage,
                  ),
                ],
              ),
              if (_bgImageBytes != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Background selected: $_bgImageFileName',
                        style: const TextStyle(color: Colors.green, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _bgImageBytes = null;
                          _bgImageFileName = null;
                          _bgImageUrlController.text = '';
                          _themeConfig['backgroundImageUrl'] = '';
                        });
                      },
                      child: const Text('Clear', style: TextStyle(color: Colors.red, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Layout Blocks',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_layoutBlocks.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _layoutBlocks.length,
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                final item = _layoutBlocks.removeAt(oldIndex);
                _layoutBlocks.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final block = _layoutBlocks[index];
              return Card(
                key: ValueKey('block_${block.hashCode}_$index'),
                color: Colors.grey[850],
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.drag_handle, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Block ${index + 1} (${block['type'].toString().toUpperCase()})',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() => _layoutBlocks.removeAt(index)),
                          ),
                        ],
                      ),
                      if (block['type'] == 'image') ...[
                        GestureDetector(
                          onTap: () => _pickImageForBlock(index),
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              border: Border.all(color: Colors.grey[800]!),
                            ),
                            child: block['imageBytes'] != null
                                ? Image.memory(block['imageBytes'], fit: BoxFit.cover)
                                : block['imageUrl'] != null && block['imageUrl'].toString().isNotEmpty
                                    ? MediaPreviewWidget(url: block['imageUrl'], width: double.infinity, height: 120)
                                    : const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add_photo_alternate, color: Colors.grey),
                                            Text('Upload Image', style: TextStyle(color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Clickable Areas:', style: TextStyle(color: Colors.white, fontSize: 12)),
                            TextButton.icon(
                              onPressed: () => _addClickableArea(index),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Area'),
                            ),
                          ],
                        ),
                        if (block['clickableAreas'] != null && (block['clickableAreas'] as List).isNotEmpty)
                          ...(block['clickableAreas'] as List).asMap().entries.map((e) {
                            final area = e.value;
                            return ListTile(
                              dense: true,
                              title: Text(area['action'], style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                'Pos: ${area['x']}%,${area['y']}% Size: ${area['w']}x${area['h']}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, color: Colors.red, size: 16),
                                onPressed: () => setState(() => (block['clickableAreas'] as List).removeAt(e.key)),
                              ),
                            );
                          }),
                      ] else if (block['type'] == 'spacer') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: block['height']?.toString() ?? '20',
                                decoration: const InputDecoration(labelText: 'Height (px)'),
                                style: const TextStyle(color: Colors.white),
                                onChanged: (v) => block['height'] = double.tryParse(v) ?? 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: block['color'] ?? 'transparent',
                                decoration: const InputDecoration(labelText: 'Color (Hex)'),
                                style: const TextStyle(color: Colors.white),
                                onChanged: (v) => block['color'] = v,
                              ),
                            ),
                          ],
                        ),
                      ] else if (block['type'] == 'text') ...[
                        TextFormField(
                          initialValue: block['content'] ?? 'Enter text...',
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Text Content'),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (v) => block['content'] = v,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: block['fontSize']?.toString() ?? '14',
                                decoration: const InputDecoration(labelText: 'Font Size'),
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                onChanged: (v) => block['fontSize'] = double.tryParse(v) ?? 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: block['color'] ?? '#ffffff',
                                decoration: const InputDecoration(labelText: 'Color (Hex)'),
                                style: const TextStyle(color: Colors.white),
                                onChanged: (v) => block['color'] = v,
                              ),
                            ),
                          ],
                        ),
                      ] else if (block['type'] == 'action_button') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: block['text'] ?? 'Join Event',
                                decoration: const InputDecoration(labelText: 'Button Text'),
                                style: const TextStyle(color: Colors.white),
                                onChanged: (v) => block['text'] = v,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: block['action'] ?? 'join_event',
                                dropdownColor: Colors.grey[800],
                                style: const TextStyle(color: Colors.white),
                                items: const [
                                  DropdownMenuItem(value: 'open_registration', child: Text('Open Registration')),
                                  DropdownMenuItem(value: 'join_event', child: Text('Join Event')),
                                  DropdownMenuItem(value: 'share', child: Text('Share Event')),
                                  DropdownMenuItem(value: 'check_in', child: Text('Daily Check-in')),
                                ],
                                onChanged: (v) => setState(() => block['action'] = v!),
                                decoration: const InputDecoration(labelText: 'Action'),
                              ),
                            ),
                          ],
                        ),
                      ] else if (block['type'] == 'join_room') ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: block['roomId'] ?? '',
                                decoration: const InputDecoration(labelText: 'Room / Group ID'),
                                style: const TextStyle(color: Colors.white),
                                onChanged: (v) => setState(() => block['roomId'] = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: block['buttonText'] ?? '',
                                decoration: const InputDecoration(labelText: 'Button Label'),
                                style: const TextStyle(color: Colors.white),
                                onChanged: (v) => setState(() => block['buttonText'] = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: block['buttonColor'] ?? '#00C853',
                                decoration: const InputDecoration(labelText: 'Button Color (Hex)'),
                                style: const TextStyle(color: Colors.white),
                                onChanged: (v) => setState(() => block['buttonColor'] = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: block['textColor'] ?? '#ffffff',
                                decoration: const InputDecoration(labelText: 'Text Color (Hex)'),
                                style: const TextStyle(color: Colors.white),
                                onChanged: (v) => setState(() => block['textColor'] = v),
                              ),
                            ),
                          ],
                        ),
                      ] else if (block['type'] == 'rewards_showcase') ...[
                        TextFormField(
                          initialValue: block['title'] ?? 'Event Rewards',
                          decoration: const InputDecoration(labelText: 'Section Title'),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (v) => block['title'] = v,
                        ),
                      ] else if (block['type'] == 'action_row') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Action Items:', style: TextStyle(color: Colors.white, fontSize: 12)),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  block['items'] = block['items'] ?? [];
                                  (block['items'] as List).add({
                                    'icon': 'description',
                                    'label': 'New Action',
                                    'action': 'open_rules',
                                    'data': '',
                                  });
                                });
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Item'),
                            ),
                          ],
                        ),
                        if (block['items'] != null)
                          ...(block['items'] as List).asMap().entries.map((itemEntry) {
                            final itemIdx = itemEntry.key;
                            final item = itemEntry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: item['label'] ?? '',
                                          decoration: const InputDecoration(labelText: 'Label'),
                                          style: const TextStyle(color: Colors.white),
                                          onChanged: (val) => setState(() => item['label'] = val),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: item['icon'] ?? 'description',
                                          dropdownColor: Colors.grey[900],
                                          style: const TextStyle(color: Colors.white),
                                          items: const [
                                            DropdownMenuItem(value: 'description', child: Text('Rules (Doc)')),
                                            DropdownMenuItem(value: 'history', child: Text('History (Clock)')),
                                            DropdownMenuItem(value: 'emoji_events', child: Text('Events (Trophy)')),
                                            DropdownMenuItem(value: 'star', child: Text('Star')),
                                            DropdownMenuItem(value: 'favorite', child: Text('Heart')),
                                          ],
                                          onChanged: (val) => setState(() => item['icon'] = val),
                                          decoration: const InputDecoration(labelText: 'Icon'),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                        onPressed: () => setState(() => (block['items'] as List).removeAt(itemIdx)),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: item['action'] ?? 'open_rules',
                                          dropdownColor: Colors.grey[900],
                                          style: const TextStyle(color: Colors.white),
                                          items: const [
                                            DropdownMenuItem(value: 'open_rules', child: Text('Open Rules')),
                                            DropdownMenuItem(value: 'open_registration', child: Text('Open Registration')),
                                            DropdownMenuItem(value: 'open_url', child: Text('Open URL')),
                                            DropdownMenuItem(value: 'check_in', child: Text('Daily Check-in')),
                                            DropdownMenuItem(value: 'share', child: Text('Share/Copy ID')),
                                          ],
                                          onChanged: (val) => setState(() => item['action'] = val),
                                          decoration: const InputDecoration(labelText: 'Action'),
                                        ),
                                      ),
                                      if (item['action'] == 'open_url') ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: item['data'] ?? '',
                                            decoration: const InputDecoration(labelText: 'URL'),
                                            style: const TextStyle(color: Colors.white),
                                            onChanged: (val) => setState(() => item['data'] = val),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                      ] else if (block['type'] == 'countdown') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: block['color1'] ?? '#8E2DE2',
                                decoration: const InputDecoration(labelText: 'Color 1 (Hex)'),
                                style: const TextStyle(color: Colors.white),
                                onChanged: (val) => setState(() => block['color1'] = val),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: block['color2'] ?? '#4A00E0',
                                decoration: const InputDecoration(labelText: 'Color 2 (Hex)'),
                                style: const TextStyle(color: Colors.white),
                                onChanged: (val) => setState(() => block['color2'] = val),
                              ),
                            ),
                          ],
                        ),
                      ] else if (block['type'] == 'tabbed_leaderboard') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: block['activeTabColor'] ?? '#FFC107',
                                decoration: const InputDecoration(labelText: 'Active Tab Color (Hex)'),
                                style: const TextStyle(color: Colors.white),
                                onChanged: (val) => setState(() => block['activeTabColor'] = val),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SwitchListTile(
                                title: const Text('Show Podium', style: TextStyle(color: Colors.white, fontSize: 12)),
                                value: block['showPodium'] ?? true,
                                onChanged: (val) => setState(() => block['showPodium'] = val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tabs:', style: TextStyle(color: Colors.white, fontSize: 12)),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  block['tabs'] = block['tabs'] ?? [];
                                  (block['tabs'] as List).add({
                                    'title': 'New Tab',
                                    'rankType': 'receiver',
                                    'limit': 100,
                                  });
                                });
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Tab'),
                            ),
                          ],
                        ),
                        if (block['tabs'] != null)
                          ...(block['tabs'] as List).asMap().entries.map((tabEntry) {
                            final tabIdx = tabEntry.key;
                            final tab = tabEntry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: tab['title'] ?? '',
                                      decoration: const InputDecoration(labelText: 'Title'),
                                      style: const TextStyle(color: Colors.white),
                                      onChanged: (val) => setState(() => tab['title'] = val),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: tab['rankType'] ?? 'receiver',
                                      dropdownColor: Colors.grey[900],
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      items: const [
                                        DropdownMenuItem(value: 'receiver', child: Text('Receivers')),
                                        DropdownMenuItem(value: 'sender', child: Text('Senders')),
                                        DropdownMenuItem(value: 'room', child: Text('Rooms')),
                                        DropdownMenuItem(value: 'active_room', child: Text('Active Rooms')),
                                        DropdownMenuItem(value: 'active_user', child: Text('Active Users')),
                                        DropdownMenuItem(value: 'greedy_game', child: Text('Greedy Game')),
                                        DropdownMenuItem(value: 'fruit_wheel', child: Text('Fruit Wheel')),
                                      ],
                                      onChanged: (val) => setState(() => tab['rankType'] = val),
                                      decoration: const InputDecoration(labelText: 'Source'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      initialValue: tab['limit']?.toString() ?? '100',
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Limit'),
                                      style: const TextStyle(color: Colors.white),
                                      onChanged: (val) => setState(() => tab['limit'] = int.tryParse(val) ?? 100),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                    onPressed: () => setState(() => (block['tabs'] as List).removeAt(tabIdx)),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        Center(
          child: PopupMenuButton<String>(
            onSelected: (v) {
              setState(() {
                if (v == 'image') {
                  _layoutBlocks.add({'type': 'image', 'clickableAreas': []});
                }
                if (v == 'spacer') {
                  _layoutBlocks.add({'type': 'spacer', 'height': 20, 'color': 'transparent'});
                }
                if (v == 'leaderboard') {
                  _layoutBlocks.add({
                    'type': 'tabbed_leaderboard',
                    'activeTabColor': '#FFC107',
                    'inactiveTabColor': '#9E9E9E',
                    'showPodium': true,
                    'tabs': [
                      {'title': 'Charming Star', 'rankType': 'receiver', 'limit': 100},
                    ],
                  });
                }
                if (v == 'action_button') {
                  _layoutBlocks.add({
                    'type': 'action_button',
                    'text': 'Join Event',
                    'action': 'join_event',
                    'buttonColor': '#2196F3',
                    'textColor': '#ffffff',
                  });
                }
                if (v == 'rewards_showcase') {
                  _layoutBlocks.add({'type': 'rewards_showcase', 'title': 'Event Rewards', 'backgroundColor': 'transparent'});
                }
                if (v == 'text') {
                  _layoutBlocks.add({
                    'type': 'text',
                    'content': 'Enter text here...',
                    'fontSize': 14,
                    'color': '#ffffff',
                    'alignment': 'center',
                  });
                }
                if (v == 'action_row') {
                  _layoutBlocks.add({
                    'type': 'action_row',
                    'items': [
                      {'icon': 'description', 'label': 'Rules', 'action': 'open_rules', 'data': ''},
                    ],
                  });
                }
                if (v == 'countdown') {
                  _layoutBlocks.add({
                    'type': 'countdown',
                    'style': 'gradient',
                    'color1': '#8E2DE2',
                    'color2': '#4A00E0',
                    'textColor': '#ffffff',
                  });
                }
                if (v == 'join_room') {
                  _layoutBlocks.add({
                    'type': 'join_room',
                    'roomId': '234570756',
                    'buttonText': 'Click here to enter room 234570756',
                    'buttonColor': '#00C853',
                    'textColor': '#ffffff',
                  });
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Add Block', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'image', child: Text('Image Block')),
              const PopupMenuItem(value: 'action_row', child: Text('Action Row Block')),
              const PopupMenuItem(value: 'countdown', child: Text('Countdown Block')),
              const PopupMenuItem(value: 'leaderboard', child: Text('Tabbed Leaderboard Block')),
              const PopupMenuItem(value: 'rewards_showcase', child: Text('Rewards Showcase')),
              const PopupMenuItem(value: 'text', child: Text('Text Block')),
              const PopupMenuItem(value: 'spacer', child: Text('Spacer Block')),
              const PopupMenuItem(value: 'join_room', child: Text('Join Room Block')),
            ],
          ),
        ),
      ],
    );
  }
}
