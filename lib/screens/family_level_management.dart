import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../models/family_level_model.dart';
import '../services/family_level_service.dart';

class FamilyLevelManagementScreen extends StatefulWidget {
  const FamilyLevelManagementScreen({Key? key}) : super(key: key);

  @override
  State<FamilyLevelManagementScreen> createState() => _FamilyLevelManagementScreenState();
}

class _FamilyLevelManagementScreenState extends State<FamilyLevelManagementScreen> {
  bool _isLoading = false;

  void _showAddEditDialog([FamilyLevelModel? level]) {
    final isEditing = level != null;
    final levelNumberController = TextEditingController(text: level?.levelNumber.toString() ?? '');
    final levelNameController = TextEditingController(text: level?.levelName ?? '');
    final requiredPointsController = TextEditingController(text: level?.requiredPoints.toString() ?? '');
    final bonusAmountController = TextEditingController(text: level?.bonusAmount.toString() ?? '');
    final refreshDaysController = TextEditingController(text: level?.refreshDays.toString() ?? '30');
    
    Uint8List? selectedImageBytes;
    String? selectedImageName;
    String? currentFrameUrl = level?.frameUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              isEditing ? 'Edit Family Level' : 'Add Family Level',
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image picker
                  GestureDetector(
                    onTap: () async {
                      try {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'svga'],
                          withData: true,
                        );

                        if (result != null && result.files.first.bytes != null) {
                          setState(() {
                            selectedImageBytes = result.files.first.bytes;
                            selectedImageName = result.files.first.name;
                          });
                        }
                      } catch (e) {
                        debugPrint('Error picking file: $e');
                      }
                    },
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: selectedImageBytes != null
                          ? (selectedImageName?.toLowerCase().endsWith('svga') == true 
                              ? const Center(child: Text('SVGA Selected', style: TextStyle(color: Colors.white)))
                              : Image.memory(selectedImageBytes!, fit: BoxFit.cover))
                          : (currentFrameUrl != null && currentFrameUrl!.isNotEmpty
                              ? (currentFrameUrl!.toLowerCase().contains('.svga')
                                  ? const Center(child: Text('Current: SVGA', style: TextStyle(color: Colors.white)))
                                  : Image.network(currentFrameUrl!, fit: BoxFit.cover))
                              : const Icon(Icons.add_a_photo, color: Colors.white54, size: 40)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap to upload Frame (PNG/GIF/SVGA)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: levelNumberController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Level Number',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: levelNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Level Name',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: requiredPointsController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Required Points (Flame Points)',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bonusAmountController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Level Up Bonus',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: refreshDaysController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Refresh Period (Days)',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (levelNumberController.text.isEmpty || requiredPointsController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Level number and required points are required')));
                    return;
                  }

                  setState(() => _isLoading = true);
                  
                  final newLevel = FamilyLevelModel(
                    id: level?.id ?? '',
                    levelNumber: int.tryParse(levelNumberController.text) ?? 1,
                    levelName: levelNameController.text,
                    requiredPoints: int.tryParse(requiredPointsController.text) ?? 0,
                    bonusAmount: int.tryParse(bonusAmountController.text) ?? 0,
                    refreshDays: int.tryParse(refreshDaysController.text) ?? 30,
                    frameUrl: currentFrameUrl ?? '',
                    createdAt: level?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  try {
                    if (isEditing) {
                      await FamilyLevelService.updateFamilyLevel(
                        newLevel,
                        imageBytes: selectedImageBytes,
                        imageFileName: selectedImageName,
                      );
                    } else {
                      await FamilyLevelService.addFamilyLevel(
                        newLevel,
                        imageBytes: selectedImageBytes,
                        imageFileName: selectedImageName,
                      );
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Level updated' : 'Level added')));
                    }
                  } catch (e) {
                    debugPrint('Error saving level: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(FamilyLevelModel level) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Level', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete Level ${level.levelNumber}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await FamilyLevelService.deleteFamilyLevel(level.id, level.frameUrl);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Level deleted')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Family Levels Management'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<FamilyLevelModel>>(
        stream: FamilyLevelService.getFamilyLevels(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final levels = snapshot.data ?? [];

          if (levels.isEmpty) {
            return const Center(
              child: Text(
                'No family levels configured.\nClick + to add.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final level = levels[index];
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: level.frameUrl.isNotEmpty
                        ? (level.frameUrl.toLowerCase().contains('.svga')
                            ? const Center(child: Text('SVGA', style: TextStyle(color: Colors.white, fontSize: 10)))
                            : Image.network(level.frameUrl, fit: BoxFit.cover))
                        : const Icon(Icons.image_not_supported, color: Colors.white54),
                  ),
                  title: Text(
                    'Level ${level.levelNumber} - ${level.levelName}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Points: ${level.requiredPoints} | Bonus: ${level.bonusAmount} | Refresh: ${level.refreshDays}d',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddEditDialog(level),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteDialog(level),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
