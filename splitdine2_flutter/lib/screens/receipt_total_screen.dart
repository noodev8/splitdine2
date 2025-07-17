import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../services/session_provider.dart';

class ReceiptTotalScreen extends StatefulWidget {
  final Session session;

  const ReceiptTotalScreen({
    super.key,
    required this.session,
  });

  @override
  State<ReceiptTotalScreen> createState() => _ReceiptTotalScreenState();
}

class _ReceiptTotalScreenState extends State<ReceiptTotalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemsController = TextEditingController();
  final _serviceChargeController = TextEditingController();
  final _extrasController = TextEditingController();

  bool _isLoading = false;
  double _totalBill = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeValues();
    _addListeners();
  }

  void _initializeValues() {
    // Initialize with existing session values
    _itemsController.text = widget.session.itemAmount > 0
        ? widget.session.itemAmount.toStringAsFixed(2)
        : '';
    _serviceChargeController.text = widget.session.serviceCharge > 0
        ? widget.session.serviceCharge.toStringAsFixed(2)
        : '';
    _extrasController.text = widget.session.extraCharge > 0
        ? widget.session.extraCharge.toStringAsFixed(2)
        : '';
    _calculateTotal();
  }

  void _addListeners() {
    _itemsController.addListener(_calculateTotal);
    _serviceChargeController.addListener(_calculateTotal);
    _extrasController.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    final items = double.tryParse(_itemsController.text) ?? 0.0;
    final serviceCharge = double.tryParse(_serviceChargeController.text) ?? 0.0;
    final extras = double.tryParse(_extrasController.text) ?? 0.0;

    setState(() {
      _totalBill = items + serviceCharge + extras;
    });
  }

  @override
  void dispose() {
    _itemsController.dispose();
    _serviceChargeController.dispose();
    _extrasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Bill Total',
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
      body: Column(
        children: [
          // Total Section at top
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'TOTAL BILL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '£${_totalBill.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Receipt Header
                    _buildReceiptHeader(),
                    const SizedBox(height: 32),

                    // Bill Items
                    _buildBillItems(),
                    const SizedBox(height: 100), // Space for fixed button
                  ],
                ),
              ),
            ),
          ),

          // Fixed Save Button at bottom
          _buildFixedSaveButton(),
        ],
      ),
    );
  }

  Widget _buildReceiptHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            widget.session.sessionName ?? 'Unnamed Session',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.session.location,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Code: ${widget.session.joinCode}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const Divider(height: 24, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildBillItems() {
    return Column(
      children: [
        // Item Charge
        _buildCurrencyField(
          label: 'Item Charge',
          controller: _itemsController,
          hint: '0.00',
        ),
        const SizedBox(height: 16),

        // Service Charge
        _buildCurrencyField(
          label: 'Service Charge',
          controller: _serviceChargeController,
          hint: '0.00',
        ),
        const SizedBox(height: 16),

        // Extras
        _buildCurrencyField(
          label: 'Extras',
          controller: _extrasController,
          hint: '0.00',
        ),
      ],
    );
  }

  Widget _buildCurrencyField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return GestureDetector(
      onTap: () {
        _showCalculatorDialog(label, controller);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.text.isEmpty ? '£0.00' : '£${controller.text}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showCalculatorDialog(String label, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) => _CalculatorDialog(
        label: label,
        initialValue: controller.text,
        onSave: (value) {
          controller.text = value;
          _calculateTotal();
        },
      ),
    );
  }

  Widget _buildFixedSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveBillTotal,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Save Bill Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _saveBillTotal() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get values from controllers
        final itemAmount = double.tryParse(_itemsController.text) ?? 0.0;
        final serviceCharge = double.tryParse(_serviceChargeController.text) ?? 0.0;
        final extraCharge = double.tryParse(_extrasController.text) ?? 0.0;

        // Call API to update session bill totals
        final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
        final result = await sessionProvider.updateSessionBillTotals(
          sessionId: widget.session.id,
          itemAmount: itemAmount,
          taxAmount: 0.0, // Tax field removed
          serviceCharge: serviceCharge,
          extraCharge: extraCharge,
          totalAmount: _totalBill,
        );

        // Show success message but stay on screen
        if (mounted) {
          if (result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bill total saved successfully')),
            );
            // Don't navigate away - stay on the screen
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${result.errorMessage}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating bill total: $e')),
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
  }
}

// Calculator Dialog Widget
class _CalculatorDialog extends StatefulWidget {
  final String label;
  final String initialValue;
  final Function(String) onSave;

  const _CalculatorDialog({
    required this.label,
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<_CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<_CalculatorDialog> {
  String _displayValue = '';

  @override
  void initState() {
    super.initState();
    _displayValue = widget.initialValue.isEmpty ? '' : widget.initialValue;
  }

  void _onNumberTap(String number) {
    setState(() {
      if (number == '.') {
        if (!_displayValue.contains('.')) {
          _displayValue = _displayValue.isEmpty ? '0.' : '$_displayValue.';
        }
      } else {
        _displayValue += number;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_displayValue.isNotEmpty) {
        _displayValue = _displayValue.substring(0, _displayValue.length - 1);
      }
    });
  }

  void _onSave() {
    widget.onSave(_displayValue);
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
            // Field label
            Text(
              widget.label,
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
                '£${_displayValue.isEmpty ? '0.00' : _displayValue}',
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
                  },
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
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
