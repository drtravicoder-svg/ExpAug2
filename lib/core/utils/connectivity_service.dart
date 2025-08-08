import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network connectivity status
enum ConnectivityStatus {
  online,
  offline,
  unknown,
}

/// Network connection type
enum ConnectionType {
  wifi,
  mobile,
  ethernet,
  bluetooth,
  vpn,
  other,
  none,
}

/// Connectivity service to monitor network status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityStatus> _statusController = StreamController<ConnectivityStatus>.broadcast();
  final StreamController<ConnectionType> _typeController = StreamController<ConnectionType>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  ConnectionType _currentType = ConnectionType.none;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _checkTimer;

  /// Get current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Get current connection type
  ConnectionType get currentType => _currentType;

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Stream of connection type changes
  Stream<ConnectionType> get typeStream => _typeController.stream;

  /// Check if device is currently online
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Check if device is currently offline
  bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Get initial connectivity status
      await _updateConnectivityStatus();

      // Listen to connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          if (kDebugMode) {
            print('Connectivity stream error: $error');
          }
        },
      );

      // Start periodic connectivity checks
      _startPeriodicCheck();

      if (kDebugMode) {
        print('✅ Connectivity service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize connectivity service: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _checkTimer?.cancel();
    _statusController.close();
    _typeController.close();
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _updateConnectivityStatus();
  }

  /// Update connectivity status
  Future<void> _updateConnectivityStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final newType = _mapConnectivityResult(results);
      final newStatus = await _checkInternetConnection(newType);

      if (newStatus != _currentStatus) {
        _currentStatus = newStatus;
        _statusController.add(_currentStatus);
        
        if (kDebugMode) {
          print('🌐 Connectivity status changed: $_currentStatus');
        }
      }

      if (newType != _currentType) {
        _currentType = newType;
        _typeController.add(_currentType);
        
        if (kDebugMode) {
          print('📡 Connection type changed: $_currentType');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating connectivity status: $e');
      }
    }
  }

  /// Map ConnectivityResult to ConnectionType
  ConnectionType _mapConnectivityResult(List<ConnectivityResult> results) {
    if (results.isEmpty) return ConnectionType.none;

    // Return the first (primary) connection type
    switch (results.first) {
      case ConnectivityResult.wifi:
        return ConnectionType.wifi;
      case ConnectivityResult.mobile:
        return ConnectionType.mobile;
      case ConnectivityResult.ethernet:
        return ConnectionType.ethernet;
      case ConnectivityResult.bluetooth:
        return ConnectionType.bluetooth;
      case ConnectivityResult.vpn:
        return ConnectionType.vpn;
      case ConnectivityResult.other:
        return ConnectionType.other;
      case ConnectivityResult.none:
        return ConnectionType.none;
    }
  }

  /// Check actual internet connection by pinging a reliable server
  Future<ConnectivityStatus> _checkInternetConnection(ConnectionType type) async {
    if (type == ConnectionType.none) {
      return ConnectivityStatus.offline;
    }

    try {
      // Try to connect to multiple reliable servers
      final servers = [
        'google.com',
        'cloudflare.com',
        '8.8.8.8',
      ];

      for (final server in servers) {
        try {
          final result = await InternetAddress.lookup(server).timeout(
            const Duration(seconds: 5),
          );
          
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            return ConnectivityStatus.online;
          }
        } catch (e) {
          // Continue to next server
          continue;
        }
      }

      return ConnectivityStatus.offline;
    } catch (e) {
      if (kDebugMode) {
        print('Internet connection check failed: $e');
      }
      return ConnectivityStatus.offline;
    }
  }

  /// Start periodic connectivity checks
  void _startPeriodicCheck() {
    _checkTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateConnectivityStatus(),
    );
  }

  /// Force refresh connectivity status
  Future<void> refresh() async {
    await _updateConnectivityStatus();
  }

  /// Wait for internet connection
  Future<void> waitForConnection({Duration? timeout}) async {
    if (isOnline) return;

    final completer = Completer<void>();
    late StreamSubscription<ConnectivityStatus> subscription;

    subscription = statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    // Set timeout if provided
    if (timeout != null) {
      Timer(timeout, () {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Connection timeout', timeout));
        }
      });
    }

    return completer.future;
  }

  /// Check if connection is metered (mobile data)
  bool get isMeteredConnection => _currentType == ConnectionType.mobile;

  /// Check if connection is fast (WiFi or Ethernet)
  bool get isFastConnection => 
      _currentType == ConnectionType.wifi || 
      _currentType == ConnectionType.ethernet;

  /// Get connection quality description
  String get connectionDescription {
    switch (_currentType) {
      case ConnectionType.wifi:
        return 'Connected via WiFi';
      case ConnectionType.mobile:
        return 'Connected via Mobile Data';
      case ConnectionType.ethernet:
        return 'Connected via Ethernet';
      case ConnectionType.bluetooth:
        return 'Connected via Bluetooth';
      case ConnectionType.vpn:
        return 'Connected via VPN';
      case ConnectionType.other:
        return 'Connected via Other';
      case ConnectionType.none:
        return 'No Connection';
    }
  }

  /// Get connection icon name
  String get connectionIcon {
    switch (_currentType) {
      case ConnectionType.wifi:
        return 'wifi';
      case ConnectionType.mobile:
        return 'signal_cellular_4_bar';
      case ConnectionType.ethernet:
        return 'settings_ethernet';
      case ConnectionType.bluetooth:
        return 'bluetooth';
      case ConnectionType.vpn:
        return 'vpn_lock';
      case ConnectionType.other:
        return 'device_hub';
      case ConnectionType.none:
        return 'signal_cellular_off';
    }
  }
}

/// Extension for easy access to connectivity service
extension ConnectivityExtension on ConnectivityService {
  /// Execute a function only when online
  Future<T?> whenOnline<T>(Future<T> Function() action) async {
    if (isOnline) {
      return await action();
    }
    return null;
  }

  /// Execute a function with automatic retry on connection restore
  Future<T> withRetry<T>(
    Future<T> Function() action, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        if (isOffline) {
          await waitForConnection(timeout: const Duration(seconds: 30));
        }
        
        return await action();
      } catch (e) {
        attempts++;
        
        if (attempts >= maxRetries) {
          rethrow;
        }
        
        await Future.delayed(delay * attempts);
      }
    }
    
    throw Exception('Max retry attempts exceeded');
  }
}
