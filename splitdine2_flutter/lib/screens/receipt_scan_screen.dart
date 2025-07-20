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

class _ReceiptScanScreenState extends State<ReceiptScanScreen> with WidgetsBindingObserver {
  static const int maxItemNameLength = 30;

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
  bool _cameraInProgress = false;  // Track if camera operation is in progress

  // Track guest choices and shared items
  Map<int, List<int>> _itemAssignments = {}; // itemId -> list of userIds
  final Set<int> _sharedItems = {}; // Set of item IDs that are marked as shared

  @override
  void initState() {
    super.initState();
    print('[DEBUG] ReceiptScanScreen initState called');
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  @override
  void dispose() {
    print('[DEBUG] ReceiptScanScreen dispose called');
    WidgetsBinding.instance.removeObserver(this);
    // Clean up resources
    _selectedImage = null;
    _parsedItems.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[DEBUG] App lifecycle state changed to: $state');
    if (state == AppLifecycleState.resumed) {
      print('[DEBUG] App resumed - checking for pending operations');
      // If we were processing an image when the app was paused, we might need to recover
      if (_isProcessing && _selectedImage == null) {
        print('[DEBUG] Was processing but image is null - resetting state');
        setState(() {
          _isProcessing = false;
          _errorMessage = null;  // Don't show error, just reset state
        });
      }
      
      // Reset camera in progress flag and automatically open gallery if camera was interrupted
      if (_cameraInProgress) {
        print('[DEBUG] Camera operation was interrupted - automatically opening gallery');
        setState(() {
          _cameraInProgress = false;
        });
        
        // Automatically open gallery as fallback
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _pickImage(ImageSource.gallery);
          }
        });
      }
    }
  }

  String _getLoadingMessage() {
    if (_isProcessing && _selectedImage != null) {
      return 'Scanning receipt...';
    } else if (_isLoading) {
      return 'Loading items...';
    }
    return 'Processing...';
  }

  String _getLoadingSubMessage() {
    if (_isProcessing && _selectedImage != null) {
      return 'Extracting text and identifying items';
    } else if (_isLoading) {
      return 'Please wait while we load your data';
    }
    return 'This won\'t take long';
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    await _loadParticipants();
    await _loadExistingItems();
    await _loadAssignments();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Guest Choices',
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
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7A8471)),
                ),
                const SizedBox(height: 16),
                Text(
                  _getLoadingMessage(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getLoadingSubMessage(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
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
                label: const Text(
                  'Scan',
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                      MediaQuery.of(context).padding.top - 
                      kToolbarHeight - 
                      140, // Approximate bottom nav height
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon stack for visual interest
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A8471).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: const Color(0xFF7A8471),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'No receipt items yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get started by scanning your receipt\nor adding items manually',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Start adding your items to make bill splitting easier at the end',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Quick action buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text(
                      'Scan Receipt',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7A8471),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addNewItem,
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Add Item Manually',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7A8471),
                      side: const BorderSide(color: Color(0xFF7A8471)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Tips section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for better results',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Make sure the receipt is well-lit and flat\n'
                    '• Include all items and prices in the photo\n'
                    '• You can edit items after scanning',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      height: 1.3,
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

  Widget _buildSessionReceiptItemCard(SessionReceiptItem item) {
    final itemAssignments = _getItemAssignments(item.id);
    final isShared = _sharedItems.contains(item.id);
    final splitPrice = isShared && itemAssignments.isNotEmpty ? item.price / itemAssignments.length : item.price;
    final isAssigned = itemAssignments.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: isAssigned ? Colors.blue.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAssigned ? Colors.blue.shade200 : Colors.grey.shade300,
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
                      // Item name with shared tag
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showEditItemDialog(item),
                              child: Text(
                                item.itemName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (isShared) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SHARED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Price information - stack vertically for shared items
                      if (isShared) ...[
                        GestureDetector(
                          onTap: () => _showEditItemDialog(item),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '£${item.price.toStringAsFixed(2)} total',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '£${splitPrice.toStringAsFixed(2)} each',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7A8471),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        GestureDetector(
                          onTap: () => _showEditItemDialog(item),
                          child: Text(
                            '£${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7A8471),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Action buttons row
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditItemDialog(item);
                        break;
                      case 'copy':
                        _copyItem(item);
                        break;
                      case 'toggle_type':
                        _toggleItemType(item);
                        break;
                      case 'delete':
                        _deleteItem(item);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.edit, size: 20),
                        title: Text('Edit Item'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'copy',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.copy, size: 20),
                        title: Text('Copy Item'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'toggle_type',
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          isShared ? Icons.person : Icons.group,
                          size: 20,
                          color: isShared ? Colors.grey.shade700 : Colors.orange.shade700,
                        ),
                        title: Text(isShared ? 'Make Individual' : 'Make Shared'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.delete, color: Colors.red, size: 20),
                        title: Text('Delete Item', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
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
    final progress = total > 0 ? allocated / total : 0.0;
    final percentage = (progress * 100).toInt();
    final isComplete = allocated == total && total > 0;
    final isOverspent = allocated > total && total > 0;
    
    // Determine colors and status
    Color statusColor;
    String statusText;
    if (isOverspent) {
      statusColor = Colors.red;
      statusText = 'OVERSPENT';
    } else if (isComplete) {
      statusColor = Colors.green;
      statusText = 'COMPLETE';
    } else {
      statusColor = const Color(0xFF7A8471); // Use sage green instead of orange
      statusText = 'PROGRESS';
    }

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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Total and allocated amounts
              Row(
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
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
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Progress bar
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        '${percentage.clamp(0, 999)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isOverspent 
                      ? '£${(allocated - total).toStringAsFixed(2)} over budget'
                      : isComplete
                        ? 'All items allocated'
                        : '£${(total - allocated).toStringAsFixed(2)} remaining to allocate',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
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
        final isShared = _sharedItems.contains(item.id);
        if (isShared) {
          // For shared items, add the full price once (split between guests)
          total += item.price;
        } else {
          // For individual items, each guest has their own item
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
        await _loadAssignments();
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              IconButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                icon: Icon(
                  Icons.close,
                  color: Colors.red.shade600,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
          if (_shouldShowRetryAction()) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _retryLastAction,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
                const SizedBox(width: 8),
                if (_selectedImage != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _errorMessage = null;
                      });
                    },
                    icon: const Icon(Icons.photo_camera, size: 16),
                    label: const Text('Try Different Image'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _shouldShowRetryAction() {
    return _errorMessage != null && 
           (_errorMessage!.contains('receipt') || 
            _errorMessage!.contains('process') || 
            _errorMessage!.contains('scan') ||
            _errorMessage!.contains('network') ||
            _errorMessage!.contains('failed'));
  }

  void _retryLastAction() {
    setState(() {
      _errorMessage = null;
    });
    
    if (_selectedImage != null) {
      _processReceipt();
    } else {
      _loadExistingItems();
    }
  }







  Future<void> _pickImage([ImageSource? source]) async {
    print('[DEBUG] _pickImage called with source: $source');
    print('[DEBUG] Current state - isProcessing: $_isProcessing, selectedImage: $_selectedImage');
    
    // Prevent multiple simultaneous camera operations
    if (_cameraInProgress) {
      print('[DEBUG] Camera operation already in progress, ignoring request');
      return;
    }
    
    ImageSource? selectedSource;
    
    try {
      selectedSource = source ?? await _showImageSourceDialog();
      print('[DEBUG] Selected source: $selectedSource');

      // Silently redirect to gallery if camera might cause issues
      // This handles low-memory devices gracefully
      if (selectedSource == ImageSource.camera) {
        print('[DEBUG] Camera selected - checking device memory status');
        // For now, we'll use camera as requested but if it fails, we'll suggest gallery
      }

      setState(() {
        _cameraInProgress = true;
      });

      final XFile? image = await _picker.pickImage(
        source: selectedSource,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      print('[DEBUG] Image picker returned: ${image?.path}');

      if (image != null) {
        print('[DEBUG] Image selected, updating state...');
        setState(() {
          _selectedImage = File(image.path);
          _parsedItems.clear();
          _errorMessage = null;
          _cameraInProgress = false;
        });

        // Automatically process the receipt after image selection
        print('[DEBUG] Starting receipt processing...');
        await _processReceipt();
      } else {
        print('[DEBUG] Image picker was cancelled');
        setState(() {
          _cameraInProgress = false;
        });
      }
    } catch (e) {
      print('[ERROR] Failed to pick image: $e');
      print('[ERROR] Stack trace: ${StackTrace.current}');
      setState(() {
        _cameraInProgress = false;
      });
      
      // If camera failed, automatically try gallery
      if (selectedSource == ImageSource.camera && mounted) {
        print('[DEBUG] Camera failed, automatically trying gallery');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Switching to gallery...'),
            duration: Duration(seconds: 1),
          ),
        );
        
        // Small delay before opening gallery
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Try gallery instead
        try {
          final XFile? galleryImage = await _picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );
          
          if (galleryImage != null) {
            setState(() {
              _selectedImage = File(galleryImage.path);
              _parsedItems.clear();
              _errorMessage = null;
            });
            await _processReceipt();
          }
        } catch (galleryError) {
          print('[ERROR] Gallery also failed: $galleryError');
          setState(() {
            _errorMessage = 'Unable to select image. Please try again.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Unable to select image. Please try again.';
        });
      }
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
                subtitle: const Text('Take a new photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    return result ?? ImageSource.gallery;  // Default to gallery if camera issues persist
  }

  Future<void> _processReceipt() async {
    if (_selectedImage == null) {
      print('[DEBUG] _processReceipt called but no image selected');
      return;
    }

    print('[DEBUG] _processReceipt starting with image: ${_selectedImage!.path}');
    print('[DEBUG] Image exists: ${await _selectedImage!.exists()}');
    print('[DEBUG] Image size: ${await _selectedImage!.length()} bytes');

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
        final parsedItems = List<Map<String, dynamic>>.from(
          (data['items'] ?? []).map((item) => {
            'name': item['name'] ?? '',
            'price': (item['price'] as num?)?.toDouble() ?? 0.0,
            'quantity': item['quantity'] ?? 1,
          })
        );

        // Filter out empty items and truncate names
        final validItems = parsedItems
            .where((item) => (item['name'] ?? '').toString().trim().isNotEmpty)
            .map((item) => {
              ...item,
              'name': _truncateItemName((item['name'] ?? '').toString().trim()),
            })
            .toList();

        if (validItems.isEmpty) {
          setState(() {
            _errorMessage = 'No valid items found in receipt';
          });
          return;
        }

        // Automatically add items to session
        try {
          final addResult = await SessionReceiptService.addItemsFromReceipt(
            sessionId: widget.session.id,
            items: validItems,
          );

          if (addResult['success']) {
            if (mounted) {
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added ${validItems.length} items from receipt'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );

              // Clear the selected image and reload the items
              setState(() {
                _selectedImage = null;
                _parsedItems.clear();
              });
              
              // Reload the existing items to show the newly added ones
              await _loadExistingItems();
              await _loadAssignments();
            }
          } else {
            setState(() {
              _errorMessage = addResult['message'] ?? 'Failed to add items to session';
            });
          }
        } catch (e) {
          setState(() {
            _errorMessage = 'Error adding items: $e';
          });
        }
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
    final isShared = _sharedItems.contains(item.id);
    
    // Group participants
    final assignedParticipants = _participants.where((p) => assignedUserIds.contains(p.userId)).toList();
    final unassignedParticipants = _participants.where((p) => !assignedUserIds.contains(p.userId)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        // All participants
        if (_participants.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _participants.map((participant) {
              final isAssigned = assignedUserIds.contains(participant.userId);
              return _buildParticipantChip(participant, isAssigned, item);
            }).toList(),
          ),
        
        // Fallback message when no participants loaded
        if (_participants.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.amber.shade700,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No participants loaded. Check your internet connection or try refreshing.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Info text for shared items
        if (isShared && itemAssignments.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Price will be split equally among ${itemAssignments.length} people',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
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
      selectedColor: const Color(0xFF7A8471),
      backgroundColor: Colors.grey.shade100,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF7A8471) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildAddItemsButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _addItemsToSession,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF7A8471),
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

    // Filter out items with empty names and truncate long names
    final validItems = _parsedItems
        .where((item) => (item['name'] ?? '').toString().trim().isNotEmpty)
        .map((item) => {
          ...item,
          'name': _truncateItemName((item['name'] ?? '').toString().trim()),
        })
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
          await _loadAssignments();
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
        // Update guest choice prices if price changed
        if (price != item.price) {
          await _guestChoiceService.updateItemPrices(
            sessionId: widget.session.id,
            itemId: item.id,
            newPrice: price,
            isShared: _sharedItems.contains(item.id),
          );
        }

        await _loadExistingItems();
        await _loadAssignments();
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
      // First delete all guest choice assignments for this item
      await _guestChoiceService.deleteItemAssignments(
        sessionId: widget.session.id,
        itemId: item.id,
      );

      // Then delete the receipt item itself
      final result = await SessionReceiptService.deleteItem(item.id, widget.session.id);

      if (result['success']) {
        // Remove from local state
        setState(() {
          _itemAssignments.remove(item.id);
          _sharedItems.remove(item.id);
        });

        await _loadExistingItems();
        await _loadAssignments();
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

  // Truncate item name if too long
  String _truncateItemName(String name) {
    if (name.length <= maxItemNameLength) {
      return name;
    }
    return '${name.substring(0, maxItemNameLength - 3)}...';
  }

  // Toggle participant assignment
  Future<void> _toggleParticipantAssignment(SessionReceiptItem item, Participant participant, bool assign) async {
    try {
      if (assign) {
        final isShared = _sharedItems.contains(item.id);
        
        // For individual items, remove all existing assignments first
        if (!isShared) {
          final existingAssignments = _getItemAssignments(item.id);
          for (final existingUserId in existingAssignments) {
            await _guestChoiceService.unassignItem(
              sessionId: widget.session.id,
              itemId: item.id,
              userId: existingUserId,
            );
          }
          
          // Clear local assignments for individual items
          setState(() {
            _itemAssignments[item.id] = [];
          });
        }
        
        // Assign item to participant
        final result = await _guestChoiceService.assignItem(
          sessionId: widget.session.id,
          itemId: item.id,
          userId: participant.userId,
          splitItem: isShared,
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
          itemId: item.id,
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
    final wasShared = _sharedItems.contains(item.id);
    final willBeShared = !wasShared;

    setState(() {
      if (wasShared) {
        _sharedItems.remove(item.id);
      } else {
        _sharedItems.add(item.id);
      }
    });

    // Update shared status in database
    try {
      await _guestChoiceService.updateItemSharedStatus(
        sessionId: widget.session.id,
        itemId: item.id,
        isShared: willBeShared,
        itemPrice: item.price,
      );
    } catch (e) {
      // Revert state change if API call fails
      setState(() {
        if (wasShared) {
          _sharedItems.add(item.id);
        } else {
          _sharedItems.remove(item.id);
        }
      });
    }
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
        await _loadAssignments();
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
        final participantList = result['participants'] as List<Participant>;
        setState(() {
          _participants = participantList;
        });
      }
    } catch (e) {
      // Failed to load participants - continue without them
    }
  }

  // Load existing assignments
  Future<void> _loadAssignments() async {
    try {
      final result = await _guestChoiceService.getSessionAssignments(widget.session.id);

      if (result['success']) {
        final assignments = result['assignments'] as List;

        // Group assignments by item_id and track shared items
        Map<int, List<int>> assignmentsByItemId = {};
        Set<int> sharedItemIds = {};

        for (final assignment in assignments) {
          final itemId = assignment['item_id'] as int?;
          final userId = assignment['user_id'] as int?;
          final isShared = assignment['split_item'] as bool? ?? false;

          // Skip if missing required data
          if (itemId == null || userId == null) continue;

          if (assignmentsByItemId[itemId] == null) {
            assignmentsByItemId[itemId] = [];
          }
          assignmentsByItemId[itemId]!.add(userId);

          // Track shared items
          if (isShared) {
            sharedItemIds.add(itemId);
          }
        }

        setState(() {
          _itemAssignments = assignmentsByItemId;
          _sharedItems.clear();
          _sharedItems.addAll(sharedItemIds);
        });
      }
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
      // Truncate name if too long
      final truncatedName = name.length > 30 ? '${name.substring(0, 27)}...' : name;
      widget.onSave(truncatedName, price);
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
                  backgroundColor: const Color(0xFF7A8471),
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
