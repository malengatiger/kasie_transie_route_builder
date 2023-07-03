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

///Using a map, place each route point after another till the route is mapped
class RouteCreatorMap2 extends StatefulWidget {
  final lib.Route route;

  const RouteCreatorMap2({
    Key? key,
    required this.route,
  }) : super(key: key);

  @override
  RouteCreatorMap2State createState() => RouteCreatorMap2State();
}

class RouteCreatorMap2State extends State<RouteCreatorMap2> {
  static const defaultZoom = 16.0;
  final Completer<GoogleMapController> _mapController = Completer();

  final CameraPosition _myCurrentCameraPosition =
      const CameraPosition(target: LatLng(-26.5, 27.6), zoom: 14.6);
  static const mm = '💟💟💟💟💟💟💟💟💟💟 RouteCreatorMap2: 💪 ';
  final _key = GlobalKey<ScaffoldState>();
  bool busy = false;
  bool isHybrid = false;
  lib.User? _user;
  geo.Position? _currentPosition;
  final Set<Marker> _markers = HashSet();
  final Set<Circle> _circles = HashSet();
  final Set<Polyline> _polyLines = {};
  BitmapDescriptor? _dotMarker;

  // List<BitmapDescriptor> _numberMarkers = [];
  final List<lib.RoutePoint> rpList = [];

  // List<lib.Landmark> _landmarks = [];
  List<lib.RoutePoint> existingRoutePoints = [];
  List<poly.PointLatLng>? polylinePoints;
  final numberMarkers = <BitmapDescriptor>[];

  int routePointIndex = 0;
  bool sending = false;
  Timer? timer;
  int totalPoints = 0;
  var routeLandmarks = <lib.RouteLandmark>[];
  var landmarkIndex = 0;

  @override
  void initState() {
    super.initState();
    _makeDotMarker();
    _getUser();
  }

  void _controlReads(bool refresh) async {
    setState(() {
      busy = true;
    });
    try {
      await _buildLandmarkIcons();
      await getRoutePoints(refresh);
      await getRouteLandmarks();
    } catch (e) {
      pp(e);
    }
    setState(() {
      busy = false;
    });
  }


  Future getRouteLandmarks() async {
    routeLandmarks =
        await listApiDog.getRouteLandmarks(widget.route.routeId!, true);
    pp('\n\n$mm _getRouteLandmarks ...  ${E.appleRed} route: ${widget.route.name}; found: ${routeLandmarks.length} ');
    routeLandmarks.sort((a, b) => a.created!.compareTo(b.created!));
    landmarkIndex = 0;
    for (var landmark in routeLandmarks) {
      final latLng = LatLng(landmark.position!.coordinates.last,
          landmark.position!.coordinates.first);
      _markers.add(Marker(
          markerId: MarkerId('${landmark.landmarkId}'),
          icon: numberMarkers.elementAt(landmarkIndex),
          onTap: () {
            pp('$mm .............. marker tapped: $routePointIndex');
            //_deleteRoutePoint(routePoint);
          },
          infoWindow: InfoWindow(
              snippet:
                  '\nThis landmark is part of the route: \n${widget.route.name}\n\n',
              title: '🔵 ${landmark.landmarkName}',
              onTap: () {
                pp('$mm ............. infoWindow tapped, point index: $routePointIndex');
                //_deleteLandmark(landmark);
              }),
          position: latLng));
      landmarkIndex++;
      pp('$mm ... routeLandmark added to markers: ${_markers.length}');
    }
    setState(() {});

    var last = routeLandmarks.last;
    final latLng = LatLng(
        last.position!.coordinates.last, last.position!.coordinates.first);

    _animateCamera(latLng, 15.0);

  }

