import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../business_logic/services/offline_service.dart';
import '../../../core/utils/connectivity_service.dart';
import '../../../core/utils/formatters.dart';

/// Widget to display offline status and sync information
class OfflineStatusWidget extends ConsumerStatefulWidget {
  final OfflineService offlineService;

  const OfflineStatusWidget({
    super.key,
    required this.offlineService,
  });

  @override
  ConsumerState<OfflineStatusWidget> createState() => _OfflineStatusWidgetState();
}

class _OfflineStatusWidgetState extends ConsumerState<OfflineStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  bool _isConnected = true;
  SyncStatus _syncStatus = SyncStatus.synced;
  int _pendingOperations = 0;
  int _cacheSize = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
    _updateStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    final connectivity = ConnectivityService();
    final isConnected = await connectivity.hasConnection();
    final syncStatus = widget.offlineService.getSyncStatus();
    final pendingOps = widget.offlineService.getPendingOperationsCount();
    final cacheSize = await widget.offlineService.getCacheSize();

    if (mounted) {
      setState(() {
        _isConnected = isConnected;
        _syncStatus = syncStatus;
        _pendingOperations = pendingOps;
        _cacheSize = cacheSize;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: _showStatusDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatusColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStatusColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _syncStatus == SyncStatus.syncing ? _pulseAnimation.value : 1.0,
                  child: Icon(
                    _getStatusIcon(),
                    size: 16,
                    color: _getStatusColor(),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              _getStatusText(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_pendingOperations > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _pendingOperations.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (!_isConnected) return Colors.orange;
    
    switch (_syncStatus) {
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.pending:
        return Colors.orange;
      case SyncStatus.syncing:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    if (!_isConnected) return Icons.wifi_off;
    
    switch (_syncStatus) {
      case SyncStatus.synced:
        return Icons.cloud_done;
      case SyncStatus.pending:
        return Icons.cloud_upload;
      case SyncStatus.syncing:
        return Icons.sync;
    }
  }

  String _getStatusText() {
    if (!_isConnected) return 'Offline';
    
    switch (_syncStatus) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.syncing:
        return 'Syncing';
    }
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => _OfflineStatusDialog(
        isConnected: _isConnected,
        syncStatus: _syncStatus,
        pendingOperations: _pendingOperations,
        cacheSize: _cacheSize,
        onForceSync: _handleForceSync,
        onClearCache: _handleClearCache,
      ),
    );
  }

  Future<void> _handleForceSync() async {
    try {
      await widget.offlineService.forceSync();
      await _updateStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleClearCache() async {
    try {
      await widget.offlineService.clearCache();
      await _updateStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clear cache failed: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Dialog showing detailed offline status
class _OfflineStatusDialog extends StatelessWidget {
  final bool isConnected;
  final SyncStatus syncStatus;
  final int pendingOperations;
  final int cacheSize;
  final VoidCallback onForceSync;
  final VoidCallback onClearCache;

  const _OfflineStatusDialog({
    required this.isConnected,
    required this.syncStatus,
    required this.pendingOperations,
    required this.cacheSize,
    required this.onForceSync,
    required this.onClearCache,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Offline Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow(
            'Connection',
            isConnected ? 'Online' : 'Offline',
            isConnected ? Icons.wifi : Icons.wifi_off,
            isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            'Sync Status',
            _getSyncStatusText(),
            _getSyncStatusIcon(),
            _getSyncStatusColor(),
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            'Pending Operations',
            pendingOperations.toString(),
            Icons.pending_actions,
            pendingOperations > 0 ? Colors.orange : Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            'Cache Size',
            FileSizeFormatter.format(cacheSize),
            Icons.storage,
            theme.colorScheme.primary,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (cacheSize > 0)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onClearCache();
            },
            child: const Text('Clear Cache'),
          ),
        if (isConnected && pendingOperations > 0)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onForceSync();
            },
            child: const Text('Force Sync'),
          ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getSyncStatusText() {
    switch (syncStatus) {
      case SyncStatus.synced:
        return 'All synced';
      case SyncStatus.pending:
        return 'Pending sync';
      case SyncStatus.syncing:
        return 'Syncing...';
    }
  }

  IconData _getSyncStatusIcon() {
    switch (syncStatus) {
      case SyncStatus.synced:
        return Icons.cloud_done;
      case SyncStatus.pending:
        return Icons.cloud_upload;
      case SyncStatus.syncing:
        return Icons.sync;
    }
  }

  Color _getSyncStatusColor() {
    switch (syncStatus) {
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.pending:
        return Colors.orange;
      case SyncStatus.syncing:
        return Colors.blue;
    }
  }
}

/// File size formatter extension
class FileSizeFormatter {
  static String format(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
