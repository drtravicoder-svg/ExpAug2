import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'error_handler.dart';

/// Permission types used in the app
enum AppPermission {
  camera,
  photos,
  storage,
  location,
  microphone,
  contacts,
  notification,
  biometric,
}

/// Permission status with additional context
enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  unknown,
}

/// Service to handle all app permissions
class PermissionsService {
  static final PermissionsService _instance = PermissionsService._internal();
  factory PermissionsService() => _instance;
  PermissionsService._internal();

  /// Map app permissions to system permissions
  Permission _getSystemPermission(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return Permission.camera;
      case AppPermission.photos:
        return Platform.isIOS ? Permission.photos : Permission.storage;
      case AppPermission.storage:
        return Permission.storage;
      case AppPermission.location:
        return Permission.locationWhenInUse;
      case AppPermission.microphone:
        return Permission.microphone;
      case AppPermission.contacts:
        return Permission.contacts;
      case AppPermission.notification:
        return Permission.notification;
      case AppPermission.biometric:
        return Platform.isAndroid ? Permission.systemAlertWindow : Permission.camera; // Fallback
    }
  }

  /// Convert system permission status to app permission status
  AppPermissionStatus _convertStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return AppPermissionStatus.granted;
      case PermissionStatus.denied:
        return AppPermissionStatus.denied;
      case PermissionStatus.permanentlyDenied:
        return AppPermissionStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return AppPermissionStatus.restricted;
      case PermissionStatus.limited:
        return AppPermissionStatus.limited;
      case PermissionStatus.provisional:
        return AppPermissionStatus.limited;
    }
  }

  /// Check if a permission is granted
  Future<bool> isGranted(AppPermission permission) async {
    try {
      final systemPermission = _getSystemPermission(permission);
      final status = await systemPermission.status;
      return status == PermissionStatus.granted;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Permission Check',
        additionalData: {'permission': permission.toString()},
      );
      return false;
    }
  }

  /// Get permission status
  Future<AppPermissionStatus> getStatus(AppPermission permission) async {
    try {
      final systemPermission = _getSystemPermission(permission);
      final status = await systemPermission.status;
      return _convertStatus(status);
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Permission Status',
        additionalData: {'permission': permission.toString()},
      );
      return AppPermissionStatus.unknown;
    }
  }

  /// Request a single permission
  Future<AppPermissionStatus> request(AppPermission permission) async {
    try {
      final systemPermission = _getSystemPermission(permission);
      final status = await systemPermission.request();
      
      if (kDebugMode) {
        print('🔐 Permission ${permission.toString()} status: ${status.toString()}');
      }
      
      return _convertStatus(status);
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Permission Request',
        additionalData: {'permission': permission.toString()},
      );
      return AppPermissionStatus.unknown;
    }
  }

  /// Request multiple permissions
  Future<Map<AppPermission, AppPermissionStatus>> requestMultiple(
    List<AppPermission> permissions,
  ) async {
    final results = <AppPermission, AppPermissionStatus>{};
    
    try {
      final systemPermissions = permissions.map(_getSystemPermission).toList();
      final statuses = await systemPermissions.request();
      
      for (int i = 0; i < permissions.length; i++) {
        final permission = permissions[i];
        final systemPermission = systemPermissions[i];
        final status = statuses[systemPermission] ?? PermissionStatus.denied;
        results[permission] = _convertStatus(status);
      }
      
      if (kDebugMode) {
        print('🔐 Multiple permissions requested: $results');
      }
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Multiple Permission Request',
        additionalData: {'permissions': permissions.toString()},
      );
      
      // Fill with unknown status on error
      for (final permission in permissions) {
        results[permission] = AppPermissionStatus.unknown;
      }
    }
    
    return results;
  }

  /// Check if permission should show rationale
  Future<bool> shouldShowRationale(AppPermission permission) async {
    try {
      final systemPermission = _getSystemPermission(permission);
      return await systemPermission.shouldShowRequestRationale;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Permission Rationale Check',
        additionalData: {'permission': permission.toString()},
      );
      return false;
    }
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Open App Settings',
      );
      return false;
    }
  }

  /// Request camera permission with rationale
  Future<bool> requestCameraPermission({String? rationale}) async {
    final status = await getStatus(AppPermission.camera);
    
    if (status == AppPermissionStatus.granted) {
      return true;
    }
    
    if (status == AppPermissionStatus.permanentlyDenied) {
      return false;
    }
    
    final requestStatus = await request(AppPermission.camera);
    return requestStatus == AppPermissionStatus.granted;
  }

  /// Request photo library permission
  Future<bool> requestPhotosPermission() async {
    final status = await getStatus(AppPermission.photos);
    
    if (status == AppPermissionStatus.granted || status == AppPermissionStatus.limited) {
      return true;
    }
    
    if (status == AppPermissionStatus.permanentlyDenied) {
      return false;
    }
    
    final requestStatus = await request(AppPermission.photos);
    return requestStatus == AppPermissionStatus.granted || 
           requestStatus == AppPermissionStatus.limited;
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await getStatus(AppPermission.location);
    
    if (status == AppPermissionStatus.granted) {
      return true;
    }
    
    if (status == AppPermissionStatus.permanentlyDenied) {
      return false;
    }
    
    final requestStatus = await request(AppPermission.location);
    return requestStatus == AppPermissionStatus.granted;
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    final status = await getStatus(AppPermission.notification);
    
    if (status == AppPermissionStatus.granted) {
      return true;
    }
    
    final requestStatus = await request(AppPermission.notification);
    return requestStatus == AppPermissionStatus.granted;
  }

  /// Request all essential permissions for the app
  Future<Map<AppPermission, bool>> requestEssentialPermissions() async {
    final permissions = [
      AppPermission.camera,
      AppPermission.photos,
      AppPermission.notification,
    ];
    
    final results = await requestMultiple(permissions);
    final boolResults = <AppPermission, bool>{};
    
    for (final entry in results.entries) {
      boolResults[entry.key] = entry.value == AppPermissionStatus.granted ||
                               entry.value == AppPermissionStatus.limited;
    }
    
    return boolResults;
  }

  /// Get permission description for UI
  String getPermissionDescription(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return 'Camera access is needed to capture expense receipts';
      case AppPermission.photos:
        return 'Photo library access is needed to select receipt images';
      case AppPermission.storage:
        return 'Storage access is needed to save and manage files';
      case AppPermission.location:
        return 'Location access is needed to tag expenses with location';
      case AppPermission.microphone:
        return 'Microphone access is needed for voice notes';
      case AppPermission.contacts:
        return 'Contacts access is needed to easily invite trip members';
      case AppPermission.notification:
        return 'Notification permission is needed to keep you updated';
      case AppPermission.biometric:
        return 'Biometric authentication is needed to secure your data';
    }
  }

  /// Get permission icon
  String getPermissionIcon(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return 'camera_alt';
      case AppPermission.photos:
        return 'photo_library';
      case AppPermission.storage:
        return 'storage';
      case AppPermission.location:
        return 'location_on';
      case AppPermission.microphone:
        return 'mic';
      case AppPermission.contacts:
        return 'contacts';
      case AppPermission.notification:
        return 'notifications';
      case AppPermission.biometric:
        return 'fingerprint';
    }
  }
}
