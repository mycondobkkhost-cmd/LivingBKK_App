import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/env.dart';
import '../models/listing_public.dart';
import '../theme/app_theme.dart';

/// Bangkok center (BTS Asok area)
const kBangkokCenter = LatLng(13.7367, 100.5608);

class ListingsMap extends StatefulWidget {
  const ListingsMap({
    super.key,
    required this.listings,
    this.selectedId,
    this.onListingTap,
  });

  final List<ListingPublic> listings;
  final String? selectedId;
  final void Function(ListingPublic listing)? onListingTap;

  @override
  State<ListingsMap> createState() => _ListingsMapState();
}

class _ListingsMapState extends State<ListingsMap> {
  GoogleMapController? _controller;

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    for (final l in widget.listings) {
      if (l.lat == null || l.lng == null) continue;
      final isSelected = l.id == widget.selectedId;
      final isCoAgent = l.coAgentEligible;
      markers.add(
        Marker(
          markerId: MarkerId(l.id),
          position: LatLng(l.lat!, l.lng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected
                ? BitmapDescriptor.hueViolet
                : isCoAgent
                    ? BitmapDescriptor.hueMagenta
                    : BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: l.title,
            snippet: '฿${l.priceNet.toInt()}',
          ),
          onTap: () => widget.onListingTap?.call(l),
        ),
      );
    }
    return markers;
  }

  Future<void> _goToMyLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เปิด Location Services ใน Settings')),
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่ได้รับอนุญาตใช้ตำแหน่ง')),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Env.hasMapsKey) {
      return _FallbackMap(
        listings: widget.listings,
        onNearMe: _goToMyLocation,
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: kBangkokCenter,
              zoom: 12,
            ),
            markers: _buildMarkers(),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _controller = c,
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            heroTag: 'near_me',
            onPressed: _goToMyLocation,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}

class _FallbackMap extends StatelessWidget {
  const _FallbackMap({
    required this.listings,
    required this.onNearMe,
  });

  final List<ListingPublic> listings;
  final VoidCallback onNearMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 56, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(
              '${listings.length} ทรัพย์ · ใส่ GOOGLE_MAPS_API_KEY ใน assets/env',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onNearMe,
              icon: const Icon(Icons.my_location),
              label: const Text('ใกล้ฉัน'),
            ),
          ],
        ),
      ),
    );
  }
}