  Future<void> _animateCamera(LatLng latLng, double zoom) async {
    var cameraPos = CameraPosition(target: latLng, zoom: zoom);
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPos));
  }

  Future _buildLandmarkIcons() async {
    for (var i = 0; i < 120; i++) {
      var intList =
          await getBytesFromAsset("assets/numbers/number_${i + 1}.png", 84);
      numberMarkers.add(BitmapDescriptor.fromBytes(intList));
    }
    pp('$mm have built ${numberMarkers.length} markers for landmarks');
  }

  Future getRoutePoints(bool refresh) async {
    pp('$mm getRoutePoints ... refresh $refresh');
    setState(() {
      busy = true;
    });
    try {
      _user = await prefs.getUser();
      pp('$mm getting existing RoutePoints ....... refresh: $refresh');
      setState(() {
        busy = true;
      });
      existingRoutePoints =
          await listApiDog.getRoutePoints(widget.route.routeId!, refresh);
      pp('$mm .......... existingRoutePoints ....  🍎 found: '
          '${existingRoutePoints.length} points');
      routePointIndex = existingRoutePoints.length;
      await _buildExistingMarkers();
    } catch (e) {
      pp(e);
    }
  }

  Future<void> _buildExistingMarkers() async {
    await _makeDotMarker();
    _addPolyLine();
  }

  void _addPolyLine() {

    pp('$mm .......... _addPolyLine ....... .');
    _polyLines.clear();
    var mPoints = <LatLng>[];
    existingRoutePoints.sort((a, b) => a.index!.compareTo(b.index!));
    for (var rp in existingRoutePoints) {
      mPoints.add(LatLng(
          rp.position!.coordinates.last, rp.position!.coordinates.first));
    }
    var polyLine = Polyline(
        color: Colors.grey[600]!,
        width: 8,
        points: mPoints,
        polylineId: PolylineId(DateTime.now().toIso8601String()));

    _polyLines.add(polyLine);
    //
    var last = existingRoutePoints.last;
    final latLng = LatLng(
        last.position!.coordinates.last, last.position!.coordinates.first);
    totalPoints = existingRoutePoints.length;
    routePointIndex = existingRoutePoints.length;

    _animateCamera(latLng, 16);
    setState(() {});
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
    var intList = await getBytesFromAsset("assets/markers/dot2.png", 64);
    _dotMarker = BitmapDescriptor.fromBytes(intList);
    pp('$mm custom marker 💜 assets/markers/dot2.png created');
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

  bool checkDistance(LatLng latLng) {
    double? mLat, mLng;
    lib.RoutePoint? prev;
    try {
      prev = rpList.last;
      mLat = prev.position!.coordinates.last;
      mLng = prev.position!.coordinates.first;
    } catch (e) {
      return true;
    }

    try {
      var dist = locationBloc.getDistance(
          latitude: latLng.latitude,
          longitude: latLng.longitude,
          toLatitude: mLat,
          toLongitude: mLng);

      if (dist > 50) {
        pp('\n\n\n$mm ... this is probably a rogue routePoint: ${E.redDot} '
            '${E.redDot}${E.redDot} distance from previous point:  ${E.redDot} $dist metres');
        return false;
      } else {
        pp('$mm distance from previous point: ${E.appleGreen} $dist metres');
      }
    } catch (e) {
      pp('$mm checkDistance failed: ${E.redDot} ');
    }
    return true;
  }

  void _addNewRoutePoint(LatLng latLng) async {
    if (!checkDistance(latLng)) {
      return;
    }

    var id = Uuid.v4().toString();
    // _markers.add(Marker(
    //     markerId: MarkerId(id),
    //     icon: _dotMarker!,
    //     onTap: () {
    //       pp('$mm .............. marker tapped: $routePointIndex ${E.blueDot} '
    //           'latLng: $latLng - routePointId: $id');
    //     },
    //     infoWindow: InfoWindow(
    //         snippet: '\nThis point is part of the route. Tap to remove\n\n',
    //         title: 'RoutePoint ${routePointIndex + 1}',
    //         onTap: () {
    //           pp('$mm ............. infoWindow tapped, point index: $routePointIndex'
    //               'latLng: $latLng - routePointId: $id ${E.redDot} DELETE!!');
    //           _deleteRoutePoint(id);
    //         }),
    //     position: LatLng(latLng.latitude, latLng.longitude)));

    if (timer == null) {
      startTimer();
    }
    totalPoints++;
    pp('$mm RoutePoint added to map; index: $routePointIndex '
        '🔵 🔵 🔵 total points: $totalPoints');

    routePointIndex++;
    var routePoint = lib.RoutePoint(ObjectId(),
        latitude: latLng.latitude,
        longitude: latLng.longitude,
        routeId: widget.route.routeId,
        routeName: widget.route.name,
        index: routePointIndex,
        position: lib.Position(
          coordinates: [latLng.longitude, latLng.latitude],
          latitude: latLng.latitude,
          longitude: latLng.longitude,
        ),
        routePointId: id,
        created: DateTime.now().toUtc().toIso8601String());

    existingRoutePoints.add(routePoint);
    rpList.add(routePoint);

    _addPolyLine();

    _animateCamera(latLng, defaultZoom + 6);
    setState(() {});
  }

  void startTimer() {
    pp('$mm ... startTimer ... ');
    timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      pp('$mm timer ticked: 💛️💛️ ${timer.tick}');
      _sendRoutePointsToBackend();
    });
  }

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

  void _deleteRoutePoint(String routePointId) async {

    bool found = false;
    lib.RoutePoint? routePoint;
    for (var rp in rpList) {
      if (rp.routePointId == routePointId) {
        found = true;
        routePoint = rp;
      }
    }
    if (found) {
      rpList.remove(routePoint);
      existingRoutePoints.remove(routePoint);
      totalPoints--;
      var res = _markers.remove(Marker(markerId: MarkerId(routePointId)));
      pp('$mm ... removed marker from map, result: $res, ${E.nice} = true, '
          ' ${E.redDot} if not, the routePoint was no longer '
          'in the current list and must be deleted from backend');
      setState(() {});
    } else {
      try {
        setState(() {
          busy = true;
        });
          pp('$mm ... start delete ...');
          final result = await dataApiDog.deleteRoutePoint(routePointId);
          pp('$mm ... removed point from database: $result; ${E.nice} 0 is good, Boss!');

      } catch (e) {
        pp('$mm $e');
      }
      setState(() {
        busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _key,
        body: Stack(children: [
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
              _controlReads(false);
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
                    color: Colors.black38,
                    shape: getRoundedBorder(radius: 16),
                    elevation: 24,
                    child: SizedBox(
                      height: 108,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              'Route Mapper',
                              style: myTextStyleMediumLarge(context, 20),
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
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              '${widget.route.associationName}',
                              style: myTextStyleTiny(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ))),
          Positioned(
              left: 16,
              bottom: 80,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Text('Points'),
                    const SizedBox(
                      width: 16,
                    ),
                    Text(
                      '$totalPoints',
                      style: myNumberStyleLargerWithColor(
                          Colors.black26, 44, context),
                    ),
                  ],
                ),
              )),
          Positioned(
              left: 16,
              bottom: 20,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Text('Index:'),
                    const SizedBox(
                      width: 16,
                    ),
                    Text(
                      '$routePointIndex',
                      style: myNumberStyleLargerWithColor(
                          Colors.black26, 20, context),
                    ),
                  ],
                ),
              )),
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
                          _controlReads(true);
                        },
                        icon: Icon(
                          Icons.refresh,
                          color: Theme.of(context).primaryColor,
                        ))
                  ],
                ),
              )),
          busy
              ? const Positioned(
                  left: 100,
                  top: 160,
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 12,
                      backgroundColor: Colors.purple,
                    ),
                  ))
              : const SizedBox(),
        ]));
  }
}
