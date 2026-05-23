import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/donor_profile_provider.dart';
import '../providers/donor_auth_provider.dart';
import '../widgets/donor_shimmer_widgets.dart';
import '../widgets/donor_app_bar.dart';
import '../widgets/donor_sub_header.dart';

/// Screen for viewing and editing donor profile information
class DonorProfileScreen extends StatefulWidget {
  const DonorProfileScreen({super.key});

  @override
  State<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends State<DonorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _contactController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<DonorAuthProvider>(context, listen: false);
    final profileProvider = Provider.of<DonorProfileProvider>(context, listen: false);
    
    if (authProvider.donorUser?.donorId != null) {
      await profileProvider.loadDonorProfile(authProvider.donorUser!.donorId);
      
      // Initialize controllers with loaded data
      if (profileProvider.donorProfile != null) {
        _nameController.text = profileProvider.donorProfile!.name;
        _addressController.text = profileProvider.donorProfile!.house;
        _contactController.text = profileProvider.donorProfile!.phoneNumber;
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImageToCloudinary(File image) async {
    setState(() => _isUploadingImage = true);
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/dfcehequr/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'images'
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['url'];
      } else {
        throw Exception('Failed to upload image to Cloudinary');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xff1BA3A1)),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xff1BA3A1)),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<DonorAuthProvider>(context, listen: false);
    final profileProvider = Provider.of<DonorProfileProvider>(context, listen: false);

    if (authProvider.donorUser?.donorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update profile. Please try logging in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Upload image if selected
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImageToCloudinary(_selectedImage!);
      if (imageUrl == null) {
        // Upload failed, error already shown
        return;
      }
    }

    final success = await profileProvider.updateDonorProfile(
      donorId: authProvider.donorUser!.donorId,
      address: _addressController.text,
      contactNumber: _contactController.text,
      photoUrl: imageUrl, // Pass the new image URL if uploaded
    );

    if (mounted) {
      if (success) {
        // Clear selected image after successful save
        setState(() => _selectedImage = null);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (profileProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const DonorAppBar(),
      body: Column(
        children: [
          DonorSubHeader(
            title: 'My Profile',
            trailing: Consumer<DonorProfileProvider>(
              builder: (context, provider, child) {
                if (provider.isEditing) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          provider.cancelEditing();
                          // Reset controllers
                          if (provider.donorProfile != null) {
                            _nameController.text = provider.donorProfile!.name;
                            _addressController.text = provider.donorProfile!.house;
                            _contactController.text = provider.donorProfile!.phoneNumber;
                          }
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: provider.isLoading ? null : _saveProfile,
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Color(0xff1BA3A1),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xff1BA3A1)),
                  onPressed: provider.toggleEditMode,
                );
              },
            ),
          ),
          Expanded(
            child: Consumer<DonorProfileProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.donorProfile == null) {
                  return const DonorProfileShimmer();
                }
      
                if (provider.errorMessage != null && provider.donorProfile == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontFamily: "Inter",
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1BA3A1),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.donorProfile == null) {
            return const Center(
              child: Text('No profile data available'),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadProfile,
            color: const Color(0xff1BA3A1),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: provider.isEditing ? _showImageSourceDialog : null,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xff1BA3A1),
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: _selectedImage != null
                                        ? Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.cover,
                                          )
                                        : provider.donorProfile!.photoUrl.isNotEmpty
                                            ? Image.network(
                                                provider.donorProfile!.photoUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: const Color(0xff1BA3A1).withOpacity(0.1),
                                                    child: const Icon(
                                                      Icons.person,
                                                      size: 60,
                                                      color: Color(0xff1BA3A1),
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: const Color(0xff1BA3A1).withOpacity(0.1),
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Color(0xff1BA3A1),
                                                ),
                                              ),
                                  ),
                                ),
                              ),
                              if (provider.isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _showImageSourceDialog,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xff1BA3A1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              if (_isUploadingImage)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.donorProfile!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Inter",
                            ),
                          ),

                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Profile Information
                    const Text(
                      'Profile Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: "Inter",
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Name (Read-only)
                    _buildInfoField(
                      label: 'Full Name',
                      value: provider.donorProfile!.name,
                      icon: Icons.person_outline,
                      isEditable: false,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // House (Read-only)
                    _buildInfoField(
                      label: 'House',
                      value: provider.donorProfile!.house,
                      icon: Icons.home_outlined,
                      isEditable: false,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Address (Editable)
                    provider.isEditing
                        ? _buildEditableField(
                            label: 'Address',
                            controller: _addressController,
                            icon: Icons.location_on_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Address is required';
                              }
                              return null;
                            },
                          )
                        : _buildInfoField(
                            label: 'Address',
                            value: provider.donorProfile!.house,
                            icon: Icons.location_on_outlined,
                            isEditable: true,
                          ),
                    
                    const SizedBox(height: 16),
                    
                    // Contact Number (Editable)
                    provider.isEditing
                        ? _buildEditableField(
                            label: 'Contact Number',
                            controller: _contactController,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Contact number is required';
                              }
                              if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                                return 'Enter a valid 10-digit number';
                              }
                              return null;
                            },
                          )
                        : _buildInfoField(
                            label: 'Contact Number',
                            value: provider.donorProfile!.phoneNumber,
                            icon: Icons.phone_outlined,
                            isEditable: true,
                          ),
                    
                    const SizedBox(height: 16),
                    
                    // Monthly Amount (Read-only)
                    _buildInfoField(
                      label: 'Monthly Contribution',
                      value: '₹${provider.donorProfile!.amount.toStringAsFixed(0)}',
                      icon: Icons.currency_rupee,
                      isEditable: false,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Edit hint
                    if (!provider.isEditing)
                      Center(
                        child: Text(
                          'Tap the edit icon to update your address, contact number, and profile picture',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontFamily: "Inter",
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    )])    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    required bool isEditable,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff1BA3A1), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: "Inter",
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: "Inter",
                  ),
                ),
              ],
            ),
          ),
          if (isEditable)
            Icon(Icons.edit, size: 18, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: "Inter",
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xff1BA3A1)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xff1BA3A1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xff1BA3A1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
