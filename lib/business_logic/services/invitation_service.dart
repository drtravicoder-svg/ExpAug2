import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/firebase_config.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/error_handler.dart';
import '../../data/models/user.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/trip_repository.dart';

/// Invitation types
enum InvitationType {
  email,
  whatsapp,
  sms,
  link,
}

/// Invitation status
enum InvitationStatus {
  pending,
  accepted,
  declined,
  expired,
}

/// Member invitation model
class MemberInvitation {
  final String id;
  final String tripId;
  final String invitedBy;
  final String invitedEmail;
  final String? invitedPhone;
  final String invitedName;
  final InvitationType type;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? acceptedAt;
  final String magicLink;

  const MemberInvitation({
    required this.id,
    required this.tripId,
    required this.invitedBy,
    required this.invitedEmail,
    this.invitedPhone,
    required this.invitedName,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.acceptedAt,
    required this.magicLink,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'tripId': tripId,
    'invitedBy': invitedBy,
    'invitedEmail': invitedEmail,
    'invitedPhone': invitedPhone,
    'invitedName': invitedName,
    'type': type.toString(),
    'status': status.toString(),
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'acceptedAt': acceptedAt,
    'magicLink': magicLink,
  };

  factory MemberInvitation.fromJson(Map<String, dynamic> json) => MemberInvitation(
    id: json['id'],
    tripId: json['tripId'],
    invitedBy: json['invitedBy'],
    invitedEmail: json['invitedEmail'],
    invitedPhone: json['invitedPhone'],
    invitedName: json['invitedName'],
    type: InvitationType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => InvitationType.email,
    ),
    status: InvitationStatus.values.firstWhere(
      (e) => e.toString() == json['status'],
      orElse: () => InvitationStatus.pending,
    ),
    createdAt: DateTime.parse(json['createdAt']),
    expiresAt: DateTime.parse(json['expiresAt']),
    acceptedAt: json['acceptedAt'],
    magicLink: json['magicLink'],
  );
}

/// Service for managing member invitations
class InvitationService {
  final UserRepository _userRepository;
  final TripRepository _tripRepository;
  final Uuid _uuid;

  InvitationService({
    UserRepository? userRepository,
    TripRepository? tripRepository,
    Uuid? uuid,
  })  : _userRepository = userRepository ?? UserRepository(),
        _tripRepository = tripRepository ?? TripRepository(),
        _uuid = uuid ?? const Uuid();

  /// Generate magic link for invitation
  String _generateMagicLink(String invitationId) {
    final baseUrl = EnvironmentConfig.apiBaseUrl;
    return '$baseUrl/invite/$invitationId';
  }

  /// Generate invitation code
  String _generateInvitationCode() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Create member invitation
  Future<MemberInvitation> createInvitation({
    required String tripId,
    required String invitedBy,
    required String invitedEmail,
    String? invitedPhone,
    required String invitedName,
    required InvitationType type,
  }) async {
    try {
      final invitationId = _uuid.v4();
      final magicLink = _generateMagicLink(invitationId);
      
      final invitation = MemberInvitation(
        id: invitationId,
        tripId: tripId,
        invitedBy: invitedBy,
        invitedEmail: invitedEmail,
        invitedPhone: invitedPhone,
        invitedName: invitedName,
        type: type,
        status: InvitationStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)), // 7 days expiry
        magicLink: magicLink,
      );

      // Store invitation in Firestore
      // TODO: Implement invitation storage in Firestore
      
      // Log analytics event
      await FirebaseConfig.logEvent(
        FirebaseConstants.eventMemberInvited,
        {
          'trip_id': tripId,
          'invitation_type': type.toString(),
          'invited_by': invitedBy,
        },
      );

