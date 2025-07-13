import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitdine2_flutter/models/session.dart';
import 'package:splitdine2_flutter/models/receipt_item.dart';
import 'package:splitdine2_flutter/models/participant.dart';
import 'package:splitdine2_flutter/services/receipt_provider.dart';
import 'package:splitdine2_flutter/services/session_service.dart';

class SharedItemsScreen extends StatefulWidget {
  final Session session;

  const SharedItemsScreen({
    super.key,
    required this.session,
  });

  @override
  State<SharedItemsScreen> createState() => _SharedItemsScreenState();
}

class _SharedItemsScreenState extends State<SharedItemsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _priceController = TextEditingController();
  
  List<Participant> _participants = [];
  List<Participant> _selectedParticipants = [];
  bool _isLoading = false;
  bool _isAddingItem = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadParticipants();
      _loadItems();
    });
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
    await receiptProvider.loadItems(widget.session.id);
  }

  Future<void> _loadParticipants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sessionService = SessionService();
      final result = await sessionService.getSessionParticipants(widget.session.id);
      
      if (result['success']) {
        setState(() {
          _participants = result['participants'] as List<Participant>;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load participants';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addSharedItem() async {
    if (!_formKey.currentState!.validate() || _selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select at least one participant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isAddingItem = true;
    });

    try {
      final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
      
      // Create share string with participant names
      final shareString = _selectedParticipants.map((p) => p.displayName).join(',');
      
      final success = await receiptProvider.addItem(
        sessionId: widget.session.id,
        itemName: _itemNameController.text.trim(),
        price: double.parse(_priceController.text),
        quantity: 1,
        share: shareString,
      );

      if (success) {
        // Clear form
        _itemNameController.clear();
        _priceController.clear();
        setState(() {
          _selectedParticipants.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shared item added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(receiptProvider.errorMessage ?? 'Failed to add shared item'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isAddingItem = false;
      });
    }
  }

  void _toggleParticipant(Participant participant) {
    setState(() {
      if (_selectedParticipants.contains(participant)) {
        _selectedParticipants.remove(participant);
      } else {
        _selectedParticipants.add(participant);
      }
    });
  }

  void _selectAllParticipants() {
    setState(() {
      if (_selectedParticipants.length == _participants.length) {
        _selectedParticipants.clear();
      } else {
        _selectedParticipants = List.from(_participants);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Shared Items',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadParticipants,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Add Item Form
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Shared Item',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Item Name Field
                            TextFormField(
                              controller: _itemNameController,
                              decoration: InputDecoration(
                                labelText: 'Item Name',
                                labelStyle: theme.textTheme.bodyLarge,
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                              ),
                              style: theme.textTheme.bodyLarge,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter an item name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Price Field
                            TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: 'Price (£)',
                                labelStyle: theme.textTheme.bodyLarge,
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                prefixText: '£',
                              ),
                              style: theme.textTheme.bodyLarge,
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
                            const SizedBox(height: 16),
                            
                            // Participants Selection
                            Text(
                              'Who is sharing this item?',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Select All Button
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _selectAllParticipants,
                                    icon: Icon(
                                      _selectedParticipants.length == _participants.length
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                    ),
                                    label: Text(
                                      _selectedParticipants.length == _participants.length
                                          ? 'Deselect All'
                                          : 'Select All',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
