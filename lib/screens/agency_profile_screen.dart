import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/agency_model.dart';
import '../services/agency_service.dart';
import '../widgets/media_preview_widget.dart';

class AgencyProfileScreen extends StatefulWidget {
  final String agencyId;
  
  const AgencyProfileScreen({
    super.key,
    required this.agencyId,
  });

  @override
  State<AgencyProfileScreen> createState() => _AgencyProfileScreenState();
}

class _AgencyProfileScreenState extends State<AgencyProfileScreen> {
  AgencyModel? _agency;
  bool _isLoading = true;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _agencyNameController = TextEditingController();
  final _agencyIdController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerAddressController = TextEditingController();
  
  String? _logoUrl;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAgencyData();
  }

  @override
  void dispose() {
    _agencyNameController.dispose();
    _agencyIdController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    _ownerAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadAgencyData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final agency = await AgencyService.getAgency(widget.agencyId);
      if (agency != null) {
        _agency = agency;
        _populateForm();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading agency data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateForm() {
    if (_agency != null) {
      _agencyNameController.text = _agency!.agencyName;
      _agencyIdController.text = _agency!.agencyIdNumber;
      _ownerNameController.text = _agency!.owner.name;
      _ownerPhoneController.text = _agency!.owner.phone;
      _ownerEmailController.text = _agency!.owner.email;
      _ownerAddressController.text = _agency!.owner.address ?? '';
      _logoUrl = _agency!.logoUrl;
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
          'Agency Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveProfile,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                    _populateForm(); // Reset form
                  },
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agency Logo Section
            _buildLogoSection(),
            
            const SizedBox(height: 24),
            
            // Agency Information
            _buildSectionTitle('Agency Information'),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _agencyNameController,
              label: 'Agency Name',
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter agency name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _agencyIdController,
              label: 'Agency ID Number',
              enabled: false, // Agency ID should not be editable
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Agency ID is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            
            // Owner Information
            _buildSectionTitle('Owner Information'),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _ownerNameController,
              label: 'Owner Name',
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter owner name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _ownerPhoneController,
              label: 'Phone Number',
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _ownerEmailController,
              label: 'Email Address',
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter email address';
                }
                if (!value.contains('@')) {
                  return 'Please enter valid email address';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _ownerAddressController,
              label: 'Address (Optional)',
              enabled: _isEditing,
              maxLines: 3,
            ),
            
            const SizedBox(height: 32),
            
            // Agency Statistics
            _buildSectionTitle('Agency Statistics'),
            const SizedBox(height: 16),
            
            _buildStatisticsCards(),
            
            const SizedBox(height: 32),
            
            // Agency Status
            _buildSectionTitle('Agency Status'),
            const SizedBox(height: 16),
            
            _buildStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _isEditing ? _pickImage : null,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey[600]!,
                  width: 2,
                ),
                color: Colors.grey[900],
              ),
              child: _selectedImage != null
                  ? ClipOval(
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _logoUrl != null
                      ? MediaPreviewWidget(
                          url: _logoUrl!,
                          width: 120,
                          height: 120,
                          borderRadius: BorderRadius.circular(60),
                        )
                      : const Icon(
                          Icons.business,
                          size: 60,
                          color: Colors.grey,
                        ),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _pickImage,
              child: const Text(
                'Change Logo',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: enabled ? Colors.white : Colors.grey,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        disabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Hosts',
            value: '${_agency?.totalHosts ?? 0}',
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Total Commission',
            value: (_agency?.totalCommissionEarned ?? 0.0).toStringAsFixed(2),
            icon: Icons.monetization_on,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Icon(
            _agency?.isActive == true ? Icons.check_circle : Icons.cancel,
            color: _agency?.isActive == true ? Colors.green : Colors.red,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _agency?.isActive == true ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: _agency?.isActive == true ? Colors.green : Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _agency?.isActive == true 
                      ? 'Agency is currently active and operational'
                      : 'Agency is currently inactive',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // TODO: Upload image to Firebase Storage if _selectedImage is not null
      // For now, we'll keep the existing logo URL
      
      final updatedAgency = _agency!.copyWith(
        agencyName: _agencyNameController.text.trim(),
        owner: _agency!.owner.copyWith(
          name: _ownerNameController.text.trim(),
          phone: _ownerPhoneController.text.trim(),
          email: _ownerEmailController.text.trim(),
          address: _ownerAddressController.text.trim().isEmpty 
              ? null 
              : _ownerAddressController.text.trim(),
        ),
        updatedAt: DateTime.now(),
      );

      final success = await AgencyService.updateAgency(widget.agencyId, updatedAgency);
      
      if (success) {
        // If name changed, sync it to the owner user doc
        if (_agency!.owner.userId != null &&
            _agency!.owner.userId!.isNotEmpty &&
            _agency!.agencyName != _agencyNameController.text.trim()) {
          try {
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(_agency!.owner.userId)
                .update({
              'agencyName': _agencyNameController.text.trim(),
            });
          } catch (e) {
            debugPrint('Error syncing agencyName to User doc: $e');
          }
        }

        setState(() {
          _agency = updatedAgency;
          _isEditing = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
