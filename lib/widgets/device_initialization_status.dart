import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/device_initialization_service.dart';

class DeviceInitializationStatus extends StatefulWidget {
  final String deviceId;
  final Function(Map<String, dynamic>?)? onStatusChange;
  final EdgeInsets? padding;

  const DeviceInitializationStatus({
    Key? key,
    required this.deviceId,
    this.onStatusChange,
    this.padding,
  }) : super(key: key);

  @override
  State<DeviceInitializationStatus> createState() => _DeviceInitializationStatusState();
}

class _DeviceInitializationStatusState extends State<DeviceInitializationStatus> {
  Map<String, dynamic>? _status;
  bool _loading = true;
  String? _error;
  DateTime? _lastChecked;

  @override
  void initState() {
    super.initState();
    _checkInitializationStatus();
  }

  Future<void> _checkInitializationStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await user.getIdToken();
      if (token == null) {
        throw Exception('Failed to get auth token');
      }
      
      final status = await DeviceInitializationService.getDeviceInitializationStatus(
        widget.deviceId,
        token,
      );

      setState(() {
        _status = status;
        _lastChecked = DateTime.now();
        _loading = false;
      });

      // Notify parent about status change
      if (widget.onStatusChange != null) {
        widget.onStatusChange!(status);
      }

      // Auto-refresh if device is initializing
      if (status?['status'] == 'initializing') {
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted) {
            _checkInitializationStatus();
          }
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Widget _getStatusIcon() {
    if (_loading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
        ),
      );
    }

    switch (_status?['status']) {
      case 'ready':
        return const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 20,
        );
      case 'initializing':
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        );
      case 'offline':
        return const Icon(
          Icons.wifi_off,
          color: AppColors.error,
          size: 20,
        );
      default:
        return const Icon(
          Icons.help_outline,
          color: AppColors.textSecondary,
          size: 20,
        );
    }
  }

  Color _getStatusColor() {
    switch (_status?['status']) {
      case 'ready':
        return AppColors.success;
      case 'initializing':
        return Colors.orange;
      case 'offline':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getBackgroundColor() {
    switch (_status?['status']) {
      case 'ready':
        return AppColors.success.withOpacity(0.1);
      case 'initializing':
        return Colors.orange.withOpacity(0.1);
      case 'offline':
        return AppColors.error.withOpacity(0.1);
      default:
        return AppColors.textSecondary.withOpacity(0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        padding: widget.padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Error checking device status',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                  Text(
                    _error!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.error.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _checkInitializationStatus,
              icon: const Icon(
                Icons.refresh,
                color: AppColors.error,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: widget.padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor().withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _getStatusIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _loading 
                    ? 'Checking device status...'
                    : DeviceInitializationService.getStatusMessage(_status),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(),
                  ),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _checkInitializationStatus,
                icon: Icon(
                  Icons.refresh,
                  color: _getStatusColor(),
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          // Progress bar for initializing status
          if (_status?['status'] == 'initializing') ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: DeviceInitializationService.getInitializationProgress(_status),
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 4),
            Text(
              'Initializing... ${(DeviceInitializationService.getInitializationProgress(_status) * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor().withOpacity(0.8),
              ),
            ),
          ],

          // Device info
          if (_status != null) ...[
            const SizedBox(height: 8),
            if (_status!['network_info']?['ip_address'] != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.wifi,
                    size: 14,
                    color: _getStatusColor().withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'IP: ${_status!['network_info']['ip_address']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor().withOpacity(0.8),
                    ),
                  ),
                  if (_status!['network_info']?['rssi'] != null) ...[
                    Text(
                      ' • RSSI: ${_status!['network_info']['rssi']}dBm',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor().withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            
            if (_status!['last_seen'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: _getStatusColor().withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last seen: ${(_status!['time_since_last_seen'] ?? 0).round()}s ago',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor().withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ],

          // Last checked time
          if (_lastChecked != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last checked: ${_lastChecked!.hour.toString().padLeft(2, '0')}:${_lastChecked!.minute.toString().padLeft(2, '0')}:${_lastChecked!.second.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: _getStatusColor().withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
