import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session_provider.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sessionNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _manualTimeController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String? _selectedFoodType;
  bool _isLoading = false;
  bool _useManualTime = false;

  // Time slots in 30-minute intervals
  final List<String> _timeSlots = [
    '11:00', '11:30', '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30', '17:00', '17:30', '18:00', '18:30',
    '19:00', '19:30', '20:00', '20:30', '21:00', '21:30', '22:00', '22:30'
  ];

  // Food types
  final List<String> _foodTypes = [
    'Indian', 'Mexican', 'American', 'Italian', 'Chinese', 'Japanese',
    'Thai', 'Mediterranean', 'French', 'British', 'Korean', 'Vietnamese',
    'Greek', 'Spanish', 'Lebanese', 'Turkish', 'Other'
  ];

  @override
  void dispose() {
    _sessionNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _manualTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Create Session',
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Plan Your Dining Session',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a session to split bills with friends',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Session Name
              TextFormField(
                controller: _sessionNameController,
                decoration: const InputDecoration(
                  labelText: 'Session Name',
                  hintText: 'e.g., Birthday Dinner, Team Lunch',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              
              const SizedBox(height: 16),
              
              // Location (Required)
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  hintText: 'Restaurant name or address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Date (Required)
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                    errorText: _selectedDate == null ? 'Date is required' : null,
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select date'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: TextStyle(
                      color: _selectedDate == null ? Colors.grey.shade600 : null,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Time Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Start Time (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time slot buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _timeSlots.map((time) {
                      final isSelected = _selectedTimeSlot == time && !_useManualTime;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTimeSlot = time;
                            _useManualTime = false;
                            _manualTimeController.clear();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            time,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Manual time option
                  Row(
                    children: [
                      Checkbox(
                        value: _useManualTime,
                        onChanged: (value) {
                          setState(() {
                            _useManualTime = value ?? false;
                            if (_useManualTime) {
                              _selectedTimeSlot = null;
                            } else {
                              _manualTimeController.clear();
                            }
                          });
                        },
                      ),
                      const Text('Enter custom time'),
                    ],
                  ),

                  if (_useManualTime) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _manualTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Time',
                        hintText: 'e.g., 19:30',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      validator: (value) {
                        if (_useManualTime && (value == null || value.trim().isEmpty)) {
                          return 'Please enter a time';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 16),

              // Food Type Selection
              DropdownButtonFormField<String>(
                value: _selectedFoodType,
                decoration: const InputDecoration(
                  labelText: 'Food Type (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant),
                ),
                items: _foodTypes.map((String foodType) {
                  return DropdownMenuItem<String>(
                    value: foodType,
                    child: Text(foodType),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFoodType = newValue;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Description (Optional)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Additional details about the session',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              
              const SizedBox(height: 32),
              
              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreateSession,
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Session',
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
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }



  Future<void> _handleCreateSession() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

      // Format time as string if provided
      String? timeString;
      if (_useManualTime) {
        timeString = _manualTimeController.text.trim();
      } else if (_selectedTimeSlot != null) {
        timeString = _selectedTimeSlot;
      }

      final success = await sessionProvider.createSession(
        sessionName: _sessionNameController.text.trim().isEmpty
            ? null
            : _sessionNameController.text.trim(),
        location: _locationController.text.trim(),
        sessionDate: _selectedDate!,
        sessionTime: timeString,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        foodType: _selectedFoodType,
      );

      if (success && mounted) {
        // Get the created session to show join code
        final sessions = sessionProvider.sessions;
        final createdSession = sessions.isNotEmpty ? sessions.last : null;

        if (createdSession != null) {
          // Show success dialog with join code
          await _showSuccessDialog(createdSession);
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      } else if (mounted) {
        // Show error message
        final errorMessage = sessionProvider.errorMessage ?? 'Failed to create session';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  Future<void> _showSuccessDialog(dynamic session) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Session Created!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your session has been created successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Share this code with friends:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      session.joinCode ?? 'N/A',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'They can use this code to join your session',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
