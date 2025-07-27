// Screen for managing host permissions for a session

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitdine2_flutter/models/session.dart';
import 'package:splitdine2_flutter/services/session_service.dart';
import 'package:splitdine2_flutter/services/session_provider.dart';

class HostPermissionsScreen extends StatefulWidget {
  final Session session;

  const HostPermissionsScreen({super.key, required this.session});

  @override
  State<HostPermissionsScreen> createState() => _HostPermissionsScreenState();
}

class _HostPermissionsScreenState extends State<HostPermissionsScreen> {
  final SessionService _sessionService = SessionService();
  bool _isLoading = false;
  
  // Local state for toggles
  late bool _allowInvites;
  late bool _allowGuestsAddItems;
  late bool _allowGuestsEditPrices;
  late bool _allowGuestsEditItems;
  late bool _allowGuestsAllocate;

  @override
  void initState() {
    super.initState();
    // Initialize with current permissions
    _allowInvites = widget.session.allowInvites;
    _allowGuestsAddItems = widget.session.allowGuestsAddItems;
    _allowGuestsEditPrices = widget.session.allowGuestsEditPrices;
    _allowGuestsEditItems = widget.session.allowGuestsEditItems;
    _allowGuestsAllocate = widget.session.allowGuestsAllocate;
  }

  void _lockAllPermissions() {
    setState(() {
      _allowInvites = false;
      _allowGuestsAddItems = false;
      _allowGuestsEditPrices = false;
      _allowGuestsEditItems = false;
      _allowGuestsAllocate = false;
    });
  }

  Future<void> _updatePermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final permissions = {
        'allow_invites': _allowInvites,
        'allow_guests_add_items': _allowGuestsAddItems,
        'allow_guests_edit_prices': _allowGuestsEditPrices,
        'allow_guests_edit_items': _allowGuestsEditItems,
        'allow_guests_allocate': _allowGuestsAllocate,
      };

      await _sessionService.updatePermissions(widget.session.id, permissions);
      
      // Update the session in provider
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      final updatedSession = widget.session.copyWith(
        allowInvites: _allowInvites,
        allowGuestsAddItems: _allowGuestsAddItems,
        allowGuestsEditPrices: _allowGuestsEditPrices,
        allowGuestsEditItems: _allowGuestsEditItems,
        allowGuestsAllocate: _allowGuestsAllocate,
      );
      sessionProvider.updateCurrentSession(updatedSession);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update permissions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: icon != null
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              )
            : null,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
          ),
        ),
        trailing: Transform.scale(
          scale: 0.9,
          child: Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green.shade600,
            activeTrackColor: Colors.green.shade200,
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade200,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Session Permissions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Control what guests can do in this session. Changes take effect immediately.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Lock All button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _lockAllPermissions,
                      icon: const Icon(Icons.lock, size: 18),
                      label: const Text(
                        'Lock All Permissions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Invites section
                  Text(
                    'Invites',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  _buildPermissionTile(
                    title: 'Allow Invites',
                    subtitle: 'Guests can see the session code and invite others',
                    value: _allowInvites,
                    onChanged: (value) {
                      setState(() {
                        _allowInvites = value;
                      });
                    },
                    icon: Icons.person_add,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Receipt Items section
                  Text(
                    'Receipt Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  _buildPermissionTile(
                    title: 'Add Items',
                    subtitle: 'Guests can add new items to the receipt',
                    value: _allowGuestsAddItems,
                    onChanged: (value) {
                      setState(() {
                        _allowGuestsAddItems = value;
                      });
                    },
                    icon: Icons.add_shopping_cart,
                  ),
                  
                  _buildPermissionTile(
                    title: 'Edit Prices',
                    subtitle: 'Guests can modify item prices',
                    value: _allowGuestsEditPrices,
                    onChanged: (value) {
                      setState(() {
                        _allowGuestsEditPrices = value;
                      });
                    },
                    icon: Icons.attach_money,
                  ),
                  
                  _buildPermissionTile(
                    title: 'Edit Items',
                    subtitle: 'Guests can edit item names and toggle shared status',
                    value: _allowGuestsEditItems,
                    onChanged: (value) {
                      setState(() {
                        _allowGuestsEditItems = value;
                      });
                    },
                    icon: Icons.edit,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Allocations section
                  Text(
                    'Allocations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  _buildPermissionTile(
                    title: 'Allocate Items',
                    subtitle: 'Guests can assign items to participants',
                    value: _allowGuestsAllocate,
                    onChanged: (value) {
                      setState(() {
                        _allowGuestsAllocate = value;
                      });
                    },
                    icon: Icons.group,
                  ),
                ],
              ),
            ),
          ),
          
          // Save button at bottom
          Container(
            padding: const EdgeInsets.all(16),
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePermissions,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Permissions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}