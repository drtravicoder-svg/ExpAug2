import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../data/models/trip.dart';
import '../../data/models/trip_member.dart';
import '../../data/repositories/trip_repository.dart';

// Enhanced Repository provider with proper disposal
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final repository = TripRepository();

  // Dispose repository when provider is disposed
  ref.onDispose(() {
    repository.dispose();
  });

  return repository;
});

// Enhanced All trips provider with real-time updates and error handling
final allTripsProvider = StreamProvider<List<Trip>>((ref) {
  final repository = ref.watch(tripRepositoryProvider);

  // Create a stream that combines initial data load with real-time updates
  return Stream.fromFuture(repository.getAllTrips())
      .asyncExpand((initialTrips) {
    return repository.tripsStream.startWith(initialTrips);
  }).handleError((error) {
    // Log error and provide empty list as fallback
    print('Error in allTripsProvider: $error');
    return <Trip>[];
  });
});

// Enhanced Active trip provider with real-time updates
final activeTripProvider = StreamProvider<Trip?>((ref) {
  final repository = ref.watch(tripRepositoryProvider);

  return repository.tripsStream
      .map((trips) => trips.where((trip) => trip.isActive).firstOrNull)
      .handleError((error) {
    print('Error in activeTripProvider: $error');
    return null;
  });
});

// Enhanced Trip by ID provider with caching
final tripByIdProvider = FutureProvider.family<Trip?, String>((ref, tripId) async {
  final repository = ref.watch(tripRepositoryProvider);

  try {
    return await repository.getTripById(tripId);
  } catch (e) {
    print('Error getting trip by ID: $e');
    return null;
  }
});

// Enhanced Trip statistics provider
final tripStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(tripRepositoryProvider);

  try {
    return await repository.getTripStats();
  } catch (e) {
    print('Error getting trip stats: $e');
    return <String, dynamic>{};
  }
});

// Search trips provider
final searchTripsProvider = FutureProvider.family<List<Trip>, String>((ref, query) async {
  if (query.trim().isEmpty) {
    return [];
  }

  final repository = ref.watch(tripRepositoryProvider);

  try {
    return await repository.searchTrips(query);
  } catch (e) {
    print('Error searching trips: $e');
    return [];
  }
});

// Trips by status provider
final tripsByStatusProvider = FutureProvider.family<List<Trip>, TripStatus>((ref, status) async {
  final repository = ref.watch(tripRepositoryProvider);

  try {
    return await repository.getTripsByStatus(status);
  } catch (e) {
    print('Error getting trips by status: $e');
    return [];
  }
});

// Enhanced Create Trip Form State with SQLite integration
class CreateTripFormState {
  final String tripName;
  final String? description;
  final String? origin;
  final String? destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final String currency;
  final List<TripMember> members;
  final bool isActive;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final double budgetAmount;
  final TripSettings settings;

  const CreateTripFormState({
    this.tripName = '',
    this.description,
    this.origin,
    this.destination,
    this.startDate,
    this.endDate,
    this.currency = 'INR',
    this.members = const [],
    this.isActive = false,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.budgetAmount = 0.0,
    this.settings = const TripSettings(),
  });

  CreateTripFormState copyWith({
    String? tripName,
    String? description,
    String? origin,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? currency,
    List<TripMember>? members,
    bool? isActive,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    double? budgetAmount,
    TripSettings? settings,
  }) {
    return CreateTripFormState(
      tripName: tripName ?? this.tripName,
      description: description ?? this.description,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currency: currency ?? this.currency,
      members: members ?? this.members,
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      settings: settings ?? this.settings,
    );
  }

  CreateTripFormState clearMessages() {
    return copyWith(
      errorMessage: null,
      successMessage: null,
    );
  }

