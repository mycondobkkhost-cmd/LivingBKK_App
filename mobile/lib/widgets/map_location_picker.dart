import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/env.dart';
import '../l10n/app_strings.dart';
import '../services/places_service.dart';
import '../theme/google_map_dark_style.dart';
import '../theme/living_bkk_brand.dart';
import '../utils/google_maps_web_auth.dart';
import '../utils/page_safe_insets.dart';
import 'listings_map.dart';
import 'osm_interactive_map.dart';

/// สีเขียวโทนหน้าเลือกตำแหน่ง (ตาม UI อ้างอิง)
const _pickerGreen = Color(0xFF2EB872);
const _infoBannerBg = Color(0xFFE8F0FE);
const _infoBannerFg = Color(0xFF1A73E8);

/// หน้าเลือกตำแหน่งบนแผนที่ — โทนมืด · หมุดกลางจอ · ค้นหารอบจุดนี้
class MapLocationPicker extends StatefulWidget {
  const MapLocationPicker({
    super.key,
    required this.onBack,
    required this.onConfirm,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
  });

  final VoidCallback onBack;
  final void Function(double lat, double lng, String address) onConfirm;
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final _places = PlacesService();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  GoogleMapController? _map;
  MapType _mapType = MapType.normal;
  bool _webMapsBlocked = isGoogleMapsWebBlocked;
  bool _moving = false;
  bool _locating = false;
  bool _searching = false;
  List<PlaceSearchHit> _suggestions = [];
  Timer? _geoDebounce;
  Timer? _searchDebounce;

  late double _lat;
  late double _lng;
  String _address = '';

