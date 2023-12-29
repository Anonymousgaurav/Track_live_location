import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:location/location.dart' as loc;
import 'package:provider/provider.dart';
import 'package:user_live_location/models/AppObservableModel.dart';
import 'package:user_live_location/utils/constants.dart';

class LiveLocationWidget extends StatefulWidget {
  final LatLng sourceCoordinates;
  final LatLng destinationCoordinates;
  final String sourceIcon;
  final String destinationIcon;
  final String userIcon;
  final String apiKey;
  final Color pathColor;
  final int pathWidth;
  final double tiltMap;
  final double zoomLevel;
  final Function(LocationData) recentLocationDetail;
  final Color indicatorColor;
  final Color indicatorTextColor;
  final Color loadingScreenBackground;

  const LiveLocationWidget({
    Key? key,
    required this.sourceCoordinates,
    required this.destinationCoordinates,
    this.sourceIcon = sourceMarker,
    this.destinationIcon = sourceMarker,
    this.userIcon = userMarker,
    required this.apiKey,
    required this.pathColor,
    this.pathWidth = 6,
    this.tiltMap = 30,
    this.zoomLevel = 16.0,
    required this.recentLocationDetail,
    required this.indicatorColor,
    required this.indicatorTextColor,
    required this.loadingScreenBackground,
  }) : super(key: key);

  @override
  State<LiveLocationWidget> createState() => _LiveLocationWidgetState();
}

class _LiveLocationWidgetState extends State<LiveLocationWidget> {
  final Completer<GoogleMapController> _controller = Completer();

  List<LatLng> polylineCoordinates = [];
  LocationData? currentLocation;
  bool permissionGranted = false;

  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    getCurrentLocation();
    setCustomMarkerIcon();
    getPolyPoints();
    super.initState();
  }

  void getCurrentLocation() async {
    Location location = Location();
    if (!await location.requestService()) {}
    final status = await location.requestPermission();
    const granted = PermissionStatus.granted;
    bool result = status == granted || status == granted;

    if (result) {
      location.changeSettings(accuracy: loc.LocationAccuracy.high);

      location.getLocation().then((location) {
        Provider.of<AppObservableModel>(context, listen: false)
            .currentLocation(location);

        Provider.of<AppObservableModel>(context, listen: false)
            .permissionGranted(true);
      });

      GoogleMapController googleMapController = await _controller.future;

      location.onLocationChanged.listen((newLocation) {
        Provider.of<AppObservableModel>(context, listen: false)
            .currentLocation(newLocation);
        widget.recentLocationDetail(newLocation);

        googleMapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
                zoom: widget.zoomLevel,
                target:
                    LatLng(newLocation.latitude!, newLocation.longitude!))));
      });
    } else {
      Provider.of<AppObservableModel>(context, listen: false)
          .permissionGranted(false);
    }
  }

  void setCustomMarkerIcon() {
    getBytesFromAsset(widget.sourceIcon, 64).then((onValue) {
      sourceIcon = BitmapDescriptor.fromBytes(onValue);
    });

    getBytesFromAsset(widget.destinationIcon, 64).then((onValue) {
      destinationIcon = BitmapDescriptor.fromBytes(onValue);
    });

    getBytesFromAsset(widget.userIcon, 64).then((onValue) {
      currentLocationIcon = BitmapDescriptor.fromBytes(onValue);
    });
  }

  void getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      widget.apiKey,
      PointLatLng(widget.sourceCoordinates.latitude,
          widget.sourceCoordinates.longitude),
      PointLatLng(widget.destinationCoordinates.latitude,
          widget.destinationCoordinates.longitude),
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        Provider.of<AppObservableModel>(context, listen: false)
            .polyLines(point.latitude, point.longitude);
      }
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(body: Consumer<AppObservableModel>(
        builder: (context, value, child) {
          return !value.permission
              ? Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: widget.loadingScreenBackground,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 200.0,
                        width: 200.0,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: widget.indicatorColor,
                              strokeWidth: 4.0,
                            ),
                            const SizedBox(
                              height: 20.0,
                            ),
                            Text(
                              "Loading",
                              style:
                                  TextStyle(color: widget.indicatorTextColor),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                )
              : GoogleMap(
                  scrollGesturesEnabled: true,
                  compassEnabled: true,
                  zoomGesturesEnabled: true,
                  tiltGesturesEnabled: false,
                  mapType: MapType.normal,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: true,
                  initialCameraPosition: CameraPosition(
                      target: LatLng(value.userLocation!.latitude!,
                          value.userLocation!.longitude!),
                      zoom: widget.zoomLevel,
                      tilt: widget.tiltMap),
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId(polyLines),
                      points: value.polylineCoordinates,
                      color: widget.pathColor,
                      width: widget.pathWidth,
                    )
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId(currentMarker),
                      icon: currentLocationIcon,
                      position: LatLng(value.userLocation!.latitude!,
                          value.userLocation!.longitude!),
                    ),
                    Marker(
                      markerId: const MarkerId(sourceMarkerId),
                      icon: sourceIcon,
                      position: widget.sourceCoordinates,
                    ),
                    Marker(
                      markerId: const MarkerId(destinationMarkerId),
                      icon: destinationIcon,
                      position: widget.destinationCoordinates,
                    ),
                  },
                  onMapCreated: (mapController) {
                    _controller.complete(mapController);
                  },
                );
        },
      )),
    );
  }
}
