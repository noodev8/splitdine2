import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/session.dart';
import '../services/api_service.dart';

class ReceiptScanScreen extends StatefulWidget {
  final Session session;

  const ReceiptScanScreen({
    super.key,
    required this.session,
  });

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  List<Map<String, dynamic>> _parsedItems = [];
  Map<String, dynamic>? _totals;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Scan Receipt',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.black12,
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC629)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Processing receipt...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image selection section
                  _buildImageSection(),
                  
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorMessage(),
                  ],
                  
                  if (_parsedItems.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildParsedItemsSection(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (_selectedImage == null) ...[
            Icon(
              Icons.camera_alt,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Take a photo of your receipt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure the receipt is well-lit and all text is clearly visible',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _selectedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            if (_isProcessing) ...[
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Processing receipt...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  _selectedImage = null;
                  _parsedItems.clear();
                  _totals = null;
                  _errorMessage = null;
                }),
                icon: const Icon(Icons.refresh),
                label: const Text('Retake Photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scanned Items',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'GoogleSansRounded',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review and edit the items below, then add them to your session',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Items list
        ...List.generate(_parsedItems.length, (index) {
          return _buildEditableItemCard(index);
        }),
        
        const SizedBox(height: 16),
        
        // Add item button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addNewItem,
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xFFFFC629)),
              foregroundColor: Colors.black,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Totals section
        if (_totals != null) _buildTotalsSection(),
        
        const SizedBox(height: 24),
        
        // Add to session button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _parsedItems.isNotEmpty ? _addItemsToSession : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: Text(
              'Add ${_parsedItems.length} Items to Session',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableItemCard(int index) {
    final item = _parsedItems[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item['name'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _parsedItems[index]['name'] = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: (item['price'] ?? 0.0).toStringAsFixed(2),
                  decoration: const InputDecoration(
                    labelText: 'Price (£)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _parsedItems[index]['price'] = double.tryParse(value) ?? 0.0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _removeItem(index),
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Receipt Totals',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_totals!['total_amount'] != null)
            _buildTotalRow('Total', _totals!['total_amount']),
          if (_totals!['tax_amount'] != null)
            _buildTotalRow('Tax', _totals!['tax_amount']),
          if (_totals!['service_charge'] != null)
            _buildTotalRow('Service Charge', _totals!['service_charge']),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double? amount) {
    if (amount == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            '£${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _parsedItems.clear();
          _totals = null;
          _errorMessage = null;
        });

        // Automatically process the receipt after image selection
        await _processReceipt();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _processReceipt() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.scanReceipt(
        widget.session.id,
        _selectedImage!,
      );

      if (result['success']) {
        final data = result['data'];
        setState(() {
          _parsedItems = List<Map<String, dynamic>>.from(
            (data['items'] ?? []).map((item) => {
              'name': item['name'] ?? '',
              'price': (item['price'] as num?)?.toDouble() ?? 0.0,
              'quantity': item['quantity'] ?? 1,
            })
          );
          _totals = data['totals'];
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to process receipt';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing receipt: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _addNewItem() {
    setState(() {
      _parsedItems.add({
        'name': '',
        'price': 0.0,
        'quantity': 1,
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      _parsedItems.removeAt(index);
    });
  }

  Future<void> _addItemsToSession() async {
    if (_parsedItems.isEmpty) return;

    // Filter out items with empty names
    final validItems = _parsedItems
        .where((item) => (item['name'] ?? '').toString().trim().isNotEmpty)
        .toList();

    if (validItems.isEmpty) {
      setState(() {
        _errorMessage = 'Please add at least one item with a name';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.addReceiptItems(
        widget.session.id,
        validItems,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully added ${validItems.length} items to session'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Return to session details
        }
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to add items to session';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error adding items: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}
