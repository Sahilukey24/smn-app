import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order_location_model.dart';
import '../services/location_service.dart';

/// WhatsApp-style location pin. No address typing. Share current location only.
class LocationPinWidget extends StatefulWidget {
  const LocationPinWidget({
    super.key,
    required this.orderId,
    this.locations = const [],
    this.onLocationShared,
  });

  final String orderId;
  final List<OrderLocationModel> locations;
  final VoidCallback? onLocationShared;

  @override
  State<LocationPinWidget> createState() => _LocationPinWidgetState();
}

class _LocationPinWidgetState extends State<LocationPinWidget> {
  final LocationService _locationService = LocationService();
  bool _loading = false;
  String? _error;

  Future<void> _shareMyLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied || requested == LocationPermission.deniedForever) {
          setState(() => _error = 'Location permission denied');
          setState(() => _loading = false);
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final model = await _locationService.shareLocation(
        orderId: widget.orderId,
        lat: pos.latitude,
        lng: pos.longitude,
      );
      if (model != null) {
        widget.onLocationShared?.call();
      } else {
        setState(() => _error = 'Failed to share location');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Location (pin only, no address)',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _shareMyLocation,
              icon: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
              label: const Text('Share my location'),
            ),
            if (widget.locations.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...widget.locations.map((loc) => ListTile(
                    leading: const Icon(Icons.place),
                    title: Text('${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)}'),
                    subtitle: Text(_formatTime(loc.createdAt)),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _openInMaps(loc.lat, loc.lng),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime d) {
    return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openInMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
