import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../models/receipt_item.dart';
import '../services/receipt_provider.dart';
import '../services/assignment_provider.dart';
import '../services/auth_provider.dart';
import 'add_item_screen.dart';

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
  @override
  void initState() {
    super.initState();
    // Load data after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);

    await receiptProvider.loadItems(widget.session.id);
    await assignmentProvider.loadSessionAssignments(widget.session.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Very light gray background
      body: Consumer3<ReceiptProvider, AssignmentProvider, AuthProvider>(
        builder: (context, receiptProvider, assignmentProvider, authProvider, child) {
          if (receiptProvider.isLoading || assignmentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUserId = authProvider.user?.id ?? 0;
          final userAssignments = assignmentProvider.getUserAssignments(currentUserId);
          final allItems = receiptProvider.items;

          // Get items assigned to current user
          final myItems = <ReceiptItem>[];
          for (final assignment in userAssignments) {
            final item = allItems.firstWhere(
              (item) => item.id == assignment.itemId,
              orElse: () => ReceiptItem(
                id: 0, sessionId: 0, itemName: '', price: 0.0, quantity: 0,
                addedByUserId: 0, addedByName: '',
                createdAt: DateTime.now(), updatedAt: DateTime.now()
              ),
            );
            if (item.id != 0) {
              // If item has multiple quantities, add them separately
              for (int i = 0; i < item.quantity; i++) {
                myItems.add(item.copyWith(quantity: 1));
              }
            }
          }

          // Sort items by creation date, latest first
          myItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final userTotal = assignmentProvider.getUserAssignedTotal(currentUserId, allItems);

          return Stack(
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
                          const Expanded(
                            child: Text(
                              'My Items',
                              style: TextStyle(
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

                    // Total Card overlapping the header
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
                          const Text(
                            'Your Total',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4E4B47), // Warm Gray-700
                              letterSpacing: -0.02,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '£${userTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4E4B47), // Warm Gray-700
                              letterSpacing: -0.02,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${myItems.length} item${myItems.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 18,
                              color: const Color(0xFF4E4B47).withValues(alpha: 0.7),
                              height: 1.3, // 130% line height
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Items List
                    Expanded(
                      child: myItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No items assigned to you yet',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF4E4B47),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Items you\'re assigned to will appear here',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 18,
                                      color: const Color(0xFF4E4B47).withValues(alpha: 0.7),
                                      height: 1.3, // 130% line height
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                              itemCount: myItems.length,
                              separatorBuilder: (context, index) => const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFECE9E6), // Warm Gray-200
                                indent: 24,
                                endIndent: 24,
                              ),
                              itemBuilder: (context, index) {
                                final item = myItems[index];
                                final itemAssignments = assignmentProvider.getItemAssignments(item.id);
                                final shareCount = itemAssignments.length;
                                final myShare = shareCount > 0 ? item.price / shareCount : item.price;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  title: Text(
                                    item.itemName,
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF4E4B47),
                                      height: 1.3, // 130% line height
                                    ),
                                  ),
                                  subtitle: shareCount > 1
                                      ? Text(
                                          'Shared with ${shareCount - 1} other${shareCount > 2 ? 's' : ''}',
                                          style: TextStyle(
                                            fontFamily: 'Nunito',
                                            fontSize: 16,
                                            color: const Color(0xFF4E4B47).withValues(alpha: 0.6),
                                            height: 1.3, // 130% line height
                                          ),
                                        )
                                      : null,
                                  trailing: Text(
                                    '£${myShare.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4E4B47),
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  onTap: () => _navigateToEditItem(context, item),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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
        currentIndex: 0, // Add Item is selected
        onTap: (index) {
          switch (index) {
            case 0:
              _navigateToAddItem(context);
              break;
            case 1:
              // TODO: Implement table functionality
              break;
            case 2:
              // TODO: Implement guests functionality
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add Item',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant),
            label: 'Table',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Guests',
          ),
        ],
      ),
    );
  }

  void _navigateToAddItem(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
    final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddItemScreen(session: widget.session),
      ),
    );

    // If an item was added (result contains the last item ID), automatically assign all new items to the current user
    if (result != null && result is int && mounted) {
      final currentUserId = authProvider.user?.id;
      if (currentUserId != null) {
        // Refresh items first to get all the newly added items
        await receiptProvider.loadItems(widget.session.id);

        // Find all items that are not yet assigned to anyone
        final allItems = receiptProvider.items;
        final unassignedItems = assignmentProvider.getUnallocatedItems(allItems);

        // Assign all unassigned items to the current user
        // (These should be the items we just added)
        for (final item in unassignedItems) {
          await assignmentProvider.assignItem(
            widget.session.id,
            item.id,
            currentUserId
          );
        }

        // Refresh data to show the updated assignments
        await _loadData();
      }
    } else if (result != null) {
      // Item was edited or other action, just refresh
      await _loadData();
    }
  }

  void _navigateToEditItem(BuildContext context, ReceiptItem item) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddItemScreen(
          session: widget.session,
          editItem: item,
        ),
      ),
    );

    // Refresh data when returning from edit screen
    if (result != null) {
      await _loadData();
    }
  }
}
