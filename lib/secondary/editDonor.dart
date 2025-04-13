import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui'; // For blur effect
import 'package:http/http.dart' as http; // For Cloudinary upload
import 'dart:convert';

import '../assets/custom widgets/logoutpopup.dart'; // For JSON decoding

class EditDonor extends StatefulWidget {
  final String donorId;

  const EditDonor({super.key, required this.donorId});

  @override
  State<EditDonor> createState() => _EditDonorState();
}

class _EditDonorState extends State<EditDonor> {
  late TextEditingController name;
  late TextEditingController number;
  late TextEditingController address;
  late TextEditingController amount;
  File? _image;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController();
    number = TextEditingController();
    address = TextEditingController();
    amount = TextEditingController();
    _loadDonorData();
  }

  Future<void> _loadDonorData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('donors')
          .doc(widget.donorId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          name.text = data['name'] ?? '';
          number.text = data['number'] ?? '';
          address.text = data['address'] ?? '';
          amount.text = data['amount']?.toString() ?? '';
          _existingImageUrl = data['imageUrl'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading donor data: $e')),
      );
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

  Future<String?> _uploadImageToCloudinary(File image) async {
    setState(() => _isLoading = true);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateDonor() async {
    setState(() => _isLoading = true);
    try {
      String? imageUrl = _existingImageUrl;
      if (_image != null) {
        imageUrl = await _uploadImageToCloudinary(_image!);
        if (imageUrl == null) throw Exception('Image upload failed');
      }

      await FirebaseFirestore.instance
          .collection('donors')
          .doc(widget.donorId)
          .update({
        'name': name.text,
        'number': number.text,
        'address': address.text,
        'amount': double.parse(amount.text),
        'imageUrl': imageUrl ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donor updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update donor: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
      await _updateDonor();
    }
  }

  @override
  void dispose() {
    name.dispose();
    number.dispose();
    address.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
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
                          SizedBox(
                            height: 26,
                            width: 84,
                            child: ElevatedButton(
                              onPressed: () => showLogoutConfirmation(context),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2)),
                                elevation: 0,
                              ),
                              child: const Center(
                                child: Text(
                                  'Logout',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: "Inter"),
                                ),
                              ),
                            ),
                          ),
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
                          onTap: () => Navigator.pop(context),
                          child: SvgPicture.asset(
                            'lib/assets/images/Back.svg',
                            height: 40,
                            width: 40,
                          ),
                        ),
                        title: const Center(
                          child: Text(
                            'Edit Donor',
                            style: TextStyle(
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
                                : _existingImageUrl != null
                                    ? NetworkImage(_existingImageUrl!)
                                    : null,
                            child: _image == null && _existingImageUrl == null
                                ? SvgPicture.asset(
                                    'lib/assets/images/Add Image.svg')
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
                              decoration: const InputDecoration(
                                hintText: 'Faisal Tk',
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
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '9846338560',
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
                              decoration: const InputDecoration(
                                hintText:
                                    'Khair House, Abc Town, Kerala, 678541',
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
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '5000',
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
                            child: const Text(
                              'Update Donor',
                              style: TextStyle(
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
          if (_isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
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
