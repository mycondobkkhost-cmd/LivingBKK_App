/// สไตล์แผนที่ — โทนสะอาดคล้ายแอพ Google Maps (light)
/// ลด POI / ป้ายย่อย · คงถนนหลัก · น้ำ · สวน · สถานีรถไฟฟ้า
abstract final class GoogleMapCleanStyle {
  /// JSON สำหรับ [GoogleMap.style] / [GoogleMapController.setMapStyle]
  static const String json = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#f5f5f5"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#f5f5f5"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "administrative.neighborhood",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "poi",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.park",
    "stylers": [{"visibility": "on"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#e5f3e5"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6b9b76"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#dadada"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#c9c9c9"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "featureType": "road.local",
    "elementType": "labels",
    "stylers": [{"visibility": "simplified"}]
  },
  {
    "featureType": "transit",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit.line",
    "stylers": [{"visibility": "on"}, {"color": "#e0e0e0"}]
  },
  {
    "featureType": "transit.station",
    "stylers": [{"visibility": "on"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.icon",
    "stylers": [{"visibility": "simplified"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#1a73e8"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#c9e7f5"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9e9e9e"}]
  }
]
''';
}
