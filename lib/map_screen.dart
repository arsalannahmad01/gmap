import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:gmap/consts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Location _location = new Location();

  static LatLng _currentLocation =
      LatLng(28.614292836120324, 77.19964543400975);

  static LatLng _sourceLocation = LatLng(28.600406419550154, 77.22737142127856);

  static LatLng _destinationLocation =
      LatLng(28.650829755819426, 77.23345280404128);

  Completer<GoogleMapController> _gMapController =
      Completer<GoogleMapController>();

  Map<PolylineId, Polyline> _polylines = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getCurrentLocation().then((_) => {
          _getPolylinePoints().then(
            (coordinates) => {
              _createPolylines(coordinates),
            },
          ),
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _gMapController.complete(controller);
        },
        initialCameraPosition: CameraPosition(
          target: _currentLocation,
          zoom: 12,
        ),
        markers: _createMarker(),
        polylines: Set<Polyline>.of(_polylines.values),
      ),
    );
  }

  Set<Marker> _createMarker() {
    Set<Marker> markers = {
      Marker(
        markerId: MarkerId("Current/Initial Position"),
        position: _currentLocation,
      ),
      Marker(
          markerId: MarkerId("Current/Initial Position"),
          position: _sourceLocation,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)),
      Marker(
          markerId: MarkerId("Current/Initial Position"),
          position: _destinationLocation,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)),
    };

    return markers;
  }

  // get current location
  Future<void> _getCurrentLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _location.onLocationChanged.listen((LocationData currentLocation) => {
          setState(() {
            _currentLocation =
                LatLng(currentLocation.latitude!, _currentLocation.longitude!);
            moveCamera(_currentLocation);
          })
        });
  }

  // Move Camera
  Future<void> moveCamera(LatLng position) async {
    final GoogleMapController controller = await _gMapController.future;

    CameraPosition newCameraPosition =
        CameraPosition(target: position, zoom: 12);

    controller.animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
  }

  // get the polyline points
  Future<List<LatLng>> _getPolylinePoints() async {
    List<LatLng> coordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: GOOGLE_API_KEY,
      request: PolylineRequest(
        origin: PointLatLng(
          _sourceLocation.latitude,
          _sourceLocation.longitude,
        ),
        destination: PointLatLng(
          _destinationLocation.latitude,
          _destinationLocation.longitude,
        ),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        coordinates.add(
          LatLng(point.latitude, point.longitude),
        );
      });
    }

    return coordinates;
  }

  // create polylines
  void _createPolylines(List<LatLng> coordinates) {
    PolylineId id = PolylineId("polyline");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: coordinates,
      width: 4,
    );

    setState(() {
      _polylines[id] = polyline;
    });
  }
}
