import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/session_receipt_service.dart';

class AddNewItemScreen extends StatefulWidget {
  final Session session;

  const AddNewItemScreen({
    super.key,
    required this.session,
  });

  @override
  State<AddNewItemScreen> createState() => _AddNewItemScreenState();
}

class _AddNewItemScreenState extends State<AddNewItemScreen> {
  final TextEditingController _itemNameController = TextEditingController();
  final FocusNode _itemNameFocusNode = FocusNode();
  final List<String> _addedItems = [];
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _itemNameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addItem([String? itemName]) async {
    final name = itemName ?? _itemNameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isAdding = true;
    });

    try {
      // Convert item to the format expected by the API
      final items = [{
        'name': name,
        'price': 0.0,  // Start with 0.00 as specified
      }];

      final result = await SessionReceiptService.addItemsFromReceipt(
        sessionId: widget.session.id,
        items: items,
      );

      if (result['success']) {
        setState(() {
          // Add to top of list (newest first)
          _addedItems.insert(0, name);
          _itemNameController.clear();
          _isAdding = false;
        });
        // Keep focus and keyboard open for rapid entry
        if (mounted) {
          _itemNameFocusNode.requestFocus();
        }
      } else {
        setState(() {
          _isAdding = false;
        });
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
      setState(() {
        _isAdding = false;
      });
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

  void _removeItem(int index) {
    setState(() {
      _addedItems.removeAt(index);
    });
  }

  void _duplicateItem(int index) {
    final itemName = _addedItems[index];
    _addItem(itemName);
  }

  void _onKeyTap(String key) {
    setState(() {
      if (key == 'SPACE') {
        _itemNameController.text += ' ';
      } else if (key == 'BACKSPACE') {
        if (_itemNameController.text.isNotEmpty) {
          _itemNameController.text = _itemNameController.text.substring(
            0, 
            _itemNameController.text.length - 1
          );
        }
      } else {
        _itemNameController.text += key;
      }
    });
  }

  Widget _buildCustomKeyboard() {
    const keys = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
    ];

    return Container(
      color: Colors.grey.shade100,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top 3 letter rows
              ...keys.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Add spacer for middle row to center it
                      if (index == 1) const Spacer(flex: 1),
                      
                      ...row.map((key) => _buildKey(key)),
                      
                      // Add backspace to the right of the last row
                      if (index == 2) 
                        _buildKey('BACKSPACE', flex: 2, icon: Icons.backspace),
                      
                      // Add spacer for middle row to center it
                      if (index == 1) const Spacer(flex: 1),
                    ],
                  ),
                );
              }),
              
              // Bottom row with space, clear, and submit
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKey('CLEAR', flex: 2, label: 'Clear'),
                    _buildKey('SPACE', flex: 4, label: 'Space'),
                    _buildKey('SUBMIT', flex: 2, icon: Icons.arrow_upward, 
                            backgroundColor: Theme.of(context).primaryColor,
                            textColor: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String key, {
    int flex = 1, 
    IconData? icon, 
    String? label,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Material(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(6),
          elevation: 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              if (key == 'CLEAR') {
                setState(() {
                  _itemNameController.clear();
                });
              } else if (key == 'SUBMIT') {
                _addItem();
              } else {
                _onKeyTap(key);
              }
            },
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: icon != null
                  ? Icon(icon, size: 18, color: textColor ?? Colors.grey.shade700)
                  : Text(
                      label ?? key,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor ?? Colors.grey.shade700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _addedItems.isEmpty ? 'Add Items' : 'Add Items (${_addedItems.length})',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.black12,
      ),
      body: Column(
        children: [
          // Loading indicator
          if (_isAdding)
            const LinearProgressIndicator(),
          
          // Items list (newest at top)
          Expanded(
            child: _addedItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items added yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start typing below to add items',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _addedItems.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            _addedItems[index],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: const Text(
                            '£0.00',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Duplicate button
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: () => _duplicateItem(index),
                                tooltip: 'Duplicate',
                                color: Colors.grey.shade600,
                              ),
                              // Delete button
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () => _removeItem(index),
                                tooltip: 'Remove',
                                color: Colors.red.shade400,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Future autocomplete suggestions area
          // This is where "Onion" suggestions will appear when typing "Oni"
          Container(
            // This will be populated with suggestions later
            height: 0, // Hidden for now, will expand when suggestions are available
          ),
          
          // Text display at top
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Text(
                _itemNameController.text.isEmpty 
                    ? 'Start typing'
                    : _itemNameController.text,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: _itemNameController.text.isEmpty
                      ? Colors.grey.shade400
                      : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Custom keyboard
          _buildCustomKeyboard(),
        ],
      ),
    );
  }
}