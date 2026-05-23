import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction; // null = add mode

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'income';
  DateTime _entryDate = DateTime.now();
  File? _attachmentFile;
  String? _existingAttachmentUrl;
  bool _isSaving = false;
  bool _isUploadingAttachment = false;
  final ImagePicker _picker = ImagePicker();

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final tx = widget.transaction!;
      _type = tx.type;
      _nameController.text = tx.name;
      _amountController.text = tx.amount.toStringAsFixed(0);
      _descriptionController.text = tx.description ?? '';
      _entryDate = tx.entryDate;
      _existingAttachmentUrl = tx.attachmentUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _attachmentFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xff1BA3A1)),
              title: const Text('Camera', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
              onTap: () { Navigator.pop(context); _pickAttachment(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xff1BA3A1)),
              title: const Text('Gallery', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
              onTap: () { Navigator.pop(context); _pickAttachment(ImageSource.gallery); },
            ),
            if (_attachmentFile != null || _existingAttachmentUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _attachmentFile = null;
                    _existingAttachmentUrl = null;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadAttachment(File file) async {
    setState(() => _isUploadingAttachment = true);
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/dfcehequr/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'images'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['secure_url'] as String?;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Attachment upload error: $e');
      rethrow;
    } finally {
      if (mounted) setState(() => _isUploadingAttachment = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xff1BA3A1)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _entryDate = DateTime(
          picked.year, picked.month, picked.day,
          _entryDate.hour, _entryDate.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_entryDate),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xff1BA3A1)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _entryDate = DateTime(
          _entryDate.year, _entryDate.month, _entryDate.day,
          picked.hour, picked.minute,
        );
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      String? attachmentUrl = _existingAttachmentUrl;
      if (_attachmentFile != null) {
        attachmentUrl = await _uploadAttachment(_attachmentFile!);
      }

      final month = DateFormat('MMMM').format(_entryDate);
      final year = _entryDate.year.toString();

      final tx = TransactionModel(
        id: widget.transaction?.id,
        type: _type,
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        entryDate: _entryDate,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        attachmentUrl: attachmentUrl,
        month: month,
        year: year,
      );

      final provider = Provider.of<TransactionProvider>(context, listen: false);
      if (_isEditing) {
        await provider.updateTransaction(widget.transaction!.id!, tx);
      } else {
        await provider.addTransaction(tx);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xff817D8A)),
      hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xff817D8A)),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xffF2F2F3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xff1BA3A1), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = _type == 'income';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff1BA3A1),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Transaction' : 'New Transaction',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type toggle
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xffF2F2F3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _type = 'income'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _type == 'income'
                                    ? const Color(0xff1BA3A1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 16,
                                    color: _type == 'income' ? Colors.white : const Color(0xff817D8A),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Income',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _type == 'income' ? Colors.white : const Color(0xff817D8A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _type = 'expense'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _type == 'expense'
                                    ? const Color(0xffF44336)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 16,
                                    color: _type == 'expense' ? Colors.white : const Color(0xff817D8A),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Expense',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _type == 'expense' ? Colors.white : const Color(0xff817D8A),
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
                  const SizedBox(height: 20),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: _fieldDecoration('Name', hint: 'e.g. Electricity bill'),
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Amount field
                  TextFormField(
                    controller: _amountController,
                    decoration: _fieldDecoration('Amount', hint: '0'),
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Amount is required';
                      final parsed = double.tryParse(v.trim());
                      if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Date + Time pickers
                  Row(
                    children: [
                      // Date
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xffF2F2F3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 16, color: Color(0xff1BA3A1)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat('dd MMM yyyy').format(_entryDate),
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xffF2F2F3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 16, color: Color(0xff1BA3A1)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat('hh:mm a').format(_entryDate),
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
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
                  const SizedBox(height: 14),

                  // Description field (optional)
                  TextFormField(
                    controller: _descriptionController,
                    decoration: _fieldDecoration('Description (optional)'),
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 14),

                  // Attachment
                  GestureDetector(
                    onTap: _showAttachmentPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xffF2F2F3),
                        borderRadius: BorderRadius.circular(4),
                        border: (_attachmentFile != null || _existingAttachmentUrl != null)
                            ? Border.all(color: const Color(0xff1BA3A1), width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            (_attachmentFile != null || _existingAttachmentUrl != null)
                                ? Icons.attach_file_rounded
                                : Icons.attach_file_outlined,
                            size: 18,
                            color: (_attachmentFile != null || _existingAttachmentUrl != null)
                                ? const Color(0xff1BA3A1)
                                : const Color(0xff817D8A),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _attachmentFile != null
                                  ? _attachmentFile!.path.split('/').last
                                  : _existingAttachmentUrl != null
                                      ? 'Attachment attached'
                                      : 'Add attachment (optional)',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: (_attachmentFile != null || _existingAttachmentUrl != null)
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : const Color(0xff817D8A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_attachmentFile != null || _existingAttachmentUrl != null)
                            GestureDetector(
                              onTap: () => setState(() {
                                _attachmentFile = null;
                                _existingAttachmentUrl = null;
                              }),
                              child: const Icon(Icons.close, size: 16, color: Color(0xff817D8A)),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Attachment preview
                  if (_attachmentFile != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _attachmentFile!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  if (_existingAttachmentUrl != null && _attachmentFile == null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _existingAttachmentUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 80,
                          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xffF2F2F3),
                          child: const Center(child: Icon(Icons.broken_image_outlined)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isSaving || _isUploadingAttachment) ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isIncome ? const Color(0xff1BA3A1) : const Color(0xffF44336),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        elevation: 0,
                      ),
                      child: (_isSaving || _isUploadingAttachment)
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _isEditing ? 'Update Transaction' : 'Save Transaction',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isSaving || _isUploadingAttachment)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: SizedBox.shrink()),
            ),
        ],
      ),
    );
  }
}
