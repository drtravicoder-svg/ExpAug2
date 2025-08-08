import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'error_handler.dart';

/// Local storage service using SharedPreferences
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  /// Initialize the storage service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      if (kDebugMode) {
        print('✅ Storage service initialized');
      }
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Service Initialization',
      );
      rethrow;
    }
  }

  /// Ensure preferences are initialized
  Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      await initialize();
    }
    return _prefs!;
  }

  /// Store a string value
  Future<bool> setString(String key, String value) async {
    try {
      final prefs = await _preferences;
      final result = await prefs.setString(key, value);
      
      if (kDebugMode) {
        print('💾 Stored string: $key');
      }
      
      return result;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Set String',
        additionalData: {'key': key},
      );
      return false;
    }
  }

  /// Get a string value
  Future<String?> getString(String key, {String? defaultValue}) async {
    try {
      final prefs = await _preferences;
      return prefs.getString(key) ?? defaultValue;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Get String',
        additionalData: {'key': key},
      );
      return defaultValue;
    }
  }

  /// Store an integer value
  Future<bool> setInt(String key, int value) async {
    try {
      final prefs = await _preferences;
      final result = await prefs.setInt(key, value);
      
      if (kDebugMode) {
        print('💾 Stored int: $key = $value');
      }
      
      return result;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Set Int',
        additionalData: {'key': key, 'value': value},
      );
      return false;
    }
  }

  /// Get an integer value
  Future<int?> getInt(String key, {int? defaultValue}) async {
    try {
      final prefs = await _preferences;
      return prefs.getInt(key) ?? defaultValue;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Get Int',
        additionalData: {'key': key},
      );
      return defaultValue;
    }
  }

  /// Store a boolean value
  Future<bool> setBool(String key, bool value) async {
    try {
      final prefs = await _preferences;
      final result = await prefs.setBool(key, value);
      
      if (kDebugMode) {
        print('💾 Stored bool: $key = $value');
      }
      
      return result;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Set Bool',
        additionalData: {'key': key, 'value': value},
      );
      return false;
    }
  }

  /// Get a boolean value
  Future<bool?> getBool(String key, {bool? defaultValue}) async {
    try {
      final prefs = await _preferences;
      return prefs.getBool(key) ?? defaultValue;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Get Bool',
        additionalData: {'key': key},
      );
      return defaultValue;
    }
  }

  /// Store a double value
  Future<bool> setDouble(String key, double value) async {
    try {
      final prefs = await _preferences;
      final result = await prefs.setDouble(key, value);
      
      if (kDebugMode) {
        print('💾 Stored double: $key = $value');
      }
      
      return result;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Set Double',
        additionalData: {'key': key, 'value': value},
      );
      return false;
    }
  }

  /// Get a double value
  Future<double?> getDouble(String key, {double? defaultValue}) async {
    try {
      final prefs = await _preferences;
      return prefs.getDouble(key) ?? defaultValue;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Get Double',
        additionalData: {'key': key},
      );
      return defaultValue;
    }
  }

  /// Store a list of strings
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      final prefs = await _preferences;
      final result = await prefs.setStringList(key, value);
      
      if (kDebugMode) {
        print('💾 Stored string list: $key (${value.length} items)');
      }
      
      return result;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Set String List',
        additionalData: {'key': key, 'count': value.length},
      );
      return false;
    }
  }

  /// Get a list of strings
  Future<List<String>?> getStringList(String key, {List<String>? defaultValue}) async {
    try {
      final prefs = await _preferences;
      return prefs.getStringList(key) ?? defaultValue;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Get String List',
        additionalData: {'key': key},
      );
      return defaultValue;
    }
  }

  /// Store a JSON object
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      return await setString(key, jsonString);
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Set JSON',
        additionalData: {'key': key},
      );
      return false;
    }
  }

  /// Get a JSON object
  Future<Map<String, dynamic>?> getJson(String key, {Map<String, dynamic>? defaultValue}) async {
    try {
      final jsonString = await getString(key);
      if (jsonString == null) return defaultValue;
      
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Get JSON',
        additionalData: {'key': key},
      );
      return defaultValue;
    }
  }

  /// Remove a value
  Future<bool> remove(String key) async {
    try {
      final prefs = await _preferences;
      final result = await prefs.remove(key);
      
      if (kDebugMode) {
        print('🗑️ Removed: $key');
      }
      
      return result;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Remove',
        additionalData: {'key': key},
      );
      return false;
    }
  }

  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    try {
      final prefs = await _preferences;
      return prefs.containsKey(key);
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Contains Key',
        additionalData: {'key': key},
      );
      return false;
    }
  }

  /// Get all keys
  Future<Set<String>> getAllKeys() async {
    try {
      final prefs = await _preferences;
      return prefs.getKeys();
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Get All Keys',
      );
      return <String>{};
    }
  }

  /// Clear all data
  Future<bool> clear() async {
    try {
      final prefs = await _preferences;
      final result = await prefs.clear();
      
      if (kDebugMode) {
        print('🧹 Storage cleared');
      }
      
      return result;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Clear',
      );
      return false;
    }
  }

  /// Clear all data except specified keys
  Future<bool> clearExcept(List<String> keysToKeep) async {
    try {
      final prefs = await _preferences;
      final allKeys = prefs.getKeys();
      final keysToRemove = allKeys.where((key) => !keysToKeep.contains(key));
      
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
      
      if (kDebugMode) {
        print('🧹 Storage cleared except: $keysToKeep');
      }
      
      return true;
    } catch (error, stackTrace) {
      await ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Storage Clear Except',
        additionalData: {'keysToKeep': keysToKeep},
      );
      return false;
    }
  }
}