  bool get isValid {
    return tripName.trim().isNotEmpty &&
           startDate != null &&
           endDate != null &&
           members.isNotEmpty &&
           startDate!.isBefore(endDate!) &&
           !startDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)));
  }

  bool get canSave => isValid && !isLoading && !isSaving;

  String? get validationError {
    if (tripName.trim().isEmpty) return 'Trip name is required';
    if (startDate == null) return 'Start date is required';
    if (endDate == null) return 'End date is required';
    if (members.isEmpty) return 'At least one member is required';
    if (startDate != null && endDate != null && startDate!.isAfter(endDate!)) {
      return 'Start date must be before end date';
    }
    if (startDate != null && startDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return 'Start date cannot be in the past';
    }

    // Check for duplicate phone numbers
    final phoneNumbers = members.map((m) => m.phone).toList();
    final uniquePhones = phoneNumbers.toSet();
    if (phoneNumbers.length != uniquePhones.length) {
      return 'Duplicate phone numbers are not allowed';
    }

    return null;
  }
}

// Enhanced Create Trip Form Notifier with SQLite integration
class CreateTripFormNotifier extends StateNotifier<CreateTripFormState> {
  final TripRepository _repository;

  CreateTripFormNotifier(this._repository) : super(const CreateTripFormState());

  void updateTripName(String name) {
    state = state.copyWith(tripName: name).clearMessages();
  }

  void updateDescription(String? description) {
    state = state.copyWith(description: description).clearMessages();
  }

  void updateOrigin(String? origin) {
    state = state.copyWith(origin: origin).clearMessages();
  }

  void updateDestination(String? destination) {
    state = state.copyWith(destination: destination).clearMessages();
  }

  void updateStartDate(DateTime date) {
    state = state.copyWith(startDate: date).clearMessages();
  }

  void updateEndDate(DateTime date) {
    state = state.copyWith(endDate: date).clearMessages();
  }

  void updateCurrency(String currency) {
    state = state.copyWith(currency: currency).clearMessages();
  }

  void updateBudget(double budget) {
    state = state.copyWith(budgetAmount: budget).clearMessages();
  }

  void updateSettings(TripSettings settings) {
    state = state.copyWith(settings: settings).clearMessages();
  }

  void toggleActive(bool isActive) {
    state = state.copyWith(isActive: isActive).clearMessages();
  }

  void addMember(TripMember member) {
    // Check for duplicate phone numbers
    final existingMember = state.members.where((m) => m.phone == member.phone).firstOrNull;
    if (existingMember != null) {
      state = state.copyWith(errorMessage: 'Member with phone ${member.phone} already exists');
      return;
    }

    final updatedMembers = [...state.members, member];
    state = state.copyWith(members: updatedMembers).clearMessages();
  }

  void removeMember(String memberId) {
    final updatedMembers = state.members.where((m) => m.id != memberId).toList();
    state = state.copyWith(members: updatedMembers).clearMessages();
  }

  void updateMember(TripMember updatedMember) {
    final memberIndex = state.members.indexWhere((m) => m.id == updatedMember.id);
    if (memberIndex == -1) return;

    final updatedMembers = List<TripMember>.from(state.members);
    updatedMembers[memberIndex] = updatedMember;
    state = state.copyWith(members: updatedMembers).clearMessages();
  }

  void clearMessages() {
    state = state.clearMessages();
  }

  void reset() {
    state = const CreateTripFormState();
  }

  void loadTripForEditing(Trip trip) {
    state = CreateTripFormState(
      tripName: trip.name,
      description: trip.description,
      origin: trip.origin,
      destination: trip.destination,
      startDate: trip.startDate,
      endDate: trip.endDate,
      currency: trip.currency,
      members: trip.members,
      isActive: trip.isActive,
      budgetAmount: trip.budgetAmount,
      settings: trip.settings,
    );
  }

  Future<Trip?> createTrip() async {
    // Check validation first
    final validationError = state.validationError;
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return null;
    }

    state = state.copyWith(isSaving: true).clearMessages();

