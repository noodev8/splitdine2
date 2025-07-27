import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/session_receipt_item.dart';
import '../models/participant.dart';
import '../services/session_receipt_service.dart';
import '../services/session_service.dart';
import '../services/guest_choice_service.dart';
import 'add_new_item_screen.dart';

class GuestChoicesScreen extends StatefulWidget {
  final Session session;

  const GuestChoicesScreen({
    super.key,
    required this.session,
  });

  @override
  State<GuestChoicesScreen> createState() => _GuestChoicesScreenState();
}

class _GuestChoicesScreenState extends State<GuestChoicesScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  static const int maxItemNameLength = 30;

  final SessionService _sessionService = SessionService();
  final GuestChoiceService _guestChoiceService = GuestChoiceService();

  List<SessionReceiptItem> _existingItems = [];
  List<Participant> _participants = [];
  bool _isProcessing = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Track guest choices and shared items
  Map<int, List<int>> _itemAssignments = {}; // itemId -> list of userIds
  final Set<int> _sharedItems = {}; // Set of item IDs that are marked as shared
  
  // Track confirmed/hidden items (front-end only for bill reconciliation)
  final Set<int> _confirmedItems = {}; // Set of item IDs that are confirmed/ticked off
  bool _reconciliationMode = false; // Toggle reconciliation mode on/off
  bool _hideConfirmedItems = false; // Toggle to hide confirmed items

  // Animation controllers for participant chips
  late Map<String, AnimationController> _chipAnimationControllers;
  late Map<String, Animation<double>> _chipScaleAnimations;

  @override
  void initState() {
    super.initState();
    print('[DEBUG] GuestChoicesScreen initState called');
    WidgetsBinding.instance.addObserver(this);
    _chipAnimationControllers = {};
    _chipScaleAnimations = {};
    _initializeData();
  }

  @override
  void dispose() {
    print('[DEBUG] GuestChoicesScreen dispose called');
    WidgetsBinding.instance.removeObserver(this);
    // Clean up animation controllers
    for (final controller in _chipAnimationControllers.values) {
      controller.dispose();
    }
    _chipAnimationControllers.clear();
    _chipScaleAnimations.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[DEBUG] App lifecycle state changed to: $state');
    if (state == AppLifecycleState.resumed) {
      print('[DEBUG] App resumed - checking for pending operations');
    }
  }

  String _getLoadingMessage() {
    if (_isLoading) {
      return 'Loading items...';
    }
    return 'Processing...';
  }

  String _getLoadingSubMessage() {
    if (_isLoading) {
      return 'Please wait while we load your data';
    }
    return 'This won\'t take long';
  }

  // Helper method to get or create animation controller for a participant
  AnimationController _getChipAnimationController(String participantKey) {
    if (!_chipAnimationControllers.containsKey(participantKey)) {
      _chipAnimationControllers[participantKey] = AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      );
      _chipScaleAnimations[participantKey] = Tween<double>(
        begin: 1.0,
        end: 1.1,
      ).animate(CurvedAnimation(
        parent: _chipAnimationControllers[participantKey]!,
        curve: Curves.elasticOut,
      ));
    }
    return _chipAnimationControllers[participantKey]!;
  }

  // Trigger bounce animation for chip selection
  void _animateChipSelection(String participantKey) {
    final controller = _getChipAnimationController(participantKey);
    controller.forward().then((_) {
      controller.reverse();
    });
  }

  // Animated number widget for smooth price transitions
  Widget _buildAnimatedPrice(double value, TextStyle style, {String prefix = '£', String suffix = '', int decimals = 2}) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: value),
      builder: (context, animatedValue, child) {
        return Text(
          '$prefix${animatedValue.toStringAsFixed(decimals)}$suffix',
          style: style,
        );
      },
    );
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    await _loadParticipants();
    await _loadExistingItems();
    await _loadAssignments();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Guest Choices',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.black12,
        actions: [
          IconButton(
            icon: Icon(_reconciliationMode ? Icons.receipt_long : Icons.fact_check_outlined),
            onPressed: () {
              setState(() {
                _reconciliationMode = !_reconciliationMode;
                // Clean up when leaving reconciliation mode
                if (!_reconciliationMode) {
                  _hideConfirmedItems = false;
                  _confirmedItems.clear(); // Clear all confirmations
                }
              });
            },
            tooltip: _reconciliationMode ? 'Exit bill reconciliation' : 'Check bill against receipt',
            style: IconButton.styleFrom(
              backgroundColor: _reconciliationMode ? Colors.orange.shade100 : null,
            ),
          ),
          if (_reconciliationMode)
            IconButton(
              icon: Icon(_hideConfirmedItems ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _hideConfirmedItems = !_hideConfirmedItems;
                });
              },
              tooltip: _hideConfirmedItems ? 'Show confirmed items' : 'Hide confirmed items',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_isProcessing || _isLoading) ? null : _initializeData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isProcessing || _isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7A8471)),
                ),
                const SizedBox(height: 16),
                Text(
                  _getLoadingMessage(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getLoadingSubMessage(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        : Column(
              children: [
                // Total Card
                if (_existingItems.isNotEmpty) ...[
                  _buildTotalCard(),
                  const SizedBox(height: 8),
                ],



                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(),
                ],

                // Items list
                Expanded(
                  child: _existingItems.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Existing items (filtered if hiding confirmed)
                            ..._existingItems
                                .where((item) => !_hideConfirmedItems || !_confirmedItems.contains(item.id))
                                .map((item) => _buildSessionReceiptItemCard(item)),
                          ],
                        ),
                ),
              ],
            ),
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
            onPressed: _addNewItem,
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
              overlayColor: Colors.black.withValues(alpha: 0.05),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                      MediaQuery.of(context).padding.top - 
                      kToolbarHeight - 
                      140, // Approximate bottom nav height
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            // Icon stack for visual interest
            Center(
              child: Stack(
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
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: const Color(0xFF7A8471),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No receipt items yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get started by adding items manually',
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
      ),
    );
  }

  Widget _buildSessionReceiptItemCard(SessionReceiptItem item) {
    final itemAssignments = _getItemAssignments(item.id);
    final isShared = _sharedItems.contains(item.id);
    final splitPrice = isShared && itemAssignments.isNotEmpty ? item.price / itemAssignments.length : item.price;
    final isAssigned = itemAssignments.isNotEmpty;
    final isConfirmed = _confirmedItems.contains(item.id);

    // Determine card appearance based on state
    Color cardColor;
    Color borderColor;
    double opacity = 1.0;
    
    if (isConfirmed && _reconciliationMode) {
      cardColor = Colors.green.shade50;
      borderColor = Colors.green.shade300;
      opacity = 0.8;
    } else if (isAssigned) {
      cardColor = Colors.blue.shade50;
      borderColor = Colors.blue.shade200;
    } else {
      cardColor = Colors.white;
      borderColor = Colors.grey.shade300;
    }

    return Stack(
      children: [
        Opacity(
          opacity: opacity,
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: borderColor,
                width: isConfirmed ? 2 : 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_reconciliationMode) {
                    // In reconciliation mode, tap toggles confirmation
                    setState(() {
                      if (isConfirmed) {
                        _confirmedItems.remove(item.id);
                      } else {
                        _confirmedItems.add(item.id);
                      }
                    });
                  } else {
                    // Normal mode, tap edits item
                    _showEditItemDialog(item);
                  }
                },
                onLongPress: () => _showItemOptionsDialog(item),
                borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with item name, price, and actions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item name with shared tag
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.itemName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isShared) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SHARED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Price information - stack vertically for shared items
                        if (isShared) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '£${item.price.toStringAsFixed(2)} total',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '£${splitPrice.toStringAsFixed(2)} each',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7A8471),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            '£${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7A8471),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Participants section
            _buildParticipantsSection(item),


            ],
            ),
          ),
        ),
            ),
          ),
        ),
        // Corner badge for confirmed items (only show in reconciliation mode)
        if (isConfirmed && _reconciliationMode)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 3,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }





  Widget _buildTotalCard() {
    final total = _calculateTotal();
    final allocated = _calculateAllocatedTotal();
    final progress = total > 0 ? allocated / total : 0.0;
    final percentage = (progress * 100).toInt();
    final isComplete = allocated == total && total > 0;
    final isOverspent = allocated > total && total > 0;
    
    // Determine colors and status
    Color statusColor;
    String statusText;
    if (isOverspent) {
      statusColor = Colors.red;
      statusText = 'OVERSPENT';
    } else if (isComplete) {
      statusColor = Colors.green;
      statusText = 'COMPLETE';
    } else {
      statusColor = const Color(0xFF7A8471); // Use sage green instead of orange
      statusText = 'PROGRESS';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Total and allocated amounts
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _buildAnimatedPrice(
                          total,
                          TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'ALLOCATED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _buildAnimatedPrice(
                          allocated,
                          TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Progress bar
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        '${percentage.clamp(0, 999)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
                      builder: (context, animatedProgress, child) {
                        return LinearProgressIndicator(
                          value: animatedProgress,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  isComplete
                    ? Text(
                        'All items allocated',
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : _buildAnimatedPrice(
                        isOverspent ? (allocated - total) : (total - allocated),
                        TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        suffix: isOverspent ? ' over budget' : ' remaining to allocate',
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotal() {
    return _existingItems.fold(0.0, (sum, item) {
      return sum + item.price;
    });
  }

  double _calculateAllocatedTotal() {
    double total = 0.0;
    for (final item in _existingItems) {
      final assignments = _getItemAssignments(item.id);
      if (assignments.isNotEmpty) {
        final isShared = _sharedItems.contains(item.id);
        if (isShared) {
          // For shared items, add the full price once (split between guests)
          total += item.price;
        } else {
          // For individual items, each guest has their own item
          total += item.price * assignments.length;
        }
      }
    }
    return total;
  }

  // Add new item
  void _addNewItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNewItemScreen(session: widget.session),
      ),
    ).then((_) {
      // Reload items when returning from add screen
      _loadExistingItems();
      _loadAssignments();
    });
  }

  // Add item to database
  Future<void> _addItemToDatabase(String itemName, double price) async {
    try {
      final result = await SessionReceiptService.addItem(
        sessionId: widget.session.id,
        itemName: itemName,
        price: price,
      );

      if (result['success']) {
        await _loadExistingItems();
        await _loadAssignments();
      } else {
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




  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                icon: Icon(
                  Icons.close,
                  color: Colors.red.shade600,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
          if (_shouldShowRetryAction()) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _retryLastAction,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _shouldShowRetryAction() {
    return _errorMessage != null && 
           (_errorMessage!.contains('receipt') || 
            _errorMessage!.contains('process') || 
            _errorMessage!.contains('scan') ||
            _errorMessage!.contains('network') ||
            _errorMessage!.contains('failed'));
  }

  void _retryLastAction() {
    setState(() {
      _errorMessage = null;
    });
    
    _loadExistingItems();
  }










  Widget _buildParticipantsSection(SessionReceiptItem item) {
    final itemAssignments = _getItemAssignments(item.id);
    final assignedUserIds = itemAssignments.toSet();
    final isShared = _sharedItems.contains(item.id);
    

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        // All participants
        if (_participants.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _participants.map((participant) {
              final isAssigned = assignedUserIds.contains(participant.userId);
              return _buildParticipantChip(participant, isAssigned, item);
            }).toList(),
          ),
        
        // Fallback message when no participants loaded
        if (_participants.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.amber.shade700,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No participants loaded. Check your internet connection or try refreshing.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Info text for shared items
        if (isShared && itemAssignments.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Price will be split equally among ${itemAssignments.length} people',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }




  Widget _buildParticipantChip(Participant participant, bool isSelected, SessionReceiptItem item) {
    final participantKey = '${item.id}_${participant.id}';
    _getChipAnimationController(participantKey); // Initialize animation controller
    final scaleAnimation = _chipScaleAnimations[participantKey]!;
    
    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: ElevatedButton(
              onPressed: () {
                // Trigger bounce animation on selection
                _animateChipSelection(participantKey);
                _toggleParticipantAssignment(item, participant, !isSelected);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? const Color(0xFF7A8471) : Colors.white,
                foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF7A8471) : Colors.grey.shade300,
                  ),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                overlayColor: Colors.black.withValues(alpha: 0.05),
              ),
              child: Text(
                participant.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }





  // Show add item dialog
  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => _EditItemDialog(
        item: null, // null indicates this is for adding
        onSave: (newName, newPrice) async {
          await _addItemToDatabase(newName, newPrice);
        },
      ),
    );
  }

  // Show edit dialog for session receipt item
  Future<void> _showEditItemDialog(SessionReceiptItem item) async {
    showDialog(
      context: context,
      builder: (context) => _EditItemDialog(
        item: item,
        onSave: (newName, newPrice) async {
          await _updateItem(item, newName, newPrice);
        },
      ),
    );
  }

  // Update session receipt item
  Future<void> _updateItem(SessionReceiptItem item, String name, double price) async {
    try {
      final result = await SessionReceiptService.updateItem(
        itemId: item.id,
        sessionId: widget.session.id,
        itemName: name,
        price: price,
      );

      if (result['success']) {

        await _loadExistingItems();
        await _loadAssignments();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update item: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  // Delete session receipt item
  Future<void> _deleteItem(SessionReceiptItem item) async {
    try {
      // First delete all guest choice assignments for this item
      await _guestChoiceService.deleteItemAssignments(
        sessionId: widget.session.id,
        itemId: item.id,
      );

      // Then delete the receipt item itself
      final result = await SessionReceiptService.deleteItem(item.id, widget.session.id);

      if (result['success']) {
        // Remove from local state
        setState(() {
          _itemAssignments.remove(item.id);
          _sharedItems.remove(item.id);
        });

        await _loadExistingItems();
        await _loadAssignments();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete item: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get item assignments from local state
  List<int> _getItemAssignments(int itemId) {
    return _itemAssignments[itemId] ?? [];
  }

  // Truncate item name if too long
  String _truncateItemName(String name) {
    if (name.length <= maxItemNameLength) {
      return name;
    }
    return '${name.substring(0, maxItemNameLength - 3)}...';
  }

  // Toggle participant assignment
  Future<void> _toggleParticipantAssignment(SessionReceiptItem item, Participant participant, bool assign) async {
    try {
      if (assign) {
        final isShared = _sharedItems.contains(item.id);
        
        // For individual items, remove all existing assignments first
        if (!isShared) {
          final existingAssignments = _getItemAssignments(item.id);
          for (final existingUserId in existingAssignments) {
            await _guestChoiceService.unassignItem(
              sessionId: widget.session.id,
              itemId: item.id,
              userId: existingUserId,
            );
          }
          
          // Clear local assignments for individual items
          setState(() {
            _itemAssignments[item.id] = [];
          });
        }
        
        // Assign item to participant
        final result = await _guestChoiceService.assignItem(
          sessionId: widget.session.id,
          itemId: item.id,
          userId: participant.userId,
          splitItem: isShared,
        );

        if (result['success']) {
          setState(() {
            _itemAssignments[item.id] = (_itemAssignments[item.id] ?? [])..add(participant.userId);
          });
        }
      } else {
        // Unassign item from participant
        final result = await _guestChoiceService.unassignItem(
          sessionId: widget.session.id,
          itemId: item.id,
          userId: participant.userId,
        );

        if (result['success']) {
          setState(() {
            _itemAssignments[item.id]?.remove(participant.userId);
            if (_itemAssignments[item.id]?.isEmpty == true) {
              _itemAssignments.remove(item.id);
            }
          });
        }
      }
    } catch (e) {
      // Handle error silently for now
    }
  }




  // Toggle item type between individual and shared
  Future<void> _toggleItemType(SessionReceiptItem item) async {
    final wasShared = _sharedItems.contains(item.id);
    final willBeShared = !wasShared;

    setState(() {
      if (wasShared) {
        _sharedItems.remove(item.id);
      } else {
        _sharedItems.add(item.id);
      }
    });

    // Update shared status in database
    try {
      await _guestChoiceService.updateItemSharedStatus(
        sessionId: widget.session.id,
        itemId: item.id,
        isShared: willBeShared,
        itemPrice: item.price,
      );
    } catch (e) {
      // Revert state change if API call fails
      setState(() {
        if (wasShared) {
          _sharedItems.add(item.id);
        } else {
          _sharedItems.remove(item.id);
        }
      });
    }
  }

  // Copy item
  Future<void> _copyItem(SessionReceiptItem item) async {
    try {
      final result = await SessionReceiptService.addItem(
        sessionId: widget.session.id,
        itemName: '${item.itemName} (Copy)',
        price: item.price,
      );

      if (result['success']) {
        await _loadExistingItems();
        await _loadAssignments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied ${item.itemName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to copy item: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copying item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Load existing session receipt items
  Future<void> _loadExistingItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await SessionReceiptService.getItems(widget.session.id);

      if (result['success']) {
        setState(() {
          _existingItems = result['items'] as List<SessionReceiptItem>;
          // Sort items alphabetically by name for easier user navigation
          _existingItems.sort((a, b) => a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()));
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load existing items: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load session participants
  Future<void> _loadParticipants() async {
    try {
      final result = await _sessionService.getSessionParticipants(widget.session.id);
      
      if (result['success']) {
        final participantList = result['participants'] as List<Participant>;
        setState(() {
          _participants = participantList;
        });
      }
    } catch (e) {
      // Failed to load participants - continue without them
    }
  }

  // Load existing assignments
  Future<void> _loadAssignments() async {
    try {
      final result = await _guestChoiceService.getSessionAssignments(widget.session.id);

      if (result['success']) {
        final assignments = result['assignments'] as List;

        // Group assignments by item_id and track shared items
        Map<int, List<int>> assignmentsByItemId = {};
        Set<int> sharedItemIds = {};

        for (final assignment in assignments) {
          final itemId = assignment['item_id'] as int?;
          final userId = assignment['user_id'] as int?;
          final isShared = assignment['split_item'] as bool? ?? false;

          // Skip if missing required data
          if (itemId == null || userId == null) continue;

          if (assignmentsByItemId[itemId] == null) {
            assignmentsByItemId[itemId] = [];
          }
          assignmentsByItemId[itemId]!.add(userId);

          // Track shared items
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
      // Failed to load assignments - continue without them
    }
  }

  // Show dialog for re-scan options when items already exist

  // Clear existing items

  void _showItemOptionsDialog(SessionReceiptItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isShared = _sharedItems.contains(item.id);
        return AlertDialog(
          title: Text(item.itemName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Item'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditItemDialog(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Item'),
                onTap: () {
                  Navigator.of(context).pop();
                  _copyItem(item);
                },
              ),
              ListTile(
                leading: Icon(isShared ? Icons.person : Icons.group),
                title: Text(isShared ? 'Make Individual' : 'Make Shared'),
                onTap: () {
                  Navigator.of(context).pop();
                  _toggleItemType(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Item', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteItem(item);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReconciliationStatus() {
    final totalItems = _existingItems.length;
    final confirmedItems = _confirmedItems.length;
    final remainingItems = totalItems - confirmedItems;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.fact_check,
                size: 16,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bill reconciliation mode: Tap to confirm • Long press to edit',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$confirmedItems/$totalItems items confirmed',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade600,
                  ),
                ),
              ),
              if (remainingItems > 0) ...[
                Text(
                  '$remainingItems remaining',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Complete!',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// Edit Item Dialog Widget with Calculator
class _EditItemDialog extends StatefulWidget {
  final SessionReceiptItem? item;
  final Function(String, double) onSave;

  const _EditItemDialog({
    required this.item,
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
    _nameController = TextEditingController(text: widget.item?.itemName ?? '');
    _displayPrice = widget.item?.price == 0 || widget.item == null
      ? ''
      : widget.item!.price.toStringAsFixed(2);
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
                    widget.item == null ? 'Add Item' : 'Edit Item',
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
                _buildNumberButton('.'),
                _buildNumberButton('0'),
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
