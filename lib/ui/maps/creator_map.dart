import 'dart:async';
import 'dart:collection';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as poly;
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/data/route_point_list.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/utils/device_location_bloc.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:realm/realm.dart';

class CreatorMapMobile extends StatefulWidget {
  final lib.Route route;

  const CreatorMapMobile({
    Key? key,
    required this.route,
  }) : super(key: key);

  @override
  CreatorMapMobileState createState() => CreatorMapMobileState();
}

class CreatorMapMobileState extends State<CreatorMapMobile> {
  static const DEFAULT_ZOOM = 16.0;
  final Completer<GoogleMapController> _mapController = Completer();

  CameraPosition? _myCurrentCameraPosition;
  static const mm = '💟💟💟💟💟💟💟💟💟💟 CreatorMapMobile: 💪 ';
  final _key = GlobalKey<ScaffoldState>();
  bool busy = false;
  bool isHybrid = false;
  lib.User? _user;
  geo.Position? _currentPosition;
  final Set<Marker> _markers = HashSet();
  final Set<Circle> _circles = HashSet();
  final Set<Polyline> _polyLines = Set();
  BitmapDescriptor? _dotMarker;
  List<BitmapDescriptor> _numberMarkers = [];
  final List<lib.RoutePoint> rpList = [];
  List<lib.Landmark> _landmarks = [];