    try {
      // Create the trip with all enhanced fields
      final trip = await _repository.createTrip(
        name: state.tripName,
        description: state.description,
        origin: state.origin,
        destination: state.destination,
        startDate: state.startDate!,
        endDate: state.endDate!,
        currency: state.currency,
        members: state.members,
        settings: state.settings,
        budgetAmount: state.budgetAmount,
      );

      // If the user wants it active, set it as active
      if (state.isActive) {
        await _repository.setTripActive(trip.id);
      }

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Trip created successfully!',
      );

      return trip;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().contains('TripRepositoryException')
            ? e.toString().replaceAll('TripRepositoryException: ', '')
            : 'Failed to create trip: ${e.toString()}',
      );
      return null;
    }
  }

  Future<Trip?> updateTrip(String tripId) async {
    final validationError = state.validationError;
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return null;
    }

    state = state.copyWith(isSaving: true).clearMessages();

    try {
      final existingTrip = await _repository.getTripById(tripId);
      if (existingTrip == null) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Trip not found',
        );
        return null;
      }

      final updatedTrip = existingTrip.copyWith(
        name: state.tripName,
        description: state.description,
        origin: state.origin,
        destination: state.destination,
        startDate: state.startDate,
        endDate: state.endDate,
        currency: state.currency,
        members: state.members,
        settings: state.settings,
        budgetAmount: state.budgetAmount,
      );

      final result = await _repository.updateTrip(updatedTrip);

      // Handle status change if needed
      if (state.isActive != existingTrip.isActive) {
        if (state.isActive) {
          await _repository.setTripActive(tripId);
        } else {
          await _repository.toggleTripStatus(tripId);
        }
      }

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Trip updated successfully!',
      );

      return result;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().contains('TripRepositoryException')
            ? e.toString().replaceAll('TripRepositoryException: ', '')
            : 'Failed to update trip: ${e.toString()}',
      );
      return null;
    }
  }
}

// Create Trip Form Provider
final createTripFormProvider = StateNotifierProvider<CreateTripFormNotifier, CreateTripFormState>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return CreateTripFormNotifier(repository);
});

// Enhanced Add Member Form State
class AddMemberFormState {
  final String name;
  final String phone;
  final String? email;
  final bool isFromContacts;
  final String? contactId;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AddMemberFormState({
    this.name = '',
    this.phone = '',
    this.email,
    this.isFromContacts = false,
    this.contactId,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  AddMemberFormState copyWith({
    String? name,
    String? phone,
    String? email,
    bool? isFromContacts,
    String? contactId,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return AddMemberFormState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isFromContacts: isFromContacts ?? this.isFromContacts,
      contactId: contactId ?? this.contactId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  AddMemberFormState clearMessages() {
    return copyWith(
      errorMessage: null,
      successMessage: null,
    );
  }

  bool get isValid {
    return name.trim().isNotEmpty &&
           phone.trim().isNotEmpty &&
           phone.trim().length >= 10;
  }

  String? get validationError {
    if (name.trim().isEmpty) return 'Name is required';
    if (phone.trim().isEmpty) return 'Phone number is required';
    if (phone.trim().length < 10) return 'Phone number must be at least 10 digits';
    return null;
  }
}

// Enhanced Add Member Form Notifier
class AddMemberFormNotifier extends StateNotifier<AddMemberFormState> {
  final TripRepository _repository;

  AddMemberFormNotifier(this._repository) : super(const AddMemberFormState());

  void updateName(String name) {
    state = state.copyWith(name: name).clearMessages();
  }

  void updatePhone(String phone) {
    state = state.copyWith(phone: phone).clearMessages();
  }

  void updateEmail(String? email) {
    state = state.copyWith(email: email).clearMessages();
  }

  void setFromContacts({
    required String name,
    required String phone,
    String? email,
    required String contactId,
  }) {
    state = state.copyWith(
      name: name,
      phone: phone,
      email: email,
      contactId: contactId,
      isFromContacts: true,
    ).clearMessages();
  }

  void clearMessages() {
    state = state.clearMessages();
  }

  void reset() {
    state = const AddMemberFormState();
  }

  TripMember? createMember() {
    final validationError = state.validationError;
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return null;
    }

    try {
      final member = state.isFromContacts
          ? _repository.createMemberFromContact(
              name: state.name.trim(),
              phone: state.phone.trim(),
              email: state.email?.trim(),
              contactId: state.contactId!,
            )
          : _repository.createMember(
              name: state.name.trim(),
              phone: state.phone.trim(),
              email: state.email?.trim(),
            );

      state = state.copyWith(successMessage: 'Member added successfully!');
      return member;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().contains('TripRepositoryException')
            ? e.toString().replaceAll('TripRepositoryException: ', '')
            : 'Failed to create member: ${e.toString()}',
      );
      return null;
    }
  }
}

// Add Member Form Provider
final addMemberFormProvider = StateNotifierProvider<AddMemberFormNotifier, AddMemberFormState>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return AddMemberFormNotifier(repository);
});

