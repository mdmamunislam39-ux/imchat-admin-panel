import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class FruitWheelGameScreen extends StatefulWidget {
  const FruitWheelGameScreen({super.key});

  @override
  State<FruitWheelGameScreen> createState() => _FruitWheelGameScreenState();
}

class _FruitWheelGameScreenState extends State<FruitWheelGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _thumbnailUrlController = TextEditingController();
  
  double _winRatio = 50.0; // 1 to 100

  final _watermelonWeightController = TextEditingController();
  final _sevensWeightController = TextEditingController();
  final _grapeWeightController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _thumbnailUrlController.dispose();
    _watermelonWeightController.dispose();
    _sevensWeightController.dispose();
    _grapeWeightController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('fruit_wheel')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        
        if (data.containsKey('winRatio')) {
          _winRatio = (data['winRatio'] as num).toDouble();
        } else {
           _winRatio = 50.0;
        }

        _thumbnailUrlController.text = data['thumbnailUrl'] ?? '';
        _watermelonWeightController.text = (data['watermelonWeight'] ?? 1).toString();
        _sevensWeightController.text = (data['sevensWeight'] ?? 1).toString();
        _grapeWeightController.text = (data['grapeWeight'] ?? 1).toString();
      } else {
        // Defaults
        _winRatio = 50.0;
        _watermelonWeightController.text = '1';
        _sevensWeightController.text = '1';
        _grapeWeightController.text = '1';
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

    setState(() {
      _isSaving = true;
    });

    try {
      // Calculate weights from winRatio (1 to 100)
      // winRatio 100 -> highWeight 100 (User wins max)
      // winRatio 1 -> lowWeight 99 (House wins max)
      int highW = _winRatio.round();
      int lowW = 100 - _winRatio.round();
      int mediumW = 50; 

      await FirebaseFirestore.instance
          .collection('config')
          .doc('fruit_wheel')
          .set({
        'winRatio': _winRatio.round(),
        'highWeight': highW,
        'mediumWeight': mediumW,
        'lowWeight': lowW,
        'thumbnailUrl': _thumbnailUrlController.text.trim(),
        'watermelonWeight': int.tryParse(_watermelonWeightController.text) ?? 1,
        'sevensWeight': int.tryParse(_sevensWeightController.text) ?? 1,
        'grapeWeight': int.tryParse(_grapeWeightController.text) ?? 1,
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

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final Uint8List bytes = await image.readAsBytes();
      final String fileName = 'fruit_wheel_thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400]),
          enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey)),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue)),
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a value';
          }
          if (int.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Fruit Wheel Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveConfig,
            tooltip: 'Save Settings',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
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
                              setState(() {});
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
                                  child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                onPressed: _pickAndUploadImage,
                                icon: const Icon(Icons.image, color: Colors.blue),
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
                        color: Colors.blue[300],
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
                                    activeTrackColor: Colors.blue,
                                    inactiveTrackColor: Colors.grey[800],
                                    thumbColor: Colors.blueAccent,
                                    overlayColor: Colors.blue.withValues(alpha: 0.2),
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
                              const Icon(Icons.volume_up, color: Colors.blueAccent),
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
                      'Symbol Probabilities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[300],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Relative base chances of hitting each symbol.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Watermelon Weight', _watermelonWeightController),
                    _buildTextField('Sevens Weight', _sevensWeightController),
                    _buildTextField('Grape (Plum) Weight', _grapeWeightController),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveConfig,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
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