      return invitation;
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Send invitation via email
  Future<void> sendEmailInvitation({
    required MemberInvitation invitation,
    required Trip trip,
    required User inviter,
  }) async {
    try {
      final subject = 'You\'re invited to join "${trip.name}" trip!';
      final body = _buildEmailBody(invitation, trip, inviter);
      
      final emailUri = Uri(
        scheme: 'mailto',
        path: invitation.invitedEmail,
        query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Send invitation via WhatsApp
  Future<void> sendWhatsAppInvitation({
    required MemberInvitation invitation,
    required Trip trip,
    required User inviter,
  }) async {
    try {
      if (invitation.invitedPhone == null) {
        throw Exception('Phone number is required for WhatsApp invitation');
      }

      final message = _buildWhatsAppMessage(invitation, trip, inviter);
      final phoneNumber = invitation.invitedPhone!.replaceAll(RegExp(r'[^\d+]'), '');
      
      final whatsappUri = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Send invitation via SMS
  Future<void> sendSMSInvitation({
    required MemberInvitation invitation,
    required Trip trip,
    required User inviter,
  }) async {
    try {
      if (invitation.invitedPhone == null) {
        throw Exception('Phone number is required for SMS invitation');
      }

      final message = _buildSMSMessage(invitation, trip, inviter);
      final phoneNumber = invitation.invitedPhone!.replaceAll(RegExp(r'[^\d+]'), '');
      
      final smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        throw Exception('Could not launch SMS');
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Share invitation link
  Future<void> shareInvitationLink({
    required MemberInvitation invitation,
    required Trip trip,
    required User inviter,
  }) async {
    try {
      final message = _buildShareMessage(invitation, trip, inviter);
      
      await Share.share(
        message,
        subject: 'Join "${trip.name}" trip!',
      );
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Build email body
  String _buildEmailBody(MemberInvitation invitation, Trip trip, User inviter) {
    return '''
Hi ${invitation.invitedName},

${inviter.displayName} has invited you to join the "${trip.name}" trip!

Trip Details:
📍 Destination: ${trip.destination}
📅 Dates: ${trip.startDate.toString().split(' ')[0]} - ${trip.endDate.toString().split(' ')[0]}
👥 Members: ${trip.memberCount} people

Join the trip to:
• Track shared expenses
• Split costs fairly
• Stay organized with receipts
• Get real-time updates

Click here to join: ${invitation.magicLink}

This invitation expires on ${invitation.expiresAt.toString().split(' ')[0]}.

Happy travels!
The ${AppConfig.appName} Team
''';
  }

  /// Build WhatsApp message
  String _buildWhatsAppMessage(MemberInvitation invitation, Trip trip, User inviter) {
    return '''
🎉 You're invited to join "${trip.name}" trip!

Hi ${invitation.invitedName}! ${inviter.displayName} has invited you to join their trip.

📍 ${trip.destination}
📅 ${trip.startDate.toString().split(' ')[0]} - ${trip.endDate.toString().split(' ')[0]}

Join here: ${invitation.magicLink}

Track expenses, split costs, and stay organized! 💰
''';
  }

  /// Build SMS message
  String _buildSMSMessage(MemberInvitation invitation, Trip trip, User inviter) {
    return '''
${inviter.displayName} invited you to join "${trip.name}" trip (${trip.destination}). Join: ${invitation.magicLink}
''';
  }

  /// Build share message
  String _buildShareMessage(MemberInvitation invitation, Trip trip, User inviter) {
    return '''
🎉 Join "${trip.name}" trip!

${inviter.displayName} has invited you to join their trip to ${trip.destination}.

📅 ${trip.startDate.toString().split(' ')[0]} - ${trip.endDate.toString().split(' ')[0]}

Join here: ${invitation.magicLink}

Track expenses and split costs easily with ${AppConfig.appName}!
''';
  }

  /// Accept invitation
  Future<User> acceptInvitation(String invitationId) async {
    try {
      // TODO: Implement invitation acceptance logic
      // 1. Validate invitation exists and is not expired
      // 2. Create user account if doesn't exist
      // 3. Add user to trip
      // 4. Update invitation status
      
      throw UnimplementedError('Invitation acceptance not yet implemented');
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Decline invitation
  Future<void> declineInvitation(String invitationId) async {
    try {
      // TODO: Implement invitation decline logic
      throw UnimplementedError('Invitation decline not yet implemented');
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get pending invitations for a trip
  Future<List<MemberInvitation>> getPendingInvitations(String tripId) async {
    try {
      // TODO: Implement get pending invitations
      throw UnimplementedError('Get pending invitations not yet implemented');
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Cancel invitation
  Future<void> cancelInvitation(String invitationId) async {
    try {
      // TODO: Implement invitation cancellation
      throw UnimplementedError('Cancel invitation not yet implemented');
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Resend invitation
  Future<void> resendInvitation(String invitationId) async {
    try {
      // TODO: Implement invitation resend
      throw UnimplementedError('Resend invitation not yet implemented');
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }
}
