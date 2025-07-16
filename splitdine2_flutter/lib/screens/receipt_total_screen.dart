import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          const Text(
            'BILL BREAKDOWN',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 1.2,
            ),
          ),
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
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return null; // Optional fields
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid amount';
        }
        return null;
      },
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

        // Show success message and navigate back
        if (mounted) {
          if (result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bill total updated successfully')),
            );
            Navigator.of(context).pop();
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
