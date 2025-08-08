import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../business_logic/providers/trip_providers.dart';
import '../../data/models/trip_member.dart';
import '../../data/models/trip.dart';
import '../widgets/add_member_dialog.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  final String? tripId; // For editing existing trips

  const CreateTripScreen({super.key, this.tripId});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Load trip data if editing
    if (widget.tripId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTripForEditing();
      });
    }
  }

  Future<void> _loadTripForEditing() async {
    if (widget.tripId == null) return;

    try {
      final trip = await ref.read(tripRepositoryProvider).getTripById(widget.tripId!);
      if (trip != null) {
        ref.read(createTripFormProvider.notifier).loadTripForEditing(trip);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trip: $e')),
        );
      }
    }
    setState(() => _isInitialized = true);
  }

  bool get isEditing => widget.tripId != null;
  String get screenTitle => isEditing ? 'Edit Trip' : 'Create Trip';

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(createTripFormProvider);
    final formNotifier = ref.read(createTripFormProvider.notifier);

    // Show loading indicator while initializing for edit mode
    if (isEditing && !_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(screenTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: formState.isSaving ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          if (formState.isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: Colors.black87),
              onPressed: formState.canSave
                  ? () => _saveTrip(context, ref, formNotifier)
                  : null,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              screenTitle,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle with validation status
            if (formState.validationError != null)
              Text(
                formState.validationError!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[600],
                ),
              )
            else if (formState.isValid)
              Text(
                'Ready to ${isEditing ? 'update' : 'create'} trip',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[600],
                ),
              ),
            const SizedBox(height: 32),

            // Error/Success Messages
            if (formState.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formState.errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: formNotifier.clearMessages,
                      color: Colors.red[600],
                    ),
                  ],
                ),
              ),

            if (formState.successMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formState.successMessage!,
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: formNotifier.clearMessages,
                      color: Colors.green[600],
                    ),
                  ],
                ),
              ),

            // Trip Name Field
            _buildTextField(
              label: 'Trip Name *',
              value: formState.tripName,
              onChanged: formNotifier.updateTripName,
              enabled: !formState.isSaving,
            ),
            const SizedBox(height: 24),

            // Description Field
            _buildTextField(
              label: 'Description',
              value: formState.description ?? '',
              onChanged: formNotifier.updateDescription,
              enabled: !formState.isSaving,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Origin and Destination Row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Origin',
                    value: formState.origin ?? '',
                    onChanged: formNotifier.updateOrigin,
                    enabled: !formState.isSaving,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Destination',
                    value: formState.destination ?? '',
                    onChanged: formNotifier.updateDestination,
                    enabled: !formState.isSaving,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Start Date Field
            _buildDateField(
              context: context,
              label: 'Start Date *',
              value: formState.startDate,
              onChanged: formNotifier.updateStartDate,
              enabled: !formState.isSaving,
            ),
            const SizedBox(height: 24),

            // End Date Field
            _buildDateField(
              context: context,
              label: 'End Date *',
              value: formState.endDate,
              onChanged: formNotifier.updateEndDate,
              enabled: !formState.isSaving,
            ),
            const SizedBox(height: 24),

            // Currency and Budget Row
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildDropdownField(
                    label: 'Currency',
                    value: formState.currency,
                    items: const ['INR', 'USD', 'EUR', 'GBP'],
                    onChanged: formNotifier.updateCurrency,
                    enabled: !formState.isSaving,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    label: 'Budget (Optional)',
                    value: formState.budgetAmount > 0 ? formState.budgetAmount.toString() : '',
                    onChanged: (value) {
                      final budget = double.tryParse(value) ?? 0.0;
                      formNotifier.updateBudget(budget);
                    },
                    enabled: !formState.isSaving,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Active Toggle with explanation
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Set as Active Trip',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Switch(
                        value: formState.isActive,
                        onChanged: formState.isSaving ? null : formNotifier.toggleActive,
                        activeColor: Colors.white,
                        activeTrackColor: Colors.green,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[300],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only one trip can be active at a time. Active trips appear first in your list.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Members Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Members',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${formState.members.length} member${formState.members.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Members List or Empty State
            if (formState.members.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No members added yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add at least one member to create the trip',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...formState.members.map((member) => _buildMemberTile(
                member: member,
                onRemove: formState.isSaving ? null : () => formNotifier.removeMember(member.id),
              )),

            // Add Member Button
            const SizedBox(height: 16),
            _buildAddMemberButton(context, ref, formNotifier, enabled: !formState.isSaving),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: enabled ? Colors.black54 : Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.fromPosition(TextPosition(offset: value.length)),
          onChanged: enabled ? onChanged : null,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
            disabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          style: TextStyle(
            fontSize: 16,
            color: enabled ? Colors.black87 : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: enabled ? Colors.black54 : Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: enabled ? (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          } : null,
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
          decoration: InputDecoration(
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
            disabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          style: TextStyle(
            fontSize: 16,
            color: enabled ? Colors.black87 : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: enabled ? Colors.black54 : Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled ? () => _selectDate(context, value, onChanged) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value != null
                      ? DateFormat('MMM dd, yyyy').format(value)
                      : '',
                  style: const TextStyle(fontSize: 16),
                ),
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberTile({
    required TripMember member,
    required VoidCallback? onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Member Icon
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.black87,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          
          // Member Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  member.formattedPhone,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.link, color: Colors.grey[600]),
                onPressed: () {
                  // TODO: Implement contact linking
                },
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: onRemove != null ? Colors.grey[600] : Colors.grey[300]),
                onPressed: onRemove,
                tooltip: onRemove != null ? 'Remove member' : 'Cannot remove while saving',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddMemberButton(
    BuildContext context,
    WidgetRef ref,
    CreateTripFormNotifier formNotifier, {
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? () => _showAddMemberDialog(context, ref, formNotifier) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: enabled ? Colors.blue[50] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: enabled ? Colors.blue[600] : Colors.grey[400],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Add Member',
              style: TextStyle(
                fontSize: 16,
                color: enabled ? Colors.grey[700] : Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, DateTime? currentDate, ValueChanged<DateTime> onChanged) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  Future<void> _showAddMemberDialog(BuildContext context, WidgetRef ref, CreateTripFormNotifier formNotifier) async {
    final member = await showDialog<TripMember>(
      context: context,
      builder: (context) => const AddMemberDialog(),
    );
    
    if (member != null) {
      formNotifier.addMember(member);
    }
  }

  Future<void> _saveTrip(BuildContext context, WidgetRef ref, CreateTripFormNotifier formNotifier) async {
    // Clear any existing messages
    formNotifier.clearMessages();

    try {
      final trip = isEditing
          ? await formNotifier.updateTrip(widget.tripId!)
          : await formNotifier.createTrip();

      if (trip != null) {
        // Refresh the trips list
        ref.invalidate(allTripsProvider);
        ref.invalidate(activeTripProvider);
        ref.invalidate(tripStatsProvider);

        // Show success message and navigate back
        if (context.mounted) {
          final message = isEditing
              ? 'Trip "${trip.name}" updated successfully!'
              : 'Trip "${trip.name}" created successfully!';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(message)),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          // Navigate back after a short delay to show the success message
          await Future.delayed(const Duration(milliseconds: 500));
          if (context.mounted) {
            Navigator.of(context).pop(trip);
          }
        }
      }
    } catch (e) {
      // Error handling is already done in the form notifier
      // The error message will be displayed in the UI
      print('Error saving trip: $e');
    }
  }
}
