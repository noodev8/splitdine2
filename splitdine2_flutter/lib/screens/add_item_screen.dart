import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../models/receipt_item.dart';
import '../services/receipt_provider.dart';

class AddItemScreen extends StatefulWidget {
  final Session session;
  final ReceiptItem? editItem;

  const AddItemScreen({
    super.key,
    required this.session,
    this.editItem,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _shareCountController = TextEditingController();

  bool _isLoading = false;
  bool _isShareable = false;
  bool get _isEditing => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _itemNameController.text = widget.editItem!.itemName;
      _priceController.text = widget.editItem!.price.toStringAsFixed(2);
      _quantityController.text = widget.editItem!.quantity.toString();
    } else {
      _quantityController.text = '1'; // Default quantity
      _shareCountController.text = '2'; // Default share count
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _shareCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Very light gray background
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            // Header background that extends down
            Container(
              height: 200,
              decoration: const BoxDecoration(
                color: Color(0xFFFFC629), // Sunshine Yellow
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  // App bar content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF4E4B47), // Warm Gray-700
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _isEditing ? 'Edit Item' : 'Add New Item',
                            style: const TextStyle(
                              fontFamily: 'GoogleSans',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4E4B47), // Warm Gray-700
                              letterSpacing: -0.02,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                  ),

                  // Header Card overlapping the header
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _isEditing ? Icons.edit : Icons.add_shopping_cart,
                          size: 48,
                          color: const Color(0xFFFFC629), // Sunshine Yellow
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isEditing ? 'Edit Item Details' : 'Add New Item',
                          style: const TextStyle(
                            fontFamily: 'GoogleSans',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4E4B47), // Warm Gray-700
                            letterSpacing: -0.02,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32), // Reduced spacing to give more room for content

                  // Form content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24), // Added top padding to prevent clipping
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // Item Name Field
                          TextFormField(
                            controller: _itemNameController,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 18,
                              color: Color(0xFF4E4B47),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Item Name',
                              labelStyle: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 18,
                                color: Color(0xFF4E4B47),
                              ),
                              hintText: 'e.g., Margherita Pizza',
                              hintStyle: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 18,
                                color: const Color(0xFF4E4B47).withValues(alpha: 0.6),
                              ),
                              prefixIcon: const Icon(
                                Icons.restaurant_menu,
                                color: Color(0xFFFFC629), // Sunshine Yellow
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFECE9E6), // Surface color
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFECE9E6), // Surface color
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFFC629), // Sunshine Yellow
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFF04438), // Tomato Red
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter an item name';
                              }
                              if (value.trim().length < 2) {
                                return 'Item name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          // Shareable Feature (smaller, under item name)
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                color: const Color(0xFFFFC629), // Sunshine Yellow
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Shareable Item',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 14,
                                    color: Color(0xFF4E4B47),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: _isShareable,
                                  onChanged: (value) {
                                    setState(() {
                                      _isShareable = value;
                                      if (_isShareable) {
                                        _priceController.text = '0.00';
                                        _quantityController.text = '1';
                                      }
                                    });
                                  },
                                  activeColor: const Color(0xFFFFC629), // Sunshine Yellow
                                  activeTrackColor: const Color(0xFFFFC629).withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                          if (_isShareable) ...[
                            const SizedBox(height: 4),
                            Text(
                              'You\'ll pay a % of the total price',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                color: const Color(0xFF4E4B47).withValues(alpha: 0.7),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Price Field (hidden/disabled when shareable)
                          if (!_isShareable) ...[
                            TextFormField(
                              controller: _priceController,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 18,
                                color: Color(0xFF4E4B47),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Price (£)',
                                labelStyle: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 18,
                                  color: Color(0xFF4E4B47),
                                ),
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 18,
                                  color: const Color(0xFF4E4B47).withValues(alpha: 0.6),
                                ),
                                prefixIcon: const Icon(
                                  Icons.receipt, // More appropriate for UK/receipts
                                  color: Color(0xFFFFC629), // Sunshine Yellow
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFECE9E6), // Surface color
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFECE9E6), // Surface color
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFFC629), // Sunshine Yellow
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF04438), // Tomato Red
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (_isShareable) return null; // Skip validation for shareable items
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a price';
                                }
                                final price = double.tryParse(value.trim());
                                if (price == null) {
                                  return 'Please enter a valid price';
                                }
                                if (price <= 0) {
                                  return 'Price must be greater than 0';
                                }
                                if (price > 9999.99) {
                                  return 'Price cannot exceed £9999.99';
                                }
                                return null;
                              },
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Quantity Field (hidden when shareable)
                          if (!_isShareable) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFECE9E6), // Surface color
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Quantity',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 18,
                                      color: Color(0xFF4E4B47),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          final currentValue = int.tryParse(_quantityController.text) ?? 1;
                                          if (currentValue > 1) {
                                            _quantityController.text = (currentValue - 1).toString();
                                          }
                                        },
                                        icon: const Icon(Icons.remove),
                                        style: IconButton.styleFrom(
                                          backgroundColor: const Color(0xFFECE9E6),
                                          foregroundColor: const Color(0xFF4E4B47),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      SizedBox(
                                        width: 60,
                                        child: TextFormField(
                                          controller: _quantityController,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontFamily: 'Nunito',
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF4E4B47),
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                          ],
                                          validator: (value) {
                                            if (_isShareable) return null; // Skip validation for shareable items
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Required';
                                            }
                                            final quantity = int.tryParse(value.trim());
                                            if (quantity == null) {
                                              return 'Invalid';
                                            }
                                            if (quantity <= 0) {
                                              return 'Must be > 0';
                                            }
                                            if (quantity > 999) {
                                              return 'Too large';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      IconButton(
                                        onPressed: () {
                                          final currentValue = int.tryParse(_quantityController.text) ?? 1;
                                          if (currentValue < 999) {
                                            _quantityController.text = (currentValue + 1).toString();
                                          }
                                        },
                                        icon: const Icon(Icons.add),
                                        style: IconButton.styleFrom(
                                          backgroundColor: const Color(0xFFFFC629), // Sunshine Yellow
                                          foregroundColor: const Color(0xFF4E4B47),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar in same style as My Items screen
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFFC629), // Sunshine Yellow
        unselectedItemColor: const Color(0xFF4E4B47).withValues(alpha: 0.6),
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        elevation: 8,
        currentIndex: _isEditing ? 0 : 0, // Update/Add Item is selected
        onTap: (index) {
          if (_isEditing) {
            switch (index) {
              case 0:
                _saveItem(); // Update the item
                break;
              case 1:
                Navigator.of(context).pop(); // Cancel
                break;
              case 2:
                _removeItem(); // Remove the item
                break;
            }
          } else {
            switch (index) {
              case 0:
                _saveItem(); // Add the item
                break;
              case 1:
                Navigator.of(context).pop(); // Cancel
                break;
            }
          }
        },
        items: _isEditing
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.update),
                  label: 'Update',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.close),
                  label: 'Cancel',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.delete),
                  label: 'Remove',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.add),
                  label: 'Add Item',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.close),
                  label: 'Cancel',
                ),
              ],
      ),
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);

      final itemName = _itemNameController.text.trim();

      // Handle shareable items: use price 0 and quantity 1
      final double price;
      final int quantity;

      if (_isShareable) {
        price = 0.0;
        quantity = 1;
      } else {
        price = double.parse(_priceController.text.trim());
        quantity = int.parse(_quantityController.text.trim());
      }

      bool success = false;
      int? lastItemId;

      if (_isEditing) {
        success = await receiptProvider.updateItem(
          itemId: widget.editItem!.id,
          itemName: itemName,
          price: price,
          quantity: 1, // Always use quantity 1 in database
        );
      } else {
        // Add multiple items with quantity 1 each
        int successCount = 0;
        for (int i = 0; i < quantity; i++) {
          final itemSuccess = await receiptProvider.addItem(
            sessionId: widget.session.id,
            itemName: itemName,
            price: price,
            quantity: 1, // Always use quantity 1 in database
          );

          if (itemSuccess) {
            successCount++;
            // Keep track of the last added item ID for assignment
            if (receiptProvider.items.isNotEmpty) {
              lastItemId = receiptProvider.items.last.id;
            }
          }
        }
        success = successCount == quantity;
      }

      if (mounted) {
        if (success) {
          // Return the last added item ID for assignment purposes
          if (!_isEditing && lastItemId != null) {
            Navigator.of(context).pop(lastItemId);
          } else {
            Navigator.of(context).pop();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(receiptProvider.errorMessage ??
                  (_isEditing ? 'Failed to update item' : 'Failed to add items')),
              backgroundColor: const Color(0xFFF04438), // Tomato Red
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFF04438), // Tomato Red
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeItem() async {
    if (!_isEditing || widget.editItem == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);

      final success = await receiptProvider.deleteItem(widget.editItem!.id);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop('removed'); // Return special value to indicate removal
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(receiptProvider.errorMessage ?? 'Failed to remove item'),
              backgroundColor: const Color(0xFFF04438), // Tomato Red
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFF04438), // Tomato Red
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
