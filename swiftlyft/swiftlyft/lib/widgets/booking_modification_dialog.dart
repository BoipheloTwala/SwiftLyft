import 'package:flutter/material.dart';

class BookingModificationDialog extends StatefulWidget {
  final Future<bool> Function(Map<String, dynamic> changes, String? reason) onSubmit;
  final DateTime? currentPickupTime;
  final String? currentPickupAddress;
  final String? currentDropoffAddress;

  const BookingModificationDialog({
    super.key,
    required this.onSubmit,
    this.currentPickupTime,
    this.currentPickupAddress,
    this.currentDropoffAddress,
  });

  @override
  State<BookingModificationDialog> createState() => _BookingModificationDialogState();
}

class _BookingModificationDialogState extends State<BookingModificationDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _newPickupTime;
  final TextEditingController _pickupAddressController = TextEditingController();
  final TextEditingController _dropoffAddressController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentPickupAddress != null) {
      _pickupAddressController.text = widget.currentPickupAddress!;
    }
    if (widget.currentDropoffAddress != null) {
      _dropoffAddressController.text = widget.currentDropoffAddress!;
    }
  }

  @override
  void dispose() {
    _pickupAddressController.dispose();
    _dropoffAddressController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: widget.currentPickupTime ?? now.add(const Duration(hours: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.currentPickupTime ?? now.add(const Duration(hours: 2))),
    );
    if (time == null) return;
    setState(() {
      _newPickupTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });
    final changes = <String, dynamic>{};
    if (_newPickupTime != null) changes['pickupTime'] = _newPickupTime!.toIso8601String();
    if (_pickupAddressController.text.trim().isNotEmpty) changes['pickupAddress'] = _pickupAddressController.text.trim();
    if (_dropoffAddressController.text.trim().isNotEmpty) changes['dropoffAddress'] = _dropoffAddressController.text.trim();

    final ok = await widget.onSubmit(changes, _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim());
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Booking Modification'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickDateTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(_newPickupTime == null ? 'Change pickup time' : _newPickupTime!.toLocal().toString()),
                ),
              ),
              TextFormField(
                controller: _pickupAddressController,
                decoration: const InputDecoration(labelText: 'New pickup address (optional)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dropoffAddressController,
                decoration: const InputDecoration(labelText: 'New dropoff address (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'Explain the requested changes...'
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit'),
        ),
      ],
    );
  }
}


