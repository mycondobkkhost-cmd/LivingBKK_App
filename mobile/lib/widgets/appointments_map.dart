import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/env.dart';
import '../models/appointment.dart';
import '../theme/app_theme.dart';
import 'listings_map.dart';
import 'osm_interactive_map.dart';

/// Map showing viewing appointments (purple) on approximate listing zones.
class AppointmentsMap extends StatefulWidget {
  const AppointmentsMap({
    super.key,
    required this.appointments,
    this.selectedId,
    this.onAppointmentTap,
    this.height = 220,
  });

  final List<Appointment> appointments;
  final String? selectedId;
  final void Function(Appointment appointment)? onAppointmentTap;
  final double height;

  @override
  State<AppointmentsMap> createState() => _AppointmentsMapState();
}

class _AppointmentsMapState extends State<AppointmentsMap> {
  GoogleMapController? _controller;

  Set<Marker> _markers() {
    final markers = <Marker>{};
    for (final a in widget.appointments) {
      if (a.lat == null || a.lng == null) continue;
      final selected = a.id == widget.selectedId;
      markers.add(
        Marker(
          markerId: MarkerId(a.id),
          position: LatLng(a.lat!, a.lng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            selected ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: a.seekerNickname,
            snippet: '${a.listingCode ?? ''} · ${a.timeSlot}',
          ),
          onTap: () => widget.onAppointmentTap?.call(a),
        ),
      );
    }
    return markers;
  }

  void _fitBounds() {
    final points = widget.appointments
        .where((a) => a.lat != null && a.lng != null)
        .map((a) => LatLng(a.lat!, a.lng!))
        .toList();
    if (points.isEmpty || _controller == null) return;

    if (points.length == 1) {
      _controller!.animateCamera(CameraUpdate.newLatLngZoom(points.first, 14));
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }
    _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.01, minLng - 0.01),
          northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
        ),
        48,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Env.hasMapsKey) {
      return OsmAppointmentsMap(
        height: widget.height,
        appointments: widget.appointments,
        selectedId: widget.selectedId,
        onAppointmentTap: widget.onAppointmentTap,
      );
    }

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: kBangkokCenter,
            zoom: 11,
          ),
          markers: _markers(),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: (c) {
            _controller = c;
            WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
          },
        ),
      ),
    );
  }
}
