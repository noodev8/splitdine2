import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../models/receipt_item.dart';
import '../models/participant.dart';
import '../services/receipt_provider.dart';
import '../services/assignment_provider.dart';
import '../services/auth_provider.dart';
import '../services/session_service.dart';
import 'add_item_screen.dart';

class SessionItemsScreen extends StatefulWidget {
  final Session session;
  final String? initialFilter;

  const SessionItemsScreen({
    super.key,
    required this.session,
    this.initialFilter,
  });

  @override
  State<SessionItemsScreen> createState() => _SessionItemsScreenState();
}

class _SessionItemsScreenState extends State<SessionItemsScreen> {
  final SessionService _sessionService = SessionService();
  List<Participant> _participants = [];
  String? _selectedParticipant; // Filter by specific participant
  bool _participantsLoaded = false;
  @override
  void initState() {
    super.initState();
    // Set initial filter if provided
    if (widget.initialFilter != null) {
      _selectedParticipant = widget.initialFilter;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);

    await Future.wait([
      receiptProvider.loadItems(widget.session.id),
      assignmentProvider.loadSessionAssignments(widget.session.id),
      _loadParticipants(),
    ]);
  }

  Future<void> _loadParticipants() async {
    try {
      final result = await _sessionService.getSessionParticipants(widget.session.id);
      if (result['success']) {
        setState(() {
          _participants = result['participants'] as List<Participant>;
          _participantsLoaded = true;
        });
      }
    } catch (e) {
      // Handle error silently for now
      setState(() {
        _participantsLoaded = true;
      });
    }
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
            onPressed: _loadData,
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
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final items = receiptProvider.items;

          return Column(
            children: [

              // Personal Allocation Summary Card
              Consumer2<AssignmentProvider, AuthProvider>(
                builder: (context, assignmentProvider, authProvider, child) {
                  final currentUserId = authProvider.user?.id ?? 0;
                  final userTotal = assignmentProvider.getUserAssignedTotal(currentUserId, receiptProvider.items);
                  final userAssignments = assignmentProvider.getUserAssignments(currentUserId);

                  return Card(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'My Allocation',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '£${userTotal.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: userTotal > 0 ? Theme.of(context).colorScheme.primary : Colors.grey,
                                ),
                              ),
                              Text(
                                '${userAssignments.length} item${userAssignments.length == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          if (canEdit) ...[
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () => _navigateToAddItem(context),
                              icon: Icon(
                                Icons.add_circle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              tooltip: 'Add Item',
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Participant Filter
              if (_participantsLoaded && _participants.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedParticipant,
                              hint: Row(
                                children: [
                                  Icon(Icons.filter_list, color: Colors.grey.shade600),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Filter by participant...',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Show all items'),
                                ),
                                ..._participants.map((participant) {
                                  return DropdownMenuItem<String>(
                                    value: participant.displayName,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                          child: Text(
                                            participant.displayName.isNotEmpty
                                                ? participant.displayName[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(participant.displayName),
                                        ),
                                        if (participant.userId == widget.session.organizerId)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'HOST',
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedParticipant = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      if (_selectedParticipant != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedParticipant = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear filter',
                        ),
                      ],
                    ],
                  ),
                ),

              // Items List
              Expanded(
                child: Consumer<AssignmentProvider>(
                  builder: (context, assignmentProvider, child) {
                    // Filter items based on selected participant
                    List<ReceiptItem> filteredItems = items;

                    if (_selectedParticipant != null) {
                      // Filter by participant assignments
                      filteredItems = items.where((item) {
                        final assignments = assignmentProvider.getItemAssignments(item.id);
                        return assignments.any((assignment) =>
                            assignment.userName.toLowerCase() == _selectedParticipant!.toLowerCase());
                      }).toList();
                    }

                    return filteredItems.isEmpty
                        ? _buildEmptyState(context, canEdit, isFiltered: _selectedParticipant != null)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return _buildItemCard(context, item, canEdit);
                            },
                          );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }




  Widget _buildEmptyState(BuildContext context, bool canEdit, {bool isFiltered = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.search_off : Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No matching items' : 'No items yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try adjusting your search or filter'
                : canEdit
                    ? 'Tap the + button to add your first item'
                    : 'No items have been added to this session',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          if (!isFiltered && canEdit) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddItem(context),
              icon: const Icon(Icons.add),
              label: const Text('Add First Item'),
            ),
          ],
          if (isFiltered) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedParticipant = null;
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filter'),
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
      _loadData();
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
      _loadData();
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _AssignmentDialog(
          item: item,
          session: widget.session,
        );
      },
    );
  }
}

class _AssignmentDialog extends StatefulWidget {
  final ReceiptItem item;
  final Session session;

  const _AssignmentDialog({
    required this.item,
    required this.session,
  });

  @override
  State<_AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<_AssignmentDialog> {
  final SessionService _sessionService = SessionService();
  List<Participant> _participants = [];
  Set<int> _selectedUserIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
    _loadCurrentAssignments();
  }

  Future<void> _loadParticipants() async {
    try {
      final result = await _sessionService.getSessionParticipants(widget.session.id);
      if (result['success']) {
        setState(() {
          _participants = result['participants'] as List<Participant>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load participants: $e';
        _isLoading = false;
      });
    }
  }

  void _loadCurrentAssignments() {
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
    final currentAssignments = assignmentProvider.getItemAssignments(widget.item.id);
    setState(() {
      _selectedUserIds = currentAssignments.map((a) => a.userId).toSet();
    });
  }

  Future<void> _saveAssignments() async {
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
    final currentAssignments = assignmentProvider.getItemAssignments(widget.item.id);
    final currentUserIds = currentAssignments.map((a) => a.userId).toSet();

    // Users to add
    final usersToAdd = _selectedUserIds.difference(currentUserIds);
    // Users to remove
    final usersToRemove = currentUserIds.difference(_selectedUserIds);

    bool success = true;
    String? errorMessage;

    // Add new assignments
    for (final userId in usersToAdd) {
      final result = await assignmentProvider.assignItem(widget.session.id, widget.item.id, userId);
      if (!result) {
        success = false;
        errorMessage = assignmentProvider.errorMessage;
        break;
      }
    }

    // Remove assignments
    for (final userId in usersToRemove) {
      final result = await assignmentProvider.unassignItem(widget.session.id, widget.item.id, userId);
      if (!result) {
        success = false;
        errorMessage = assignmentProvider.errorMessage;
        break;
      }
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignments updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update assignments: ${errorMessage ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign "${widget.item.itemName}"'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select participants to assign this item to:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _participants.length,
                          itemBuilder: (context, index) {
                            final participant = _participants[index];
                            final isSelected = _selectedUserIds.contains(participant.userId);
                            final isOrganizer = participant.userId == widget.session.organizerId;
                            final wasAddedByOrganizer = widget.item.addedByUserId == widget.session.organizerId;

                            return CheckboxListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      participant.displayName,
                                      style: TextStyle(
                                        fontWeight: isOrganizer ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isOrganizer)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'HOST',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    participant.email != null
                                        ? participant.email!
                                        : 'Guest user',
                                  ),
                                  if (wasAddedByOrganizer && isOrganizer)
                                    Text(
                                      'Added this item',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedUserIds.add(participant.userId);
                                  } else {
                                    _selectedUserIds.remove(participant.userId);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (!_isLoading && _errorMessage == null)
          ElevatedButton(
            onPressed: _saveAssignments,
            child: const Text('Save'),
          ),
      ],
    );
  }
}