  List<poly.PointLatLng>? polylinePoints;
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _getUser();
  }

  @override
  void dispose() {
    if (timer != null) {
      timer!.cancel();
      timer == null;
    }
    if (rpList.isNotEmpty) {
      _sendRoutePointsToBackend();
    }
    super.dispose();
  }

  Future _getUser() async {
    _user = await prefs.getUser();
    _makeDotMarker();
  }

  Future _makeDotMarker() async {
    var intList = await getBytesFromAsset("assets/markers/dot2.png", 40);
    _dotMarker = BitmapDescriptor.fromBytes(intList);
    pp('$mm custom marker 💜 assets/markers/dot2.png created');
  }

  Future _getCurrentLocation() async {
    pp('$mm .......... get current location ....');
    _currentPosition = await locationBloc.getLocation();

    pp('$mm .......... get current location ....  🍎 found: ${_currentPosition!.toJson()}');
    _myCurrentCameraPosition = CameraPosition(
      target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      zoom: DEFAULT_ZOOM,
    );
    setState(() {});
  }

  Future<void> _zoomToStartCity() async {
    if (widget.route.routeStartEnd != null) {
      final latLng = LatLng(
          widget.route.routeStartEnd!.startCityPosition!.coordinates.last,
          widget.route.routeStartEnd!.startCityPosition!.coordinates.first);
      var cameraPos = CameraPosition(target: latLng, zoom: 13.0);
      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(cameraPos));
      setState(() {});
    }
  }

  int index = 0;

  void _addNewRoutePoint(LatLng latLng) async {
    var routePoint = lib.RoutePoint(ObjectId(),
        latitude: latLng.latitude,
        longitude: latLng.longitude,
        routeId: widget.route.routeId,
        index: index,
        position: lib.Position(
          coordinates: [latLng.longitude, latLng.latitude],
          latitude: latLng.latitude,
          longitude: latLng.longitude,
        ),
        routePointId: Uuid.v4().toString(),
        created: DateTime.now().toIso8601String());

    _markers.add(Marker(
        markerId: MarkerId('${routePoint.index}'),
        icon: _dotMarker!,
        onTap: () {
          pp('$mm .............. marker tapped: $index');
          _setPointInvalid(routePoint);
        },
        infoWindow: InfoWindow(
            title: 'RoutePoint ${index + 1}',
            onTap: () {
              pp('$mm ............. infoWindow tapped: ${index + 1}');
              _setPointInvalid(routePoint);
            }),
        position: LatLng(latLng.latitude, latLng.longitude)));

    rpList.add(routePoint);
    if (timer == null) {
      startTimer();
    }
    pp('$mm RoutePoint added to map and list; 🔵 🔵 🔵 total points: ${rpList.length}');
    index++;
    var cameraPos = CameraPosition(target: latLng, zoom: DEFAULT_ZOOM + 4);

    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPos));
    setState(() {});
  }

  Timer? timer;
  void startTimer() {
    pp('$mm ... startTimer ... ');
    timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      pp('$mm timer ticked: ${timer.tick}');
      _sendRoutePointsToBackend();
    });
  }

  bool sending = false;
  void _sendRoutePointsToBackend() async {
    pp('\n\n$mm ... sending route points to backend ... ${rpList.length} ');
    if (rpList.isEmpty) {
      pp('$mm no routePoints to send .... 🔵🔵 will ignore for now ...');
      return;
    }
    if (sending) {
      pp('$mm busy sending .... will ignore for now ...');
    }
    final sList = <lib.RoutePoint>[];
    for (var m in rpList) {
      sList.add(m);
    }
    rpList.clear();
    sending = true;
    var ml = RoutePointList(sList);
    final count = await dataApiDog.addRoutePoints(ml);
    sending = false;
    pp('$mm ... _sendRoutePointsToBackend: ❤️❤️route points saved to Kasie backend: ❤️ $count ❤️ DONE!\n\n');
  }

  var errors = <String>[];
  void _setPointInvalid(lib.RoutePoint routePoint) {
    pp('$mm _setPointInvalid this point; index: ${routePoint.index} from ${rpList.length} routePoints');
    try {
      _markers.remove(_markers.firstWhere((Marker marker) =>
          marker.markerId == MarkerId('${routePoint.index}')));
      errors.add(routePoint.routePointId!);
      //remove routePoint
      try {
        rpList.remove(routePoint);
        pp('$mm _setPointInvalid removed point; index: ${routePoint.index} ${E.appleRed} rpList: ${rpList.length} routePoints');

      } catch (e) {}
      setState(() {});
    } catch (e) {
      pp('We are fucked! $e');
    }
  }

  void _addPolyLine() {
    var mPoints = <LatLng>[];
    if (polylinePoints != null) {
      pp('$mm adding polyline points: ${polylinePoints!.length}.....');
      for (var element in polylinePoints!) {
        mPoints.add(LatLng(element.latitude, element.longitude));
      }
      var polyLine = Polyline(
          color: Colors.black,
          width: 4,
          points: mPoints,
          startCap: StrokeCap.butt as Cap,
          polylineId: PolylineId(DateTime.now().toIso8601String()));
      _polyLines.add(polyLine);
      setState(() {});
    }
  }

  void _addCircles(
      {required LatLng startLatLng, required LatLng destinationLatLng}) async {
    pp('$mm _addCircle ...  🍎  🍎 ');
    _circles.add(Circle(
      center: LatLng(startLatLng.latitude, startLatLng.longitude),
      radius: 150.0,
      strokeColor: Colors.green,
      fillColor: Colors.black26,
      strokeWidth: 4,
      circleId: CircleId('${DateTime.now().microsecondsSinceEpoch}'),
      onTap: () {},
    ));
    _circles.add(Circle(
      center: LatLng(destinationLatLng.latitude, destinationLatLng.longitude),
      radius: 150.0,
      strokeColor: Colors.red,
      fillColor: Colors.black26,
      strokeWidth: 4,
      circleId: CircleId('${DateTime.now().microsecondsSinceEpoch}'),
      onTap: () {},
    ));
  }

  void _saveRoutePoints() async {
    _sendRoutePointsToBackend();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _key,
        body: _myCurrentCameraPosition == null
            ? Center(
                child: Text(
                  'Waiting for GPS location ...',
                  style: myTextStyleMedium(context),
                ),
              )
            : Stack(children: [
                GoogleMap(
                  mapType: isHybrid ? MapType.hybrid : MapType.normal,
                  myLocationEnabled: true,
                  markers: _markers,
                  circles: _circles,
                  polylines: _polyLines,
                  initialCameraPosition: _myCurrentCameraPosition!,
                  onTap: _addNewRoutePoint,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController.complete(controller);
                    _zoomToStartCity();
                  },
                ),
                Positioned(
                    right: 12,
                    top: 120,
                    child: Container(
                      color: Colors.black45,
                      child: Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: IconButton(
                            onPressed: () {
                              setState(() {
                                isHybrid = !isHybrid;
                              });
                            },
                            icon: Icon(
                              Icons.album_outlined,
                              color: isHybrid ? Colors.yellow : Colors.white,
                            )),
                      ),
                    )),
                Positioned(
                    left: 12,
                    top: 40,
                    child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Card(
                          color: Colors.black26,
                          elevation: 24,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.arrow_back_ios,
                                  size: 24,
                                  color: Colors.white,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    '${widget.route.name}',
                                    style: myTextStyleSmallWithColor(
                                        context, Colors.white),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ))),
                rpList.length > 10
                    ? Positioned(
                        left: 16,
                        bottom: 40,
                        child: Container(
                          color: Colors.black26,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: _saveRoutePoints,
                              child: Text('Save  ${rpList.length} RoutePoints'),
                            ),
                          ),
                        ))
                    : Container()
              ]));
  }
}
