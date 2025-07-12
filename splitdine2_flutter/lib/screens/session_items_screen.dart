import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../models/receipt_item.dart';
import '../services/receipt_provider.dart';
import '../services/assignment_provider.dart';
import '../services/auth_provider.dart';
import 'add_item_screen.dart';

class SessionItemsScreen extends StatefulWidget {
  final Session session;

  const SessionItemsScreen({
    super.key,
    required this.session,
  });

  @override
  State<SessionItemsScreen> createState() => _SessionItemsScreenState();
}

class _SessionItemsScreenState extends State<SessionItemsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItems();
    });
  }

  Future<void> _loadItems() async {
    final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);

    await Future.wait([
      receiptProvider.loadItems(widget.session.id),
      assignmentProvider.loadSessionAssignments(widget.session.id),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isUpcoming = widget.session.sessionDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));
    final canEdit = isUpcoming;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.session.displayName} - Items'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadItems,
            tooltip: 'Refresh items',
          ),
        ],
      ),
      body: Consumer<ReceiptProvider>(
        builder: (context, receiptProvider, child) {
          if (receiptProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (receiptProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading items',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    receiptProvider.errorMessage!,
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadItems,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final items = receiptProvider.items;

          return Column(
            children: [
              // Summary Card
              Consumer<AssignmentProvider>(
                builder: (context, assignmentProvider, child) {
                  final allocatedAmount = assignmentProvider.getTotalAllocatedAmount(receiptProvider.items);
                  final unallocatedItems = assignmentProvider.getUnallocatedItems(receiptProvider.items);

                  return Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryItem(
                                context,
                                icon: Icons.receipt_long,
                                label: 'Items',
                                value: '${receiptProvider.uniqueItemCount}',
                              ),
                              _buildSummaryItem(
                                context,
                                icon: Icons.shopping_cart,
                                label: 'Quantity',
                                value: '${receiptProvider.totalItemCount}',
                              ),
                              _buildSummaryItem(
                                context,
                                icon: Icons.attach_money,
                                label: 'Total',
                                value: '£${receiptProvider.subtotal.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryItem(
                                context,
                                icon: Icons.check_circle,
                                label: 'Allocated',
                                value: '£${allocatedAmount.toStringAsFixed(2)}',
                                valueColor: Colors.green,
                              ),
                              _buildSummaryItem(
                                context,
                                icon: Icons.pending,
                                label: 'Unallocated',
                                value: '${unallocatedItems.length} items',
                                valueColor: unallocatedItems.isEmpty ? Colors.green : Colors.orange,
                              ),
                              _buildSummaryItem(
                                context,
                                icon: Icons.account_balance_wallet,
                                label: 'Remaining',
                                value: '£${(receiptProvider.subtotal - allocatedAmount).toStringAsFixed(2)}',
                                valueColor: (receiptProvider.subtotal - allocatedAmount) == 0 ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Items List
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState(context, canEdit)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildItemCard(context, item, canEdit);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () => _navigateToAddItem(context),
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool canEdit) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No items yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            canEdit
                ? 'Tap the + button to add your first item'
                : 'No items have been added to this session',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          if (canEdit) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddItem(context),
              icon: const Icon(Icons.add),
              label: const Text('Add First Item'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, ReceiptItem item, bool canEdit) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);

    final currentUserId = authProvider.user?.id ?? 0;
    final canEditItem = canEdit && receiptProvider.canEditItem(item, currentUserId, widget.session.isHost);

    return Consumer<AssignmentProvider>(
      builder: (context, assignmentProvider, child) {
        final itemAssignments = assignmentProvider.getItemAssignments(item.id);
        final isAssignedToMe = assignmentProvider.isItemAssignedToUser(item.id, currentUserId);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: itemAssignments.isNotEmpty
                  ? Colors.green.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: itemAssignments.isNotEmpty
                  ? Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    )
                  : Text(
                      item.quantity.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            title: Text(
              item.itemName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('£${item.price.toStringAsFixed(2)} each'),
                Text(
                  'Added by ${item.addedByName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (itemAssignments.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Assigned to: ${itemAssignments.map((a) => a.userName).join(', ')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '£${item.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Assignment button
                if (canEdit) ...[
                  IconButton(
                    icon: Icon(
                      isAssignedToMe ? Icons.remove_circle : Icons.add_circle,
                      color: isAssignedToMe ? Colors.red : Colors.green,
                    ),
                    onPressed: () => _toggleAssignment(context, item, isAssignedToMe),
                    tooltip: isAssignedToMe ? 'Remove from me' : 'Assign to me',
                  ),
                ],
                if (canEditItem) ...[
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editItem(context, item);
                      } else if (value == 'delete') {
                        _deleteItem(context, item);
                      } else if (value == 'assign_others') {
                        _showAssignmentDialog(context, item);
                      }
                    },
                    itemBuilder: (context) => [
                      if (widget.session.isHost) ...[
                        const PopupMenuItem(
                          value: 'assign_others',
                          child: Row(
                            children: [
                              Icon(Icons.people, size: 18),
                              SizedBox(width: 8),
                              Text('Assign to Others'),
                            ],
                          ),
                        ),
                      ],
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            onTap: canEdit ? () => _showAssignmentDialog(context, item) : null,
          ),
        );
      },
    );
  }

  void _navigateToAddItem(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddItemScreen(session: widget.session),
      ),
    ).then((_) {
      // Refresh items when returning from add item screen
      _loadItems();
    });
  }

  void _editItem(BuildContext context, ReceiptItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddItemScreen(
          session: widget.session,
          editItem: item,
        ),
      ),
    ).then((_) {
      // Refresh items when returning from edit item screen
      _loadItems();
    });
  }

  void _deleteItem(BuildContext context, ReceiptItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.itemName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
              final success = await receiptProvider.deleteItem(item.id);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                        ? 'Item deleted successfully' 
                        : receiptProvider.errorMessage ?? 'Failed to delete item'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleAssignment(BuildContext context, ReceiptItem item, bool isCurrentlyAssigned) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id ?? 0;

    bool success;
    if (isCurrentlyAssigned) {
      success = await assignmentProvider.unassignItem(widget.session.id, item.id, currentUserId);
    } else {
      success = await assignmentProvider.assignItem(widget.session.id, item.id, currentUserId);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (isCurrentlyAssigned ? 'Item removed from you' : 'Item assigned to you')
              : assignmentProvider.errorMessage ?? 'Failed to update assignment'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showAssignmentDialog(BuildContext context, ReceiptItem item) {
    // TODO: Implement assignment dialog for organizers to assign to others
    // For now, just show a simple message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Assignment dialog coming soon!'),
      ),
    );
  }
}
