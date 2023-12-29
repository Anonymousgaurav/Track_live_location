import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class AppObservableModel with ChangeNotifier {
  LocationData? userLocation;
  List<LatLng> polylineCoordinates;
  bool permission;

  AppObservableModel({
    this.userLocation,
    required this.polylineCoordinates,
    required this.permission,
  }) : super();

  factory AppObservableModel.empty() =>
      AppObservableModel(polylineCoordinates: [], permission: false);

  void currentLocation(LocationData currentLocation) {
    this.userLocation = currentLocation;
    this.notifyListeners();
  }

  void polyLines(double lat, double lon) {
    polylineCoordinates.add(LatLng(lat, lon));
    this.notifyListeners();
  }

  void permissionGranted(bool permission) {
    this.permission = permission;
    this.notifyListeners();
  }
}