/// Extension for easy access to common app preferences
extension AppStorageExtension on StorageService {
  // User preferences
  Future<String?> getUserId() => getString(AppConstants.keyUserId);
  Future<bool> setUserId(String userId) => setString(AppConstants.keyUserId, userId);
  
  Future<String?> getUserEmail() => getString(AppConstants.keyUserEmail);
  Future<bool> setUserEmail(String email) => setString(AppConstants.keyUserEmail, email);
  
  Future<String?> getUserName() => getString(AppConstants.keyUserName);
  Future<bool> setUserName(String name) => setString(AppConstants.keyUserName, name);
  
  // App preferences
  Future<bool> isFirstLaunch() async => await getBool(AppConstants.keyIsFirstLaunch) ?? true;
  Future<bool> setFirstLaunchComplete() => setBool(AppConstants.keyIsFirstLaunch, false);
  
  Future<String> getThemeMode() async => await getString(AppConstants.keyThemeMode) ?? 'system';
  Future<bool> setThemeMode(String mode) => setString(AppConstants.keyThemeMode, mode);
  
  Future<String> getLanguage() async => await getString(AppConstants.keyLanguage) ?? 'en';
  Future<bool> setLanguage(String language) => setString(AppConstants.keyLanguage, language);
  
  // Feature preferences
  Future<bool> isBiometricEnabled() async => await getBool(AppConstants.keyBiometricEnabled) ?? false;
  Future<bool> setBiometricEnabled(bool enabled) => setBool(AppConstants.keyBiometricEnabled, enabled);
  
  Future<bool> areNotificationsEnabled() async => await getBool(AppConstants.keyNotificationsEnabled) ?? true;
  Future<bool> setNotificationsEnabled(bool enabled) => setBool(AppConstants.keyNotificationsEnabled, enabled);
  
  Future<bool> isOfflineModeEnabled() async => await getBool(AppConstants.keyOfflineModeEnabled) ?? true;
  Future<bool> setOfflineModeEnabled(bool enabled) => setBool(AppConstants.keyOfflineModeEnabled, enabled);
}
