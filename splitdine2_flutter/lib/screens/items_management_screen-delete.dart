import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/session_receipt_item.dart';
import '../models/participant.dart';
import '../services/session_service.dart';
import '../services/session_receipt_service.dart';
import '../services/guest_choice_service.dart';
import 'add_new_item_screen.dart';

/// Screen for managing session items and guest assignments
class ItemsManagementScreen extends StatefulWidget {
  final Session session;

  const ItemsManagementScreen({
    super.key,
    required this.session,
  });

  @override
  State<ItemsManagementScreen> createState() => _ItemsManagementScreenState();
}

class _ItemsManagementScreenState extends State<ItemsManagementScreen> {
  final SessionService _sessionService = SessionService();
  final GuestChoiceService _guestChoiceService = GuestChoiceService();

  List<SessionReceiptItem> _items = [];
  List<Participant> _participants = [];
  Map<int, List<int>> _itemAssignments = {};
  final Set<int> _sharedItems = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _loadItems(),
      _loadParticipants(),
      _loadAssignments(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadItems() async {
    try {
      final result = await SessionReceiptService.getItems(widget.session.id);
      if (result['success']) {
        setState(() {
          _items = result['items'] as List<SessionReceiptItem>;
          _items.sort((a, b) => a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()));
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadParticipants() async {
    try {
      final result = await _sessionService.getSessionParticipants(widget.session.id);
      if (result['success']) {
        setState(() {
          _participants = result['participants'] as List<Participant>;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadAssignments() async {
    try {
      final result = await _guestChoiceService.getSessionAssignments(widget.session.id);
      if (result['success']) {
        final assignments = result['assignments'] as List;
        Map<int, List<int>> assignmentsByItemId = {};
        Set<int> sharedItemIds = {};

        for (final assignment in assignments) {
          final itemId = assignment['item_id'] as int?;
          final userId = assignment['user_id'] as int?;
          final isShared = assignment['split_item'] as bool? ?? false;

          if (itemId == null || userId == null) continue;

          assignmentsByItemId[itemId] ??= [];
          assignmentsByItemId[itemId]!.add(userId);

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
      // Handle error
    }
  }

  void _navigateToAddItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNewItemScreen(session: widget.session),
      ),
    ).then((_) {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Manage Items',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _buildEmptyState()
              : _buildItemsList(),
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
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _navigateToAddItem,
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Add Items',
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                const Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: Color(0xFF7A8471),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'No items yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to start splitting the bill',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    final total = _items.fold(0.0, (sum, item) => sum + item.price);
    
    return Column(
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '£${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7A8471),
                ),
              ),
            ],
          ),
        ),
        
        // Items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _items.length,
            itemBuilder: (context, index) => _buildItemCard(_items[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(SessionReceiptItem item) {
    final assignments = _itemAssignments[item.id] ?? [];
    final isShared = _sharedItems.contains(item.id);
    final assignedParticipants = _participants
        .where((p) => assignments.contains(p.userId))
        .map((p) => p.displayName)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: assignments.isNotEmpty ? Colors.blue.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: assignments.isNotEmpty ? Colors.blue.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isShared)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SHARED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '£${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'delete':
                        _deleteItem(item);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.delete, color: Colors.red, size: 20),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (assignedParticipants.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: assignedParticipants
                    .map((name) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7A8471).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7A8471),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(SessionReceiptItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Delete "${item.itemName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _guestChoiceService.deleteItemAssignments(
          sessionId: widget.session.id,
          itemId: item.id,
        );

        final result = await SessionReceiptService.deleteItem(item.id, widget.session.id);
        if (result['success']) {
          _loadData();
        }
      } catch (e) {
        // Handle error
      }
    }
  }
}