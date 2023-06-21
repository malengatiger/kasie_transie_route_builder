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

class RouteCreatorMap extends StatefulWidget {
  final lib.Route route;

  const RouteCreatorMap({
    Key? key,
    required this.route,
  }) : super(key: key);

  @override
  RouteCreatorMapState createState() => RouteCreatorMapState();
}

class RouteCreatorMapState extends State<RouteCreatorMap> {
  static const defaultZoom = 16.0;
  final Completer<GoogleMapController> _mapController = Completer();

  CameraPosition _myCurrentCameraPosition =
      const CameraPosition(target: LatLng(-26.5, 27.6), zoom: 14.6);
  static const mm = '💟💟💟💟💟💟💟💟💟💟 RouteCreatorMap: 💪 ';
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

  int index = 0;
  bool sending = false;
  Timer? timer;
  int totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _makeDotMarker();
    _getUser();
  }

  Future _getRoutePoints(bool refresh) async {
    setState(() {
      busy = true;
    });
    try {
      _user = await prefs.getUser();
      pp('$mm getting existing RoutePoints ....... refresh: $refresh');
      existingRoutePoints =
          await listApiDog.getRoutePoints(widget.route.routeId!, refresh);
      pp('$mm .......... existingRoutePoints ....  🍎 found: '
          '${existingRoutePoints.length} points');
      _buildExistingMarkers();
    } catch (e) {
      pp(e);
    }
    // setState(() {
    //   busy = false;
    // });
  }

  Future<void> _buildExistingMarkers() async {
    _clearMap();
    setState(() {
      busy = true;
    });
    await _makeDotMarker();
    if (existingRoutePoints.isNotEmpty) {
      for (var routePoint in existingRoutePoints) {
        var latLng = LatLng(routePoint.position!.coordinates.last,
            routePoint.position!.coordinates.first);
        _markers.add(Marker(
            markerId: MarkerId('${routePoint.routePointId}'),
            icon: _dotMarker!,
            onTap: () {
              pp('$mm .............. ${E.pear}${E.pear}${E.pear} '
                  'marker tapped: routePointId: ${routePoint.toJson()}');
            },
            infoWindow: InfoWindow(
                title: 'RoutePoint ${index + 1}',
                snippet: "This route point is part of the route. Tap to remove",
                onTap: () {
                  pp('$mm ............. infoWindow tapped: ${index + 1}');
                  _deleteRoutePoint(routePoint);
                }),
            position: LatLng(latLng.latitude, latLng.longitude)));
      }
      var last = existingRoutePoints.last;
      final latLng = LatLng(
          last.position!.coordinates.last, last.position!.coordinates.first);
      totalPoints = existingRoutePoints.length;
      index = existingRoutePoints.length - 1;

      var cameraPos = CameraPosition(target: latLng, zoom: 13.0);
      final GoogleMapController controller = await _mapController.future;
      await controller.animateCamera(CameraUpdate.newCameraPosition(cameraPos));
    }
    setState(() {
      busy = false;
    });
  }

  void _clearMap() {
    _polyLines.clear();
    _markers.clear();
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
      var cameraPos = CameraPosition(target: latLng, zoom: 13.0);
      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(cameraPos));
      setState(() {});
    }
  }

  bool checkDistance(LatLng latLng) {
    double? mLat, mLng;
    if (index > 1) {
      mLat = rpList.elementAt(index - 2).position!.coordinates.last;
      mLng = rpList.elementAt(index - 2).position!.coordinates.first;
      var dist = locationBloc.getDistance(
          latitude: latLng.latitude,
          longitude: latLng.longitude,
          toLatitude: mLat,
          toLongitude: mLng);
      if (dist > 20) {
        pp('$mm ... this is probably a rogue routePoint: ${E.redDot} '
            'distance from previous point: $dist metres');
        return false;
      } else {
        pp('$mm distance from previous point: ${E.appleGreen} $dist metres');
      }
    }
    return true;
  }

  void _addNewRoutePoint(LatLng latLng) async {
    if (!checkDistance(latLng)) {
      return;
    }

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
          // _deleteRoutePoint(routePoint);
        },
        infoWindow: InfoWindow(
            snippet: 'This point is part of the route. Tap to remove',
            title: 'RoutePoint ${index + 1}',
            onTap: () {
              pp('$mm ............. infoWindow tapped, point index: $index');
              _deleteRoutePoint(routePoint);
            }),
        position: LatLng(latLng.latitude, latLng.longitude)));

    rpList.add(routePoint);
    if (timer == null) {
      startTimer();
    }
    pp('$mm RoutePoint added to map and list; '
        '🔵 🔵 🔵 total points: ${rpList.length}');

    index++;
    totalPoints++;
    var cameraPos = CameraPosition(target: latLng, zoom: defaultZoom + 6);

    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPos));
    setState(() {});
  }

  void startTimer() {
    pp('$mm ... startTimer ... ');
    timer = Timer.periodic(const Duration(seconds: 30), (timer) {
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

  void _deleteRoutePoint(lib.RoutePoint point) async {
    setState(() {
      busy = true;
    });
    try {
      var id = point.routePointId!;
      var res = _markers.remove(Marker(markerId: MarkerId(id)));
      totalPoints--;
      pp('$mm ... removed marker from map: $res, ${E.nice} = true, if not, we fucked!');
      myPrettyJsonPrint(point.toJson());
      try {
        pp('$mm ... start delete ...');
        final result = await dataApiDog.deleteRoutePoint(id);
        pp('$mm ... removed point from database: $result; ${E.nice} 0 is good, Boss!');
        await _getRoutePoints(true);
      } catch (e) {}
    } catch (e) {
      pp('$mm $e');
    }
    setState(() {
      busy = false;
    });
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
                    _getRoutePoints(false);
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
                Positioned(
                    left: 16,
                    bottom: 40,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '$totalPoints',
                        style: myNumberStyleLargerWithColor(
                            Colors.black26, 44, context),
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
                                _getRoutePoints(true);
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
