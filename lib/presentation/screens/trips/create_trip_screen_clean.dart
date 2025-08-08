import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Simplified models for the clean demo
class TripMemberClean {
  final String id;
  final String name;
  final String phone;

  TripMemberClean({
    required this.id,
    required this.name,
    required this.phone,
  });

  String get formattedPhone => phone;
}

class CreateTripScreenClean extends ConsumerStatefulWidget {
  const CreateTripScreenClean({super.key});

  @override
  ConsumerState<CreateTripScreenClean> createState() => _CreateTripScreenCleanState();
}

class _CreateTripScreenCleanState extends ConsumerState<CreateTripScreenClean> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  bool _isLoading = false;

  final List<TripMemberClean> _members = [
    TripMemberClean(id: '1', name: 'John Doe', phone: '+1 234 567 8900'),
    TripMemberClean(id: '2', name: 'Jane Smith', phone: '+1 234 567 8901'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  void _addMember() {
    setState(() {
      _members.add(TripMemberClean(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'New Member ${_members.length + 1}',
        phone: '+1 234 567 89${_members.length.toString().padLeft(2, '0')}',
      ));
    });
  }

  void _removeMember(String id) {
    setState(() {
      _members.removeWhere((member) => member.id == id);
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _handleSubmit,
            icon: Icon(
              Icons.check,
              color: _isLoading ? Colors.grey : Colors.black,
              size: 24,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // Title
            const Text(
              'Create Trip',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 32),

            // Trip Name
            _buildInputField(
              label: 'Trip Name',
              controller: _nameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a trip name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Start Date
            _buildDateField(
              label: 'Start Date',
              date: _startDate,
              onTap: _selectStartDate,
            ),
            const SizedBox(height: 16),

            // End Date
            _buildDateField(
              label: 'End Date',
              date: _endDate,
              onTap: _selectEndDate,
            ),
            const SizedBox(height: 32),

            // Active Toggle
            _buildToggleField(),
            const SizedBox(height: 32),

            // Members Section
            _buildMembersSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
          fontWeight: FontWeight.w400,
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 0.5),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 0.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      validator: validator,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date == null ? label : _formatDate(date),
                style: TextStyle(
                  fontSize: 16,
                  color: date == null ? Colors.grey[600] : Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              color: Colors.grey[600],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleField() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Active',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        Switch(
          value: _isActive,
          onChanged: (value) {
            setState(() => _isActive = value);
          },
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF4CAF50), // Green color from demo
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey[300],
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Members',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),

        // Members List
        ..._members.map((member) => _buildMemberCard(member)),

        // Add Member Button
        _buildAddMemberButton(),
      ],
    );
  }

  Widget _buildMemberCard(TripMemberClean member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Avatar (black dot)
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
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
          // Link icon
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link to contacts feature')),
              );
            },
            icon: Icon(
              Icons.link,
              color: Colors.grey[600],
              size: 18,
            ),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          // Delete icon
          IconButton(
            onPressed: () => _removeMember(member.id),
            icon: Icon(
              Icons.delete_outline,
              color: Colors.grey[600],
              size: 18,
            ),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMemberButton() {
    return InkWell(
      onTap: _addMember,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.add,
              color: Colors.black,
              size: 18,
            ),
            const SizedBox(width: 12),
            const Text(
              'Add Member',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