// Enhanced Trip Actions Provider with comprehensive operations
final tripActionsProvider = Provider<TripActions>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return TripActions(repository, ref);
});

class TripActions {
  final TripRepository _repository;
  final Ref _ref;

  TripActions(this._repository, this._ref);

  Future<Trip?> toggleTripStatus(String tripId) async {
    try {
      final result = await _repository.toggleTripStatus(tripId);
      _refreshProviders();
      return result;
    } catch (e) {
      print('Error toggling trip status: $e');
      return null;
    }
  }

  Future<bool> deleteTrip(String tripId) async {
    try {
      await _repository.deleteTrip(tripId);
      _refreshProviders();
      return true;
    } catch (e) {
      print('Error deleting trip: $e');
      return false;
    }
  }

  Future<bool> permanentlyDeleteTrip(String tripId) async {
    try {
      await _repository.permanentlyDeleteTrip(tripId);
      _refreshProviders();
      return true;
    } catch (e) {
      print('Error permanently deleting trip: $e');
      return false;
    }
  }

  Future<Trip?> restoreTrip(String tripId) async {
    try {
      final result = await _repository.restoreTrip(tripId);
      _refreshProviders();
      return result;
    } catch (e) {
      print('Error restoring trip: $e');
      return null;
    }
  }

  Future<Trip?> addMemberToTrip(String tripId, TripMember member) async {
    try {
      final result = await _repository.addMemberToTrip(tripId, member);
      _refreshProviders();
      return result;
    } catch (e) {
      print('Error adding member to trip: $e');
      return null;
    }
  }

  Future<Trip?> removeMemberFromTrip(String tripId, String memberId) async {
    try {
      final result = await _repository.removeMemberFromTrip(tripId, memberId);
      _refreshProviders();
      return result;
    } catch (e) {
      print('Error removing member from trip: $e');
      return null;
    }
  }

  Future<Trip?> updateMemberInTrip(String tripId, TripMember member) async {
    try {
      final result = await _repository.updateMemberInTrip(tripId, member);
      _refreshProviders();
      return result;
    } catch (e) {
      print('Error updating member in trip: $e');
      return null;
    }
  }

  Future<String?> backupDatabase() async {
    try {
      return await _repository.backupDatabase();
    } catch (e) {
      print('Error backing up database: $e');
      return null;
    }
  }

  Future<void> clearCache() async {
    await _repository.clearCache();
    _refreshProviders();
  }

  void _refreshProviders() {
    _ref.invalidate(allTripsProvider);
    _ref.invalidate(activeTripProvider);
    _ref.invalidate(tripStatsProvider);
  }
}

// Database status provider
final databaseStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(tripRepositoryProvider);

  try {
    final stats = repository.getDatabaseStats();
    final tripStats = await repository.getTripStats();

    return {
      'database': stats,
      'trips': tripStats,
      'cacheAge': repository.cacheAgeInMinutes,
      'hasCachedData': repository.hasCachedData,
    };
  } catch (e) {
    print('Error getting database status: $e');
    return <String, dynamic>{};
  }
});

// Extension for stream utilities
extension StreamExtensions<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
