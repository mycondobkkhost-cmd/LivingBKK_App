import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/env.dart';
import '../l10n/app_strings.dart';
import '../models/listing_public.dart';
import '../theme/app_theme.dart';
import '../utils/map_cluster_helper.dart';
import 'map_price_marker.dart';
import 'osm_interactive_map.dart';

/// Bangkok center (BTS Asok area)
const kBangkokCenter = LatLng(13.7367, 100.5608);

class ListingsMap extends StatefulWidget {
  const ListingsMap({
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
  /// เต็มจอ — ไม่มุมโค้ง (หน้าแผนที่เต็ม)
  final bool fullBleed;
  /// เปิดแผนที่แล้วเลื่อนไปตำแหน่งผู้ใช้ (Near By)
  final bool focusUserOnStart;
  final double fabBottomPadding;
  final double? pinLatitude;
  final double? pinLongitude;
  final double? radiusKm;
  final bool pinPlacementMode;
  final void Function(double lat, double lng)? onPinPlaced;

  @override
  State<ListingsMap> createState() => _ListingsMapState();
}

class _ListingsMapState extends State<ListingsMap> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  int _markerGen = 0;
  double _zoom = 12;

  bool get showPriceOnMarker => widget.showPriceOnMarker;

  @override
  void initState() {
    super.initState();
    _rebuildMarkers();
  }

  @override
  void didUpdateWidget(ListingsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listings != widget.listings ||
        oldWidget.selectedId != widget.selectedId ||
        oldWidget.showPriceOnMarker != widget.showPriceOnMarker ||
        oldWidget.pinLatitude != widget.pinLatitude ||
        oldWidget.pinLongitude != widget.pinLongitude) {
      _rebuildMarkers();
    }
    if (oldWidget.listings != widget.listings) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
  }

  Future<void> _rebuildMarkers() async {
    final s = AppStrings.of(context);
    final gen = ++_markerGen;
    final next = <Marker>{};

    final points = widget.listings
        .where((l) => l.lat != null && l.lng != null)
        .map((l) => (item: l, lat: l.lat!, lng: l.lng!))
        .toList();

    final clusters = clusterByZoom<ListingPublic>(points: points, zoom: _zoom);

    for (final cluster in clusters) {
      if (cluster.count > 1) {
        next.add(
          Marker(
            markerId: MarkerId('cluster-${cluster.center.latitude}-${cluster.center.longitude}'),
            position: LatLng(cluster.center.latitude, cluster.center.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            infoWindow: InfoWindow(
              title: s.mapListingsCount(cluster.count),
              snippet: s.mapTapToZoom,
            ),
            onTap: () => _zoomToCluster(cluster),
          ),
        );
        continue;
      }

      final l = cluster.items.first;
      final isSelected = l.id == widget.selectedId;
      final isCoAgent = l.coAgentEligible;

      BitmapDescriptor icon;
      if (showPriceOnMarker) {
        icon = await MapPriceMarker.iconFor(
          l.priceNet,
          isRent: l.listingType == 'rent',
          selected: isSelected,
          isEnglish: s.isEnglish,
        );
      } else {
        icon = BitmapDescriptor.defaultMarkerWithHue(
          isSelected
              ? BitmapDescriptor.hueViolet
              : isCoAgent
                  ? BitmapDescriptor.hueMagenta
                  : BitmapDescriptor.hueViolet,
        );
      }

      if (!mounted || gen != _markerGen) return;

      next.add(
        Marker(
          markerId: MarkerId(l.id),
          position: LatLng(l.lat!, l.lng!),
          icon: icon,
          anchor: showPriceOnMarker ? const Offset(0.5, 0.5) : const Offset(0.5, 1.0),
          infoWindow: InfoWindow(
            title: showPriceOnMarker
                ? MapPriceMarker.labelFor(
                    l.priceNet,
                    isRent: l.listingType == 'rent',
                    isEnglish: s.isEnglish,
                  )
                : l.title,
            snippet: l.projectName ?? l.district ?? '',
          ),
          onTap: () => widget.onListingTap?.call(l),
        ),
      );
    }

    if (!mounted || gen != _markerGen) return;
    setState(() => _markers = next);
  }

  Future<void> _zoomToCluster(MapCluster<ListingPublic> cluster) async {
    final targetZoom = (_zoom + 2).clamp(12.0, 16.0);
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(cluster.center.latitude, cluster.center.longitude),
        targetZoom,
      ),
    );
    setState(() => _zoom = targetZoom);
    await _rebuildMarkers();
  }

  Future<void> _onCameraIdle() async {
    final z = await _controller?.getZoomLevel();
    if (z == null || !mounted) return;
    if ((z - _zoom).abs() > 0.25) {
      setState(() => _zoom = z);
      await _rebuildMarkers();
    }
  }

  void _fitBounds() {
    final points = widget.listings
        .where((l) => l.lat != null && l.lng != null)
        .map((l) => LatLng(l.lat!, l.lng!))
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
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.008, minLng - 0.008),
          northeast: LatLng(maxLat + 0.008, maxLng + 0.008),
        ),
        40,
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).enableLocationServices)),
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
        SnackBar(content: Text(AppStrings.of(context).locationDenied)),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 14),
    );
  }

  Set<Circle> get _searchCircles {
    final lat = widget.pinLatitude;
    final lng = widget.pinLongitude;
    final km = widget.radiusKm;
    if (lat == null || lng == null || km == null) return {};
    return {
      Circle(
        circleId: const CircleId('search_pin_radius'),
        center: LatLng(lat, lng),
        radius: km * 1000,
        fillColor: AppTheme.primary.withOpacity(0.12),
        strokeColor: AppTheme.primary,
        strokeWidth: 2,
      ),
    };
  }

  Set<Marker> get _pinMarkers {
    final lat = widget.pinLatitude;
    final lng = widget.pinLongitude;
    if (lat == null || lng == null) return {};
    return {
      Marker(
        markerId: const MarkerId('search_pin'),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        zIndex: 2,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!Env.hasMapsKey) {
      return OsmListingsMap(
        listings: widget.listings,
        selectedId: widget.selectedId,
        onListingTap: widget.onListingTap,
        showPriceOnMarker: showPriceOnMarker,
        fullBleed: widget.fullBleed,
        focusUserOnStart: widget.focusUserOnStart,
        fabBottomPadding: widget.fabBottomPadding,
        pinLatitude: widget.pinLatitude,
        pinLongitude: widget.pinLongitude,
        radiusKm: widget.radiusKm,
        pinPlacementMode: widget.pinPlacementMode,
        onPinPlaced: widget.onPinPlaced,
      );
    }

    final radius = widget.fullBleed ? 0.0 : 16.0;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: kBangkokCenter,
              zoom: 12,
            ),
            markers: {..._markers, ..._pinMarkers},
            circles: _searchCircles,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) {
              _controller = c;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (widget.focusUserOnStart) {
                  _goToMyLocation();
                } else {
                  _fitBounds();
                }
              });
            },
            onCameraIdle: _onCameraIdle,
            onTap: widget.pinPlacementMode
                ? (pos) => widget.onPinPlaced?.call(pos.latitude, pos.longitude)
                : null,
          ),
        ),
        Positioned(
          right: 12,
          bottom: widget.fabBottomPadding,
          child: FloatingActionButton.small(
            heroTag: 'near_me',
            onPressed: _goToMyLocation,
            tooltip: AppStrings.of(context).searchNearByTitle,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
