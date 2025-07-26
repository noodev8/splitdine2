import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../services/session_receipt_service.dart';
import '../services/menu_service.dart';
import '../services/auth_provider.dart';
import '../services/guest_choice_service.dart';
import '../models/session_receipt_item.dart';

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
  final List<Map<String, dynamic>> _addedItems = []; // Store name, price, and itemId
  final MenuService _menuService = MenuService();
  
  bool _isAdding = false;
  List<Map<String, dynamic>> _suggestions = [];
  int? _selectedSuggestionId;
  bool _autoAssignToMe = true; // Toggle for auto-assigning items to current user

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _itemNameFocusNode.requestFocus();
    });
    
    // Listen to text changes for autocomplete
    _itemNameController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _itemNameController.removeListener(_onTextChanged);
    _itemNameController.dispose();
    _itemNameFocusNode.dispose();
    _menuService.dispose();
    super.dispose();
  }
  
  void _onTextChanged() {
    final text = _itemNameController.text;
    
    // Get the current word being typed (word at cursor position)
    final cursorPos = _itemNameController.selection.end;
    final currentWord = _getCurrentWord(text, cursorPos);
    
    // Clear suggestions if no current word or too short (WhatsApp-style)
    if (currentWord.isEmpty || currentWord.length < 2) {
      if (_suggestions.isNotEmpty) {
        setState(() {
          _suggestions = [];
          _selectedSuggestionId = null;
        });
      }
      return;
    }
    
    // Trigger search with debouncing - search only the current word
    _menuService.searchMenuItems(currentWord).then((result) {
      if (mounted) {
        setState(() {
          if (result['success']) {
            _suggestions = List<Map<String, dynamic>>.from(result['suggestions']);
          } else {
            _suggestions = [];
          }
        });
      }
    });
  }

  // Helper function to get the current word being typed (WhatsApp-style)
  String _getCurrentWord(String text, int cursorPos) {
    if (text.isEmpty) return '';
    
    cursorPos = cursorPos.clamp(0, text.length);
    
    // If cursor is at position 0, no current word
    if (cursorPos == 0) return '';
    
    // If character before cursor is a space, we're not inside a word
    if (text[cursorPos - 1] == ' ') {
      return '';
    }
    
    // Find start of current word (go backwards until we hit a space or beginning)
    int start = cursorPos - 1;
    while (start > 0 && text[start - 1] != ' ') {
      start--;
    }
    
    // Current word is from start to cursor position (what's been typed so far)
    String currentWord = text.substring(start, cursorPos);
    return currentWord.trim();
  }

  Future<void> _addItem([String? itemName, String? originalUserInput]) async {
    final name = (itemName ?? _itemNameController.text).trim();
    if (name.isEmpty) return;

    setState(() {
      _isAdding = true;
    });

    try {
      // Convert item to the format expected by the API
      final items = [{
        'name': name,
        'price': 0.0,  // Will be updated when user sets price
      }];

      final result = await SessionReceiptService.addItemsFromReceipt(
        sessionId: widget.session.id,
        items: items,
      );

      if (result['success']) {
        // Always log the search to track what items users are adding
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.user != null) {
          // Use original user input if provided (for suggestion selections), 
          // otherwise use the current text field or item name
          final userInput = originalUserInput ?? (itemName ?? _itemNameController.text.trim());
          MenuService.logSearch(
            userInput: userInput,
            matchedMenuItemId: _selectedSuggestionId, // null if no match
            guestId: authProvider.user!.id,
          );
        }
        
        // Get the item ID from the result for later price updates  
        final itemId = result['items']?.isNotEmpty == true 
            ? result['items'][0].id 
            : null;
        
        setState(() {
          // Add to top of list (newest first) with name, price, and itemId
          _addedItems.insert(0, {
            'name': name,
            'price': 0.0,
            'itemId': itemId,
          });
          _itemNameController.clear();
          _isAdding = false;
          _suggestions = [];
          _selectedSuggestionId = null;
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
  
  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final text = _itemNameController.text;
    final cursorPos = _itemNameController.selection.end.clamp(0, text.length);
    
    // Find current word boundaries
    int start = cursorPos;
    int end = cursorPos;
    
    // Move start backwards to find word start
    while (start > 0 && text[start - 1] != ' ') {
      start--;
    }
    
    // Move end forwards to find word end
    while (end < text.length && text[end] != ' ') {
      end++;
    }
    
    // Replace current word with suggestion and add space
    final suggestionName = suggestion['name'] as String;
    final newText = text.substring(0, start) + 
                   suggestionName + ' ' +
                   text.substring(end);
    
    setState(() {
      _itemNameController.text = newText;
      // Position cursor after the inserted word and space
      _itemNameController.selection = TextSelection.collapsed(
        offset: start + suggestionName.length + 1,
      );
      _selectedSuggestionId = suggestion['id'];
      _suggestions = [];
    });
  }
  

  void _removeItem(int index) {
    setState(() {
      _addedItems.removeAt(index);
    });
  }

  // Auto-assign all unassigned items to current user
  Future<void> _autoAssignItemsToMe() async {
    if (!_autoAssignToMe) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;
    
    final guestChoiceService = GuestChoiceService();
    
    for (final item in _addedItems) {
      if (item['itemId'] != null) {
        try {
          await guestChoiceService.assignItem(
            sessionId: widget.session.id,
            itemId: item['itemId'],
            userId: authProvider.user!.id,
            splitItem: false,
          );
        } catch (e) {
          // Handle error silently for now - items can be assigned manually later
          print('Failed to auto-assign item ${item['name']}: $e');
        }
      }
    }
  }

  void _duplicateItem(int index) {
    final item = _addedItems[index];
    _addItem(item['name']); // This will create a new database entry
  }

  void _showEditItemDialog(int index) {
    final item = _addedItems[index];
    showDialog(
      context: context,
      builder: (context) => _EditItemDialog(
        itemName: item['name'],
        initialPrice: item['price'],
        onSave: (newName, newPrice) async {
          // Update in database if we have an itemId
          if (item['itemId'] != null) {
            try {
              await SessionReceiptService.updateItem(
                itemId: item['itemId'],
                sessionId: widget.session.id,
                itemName: newName,
                price: newPrice,
              );
            } catch (e) {
              // Handle error silently for now
              print('Failed to update item in database: $e');
            }
          }
          
          // Update local state
          setState(() {
            _addedItems[index] = {
              'name': newName,
              'price': newPrice,
              'itemId': item['itemId'],
            };
          });
        },
      ),
    );
  }

  // Get the current word being typed for display
  String _getCurrentTypedWord() {
    final text = _itemNameController.text;
    final cursorPos = _itemNameController.selection.end;
    final currentWord = _getCurrentWord(text, cursorPos);
    return currentWord.isEmpty ? '' : currentWord;
  }

  // Get suggestion at index (null-safe)
  String _getSuggestion(int index) {
    if (_suggestions.length > index) {
      return _suggestions[index]['name'] ?? '';
    }
    return '';
  }

  // Build a suggestion chip widget
  Widget _buildSuggestionChip(String text, bool isCurrentWord) {
    if (text.isEmpty) {
      return Container(
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
      );
    }

    return GestureDetector(
      onTap: isCurrentWord ? null : () => _selectSuggestionByText(text),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isCurrentWord ? Colors.grey.shade100 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentWord ? Colors.grey.shade300 : Colors.blue.shade200,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isCurrentWord ? Colors.grey.shade700 : Colors.blue.shade700,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // Select suggestion by text
  void _selectSuggestionByText(String suggestionText) {
    final suggestion = _suggestions.firstWhere(
      (s) => s['name'] == suggestionText,
      orElse: () => {},
    );
    if (suggestion.isNotEmpty) {
      _selectSuggestion(suggestion);
    }
  }

  void _onKeyTap(String key) {
    final currentText = _itemNameController.text;
    final currentSelection = _itemNameController.selection;
    
    setState(() {
      if (key == 'SPACE') {
        _itemNameController.text += ' ';
        _itemNameController.selection = TextSelection.collapsed(
          offset: _itemNameController.text.length,
        );
      } else if (key == 'BACKSPACE') {
        if (currentText.isNotEmpty) {
          _itemNameController.text = currentText.substring(0, currentText.length - 1);
          _itemNameController.selection = TextSelection.collapsed(
            offset: _itemNameController.text.length,
          );
        }
      } else {
        _itemNameController.text += key;
        _itemNameController.selection = TextSelection.collapsed(
          offset: _itemNameController.text.length,
        );
      }
    });
    
    // Trigger the word-based search after updating text
    _onTextChanged();
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
        child: _AnimatedKey(
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
          backgroundColor: backgroundColor ?? Colors.white,
          textColor: textColor ?? Colors.grey.shade700,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) async {
        if (didPop) {
          // Auto-assign items before leaving if toggle is on
          await _autoAssignItemsToMe();
        }
      },
      child: Scaffold(
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
          actions: [
            // Auto-assign toggle
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _autoAssignToMe ? Icons.person : Icons.people,
                    size: 18,
                    color: _autoAssignToMe ? Colors.green.shade600 : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _autoAssignToMe = !_autoAssignToMe;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _autoAssignToMe ? Colors.green.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _autoAssignToMe ? Colors.green.shade300 : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        _autoAssignToMe ? 'Assign to me' : 'Unassigned',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _autoAssignToMe ? Colors.green.shade700 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                          onTap: () => _showEditItemDialog(index),
                          title: Text(
                            _addedItems[index]['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '£${_addedItems[index]['price'].toStringAsFixed(2)}',
                            style: TextStyle(
                              color: _addedItems[index]['price'] > 0 ? Colors.green.shade600 : Colors.grey,
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
          
          // WhatsApp-style persistent suggestion bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Current word being typed (left slot)
                Expanded(
                  child: _buildSuggestionChip(_getCurrentTypedWord(), true),
                ),
                const SizedBox(width: 8),
                // First suggestion (middle slot)
                Expanded(
                  child: _buildSuggestionChip(_getSuggestion(0), false),
                ),
                const SizedBox(width: 8),
                // Second suggestion (right slot)
                Expanded(
                  child: _buildSuggestionChip(_getSuggestion(1), false),
                ),
              ],
            ),
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
    ),
    );
  }
}

// Animated Key Widget for smooth press animations
class _AnimatedKey extends StatefulWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final Widget child;

  const _AnimatedKey({
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    required this.child,
  });

  @override
  State<_AnimatedKey> createState() => _AnimatedKeyState();
}

class _AnimatedKeyState extends State<_AnimatedKey>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        height: 40,
        transform: Matrix4.identity()
          ..scale(_isPressed ? 0.95 : 1.0), // Subtle scale animation
        decoration: BoxDecoration(
          color: _isPressed 
              ? widget.backgroundColor.withValues(alpha: 0.8) // Slightly dimmed when pressed
              : widget.backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _isPressed 
                ? Colors.blue.shade200 // Subtle border highlight when pressed
                : Colors.grey.shade200,
            width: _isPressed ? 1.5 : 1,
          ),
          boxShadow: _isPressed
              ? [] // Remove shadow when pressed (pressed effect)
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}

// Edit Item Dialog Widget with Calculator
class _EditItemDialog extends StatefulWidget {
  final String itemName;
  final double initialPrice;
  final Function(String, double) onSave;

  const _EditItemDialog({
    required this.itemName,
    required this.initialPrice,
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
    _nameController = TextEditingController(text: widget.itemName);
    _displayPrice = widget.initialPrice > 0 
        ? widget.initialPrice.toStringAsFixed(2) 
        : '';
    _isFirstTap = widget.initialPrice == 0; // Only clear on first tap if price is 0
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
            Stack(
              children: [
                // Centered title
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Edit Item',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Close button positioned on the right
                Positioned(
                  right: 0,
                  top: -8, // Adjust vertical alignment
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
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
                _buildNumberButton('0'),
                _buildNumberButton('.'),
                _buildBackspaceButton(),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  overlayColor: Colors.black.withValues(alpha: 0.05),
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