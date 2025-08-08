import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../business_logic/providers/trip_providers.dart';
import '../../data/models/trip_member.dart';

class AddMemberDialog extends ConsumerStatefulWidget {
  const AddMemberDialog({super.key});

  @override
  ConsumerState<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<AddMemberDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(addMemberFormProvider);
    final formNotifier = ref.read(addMemberFormProvider.notifier);

    // Update controllers when state changes
    if (_nameController.text != formState.name) {
      _nameController.text = formState.name;
    }
    if (_phoneController.text != formState.phone) {
      _phoneController.text = formState.phone;
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Add Member',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
                onChanged: formNotifier.updateName,
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '1234567890',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.length != 10) {
                    return 'Phone number must be 10 digits';
                  }
                  return null;
                },
                onChanged: formNotifier.updatePhone,
              ),

              // Error Message
              if (formState.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formState.errorMessage!,
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Contact Picker Button
              OutlinedButton.icon(
                onPressed: () => _pickFromContacts(context, formNotifier),
                icon: const Icon(Icons.contacts_outlined),
                label: const Text('Pick from Contacts'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      formNotifier.reset();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: formState.isLoading
                        ? null
                        : () => _addMember(context, formNotifier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 40),
                    ),
                    child: formState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addMember(BuildContext context, AddMemberFormNotifier formNotifier) {
    if (_formKey.currentState?.validate() ?? false) {
      final member = formNotifier.createMember();
      if (member != null) {
        Navigator.of(context).pop(member);
      }
    }
  }

  void _pickFromContacts(BuildContext context, AddMemberFormNotifier formNotifier) {
    // TODO: Implement contact picker
    // For now, show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact picker will be implemented in the next version'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

// Contact Picker Implementation (placeholder for future)
class ContactPickerService {
  static Future<ContactInfo?> pickContact() async {
    // This would integrate with the device's contact picker
    // For now, return null to indicate no contact was selected
    return null;
  }
}

class ContactInfo {
  final String name;
  final String phone;
  final String contactId;

  const ContactInfo({
    required this.name,
    required this.phone,
    required this.contactId,
  });
}

// Extension to create TripMember from ContactInfo
extension ContactInfoExtension on ContactInfo {
  TripMember toTripMember() {
    return TripMember.create(
      name: name,
      phone: phone.replaceAll(RegExp(r'[^\d]'), ''), // Remove non-digits
      contactId: contactId,
      isFromContacts: true,
    );
  }
}
