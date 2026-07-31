import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class PinkGreedyGameScreen extends StatefulWidget {
  const PinkGreedyGameScreen({super.key});

  @override
  State<PinkGreedyGameScreen> createState() => _PinkGreedyGameScreenState();
}

class _PinkGreedyGameScreenState extends State<PinkGreedyGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _thumbnailUrlController = TextEditingController();
  
  double _winRatio = 50.0; // 1 to 100

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  bool _isCustomScheduled = false;
  String _customItem = 'Pizza';
  DateTime? _scheduledTime;

  final List<String> _items = ['Pizza', 'Salad', 'Beef Steak'];

  @override
  void dispose() {
    _thumbnailUrlController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('pink_greedy_game')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        
        if (data.containsKey('winRatio')) {
          _winRatio = (data['winRatio'] as num).toDouble();
        } else {
           _winRatio = 50.0;
        }

        _isCustomScheduled = data['isCustomScheduled'] ?? false;
        _customItem = data['customItem'] ?? 'Pizza';
        _thumbnailUrlController.text = data['thumbnailUrl'] ?? '';
        if (data['scheduledTime'] != null) {
          _scheduledTime = (data['scheduledTime'] as Timestamp).toDate();
        }
      } else {
        // Defaults
        _winRatio = 50.0;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading config: $e')),
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

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isCustomScheduled && _scheduledTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a scheduled time')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      int highW = _winRatio.round();
      int lowW = 100 - _winRatio.round();
      int mediumW = 50; 

      await FirebaseFirestore.instance
          .collection('config')
          .doc('pink_greedy_game')
          .set({
        'winRatio': _winRatio.round(),
        'highWeight': highW,
        'mediumWeight': mediumW,
        'lowWeight': lowW,
        'isCustomScheduled': _isCustomScheduled,
        'customItem': _customItem,
        'thumbnailUrl': _thumbnailUrlController.text.trim(),
        'scheduledTime': _scheduledTime != null ? Timestamp.fromDate(_scheduledTime!) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving config: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledTime ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final Uint8List bytes = await image.readAsBytes();
      final String fileName = 'pink_greedy_game_thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child('game_thumbnails/$fileName');

      final UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _thumbnailUrlController.text = downloadUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
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
        title: const Text('Pink Greedy Game Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveConfig,
            tooltip: 'Save Settings',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _thumbnailUrlController,
                            style: const TextStyle(color: Colors.white),
                            onChanged: (val) {
                              setState(() {}); // To update preview
                            },
                            decoration: InputDecoration(
                              labelText: 'Game Thumbnail URL (Optional)',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                              hintText: 'Leave empty to use default emoji',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _isUploadingImage
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.pink, strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                onPressed: _pickAndUploadImage,
                                icon: const Icon(Icons.image, color: Colors.pink),
                                tooltip: 'Upload from Gallery',
                              ),
                      ],
                    ),
                    if (_thumbnailUrlController.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(_thumbnailUrlController.text),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Winning Ratio (Users Win Chance)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink[300],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Adjust the overall win ratio from 1% to 100%. Higher percentage means users win more. Lower means house profits more.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    
                    // Volume Slider
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.volume_down, color: Colors.grey),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.pink,
                                    inactiveTrackColor: Colors.grey[800],
                                    thumbColor: Colors.pinkAccent,
                                    overlayColor: Colors.pink.withValues(alpha: 0.2),
                                    valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                                  ),
                                  child: Slider(
                                    value: _winRatio,
                                    min: 1,
                                    max: 100,
                                    divisions: 99,
                                    label: '${_winRatio.round()}%',
                                    onChanged: (value) {
                                      setState(() {
                                        _winRatio = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const Icon(Icons.volume_up, color: Colors.pinkAccent),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_winRatio.round()}%',
                            style: TextStyle(
                              color: _winRatio > 50 ? Colors.greenAccent : (_winRatio < 50 ? Colors.redAccent : Colors.white),
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.grey, height: 48),

                    Text(
                      'Custom Scheduled Win Item',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink[300],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Schedule a specific item to win at an exact time, overriding the automatic system.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            title: const Text('Enable Scheduled Win', style: TextStyle(color: Colors.white)),
                            value: _isCustomScheduled,
                            onChanged: (value) {
                              setState(() {
                                _isCustomScheduled = value;
                              });
                            },
                            activeThumbColor: Colors.pink,
                          ),
                          
                          if (_isCustomScheduled) ...[
                            const SizedBox(height: 16),
                            const Text('Select Item:', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _customItem,
                              dropdownColor: Colors.grey[850],
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[700]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.pink),
                                ),
                              ),
                              items: _items.map((String item) {
                                return DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _customItem = newValue;
                                  });
                                }
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            const Text('Select Time:', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _pickDateTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[700]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _scheduledTime != null
                                          ? DateFormat('MMM dd, yyyy - hh:mm a').format(_scheduledTime!)
                                          : 'Tap to select date & time',
                                      style: TextStyle(
                                        color: _scheduledTime != null ? Colors.white : Colors.grey,
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today, color: Colors.pink),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveConfig,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Save Configuration',
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
}
