import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as osm;

import '../l10n/app_strings.dart';
import '../models/appointment.dart';
import '../models/listing_public.dart';
import '../theme/app_theme.dart';
import '../utils/map_cluster_helper.dart';
import 'map_price_marker.dart';

/// แผนที่ฟรี (OpenStreetMap) — ใช้เมื่อยังไม่มี GOOGLE_MAPS_API_KEY
class OsmListingsMap extends StatefulWidget {
  const OsmListingsMap({
    super.key,
    required this.listings,
    this.selectedId,
    this.onListingTap,
    this.showPriceOnMarker = false,
    this.fullBleed = false,
    this.focusUserOnStart = false,
    this.fabBottomPadding = 12,
    this.pinLatitude,
    this.pinLongitude,
    this.radiusKm,
    this.pinPlacementMode = false,
    this.onPinPlaced,
  });

  final List<ListingPublic> listings;
  final String? selectedId;
  final void Function(ListingPublic listing)? onListingTap;
  final bool showPriceOnMarker;
  final bool fullBleed;
  final bool focusUserOnStart;
  final double fabBottomPadding;
  final double? pinLatitude;
  final double? pinLongitude;
  final double? radiusKm;
  final bool pinPlacementMode;
  final void Function(double lat, double lng)? onPinPlaced;

  @override
  State<OsmListingsMap> createState() => _OsmListingsMapState();
}

class _OsmListingsMapState extends State<OsmListingsMap> {
  final _mapController = MapController();
  static const _bangkok = osm.LatLng(13.7367, 100.5608);
  double _zoom = 12;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.focusUserOnStart) {
        _goToMyLocation();
      } else {
        _fitBounds();
      }
    });
  }

  void _onMapEvent(MapEvent event) {
    final z = _mapController.camera.zoom;
    if ((z - _zoom).abs() > 0.25 && mounted) {
      setState(() => _zoom = z);
    }
  }

  void _zoomToCluster(MapCluster<ListingPublic> cluster) {
    final targetZoom = (_zoom + 2).clamp(12.0, 16.0);
    _mapController.move(cluster.center, targetZoom);
    setState(() => _zoom = targetZoom);
  }

  @override
  void didUpdateWidget(OsmListingsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listings != widget.listings ||
        oldWidget.selectedId != widget.selectedId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
  }

  void _fitBounds() {
    final points = widget.listings
        .where((l) => l.lat != null && l.lng != null)
        .map((l) => osm.LatLng(l.lat!, l.lng!))
        .toList();
    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 14);
      return;
    }

    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    final s = AppStrings.of(context);
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.enableLocationServices)),
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
        SnackBar(content: Text(s.locationDenied)),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    _mapController.move(osm.LatLng(pos.latitude, pos.longitude), 14);
  }

  List<Marker> _buildMarkers() {
    final points = widget.listings
        .where((l) => l.lat != null && l.lng != null)
        .map((l) => (item: l, lat: l.lat!, lng: l.lng!))
        .toList();

    final clusters = clusterByZoom<ListingPublic>(points: points, zoom: _zoom);
    final markers = <Marker>[];

    for (final cluster in clusters) {
      if (cluster.count > 1) {
        markers.add(
          Marker(
            point: cluster.center,
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () => _zoomToCluster(cluster),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${cluster.count}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
        continue;
      }

      final l = cluster.items.first;
      final selected = l.id == widget.selectedId;
      final label = widget.showPriceOnMarker
          ? MapPriceMarker.labelFor(
              l.priceNet,
              isRent: l.listingType == 'rent',
              isEnglish: AppStrings.of(context).isEnglish,
            )
          : l.title;

      markers.add(
        Marker(
          point: osm.LatLng(l.lat!, l.lng!),
          width: widget.showPriceOnMarker ? 72 : 28,
          height: widget.showPriceOnMarker ? 32 : 28,
          child: GestureDetector(
            onTap: () => widget.onListingTap?.call(l),
            child: widget.showPriceOnMarker
                ? Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryDark : AppTheme.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : Icon(
                    Icons.location_on,
                    color: selected ? AppTheme.primaryDark : AppTheme.primary,
                    size: 32,
                  ),
          ),
        ),
      );
    }
    final lat = widget.pinLatitude;
    final lng = widget.pinLongitude;
    if (lat != null && lng != null) {
      markers.add(
        Marker(
          point: osm.LatLng(lat, lng),
          width: 32,
          height: 32,
          child: Icon(Icons.push_pin, color: AppTheme.primary, size: 32),
        ),
      );
    }
    return markers;
  }

  List<CircleMarker> _buildCircles() {
    final lat = widget.pinLatitude;
    final lng = widget.pinLongitude;
    final km = widget.radiusKm;
    if (lat == null || lng == null || km == null) return [];
    return [
      CircleMarker(
        point: osm.LatLng(lat, lng),
        radius: km * 1000,
        color: AppTheme.primary.withOpacity(0.12),
        borderColor: AppTheme.primary,
        borderStrokeWidth: 2,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final radius = widget.fullBleed ? 0.0 : 16.0;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _bangkok,
              initialZoom: 12,
              onMapEvent: _onMapEvent,
              onTap: widget.pinPlacementMode
                  ? (_, point) => widget.onPinPlaced?.call(
                        point.latitude,
                        point.longitude,
                      )
                  : null,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.livingbkk.app',
              ),
              if (_buildCircles().isNotEmpty)
                CircleLayer(circles: _buildCircles()),
              MarkerLayer(markers: _buildMarkers()),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 8,
          top: 8,
          child: Material(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                s.osmMapFreeNote,
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: widget.fabBottomPadding,
          child: FloatingActionButton.small(
            heroTag: 'near_me_osm',
            onPressed: _goToMyLocation,
            tooltip: s.searchNearByTitle,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}

/// แผนที่นัดชม (OpenStreetMap)
class OsmAppointmentsMap extends StatefulWidget {
  const OsmAppointmentsMap({
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
  State<OsmAppointmentsMap> createState() => _OsmAppointmentsMapState();
}

class _OsmAppointmentsMapState extends State<OsmAppointmentsMap> {
  final _mapController = MapController();
  static const _bangkok = osm.LatLng(13.7367, 100.5608);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  void _fitBounds() {
    final points = widget.appointments
        .where((a) => a.lat != null && a.lng != null)
        .map((a) => osm.LatLng(a.lat!, a.lng!))
        .toList();
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 14);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];
    for (final a in widget.appointments) {
      if (a.lat == null || a.lng == null) continue;
      final selected = a.id == widget.selectedId;
      markers.add(
        Marker(
          point: osm.LatLng(a.lat!, a.lng!),
          width: 28,
          height: 28,
          child: GestureDetector(
            onTap: () => widget.onAppointmentTap?.call(a),
            child: Icon(
              Icons.location_on,
              color: selected ? AppTheme.primaryDark : AppTheme.warning,
              size: 32,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _bangkok,
            initialZoom: 11,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.livingbkk.app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}
