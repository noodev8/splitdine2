import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitdine2_flutter/models/session.dart';
import 'package:splitdine2_flutter/services/split_item_provider.dart';

class AddSplitItemScreen extends StatefulWidget {
  final Session session;

  const AddSplitItemScreen({
    super.key,
    required this.session,
  });

  @override
  State<AddSplitItemScreen> createState() => _AddSplitItemScreenState();
}

class _AddSplitItemScreenState extends State<AddSplitItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;

  // Custom theme colors for this screen only
  static const Color primaryColor = Color(0xFFFFC629); // Sunshine Yellow
  static const Color secondaryColor = Color(0xFFF04438); // Tomato Red
  static const Color backgroundColor = Color(0xFFFFFFFF); // White
  static const Color surfaceColor = Color(0xFFECE9E6); // Light Gray
  static const Color onSurfaceColor = Color(0xFF4E4B47); // Dark Gray

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addSplitItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    print('=== ADD SPLIT ITEM DEBUG ===');
    print('Session ID: ${widget.session.id}');
    print('Item Name: ${_nameController.text.trim()}');
    print('Price: ${_priceController.text}');
    print('Description: ${_descriptionController.text.trim()}');
    print('============================');

    setState(() {
      _isLoading = true;
    });

    try {
      final splitItemProvider = Provider.of<SplitItemProvider>(context, listen: false);

      final success = await splitItemProvider.addItem(
        sessionId: widget.session.id,
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Split item added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(splitItemProvider.errorMessage ?? 'Failed to add split item'),
              backgroundColor: secondaryColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: secondaryColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: surfaceColor,
          onSurface: onSurfaceColor,
        ),
        textTheme: Theme.of(context).textTheme.copyWith(
          headlineLarge: const TextStyle(
            fontWeight: FontWeight.bold,
            color: onSurfaceColor,
          ),
          headlineMedium: const TextStyle(
            fontWeight: FontWeight.bold,
            color: onSurfaceColor,
          ),
          headlineSmall: const TextStyle(
            fontWeight: FontWeight.bold,
            color: onSurfaceColor,
          ),
          bodyLarge: const TextStyle(
            fontSize: 24,
            color: onSurfaceColor,
          ),
          bodyMedium: const TextStyle(
            fontSize: 16,
            color: onSurfaceColor,
          ),
          bodySmall: const TextStyle(
            fontSize: 14,
            color: onSurfaceColor,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            'Add Split Item',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Create New Split Item',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add an item that will be split equally between participants.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Item Name Field
                Text(
                  'Item Name',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'e.g., Shared Appetizer, Bottle of Wine',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: surfaceColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an item name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Price Field
                Text(
                  'Total Price (£)',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: surfaceColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a price';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Description Field (Optional)
                Text(
                  'Description (Optional)',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Add any additional details...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: surfaceColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 32),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'After creating the item, you can assign participants by tapping on it in the list.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: onSurfaceColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addSplitItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Text(
                            'Add Item',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
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
}
