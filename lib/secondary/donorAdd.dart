import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../assets/custom widgets/donorAddpopup.dart';
import '../assets/custom widgets/logoutpopup.dart';
import 'package:firebase_core/firebase_core.dart'; // Add Firebase Core
import 'package:cloud_firestore/cloud_firestore.dart'; // Add Firestore
import 'dart:ui'; // For blur effect
import 'package:http/http.dart' as http; // For Cloudinary upload
import 'dart:convert'; // For JSON decoding

class DonorAdd extends StatefulWidget {
  final String? donorId;
  final String? initialName;
  final String? initialNumber;
  final String? initialAddress;
  final String? initialAmount;
  final String? initialImageUrl;
  
  const DonorAdd({
    super.key,
    this.donorId,
    this.initialName,
    this.initialNumber,
    this.initialAddress,
    this.initialAmount,
    this.initialImageUrl,
  });

  @override
  State<DonorAdd> createState() => _DonorAddState();
}

class _DonorAddState extends State<DonorAdd> {
  TextEditingController name = TextEditingController();
  TextEditingController number = TextEditingController();
  TextEditingController address = TextEditingController();
  TextEditingController amount = TextEditingController();
  File? _image;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false; // Loading state for blur overlay
  bool get _isEditing => widget.donorId != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (_isEditing) {
      name.text = widget.initialName ?? '';
      number.text = widget.initialNumber ?? '';
      address.text = widget.initialAddress ?? '';
      amount.text = widget.initialAmount ?? '';
      _existingImageUrl = widget.initialImageUrl;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Function to upload image to Cloudinary and return the URL
  Future<String?> _uploadImageToCloudinary(File image) async {
    setState(() => _isLoading = true); // Show loading
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/dfcehequr/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'images' // Replace with your preset
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    } finally {
      setState(() => _isLoading = false); // Hide loading
    }
  }

  // Function to add or update donor data in Firestore
  Future<void> _saveDonor() async {
    setState(() => _isLoading = true);
    try {
      String? imageUrl = _existingImageUrl; // Keep existing image by default
      
      // Only upload new image if one was selected
      if (_image != null) {
        imageUrl = await _uploadImageToCloudinary(_image!);
        if (imageUrl == null) throw Exception('Image upload failed');
      }

      final donorData = {
        'name': name.text,
        'number': number.text,
        'address': address.text,
        'amount': double.parse(amount.text),
        'imageUrl': imageUrl ?? '',
      };

      if (_isEditing) {
        // Update existing donor
        await FirebaseFirestore.instance
            .collection('donors')
            .doc(widget.donorId)
            .update({
          ...donorData,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donor updated successfully')),
        );
      } else {
        // Add new donor
        DocumentReference donorRef = await FirebaseFirestore.instance
            .collection('donors')
            .add({
          ...donorData,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Initialize paymentStatus for current year's months
        final now = DateTime.now();
        final currentYear = now.year;
        final currentMonth = now.month;
        Map<String, String> paymentStatus = {};

        for (int month = 1; month <= currentMonth; month++) {
          final date = DateTime(currentYear, month, 1);
          final monthName = DateFormat('MMMM').format(date);
          paymentStatus['$monthName-$currentYear'] = 'unpaid';
        }

        await donorRef.update({'paymentStatus': paymentStatus});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donor added successfully')),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Failed to update donor: $e' : 'Failed to add donor: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
// Helper to get month name
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
  void _validateAndSubmit(BuildContext context) async {
    if (name.text.isEmpty ||
        number.text.isEmpty ||
        address.text.isEmpty ||
        amount.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields must be filled!')),
      );
    } else {
      await _saveDonor(); // Save to Firebase
      
      if (_isEditing) {
        // Navigate back to donor details after editing
        Navigator.pop(context, true);
      } else {
        showAddedConfirmation(context); // Show confirmation popup
        // Clear fields after submission
        name.clear();
        number.clear();
        address.clear();
        amount.clear();
        setState(() {
          _image = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                elevation: 0,
                backgroundColor: const Color(0xff1BA3A1),
                automaticallyImplyLeading: false,
                expandedHeight: 100,
                flexibleSpace: FlexibleSpaceBar(
                  background: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Image.asset(
                              'lib/assets/images/pmj white.png',
                              height: 50,
                            ),
                          ),
                          // SizedBox(
                          //   height: 26,
                          //   width: 84,
                          //   child: ElevatedButton(
                          //     onPressed: () => showLogoutConfirmation(context),
                          //     style: ElevatedButton.styleFrom(
                          //       foregroundColor: Colors.black,
                          //       backgroundColor: Colors.white,
                          //       shape: RoundedRectangleBorder(
                          //           borderRadius: BorderRadius.circular(2)),
                          //       elevation: 0,
                          //     ),
                          //     child: const Center(
                          //       child: Text(
                          //         'Logout',
                          //         style: TextStyle(
                          //             fontSize: 10,
                          //             fontWeight: FontWeight.w600,
                          //             fontFamily: "Inter"),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ListTile(
                        leading: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: SvgPicture.asset(
                            'lib/assets/images/Back.svg',
                            height: 40,
                            width: 40,
                          ),
                        ),
                        title: Center(
                          child: Text(
                            _isEditing ? 'Edit Donor' : 'Add New Donor',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                        trailing: SvgPicture.asset(
                          'lib/assets/images/settingsnew.svg',
                          height: 40,
                          width: 40,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () => _pickImage(ImageSource.gallery),
                          child: CircleAvatar(
                            radius: 84,
                            backgroundImage: _image != null 
                                ? FileImage(_image!) 
                                : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                                    ? NetworkImage(_existingImageUrl!)
                                    : null,
                            child: (_image == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty))
                                ? SvgPicture.asset('lib/assets/images/Add Image.svg')
                                : null,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Full name',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: name,
                              obscureText: false,
                              keyboardType: TextInputType.name,
                              decoration: const InputDecoration(
                                hintText: 'Enter full name',
                                hintStyle: TextStyle(
                                    fontSize: 12, color: Color(0xffA7A4AD)),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFF1BA3A1), width: 1.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFF1BA3A1), width: 2.0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Mobile Number',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: number,
                              obscureText: false,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Enter mobile number',
                                hintStyle: TextStyle(
                                    fontSize: 12, color: Color(0xffA7A4AD)),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFF1BA3A1), width: 1.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFF1BA3A1), width: 2.0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Address',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              maxLines: 3,
                              controller: address,
                              obscureText: false,
                              keyboardType: TextInputType.name,
                              decoration: const InputDecoration(
                                hintText: 'Enter complete address',
                                hintStyle: TextStyle(
                                    fontSize: 12, color: Color(0xffA7A4AD)),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFF1BA3A1), width: 1.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFF1BA3A1), width: 2.0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Amount',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: amount,
                              obscureText: false,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Enter monthly amount',
                                hintStyle: TextStyle(
                                    fontSize: 12, color: Color(0xffA7A4AD)),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFF1BA3A1), width: 1.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFF1BA3A1), width: 2.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xff1BA3A1),
                              elevation: 0.0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => _validateAndSubmit(context),
                            child: Text(
                              _isEditing ? 'Update Donor' : 'Add Donor',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Full-screen blur and loading overlay
          if (_isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Blur effect
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.3), // Semi-transparent overlay
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}