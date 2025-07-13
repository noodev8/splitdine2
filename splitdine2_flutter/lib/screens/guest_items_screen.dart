import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../models/receipt_item.dart';
import '../models/participant.dart';
import '../services/receipt_provider.dart';
import '../services/session_provider.dart';
import '../services/auth_provider.dart';

class GuestItemsScreen extends StatefulWidget {
  final Session session;

  const GuestItemsScreen({
    super.key,
    required this.session,
  });

  @override
  State<GuestItemsScreen> createState() => _GuestItemsScreenState();
}

class _GuestItemsScreenState extends State<GuestItemsScreen> {
  List<Participant> _participants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

      // Load items and participants
      await Future.wait([
        receiptProvider.loadItems(widget.session.id),
        sessionProvider.loadParticipants(widget.session.id),
      ]);

      if (mounted) {
        setState(() {
          _participants = sessionProvider.participants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<ReceiptItem> _getItemsForParticipant(int userId) {
    final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
    return receiptProvider.items.where((item) => item.addedByUserId == userId).toList();
  }

  double _getTotalForParticipant(int userId) {
    final items = _getItemsForParticipant(userId);
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Very light gray background
      body: Stack(
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
                          'Guest Items',
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
                      IconButton(
                        onPressed: _loadData,
                        icon: const Icon(
                          Icons.refresh,
                          color: Color(0xFF4E4B47), // Warm Gray-700
                        ),
                      ),
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
                      const Icon(
                        Icons.people,
                        size: 48,
                        color: Color(0xFFFFC629), // Sunshine Yellow
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.session.displayName,
                        style: const TextStyle(
                          fontFamily: 'GoogleSans',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4E4B47), // Warm Gray-700
                          letterSpacing: -0.02,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Individual guest totals and items',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          color: const Color(0xFF4E4B47).withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC629)),
                          ),
                        )
                      : _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFF04438), // Tomato Red
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 16,
                                      color: Color(0xFFF04438), // Tomato Red
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadData,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFC629), // Sunshine Yellow
                                      foregroundColor: const Color(0xFF4E4B47), // OnPrimary
                                    ),
                                    child: const Text(
                                      'Retry',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _participants.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 64,
                                        color: Color(0xFF4E4B47),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No participants found',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 18,
                                          color: Color(0xFF4E4B47),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _buildParticipantsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: _participants.length,
      itemBuilder: (context, index) {
        final participant = _participants[index];
        final items = _getItemsForParticipant(participant.userId);
        final total = _getTotalForParticipant(participant.userId);
        final isOrganizer = participant.userId == widget.session.organizerId;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                spreadRadius: 0,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Participant header with total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC629).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFFFC629), // Sunshine Yellow
                      child: Text(
                        participant.displayName.isNotEmpty 
                            ? participant.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontFamily: 'GoogleSans',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4E4B47),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                participant.displayName,
                                style: const TextStyle(
                                  fontFamily: 'GoogleSans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4E4B47),
                                ),
                              ),
                              if (isOrganizer) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFC629), // Sunshine Yellow
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'HOST',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4E4B47),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${items.length} item${items.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              color: const Color(0xFF4E4B47).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '£${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'GoogleSans',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4E4B47),
                          ),
                        ),
                        Text(
                          'Total',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: const Color(0xFF4E4B47).withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Items list
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: items.map((item) => _buildItemTile(item)).toList(),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No items added yet',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: const Color(0xFF4E4B47).withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemTile(ReceiptItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFECE9E6),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4E4B47),
                  ),
                ),
                if (item.share != null && item.share!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Shared with ${item.share}',
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
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '£${(item.price * item.quantity).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4E4B47),
                ),
              ),
              if (item.quantity > 1)
                Text(
                  'x${item.quantity}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: const Color(0xFF4E4B47).withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
