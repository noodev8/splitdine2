import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../models/receipt_item.dart';
import '../services/auth_provider.dart';
import '../services/receipt_provider.dart';
import '../services/split_item_service.dart';
import 'split_items_screen.dart';

class MyItemsScreen extends StatefulWidget {
  final Session session;

  const MyItemsScreen({
    super.key,
    required this.session,
  });

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  List<ReceiptItem> _myItems = [];
  List<Map<String, dynamic>> _splitItems = [];
  bool _isLoading = false;
  bool _isAddingItem = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadSplitItems();
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await receiptProvider.loadItems(widget.session.id);

      final currentUserId = authProvider.user?.id ?? 0;
      final allItems = receiptProvider.items;

      // Filter items added by current user
      final userItems = allItems.where((item) => item.addedByUserId == currentUserId).toList();

      // Sort by creation date, latest first
      userItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _myItems = userItems;
      });
    } catch (e) {
      print('Error loading items: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSplitItems() async {
    try {
      final splitItemService = SplitItemService();
      final result = await splitItemService.getUserSplitItems(widget.session.id);

      if (result['success']) {
        setState(() {
          _splitItems = (result['items'] as List).map((item) => {
            'id': item['id'],
            'name': item['name'],
            'price': item['price'], // Full price
            'split_price': item['split_price'], // Split price
            'participant_count': item['participant_count'],
            'description': item['description'],
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading split items: $e');
    }
  }

  void _navigateToSplitItems() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SplitItemsScreen(session: widget.session),
      ),
    ).then((_) {
      // Refresh split items when returning from split items screen
      _loadSplitItems();
    });
  }



  Future<void> _addItem(String itemName) async {
    if (itemName.trim().isEmpty) return;

    setState(() {
      _isAddingItem = true;
    });

    try {
      final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);

      final success = await receiptProvider.addItem(
        sessionId: widget.session.id,
        itemName: itemName.trim(),
        price: 0.0, // Start with zero price
      );

      if (success) {
        _textController.clear();
        await _loadItems(); // Reload to get the new item
      }
    } catch (e) {
      print('Error adding item: $e');
    } finally {
      setState(() {
        _isAddingItem = false;
      });
    }
  }

  void _showEditPriceDialog(ReceiptItem item) {
    showDialog(
      context: context,
      builder: (context) => _EditPriceDialog(
        item: item,
        onSave: (newPrice) async {
          final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
          await receiptProvider.updateItem(
            itemId: item.id,
            itemName: item.itemName,
            price: newPrice,
            share: item.share,
          );
          await _loadItems();
        },
        onDelete: () async {
          final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
          await receiptProvider.deleteItem(item.id);
          await _loadItems();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Combine personal items and split items with unified total
    final personalTotal = _myItems.fold<double>(0.0, (sum, item) => sum + item.price);
    final splitTotal = _splitItems.fold<double>(0.0, (sum, item) => sum + (item['split_price'] ?? 0.0));
    final totalAmount = personalTotal + splitTotal;
    final totalItemCount = _myItems.length + _splitItems.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'My Items',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.black12,
        centerTitle: false,
        actions: [
          // Add Split Item button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonal(
              onPressed: () {
                _navigateToSplitItems();
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_add, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Split',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Total price card
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                  children: [
                    Text(
                      'Your Total',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'GoogleSansRounded',
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '£${totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontFamily: 'GoogleSansRounded',
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (totalItemCount > 0)
                      Text(
                        '${totalItemCount} item${totalItemCount != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Nunito',
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                  ),
                ),
              ),

              // Combined Items list
              Expanded(
                child: totalItemCount == 0
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items yet',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first item below\nor use the Split button for shared items',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _myItems.length + _splitItems.length,
                      itemBuilder: (context, index) {
                        if (index < _myItems.length) {
                          // Personal item
                          final item = _myItems[index];
                          return _buildItemCard(item);
                        } else {
                          // Split item
                          final splitItem = _splitItems[index - _myItems.length];
                          return _buildSplitItemCard(splitItem);
                        }
                      },
                    ),
              ),
            ],
          ),
      // Bottom input field that stays connected to keyboard
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _textFocusNode,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Add food item',
                      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFamily: 'Nunito',
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: 'Nunito',
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _addItem(value);
                      }
                    },
                  ),
                ),
              ),
              if (_isAddingItem)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(ReceiptItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          item.itemName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: Text(
          '£${item.price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: item.price == 0
              ? Colors.grey.shade600
              : Colors.black87,
          ),
        ),
        onTap: () => _showEditPriceDialog(item),
      ),
    );
  }

  Widget _buildSplitItemCard(Map<String, dynamic> splitItem) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          Icons.group,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        title: Text(
          splitItem['name'] ?? '',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '£${(splitItem['split_price'] ?? 0.0).toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4E4B47), // Match guest items color
              ),
            ),
            if ((splitItem['participant_count'] ?? 0) > 1) ...[
              const SizedBox(height: 2),
              Text(
                'Split ${splitItem['participant_count']} ways',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: const Color(0xFF4E4B47).withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          // Navigate to split items screen and scroll to this item
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SplitItemsScreen(
                session: widget.session,
                scrollToItemName: splitItem['name'],
              ),
            ),
          ).then((_) {
            // Refresh split items when returning from split items screen
            _loadSplitItems();
          });
        },
      ),
    );
  }
}

// Edit Price Dialog Widget
class _EditPriceDialog extends StatefulWidget {
  final ReceiptItem item;
  final Function(double) onSave;
  final VoidCallback onDelete;

  const _EditPriceDialog({
    required this.item,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_EditPriceDialog> createState() => _EditPriceDialogState();
}

class _EditPriceDialogState extends State<_EditPriceDialog> {
  String _displayPrice = '';

  @override
  void initState() {
    super.initState();
    _displayPrice = widget.item.price == 0
      ? ''
      : widget.item.price.toStringAsFixed(2);
  }

  void _onNumberTap(String number) {
    setState(() {
      if (number == '.') {
        if (!_displayPrice.contains('.')) {
          _displayPrice = _displayPrice.isEmpty ? '0.' : _displayPrice + '.';
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
    final price = double.tryParse(_displayPrice) ?? 0.0;
    widget.onSave(price);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Item name
            Text(
              widget.item.itemName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'GoogleSansRounded',
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Price display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '£${_displayPrice.isEmpty ? '0.00' : _displayPrice}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'GoogleSansRounded',
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Number pad
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
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

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onDelete();
                  },
                  child: Text(
                    'Remove Item',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return FilledButton.tonal(
      onPressed: () => _onNumberTap(number),
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        number,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return FilledButton.tonal(
      onPressed: _onBackspace,
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Icon(
        Icons.backspace_outlined,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
