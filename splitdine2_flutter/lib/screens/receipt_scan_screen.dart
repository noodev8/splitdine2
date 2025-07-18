import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/session.dart';
import '../models/session_receipt_item.dart';
import '../models/participant.dart';
import '../services/api_service.dart';
import '../services/session_receipt_service.dart';
import '../services/session_service.dart';
import '../services/guest_choice_service.dart';

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
  final SessionService _sessionService = SessionService();
  final GuestChoiceService _guestChoiceService = GuestChoiceService();

  File? _selectedImage;
  List<Map<String, dynamic>> _parsedItems = [];
  List<SessionReceiptItem> _existingItems = [];
  List<Participant> _participants = [];
  bool _isProcessing = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Track guest choices and shared items
  final Map<int, List<int>> _itemAssignments = {}; // itemId -> list of userIds
  final Set<int> _sharedItems = {}; // Set of item IDs that are marked as shared

  @override
  void initState() {
    super.initState();
    _loadExistingItems();
    _loadParticipants();
    _loadAssignments();
  }

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
      body: _isProcessing || _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6200EE)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Total Card
                if (_existingItems.isNotEmpty) ...[
                  _buildTotalCard(),
                  const SizedBox(height: 8),
                ],



                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(),
                ],

                // Items list
                Expanded(
                  child: _existingItems.isEmpty && _parsedItems.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Existing items
                            ..._existingItems.map((item) => _buildSessionReceiptItemCard(item)),

                            // Parsed items (if any)
                            ..._parsedItems.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return _buildParsedItemCard(item, index);
                            }),

                            // Add items button (if there are parsed items)
                            if (_parsedItems.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildAddItemsButton(),
                            ],
                          ],
                        ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addNewItem,
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Add Item',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                onPressed: _showRescanDialog,
                icon: const Icon(Icons.camera_alt, size: 20),
                label: Text(
                  _existingItems.isEmpty ? 'Scan Receipt' : 'Re-scan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No receipt items yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan a receipt to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionReceiptItemCard(SessionReceiptItem item) {
    final itemAssignments = _getItemAssignments(item.id);
    final isShared = _sharedItems.contains(item.id) || itemAssignments.length > 1;
    final splitPrice = isShared && itemAssignments.isNotEmpty ? item.price / itemAssignments.length : item.price;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with item name, price, and actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.itemName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (isShared) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC629).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SHARED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '£${item.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isShared ? Colors.grey.shade600 : const Color(0xFF6200EE),
                            ),
                          ),
                          if (isShared) ...[
                            Text(
                              ' (£${splitPrice.toStringAsFixed(2)} each)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6200EE),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Copy item button
                    IconButton(
                      onPressed: () => _copyItem(item),
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy Item',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.grey.shade700,
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Edit item button
                    IconButton(
                      onPressed: () => _showEditItemDialog(item),
                      icon: const Icon(Icons.edit, size: 18),
                      tooltip: 'Edit Item',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EE).withValues(alpha: 0.1),
                        foregroundColor: const Color(0xFF6200EE),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Shared toggle button
                    IconButton(
                      onPressed: () => _toggleItemType(item),
                      icon: const Icon(Icons.group, size: 18),
                      tooltip: isShared ? 'Make Individual' : 'Make Shared',
                      style: IconButton.styleFrom(
                        backgroundColor: isShared
                          ? const Color(0xFFFFC629).withValues(alpha: 0.2)
                          : Colors.grey.shade100,
                        foregroundColor: isShared
                          ? const Color(0xFFFFC629)
                          : Colors.grey.shade700,
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Delete item button
                    IconButton(
                      onPressed: () => _deleteItem(item),
                      icon: const Icon(Icons.delete, size: 18),
                      tooltip: 'Delete Item',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Participants section
            _buildParticipantsSection(item),


          ],
        ),
      ),
    );
  }





  Widget _buildTotalCard() {
    final total = _calculateTotal();
    final allocated = _calculateAllocatedTotal();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '£${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6200EE),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ALLOCATED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '£${allocated.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: allocated >= total ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotal() {
    return _existingItems.fold(0.0, (sum, item) {
      return sum + item.price;
    });
  }

  double _calculateAllocatedTotal() {
    double total = 0.0;
    for (final item in _existingItems) {
      final assignments = _getItemAssignments(item.id);
      if (assignments.isNotEmpty) {
        final isShared = _sharedItems.contains(item.id) || assignments.length > 1;
        if (isShared) {
          // For shared items, add the full price once
          total += item.price;
        } else {
          // For individual items, add price for each assignment
          total += item.price * assignments.length;
        }
      }
    }
    return total;
  }

  // Add new item
  void _addNewItem() {
    _showAddItemDialog();
  }

  // Add item to database
  Future<void> _addItemToDatabase(String itemName, double price) async {
    try {
      final result = await SessionReceiptService.addItem(
        sessionId: widget.session.id,
        itemName: itemName,
        price: price,
      );

      if (result['success']) {
        await _loadExistingItems();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add item: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildParsedItemCard(Map<String, dynamic> item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item header with name, price, and menu
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: item['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Item name',
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _parsedItems[index]['name'] = value;
                          });
                        },
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: item['price']?.toString() ?? '0.00',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6200EE),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                          contentPadding: EdgeInsets.zero,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          setState(() {
                            _parsedItems[index]['price'] = double.tryParse(value) ?? 0.0;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Participants list (placeholder for now)
            _buildParticipantsListForParsed(),
          ],
        ),
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







  Future<void> _pickImage([ImageSource? source]) async {
    try {
      ImageSource selectedSource = source ?? await _showImageSourceDialog();

      final XFile? image = await _picker.pickImage(
        source: selectedSource,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _parsedItems.clear();
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

  Future<ImageSource> _showImageSourceDialog() async {
    final result = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    return result ?? ImageSource.camera;
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



  Widget _buildParticipantsSection(SessionReceiptItem item) {
    final itemAssignments = _getItemAssignments(item.id);
    final assignedUserIds = itemAssignments.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _participants.map((participant) {
            final isAssigned = assignedUserIds.contains(participant.userId);
            return _buildParticipantChip(participant, isAssigned, item);
          }).toList(),
        ),
      ],
    );
  }



  Widget _buildParticipantsListForParsed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Will be available after adding to session',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantChip(Participant participant, bool isSelected, SessionReceiptItem item) {
    return FilterChip(
      label: Text(
        participant.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        _toggleParticipantAssignment(item, participant, selected);
      },
      selectedColor: const Color(0xFF6200EE),
      backgroundColor: Colors.grey.shade100,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF6200EE) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildAddItemsButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _addItemsToSession,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6200EE),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Add ${_parsedItems.length} Items to Session',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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
      final result = await SessionReceiptService.addItemsFromReceipt(
        sessionId: widget.session.id,
        items: validItems,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully added ${validItems.length} items to session'),
              backgroundColor: Colors.green,
            ),
          );

          // Clear parsed items and reload existing items
          setState(() {
            _parsedItems.clear();
          });
          await _loadExistingItems();
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to add items to session';
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

  // Show add item dialog
  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => _EditItemDialog(
        item: null, // null indicates this is for adding
        onSave: (newName, newPrice) async {
          await _addItemToDatabase(newName, newPrice);
        },
      ),
    );
  }

  // Show edit dialog for session receipt item
  Future<void> _showEditItemDialog(SessionReceiptItem item) async {
    showDialog(
      context: context,
      builder: (context) => _EditItemDialog(
        item: item,
        onSave: (newName, newPrice) async {
          await _updateItem(item, newName, newPrice);
        },
      ),
    );
  }

  // Update session receipt item
  Future<void> _updateItem(SessionReceiptItem item, String name, double price) async {
    try {
      final result = await SessionReceiptService.updateItem(
        itemId: item.id,
        sessionId: widget.session.id,
        itemName: name,
        price: price,
      );

      if (result['success']) {
        await _loadExistingItems();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update item: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  // Delete session receipt item
  Future<void> _deleteItem(SessionReceiptItem item) async {
    try {
      final result = await SessionReceiptService.deleteItem(item.id, widget.session.id);

      if (result['success']) {
        await _loadExistingItems();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete item: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get item assignments from local state
  List<int> _getItemAssignments(int itemId) {
    return _itemAssignments[itemId] ?? [];
  }

  // Toggle participant assignment
  Future<void> _toggleParticipantAssignment(SessionReceiptItem item, Participant participant, bool assign) async {
    try {
      if (assign) {
        // Assign item to participant
        final result = await _guestChoiceService.assignItem(
          sessionId: widget.session.id,
          itemName: item.itemName,
          price: item.price,
          userId: participant.userId,
          splitItem: _sharedItems.contains(item.id),
        );

        if (result['success']) {
          setState(() {
            _itemAssignments[item.id] = (_itemAssignments[item.id] ?? [])..add(participant.userId);
          });
        }
      } else {
        // Unassign item from participant
        final result = await _guestChoiceService.unassignItem(
          sessionId: widget.session.id,
          itemName: item.itemName,
          userId: participant.userId,
        );

        if (result['success']) {
          setState(() {
            _itemAssignments[item.id]?.remove(participant.userId);
            if (_itemAssignments[item.id]?.isEmpty == true) {
              _itemAssignments.remove(item.id);
            }
          });
        }
      }
    } catch (e) {
      // Handle error silently for now
    }
  }



  // Toggle item type between individual and shared
  Future<void> _toggleItemType(SessionReceiptItem item) async {
    setState(() {
      if (_sharedItems.contains(item.id)) {
        _sharedItems.remove(item.id);
      } else {
        _sharedItems.add(item.id);
      }
    });
  }

  // Copy item
  Future<void> _copyItem(SessionReceiptItem item) async {
    try {
      final result = await SessionReceiptService.addItem(
        sessionId: widget.session.id,
        itemName: '${item.itemName} (Copy)',
        price: item.price,
      );

      if (result['success']) {
        await _loadExistingItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied ${item.itemName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to copy item: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copying item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Load existing session receipt items
  Future<void> _loadExistingItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await SessionReceiptService.getItems(widget.session.id);

      if (result['success']) {
        setState(() {
          _existingItems = result['items'] as List<SessionReceiptItem>;
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load existing items: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load session participants
  Future<void> _loadParticipants() async {
    try {
      final result = await _sessionService.getSessionParticipants(widget.session.id);
      if (result['success']) {
        setState(() {
          _participants = result['participants'] as List<Participant>;
        });
      }
    } catch (e) {
      // Failed to load participants - continue without them
    }
  }

  // Load existing assignments
  Future<void> _loadAssignments() async {
    try {
      // Create a map to group assignments by item name
      Map<String, List<int>> assignmentsByItem = {};

      for (final item in _existingItems) {
        final result = await _guestChoiceService.getItemAssignments(
          sessionId: widget.session.id,
          itemName: item.itemName,
        );

        if (result['success']) {
          final assignments = result['assignments'] as List;
          final userIds = assignments.map((a) => a['user_id'] as int).toList();
          assignmentsByItem[item.itemName] = userIds;
        }
      }

      setState(() {
        _itemAssignments.clear();
        for (final item in _existingItems) {
          final userIds = assignmentsByItem[item.itemName] ?? [];
          if (userIds.isNotEmpty) {
            _itemAssignments[item.id] = userIds;
          }
        }
      });
    } catch (e) {
      // Failed to load assignments - continue without them
    }
  }

  // Show dialog for re-scan options when items already exist
  Future<void> _showRescanDialog() async {
    if (_existingItems.isEmpty) {
      _pickImage();
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Items Already Exist'),
          content: Text(
            'There are already ${_existingItems.length} items in this session. What would you like to do?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('add'),
              child: const Text('Add to Existing'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('replace'),
              child: const Text(
                'Replace All',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (result == 'add') {
      _pickImage();
    } else if (result == 'replace') {
      await _clearExistingItems();
      _pickImage();
    }
  }

  // Clear existing items
  Future<void> _clearExistingItems() async {
    try {
      final result = await SessionReceiptService.clearItems(widget.session.id);
      if (result['success']) {
        setState(() {
          _existingItems.clear();
        });
      }
    } catch (e) {
      // Failed to clear existing items - continue
    }
  }
}

// Edit Item Dialog Widget with Calculator
class _EditItemDialog extends StatefulWidget {
  final SessionReceiptItem? item;
  final Function(String, double) onSave;

  const _EditItemDialog({
    required this.item,
    required this.onSave,
  });

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late TextEditingController _nameController;
  String _displayPrice = '';
  bool _isFirstTap = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.itemName ?? '');
    _displayPrice = widget.item?.price == 0 || widget.item == null
      ? ''
      : widget.item!.price.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onNumberTap(String number) {
    setState(() {
      // Clear display on first tap
      if (_isFirstTap) {
        _displayPrice = '';
        _isFirstTap = false;
      }

      if (number == '.') {
        if (!_displayPrice.contains('.')) {
          _displayPrice = _displayPrice.isEmpty ? '0.' : '$_displayPrice.';
        }
      } else {
        _displayPrice += number;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_displayPrice.isNotEmpty) {
        _displayPrice = _displayPrice.substring(0, _displayPrice.length - 1);
      }
    });
  }

  void _onSave() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_displayPrice) ?? 0.0;

    if (name.isNotEmpty) {
      widget.onSave(name, price);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 350,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            // Close button and title
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item == null ? 'Add Item' : 'Edit Item',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Item name field
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // Price display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Text(
                '£${_displayPrice.isEmpty ? '0.00' : _displayPrice}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6200EE),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            // Number pad
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                _buildNumberButton('1'),
                _buildNumberButton('2'),
                _buildNumberButton('3'),
                _buildNumberButton('4'),
                _buildNumberButton('5'),
                _buildNumberButton('6'),
                _buildNumberButton('7'),
                _buildNumberButton('8'),
                _buildNumberButton('9'),
                _buildNumberButton('.'),
                _buildNumberButton('0'),
                _buildBackspaceButton(),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6200EE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return FilledButton.tonal(
      onPressed: () => _onNumberTap(number),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        number,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return FilledButton.tonal(
      onPressed: _onBackspace,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Icon(
        Icons.backspace_outlined,
        color: Colors.black87,
      ),
    );
  }
}
