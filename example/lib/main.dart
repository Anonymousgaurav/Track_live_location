import 'package:example/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:user_live_location/models/AppObservableModel.dart';
import 'package:user_live_location/presentation/widgets/LiveLocationWidget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppObservableModel.empty(),
      lazy: true,
      child: LiveLocationWidget(
        loadingScreenBackground: ColorsRes.splashColor,
        indicatorColor: Colors.white,
        indicatorTextColor: Colors.white,
        sourceCoordinates: const LatLng(14.543174288806494, 121.01995289558047),
        destinationCoordinates: const LatLng(14.594365501150298, 120.97039980485026),
        apiKey: "",
        pathColor: ColorsRes.splashColor,
        pathWidth: 6,
        zoomLevel: 16.0,
        tiltMap: 30,
        sourceIcon: "assets/images/location_pin.png",
        destinationIcon: "assets/images/location_pin.png",
        userIcon: "assets/images/user_pin.png",
        recentLocationDetail: (loc) {},
      ),
    );
  }
}