  bool get _useOsm =>
      !Env.hasMapsKey || Env.preferOsmWebMap || _webMapsBlocked;

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLat ?? kBangkokCenter.latitude;
    _lng = widget.initialLng ?? kBangkokCenter.longitude;
    _address = widget.initialAddress?.trim() ?? '';
    if (_address.isNotEmpty) _searchCtrl.text = _address;
    listenGoogleMapsWebAuthFailure(() {
      if (!mounted || _webMapsBlocked) return;
      setState(() => _webMapsBlocked = true);
    });
    if (_address.isEmpty) {
      unawaited(_reverseGeocode(_lat, _lng));
    }
  }

  @override
  void dispose() {
    _geoDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    final label = await _places.reverseGeocode(lat, lng);
    if (!mounted) return;
    setState(() {
      _address = label?.trim().isNotEmpty == true
          ? label!.trim()
          : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
      if (!_searchFocus.hasFocus) {
        _searchCtrl.text = _address;
      }
    });
  }

  void _onCameraMove(CameraPosition pos) {
    _lat = pos.target.latitude;
    _lng = pos.target.longitude;
    if (!_moving) setState(() => _moving = true);
  }

  void _onCameraIdle() {
    setState(() => _moving = false);
    _geoDebounce?.cancel();
    _geoDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_reverseGeocode(_lat, _lng));
    });
  }

  Future<void> _goMyLocation() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).mapPickerNeedLocation)),
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _lat = pos.latitude;
      _lng = pos.longitude;
      await _map?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(_lat, _lng), 16),
      );
      await _reverseGeocode(_lat, _lng);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).mapPickerNeedLocation)),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onSearchChanged(String raw) {
    _searchDebounce?.cancel();
    final q = raw.trim();
    if (q.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 320), () async {
      setState(() => _searching = true);
      final hits = await _places.search(q);
      if (!mounted) return;
      setState(() {
        _suggestions = hits;
        _searching = false;
      });
    });
  }

  Future<void> _selectHit(PlaceSearchHit hit) async {
    _searchFocus.unfocus();
    setState(() => _suggestions = []);
    if (hit.lat == null || hit.lng == null) return;
    _lat = hit.lat!;
    _lng = hit.lng!;
    _address = hit.subtitle.isNotEmpty ? '${hit.name}, ${hit.subtitle}' : hit.name;
    _searchCtrl.text = _address;
    await _map?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(_lat, _lng), 16),
    );
  }

  void _confirm() {
    final addr = _address.trim().isNotEmpty
        ? _address.trim()
        : _searchCtrl.text.trim();
    widget.onConfirm(_lat, _lng, addr);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final topInset = PageSafeInsets.top(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: topInset),
          _Header(title: s.mapPickerTitle, onBack: widget.onBack),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _SearchField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              hint: s.mapPickerSearchHint,
              onChanged: _onSearchChanged,
              onClear: () {
                _searchCtrl.clear();
                setState(() => _suggestions = []);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _InfoBanner(text: s.mapPickerHint),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _buildMap()),
                // center pin + bubble
                IgnorePointer(
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_address.isNotEmpty && !_moving)
                            _AddressBubble(text: _address),
                          if (_address.isNotEmpty && !_moving)
                            const SizedBox(height: 6),
                          _CenterPin(lifting: _moving),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: _MapTypeToggle(
                    mapType: _mapType,
                    onChanged: (t) => setState(() => _mapType = t),
                    mapLabel: s.mapPickerMapType,
                    satelliteLabel: s.mapPickerSatellite,
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 16,
                  child: _MyLocationChip(
                    loading: _locating,
                    label: s.mapPickerUseCurrent,
                    onTap: _goMyLocation,
                  ),
                ),
                if (_suggestions.isNotEmpty || _searching)
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 8,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      clipBehavior: Clip.antiAlias,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _suggestions.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final hit = _suggestions[i];
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.place_outlined,
                                      color: LivingBkkBrand.brandRed,
                                      size: 22,
                                    ),
                                    title: Text(
                                      hit.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    subtitle: Text(
                                      hit.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    onTap: () => _selectHit(hit),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + (bottomInset > 0 ? 0 : 4)),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _confirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: _pickerGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    s.mapPickerSearchAround,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_useOsm) {
      return ColoredBox(
        color: const Color(0xFF1d2c4d),
        child: OsmListingsMap(
          listings: const [],
          fullBleed: true,
          focusUserOnStart: false,
          fabBottomPadding: 8,
          pinLatitude: _lat,
          pinLongitude: _lng,
        ),
      );
    }

    return GoogleMap(
      key: ValueKey(_mapType),
      initialCameraPosition: CameraPosition(
        target: LatLng(_lat, _lng),
        zoom: 15.5,
      ),
      style: _mapType == MapType.normal ? GoogleMapDarkStyle.json : null,
      mapType: _mapType,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      indoorViewEnabled: false,
      trafficEnabled: false,
      buildingsEnabled: true,
      markers: const <Marker>{},
      onMapCreated: (c) {
        _map = c;
      },
      onCameraMove: _onCameraMove,
      onCameraIdle: _onCameraIdle,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: Color(0xFF202124),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, v, __) {
            if (v.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              onPressed: onClear,
              icon: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
            );
          },
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: _infoBannerFg, width: 1.4),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _infoBannerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, size: 18, color: _infoBannerFg),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: Color(0xFF3C4043),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapTypeToggle extends StatelessWidget {
  const _MapTypeToggle({
    required this.mapType,
    required this.onChanged,
    required this.mapLabel,
    required this.satelliteLabel,
  });

  final MapType mapType;
  final ValueChanged<MapType> onChanged;
  final String mapLabel;
  final String satelliteLabel;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, MapType type) {
      final selected = mapType == type;
      return GestureDetector(
        onTap: () => onChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _pickerGreen : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF202124),
            ),
          ),
        ),
      );
    }

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            chip(mapLabel, MapType.normal),
            chip(satelliteLabel, MapType.satellite),
          ],
        ),
      ),
    );
  }
}

class _MyLocationChip extends StatelessWidget {
  const _MyLocationChip({
    required this.loading,
    required this.label,
    required this.onTap,
  });

  final bool loading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.my_location, size: 18, color: Color(0xFF202124)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF202124),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressBubble extends StatelessWidget {
  const _AddressBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Material(
        elevation: 3,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202124),
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterPin extends StatelessWidget {
  const _CenterPin({required this.lifting});

  final bool lifting;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      transform: Matrix4.translationValues(0, lifting ? -10 : 0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            size: 48,
            color: LivingBkkBrand.brandRed,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: lifting ? 0.35 : 0.0,
            child: Container(
              width: 10,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
