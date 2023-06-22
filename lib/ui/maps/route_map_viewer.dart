import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as poly;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/route_point_list.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/utils/device_location_bloc.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:realm/realm.dart';

class RouteMapViewer extends StatefulWidget {
  final lib.Route route;

  const RouteMapViewer({
    Key? key,
    required this.route,
  }) : super(key: key);

  @override
  RouteMapViewerState createState() => RouteMapViewerState();
}

class RouteMapViewerState extends State<RouteMapViewer> {
  static const defaultZoom = 14.0;
  final Completer<GoogleMapController> _mapController = Completer();

  CameraPosition? _myCurrentCameraPosition;
  static const mm = '😡😡😡😡😡😡😡 RouteMapViewer: 💪 ';
  final _key = GlobalKey<ScaffoldState>();
  bool busy = false;
  bool isHybrid = true;
  lib.User? _user;
  geo.Position? _currentPosition;
  final Set<Marker> _markers = HashSet();
  final Set<Circle> _circles = HashSet();
  final Set<Polyline> _polyLines = Set();
  BitmapDescriptor? _dotMarker;
  // List<BitmapDescriptor> _numberMarkers = [];
  final List<lib.RoutePoint> rpList = [];
  List<lib.RoutePoint> existingRoutePoints = [];
  // List<lib.Landmark> _landmarks = [];

  List<poly.PointLatLng>? polylinePoints;
  Color color = Colors.black;
  var routeLandmarks = <lib.RouteLandmark>[];
  int landmarkIndex = 0;

  @override
  void initState() {
    super.initState();
    _buildLandmarkIcons();
    _getCurrentLocation();
    _getUser();
    color = _getColor();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _getColor() {
    switch (widget.route.color) {
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      case 'amber':
        return Colors.amber;
      case 'yellow':
        return Colors.yellow;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      case 'green':
        return Colors.green;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'blue':
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  Future _getRouteLandmarks() async {
    routeLandmarks =
        await listApiDog.getRouteLandmarks(widget.route.routeId!, true);
    pp('$mm _getRouteLandmarks ...  route: ${widget.route.name}; found: ${routeLandmarks.length} ');

    landmarkIndex = 0;
    for (var landmark in routeLandmarks) {
      final latLng = LatLng(landmark.position!.coordinates.last,
          landmark.position!.coordinates.first);
      _markers.add(Marker(
          markerId: MarkerId('${landmark.landmarkId}'),
          icon: numberMarkers.elementAt(landmarkIndex),
          onTap: () {
            pp('$mm .............. marker tapped: $index');
            //_deleteRoutePoint(routePoint);
          },
          infoWindow: InfoWindow(
              snippet: 'This landmark is part of the route.',
              title: '🔵 ${landmark.landmarkName}',
              onTap: () {
                pp('$mm ............. infoWindow tapped, point index: $index');
                //_deleteLandmark(landmark);
              }),
          position: latLng));
      landmarkIndex++;
    }
    setState(() {});
  }

  Future _getRoutePoints(bool refresh) async {
    setState(() {
      busy = true;
    });
    try {
      _user = await prefs.getUser();
      pp('$mm getting existing RoutePoints .......');
      existingRoutePoints =
          await listApiDog.getRoutePoints(widget.route.routeId!, refresh);

      pp('$mm .......... existingRoutePoints ....  🍎 found: '
          '${existingRoutePoints.length} points');
      _addPolyLine();
      setState(() {

      });
      var point = existingRoutePoints.first;
      var latLng = LatLng(point.position!.coordinates.last, point.position!.coordinates.first);
      _myCurrentCameraPosition = CameraPosition(
        target: latLng,
        zoom: defaultZoom,
      );
      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(_myCurrentCameraPosition!));

    } catch (e) {
      pp(e);
    }
    setState(() {
      busy = false;
    });
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
      zoom: defaultZoom,
    );
    setState(() {});
  }

  Future<void> _zoomToStartCity() async {
    if (widget.route.routeStartEnd != null) {
      final latLng = LatLng(
          widget.route.routeStartEnd!.startCityPosition!.coordinates.last,
          widget.route.routeStartEnd!.startCityPosition!.coordinates.first);
      var cameraPos = CameraPosition(target: latLng, zoom: 11.0);
      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(cameraPos));
      setState(() {});
    }
  }

  int index = 0;
  final numberMarkers = <BitmapDescriptor>[];
  Future _buildLandmarkIcons() async {
    for (var i = 0; i < 100; i++) {
      var intList =
          await getBytesFromAsset("assets/numbers/number_${i + 1}.png", 84);
      numberMarkers.add(BitmapDescriptor.fromBytes(intList));
    }
    pp('$mm have built ${numberMarkers.length} markers for landmarks');
  }

  _clearMap() {
    _polyLines.clear();
    _markers.clear();
  }

  void _addPolyLine() {
    pp('$mm .......... _addPolyLine ....... .');
    var mPoints = <LatLng>[];
    existingRoutePoints.sort((a, b) => a.index!.compareTo(b.index!));
    for (var rp in existingRoutePoints) {
      mPoints.add(LatLng(
          rp.position!.coordinates.last, rp.position!.coordinates.first));
    }
    _clearMap();
    var polyLine = Polyline(
        color: color,
        width: 8,
        points: mPoints,
        polylineId: PolylineId(DateTime.now().toIso8601String()));

    _polyLines.add(polyLine);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _key,
        body: _myCurrentCameraPosition == null
            ? Center(
                child: Text(
                  'Waiting for GPS location ...',
                  style: myTextStyleMediumBold(context),
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
                  onTap: (latLng) {
                    pp('$mm .......... on map tapped : $latLng .');
                  },
                  onMapCreated: (GoogleMapController controller) async {
                    _mapController.complete(controller);
                    _zoomToStartCity();
                    await _getRoutePoints(false);
                    _getRouteLandmarks();
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
                            child: SizedBox(
                              height: 100,
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Text(
                                    'Route Viewer',
                                    style: myTextStyleMediumLargeWithColor(
                                        context, Colors.white),
                                  ),
                                  Row(
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
                                          style: myTextStyleMediumWithColor(
                                              context, Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text('${widget.route.associationName}', style: myTextStyleTiny(context),)

                                ],
                              ),
                            ),
                          ),
                        ))),
                Positioned(
                    right: 12,
                    top: 40,
                    child: Card(
                      elevation: 8,
                      shape: getRoundedBorder(radius: 12),
                      child: Row(
                        children: [
                          IconButton(
                              onPressed: () {
                                _getRoutePoints(true);
                              },
                              icon: Icon(
                                Icons.toggle_on,
                                color: Theme.of(context).primaryColor,
                              ))
                        ],
                      ),
                    )),
                busy
                    ? const Positioned(
                        top: 160,
                        left: 48,
                        child: Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 12,
                              backgroundColor: Colors.pink,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
              ]));
  }
}
