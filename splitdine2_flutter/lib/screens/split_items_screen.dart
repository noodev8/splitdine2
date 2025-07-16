import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitdine2_flutter/models/session.dart';
import 'package:splitdine2_flutter/models/split_item.dart';
import 'package:splitdine2_flutter/models/participant.dart';
import 'package:splitdine2_flutter/services/split_item_provider.dart';
import 'package:splitdine2_flutter/services/session_service.dart';
import 'package:splitdine2_flutter/screens/add_split_item_screen.dart';

class SplitItemsScreen extends StatefulWidget {
  final Session session;
  final String? scrollToItemName; // Optional item name to scroll to

  const SplitItemsScreen({
    super.key,
    required this.session,
    this.scrollToItemName,
  });

  @override
  State<SplitItemsScreen> createState() => _SplitItemsScreenState();
}

class _SplitItemsScreenState extends State<SplitItemsScreen> {
  List<Participant> _participants = [];
  bool _isLoadingParticipants = false;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  // Material 3 grey color scheme to match guest items
  static const Color backgroundColor = Color(0xFFFAFAFA); // Very light gray background
  static const Color surfaceColor = Color(0xFFFFFFFF); // White surface
  static const Color onSurfaceColor = Color(0xFF4E4B47); // Dark Gray text

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSplitItems(),
      _loadParticipants(),
    ]);

    // Scroll to specific item if requested
    if (widget.scrollToItemName != null) {
      _scrollToItem(widget.scrollToItemName!);
    }
  }

  Future<void> _loadSplitItems() async {
    final splitItemProvider = Provider.of<SplitItemProvider>(context, listen: false);
    await splitItemProvider.loadItems(widget.session.id);
  }

  void _scrollToItem(String itemName) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final splitItemProvider = Provider.of<SplitItemProvider>(context, listen: false);
      final items = splitItemProvider.items;

      final itemIndex = items.indexWhere((item) => item.name == itemName);
      if (itemIndex != -1 && _scrollController.hasClients) {
        // Calculate approximate position (each item card is roughly 200 pixels)
        final position = itemIndex * 200.0;
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadParticipants() async {
    setState(() {
      _isLoadingParticipants = true;
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
        _isLoadingParticipants = false;
      });
    }
  }

  void _navigateToAddSplitItem() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddSplitItemScreen(session: widget.session),
      ),
    ).then((_) {
      // Refresh the list when returning from add screen
      _loadSplitItems();
    });
  }



  Future<void> _toggleParticipant(SplitItem item, Participant participant, bool isSelected) async {
    final splitItemProvider = Provider.of<SplitItemProvider>(context, listen: false);

    if (isSelected) {
      await splitItemProvider.addParticipant(
        itemId: item.id,
        userId: participant.userId,
        sessionId: widget.session.id,
      );
    } else {
      await splitItemProvider.removeParticipant(item.id, participant.userId, widget.session.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            'Split Items',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurfaceColor,
            ),
          ),
          backgroundColor: surfaceColor,
          foregroundColor: onSurfaceColor,
          elevation: 0,
        ),
        body: Consumer<SplitItemProvider>(
          builder: (context, splitItemProvider, child) {
            if (splitItemProvider.isLoading || _isLoadingParticipants) {
              return const Center(child: CircularProgressIndicator());
            }

            if (splitItemProvider.errorMessage != null || _errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      splitItemProvider.errorMessage ?? _errorMessage!,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final splitItems = splitItemProvider.items;

            if (splitItems.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.call_split,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No split items yet',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Add items that will be split equally between selected participants.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: splitItems.length,
              itemBuilder: (context, index) {
                final item = splitItems[index];
                return _buildSplitItemCard(item);
              },
            );
          },
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
            child: ElevatedButton(
              onPressed: _navigateToAddSplitItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: onSurfaceColor, // Use dark gray instead of blue
                foregroundColor: Colors.white, // White text for good contrast
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Add Split',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Ensure white text
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildSplitItemCard(SplitItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item header - more prominent
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: onSurfaceColor,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '£${item.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: onSurfaceColor,
                          ),
                        ),
                        if (item.participants.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '£${(item.price / item.participants.length).toStringAsFixed(2)} each',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirmation(item);
                        } else if (value == 'assign_all') {
                          _assignToAllParticipants(item);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'assign_all',
                          child: Row(
                            children: [
                              Icon(Icons.group_add, size: 20),
                              SizedBox(width: 8),
                              Text('Assign to All'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete Item', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Participants section
            Text(
              'Participants (${item.participants.length})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 8),

            // All participants in consistent order
            ..._getAllParticipantsInOrder(item).map((participantData) => _buildParticipantRow(
              item,
              participantData['name'],
              participantData['userId'],
              participantData['isAssigned']
            )),

            const SizedBox(height: 8),

            // Added by info
            Text(
              'Added by ${item.addedByName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantRow(SplitItem item, String participantName, int participantId, bool isAssigned) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.person,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              participantName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isAssigned ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
          ),
          if (isAssigned)
            InkWell(
              onTap: () => _toggleParticipant(item, _findParticipantById(participantId), false),
              child: Container(
                padding: const EdgeInsets.all(12), // Increased padding for larger tap area
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check,
                  size: 24, // Increased from 16 to 24
                  color: Colors.black,
                ),
              ),
            )
          else
            InkWell(
              onTap: () => _toggleParticipant(item, _findParticipantById(participantId), true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Increased padding
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, width: 2), // Thicker border
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+ Add',
                  style: TextStyle(
                    fontSize: 14, // Increased from 12 to 14
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAllParticipantsInOrder(SplitItem item) {
    final assignedUserIds = item.participants.map((p) => p.userId).toSet();

    // Create a consistent list of all participants with their assignment status
    return _participants.map((participant) {
      final isAssigned = assignedUserIds.contains(participant.userId);
      return {
        'name': participant.displayName,
        'userId': participant.userId,
        'isAssigned': isAssigned,
      };
    }).toList();
  }

  Participant _findParticipantById(int userId) {
    return _participants.firstWhere(
      (p) => p.userId == userId,
      orElse: () => Participant(
        id: 0,
        sessionId: widget.session.id,
        userId: userId,
        displayName: 'Unknown User',
        role: 'guest',
        joinedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(SplitItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Split Item'),
          content: Text('Are you sure you want to delete "${item.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final splitItemProvider = Provider.of<SplitItemProvider>(context, listen: false);
      final success = await splitItemProvider.deleteItem(item.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Split item deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete split item: ${splitItemProvider.errorMessage}')),
          );
        }
      }
    }
  }

  Future<void> _assignToAllParticipants(SplitItem item) async {
    if (!mounted) return;

    final splitItemProvider = Provider.of<SplitItemProvider>(context, listen: false);

    // Get all unassigned participants
    final unassignedParticipants = _getAllParticipantsInOrder(item)
        .where((p) => !p['isAssigned'])
        .toList();

    if (unassignedParticipants.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All participants are already assigned to this item')),
        );
      }
      return;
    }

    // Add all unassigned participants
    for (final participantData in unassignedParticipants) {
      await splitItemProvider.addParticipant(
        itemId: item.id,
        userId: participantData['userId'],
        sessionId: widget.session.id,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned ${unassignedParticipants.length} participants to "${item.name}"')),
      );
    }
  }
}




